extends Node2D
## Combat sandbox (debug builds only): spawn Hunters and enemies, watch auto combat, tap to
## select / move. Reached from the Town debug panel. Hunters spawned here join the real roster.

const HUNTER_SCENE := preload("res://actors/hunter/hunter.tscn")
const SELECT_RADIUS := 18.0
## Fights happen below the rock so the debug panel does not cover them.
const SPAWN_POINT := Vector2(180, 590)
const ENEMY_SPAWN_AREA := Rect2(40, 420, 280, 50)
const GROUND_SIZE := Vector2(360, 800)
const TILE := 32.0
const GRASS := Color("2f4a34")
const GRASS_ALT := Color("2b4430")
const WALKABLE_TINT := Color(1, 1, 1, 0.04)
const LOG_LINES := 4

@onready var _actors: Node2D = $Actors
@onready var _navigation: NavigationRegion2D = $NavigationRegion2D

var _hunters: HunterService
var _selected: Hunter
var _info_label: Label
var _log_label: Label
var _log: PackedStringArray = []


func _ready() -> void:
	_hunters = GameManager.hunters
	# Bake at runtime so obstacles placed in the scene carve holes in the walkable area.
	_navigation.bake_navigation_polygon(false)
	GameManager.combat.actor_defeated.connect(_on_actor_defeated)
	GameManager.combat.damage_dealt.connect(_on_damage_dealt)
	# The roster outlives this scene (e.g. after an expedition): show every Hunter again.
	for runtime in _hunters.get_all():
		_spawn_actor(runtime)


func setup_debug(panel: DebugPanel) -> void:
	panel.add_separator()
	panel.add_label("Tap ground: move. Tap Hunter: select.")
	panel.add_button_row([
		["Hunter", spawn_warrior],
		["Hit 25", func() -> void: _with_selected(func(h: Hunter) -> void: h.health.take_damage(25.0))],
		["Revive", func() -> void: _with_selected(_heal_hunter)],
		["Lv +1", func() -> void: _with_selected(func(h: Hunter) -> void: _hunters.set_level(h.runtime, h.runtime.level + 1))],
	])
	panel.add_button_row([
		["Slime", func() -> void: spawn_enemy(&"slime")],
		["Slime x3", _spawn_three_slimes],
		["Slime x6", _spawn_six_slimes],
	])
	panel.add_button_row([
		["Town", func() -> void: GameManager.request_world(&"town")],
		["Heal all", _heal_all],
	])
	_info_label = panel.add_label("No Hunter selected")
	_refresh_info()
	_log_label = panel.add_label("")


func _unhandled_input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch == null or not touch.pressed:
		return
	var world_position := get_canvas_transform().affine_inverse() * touch.position
	var tapped := _find_hunter_at(world_position)
	if tapped != null:
		_select(tapped)
	elif _selected != null:
		_selected.command_move_to(world_position)
	get_viewport().set_input_as_handled()


func _draw() -> void:
	for x in range(0, int(GROUND_SIZE.x / TILE) + 1):
		for y in range(0, int(GROUND_SIZE.y / TILE) + 1):
			var color := GRASS if (x + y) % 2 == 0 else GRASS_ALT
			draw_rect(Rect2(Vector2(x, y) * TILE, Vector2(TILE, TILE)), color)
	var outline := _navigation.navigation_polygon.get_outline(0)
	draw_colored_polygon(outline, WALKABLE_TINT)


func spawn_warrior() -> Hunter:
	var runtime := _hunters.create_hunter(&"warrior", GameManager.rng)
	if runtime == null:
		return null
	GameManager.equipment.give_starting_gear(runtime)
	return _spawn_actor(runtime)








## Debug stand-in for the Hospital (Phase 6).
func _heal_all() -> void:
	for child in _actors.get_children():
		if child is Hunter:
			_heal_hunter(child)
	_refresh_info()


func _heal_hunter(hunter: Hunter) -> void:
	_hunters.recover(hunter.runtime)
	hunter.revive(hunter.health.max_health)


