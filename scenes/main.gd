extends Node
## Game root (ARCHITECTURE.md → Scene structure).
## GameRoot: non-visual runtime nodes. WorldContainer: active world map / expedition scene. UI: the game
## UI (UIRoot) and the developer debug panel. Switches worlds with a fade and pauses expeditions
## when the app goes to background (D2).

const WORLDS := {
	## The main map (Town + regions, D27).
	&"town": preload("res://world/world/world.tscn"),
	## Combat sandbox for development (debug builds).
	&"sandbox": preload("res://world/test_arena/test_arena.tscn"),
}
const FADE_TIME := 0.35
const RESULT_BANNER_TIME := 2.0
## Shorter absences are not worth a "while you were away" sheet.
const OFFLINE_SHEET_MIN_SECONDS := 60.0

@onready var _world_container: Node2D = $WorldContainer
@onready var _ui: UIRoot = $UI/UIRoot
@onready var _debug_panel := get_node_or_null(^"UI/DebugPanel") as DebugPanel
@onready var _fade: ColorRect = $Transition/Fade
@onready var _banner: Label = $Transition/Banner

var _world: Node
var _switching := false
## Result sheet to show once the town is back.
var _pending_result: ExpeditionRun


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.expeditions.expedition_started.connect(_on_expedition_started)
	GameManager.expeditions.expedition_finished.connect(_on_expedition_finished)
	GameManager.world_change_requested.connect(_on_world_change_requested)
	SaveManager.offline_progress_applied.connect(_on_offline_progress)
	_ui.depart_requested.connect(_on_depart_requested)
	_ui.build_requested.connect(func(building_id: StringName) -> void:
		if _world is WorldMap:
			_world.begin_build(building_id))
	_ui.move_requested.connect(func(instance_id: StringName) -> void:
		if _world is WorldMap:
			_world.begin_move(instance_id))
	_ui.placement_confirmed.connect(func() -> void:
		if _world is WorldMap:
			var error: String = _world.confirm_placement()
			if not error.is_empty():
				_ui.toast(error, true))
	_ui.placement_cancelled.connect(func() -> void:
		if _world is WorldMap:
			_world.cancel_placement())
	_ui.follow_requested.connect(func(unique_id: StringName) -> void:
		if _world is WorldMap and not _world.follow_hunter(unique_id):
			_ui.toast("Not on the map right now", true))
	_ui.recenter_requested.connect(func() -> void:
		if _world is WorldMap and not _world.is_in_dungeon():
			_world.recenter_on_town())
	_ui.focus_region_requested.connect(func(region_id: StringName) -> void:
		if _world is WorldMap and not _world.is_in_dungeon():
			_world.focus_region(region_id))
	_ui.party_picker = func() -> Array:
		return _world.pick_party() if _world is WorldMap else []
	_banner.visible = false
	_fade.color.a = 0.0
	_show_world(WORLDS[&"town"].instantiate())
	if not SaveManager.last_warnings.is_empty():
		_ui.toast("Save: " + "; ".join(SaveManager.last_warnings), true)
	_on_offline_progress(SaveManager.last_offline_summary)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			_set_background(true)
		NOTIFICATION_APPLICATION_RESUMED:
			_set_background(false)
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			if OS.has_feature("mobile"):
				_set_background(true)
		NOTIFICATION_APPLICATION_FOCUS_IN:
			if OS.has_feature("mobile"):
				_set_background(false)


## Expeditions only progress while the app is open (DECISIONS.md D2).
func _set_background(in_background: bool) -> void:
	if GameManager.expeditions.is_running():
		get_tree().paused = in_background


func _on_world_change_requested(world_id: StringName) -> void:
	if WORLDS.has(world_id) and not GameManager.expeditions.is_running():
		_switch_world(WORLDS[world_id].instantiate())


