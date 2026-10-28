class_name WorldMap
extends Node2D
## The main map (WORLD_DESIGN.md, DECISIONS.md D52, D28, D33): top-down grid with the Town
## (top-left), Ancient Ruins (top-right), Dark Forest (bottom-left) and Goblin Cave (bottom-right),
## joined by bridges; dungeon entrances on rock ledges off the outer edges.
## The screen is a camera over it: drag to pan, pinch / wheel to zoom, tap a Hunter to follow.
## Buildings mirror BuildingService; placement mode previews a ghost and asks UIRoot to confirm.

## A placed building / a Hunter / a dungeon entrance was tapped; Main opens the matching sheet.
signal building_tapped(instance_id: StringName)
signal hunter_tapped(hunter: HunterRuntime)
## A monster in a hunting region was tapped (opens its info).
signal monster_tapped(monster: Enemy)
signal entrance_tapped(expedition_id: StringName)
## The Hunter Gate or the Boss Arena altar was tapped (D58): the region's id.
signal structure_tapped(region_id: StringName)
## The departure walk failed (e.g. validation changed meanwhile).
signal depart_failed(reason: String)
## The camera left (true) or came back over (false) the Town: the UI offers the way back.
signal camera_away_changed(away: bool)
## Placement preview moved / started / ended. `active` false = placement mode closed.
## `reason` is empty when the ghost can be placed where it is.
signal placement_changed(active: bool, title: String, reason: String)

const HUNTER_SCENE := preload("res://actors/hunter/hunter.tscn")
## A touch that moves less than this is a tap, otherwise a drag.
const TAP_SLOP := 10.0
const SELECT_RADIUS := 18.0
const PLAZA_RING := 34.0
const BED_SPACING := 18.0
## Longest walk to a dungeon entrance before the party gives up.
const DEPART_TIMEOUT := 90.0
## The dungeon instance sits this far right of the map's bounds (outside the camera's range).
const DUNGEON_GAP := 400.0
## Props keep this many tiles away from gates and dungeon entrances.
const PROP_CLEARANCE := 3
const PROP_SEED := 20261011
## Props closer than this leave slivers in the baked navigation mesh; keep them apart.
const PROP_SPACING := 34.0
const START_ZOOM := 0.6
## The zoom-out limit shows the whole Town plus this much more (1.25 = a quarter).
const ZOOM_OUT_MARGIN := 1.25
const CARRIER_CHECK_INTERVAL := 1.0
## A sleeping Hunter this close to its House door goes inside (hidden).
const ENTER_DISTANCE := 10.0

var input_blocker: Callable = func(_point: Vector2) -> bool: return false
var world: WorldService

var _navigation: NavigationRegion2D
var _ground: Node2D
var _day_night: DayNight
var _weather: WeatherLayer
var _audio: AudioFeedback
var _entities: Node2D
var _buildings_root: Node2D
var _actors: Node2D
var _camera: WorldCamera
## Camera-away polling (see _poll_camera_away): world px past the Town's bounds that still count as home.
const AWAY_MARGIN := 80.0
const AWAY_POLL := 0.25
var _away_timer := 0.0
var _camera_away := false
var _panel: DebugPanel
var _building_nodes: Dictionary[StringName, TownBuilding] = {}
var _entrances: Array[DungeonEntrance] = []
## Hunter Gate and Boss Arena altar (D58): region id → node with `hit_test`.
var _structures: Dictionary[StringName, Node2D] = {}
var _spawners: Dictionary[StringName, RegionSpawner] = {}
var _drops: Array[LootDrop] = []
## Town decorations (lamps, fountain, benches…), hidden while a building stands on them.
var _decor: Array[TownDecor] = []
var _staff: Dictionary[StringName, StaffWorker] = {}
## Gate centres and dungeon entrances: monsters do not spawn next to them.
var _keep_clear_points: Array[Vector2] = []
var _hunter_actors: Dictionary[StringName, Hunter] = {}
## Summoned newcomers waiting to come down at the Gate (D83), in order.
var _arrivals: Array[HunterRuntime] = []
var _arrival_playing := false
var _shake: CameraShake
## Height (px) a newcomer drops from, and the pause between two arrivals (s).
const ARRIVAL_DROP := 88.0
const ARRIVAL_GAP := 0.45
var _selected_building: StringName = &""
var _selected_hunter: Hunter
## Active touches (index → screen position) for drag / pinch.
var _touches: Dictionary[int, Vector2] = {}
var _touch_start := Vector2.ZERO
var _dragging := false
var _touch_on_ui := false
var _departing := false
var _dungeon: ExpeditionScene
var _refresh_queued := false
var _bake_queued := false
var _replan_queued := false
var _carrier_check_in := 0.0
## Body id -> seconds without any possible carrier.
var _unattended: Dictionary[StringName, float] = {}
## Placement mode (D33): &"build" or &"move"; empty when off.
var _placing: StringName = &""
var _placing_building: StringName = &""
var _placing_instance: StringName = &""
var _placing_tile := Vector2i.ZERO
var _ghost: BuildingVisual


func _ready() -> void:
	world = GameManager.world
	_build_scene()
	for placed in GameManager.buildings.get_instances():
		_spawn_building(placed)
	_spawn_props()
	_bake_navigation()
	# Spawners need the synced navigation map to pick spawn points.
	await _navigation_synced()
	_spawn_regions()
	_spawn_staff()
	for runtime in GameManager.hunters.get_all():
		if runtime.expedition_id == &"":
			var outside := (runtime.task != &"" or not runtime.alive) and not runtime.injured and world.region_at(runtime.world_position) != null
			_spawn_actor(runtime, runtime.world_position if outside else get_home_position(runtime))
	var buildings := GameManager.buildings
	buildings.building_placed.connect(_spawn_building)
	buildings.building_moved.connect(_on_building_moved)
	buildings.building_removed.connect(_on_building_removed)
	buildings.building_upgraded.connect(_on_building_upgraded)
	buildings.layout_changed.connect(_on_layout_changed)
	GameManager.hunters.hunter_added.connect(_on_hunter_added)
	GameManager.hunters.hunter_removed.connect(_on_hunter_removed)
	GameManager.hunters.hunter_changed.connect(_on_hunter_changed)
	GameManager.activities.activity_changed.connect(_on_activity_changed)
	GameManager.corpses.body_delivered.connect(_on_body_delivered)
	GameManager.combat.monster_skill_cast.connect(_on_monster_skill_cast)
	GameManager.combat.skill_cast.connect(_on_class_skill_cast)


func _build_scene() -> void:
	_ground = Node2D.new()
	_ground.name = "Ground"
	_ground.set_script(preload("res://world/world/world_ground.gd"))
	add_child(_ground)
	var plaza := _town_plaza()
	var ledges: Array[Vector2i] = []
	for definition in DataRegistry.get_all(&"expedition"):
		var expedition := definition as ExpeditionDefinition
		if expedition.region_id != &"":
			ledges.append(expedition.entrance_tile)
	_ground.setup(world, _town_roads(plaza), plaza, world.get_town_pond(), ledges)
	var shimmer := WaterShimmer.new()
	shimmer.name = "WaterShimmer"
	shimmer.setup(world)
	add_child(shimmer)
	_day_night = DayNight.new()
	_day_night.name = "DayNight"
	add_child(_day_night)
	_day_night.setup(world)
	_weather = WeatherLayer.new()
	_weather.name = "WeatherLayer"
	add_child(_weather)
	RenderingServer.set_default_clear_color(Color("12394a"))
	_navigation = NavigationRegion2D.new()
	_navigation.name = "NavigationRegion2D"
	var polygon := NavigationPolygon.new()
	for outline in world.navigation_outlines():
		polygon.add_outline(outline)
	polygon.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	polygon.source_geometry_mode = NavigationPolygon.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	polygon.source_geometry_group_name = &"navigation_obstacles"
	polygon.agent_radius = 7.0
	_navigation.navigation_polygon = polygon
	add_child(_navigation)
	_entities = _y_sorted("Entities", self)
	var feedback := CombatFeedback.new()
	feedback.name = "CombatFeedback"
	add_child(feedback)
	_audio = AudioFeedback.new()
	_audio.name = "AudioFeedback"
	_audio.setup(world)
	add_child(_audio)
	_buildings_root = _y_sorted("Buildings", _entities)
	var props := _y_sorted("Props", _entities)
	props.add_to_group(&"world_props")
	_actors = _y_sorted("Actors", _entities)
	for gate in world.get_gates():
		var arch := GateVisual.new()
		arch.setup(gate)
		_entities.add_child(arch)
		_keep_clear_points.append(gate.center)
	for definition in DataRegistry.get_all(&"expedition"):
		var expedition := definition as ExpeditionDefinition
		if expedition.region_id == &"":
			continue
		var entrance := DungeonEntrance.new()
		entrance.setup(expedition)
		_entities.add_child(entrance)
		_entrances.append(entrance)
		_keep_clear_points.append(entrance.position)
	for region in world.get_regions():
		var structure: Node2D = null
		if region.kind == RegionDefinition.Kind.GATE:
			structure = HunterGateVisual.new()
		elif region.kind == RegionDefinition.Kind.BOSS:
			structure = BossAltarVisual.new()
		elif region.kind == RegionDefinition.Kind.MOUNT:
			structure = HibernationMountVisual.new()
		if structure == null:
			continue
		structure.position = world.region_center(region)
		_entities.add_child(structure)
		_structures[region.id] = structure
		_keep_clear_points.append(structure.position)
	_camera = WorldCamera.new()
	_camera.name = "Camera"
	_camera.bounds = world.get_bounds(96.0)
	_camera.zoom = Vector2(START_ZOOM, START_ZOOM)
	_camera.position = world.region_center(world.get_town())
	add_child(_camera)
	_update_zoom_limit()
	get_viewport().size_changed.connect(_update_zoom_limit)
	_ghost = BuildingVisual.new()
	_ghost.ghost = true
	_ghost.visible = false
	_ghost.z_index = 10
	add_child(_ghost)


