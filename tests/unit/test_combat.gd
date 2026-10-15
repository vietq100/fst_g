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


func test_skill_hits_nearby_targets_with_multiplier_and_effect() -> void:
	var attacker := _slime()
	var target := _slime()
	target.global_position = Vector2(100, 100)
	var near := _slime()
	near.global_position = Vector2(120, 100)
	var far := _slime()
	far.global_position = Vector2(300, 100)
	var used: Array = []
	_service.skill_used.connect(func(_a: Actor, hit: Array[Actor], skill: ActiveSkillDefinition) -> void: used.append([hit, skill.id]))
	var bash := ActiveSkillDefinition.new()
	bash.id = &"test_bash"
	bash.damage = 2.0
	bash.radius = 50.0
	bash.targets = 2
	bash.effect_id = &"stun"
	bash.self_effect_id = &"fortify"
	var hit := _service.resolve_skill(attacker, target, bash)
	assert_eq(hit, [target, near] as Array[Actor], "target first, then the nearest within range")
	assert_almost_eq(target.health.current_health, 30.0 - 11.0, 0.0001, "5.5 × 2")
	assert_almost_eq(near.health.current_health, 19.0)
	assert_almost_eq(far.health.current_health, 30.0, 0.0001, "out of range")
	assert_false(target.effects.can_attack(), "stunned")
	assert_false(near.effects.can_attack(), "stunned")
	assert_true(far.effects.can_attack())
	assert_true(attacker.effects.has_effect(&"fortify"), "self buff")
	assert_eq(used.size(), 1)
	assert_eq(used[0][1], &"test_bash")
	# Buff-only skill: no damage, heals the user.
	var hurt := _slime()
	hurt.health.take_damage(15.0)
	var mend := ActiveSkillDefinition.new()
	mend.id = &"test_mend"
	mend.damage = 0.0
	mend.heal_ratio = 0.5
	assert_eq(_service.resolve_skill(hurt, target, mend).size(), 0)
	assert_almost_eq(hurt.health.current_health, 30.0)
	assert_almost_eq(target.health.current_health, 19.0, 0.0001, "untouched by a buff")


func test_actor_uses_a_ready_skill_then_waits_for_the_cooldown() -> void:
	var definition := (_registry.find_def(&"enemy", &"goblin") as EnemyDefinition)
	var goblin := definition.actor_scene.instantiate() as Enemy
	(Engine.get_main_loop() as SceneTree).root.add_child(goblin)
	_actors.append(goblin)
	goblin.setup(definition, _service, 0.5)
	assert_eq(goblin.get_active_skills().size(), 2, "two monster skills")
	# Gear: the Goblin Club adds +2 attack to the base 10.
	assert_almost_eq(goblin.get_combat_stats().attack, 12.0)
	var target := _slime()
	var skills: Array[StringName] = []
	_service.skill_used.connect(func(_a: Actor, _hit: Array[Actor], skill: ActiveSkillDefinition) -> void: skills.append(skill.id))
	goblin._strike(target)
	assert_eq(skills, [&"dirty_trick"] as Array[StringName], "first skill, ready at once")
	assert_true(goblin.get_skill_cooldown(&"dirty_trick") > 0.0)
	goblin._strike(target)
	assert_eq(skills.size(), 2, "second skill is ready too")
	goblin._strike(target)
	assert_eq(skills.size(), 2, "both on cooldown: plain attack")


func _slime(definition: EnemyDefinition = null) -> Enemy:
	if definition == null:
		definition = _registry.find_def(&"enemy", &"slime") as EnemyDefinition
	var enemy := definition.actor_scene.instantiate() as Enemy
	(Engine.get_main_loop() as SceneTree).root.add_child(enemy)
	enemy.setup(definition, _service, 0.5)
	_actors.append(enemy)
	return enemy