func _on_depart_requested(expedition_id: StringName, party: Array[StringName]) -> void:
	if _world is WorldMap:
		var definition := DataRegistry.get_expedition(expedition_id)
		_ui.toast("The party heads to %s" % definition.display_name)
		_world.depart(expedition_id, party)


## Dungeons run inside the world map (D35); other worlds (sandbox) still switch scenes.
func _on_expedition_started(_run: ExpeditionRun) -> void:
	if _world is WorldMap:
		_world.enter_dungeon()
		_ui.set_mode(UIRoot.Mode.EXPEDITION)
		_rebuild_debug_panel()
		return
	var definition := GameManager.expeditions.get_current_definition()
	var scene := definition.scene.instantiate() as ExpeditionScene
	await _switch_world(scene)
	scene.start(GameManager.expeditions)
	_rebuild_debug_panel()
	_ui.set_mode(UIRoot.Mode.EXPEDITION)


func _on_expedition_finished(run: ExpeditionRun) -> void:
	_pending_result = run
	_banner.text = "VICTORY" if run.phase == ExpeditionRun.Phase.SUCCESS else "DEFEAT"
	_banner.visible = true
	await get_tree().create_timer(RESULT_BANNER_TIME).timeout
	_banner.visible = false
	if _world is WorldMap:
		_world.exit_dungeon(run)
		_ui.set_mode(UIRoot.Mode.TOWN)
		_rebuild_debug_panel()
		_ui.show_message(MessageSheet.for_expedition(run))
		_pending_result = null
		return
	await _switch_world(WORLDS[&"town"].instantiate())


func _switch_world(next_world: Node) -> void:
	while _switching:
		await get_tree().process_frame
	_switching = true
	var tween := create_tween()
	tween.tween_property(_fade, ^"color:a", 1.0, FADE_TIME)
	await tween.finished
	_show_world(next_world)
	tween = create_tween()
	tween.tween_property(_fade, ^"color:a", 0.0, FADE_TIME)
	await tween.finished
	_switching = false


func _show_world(next_world: Node) -> void:
	if _world != null:
		_world.queue_free()
	_world = next_world
	_world_container.add_child(_world)
	if _world is WorldMap:
		_ui.set_mode(UIRoot.Mode.TOWN)
		var map := _world as WorldMap
		map.input_blocker = func(point: Vector2) -> bool:
			return _ui.blocks_point(point) or (_has_debug_panel() and _debug_panel.get_global_rect().has_point(point))
		map.building_tapped.connect(_ui.open_building)
		map.hunter_tapped.connect(_ui.open_hunter)
		map.entrance_tapped.connect(_ui.open_entrance)
		map.placement_changed.connect(_ui.set_placement)
		map.depart_failed.connect(func(reason: String) -> void: _ui.toast(reason, true))
		if _pending_result != null:
			_ui.show_message(MessageSheet.for_expedition(_pending_result))
			_pending_result = null
	elif _world is ExpeditionScene:
		_ui.set_mode(UIRoot.Mode.EXPEDITION)
	else:
		_ui.set_mode(UIRoot.Mode.SANDBOX)
	_rebuild_debug_panel()


func _rebuild_debug_panel() -> void:
	if not _has_debug_panel():
		return
	_debug_panel.clear()
	_debug_panel.set_status("")
	for error in DataRegistry.load_errors:
		_debug_panel.add_label("! " + error)
	if _world != null and _world.has_method(&"setup_debug"):
		_world.setup_debug(_debug_panel)


## "While you were away" sheet (DECISIONS.md D24).
func _on_offline_progress(summary: Dictionary) -> void:
	if float(summary.get("seconds", 0.0)) < OFFLINE_SHEET_MIN_SECONDS:
		return
	if _world is WorldMap and not _ui.has_sheet():
		_ui.show_message(MessageSheet.for_offline(summary))


func _has_debug_panel() -> bool:
	return _debug_panel != null and not _debug_panel.is_queued_for_deletion()
