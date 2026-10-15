class_name CombatController
extends Node
## Targeting, engagement slots and attack timing for one actor (COMBAT_SYSTEM.md, AI_SYSTEM.md).
## Keeps its target until it becomes invalid; checks on a timer and immediately when the
## target dies. Damage itself is resolved by CombatService.
##
## Engagement slots: every actor offers SLOT_COUNT fixed positions around itself. An attacker
## claims the free slot nearest to it and walks there, so attackers never stack. When all
## slots are taken, the attacker waits on an outer ring and retries.

signal target_changed(target: Actor)
signal attacked(target: Actor)

const SLOT_COUNT := 6
## Slots sit inside the attack range so arrival tolerance (4 px) and small drift keep the
## target in range. Neighbouring slots are then ~0.75 × range apart (> SEPARATION_DISTANCE).
const SLOT_RANGE_FACTOR := 0.75
## Extra distance of the waiting ring beyond the attack range.
const WAIT_RING_OFFSET := 14.0
## A slot point further than this from the walkable area counts as blocked.
const BLOCKED_SLOT_TOLERANCE := 3.0

## Group of actors this one can target, e.g. Hunter.GROUP.
var target_group: StringName
var attack_range := 0.0
var target: Actor
## False pauses attacking (targeting continues), e.g. while following a player command.
var attacks_enabled := true
## Optional rules (the world map): `func(candidate: Actor) -> bool`. `acquire_filter` limits new
## targets (aggro range), `keep_filter` also drops the current one (leash, left the region).
var acquire_filter: Callable
var keep_filter: Callable
## Optional `func(target: Actor) -> void` resolving the attack instead of the service's plain
## attack (Hunters use it for their class skill, D54).
var attack_override: Callable

var _service: CombatService
var _timer: Timer
var _cooldown := 0.0
var _active := false
## Attackers holding this actor's slots (index = slot). Null = free.
var _slot_owners: Array[Actor] = []


func _ready() -> void:
	_slot_owners.resize(SLOT_COUNT)


func setup(group: StringName, range_px: float, retarget_interval: float, service: CombatService) -> void:
	target_group = group
	attack_range = range_px
	_service = service
	if _timer == null:
		_timer = Timer.new()
		_timer.timeout.connect(refresh_target)
		add_child(_timer)
	_timer.wait_time = retarget_interval
	resume()


## The service resolving this actor's attacks (null before setup).
func get_service() -> CombatService:
	return _service


## Stops targeting and attacking (e.g. when the owner is downed).
func stop() -> void:
	_active = false
	if _timer != null:
		_timer.stop()
	_set_target(null)
	_slot_owners.fill(null)


## Starts (again) after setup or revive.
func resume() -> void:
	if _timer == null:
		return
	_active = true
	_timer.start()
	# Small random delay so a group does not attack in lockstep.
	_cooldown = randf_range(0.1, 0.5)
	refresh_target.call_deferred()


## Keeps a valid target; otherwise picks the nearest valid one (or none).
func refresh_target() -> void:
	if not _active or target_group == &"" or is_valid_target(target):
		return
	var origin := _owner_actor().global_position
	_set_target(pick_nearest(origin, get_tree().get_nodes_in_group(target_group), _can_acquire))


func is_valid_target(candidate: Actor) -> bool:
	return is_instance_valid(candidate) and candidate != _owner_actor() and candidate.is_targetable() \
		and (not keep_filter.is_valid() or keep_filter.call(candidate))


## Drops the current target if it is no longer valid and looks for a new one now.
func recheck() -> void:
	if target != null and not is_valid_target(target):
		_set_target(null)
	refresh_target()


func _can_acquire(candidate: Actor) -> bool:
	return is_valid_target(candidate) and (not acquire_filter.is_valid() or acquire_filter.call(candidate))


func is_target_in_range() -> bool:
	if not is_valid_target(target):
		return false
	return _owner_actor().global_position.distance_to(target.global_position) <= get_reach()


## Attack range plus the current target's extra body size.
func get_reach() -> float:
	return attack_range + (target.get_hit_radius() if is_valid_target(target) else 0.0)


## Where the owner should stand to fight its target: its claimed slot, or a waiting
## point on the outer ring if every slot is taken.
func get_approach_point() -> Vector2:
	var owner_actor := _owner_actor()
	var reach := get_reach()
	var slot_point := target.combat.claim_slot(owner_actor, reach * SLOT_RANGE_FACTOR, reach)
	if slot_point != Vector2.INF:
		return slot_point
	var direction := (owner_actor.global_position - target.global_position).normalized()
	if direction.is_zero_approx():
		direction = Vector2.DOWN
	return target.global_position + direction * (reach + WAIT_RING_OFFSET)


