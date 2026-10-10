extends Node
## Autoload. Save/load, autosave and offline catch-up (SAVE_SYSTEM.md, DECISIONS.md D21, D24).
## Single slot JSON with a backup. Writes are safe: temp file → verify → backup → replace.

signal saved(reason: StringName)
signal loaded(warnings: PackedStringArray)
## Offline town progress was applied (load or resume). See `make_summary` for the keys.
signal offline_progress_applied(summary: Dictionary)

const SCHEMA_VERSION := SaveCodec.SCHEMA_VERSION
const SAVE_PATH := "user://save.json"
const BACKUP_PATH := "user://save.bak.json"
const TEMP_SUFFIX := ".tmp"

## GameManager (or a test instance with the same services).
var game: Node
var save_path := SAVE_PATH
var backup_path := BACKUP_PATH
var last_warnings: PackedStringArray = []
var last_offline_summary: Dictionary = {}

var _autosave_pending := false
var _background_since_unix := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	game = GameManager
	game.autosave_requested.connect(request_autosave)
	if has_save():
		load_game()
	else:
		save_game(&"new_game")


func _notification(what: int) -> void:
	if game == null:
		return
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			# Mobile OSes may kill a backgrounded app without warning (SAVE_SYSTEM.md).
			if what == NOTIFICATION_APPLICATION_PAUSED or OS.has_feature("mobile"):
				save_game(&"background")
				_background_since_unix = Time.get_unix_time_from_system()
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			if _background_since_unix > 0.0:
				apply_offline_progress(Time.get_unix_time_from_system() - _background_since_unix)
				_background_since_unix = 0.0
		NOTIFICATION_WM_CLOSE_REQUEST:
			save_game(&"quit")


func has_save() -> bool:
	return FileAccess.file_exists(save_path) or FileAccess.file_exists(backup_path)


## Coalesces several requests in one frame into one write.
func request_autosave(reason: StringName = &"autosave") -> void:
	if _autosave_pending:
		return
	_autosave_pending = true
	_flush_autosave.call_deferred(reason)


func _flush_autosave(reason: StringName) -> void:
	_autosave_pending = false
	save_game(reason)


## Safe write. Returns false (and leaves the previous save untouched) on any failure.
func save_game(reason: StringName = &"manual") -> bool:
	var data := SaveCodec.capture(game)
	var text := JSON.stringify(data, "\t")
	var temp_path := save_path + TEMP_SUFFIX
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: cannot write %s (%s)" % [temp_path, FileAccess.get_open_error()])
		return false
	file.store_string(text)
	file.close()
	# Verify what actually landed on disk before replacing anything.
	if not _read_json(temp_path) is Dictionary:
		push_warning("SaveManager: verification of %s failed" % temp_path)
		DirAccess.remove_absolute(temp_path)
		return false
	if FileAccess.file_exists(save_path):
		DirAccess.copy_absolute(save_path, backup_path)
	var error := DirAccess.rename_absolute(temp_path, save_path)
	if error != OK:
		push_warning("SaveManager: cannot replace %s (%s)" % [save_path, error_string(error)])
		return false
	saved.emit(reason)
	return true


## Loads the save, falling back to the backup, then to a new game. Applies offline progress
## for the time since the save. Returns true if a save (or backup) was restored.
func load_game() -> bool:
	last_warnings = PackedStringArray()
	for path in [save_path, backup_path]:
		if not FileAccess.file_exists(path):
			continue
		var data: Variant = _read_json(path)
		if not data is Dictionary:
			last_warnings.append("%s is corrupt" % path.get_file())
			continue
		var migrated: Variant = SaveCodec.migrate(data, last_warnings)
		if migrated == null:
			continue
		SaveCodec.restore(game, migrated, last_warnings)
		if path == backup_path:
			last_warnings.append("restored from backup")
		loaded.emit(last_warnings)
		apply_offline_progress(Time.get_unix_time_from_system() - float(migrated.get("saved_at_unix", 0.0)))
		return true
	last_warnings.append("no usable save, started a new game")
	game.reset_to_new_game()
	loaded.emit(last_warnings)
	return false


func delete_save() -> void:
	for path in [save_path, backup_path, save_path + TEMP_SUFFIX]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


## Applies `elapsed` real seconds to town timers, capped (D24). Negative values (clock changed)
## are ignored. Returns the "while you were away" summary.
func apply_offline_progress(elapsed: float) -> Dictionary:
	var cap: float = game.registry.config.offline_cap_hours * 3600.0
	var seconds := clampf(elapsed, 0.0, cap)
	var before := _snapshot()
	if seconds > 0.0:
		game.advance_town_time(seconds)
	last_offline_summary = make_summary(seconds, elapsed, before)
	if seconds >= 1.0:
		offline_progress_applied.emit(last_offline_summary)
	return last_offline_summary


## Keys: seconds (applied), capped (bool), recovered (names), xp (total), levels (total).
func make_summary(seconds: float, elapsed: float, before: Dictionary) -> Dictionary:
	var recovered := PackedStringArray()
	var xp := 0
	var levels := 0
	for hunter: HunterRuntime in game.hunters.get_all():
		var old: Array = before.get(hunter.unique_id, [false, hunter.level, hunter.xp])
		if old[0] and not hunter.injured:
			recovered.append(hunter.display_name)
		levels += hunter.level - int(old[1])
		xp += _total_xp(hunter.level, hunter.xp) - _total_xp(int(old[1]), int(old[2]))
	return {"seconds": seconds, "capped": elapsed > seconds + 0.5, "recovered": recovered, "xp": xp, "levels": levels}


func _snapshot() -> Dictionary:
	var result := {}
	for hunter: HunterRuntime in game.hunters.get_all():
		result[hunter.unique_id] = [hunter.injured, hunter.level, hunter.xp]
	return result


func _total_xp(level: int, xp: int) -> int:
	var total := xp
	for lv in range(1, level):
		total += game.stats.required_xp(lv)
	return total


func _read_json(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return null
	return json.data
