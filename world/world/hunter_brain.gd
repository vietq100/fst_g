class_name HunterBrain
extends Node
## Decides what a Hunter in the world does (AUTONOMY_SYSTEM.md → Brain, DECISIONS.md D29). Child
## of the Hunter actor. Priorities: needs (sleep / eat / rest) and a full loot bag send it home;
## otherwise its duty sends it hunting in a region, or it lives in town. Rules come from the
## services; the brain only picks the task and where to walk.

const THINK_INTERVAL := 0.5
## Close enough to the Warehouse door to hand in the bag.
const DEPOSIT_DISTANCE := 24.0
const RETURNING := &"returning"
## Walking to a body / dragging it to the Temple (D30, D42).
const FETCHING := &"fetching"
const CARRYING := &"carrying"
## Walking with a party to a dungeon entrance (D35); fights what attacks on the way.
const DEPARTING := &"departing"
## Talent crafting in the field (D46): standing still, cancelled when hit.
const COOKING := &"cooking"
const BREWING := &"brewing"
## Close enough to a body to pick it up.
const PICK_UP_DISTANCE := 18.0
## Stopped this close to a door counts as arrived (the exact point may be hard to reach).
const STOPPED_ARRIVE_DISTANCE := 64.0

var hunter: Hunter
var map: WorldMap
## False while something else drives the Hunter (departure walk, dungeon run).
var enabled := true
## Targeting rule while disabled (e.g. only the dungeon's enemies); unset = anything.
var override_filter: Callable
## Set by the world while the Hunter walks to a dungeon entrance (INF = not departing).
var depart_point := Vector2.INF
var _resting := false
var _think_in := 0.0
## Field crafting in progress (null = none) and the seconds left.
var _craft_recipe: RecipeDefinition
var _craft_left := 0.0
var _bubble: CraftBubble
var _rng := RandomNumberGenerator.new()


func setup(owner_hunter: Hunter, world_map: WorldMap) -> void:
	hunter = owner_hunter
	map = world_map
	name = "Brain"
	_rng.seed = hash(owner_hunter.runtime.unique_id)
	_think_in = _rng.randf_range(0.0, THINK_INTERVAL)
	hunter.combat.acquire_filter = _can_engage
	hunter.combat.keep_filter = _can_keep
	hunter.health.damaged.connect(_on_damaged)


func is_crafting() -> bool:
	return _craft_recipe != null


func _physics_process(delta: float) -> void:
	if _craft_recipe != null and enabled:
		_craft_left -= delta
		if _bubble != null:
			_bubble.progress = 1.0 - _craft_left / maxf(_craft_recipe.field_seconds, 0.01)
		if _craft_left <= 0.0:
			_finish_craft()
	_think_in -= delta
	if _think_in <= 0.0:
		_think_in = THINK_INTERVAL
		think()


## Re-evaluates now (also called when activities or the layout change).
func think() -> void:
	var runtime := hunter.runtime
	if runtime == null:
		return
	if not enabled or runtime.injured or not runtime.alive or not hunter.is_targetable():
		return
	runtime.world_position = hunter.global_position
	if depart_point != Vector2.INF:
		_set_task(DEPARTING)
		if hunter.combat.target == null:
			hunter.travel_target = depart_point
		return
	var body := GameManager.corpses.get_body_of(runtime)
	if body != null:
		_cancel_craft()
		_carry(body)
		return
	if _craft_recipe != null:
		return
	if _self_care():
		return
	var needs: NeedsService = GameManager.needs
	var regions: RegionService = GameManager.regions
	_resting = regions.needs_rest(runtime, _resting)
	var go_home := needs.wants_sleep(runtime, runtime.activity == ActivityService.SLEEPING) \
		or needs.wants_meal(runtime) or _resting or regions.is_bag_full(runtime)
	var duty_region := regions.get_duty_region(runtime)
	var in_town := map.world.region_at(hunter.global_position) == map.world.get_town()
	if in_town and _resting and GameManager.supply.best_medicine(runtime) != null:
		_set_task(&"")
		_visit_hospital()
		return
	if in_town and not runtime.loot_bag.is_empty():
		_set_task(runtime.task if runtime.task == HunterRuntime.HUNTING else &"")
		_deposit()
		return
	if in_town and GameManager.equipment.wants_repair(runtime):
		_set_task(&"")
		_repair()
		return
	if go_home or duty_region == null or (in_town and runtime.task == &"" and _busy_in_town(runtime)):
		_go_home(in_town)
	else:
		_hunt(duty_region)


