extends Node
## Audio autoload (AUDIO_DESIGN.md, D78): plays the synthesized sound effects and music.
## - Buses Music and SFX (created when missing), their volumes saved in the settings file.
## - Sound effects render on first use (SoundSynth) and are cached. Each keeps its `cooldown`, so hits and
##   clicks never pile up; world sounds play only near the screen, quieter towards its edge, with a slight
##   pitch variation.
## - Music tracks render on a worker thread the first time they are wanted, then loop; changing track
##   fades out the old one and in the new one.

const SFX_PATH := "res://data/audio/sfx.json"
const MUSIC_PATH := "res://data/audio/music.json"
const SETTINGS_PATH := "user://settings.cfg"
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"
## Volumes 0..1 when nothing is saved.
const DEFAULT_VOLUMES := {MUSIC_BUS: 0.6, SFX_BUS: 0.8}
## Sound effect players: more at once are dropped.
const VOICES := 12
## World sounds this far outside the screen (fraction of its size) are not played; at the screen edge
## they are EDGE_DB quieter than at its centre.
const OFF_SCREEN := 0.2
const EDGE_DB := -8.0
## Random pitch spread of world sounds.
const PITCH_JITTER := 0.05
const MUSIC_FADE := 1.2
## Music volume in dB at full slider (the tracks are normalised loud).
const MUSIC_DB := -6.0

var _recipes: Dictionary = {}
var _tracks: Dictionary = {}
var _streams: Dictionary = {}
var _last_played: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
## Rendered music: track id -> AudioStreamWAV.
var _music_streams: Dictionary = {}
var _music: Array[AudioStreamPlayer] = []
## Index in _music of the player of the current track.
var _music_front := 0
var _wanted_track: StringName = &""
var _playing_track: StringName = &""
var _thread: Thread
var _rendering: StringName = &""
var _fade_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus(MUSIC_BUS)
	_ensure_bus(SFX_BUS)
	_recipes = _load_json(SFX_PATH)
	_tracks = _load_json(MUSIC_PATH)
	for bus: StringName in DEFAULT_VOLUMES:
		_apply_volume(bus, get_volume(bus))
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		player.bus = SFX_BUS
		add_child(player)
		_players.append(player)
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = MUSIC_BUS
		player.volume_db = -80.0
		add_child(player)
		_music.append(player)


func _exit_tree() -> void:
	if _thread != null and _thread.is_started():
		_thread.wait_to_finish()


# --- Sound effects ----------------------------------------------------------------------------------


## Plays a sound effect (sfx.json id). `at` (world position) makes it a world sound: skipped off screen,
## quieter near the edge, pitch varied. Returns whether it played.
func play(id: StringName, at: Vector2 = Vector2.INF) -> bool:
	var recipe: Dictionary = _recipes.get(String(id), {})
	if recipe.is_empty():
		return false
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_played.get(id, -INF)) < float(recipe.get("cooldown", 0.0)):
		return false
	var volume_db: float = recipe.get("volume_db", 0.0)
	var pitch := 1.0
	if at != Vector2.INF:
		var falloff := _screen_falloff(at)
		if falloff < 0.0:
			return false
		volume_db += EDGE_DB * falloff
		pitch = randf_range(1.0 - PITCH_JITTER, 1.0 + PITCH_JITTER)
	var player := _free_player()
	if player == null:
		return false
	_last_played[id] = now
	player.stream = _stream(id, recipe)
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()
	return true


## A UI sound (no position).
func play_ui(id: StringName) -> bool:
	return play(id)


## 0 at the screen centre → 1 at its edge; -1 when too far outside to be heard.
func _screen_falloff(at: Vector2) -> float:
	var viewport := get_viewport()
	if viewport == null:
		return 0.0
	var screen := viewport.get_canvas_transform() * at
	var rect := viewport.get_visible_rect()
	if not rect.grow(rect.size.x * OFF_SCREEN).has_point(screen):
		return -1.0
	var half := rect.size * 0.5
	var offset := (screen - rect.get_center()).abs() / half
	return clampf(maxf(offset.x, offset.y), 0.0, 1.0)


