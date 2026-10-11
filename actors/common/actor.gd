class_name Actor
extends CharacterBody2D
## Shared base for Hunters and enemies: component access, navigation movement,
## auto-combat chase, downed handling and feedback hooks
## (ARCHITECTURE.md → Actor composition). Origin is at the feet.

## Distance at which a move target counts as reached.
const ARRIVE_DISTANCE := 2.0
## Re-path the chase only when the approach point moved this far.
const REPATH_DISTANCE := 6.0
## Standing teammates closer than this drift apart (actors do not body-block each other).
## Must stay below the distance between neighbouring engagement slots (~13.5 px).
const SEPARATION_DISTANCE := 12.0
const SEPARATION_SPEED := 30.0
## Move speed above base × this shows the run animation.
const RUN_SPEED_FACTOR := 1.15

@onready var visual: ActorVisual = $Visual
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var health: HealthController = $HealthController
@onready var combat: CombatController = $CombatController
@onready var state: StateController = $StateController
## Buffs/debuffs (D48). Created in code so every actor scene gets one.
var effects: StatusEffectController

## When true the actor chases and attacks its CombatController target on its own.
var auto_combat := false
## Where an auto-combat actor walks when it has no target (expedition travel). INF = none.
var travel_target := Vector2.INF
## False: once the target is in range, stand still instead of stepping to an engagement
## slot. Used by bosses so the fight does not drift as both sides chase each other's slots.
var repositions_in_range := true
## Set while following a player command; auto combat resumes on arrival.
var _manual_move := false


func _ready() -> void:
	effects = StatusEffectController.new()
	effects.name = "StatusEffects"
	add_child(effects)
	var effect_view := StatusEffectView.new()
	add_child(effect_view)
	effect_view.bind(self)
	health.died.connect(_on_died)
	health.damaged.connect(func(_amount: float) -> void: visual.play_hit_flash())
	combat.attacked.connect(_on_attacked)


## Group of this actor's own side (Hunter.GROUP / Enemy.GROUP).
func get_team_group() -> StringName:
	return &""


## Pixels per second. Overridden by subclasses.
func get_move_speed() -> float:
	return 0.0


## Overridden by subclasses. `against` is the opponent (for conditional modifiers), may be null.
func get_combat_stats(_against: Actor = null) -> CombatStats:
	return CombatStats.new()


## Combat stats after active status effects (D48). CombatService uses this.
func get_final_combat_stats(against: Actor = null) -> CombatStats:
	return effects.modify_combat_stats(get_combat_stats(against))


## Effects this actor's hits may apply. Overridden by subclasses.
func get_on_hit_effects() -> Array[StatusEffectChance]:
	return []


## Move speed after status effects (slow, haste).
func get_final_move_speed() -> float:
	return effects.modify_stat(HunterService.MOVE_SPEED, get_move_speed())


## Extra body size beyond a standard actor; attackers add it to their reach.
func get_hit_radius() -> float:
	return 0.0


## Whether other actors may select this one as a target.
func is_targetable() -> bool:
	return is_inside_tree() and not health.is_dead() and not state.is_state(StateController.State.DOWNED)


func can_attack() -> bool:
	return not _manual_move and not state.is_state(StateController.State.DOWNED) and effects.can_attack()


## Player/debug command: walk to a point, ignoring combat until arrival.
func command_move_to(target: Vector2) -> void:
	_manual_move = true
	move_to(target)


func move_to(target: Vector2) -> void:
	if not state.change(StateController.State.MOVING):
		return
	nav_agent.target_position = target


func stop() -> void:
	_manual_move = false
	velocity = Vector2.ZERO
	visual.moving = false
	if state.is_state(StateController.State.MOVING):
		state.change(StateController.State.IDLE)


## Brings a downed actor back (Hospital / debug).
func revive(amount: float) -> void:
	effects.clear_all()
	health.revive(amount)
	state.revive()
	visual.downed = false
	combat.resume()


func face_towards(point: Vector2) -> void:
	visual.facing = Facing.from_vector(point - global_position, visual.facing)