func _y_sorted(node_name: String, parent: Node) -> Node2D:
	var node := Node2D.new()
	node.name = node_name
	node.y_sort_enabled = true
	parent.add_child(node)
	return node


func get_camera() -> WorldCamera:
	return _camera


func setup_debug(panel: DebugPanel) -> void:
	_panel = panel
	_rebuild_panel()


## Coalesces several changes into one panel rebuild at the end of the frame.
func request_refresh() -> void:
	if not _refresh_queued:
		_refresh_queued = true
		_rebuild_panel.call_deferred()


# --- Input: tap, drag, pinch, wheel ----------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch != null:
		_on_touch(touch)
		get_viewport().set_input_as_handled()
		return
	var drag := event as InputEventScreenDrag
	if drag != null:
		_on_drag(drag)
		get_viewport().set_input_as_handled()
		return
	var button := event as InputEventMouseButton
	if button != null and button.pressed and not input_blocker.call(button.position):
		if button.button_index == MOUSE_BUTTON_WHEEL_UP:
			_camera.zoom_at(WorldCamera.WHEEL_STEP, button.position)
		elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_camera.zoom_at(1.0 / WorldCamera.WHEEL_STEP, button.position)
		return
	var magnify := event as InputEventMagnifyGesture
	if magnify != null:
		if not input_blocker.call(magnify.position):
			_camera.zoom_at(magnify.factor, magnify.position)
		return
	var pan := event as InputEventPanGesture
	if pan != null and not input_blocker.call(pan.position):
		_camera.pan(-pan.delta * 8.0)


func _on_touch(touch: InputEventScreenTouch) -> void:
	if touch.pressed:
		_touches[touch.index] = touch.position
		if _touches.size() == 1:
			_touch_start = touch.position
			_dragging = false
			_touch_on_ui = input_blocker.call(touch.position)
		else:
			# A second finger turns the gesture into a pinch, never a tap.
			_dragging = true
		return
	# A release without a tracked press belongs to UI that took the press (a dialog's list or button):
	# it must never turn into a tap on the map under it. A release over UI is never a tap either.
	var tracked := _touches.has(touch.index)
	_touches.erase(touch.index)
	if tracked and touch.index == 0 and not _dragging and not _touch_on_ui and not input_blocker.call(touch.position):
		_on_tap(screen_to_world(touch.position))


func _on_drag(drag: InputEventScreenDrag) -> void:
	if _touch_on_ui or not _touches.has(drag.index):
		return
	if _touches.size() >= 2:
		var other_index := -1
		for index in _touches:
			if index != drag.index:
				other_index = index
				break
		var other := _touches[other_index]
		var before := other.distance_to(_touches[drag.index])
		_touches[drag.index] = drag.position
		var after := other.distance_to(drag.position)
		if before > 1.0:
			_camera.zoom_at(after / before, (other + drag.position) * 0.5)
		return
	_touches[drag.index] = drag.position
	if _dragging or drag.position.distance_to(_touch_start) > TAP_SLOP:
		_dragging = true
		_camera.pan(drag.relative)