## Eat / heal from its own bag, or start cooking / brewing with its talent (D46). True when busy.
func _self_care() -> bool:
	var runtime := hunter.runtime
	var talents: TalentService = GameManager.talents
	if GameManager.needs.is_hungry(runtime):
		if GameManager.needs.talents != null and talents.eat_from_bag(runtime) > 0.0:
			GameManager.needs.needs_changed.emit(runtime)
		elif _start_craft(talents.pick_recipe(runtime, TalentService.Kind.FOOD), COOKING):
			return true
	if GameManager.regions.needs_rest(runtime, false):
		if talents.use_medicine_from_bag(runtime) > 0.0:
			_resting = GameManager.regions.needs_rest(runtime, false)
		elif _start_craft(talents.pick_recipe(runtime, TalentService.Kind.MEDICINE), BREWING):
			return true
	return false


func _start_craft(recipe: RecipeDefinition, task: StringName) -> bool:
	if recipe == null:
		return false
	_craft_recipe = recipe
	_craft_left = recipe.field_seconds
	_show_bubble(task == BREWING)
	_set_task(task)
	hunter.travel_target = Vector2.INF
	hunter.stop()
	return true


func _finish_craft() -> void:
	var recipe := _craft_recipe
	_craft_recipe = null
	_hide_bubble()
	GameManager.talents.make_from_bag(hunter.runtime, recipe)
	# Use it right away, then decide again.
	_self_care()
	think()


func cancel_craft() -> void:
	_cancel_craft()


func _cancel_craft() -> void:
	if _craft_recipe == null:
		return
	_craft_recipe = null
	_hide_bubble()
	_set_task(&"")


func _show_bubble(brewing: bool) -> void:
	_hide_bubble()
	_bubble = CraftBubble.new()
	_bubble.brewing = brewing
	hunter.add_child(_bubble)


func _hide_bubble() -> void:
	if _bubble != null and is_instance_valid(_bubble):
		_bubble.queue_free()
	_bubble = null


## Being hit interrupts field crafting (nothing is used up).
func _on_damaged(_amount: float) -> void:
	if _craft_recipe != null:
		_cancel_craft()
		think()


## Town life the Hunter should finish before leaving (sleeping until rested, eating).
func _busy_in_town(runtime: HunterRuntime) -> bool:
	return runtime.activity == ActivityService.SLEEPING or runtime.activity == ActivityService.EATING


func _go_home(in_town: bool) -> void:
	if in_town:
		_set_task(&"")
	elif hunter.runtime.task != RETURNING:
		_set_task(RETURNING)
	hunter.travel_target = map.get_home_position(hunter.runtime)


func _hunt(region: RegionDefinition) -> void:
	_set_task(HunterRuntime.HUNTING)
	if hunter.combat.target != null:
		return
	# Walk towards the nearest monster of the duty region; it is engaged once in range.
	var best: Enemy = null
	var best_distance := INF
	for enemy in map.get_monsters(region.id):
		var distance := hunter.global_position.distance_squared_to(enemy.global_position)
		if distance < best_distance:
			best = enemy
			best_distance = distance
	if best != null:
		hunter.travel_target = best.global_position
	elif hunter.travel_target == Vector2.INF or hunter.global_position.distance_to(hunter.travel_target) < 12.0 \
			or map.world.region_at(hunter.travel_target) != region:
		hunter.travel_target = map.random_point_in(region, _rng)


