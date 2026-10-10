class_name Town
extends Node2D
## The hub scene (TOWN_DESIGN.md): buildings, the roster walking around, tap a building or a
## Hunter to open its panel (UIRoot), drag to pan, depart on expeditions through the South Gate.

## A building (or &"gate") / a Hunter was tapped; Main opens the matching UI sheet.
signal building_tapped(building_id: StringName)
signal hunter_tapped(hunter: HunterRuntime)
## The departure walk started / failed (e.g. validation changed meanwhile).
signal depart_failed(reason: String)

const HUNTER_SCENE := preload("res://actors/hunter/hunter.tscn")
## A touch that moves less than this is a tap, otherwise a drag.
const TAP_SLOP := 10.0
const SELECT_RADIUS := 18.0
## Spots around the plaza / hospital beds for idle and injured Hunters.
const PLAZA_RING := 30.0
const BED_SPACING := 18.0
const DEPART_TIMEOUT := 4.0
const GATE := &"gate"

@onready var _navigation: NavigationRegion2D = $NavigationRegion2D
@onready var _actors: Node2D = $World/Actors
@onready var _buildings_root: Node2D = $World/Buildings
@onready var _camera: Camera2D = $Camera2D
@onready var _plaza: Marker2D = $Markers/Plaza
@onready var _gate: Marker2D = $Markers/Gate
@onready var _hospital_beds: Marker2D = $Markers/HospitalBeds
@onready var _tavern_door: Marker2D = $Markers/TavernDoor
@onready var _training_yard: Marker2D = $Markers/TrainingYard

var _panel: DebugPanel
## `func(screen_position: Vector2) -> bool`: true when UI covers that point (set by Main).
var input_blocker: Callable = func(_point: Vector2) -> bool: return false
var _hunter_actors: Dictionary[StringName, Hunter] = {}
var _selected_building: StringName = &""
var _selected_hunter: Hunter
var _touch_start := Vector2.ZERO
var _dragging := false
var _touch_on_ui := false
var _departing := false
var _refresh_queued := false


func _ready() -> void:
	# Bake at runtime so buildings and props carve the walkable area.
	_navigation.bake_navigation_polygon(false)
	for runtime in GameManager.hunters.get_all():
		if runtime.expedition_id == &"":
			_spawn_actor(runtime, _home_position(runtime))
	GameManager.hunters.hunter_added.connect(_on_hunter_added)
	GameManager.hunters.hunter_changed.connect(_on_hunter_changed)
	GameManager.buildings.building_upgraded.connect(_on_building_upgraded)
	GameManager.activities.activity_changed.connect(_on_activity_changed)


func setup_debug(panel: DebugPanel) -> void:
	_panel = panel
	_rebuild_panel()


## Coalesces several changes into one panel rebuild at the end of the frame.
func request_refresh() -> void:
	if not _refresh_queued:
		_refresh_queued = true
		_rebuild_panel.call_deferred()


# --- Input -------------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch != null and touch.index == 0:
		if touch.pressed:
			_touch_start = touch.position
			_dragging = false
			_touch_on_ui = input_blocker.call(touch.position)
		elif not _dragging and not _touch_on_ui:
			_on_tap(get_canvas_transform().affine_inverse() * touch.position)
		get_viewport().set_input_as_handled()
		return
	var drag := event as InputEventScreenDrag
	if drag != null and drag.index == 0 and not _touch_on_ui:
		if _dragging or drag.position.distance_to(_touch_start) > TAP_SLOP:
			_dragging = true
			_camera.pan(drag.relative)
		get_viewport().set_input_as_handled()


func _on_tap(world_position: Vector2) -> void:
	if _departing:
		return
	var hunter := _hunter_at(world_position)
	if hunter != null:
		select_hunter(hunter)
		hunter_tapped.emit(hunter.runtime)
		return
	var building_id := _building_at(world_position)
	select_building(building_id)
	if building_id != &"":
		building_tapped.emit(building_id)


## Debug: wipe the save and start over (the town scene is rebuilt).
func _new_game() -> void:
	SaveManager.delete_save()
	GameManager.reset_to_new_game()
	SaveManager.save_game(&"new_game")
	GameManager.request_world(&"town")


func select_building(building_id: StringName) -> void:
	_selected_building = building_id
	_set_selected_hunter(null)
	for building in _buildings():
		building.visual.selected = building.building_id == building_id


func select_hunter(hunter: Hunter) -> void:
	_selected_building = &""
	for building in _buildings():
		building.visual.selected = false
	_set_selected_hunter(hunter)


func _set_selected_hunter(hunter: Hunter) -> void:
	if is_instance_valid(_selected_hunter):
		_selected_hunter.visual.selected = false
	_selected_hunter = hunter
	if hunter != null:
		hunter.visual.selected = true


func _hunter_at(world_position: Vector2) -> Hunter:
	var best: Hunter = null
	var best_distance := SELECT_RADIUS
	for hunter in _hunter_actors.values():
		# Hunters are drawn above their origin; test against the body centre.
		var distance := world_position.distance_to(hunter.global_position + Vector2(0, -14))
		if distance < best_distance:
			best = hunter
			best_distance = distance
	return best


func _building_at(world_position: Vector2) -> StringName:
	if world_position.distance_to(_gate.global_position + Vector2(0, -16)) < 40.0:
		return GATE
	for building in _buildings():
		if building.get_hit_rect().has_point(world_position):
			return building.building_id
	return &""


func _buildings() -> Array[TownBuilding]:
	var result: Array[TownBuilding] = []
	for child in _buildings_root.get_children():
		if child is TownBuilding:
			result.append(child)
	return result


# --- Hunters in town -------------------------------------------------------------------

