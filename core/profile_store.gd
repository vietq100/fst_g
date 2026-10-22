class_name ProfileStore
extends RefCounted
## Local player profiles (stand-in for an account login): an index file with the profiles' names and a
## one-line summary of each, and one folder per profile holding its save and backup. The login screen
## (ProfileScreen) lists them; SaveManager works on the selected profile's files.

const INDEX_PATH := "user://profiles.json"
const FOLDER := "user://profiles"
const LEGACY_SAVE := "user://save.json"
const LEGACY_BACKUP := "user://save.bak.json"
const MAX_NAME := 16

## Overridable for tests.
static var index_path := INDEX_PATH
static var folder := FOLDER


## [{id, name, created, played, town, hunters, gold}], most recently played first.
static func list() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in _read().get("profiles", []):
		result.append(entry)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("played", 0.0)) > float(b.get("played", 0.0)))
	return result


static func get_profile(id: String) -> Dictionary:
	for entry in list():
		if entry["id"] == id:
			return entry
	return {}


## A new empty profile; the name is trimmed, cut to MAX_NAME and never empty. Returns its id.
static func create(profile_name: String, preset_id: String = "", limit: int = MAX_NAME) -> String:
	var data := _read()
	var clean := profile_name.strip_edges().left(limit)
	var profiles: Array = data.get("profiles", [])
	if clean.is_empty():
		clean = Loc.t("ui.profile.default_name", {"n": profiles.size() + 1})
	var now := Time.get_unix_time_from_system()
	var id := "p%d" % int(Time.get_ticks_usec() + now * 1000.0)
	profiles.append({"id": id, "name": clean, "created": now, "played": now, "town": 1, "hunters": 0, "gold": 0, "preset": preset_id})
	data["profiles"] = profiles
	_write(data)
	return id


static func rename(id: String, profile_name: String) -> void:
	var data := _read()
	for entry: Dictionary in data.get("profiles", []):
		if entry["id"] == id and not profile_name.strip_edges().is_empty():
			entry["name"] = profile_name.strip_edges().left(MAX_NAME)
	_write(data)


## Removes the profile and its save files.
static func delete(id: String) -> void:
	var data := _read()
	var kept: Array = []
	for entry: Dictionary in data.get("profiles", []):
		if entry["id"] != id:
			kept.append(entry)
	data["profiles"] = kept
	_write(data)
	for path in [save_path(id), backup_path(id), save_path(id) + SaveManager.TEMP_SUFFIX]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	if DirAccess.dir_exists_absolute(folder.path_join(id)):
		DirAccess.remove_absolute(folder.path_join(id))


## Updates the summary shown on the profile card and the last-played time.
static func touch(id: String, town_level: int, hunters: int, gold: int) -> void:
	var data := _read()
	for entry: Dictionary in data.get("profiles", []):
		if entry["id"] == id:
			entry["played"] = Time.get_unix_time_from_system()
			entry["town"] = town_level
			entry["hunters"] = hunters
			entry["gold"] = gold
	_write(data)


static func save_path(id: String) -> String:
	return folder.path_join(id).path_join("save.json")


static func backup_path(id: String) -> String:
	return folder.path_join(id).path_join("save.bak.json")


## A save made before profiles existed becomes the first profile.
static func migrate_legacy() -> void:
	if not list().is_empty() or not (FileAccess.file_exists(LEGACY_SAVE) or FileAccess.file_exists(LEGACY_BACKUP)):
		return
	var id := create(Loc.t("ui.profile.default_name", {"n": 1}))
	DirAccess.make_dir_recursive_absolute(folder.path_join(id))
	for pair: Array in [[LEGACY_SAVE, save_path(id)], [LEGACY_BACKUP, backup_path(id)]]:
		if FileAccess.file_exists(pair[0]):
			DirAccess.copy_absolute(pair[0], pair[1])
			DirAccess.remove_absolute(pair[0])


static func _read() -> Dictionary:
	var file := FileAccess.open(index_path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


static func _write(data: Dictionary) -> void:
	var file := FileAccess.open(index_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