func _spawn_actor(runtime: HunterRuntime) -> Hunter:
	var hunter := HUNTER_SCENE.instantiate() as Hunter
	_actors.add_child(hunter)
	hunter.global_position = SPAWN_POINT + Vector2(randf_range(-60, 60), randf_range(-10, 10))
	hunter.setup(runtime, _hunters, GameManager.combat, DataRegistry.config.retarget_interval, GameManager.equipment)
	hunter.health.health_changed.connect(func(_c: float, _m: float) -> void: _refresh_info())
	hunter.state.state_changed.connect(func(_p: int, _c: int) -> void: _refresh_info())
	_select(hunter)
	return hunter


func spawn_enemy(definition_id: StringName) -> Enemy:
	var definition := DataRegistry.get_enemy(definition_id)
	if definition == null or definition.actor_scene == null:
		return null
	var enemy := definition.actor_scene.instantiate() as Enemy
	_actors.add_child(enemy)
	enemy.global_position = ENEMY_SPAWN_AREA.position + Vector2(randf() * ENEMY_SPAWN_AREA.size.x, randf() * ENEMY_SPAWN_AREA.size.y)
	enemy.setup(definition, GameManager.combat, DataRegistry.config.retarget_interval)
	return enemy


func _spawn_three_slimes() -> void:
	for i in 3:
		spawn_enemy(&"slime")


func _spawn_six_slimes() -> void:
	_spawn_three_slimes()
	_spawn_three_slimes()


func _select(hunter: Hunter) -> void:
	if _selected != null:
		_selected.visual.selected = false
	_selected = hunter
	_selected.visual.selected = true
	_refresh_info()


func _with_selected(action: Callable) -> void:
	if _selected != null:
		action.call(_selected)
		_refresh_info()


func _find_hunter_at(world_position: Vector2) -> Hunter:
	var best: Hunter = null
	var best_distance := SELECT_RADIUS
	for child in _actors.get_children():
		var hunter := child as Hunter
		if hunter == null:
			continue
		# Hunters are drawn above their origin; test against the body centre.
		var distance := world_position.distance_to(hunter.global_position + Vector2(0, -14))
		if distance < best_distance:
			best = hunter
			best_distance = distance
	return best


func _refresh_info() -> void:
	if _info_label == null or _selected == null:
		return
	var runtime := _selected.runtime
	_info_label.text = "%s  Lv %d\nHP %d/%d  ATK %.1f  DEF %.1f\nSPD %d  CRIT %d%%  %s" % [
		runtime.display_name,
		runtime.level,
		roundi(_selected.health.current_health),
		roundi(_selected.health.max_health),
		_hunters.get_stat(runtime, HunterService.ATTACK),
		_hunters.get_stat(runtime, HunterService.DEFENSE),
		roundi(_hunters.get_stat(runtime, HunterService.MOVE_SPEED)),
		roundi(_hunters.get_stat(runtime, HunterService.CRITICAL_CHANCE) * 100.0),
		StateController.State.keys()[_selected.state.current],
	]


func _on_damage_dealt(attacker: Actor, target: Actor, amount: float, is_critical: bool) -> void:
	if is_critical:
		_add_log("%s CRIT %s for %d" % [_actor_name(attacker), _actor_name(target), roundi(amount)])


func _on_actor_defeated(actor: Actor, by: Actor) -> void:
	var verb := "downed" if actor is Hunter else "killed"
	_add_log("%s %s %s" % [_actor_name(by), verb, _actor_name(actor)])


func _add_log(line: String) -> void:
	_log.append(line)
	if _log.size() > LOG_LINES:
		_log.remove_at(0)
	if _log_label != null:
		_log_label.text = "\n".join(_log)


func _actor_name(actor: Actor) -> String:
	if not is_instance_valid(actor):
		return "?"
	if actor is Hunter:
		return (actor as Hunter).runtime.display_name
	if actor is Enemy:
		return (actor as Enemy).definition.display_name
	return actor.name