## Called on the *target's* controller. Returns the position of the slot held by `attacker`
## (claiming the nearest free usable one if needed), or Vector2.INF if none is available.
## A slot is usable when its point is on the walkable area and within `max_range`.
func claim_slot(attacker: Actor, ring_radius: float, max_range: float) -> Vector2:
	var center := _owner_actor().global_position
	var owned := _slot_owners.find(attacker)
	if owned >= 0:
		var point := _slot_point(owned, center, ring_radius, attacker)
		if point != Vector2.INF and point.distance_to(center) <= max_range:
			return point
		_slot_owners[owned] = null
	_release_invalid_slots()
	var best := -1
	var best_point := Vector2.INF
	var best_distance := INF
	for index in SLOT_COUNT:
		if _slot_owners[index] != null:
			continue
		var point := _slot_point(index, center, ring_radius, attacker)
		if point == Vector2.INF or point.distance_to(center) > max_range:
			continue
		var distance := attacker.global_position.distance_squared_to(point)
		if distance < best_distance:
			best = index
			best_point = point
			best_distance = distance
	if best >= 0:
		_slot_owners[best] = attacker
	return best_point


## True if the owner currently holds one of its target's slots (false = waiting ring).
func holds_slot() -> bool:
	return is_valid_target(target) and target.combat._slot_owners.has(_owner_actor())


## Called on the *target's* controller when `attacker` stops attacking it.
func release_slot(attacker: Actor) -> void:
	var index := _slot_owners.find(attacker)
	if index >= 0:
		_slot_owners[index] = null


func get_claimed_slot_count() -> int:
	return SLOT_COUNT - _slot_owners.count(null)


func _physics_process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	if not _active or _service == null or not attacks_enabled or _cooldown > 0.0:
		return
	if not is_target_in_range() or not _owner_actor().can_attack():
		return
	_cooldown = _service.attack_cooldown(_owner_actor())
	attacked.emit(target)
	if attack_override.is_valid():
		attack_override.call(target)
	else:
		_service.resolve_attack(_owner_actor(), target)


## Nearest candidate for which `is_valid` returns true, or null.
static func pick_nearest(origin: Vector2, candidates: Array, is_valid: Callable) -> Node2D:
	var best: Node2D = null
	var best_distance := INF
	for candidate: Node2D in candidates:
		if not is_valid.call(candidate):
			continue
		var distance := origin.distance_squared_to(candidate.global_position)
		if distance < best_distance:
			best = candidate
			best_distance = distance
	return best


## Direction of slot `index`, evenly spaced, starting straight down.
static func slot_direction(index: int) -> Vector2:
	return Vector2.DOWN.rotated(TAU * index / SLOT_COUNT)


func _slot_point(index: int, center: Vector2, ring_radius: float, attacker: Actor) -> Vector2:
	var point := center + slot_direction(index) * ring_radius
	var navigation_map := attacker.nav_agent.get_navigation_map()
	if NavigationServer2D.map_get_iteration_id(navigation_map) == 0:
		# No navigation data yet (e.g. unit tests): use the raw point.
		return point
	var walkable := NavigationServer2D.map_get_closest_point(navigation_map, point)
	# A slot inside an obstacle is unusable; snapping it would squeeze it against a neighbour.
	return walkable if walkable.distance_to(point) <= BLOCKED_SLOT_TOLERANCE else Vector2.INF


## Frees slots whose holder is gone, downed or now targeting someone else.
func _release_invalid_slots() -> void:
	var me := _owner_actor()
	for index in SLOT_COUNT:
		var holder := _slot_owners[index]
		if holder == null:
			continue
		if not is_instance_valid(holder) or not holder.is_targetable() or holder.combat.target != me:
			_slot_owners[index] = null


func _owner_actor() -> Actor:
	return get_parent() as Actor


func _set_target(new_target: Actor) -> void:
	if new_target == target:
		return
	if is_instance_valid(target):
		target.combat.release_slot(_owner_actor())
		if target.health.died.is_connected(_on_target_died):
			target.health.died.disconnect(_on_target_died)
	target = new_target
	if target != null:
		target.health.died.connect(_on_target_died)
	target_changed.emit(target)


func _on_target_died() -> void:
	_set_target(null)
	refresh_target()