func _free_player() -> AudioStreamPlayer:
	for i in _players.size():
		var player := _players[(_next_player + i) % _players.size()]
		if not player.playing:
			_next_player = (_next_player + i + 1) % _players.size()
			return player
	return null


func _stream(id: StringName, recipe: Dictionary) -> AudioStreamWAV:
	if not _streams.has(id):
		_streams[id] = SoundSynth.sfx_stream(recipe)
	return _streams[id]


func has_sound(id: StringName) -> bool:
	return _recipes.has(String(id))


# --- Music --------------------------------------------------------------------------------------------


## Wanted music track (music.json id; &"" = silence). Renders it in the background the first time.
func set_music(track: StringName) -> void:
	if track == _wanted_track:
		return
	_wanted_track = track
	if track == &"" or _music_streams.has(track):
		_switch_music()
	else:
		_render_next()


func get_music() -> StringName:
	return _wanted_track


func _process(_delta: float) -> void:
	if _rendering == &"" or _thread == null or _thread.is_alive():
		return
	var samples: PackedFloat32Array = _thread.wait_to_finish()
	_thread = null
	var done := _rendering
	_rendering = &""
	_music_streams[done] = SoundSynth.to_stream(samples, SoundSynth.MUSIC_PEAK, true)
	if done == _wanted_track:
		_switch_music()
	else:
		_render_next()


## Starts rendering the wanted track on the worker thread (one at a time).
func _render_next() -> void:
	if _rendering != &"" or _wanted_track == &"" or _music_streams.has(_wanted_track):
		return
	var track: Dictionary = _tracks.get(String(_wanted_track), {})
	if track.is_empty():
		return
	_rendering = _wanted_track
	_thread = Thread.new()
	_thread.start(func() -> PackedFloat32Array: return SoundSynth.render_track(track))


func _switch_music() -> void:
	if _wanted_track == _playing_track:
		return
	_playing_track = _wanted_track
	if _fade_tween != null:
		_fade_tween.kill()
	# Cross-fade: the new track rises while the old one falls, then the old one stops.
	_fade_tween = create_tween().set_parallel(true)
	var old := _music[_music_front]
	if _wanted_track != &"":
		_music_front = 1 - _music_front
		var player := _music[_music_front]
		player.stream = _music_streams[_wanted_track]
		player.volume_db = -40.0
		player.play()
		_fade_tween.tween_property(player, ^"volume_db", MUSIC_DB, MUSIC_FADE)
	if old.playing:
		_fade_tween.tween_property(old, ^"volume_db", -80.0, MUSIC_FADE)
		_fade_tween.chain().tween_callback(old.stop)


# --- Volumes ------------------------------------------------------------------------------------------


## Volume 0..1 of a bus (MUSIC_BUS or SFX_BUS), as saved.
func get_volume(bus: StringName) -> float:
	var config := ConfigFile.new()
	var fallback: float = DEFAULT_VOLUMES.get(bus, 1.0)
	if config.load(SETTINGS_PATH) != OK:
		return fallback
	return clampf(float(config.get_value("audio", String(bus), fallback)), 0.0, 1.0)


## Sets and saves a bus volume (0 = muted).
func set_volume(bus: StringName, value: float) -> void:
	value = clampf(value, 0.0, 1.0)
	_apply_volume(bus, value)
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("audio", String(bus), value)
	config.save(SETTINGS_PATH)


func _apply_volume(bus: StringName, value: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		return
	AudioServer.set_bus_mute(index, value <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.0001)))


func _ensure_bus(bus: StringName) -> void:
	if AudioServer.get_bus_index(bus) >= 0:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus)
	AudioServer.set_bus_send(index, &"Master")


static func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Audio: missing %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
