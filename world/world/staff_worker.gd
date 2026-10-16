class_name StaffWorker
extends CharacterBody2D
## A village staff member (DECISIONS.md D43): not a Hunter, cannot fight, monsters ignore it.
## Waits at the Temple; when CorpseService assigns it a body it walks there, drags the body to the
## Temple at its speed × carry_speed_ratio and delivers it.
## Drawn as a Forge character (D77): a Temple acolyte in a pale robe and a hood, empty-handed, its face
## and hair from its id.

## Acolyte robe and hood colours.
const ROBE := Color("d9cfa8")
const HOOD := Color("8a7f66")
const PICK_UP_DISTANCE := 18.0
const DELIVER_DISTANCE := 24.0
const STOPPED_ARRIVE_DISTANCE := 64.0

var staff_id: StringName
var visual: ActorVisual
var _map: WorldMap
var _nav: NavigationAgent2D
var _home := Vector2.ZERO
var _moving := false


func setup(id: StringName, map: WorldMap) -> void:
	staff_id = id
	name = String(id)
	_map = map
	collision_layer = 0
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var look := ChibiVisual.new()
	look.name = "Visual"
	look.appearance = HunterAppearance.from_seed(String(id), 0)
	look.forge_weapon = "none"
	var dress := ChibiDress.new()
	dress.top = &"robe"
	dress.cloth = ROBE
	dress.has_cloth = true
	dress.hat = &"hood"
	dress.hat_tint = HOOD
	look.dress = dress
	visual = look
	add_child(visual)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape = circle
	shape.position = Vector2(0, -3)
	add_child(shape)
	_nav = NavigationAgent2D.new()
	_nav.path_desired_distance = 4.0
	_nav.target_desired_distance = 4.0
	_nav.radius = 7.0
	add_child(_nav)


## Where it waits when idle (next to the Temple).
func set_home(point: Vector2) -> void:
	_home = point


func is_busy() -> bool:
	return GameManager.corpses.get_body_of_id(staff_id) != null


func _physics_process(delta: float) -> void:
	var corpses: CorpseService = GameManager.corpses
	var body := corpses.get_body_of_id(staff_id)
	var config: GameConfig = DataRegistry.config
	if body == null:
		_walk(_home, config.staff_move_speed, delta)
		return
	if not corpses.is_carried(body):
		var body_actor := _map.get_hunter_actor(body.unique_id)
		var at := body_actor.global_position if body_actor != null else body.world_position
		if global_position.distance_to(at) <= PICK_UP_DISTANCE:
			corpses.pick_up(body)
		else:
			_walk(at, config.staff_move_speed, delta)
		return
	var door := _map.get_door(BuildingService.TEMPLE)
	if door == Vector2.INF:
		door = _map.get_home_position(body)
	var distance := global_position.distance_to(door)
	if distance <= DELIVER_DISTANCE or (distance <= STOPPED_ARRIVE_DISTANCE and not _moving):
		corpses.deliver(body)
		return
	_walk(door, config.staff_move_speed * config.carry_speed_ratio, delta)


func _walk(target: Vector2, speed: float, delta: float) -> void:
	if global_position.distance_to(target) <= 4.0:
		_set_moving(false)
		return
	if _nav.target_position.distance_to(target) > 6.0:
		_nav.target_position = target
	if _nav.is_navigation_finished():
		_set_moving(false)
		return
	var to_next := _nav.get_next_path_position() - global_position
	velocity = to_next.normalized() * minf(speed, to_next.length() / maxf(delta, 0.0001))
	_set_moving(velocity.length() > 1.0)
	if _moving:
		visual.facing = Facing.from_vector(velocity, visual.facing)
	move_and_slide()


## The visual walks while the staff member moves.
func _set_moving(value: bool) -> void:
	_moving = value
	visual.moving = value
