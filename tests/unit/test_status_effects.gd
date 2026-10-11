extends TestCase
## Status effects (D48) on real Slime actors: stacking, ticks, crowd control, stats, shields,
## thorns, lifesteal, on-hit effects and dispel. Time is stepped with advance().

const DataRegistryScript := preload("res://core/data_registry.gd")

var _registry: Node
var _service: CombatService
var _actors: Array[Node] = []


func before_each() -> void:
	_registry = DataRegistryScript.new()
	_registry.report_errors = false
	_registry.load_all(DataRegistryScript.DATA_ROOT, DataRegistryScript.CONFIG_PATH)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	_service = CombatService.new(StatService.new(_registry.config), rng)


func after_each() -> void:
	for actor in _actors:
		actor.free()
	_actors.clear()
	_registry.free()


func test_every_effect_loads() -> void:
	var ids: Array[StringName] = _registry.get_ids(DataRegistryScript.STATUS_EFFECT)
	assert_eq(ids.size(), 20)
	for id in [&"poison", &"burn", &"bleed", &"regeneration", &"stun", &"freeze", &"root", &"disarm",
			&"slow", &"haste", &"weaken", &"strength", &"armor_break", &"fortify", &"focus",
			&"vulnerable", &"shield", &"invulnerable", &"thorns", &"lifesteal"]:
		assert_true(ids.has(id), String(id))
	assert_eq(_registry.load_errors.size(), 0)


func test_stack_refresh_and_ignore() -> void:
	var slime := _slime()
	var poison := _effect(&"poison")
	slime.effects.apply(poison)
	slime.effects.advance(2.0)
	var effect := slime.effects.apply(poison, null, 2)
	assert_eq(effect.stacks, 3)
	assert_almost_eq(effect.remaining, poison.duration, 0.0001, "stacking refreshes")
	slime.effects.apply(poison, null, 9)
	assert_eq(effect.stacks, poison.max_stacks)
	var stun := _effect(&"stun")
	slime.effects.apply(stun)
	slime.effects.advance(1.0)
	slime.effects.apply(stun)
	assert_almost_eq(slime.effects.get_effect(&"stun").remaining, stun.duration - 1.0, 0.0001, "stun cannot be chained")


func test_expires_after_duration() -> void:
	var slime := _slime()
	var removed: Array[StringName] = []
	slime.effects.effect_removed.connect(func(e: StatusEffect) -> void: removed.append(e.get_id()))
	slime.effects.apply(_effect(&"haste"))
	slime.effects.advance(5.9)
	assert_true(slime.effects.has_effect(&"haste"))
	slime.effects.advance(0.2)
	assert_false(slime.effects.has_effect(&"haste"))
	assert_eq(removed, [&"haste"] as Array[StringName])


func test_damage_over_time_ticks_and_credits_kill() -> void:
	var source := _slime()
	var slime := _slime()
	var defeated: Array[Actor] = []
	var by: Array[Actor] = []
	_service.actor_defeated.connect(func(a: Actor, b: Actor) -> void:
		defeated.append(a)
		by.append(b))
	slime.effects.apply(_effect(&"poison"), source, 5)
	slime.effects.advance(1.0)
	# 2 per stack × 5 stacks.
	assert_almost_eq(slime.health.current_health, 20.0)
	slime.effects.advance(2.0)
	assert_true(slime.health.is_dead())
	assert_eq(defeated, [slime] as Array[Actor])
	assert_eq(by, [source] as Array[Actor])
	assert_true(slime.effects.get_effects().is_empty(), "death clears effects")


func test_ratio_ticks_and_regeneration() -> void:
	var slime := _slime()
	slime.effects.apply(_effect(&"bleed"), null, 3)
	slime.effects.advance(1.0)
	# 1% of 30 × 3 stacks.
	assert_almost_eq(slime.health.current_health, 29.1)
	slime.effects.clear_all()
	slime.health.take_damage(10.0)
	slime.effects.apply(_effect(&"regeneration"))
	slime.effects.advance(2.0)
	# 3% of 30 per second.
	assert_almost_eq(slime.health.current_health, 19.1 + 1.8)


func test_crowd_control_flags() -> void:
	var slime := _slime()
	slime.effects.apply(_effect(&"root"))
	assert_false(slime.effects.can_move())
	assert_true(slime.can_attack())
	slime.effects.clear_all()
	slime.effects.apply(_effect(&"disarm"))
	assert_true(slime.effects.can_move())
	assert_false(slime.can_attack())
	slime.effects.clear_all()
	slime.effects.apply(_effect(&"freeze"))
	assert_false(slime.effects.can_move())
	assert_false(slime.can_attack())
	assert_true(slime.effects.is_stunned())