## Fetch the assigned body, then drag it to the Temple (D30, D42). Carrying comes before needs.
func _carry(body: HunterRuntime) -> void:
	var corpses: CorpseService = GameManager.corpses
	var body_actor := map.get_hunter_actor(body.unique_id)
	if not corpses.is_carried(body):
		_set_task(FETCHING)
		var at := body_actor.global_position if body_actor != null else body.world_position
		if hunter.global_position.distance_to(at) <= PICK_UP_DISTANCE:
			corpses.pick_up(body)
			hunter.visual.play_action(ChibiAnimations.PICKUP)
			_set_task(CARRYING)
		else:
			hunter.travel_target = at
		return
	_set_task(CARRYING)
	var door := map.get_door(BuildingService.TEMPLE)
	if door == Vector2.INF:
		door = map.get_home_position(body)
	if _arrived(door):
		corpses.deliver(body)
		hunter.visual.play_action(ChibiAnimations.INTERACT)
		_set_task(&"")
		think()
		return
	hunter.travel_target = door


## Buys and uses medicine at the Hospital door (D41), then decides again.
func _visit_hospital() -> void:
	var door := map.get_door(BuildingService.HOSPITAL)
	if door == Vector2.INF or _arrived(door):
		GameManager.supply.treat(hunter.runtime)
		hunter.visual.play_action(ChibiAnimations.INTERACT)
		_resting = GameManager.regions.needs_rest(hunter.runtime, true)
		return
	hunter.travel_target = door


## A worn weapon goes to the Blacksmith; the Hunter pays from its purse (D64).
func _repair() -> void:
	var door := map.get_door(BuildingService.BLACKSMITH)
	if door == Vector2.INF or _arrived(door):
		GameManager.equipment.repair_by_hunter(hunter.runtime)
		hunter.visual.play_action(ChibiAnimations.INTERACT)
		return
	hunter.travel_target = door


## Loot goes to the Market when the Town has one, else to the Warehouse door (D63).
func _deposit() -> void:
	var door := map.get_door(BuildingService.MARKET)
	if door == Vector2.INF:
		door = map.get_door(BuildingService.WAREHOUSE)
	if door == Vector2.INF or _arrived(door):
		GameManager.regions.deposit(hunter.runtime)
		hunter.visual.play_action(ChibiAnimations.INTERACT)
		return
	hunter.travel_target = door


func _arrived(point: Vector2) -> bool:
	var distance := hunter.global_position.distance_to(point)
	return distance <= DEPOSIT_DISTANCE or (distance <= STOPPED_ARRIVE_DISTANCE and hunter.travel_target == point \
		and not hunter.state.is_state(StateController.State.MOVING))


func _set_task(task: StringName) -> void:
	var runtime := hunter.runtime
	if runtime.task == task:
		return
	runtime.task = task
	GameManager.activities.refresh(runtime)
	hunter.combat.recheck()


## Hunting Hunters engage monsters of the region they stand in, within range.
func _can_engage(candidate: Actor) -> bool:
	if not enabled:
		return _can_keep(candidate)
	return _can_keep(candidate) and \
		candidate.global_position.distance_to(hunter.global_position) <= DataRegistry.config.hunter_engage_range


func _can_keep(candidate: Actor) -> bool:
	if not enabled:
		# Something else drives the Hunter (dungeon run): its rule, not the world's.
		return not override_filter.is_valid() or override_filter.call(candidate)
	if hunter.runtime == null or (hunter.runtime.task != HunterRuntime.HUNTING and hunter.runtime.task != DEPARTING):
		return false
	var region := map.world.region_at(hunter.global_position)
	return region != null and not region.is_town and map.world.region_at(candidate.global_position) == region
