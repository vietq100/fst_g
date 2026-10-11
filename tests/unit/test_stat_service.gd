extends TestCase

var _stats: StatService


func before_each() -> void:
	_stats = StatService.new(GameConfig.new())


func test_stat_without_modifiers_uses_base_and_growth() -> void:
	# Warrior attack at level 4: 14 + 2 × 3
	assert_almost_eq(_stats.compute_stat(&"attack", 14.0, 2.0, 4), 20.0)
	assert_almost_eq(_stats.compute_stat(&"attack", 14.0, 2.0, 1), 14.0)


func test_flat_then_percent() -> void:
	var modifiers: Array[StatModifier] = [
		_modifier(&"attack", StatModifier.Type.FLAT, 7.0),
		_modifier(&"attack", StatModifier.Type.PERCENT, 0.05),
		_modifier(&"attack", StatModifier.Type.PERCENT, 0.15),
		_modifier(&"defense", StatModifier.Type.FLAT, 100.0),
	]
	# (14 + 7) × 1.2
	assert_almost_eq(_stats.compute_stat(&"attack", 14.0, 2.0, 1, modifiers), 25.2)


func test_conditional_modifier_needs_active_condition() -> void:
	var brave := _modifier(&"damage", StatModifier.Type.PERCENT, 0.15)
	brave.condition = &"vs_boss"
	var modifiers: Array[StatModifier] = [brave]
	assert_almost_eq(_stats.compute_stat(&"damage", 10.0, 0.0, 1, modifiers), 10.0)
	var active: Array[StringName] = [&"vs_boss"]
	assert_almost_eq(_stats.compute_stat(&"damage", 10.0, 0.0, 1, modifiers, active), 11.5)


func test_stat_never_negative() -> void:
	var modifiers: Array[StatModifier] = [_modifier(&"defense", StatModifier.Type.PERCENT, -2.0)]
	assert_almost_eq(_stats.compute_stat(&"defense", 6.0, 0.0, 1, modifiers), 0.0)


func test_damage_formula_and_minimum() -> void:
	assert_almost_eq(_stats.calculate_damage(14.0, 1.0), 13.5)
	assert_almost_eq(_stats.calculate_damage(6.0, 20.0), 1.0)


func test_critical() -> void:
	assert_almost_eq(_stats.apply_critical(10.0, 1.5), 15.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	assert_false(_stats.roll_critical(0.0, rng))
	assert_true(_stats.roll_critical(1.0, rng))


func test_attack_cooldown() -> void:
	assert_almost_eq(_stats.attack_cooldown(1.0), 1.0)
	assert_almost_eq(_stats.attack_cooldown(0.5), 2.0)
	assert_eq(_stats.attack_cooldown(0.0), INF)


func test_required_xp() -> void:
	# 30 × level^2.2, rounded up (D44)
	assert_eq(_stats.required_xp(1), 30)
	assert_eq(_stats.required_xp(2), 138)
	assert_eq(_stats.required_xp(4), 634)


func test_level_cap() -> void:
	assert_eq(_stats.level_cap(1), 10)
	assert_eq(_stats.level_cap(2), 20)
	assert_eq(_stats.level_cap(0), 10)


func _modifier(stat: StringName, type: StatModifier.Type, value: float) -> StatModifier:
	var modifier := StatModifier.new()
	modifier.stat = stat
	modifier.type = type
	modifier.value = value
	return modifier