func _physics_process(delta: float) -> void:
	if not effects.can_move():
		# Stunned / rooted: keep the current order, just do not move.
		velocity = Vector2.ZERO
		visual.moving = false
		return
	if auto_combat and not _manual_move and not state.is_state(StateController.State.DOWNED):
		_update_chase()
	if not state.is_state(StateController.State.MOVING):
		if not state.is_state(StateController.State.DOWNED):
			_apply_separation()
		return
	if nav_agent.is_navigation_finished():
		stop()
		return
	var to_next := nav_agent.get_next_path_position() - global_position
	if to_next.length() <= ARRIVE_DISTANCE and nav_agent.is_target_reached():
		stop()
		return
	# Never step past the next path point (large steps would oscillate around it).
	velocity = to_next.normalized() * minf(get_final_move_speed(), to_next.length() / maxf(delta, 0.0001))
	visual.facing = Facing.from_vector(velocity, visual.facing)
	visual.moving = true
	# Chasing a target or hasted: run (presentation only, speed is unchanged).
	visual.running = (auto_combat and not _manual_move and combat.is_valid_target(combat.target)) \
		or get_final_move_speed() > get_move_speed() * RUN_SPEED_FACTOR
	move_and_slide()


## Chase: walk to an engagement slot of the target, then attack from there (AI_SYSTEM.md).
func _update_chase() -> void:
	var target := combat.target
	if not combat.is_valid_target(target):
		_update_travel()
		return
	if not repositions_in_range and combat.is_target_in_range():
		stop()
		face_towards(target.global_position)
		return
	var approach := combat.get_approach_point()
	var slot_distance := global_position.distance_to(approach)
	# Hold position when near the slot *and* in range, or near the waiting point.
	# Attacks still happen whenever the target is in range, even while stepping to the slot.
	var near := slot_distance <= REPATH_DISTANCE
	if near and (combat.is_target_in_range() or not combat.holds_slot()):
		stop()
		face_towards(target.global_position)
		return
	if near:
		# At the slot but just out of range (target drifted): step straight towards the target.
		approach = target.global_position.move_toward(global_position, combat.get_reach() * 0.6)
	var moving := state.is_state(StateController.State.MOVING)
	if not moving or nav_agent.target_position.distance_to(approach) > REPATH_DISTANCE:
		move_to(approach)


## No target: walk to `travel_target` if set, otherwise stand still.
func _update_travel() -> void:
	if travel_target == Vector2.INF or global_position.distance_to(travel_target) <= REPATH_DISTANCE:
		stop()
		return
	var moving := state.is_state(StateController.State.MOVING)
	if not moving or nav_agent.target_position.distance_to(travel_target) > REPATH_DISTANCE:
		move_to(travel_target)


## Gentle push away from standing teammates that overlap this actor.
func _apply_separation() -> void:
	var push := Vector2.ZERO
	for node in get_tree().get_nodes_in_group(get_team_group()):
		var other := node as Actor
		if other == null or other == self or not other.is_targetable():
			continue
		var offset := global_position - other.global_position
		var distance := offset.length()
		if distance >= SEPARATION_DISTANCE:
			continue
		# Exactly overlapping: split along a stable axis based on instance ids.
		var direction := offset / distance if distance > 0.01 else (Vector2.RIGHT if get_instance_id() > other.get_instance_id() else Vector2.LEFT)
		push += direction * (1.0 - distance / SEPARATION_DISTANCE)
	if push.is_zero_approx():
		return
	velocity = push.limit_length(1.0) * SEPARATION_SPEED
	move_and_slide()
	velocity = Vector2.ZERO


func _on_attacked(target: Actor) -> void:
	face_towards(target.global_position)
	visual.play_attack_lunge(target.global_position - global_position)


func _on_died() -> void:
	_manual_move = false
	velocity = Vector2.ZERO
	effects.clear_all()
	state.change(StateController.State.DOWNED)
	combat.stop()
	visual.moving = false
	visual.downed = true
