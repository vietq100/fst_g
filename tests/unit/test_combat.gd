extends TestCase
## CombatService against real Slime actors added to the running SceneTree.

const DataRegistryScript := preload("res://core/data_registry.gd")

var _registry: Node
var _service: CombatService
var _rng: RandomNumberGenerator
var _actors: Array[Node] = []


func before_each() -> void:
	_registry = DataRegistryScript.new()
	_registry.report_errors = false
	_registry.load_all(DataRegistryScript.DATA_ROOT, DataRegistryScript.CONFIG_PATH)
	_rng = RandomNumberGenerator.new()
	_rng.seed = 7
	_service = CombatService.new(StatService.new(_registry.config), _rng)


func after_each() -> void:
	for actor in _actors:
		actor.free()
	_actors.clear()
	_registry.free()


func test_damage_uses_formula() -> void:
	var attacker := _slime()
	var target := _slime()
	# Slime vs Slime: max(1, 6 - 1 × 0.5) = 5.5, no crit (chance 0).
	assert_almost_eq(_service.resolve_attack(attacker, target), 5.5)
	assert_almost_eq(target.health.current_health, 24.5)


func test_signals_and_defeat() -> void:
	var attacker := _slime()
	var target := _slime()
	var hits: Array[float] = []
	var defeated: Array[Actor] = []
	_service.damage_dealt.connect(func(_a: Actor, _t: Actor, amount: float, _c: bool) -> void: hits.append(amount))
	_service.actor_defeated.connect(func(actor: Actor, _by: Actor) -> void: defeated.append(actor))
	for i in 6:
		_service.resolve_attack(attacker, target)
	# 5 hits × 5.5 = 27.5, 6th hit only has 2.5 HP left; 7th attack is refused.
	assert_almost_eq(hits[5], 2.5)
	assert_eq(defeated, [target] as Array[Actor])
	assert_true(target.health.is_dead())
	assert_almost_eq(_service.resolve_attack(attacker, target), 0.0, 0.0001, "dead target")
	assert_eq(hits.size(), 6)


func test_critical_hit_applies_multiplier() -> void:
	var definition := (_registry.find_def(&"enemy", &"slime") as EnemyDefinition).duplicate() as EnemyDefinition
	definition.critical_chance = 1.0
	definition.critical_damage = 2.0
	var attacker := _slime(definition)
	var target := _slime()
	var crits: Array[bool] = []
	_service.damage_dealt.connect(func(_a: Actor, _t: Actor, _amount: float, critical: bool) -> void: crits.append(critical))
	assert_almost_eq(_service.resolve_attack(attacker, target), 11.0)
	assert_eq(crits, [true] as Array[bool])


func test_attack_cooldown_from_speed() -> void:
	# Slime attack speed 0.7 → 1 / 0.7 s.
	assert_almost_eq(_service.attack_cooldown(_slime()), 1.0 / 0.7)


func test_slots_are_unique_and_nearest() -> void:
	var target := _slime()
	target.global_position = Vector2(100, 100)
	var below := _slime()
	below.global_position = Vector2(100, 160)
	var also_below := _slime()
	also_below.global_position = Vector2(102, 160)
	# Slots are only kept by attackers that actually target the slot owner.
	below.combat.target = target
	also_below.combat.target = target
	var first := target.combat.claim_slot(below, 15.0, 18.0)
	var second := target.combat.claim_slot(also_below, 15.0, 18.0)
	# First attacker gets the slot straight below the target (slot 0).
	assert_true(first.distance_to(Vector2(100, 115)) < 0.01, "got %s" % first)
	assert_true(first.distance_to(second) > 10.0, "slots differ")
	# Claiming again returns the same slot.
	assert_eq(target.combat.claim_slot(below, 15.0, 18.0), first)
	assert_eq(target.combat.get_claimed_slot_count(), 2)
	target.combat.release_slot(below)
	assert_eq(target.combat.get_claimed_slot_count(), 1)


func test_slots_run_out() -> void:
	var target := _slime()
	target.global_position = Vector2(100, 100)
	var points: Array[Vector2] = []
	for i in CombatController.SLOT_COUNT + 1:
		var attacker := _slime()
		attacker.global_position = Vector2(100, 200)
		attacker.combat.target = target
		points.append(target.combat.claim_slot(attacker, 15.0, 18.0))
	assert_eq(points.count(Vector2.INF), 1, "one attacker has to wait")
	assert_eq(target.combat.get_claimed_slot_count(), CombatController.SLOT_COUNT)


func _slime(definition: EnemyDefinition = null) -> Enemy:
	if definition == null:
		definition = _registry.find_def(&"enemy", &"slime") as EnemyDefinition
	var enemy := definition.actor_scene.instantiate() as Enemy
	(Engine.get_main_loop() as SceneTree).root.add_child(enemy)
	enemy.setup(definition, _service, 0.5)
	_actors.append(enemy)
	return enemy