func test_stat_modifiers_change_damage_and_speed() -> void:
	var attacker := _slime()
	var target := _slime()
	attacker.effects.apply(_effect(&"weaken"))
	# (6 × 0.7) - 1 × 0.5 = 3.7
	assert_almost_eq(_service.resolve_attack(attacker, target), 3.7)
	attacker.effects.clear_all()
	target.effects.apply(_effect(&"vulnerable"), null, 3)
	# 5.5 × (1 + 0.3)
	assert_almost_eq(_service.resolve_attack(attacker, target), 7.15)
	attacker.effects.apply(_effect(&"haste"))
	assert_almost_eq(_service.attack_cooldown(attacker), 1.0 / (0.7 * 1.3))
	attacker.effects.apply(_effect(&"slow"))
	assert_almost_eq(_service.attack_cooldown(attacker), 1.0 / (0.7 * 1.1))
	assert_almost_eq(attacker.get_final_move_speed(), attacker.get_move_speed())


func test_shield_absorbs_then_breaks() -> void:
	var attacker := _slime()
	var target := _slime()
	target.effects.apply(_effect(&"shield"))
	for i in 5:
		assert_almost_eq(_service.resolve_attack(attacker, target), 0.0)
	assert_almost_eq(target.effects.get_shield_total(), 2.5)
	# 6th hit: 2.5 absorbed, 3 to HP, shield gone.
	assert_almost_eq(_service.resolve_attack(attacker, target), 3.0)
	assert_false(target.effects.has_effect(&"shield"))


func test_invulnerable_takes_nothing() -> void:
	var attacker := _slime()
	var target := _slime()
	target.effects.apply(_effect(&"invulnerable"))
	assert_almost_eq(_service.resolve_attack(attacker, target), 0.0)
	target.effects.apply(_effect(&"poison"))
	target.effects.advance(1.0)
	assert_almost_eq(target.health.current_health, 30.0)


func test_thorns_and_lifesteal() -> void:
	var attacker := _slime()
	var target := _slime()
	target.effects.apply(_effect(&"thorns"))
	_service.resolve_attack(attacker, target)
	assert_almost_eq(attacker.health.current_health, 30.0 - 5.5 * 0.3)
	attacker.effects.apply(_effect(&"lifesteal"))
	_service.resolve_attack(attacker, target)
	assert_almost_eq(attacker.health.current_health, 30.0 - 5.5 * 0.3 * 2.0 + 5.5 * 0.25)


func test_on_hit_effect_applies() -> void:
	var definition := (_registry.find_def(&"enemy", &"slime") as EnemyDefinition).duplicate() as EnemyDefinition
	var bite := StatusEffectChance.new()
	bite.effect = _effect(&"poison")
	bite.chance = 1.0
	definition.on_hit_effects = [bite] as Array[StatusEffectChance]
	var attacker := _slime(definition)
	var target := _slime()
	_service.resolve_attack(attacker, target)
	assert_eq(target.effects.get_effect(&"poison").get_source(), attacker)


func test_dispel_keeps_undispellable() -> void:
	var slime := _slime()
	for id in [&"poison", &"slow", &"haste", &"invulnerable"]:
		slime.effects.apply(_effect(id))
	assert_eq(slime.effects.dispel(StatusEffectDefinition.Kind.DEBUFF), 2)
	assert_eq(slime.effects.dispel(StatusEffectDefinition.Kind.BUFF), 1)
	assert_true(slime.effects.has_effect(&"invulnerable"))


func test_revive_clears_and_dead_cannot_gain_effects() -> void:
	var slime := _slime()
	slime.health.take_damage(100.0)
	assert_null(slime.effects.apply(_effect(&"haste")))
	slime.revive(10.0)
	assert_not_null(slime.effects.apply(_effect(&"haste")))


func _effect(id: StringName) -> StatusEffectDefinition:
	return _registry.find_def(DataRegistryScript.STATUS_EFFECT, id) as StatusEffectDefinition


func _slime(definition: EnemyDefinition = null) -> Enemy:
	if definition == null:
		definition = _registry.find_def(&"enemy", &"slime") as EnemyDefinition
	var enemy := definition.actor_scene.instantiate() as Enemy
	(Engine.get_main_loop() as SceneTree).root.add_child(enemy)
	enemy.setup(definition, _service, 0.5)
	_actors.append(enemy)
	return enemy