func _spawn_actor(runtime: HunterRuntime, at: Vector2) -> Hunter:
	var hunter := HUNTER_SCENE.instantiate() as Hunter
	_actors.add_child(hunter)
	hunter.global_position = at
	hunter.setup(runtime, GameManager.hunters, GameManager.combat, DataRegistry.config.retarget_interval, GameManager.equipment)
	_hunter_actors[runtime.unique_id] = hunter
	_send_home(hunter)
	return hunter


## Where a Hunter goes in town (DECISIONS.md D14): resting/socializing at the Tavern,
## training in the Training Yard, injured at the Hospital beds, otherwise the plaza.
func _home_position(runtime: HunterRuntime) -> Vector2:
	var activity := runtime.activity if runtime.expedition_id == &"" else &""
	if runtime.injured:
		activity = ActivityService.RECOVERING
	var same := GameManager.hunters.get_all().filter(func(h: HunterRuntime) -> bool:
		return (ActivityService.RECOVERING if h.injured else h.activity) == activity)
	var index := maxi(same.find(runtime), 0)
	match activity:
		ActivityService.RECOVERING:
			return _hospital_beds.global_position + Vector2((index % 4 - 1.5) * BED_SPACING, 0)
		ActivityService.RESTING:
			return _tavern_door.global_position + Vector2(-30.0 + (index % 3) * 16.0, 6.0 + (index / 3) * 12.0)
		ActivityService.SOCIALIZING:
			return _tavern_door.global_position + Vector2(24.0 + (index % 3) * 14.0, 4.0 + (index / 3) * 12.0)
		ActivityService.TRAINING:
			return _training_yard.global_position + Vector2((index % 3 - 1) * 22.0, (index / 3) * 18.0 - 8.0)
	return _plaza.global_position + Vector2.DOWN.rotated(TAU * index / 6.0) * PLAZA_RING


func _send_home(hunter: Hunter) -> void:
	if hunter.runtime.injured:
		hunter.travel_target = Vector2.INF
		return
	hunter.travel_target = _home_position(hunter.runtime)


func _on_activity_changed(_runtime: HunterRuntime) -> void:
	# Everyone in the same activity may shift spots; re-send all standing Hunters.
	for hunter in _hunter_actors.values():
		_send_home(hunter)


func _on_hunter_added(runtime: HunterRuntime) -> void:
	# New recruits walk out of the Tavern.
	var tavern := _building_node(BuildingService.TAVERN)
	var door := tavern.global_position + Vector2(0, 12) if tavern != null else _plaza.global_position
	_spawn_actor(runtime, door)


func _on_hunter_changed(runtime: HunterRuntime) -> void:
	var hunter: Hunter = _hunter_actors.get(runtime.unique_id)
	if hunter == null:
		return
	if not runtime.injured and hunter.visual.downed:
		# Recovered at the Hospital: get up and walk back to the plaza.
		hunter.revive(hunter.health.max_health)
		_send_home(hunter)


func _building_node(building_id: StringName) -> TownBuilding:
	for building in _buildings():
		if building.building_id == building_id:
			return building
	return null


func _on_building_upgraded(building_id: StringName, _level: int) -> void:
	var building := _building_node(building_id)
	if building != null:
		building.refresh()



# --- Departure through the South Gate (DECISIONS.md D2) --------------------------------

## Walks `party` (default: pick_party) to the South Gate, then starts the expedition.
## Returns the reason if it cannot start.
func depart(expedition_id: StringName, party: Array[StringName] = []) -> String:
	if _departing:
		return "Already departing"
	if party.is_empty():
		party = pick_party()
	var error := GameManager.expeditions.validate(expedition_id, party)
	if not error.is_empty():
		depart_failed.emit(error)
		return error
	_departing = true
	var walkers: Array[Hunter] = []
	for i in party.size():
		var hunter: Hunter = _hunter_actors[party[i]]
		hunter.command_move_to(_gate.global_position + Vector2((i - 1) * 16.0, 0))
		walkers.append(hunter)
	var waited := 0.0
	while waited < DEPART_TIMEOUT and not walkers.all(func(h: Hunter) -> bool: return h.global_position.distance_to(_gate.global_position) < 28.0):
		await get_tree().physics_frame
		waited += get_physics_process_delta_time()
	_departing = false
	if GameManager.expeditions.start(expedition_id, party) == null:
		var reason := GameManager.expeditions.validate(expedition_id, party)
		depart_failed.emit(reason)
		return reason
	return ""


func pick_party() -> Array[StringName]:
	var available := GameManager.hunters.get_all().filter(func(h: HunterRuntime) -> bool:
		return not h.injured and h.state == HunterRuntime.LifecycleState.AVAILABLE)
	available.sort_custom(func(a: HunterRuntime, b: HunterRuntime) -> bool: return a.level > b.level)
	var party: Array[StringName] = []
	for runtime in available.slice(0, DataRegistry.config.max_party_size):
		party.append(runtime.unique_id)
	return party


# --- Debug panel: developer tools only (building/Hunter panels are in UIRoot) -------------

func _rebuild_panel() -> void:
	_refresh_queued = false
	if _panel == null or not is_instance_valid(_panel):
		return
	_panel.clear()
	_panel.add_button_row([
		["Save", func() -> void:
			_panel.add_label("Saved" if SaveManager.save_game(&"manual") else "Save failed")],
		["New game", _new_game],
		["Sandbox", func() -> void: GameManager.request_world(&"sandbox")],
	])
	_panel.add_button_row([
		["+500 gold", func() -> void: GameManager.wallet.add(500)],
		["+1 h", func() -> void: SaveManager.apply_offline_progress(3600.0)],
	])