func screen_to_world(screen_point: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * screen_point


func _on_tap(world_position: Vector2) -> void:
	if _placing != &"":
		_set_ghost_tile(_anchor_for(world_position, _ghost.footprint))
		return
	if _departing:
		return
	var hunter := _hunter_at(world_position)
	if hunter != null:
		select_hunter(hunter)
		follow_hunter(hunter.runtime.unique_id)
		hunter_tapped.emit(hunter.runtime)
		return
	var monster := _monster_at(world_position)
	if monster != null:
		select_building(&"")
		monster_tapped.emit(monster)
		return
	for entrance in _entrances:
		if entrance.hit_test(world_position):
			select_building(&"")
			entrance_tapped.emit(entrance.expedition_id)
			return
	for region_id in _structures:
		if _structures[region_id].hit_test(world_position):
			select_building(&"")
			structure_tapped.emit(region_id)
			return
	var instance_id := _building_at(world_position)
	select_building(instance_id)
	if instance_id != &"":
		building_tapped.emit(instance_id)


## Debug: wipe the save and start over (the world scene is rebuilt).
func _new_game() -> void:
	SaveManager.delete_save()
	GameManager.reset_to_new_game()
	SaveManager.save_game(&"new_game")
	GameManager.request_world(&"town")


func select_building(instance_id: StringName) -> void:
	_selected_building = instance_id
	_set_selected_hunter(null)
	for id in _building_nodes:
		_building_nodes[id].visual.selected = id == instance_id


func select_hunter(hunter: Hunter) -> void:
	_selected_building = &""
	for node in _building_nodes.values():
		node.visual.selected = false
	_set_selected_hunter(hunter)


## Camera follows this Hunter until the player drags (D28). Returns false if not in the world.
func follow_hunter(unique_id: StringName) -> bool:
	var hunter: Hunter = _hunter_actors.get(unique_id)
	if hunter == null:
		return false
	_camera.follow(hunter)
	return true


## The HUD covers `top` px above and `bottom` px below the map: the camera may scroll that far.
func set_view_insets(top: float, bottom: float) -> void:
	_camera.inset_top = top
	_camera.inset_bottom = bottom
	_update_zoom_limit()
	_camera.clamp_to_bounds()


## Zooming out stops a little beyond the whole Town (ZOOM_OUT_MARGIN) instead of showing the open sea.
func _update_zoom_limit() -> void:
	var area := _town_bounds()
	if area.size == Vector2.ZERO:
		return
	_camera.limit_zoom_out_to(area, ZOOM_OUT_MARGIN)


## Bounding box (world px) of the Town's outline; empty before the Town has a shape.
func _town_bounds() -> Rect2:
	var outline := world.region_outline(world.get_town())
	if outline.is_empty():
		return Rect2()
	var area := Rect2(outline[0], Vector2.ZERO)
	for point in outline:
		area = area.expand(point)
	return area


## Navigation "Town": camera back over the Town at normal zoom.
func recenter_on_town() -> void:
	_camera.zoom = Vector2(START_ZOOM, START_ZOOM)
	_camera.center_on(world.region_center(world.get_town()))


## Hex buttons I / II / III: camera over a hunting region.
func focus_region(region_id: StringName) -> void:
	var region := world.get_region(region_id)
	if region == null:
		return
	_camera.zoom = Vector2(START_ZOOM, START_ZOOM)
	_camera.center_on(world.region_center(region))


func get_hunter_actor(unique_id: StringName) -> Hunter:
	return _hunter_actors.get(unique_id)


func get_building_node(instance_id: StringName) -> TownBuilding:
	return _building_nodes.get(instance_id)


func _set_selected_hunter(hunter: Hunter) -> void:
	if is_instance_valid(_selected_hunter):
		_selected_hunter.visual.selected = false
	_selected_hunter = hunter
	if hunter != null:
		hunter.visual.selected = true


## Nearest living region monster under the tap (hit radius in screen terms, like Hunters).
func _monster_at(world_position: Vector2) -> Enemy:
	var best: Enemy = null
	var best_distance := SELECT_RADIUS / _camera.zoom.x * 0.7
	for spawner: RegionSpawner in _spawners.values():
		for enemy in spawner.get_monsters():
			var distance := world_position.distance_to(enemy.global_position + Vector2(0, -12))
			if distance < best_distance:
				best = enemy
				best_distance = distance
	# Monsters inside a running dungeon can be inspected too.
	if _dungeon != null:
		for enemy in _dungeon.get_enemies():
			var distance := world_position.distance_to(enemy.global_position + Vector2(0, -12))
			if distance < best_distance:
				best = enemy
				best_distance = distance
	return best


func _hunter_at(world_position: Vector2) -> Hunter:
	var best: Hunter = null
	# Hit radius is in screen terms: the farther out the camera, the larger in world px.
	var best_distance := SELECT_RADIUS / _camera.zoom.x * 0.6
	for hunter: Hunter in _hunter_actors.values():
		if not hunter.visible:
			continue
		# Hunters are drawn above their origin; test against the body centre.
		var distance := world_position.distance_to(hunter.global_position + Vector2(0, -14))
		if distance < best_distance:
			best = hunter
			best_distance = distance
	return best


## Front-most building under the point (largest y first, matching the draw order).
func _building_at(world_position: Vector2) -> StringName:
	var nodes := _building_nodes.values()
	nodes.sort_custom(func(a: TownBuilding, b: TownBuilding) -> bool: return a.position.y > b.position.y)
	for node: TownBuilding in nodes:
		if node.hit_test(world_position):
			return node.instance_id
	return &""


# --- Buildings (BuildingService mirror) --------------------------------------------------------

func _spawn_building(placed: BuildingService.Placed) -> void:
	var node := TownBuilding.new()
	node.setup(placed, GameManager.buildings.get_definition(placed.building_id))
	_buildings_root.add_child(node)
	_building_nodes[placed.instance_id] = node


func _on_building_moved(placed: BuildingService.Placed) -> void:
	var node: TownBuilding = _building_nodes.get(placed.instance_id)
	if node != null:
		node.refresh(placed)


func _on_building_removed(placed: BuildingService.Placed) -> void:
	var node: TownBuilding = _building_nodes.get(placed.instance_id)
	_building_nodes.erase(placed.instance_id)
	if node != null:
		node.queue_free()
	if _selected_building == placed.instance_id:
		_selected_building = &""


func _on_building_upgraded(building_id: StringName, _level: int) -> void:
	for placed in GameManager.buildings.get_instances_of(building_id):
		_on_building_moved(placed)


func _on_layout_changed() -> void:
	_refresh_decor()
	# Removed nodes leave the tree at the end of the frame; bake after that.
	if not _bake_queued:
		_bake_queued = true
		_rebake.call_deferred()


func _rebake() -> void:
	_bake_queued = false
	if not _navigation.is_baking():
		_navigation.bake_navigation_polygon(false)
	for hunter in _hunter_actors.values():
		_send_home(hunter)


func _building_node(building_id: StringName) -> TownBuilding:
	var placed := GameManager.buildings.find_first(building_id)
	return _building_nodes.get(placed.instance_id) if placed != null else null


# --- Placement mode (D33) ----------------------------------------------------------------------

func is_placing() -> bool:
	return _placing != &""


## Starts previewing a new building at the screen centre.
func begin_build(building_id: StringName) -> void:
	var definition := GameManager.buildings.get_definition(building_id)
	if definition == null:
		return
	var anchor := _anchor_for(_camera.global_position, definition.footprint)
	_start_placement(&"build", building_id, &"", definition, _nearest_free_tile(building_id, anchor))


## Starts moving an existing building; it stays put until confirmed.
func begin_move(instance_id: StringName) -> void:
	var placed := GameManager.buildings.get_instance(instance_id)
	if placed == null:
		return
	var definition := GameManager.buildings.get_definition(placed.building_id)
	var node: TownBuilding = _building_nodes.get(instance_id)
	if node != null:
		node.visual.modulate.a = 0.35
	_start_placement(&"move", placed.building_id, instance_id, definition, placed.tile)


func _start_placement(mode: StringName, building_id: StringName, instance_id: StringName,
		definition: BuildingDefinition, tile: Vector2i) -> void:
	cancel_placement()
	select_building(&"")
	_placing = mode
	_placing_building = building_id
	_placing_instance = instance_id
	_ghost.building_id = building_id
	_ghost.footprint = definition.footprint
	_ghost.visible = true
	_set_ghost_tile(tile)


func _set_ghost_tile(tile: Vector2i) -> void:
	_placing_tile = tile
	_ghost.position = TownBuilding.origin_for(tile, _ghost.footprint)
	var reason := get_placement_reason()
	_ghost.ghost_valid = reason.is_empty()
	var definition := GameManager.buildings.get_definition(_placing_building)
	var title := Loc.t("world.placement.build", {"name": definition.display_name}) if _placing == &"build" \
			else Loc.t("world.placement.move", {"name": definition.display_name})
	placement_changed.emit(true, title, reason)


## Empty when the ghost can be placed at its current tile.
func get_placement_reason() -> String:
	var buildings := GameManager.buildings
	if _placing == &"build":
		var reason := buildings.can_build(_placing_building)
		if not reason.is_empty():
			return reason
	return buildings.can_place(_placing_building, _placing_tile, _placing_instance)


## Builds / moves at the ghost tile. Returns the error ("" = done, placement mode closed).
func confirm_placement() -> String:
	if _placing == &"":
		return Loc.t("world.placement.nothing")
	var buildings := GameManager.buildings
	var error := ""
	if _placing == &"build":
		error = get_placement_reason()
		if error.is_empty() and buildings.build(_placing_building, _placing_tile) == null:
			error = Loc.t("world.placement.cannot_build")
	else:
		error = buildings.move(_placing_instance, _placing_tile)
	if error.is_empty():
		cancel_placement()
	return error


func cancel_placement() -> void:
	if _placing == &"":
		return
	var node: TownBuilding = _building_nodes.get(_placing_instance)
	if node != null:
		node.visual.modulate.a = 1.0
	_placing = &""
	_placing_building = &""
	_placing_instance = &""
	_ghost.visible = false
	placement_changed.emit(false, "", "")


## The free anchor closest to `anchor` (or `anchor` itself if the Town is full).
func _nearest_free_tile(building_id: StringName, anchor: Vector2i) -> Vector2i:
	var buildings := GameManager.buildings
	var town := world.get_town().tile_rect
	var best := anchor
	var best_distance := INF
	for gx in range(town.position.x, town.end.x):
		for gy in range(town.position.y, town.end.y):
			var tile := Vector2i(gx, gy)
			var distance := Vector2(tile - anchor).length_squared()
			if distance < best_distance and buildings.can_place(building_id, tile).is_empty():
				best = tile
				best_distance = distance
	return best


## Anchor tile so the footprint is centred on a world point.
func _anchor_for(world_point: Vector2, footprint: Vector2i) -> Vector2i:
	var tile := WorldService.world_to_tile(world_point) - Vector2(footprint) * 0.5
	return Vector2i(roundi(tile.x), roundi(tile.y))


# --- Props and roads -----------------------------------------------------------------------------

func _spawn_props() -> void:
	var props := _entities.get_node(^"Props") as Node2D
	var rng := RandomNumberGenerator.new()
	rng.seed = PROP_SEED
	var keep_clear: Array[Rect2i] = []
	for gate in world.get_gates():
		keep_clear.append(gate.tiles.grow(PROP_CLEARANCE))
	for region in world.get_regions():
		if region.kind == RegionDefinition.Kind.GATE or region.kind == RegionDefinition.Kind.BOSS or region.kind == RegionDefinition.Kind.MOUNT:
			var centre := WorldService.tile_at(world.region_center(region))
			keep_clear.append(Rect2i(centre, Vector2i.ONE).grow(PROP_CLEARANCE + 1))
	for definition in DataRegistry.get_all(&"expedition"):
		var expedition := definition as ExpeditionDefinition
		if expedition.region_id != &"":
			keep_clear.append(Rect2i(expedition.entrance_tile, Vector2i.ONE).grow(PROP_CLEARANCE))
	var placed: Array[Vector2] = []
	_spawn_pond_obstacle(props)
	_spawn_town_border(props, rng, placed)
	_spawn_town_decor(props)
	_spawn_landmarks(props, keep_clear, placed)
	_spawn_ambience(_spawn_scenery(props))
	for region in world.get_regions():
		if region.props == RegionDefinition.Props.NONE or region.prop_density <= 0.0:
			continue
		var rect := region.tile_rect
		var ground := world.region_tiles(region.id)
		for gx in range(rect.position.x, rect.end.x):
			for gy in range(rect.position.y, rect.end.y):
				var roll := rng.randf()
				var offset := Vector2(rng.randf_range(0.2, 0.8), rng.randf_range(0.2, 0.8))
				var scale := rng.randf_range(0.8, 1.2)
				if roll >= region.prop_density:
					continue
				var tile := Vector2i(gx, gy)
				if not ground.has(tile):
					continue
				if keep_clear.any(func(r: Rect2i) -> bool: return r.has_point(tile)):
					continue
				var at := WorldService.tile_to_world(Vector2(tile) + offset)
				if placed.any(func(other: Vector2) -> bool: return other.distance_to(at) < PROP_SPACING):
					continue
				placed.append(at)
				var prop := WorldProp.new()
				prop.position = at
				prop.size = scale
				match region.props:
					RegionDefinition.Props.TREES:
						prop.kind = WorldProp.Kind.PINE
						prop.tint = Color("1f4a3a").lerp(Color("2d5e40"), rng.randf())
					RegionDefinition.Props.ROCKS:
						prop.kind = WorldProp.Kind.ROCK
						prop.tint = Color("6b5f52").lerp(Color("7d7062"), rng.randf())
					RegionDefinition.Props.COLUMNS:
						prop.kind = WorldProp.Kind.COLUMN
						prop.tint = Color("b9b4a3").lerp(Color("cfcab8"), rng.randf())
				props.add_child(prop)


## Landmarks inside the hunting regions (D62 on the isometric map, D75), by biome: [kind, position as
## a fraction of the region's tile rect, tile offset]. Goblin camps are tents around a campfire.
const LANDMARKS := {
	RegionDefinition.Props.TREES: [
		[WorldLandmark.Kind.SHRINE, Vector2(0.5, 0.45), Vector2.ZERO],
		[WorldLandmark.Kind.STUMP, Vector2(0.3, 0.7), Vector2.ZERO], [WorldLandmark.Kind.STUMP, Vector2(0.72, 0.35), Vector2.ZERO],
		[WorldLandmark.Kind.STUMP, Vector2(0.2, 0.3), Vector2.ZERO], [WorldLandmark.Kind.STUMP, Vector2(0.6, 0.8), Vector2.ZERO],
		[WorldLandmark.Kind.LOG, Vector2(0.4, 0.25), Vector2.ZERO], [WorldLandmark.Kind.LOG, Vector2(0.78, 0.65), Vector2.ZERO],
		[WorldLandmark.Kind.LOG, Vector2(0.25, 0.5), Vector2.ZERO],
	],
	RegionDefinition.Props.ROCKS: [
		[WorldLandmark.Kind.CAMPFIRE, Vector2(0.35, 0.35), Vector2.ZERO],
		[WorldLandmark.Kind.TENT, Vector2(0.35, 0.35), Vector2(-2.5, -1.5)], [WorldLandmark.Kind.TENT, Vector2(0.35, 0.35), Vector2(1.5, -2.5)],
		[WorldLandmark.Kind.TENT, Vector2(0.35, 0.35), Vector2(-2.0, 2.0)], [WorldLandmark.Kind.TOTEM, Vector2(0.35, 0.35), Vector2(3.0, 1.0)],
		[WorldLandmark.Kind.CAMPFIRE, Vector2(0.68, 0.66), Vector2.ZERO],
		[WorldLandmark.Kind.TENT, Vector2(0.68, 0.66), Vector2(-2.0, -2.0)], [WorldLandmark.Kind.TENT, Vector2(0.68, 0.66), Vector2(2.0, -1.5)],
		[WorldLandmark.Kind.TOTEM, Vector2(0.55, 0.2), Vector2.ZERO], [WorldLandmark.Kind.TOTEM, Vector2(0.2, 0.75), Vector2.ZERO],
	],
	RegionDefinition.Props.COLUMNS: [
		[WorldLandmark.Kind.OBELISK, Vector2(0.5, 0.5), Vector2.ZERO],
		[WorldLandmark.Kind.ARCH, Vector2(0.3, 0.3), Vector2.ZERO], [WorldLandmark.Kind.ARCH, Vector2(0.7, 0.7), Vector2.ZERO],
		[WorldLandmark.Kind.STATUE, Vector2(0.25, 0.65), Vector2.ZERO], [WorldLandmark.Kind.STATUE, Vector2(0.7, 0.28), Vector2.ZERO],
		[WorldLandmark.Kind.STATUE, Vector2(0.55, 0.75), Vector2.ZERO], [WorldLandmark.Kind.STATUE, Vector2(0.4, 0.42), Vector2.ZERO],
	],
}
const TENT_TINTS: Array[Color] = [Color("8a6a44"), Color("6a5a44"), Color("7a5a3a")]
## Regions narrower than this (tiles) get no landmarks (the boss arena).
const LANDMARK_MIN_SIZE := 24
## How far (tiles) a landmark may move to find free ground.
const LANDMARK_SEARCH := 4
## Wide landmarks keep scattered props this far to their sides (world px).
const LANDMARK_WIDTH := {WorldLandmark.Kind.TENT: 16.0, WorldLandmark.Kind.LOG: 18.0, WorldLandmark.Kind.SHRINE: 16.0,
	WorldLandmark.Kind.ARCH: 20.0}


func _spawn_landmarks(props: Node2D, keep_clear: Array[Rect2i], placed: Array[Vector2]) -> void:
	for region in world.get_regions():
		if region.tile_rect.size.x < LANDMARK_MIN_SIZE:
			continue
		var entries: Array = LANDMARKS.get(region.props, [])
		var ground := world.region_tiles(region.id)
		for i in entries.size():
			var entry: Array = entries[i]
			var spot: Vector2 = Vector2(region.tile_rect.position) + Vector2(region.tile_rect.size) * (entry[1] as Vector2) + entry[2]
			var tile := _free_landmark_tile(Vector2i(spot.floor()), ground, keep_clear, placed)
			if tile == Vector2i(-99999, -99999):
				continue
			var at := WorldService.tile_to_world(Vector2(tile) + Vector2(0.5, 0.5))
			var landmark := WorldLandmark.new().setup(entry[0], TENT_TINTS[i % TENT_TINTS.size()])
			landmark.position = at
			props.add_child(landmark)
			placed.append(at)
			var half: float = LANDMARK_WIDTH.get(entry[0], 0.0)
			if half > 0.0:
				placed.append(at + Vector2(-half, 0))
				placed.append(at + Vector2(half, 0))


## Nearest region ground tile to `start` that is clear of gates / entrances and other landmarks;
## (-99999, -99999) when there is none close by.
func _free_landmark_tile(start: Vector2i, ground: Dictionary, keep_clear: Array[Rect2i], placed: Array[Vector2]) -> Vector2i:
	for radius in LANDMARK_SEARCH + 1:
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				if maxi(absi(dx), absi(dy)) != radius:
					continue
				var tile := start + Vector2i(dx, dy)
				if not ground.has(tile) or not ground.has(tile + Vector2i(1, 1)) or not ground.has(tile - Vector2i(1, 1)):
					continue
				if keep_clear.any(func(rect: Rect2i) -> bool: return rect.has_point(tile)):
					continue
				var at := WorldService.tile_to_world(Vector2(tile) + Vector2(0.5, 0.5))
				if placed.any(func(other: Vector2) -> bool: return other.distance_to(at) < PROP_SPACING * 0.7):
					continue
				return tile
	return Vector2i(-99999, -99999)


## Scenery in the water around the plateaus (D75): [kind, how many], biggest first.
const SCENERY := [
	[WorldScenery.Kind.LIGHTHOUSE, 1], [WorldScenery.Kind.WRECK, 1], [WorldScenery.Kind.ISLET_TREES, 4],
	[WorldScenery.Kind.ISLET_PALMS, 3], [WorldScenery.Kind.SANDBAR, 4], [WorldScenery.Kind.ROCKS, 8],
	[WorldScenery.Kind.LOG, 3], [WorldScenery.Kind.KELP, 6],
]
const SCENERY_SEED := 20261016
## Scenery stays this far inside the camera bounds, and this far from land, cliffs and bridges (world px).
const SCENERY_INSET := 30.0
const SCENERY_SHORE := 60.0
## The cliff faces hang this far below the land's front edges.
const SCENERY_CLIFF := 48.0
const SCENERY_TRIES := 80
const CLOUD_COUNT := 6
const GULL_COUNT := 5
## The sky layer (clouds, gulls, the lighthouse beam) draws above the entities.
const SKY_Z := 20
## A boat lies moored this far from a palm islet's centre (below it, in open water).
const BOAT_OFFSET := Vector2(12, 66)


## Returns the pieces placed.
func _spawn_scenery(props: Node2D) -> Array[WorldScenery]:
	var rng := RandomNumberGenerator.new()
	rng.seed = SCENERY_SEED
	var area := world.get_bounds(96.0).grow(-SCENERY_INSET)
	var taken: Array[Vector2] = []
	var taken_reach: Array[float] = []
	var salt := 0
	var pieces: Array[WorldScenery] = []
	for entry: Array in SCENERY:
		var kind: WorldScenery.Kind = entry[0]
		var reach := WorldScenery.reach_of(kind)
		for n in int(entry[1]):
			for attempt in SCENERY_TRIES:
				var at := area.position + Vector2(rng.randf() * area.size.x, rng.randf() * area.size.y)
				var clear := _open_water(at, reach + SCENERY_SHORE)
				for i in taken.size():
					clear = clear and taken[i].distance_to(at) >= taken_reach[i] + reach
				if not clear:
					continue
				var piece := WorldScenery.new()
				piece.kind = kind
				piece.salt = salt
				piece.position = at
				salt += 1
				props.add_child(piece)
				pieces.append(piece)
				taken.append(at)
				taken_reach.append(reach)
				break
	return pieces


## Moving life (D75): cloud shadows over everything, gulls circling the islets, a boat by a palm islet,
## the lighthouse beacon. Clouds and gulls fly in a sky layer above the entities.
func _spawn_ambience(pieces: Array[WorldScenery]) -> void:
	var sky := Node2D.new()
	sky.name = "Sky"
	sky.z_index = SKY_Z
	add_child(sky)
	var rng := RandomNumberGenerator.new()
	rng.seed = SCENERY_SEED + 1
	var area := world.get_bounds(200.0)
	for i in CLOUD_COUNT:
		var cloud := WorldAmbience.new()
		cloud.kind = WorldAmbience.Kind.CLOUD
		cloud.area = area
		cloud.size = rng.randf_range(90.0, 170.0)
		cloud.speed = rng.randf_range(0.7, 1.3)
		cloud.position = area.position + Vector2(rng.randf() * area.size.x, rng.randf() * area.size.y)
		sky.add_child(cloud)
	var islets := pieces.filter(func(piece: WorldScenery) -> bool:
		return piece.kind in [WorldScenery.Kind.ISLET_TREES, WorldScenery.Kind.ISLET_PALMS, WorldScenery.Kind.LIGHTHOUSE])
	for i in mini(GULL_COUNT, islets.size()):
		var gull := WorldAmbience.new()
		gull.kind = WorldAmbience.Kind.GULL
		gull.centre = (islets[i] as WorldScenery).position + Vector2(0, -30)
		gull.radius = rng.randf_range(50.0, 90.0)
		gull.speed = rng.randf_range(0.35, 0.6) * (1.0 if i % 2 == 0 else -1.0)
		gull.phase = rng.randf() * TAU
		gull.position = gull.centre
		sky.add_child(gull)
	for piece in pieces:
		if piece.kind == WorldScenery.Kind.LIGHTHOUSE:
			var beacon := WorldAmbience.new()
			beacon.kind = WorldAmbience.Kind.BEACON
			beacon.position = WorldScenery.LIGHTHOUSE_LAMP
			beacon.z_index = SKY_Z
			beacon.add_to_group(DayNight.LIGHT_GROUP)
			beacon.set_meta(&"light_radius", 36.0)
			piece.add_child(beacon)
	for piece in pieces:
		if piece.kind == WorldScenery.Kind.ISLET_PALMS:
			var boat := WorldAmbience.new()
			boat.kind = WorldAmbience.Kind.BOAT
			boat.position = piece.position + BOAT_OFFSET
			piece.get_parent().add_child(boat)
			break


## No land, cliff face, bridge or dungeon ledge within `radius` of a water point (the centre and a
## flattened ring).
func _open_water(point: Vector2, radius: float) -> bool:
	for i in 13:
		var probe := point
		if i > 0:
			var angle := i * TAU / 12.0
			probe = point + Vector2(cos(angle), sin(angle) * 0.5) * radius
		if world.region_at(probe) != null or world.region_at(probe - Vector2(0, SCENERY_CLIFF)) != null:
			return false
		for gate in world.get_gates():
			if WorldService.rect_has_point(gate.tiles.grow(2), probe):
				return false
	for definition in DataRegistry.get_all(&"expedition"):
		var expedition := definition as ExpeditionDefinition
		if expedition.region_id != &"" and WorldService.tile_center(expedition.entrance_tile).distance_to(point) < radius + 40.0:
			return false
	return true


## The pond blocks walking (a navigation obstacle over its water).
func _spawn_pond_obstacle(props: Node2D) -> void:
	var pond := world.get_town_pond()
	if pond.size == Vector2i.ZERO:
		return
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.add_to_group(&"navigation_obstacles")
	var shape := CollisionPolygon2D.new()
	shape.polygon = WorldService.rect_polygon(pond, 0.1)
	body.add_child(shape)
	props.add_child(body)


## Lamp posts at the plaza corners, a fountain, well, statue, benches, flower beds, barrels, hay
## and a signpost, placed around the Town Hall. They never block: they only hide under buildings.
func _spawn_town_decor(props: Node2D) -> void:
	var town := world.get_town()
	var hall: BuildingDefinition = DataRegistry.get_building(BuildingService.TOWN_HALL)
	if town == null or hall == null or hall.default_tiles.is_empty():
		return
	var origin := hall.default_tiles[0]
	var plaza := _town_plaza()
	var roads := _town_roads(plaza)
	var pond := world.get_town_pond().grow(1)
	var ground := world.region_tiles(town.id)
	var plan: Array = [
		[TownDecor.Kind.LAMP, Vector2i(-2, -2)], [TownDecor.Kind.LAMP, Vector2i(5, -2)],
		[TownDecor.Kind.LAMP, Vector2i(-2, 5)], [TownDecor.Kind.LAMP, Vector2i(5, 5)],
		[TownDecor.Kind.FOUNTAIN, Vector2i(6, 6)], [TownDecor.Kind.WELL, Vector2i(-6, -3)],
		[TownDecor.Kind.STATUE, Vector2i(3, -5)], [TownDecor.Kind.BENCH, Vector2i(-3, 1)],
		[TownDecor.Kind.BENCH, Vector2i(6, 1)], [TownDecor.Kind.FLOWERBED, Vector2i(-4, -5)],
		[TownDecor.Kind.FLOWERBED, Vector2i(-4, 4)], [TownDecor.Kind.FLOWERBED, Vector2i(7, -4)],
		[TownDecor.Kind.FLOWERBED, Vector2i(8, 3)], [TownDecor.Kind.BARRELS, Vector2i(-7, 1)],
		[TownDecor.Kind.BARRELS, Vector2i(9, 7)], [TownDecor.Kind.HAY, Vector2i(-8, 6)],
		[TownDecor.Kind.SIGN, Vector2i(1, 8)],
	]
	var index := 0
	for entry: Array in plan:
		index += 1
		var tile: Vector2i = origin + entry[1]
		if not ground.has(tile) or pond.has_point(tile):
			continue
		# Lamps stand on the plaza corners; everything else keeps off the paved ground.
		if entry[0] != TownDecor.Kind.LAMP and (plaza.has(tile) or roads.has(tile)):
			continue
		var decor := TownDecor.new()
		decor.kind = entry[0]
		decor.tile = tile
		decor.variant = index
		decor.position = WorldService.tile_to_world(Vector2(tile) + Vector2(0.5, 0.5))
		props.add_child(decor)
		_decor.append(decor)
	_refresh_decor()


## Decorations disappear while a building (or its top-left overhang) covers their tile.
func _refresh_decor() -> void:
	for decor in _decor:
		if not is_instance_valid(decor):
			continue
		var covered := false
		for placed in GameManager.buildings.get_instances():
			if GameManager.buildings.get_footprint_rect(placed).grow(1).has_point(decor.tile):
				covered = true
				break
		decor.visible = not covered
	# Hidden lamps stop glowing at night.
	if _day_night != null:
		_day_night.refresh_lights()


## Trees along the Town's back (top) edge, behind the fence, so it feels enclosed.
func _spawn_town_border(props: Node2D, rng: RandomNumberGenerator, placed: Array[Vector2]) -> void:
	var town := world.get_town()
	if town == null:
		return
	var rect := town.tile_rect
	var pond := world.get_town_pond().grow(1)
	var ground := world.region_tiles(town.id)
	for gx in range(rect.position.x, rect.end.x):
		for gy in range(rect.position.y, rect.end.y):
			var tile := Vector2i(gx, gy)
			# The two rows along the back (north-east) edge of the shape.
			if not ground.has(tile) or (ground.has(tile + Vector2i(0, -1)) and ground.has(tile + Vector2i(0, -2))):
				continue
			if pond.has_point(tile) or rng.randf() > 0.55:
				continue
			var at := WorldService.tile_to_world(Vector2(tile) + Vector2(rng.randf_range(0.3, 0.7), rng.randf_range(0.3, 0.7)))
			if placed.any(func(other: Vector2) -> bool: return other.distance_to(at) < PROP_SPACING * 0.8):
				continue
			placed.append(at)
			var prop := WorldProp.new()
			prop.position = at
			prop.size = rng.randf_range(0.9, 1.25)
			prop.kind = WorldProp.Kind.TREE
			prop.tint = Color("2f6a36").lerp(Color("3f8a40"), rng.randf())
			props.add_child(prop)


## Decorative dirt roads in the Town: from the Town Hall's default spot to every Town gate.
func _town_roads(plaza: Dictionary[Vector2i, bool] = {}) -> Dictionary[Vector2i, bool]:
	var roads: Dictionary[Vector2i, bool] = {}
	var town := world.get_town()
	var hall: BuildingDefinition = DataRegistry.get_building(BuildingService.TOWN_HALL)
	if town == null or hall == null or hall.default_tiles.is_empty():
		return roads
	var hall_rect := Rect2i(hall.default_tiles[0], hall.footprint)
	for gate in world.gates_of(town.id):
		var g := gate.tiles
		if g.position.x >= town.tile_rect.end.x:
			for x in range(hall_rect.end.x, g.position.x):
				for y in range(g.position.y, g.end.y):
					roads[Vector2i(x, y)] = true
		elif g.position.y >= town.tile_rect.end.y:
			for y in range(hall_rect.end.y, g.position.y):
				for x in range(g.position.x, g.end.x):
					roads[Vector2i(x, y)] = true
		elif g.end.x <= town.tile_rect.position.x:
			# Road to the Hunter Gate bridge (D58).
			for x in range(g.end.x, hall_rect.position.x):
				for y in range(g.position.y, g.end.y):
					roads[Vector2i(x, y)] = true
	# A path from the Town Hall up to the pond and to the west edge, so the map has a "main street".
	for x in range(hall_rect.position.x - 1, 8, -1):
		roads[Vector2i(x, hall_rect.position.y + 1)] = true
	for y in range(hall_rect.position.y + 1, 7, -1):
		roads[Vector2i(8, y)] = true
	for tile in plaza:
		roads.erase(tile)
	return roads


## Cobbled plaza around the Town Hall (two tiles wide).
func _town_plaza() -> Dictionary[Vector2i, bool]:
	var plaza: Dictionary[Vector2i, bool] = {}
	var hall: BuildingDefinition = DataRegistry.get_building(BuildingService.TOWN_HALL)
	if hall == null or hall.default_tiles.is_empty():
		return plaza
	var hall_rect := Rect2i(hall.default_tiles[0], hall.footprint)
	for x in range(hall_rect.position.x - 2, hall_rect.end.x + 2):
		for y in range(hall_rect.position.y - 2, hall_rect.end.y + 2):
			plaza[Vector2i(x, y)] = true
	return plaza


# --- Regions: monsters, points -------------------------------------------------------------------

## Walkable area in two steps: a quick mesh from the region outlines (no obstacles) so the world can
## start at once, then the full bake with every prop carved out on a worker thread (~25 s for the
## ~900 obstacles of the big map; baking it on the main thread was a black screen at start-up). The
## full mesh replaces the quick one when it is done.
func _bake_navigation() -> void:
	var polygon := _navigation.navigation_polygon
	var source := NavigationMeshSourceGeometryData2D.new()
	for outline in polygon.get_outline_count():
		source.add_traversable_outline(polygon.get_outline(outline))
	NavigationServer2D.bake_from_source_geometry_data(polygon, source)
	_navigation.navigation_polygon = polygon
	_navigation.bake_navigation_polygon(true)


func _navigation_synced() -> void:
	var map_rid := get_world_2d().navigation_map
	for frame in 30:
		await get_tree().physics_frame
		if NavigationServer2D.map_get_iteration_id(map_rid) > 0:
			return


func _spawn_regions() -> void:
	var index := 0
	var spawning: Array[RegionDefinition] = GameManager.regions.get_hunting_regions()
	for region in world.get_regions():
		if region.kind == RegionDefinition.Kind.BOSS:
			spawning.append(region)
	for region in spawning:
		var spawner := RegionSpawner.new()
		add_child(spawner)
		spawner.setup(self, _actors, region, PROP_SEED + index)
		spawner.monster_killed.connect(_on_monster_killed)
		spawner.populate()
		_spawners[region.id] = spawner
		index += 1


## Village staff (D43) wait beside the Temple (or the Town Hall without one).
func _spawn_staff() -> void:
	var index := 0
	for staff_id in GameManager.corpses.get_staff_ids():
		var worker := StaffWorker.new()
		worker.setup(staff_id, self)
		_actors.add_child(worker)
		worker.global_position = _staff_home(index)
		worker.set_home(worker.global_position)
		_staff[staff_id] = worker
		index += 1


func _staff_home(index: int) -> Vector2:
	return _door_of(BuildingService.TEMPLE, _plaza()) + Vector2(-26.0 - index * 16.0, 4.0)


func get_staff_worker(staff_id: StringName) -> StaffWorker:
	return _staff.get(staff_id)


func get_monsters(region_id: StringName) -> Array[Enemy]:
	var spawner: RegionSpawner = _spawners.get(region_id)
	return spawner.get_monsters() if spawner != null else [] as Array[Enemy]


func get_keep_clear_points() -> Array[Vector2]:
	return _keep_clear_points


## A random walkable point inside `region`.
func random_point_in(region: RegionDefinition, rng: RandomNumberGenerator) -> Vector2:
	var tiles := world.region_tile_list(region.id)
	var tile := Vector2(tiles[rng.randi() % tiles.size()]) + Vector2(rng.randf(), rng.randf())
	return NavigationServer2D.map_get_closest_point(get_world_2d().navigation_map, WorldService.tile_to_world(tile))


## Door of the (unique) building of that type, or Vector2.INF if there is none.
func get_door(building_id: StringName) -> Vector2:
	var node := _building_node(building_id)
	return node.get_door_point() if node != null else Vector2.INF


## A monster casts a skill: its name floats up over it.
func _on_monster_skill_cast(monster: Actor, skill: MonsterSkillDefinition) -> void:
	if not is_instance_valid(monster):
		return
	_popup(skill.display_name, Color("ffb347") if skill.is_active() else Color("8ab4f8"), monster.global_position + Vector2(0, -44), 0.0)
	# Pixel effect in the skill's element (D75): area and self effects on the monster, hits and spells on
	# its target.
	var kind := SkillEffect.kind_for(skill)
	var at := monster.global_position
	if not SkillEffect.on_caster(kind) and monster.combat.is_valid_target(monster.combat.target):
		at = monster.combat.target.global_position
	SkillEffect.play(_entities, at, kind, SkillEffect.element_for(skill))


## A Hunter casts a class skill (D75): the cast pose (staff casters raise the staff) and a pixel effect in
## the skill's element, on the target or around the caster.
## A Hunter's personality shows: breaking off, drinking medicine.
func _on_hunter_behavior(hunter: Hunter, key: StringName) -> void:
	if is_instance_valid(hunter):
		_popup(Loc.t("world.popup.%s" % key), Color("ff9f6b") if key != &"potion" else Color("7fe08a"), hunter.global_position + Vector2(0, -52), 0.0)


func _on_class_skill_cast(caster: Actor, skill: ClassSkillDefinition) -> void:
	if not is_instance_valid(caster) or skill == null or not skill.is_active():
		return
	if caster.visual != null:
		caster.visual.play_action(ChibiAnimations.SKILL)
	var kind := SkillEffect.kind_for_class(skill)
	var at := caster.global_position
	if SkillEffect.class_effect_on_target(skill) and caster.combat != null and caster.combat.is_valid_target(caster.combat.target):
		at = caster.combat.target.global_position
	SkillEffect.play(_entities, at, kind, SkillEffect.element_for_class(skill))


func _on_monster_killed(enemy: Enemy, killer: Hunter, reward: KillReward) -> void:
	if reward.on_ground:
		_spawn_drop(enemy.global_position, reward)
	elif is_instance_valid(killer) and not reward.items.is_empty():
		killer.visual.play_action(ChibiAnimations.LOOT)
	var at := enemy.global_position + Vector2(0, -30)
	var line := 0
	if reward.gold > 0:
		_popup(Loc.t("world.popup.gold", {"gold": reward.gold}), RarityColors.GOLD, at, 0.0)
		line += 1
	for item_id in reward.items:
		var item := DataRegistry.get_item(item_id)
		if item != null:
			_popup(Loc.t("world.popup.item", {"count": reward.items[item_id], "name": item.display_name}), RarityColors.of(item.rarity), at + Vector2(0, -12.0 * line), 0.15 * line)
			line += 1


## Loot of a slain monster lies on the ground until a Hunter picks it up.
func _spawn_drop(at: Vector2, reward: KillReward) -> void:
	if reward.gold <= 0 and reward.items.is_empty():
		return
	var drop := LootDrop.new()
	_entities.add_child(drop)
	drop.global_position = at
	drop.setup(reward.gold, reward.items)
	_drops.append(drop)


func get_drops() -> Array[LootDrop]:
	# Untyped: a freed drop cannot be converted to LootDrop, so a typed argument errors before the check.
	_drops.assign(_drops.filter(func(drop) -> bool: return is_instance_valid(drop) and not drop.is_queued_for_deletion()))
	return _drops


## Nearest loot on the ground within `radius` that `hunter` can use (items need bag room; gold
## always).
func get_nearest_drop(hunter: Hunter, radius: float) -> LootDrop:
	var best: LootDrop = null
	var best_distance := radius
	var bag_full := GameManager.regions.is_bag_full(hunter.runtime)
	for drop in get_drops():
		if bag_full and drop.gold <= 0:
			continue
		var distance := hunter.global_position.distance_to(drop.global_position)
		if distance < best_distance:
			best = drop
			best_distance = distance
	return best


## A Hunter picks the drop up: gold into its purse, items into its bag as far as they fit.
func collect_drop(drop: LootDrop, hunter: Hunter) -> void:
	if not is_instance_valid(drop) or drop.is_empty():
		return
	var gold := drop.gold
	var before := drop.get_item_count()
	var picked := drop.items.duplicate()
	var left := GameManager.regions.collect_drop(hunter.runtime, gold, drop.items)
	drop.gold = 0
	drop.items = left
	hunter.visual.play_action(ChibiAnimations.LOOT)
	if _audio != null:
		_audio.play_loot(drop.global_position)
	var at := hunter.global_position + Vector2(0, -34)
	var line := 0
	if gold > 0:
		_popup(Loc.t("world.popup.gold", {"gold": gold}), RarityColors.GOLD, at, 0.0)
		line += 1
	for item_id in picked:
		var taken: int = picked[item_id] - left.get(item_id, 0)
		var item := DataRegistry.get_item(item_id)
		if taken > 0 and item != null:
			_popup(Loc.t("world.popup.item", {"count": taken, "name": item.display_name}), RarityColors.of(item.rarity), at + Vector2(0, -12.0 * line), 0.15 * line)
			line += 1
	if before > 0 or gold > 0:
		drop.queue_redraw()


func _popup(text: String, color: Color, at: Vector2, delay: float) -> void:
	var popup := LootPopup.new()
	_entities.add_child(popup)
	popup.global_position = at
	popup.setup(text, color, delay)


# --- Hunters in the world -----------------------------------------------------------------------

func _spawn_actor(runtime: HunterRuntime, at: Vector2) -> Hunter:
	var hunter := HUNTER_SCENE.instantiate() as Hunter
	_actors.add_child(hunter)
	hunter.global_position = at
	hunter.setup(runtime, GameManager.hunters, GameManager.combat, DataRegistry.config.retarget_interval, GameManager.equipment, GameManager.class_skills)
	_hunter_actors[runtime.unique_id] = hunter
	var brain := HunterBrain.new()
	hunter.add_child(brain)
	brain.setup(hunter, self)
	brain.behavior_event.connect(_on_hunter_behavior)
	hunter.health.died.connect(_on_hunter_died.bind(hunter))
	_send_home(hunter)
	return hunter


## A Hunter at 0 HP dies where it stands and leaves a body (D30).
func _on_hunter_died(hunter: Hunter) -> void:
	if hunter.runtime.expedition_id != &"":
		# Fallen in a dungeon: comes out as a body when the run ends (D35).
		return
	GameManager.corpses.die(hunter.runtime, hunter.global_position)


# --- Bodies and carriers (D30) -------------------------------------------------------------------

## Gives every body without a carrier the nearest free Hunter. When nobody can carry for
## `body_rescue_seconds` (e.g. everyone fell), the town brings the body to the Temple.
func _assign_carriers() -> void:
	var corpses: CorpseService = GameManager.corpses
	for body_id in _unattended.keys():
		var tracked := GameManager.hunters.get_hunter(body_id)
		if tracked == null or not corpses.is_body(tracked) or corpses.has_carrier(tracked):
			_unattended.erase(body_id)
	for body in corpses.get_bodies():
		if corpses.has_carrier(body):
			continue
		if _try_assign(body):
			_unattended.erase(body.unique_id)
			continue
		var waited: float = _unattended.get(body.unique_id, 0.0) + CARRIER_CHECK_INTERVAL
		_unattended[body.unique_id] = waited
		if waited >= DataRegistry.config.body_rescue_seconds:
			_unattended.erase(body.unique_id)
			corpses.deliver(body)


## True when a carrier was assigned: the nearest free staff member if the treasury can pay the
## fee (D43), otherwise the nearest free Hunter.
func _try_assign(body: HunterRuntime) -> bool:
	var corpses: CorpseService = GameManager.corpses
	var body_actor: Hunter = _hunter_actors.get(body.unique_id)
	var at := body_actor.global_position if body_actor != null else body.world_position
	var free_staff := corpses.get_free_staff()
	free_staff.sort_custom(func(a: StringName, b: StringName) -> bool:
		return _staff_distance(a, at) < _staff_distance(b, at))
	for staff_id in free_staff:
		if corpses.assign_staff(body, staff_id).is_empty():
			return true
	var best: Hunter = null
	var best_distance := INF
	for hunter: Hunter in _hunter_actors.values():
		var brain := hunter.get_node_or_null(^"Brain") as HunterBrain
		if brain == null or not brain.enabled or not hunter.is_targetable() or not corpses.can_carry(hunter.runtime):
			continue
		var distance := hunter.global_position.distance_squared_to(at)
		if distance < best_distance:
			best = hunter
			best_distance = distance
	if best == null or not corpses.assign(body, best.runtime).is_empty():
		return false
	_send_home(best)
	return true


func _staff_distance(staff_id: StringName, at: Vector2) -> float:
	var worker: StaffWorker = _staff.get(staff_id)
	return worker.global_position.distance_squared_to(at) if worker != null else INF


## Carried bodies follow their carrier.
func _drag_bodies() -> void:
	var corpses: CorpseService = GameManager.corpses
	for body in corpses.get_bodies():
		if not corpses.is_carried(body):
			continue
		var carrier_id := corpses.get_carrier_id(body)
		var body_actor: Hunter = _hunter_actors.get(body.unique_id)
		var carrier_actor: Node2D = _staff.get(carrier_id) if corpses.is_staff(carrier_id) else _hunter_actors.get(carrier_id)
		if body_actor == null or carrier_actor == null:
			continue
		body_actor.global_position = carrier_actor.global_position + Vector2(-12, 3)
		body.world_position = body_actor.global_position


func _on_body_delivered(body: HunterRuntime) -> void:
	var body_actor: Hunter = _hunter_actors.get(body.unique_id)
	if body_actor != null:
		body_actor.global_position = get_home_position(body)


func _door_of(building_id: StringName, fallback: Vector2) -> Vector2:
	var node := _building_node(building_id)
	return node.get_door_point() if node != null else fallback


func _plaza() -> Vector2:
	return _door_of(BuildingService.TOWN_HALL, world.region_center(world.get_town())) + Vector2(0, 18)


## Where a Hunter goes in town (D14, D31, D32): sleeping in its House (outdoors beside the Town
## Hall without a bed), eating / resting / socializing at the Tavern, training beside the Town Hall,
## dead or injured at the Temple, otherwise the plaza. Missing buildings fall back to the plaza.
func get_home_position(runtime: HunterRuntime) -> Vector2:
	if runtime.hibernating:
		return _mount_spot(runtime)
	var activity := runtime.activity if runtime.expedition_id == &"" else &""
	if runtime.injured:
		activity = ActivityService.RECOVERING
	var same := GameManager.hunters.get_all().filter(func(h: HunterRuntime) -> bool:
		return (ActivityService.RECOVERING if h.injured else h.activity) == activity)
	var index := maxi(same.find(runtime), 0)
	var plaza := _plaza()
	match activity:
		ActivityService.SLEEPING:
			var home := GameManager.housing.get_home(runtime)
			var house: TownBuilding = _building_nodes.get(home.instance_id) if home != null else null
			if house != null:
				return house.get_door_point()
			return plaza + Vector2(70.0 + (index % 3) * 16.0, 24.0 + (index / 3) * 12.0)
		ActivityService.EATING:
			return _door_of(BuildingService.TAVERN, plaza) + Vector2(-8.0 + (index % 3) * 12.0, 14.0)
		ActivityService.RECOVERING:
			return _door_of(BuildingService.TEMPLE, plaza) + Vector2((index % 4 - 1.5) * BED_SPACING, 8.0)
		ActivityService.RESTING:
			return _door_of(BuildingService.TAVERN, plaza) + Vector2(-20.0 + (index % 3) * 16.0, 6.0 + (index / 3) * 12.0)
		ActivityService.SOCIALIZING:
			return _door_of(BuildingService.TAVERN, plaza) + Vector2(24.0 + (index % 3) * 14.0, 4.0 + (index / 3) * 12.0)
		ActivityService.TRAINING:
			return plaza + Vector2(-90.0 + (index % 3) * 22.0, 10.0 + (index / 3) * 18.0)
	return plaza + Vector2.DOWN.rotated(TAU * index / 6.0) * PLAZA_RING


## Hunters asleep in a House are inside it (hidden, not tappable). Bodies follow carriers.
## An open sheet covers `height` screen px at the bottom: the camera keeps a followed Hunter above it.
func set_sheet_cover(height: float) -> void:
	_camera.cover_bottom = height


## Polled a few times a second: is the camera's centre outside the Town (plus AWAY_MARGIN)?
func _poll_camera_away(delta: float) -> void:
	_away_timer += delta
	if _away_timer < AWAY_POLL:
		return
	_away_timer = 0.0
	var away := false
	if not is_in_dungeon():
		var area := _town_bounds()
		away = area.size != Vector2.ZERO and not area.grow(AWAY_MARGIN).has_point(_camera.global_position)
	if away != _camera_away:
		_camera_away = away
		camera_away_changed.emit(away)


func _physics_process(delta: float) -> void:
	_poll_camera_away(delta)
	_drag_bodies()
	_carrier_check_in -= delta
	if _carrier_check_in <= 0.0:
		_carrier_check_in = CARRIER_CHECK_INTERVAL
		_assign_carriers()
	for hunter: Hunter in _hunter_actors.values():
		var inside := hunter.runtime.activity == ActivityService.SLEEPING and GameManager.housing.get_home(hunter.runtime) != null \
			and hunter.travel_target != Vector2.INF and hunter.global_position.distance_to(hunter.travel_target) < ENTER_DISTANCE
		if hunter.visible == inside:
			hunter.visible = not inside


## Lets the Hunter's brain re-plan (dead Hunters lie still at the Temple).
func _send_home(hunter: Hunter) -> void:
	if hunter.runtime.injured:
		hunter.travel_target = Vector2.INF
		return
	var brain := hunter.get_node_or_null(^"Brain") as HunterBrain
	if brain != null:
		brain.think()
	else:
		hunter.travel_target = get_home_position(hunter.runtime)


func _on_activity_changed(_runtime: HunterRuntime) -> void:
	# Everyone in the same activity may shift spots; re-plan all Hunters once this frame.
	if not _replan_queued:
		_replan_queued = true
		_replan_all.call_deferred()


func _replan_all() -> void:
	_replan_queued = false
	for hunter in _hunter_actors.values():
		_send_home(hunter)


func _on_hunter_added(runtime: HunterRuntime) -> void:
	var gate := _gate_region()
	if gate != null and GameManager.recruitment.is_arriving(runtime.unique_id):
		# Summoned (D83): queued, each comes down the light column in turn.
		_arrivals.append(runtime)
		_next_arrival()
		return
	# New recruits walk in through the Hunter Gate (D58), or out of the Tavern without one.
	_spawn_actor(runtime, world.region_center(gate) if gate != null else _door_of(BuildingService.TAVERN, _plaza()))


## Plays the next queued arrival (D83): a light column at the Gate climbs through the tiers up to
## the newcomer's, the Hunter drops in with a small shake, then the brain walks it on.
func _next_arrival() -> void:
	if _arrival_playing or _arrivals.is_empty():
		return
	_arrival_playing = true
	var runtime: HunterRuntime = _arrivals.pop_front()
	var gate := _gate_region()
	var at := world.region_center(gate) if gate != null else _plaza()
	if _camera != null:
		_camera.stop_following()
		_camera.center_on(at)
	var column := SummonColumn.new()
	column.position = at
	_entities.add_child(column)
	column.setup(runtime.tier)
	await column.peaked
	if not is_instance_valid(self) or GameManager.hunters.get_hunter(runtime.unique_id) == null:
		_arrival_playing = false
		_next_arrival()
		return
	var hunter := _spawn_actor(runtime, at)
	var brain := hunter.get_node_or_null(^"Brain") as HunterBrain
	if brain != null:
		brain.enabled = false
	hunter.travel_target = Vector2.INF
	hunter.z_index = 85
	hunter.visual.position = Vector2(0, -ARRIVAL_DROP)
	var tween := hunter.create_tween()
	tween.tween_property(hunter.visual, ^"position", Vector2.ZERO, 0.28).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(hunter.visual, ^"position", Vector2(0, -6), 0.09).set_ease(Tween.EASE_OUT)
	tween.tween_property(hunter.visual, ^"position", Vector2.ZERO, 0.09).set_ease(Tween.EASE_IN)
	await tween.finished
	hunter.z_index = 0
	column.impact()
	if _shake == null:
		_shake = CameraShake.new()
		add_child(_shake)
	_shake.shake(4.0, 0.25)
	GameManager.recruitment.mark_arrived(runtime.unique_id)
	if brain != null:
		brain.enabled = true
		brain.think()
	else:
		_send_home(hunter)
	await get_tree().create_timer(ARRIVAL_GAP).timeout
	_arrival_playing = false
	_next_arrival()


## An expelled Hunter's actor leaves the world at once (D58).
func _on_hunter_removed(runtime: HunterRuntime) -> void:
	var hunter: Hunter = _hunter_actors.get(runtime.unique_id)
	_hunter_actors.erase(runtime.unique_id)
	if hunter == null:
		return
	if _selected_hunter == hunter:
		_set_selected_hunter(null)
	if _camera.follow_target == hunter:
		_camera.stop_following()
	hunter.queue_free()


func _gate_region() -> RegionDefinition:
	for region in world.get_regions():
		if region.kind == RegionDefinition.Kind.GATE:
			return region
	return null


func _mount_region() -> RegionDefinition:
	for region in world.get_regions():
		if region.kind == RegionDefinition.Kind.MOUNT:
			return region
	return null


## A sleeper's spot on the Hibernation Mount (D83): the sleepers spread over the Mount's tiles in
## a fixed order (by id), keeping clear of the cave mouth at its centre; the plaza without a Mount.
func _mount_spot(runtime: HunterRuntime) -> Vector2:
	var mount := _mount_region()
	if mount == null:
		return _plaza()
	var sleepers := GameManager.hunters.get_hibernating()
	sleepers.sort_custom(func(a: HunterRuntime, b: HunterRuntime) -> bool: return String(a.unique_id) < String(b.unique_id))
	var index := maxi(sleepers.find(runtime), 0)
	var centre := WorldService.tile_at(world.region_center(mount))
	var spots: Array = world.region_tile_list(mount.id).filter(func(tile: Vector2i) -> bool:
		return absi(tile.x - centre.x) > 1 or absi(tile.y - centre.y) > 1)
	if spots.is_empty():
		return world.region_center(mount)
	# A stride coprime with most sizes scatters neighbours in the list across the hill.
	var tile: Vector2i = spots[(index * 7) % spots.size()]
	return WorldService.tile_to_world(Vector2(tile) + Vector2(0.5, 0.5))


func _on_hunter_changed(runtime: HunterRuntime) -> void:
	var hunter: Hunter = _hunter_actors.get(runtime.unique_id)
	if hunter == null:
		return
	if runtime.alive and not runtime.injured and hunter.visual.downed:
		# Revived at the Temple: get up and walk back.
		hunter.revive(maxf(runtime.current_hp, 1.0))
		_send_home(hunter)


# --- Dungeons (D35): walk to the entrance, run the dungeon inside the world --------------------

## Walks `party` (default: pick_party) to the dungeon's entrance, then starts the run. The rest of
## the world keeps living. Returns the reason if it cannot start.
func depart(expedition_id: StringName, party: Array[StringName] = []) -> String:
	if _departing or _dungeon != null:
		return Loc.t("world.depart.party_out")
	if party.is_empty():
		party = pick_party()
	var error := GameManager.expeditions.validate(expedition_id, party)
	var definition := DataRegistry.get_expedition(expedition_id)
	if error.is_empty() and (definition == null or definition.locked):
		error = Loc.t("world.depart.sealed")
	if not error.is_empty():
		depart_failed.emit(error)
		return error
	_departing = true
	var target := world.get_entrance_point(definition)
	var walkers: Array[Hunter] = []
	for i in party.size():
		var hunter: Hunter = _hunter_actors.get(party[i])
		if hunter == null:
			continue
		var carried := GameManager.corpses.get_body_of(hunter.runtime)
		if carried != null:
			var body_actor: Hunter = _hunter_actors.get(carried.unique_id)
			GameManager.corpses.drop(carried, body_actor.global_position if body_actor != null else carried.world_position)
		var brain := hunter.get_node_or_null(^"Brain") as HunterBrain
		if brain != null:
			brain.depart_point = target + Vector2((i - 1) * 16.0, 0)
			brain.think()
		walkers.append(hunter)
	_camera.follow_party(_as_actors(walkers))
	var waited := 0.0
	while waited < DEPART_TIMEOUT and walkers.all(func(h: Hunter) -> bool: return h.is_targetable()) \
			and not walkers.all(func(h: Hunter) -> bool: return h.global_position.distance_to(target) < 40.0):
		await get_tree().physics_frame
		waited += get_physics_process_delta_time()
	_departing = false
	for hunter in walkers:
		var brain := hunter.get_node_or_null(^"Brain") as HunterBrain
		if brain != null:
			brain.depart_point = Vector2.INF
	if GameManager.expeditions.start(expedition_id, party) == null:
		for hunter in walkers:
			_send_home(hunter)
		_camera.stop_following()
		var reason := GameManager.expeditions.validate(expedition_id, party)
		depart_failed.emit(reason if not reason.is_empty() else Loc.t("world.depart.unreachable"))
		return reason
	return ""


func is_in_dungeon() -> bool:
	return _dungeon != null


## The run started (Main): build the dungeon next to the map and move the party in.
func enter_dungeon() -> void:
	var service := GameManager.expeditions
	var definition := service.get_current_definition()
	_dungeon = definition.scene.instantiate() as ExpeditionScene
	_dungeon.embedded = true
	var origin := Vector2(world.get_bounds().end.x + DUNGEON_GAP, 0)
	_dungeon.position = origin
	add_child(_dungeon)
	var party: Array[Hunter] = []
	for hunter_id in service.current_run.party_ids:
		var hunter: Hunter = _hunter_actors.get(hunter_id)
		if hunter != null:
			var brain := hunter.get_node_or_null(^"Brain") as HunterBrain
			if brain != null:
				brain.override_filter = _dungeon.is_inside
			_set_brain(hunter, false)
			hunter.stop()
			hunter.reparent(_dungeon.get_node(^"World/Actors"))
			party.append(hunter)
	_dungeon.start(service, party)
	_camera.bounds = Rect2(origin + ExpeditionScene.MAP_RECT.position, ExpeditionScene.MAP_RECT.size)
	_camera.zoom = Vector2.ONE
	# The dungeon is far from the Town: jump there rather than glide across the map.
	_camera.follow_party(_as_actors(party), true)


## The run ended (Main, after the result banner): survivors come out at the entrance and go back to
## their own lives; the fallen lie there as bodies (ExpeditionService.downed_handler).
func exit_dungeon(run: ExpeditionRun) -> void:
	if _dungeon == null:
		return
	var definition := DataRegistry.get_expedition(run.expedition_id)
	var exit_point := world.get_entrance_point(definition) if definition != null else _plaza()
	var party: Array[Hunter] = _dungeon.get_party().duplicate()
	_dungeon.release_party()
	var index := 0
	for hunter in party:
		if not is_instance_valid(hunter):
			continue
		hunter.reparent(_actors)
		var runtime := hunter.runtime
		hunter.global_position = runtime.world_position if not runtime.alive else exit_point + ExpeditionScene.FORMATION[index % ExpeditionScene.FORMATION.size()]
		runtime.world_position = hunter.global_position
		hunter.travel_target = Vector2.INF
		var brain := hunter.get_node_or_null(^"Brain") as HunterBrain
		if brain != null:
			brain.override_filter = Callable()
		_set_brain(hunter, true)
		index += 1
	_dungeon.queue_free()
	_dungeon = null
	_camera.bounds = world.get_bounds(96.0)
	_camera.stop_following()
	_camera.center_on(exit_point)
	request_refresh()


static func _as_actors(hunters: Array[Hunter]) -> Array[Actor]:
	var actors: Array[Actor] = []
	actors.assign(hunters)
	return actors


func _set_brain(hunter: Hunter, on: bool) -> void:
	var brain := hunter.get_node_or_null(^"Brain") as HunterBrain
	if brain != null:
		if not on:
			brain.cancel_craft()
		brain.enabled = on
		hunter.combat.recheck()


func pick_party() -> Array[StringName]:
	var available := GameManager.hunters.get_all().filter(func(h: HunterRuntime) -> bool:
		return not h.injured and not h.hibernating and h.state == HunterRuntime.LifecycleState.AVAILABLE)
	available.sort_custom(func(a: HunterRuntime, b: HunterRuntime) -> bool: return a.level > b.level)
	var party: Array[StringName] = []
	for runtime in available.slice(0, DataRegistry.config.max_party_size):
		party.append(runtime.unique_id)
	return party


# --- Debug panel: developer tools only ------------------------------------------------------------

func _rebuild_panel() -> void:
	_refresh_queued = false
	if _panel == null or not is_instance_valid(_panel):
		return
	_panel.clear()
	_panel.add_button_row([
		[Loc.t("world.dev.save"), func() -> void:
			_panel.add_label(Loc.t("world.dev.saved") if SaveManager.save_game(&"manual") else Loc.t("world.dev.save_failed"))],
		[Loc.t("world.dev.new_game"), _new_game],
		[Loc.t("world.dev.sandbox"), func() -> void: GameManager.request_world(&"sandbox")],
	])
	_panel.add_button_row([
		[Loc.t("world.dev.add_gold"), func() -> void: GameManager.wallet.add(500)],
		[Loc.t("world.dev.add_hour"), func() -> void: SaveManager.apply_offline_progress(3600.0)],
		[Loc.t("world.dev.tire_all"), func() -> void:
			for runtime in GameManager.hunters.get_all():
				runtime.stamina = 10.0
				runtime.energy = 20.0
				GameManager.needs.needs_changed.emit(runtime)],
	])
	if _dungeon != null:
		_dungeon.setup_debug(_panel)
