extends TestCase

const DataRegistryScript := preload("res://core/data_registry.gd")

var _registry: Node
var _service: HunterService
var _rng: RandomNumberGenerator


func before_each() -> void:
	_registry = DataRegistryScript.new()
	_registry.report_errors = false
	_registry.load_all(DataRegistryScript.DATA_ROOT, DataRegistryScript.CONFIG_PATH)
	_service = HunterService.new(_registry, StatService.new(_registry.config), _registry.config)
	_rng = RandomNumberGenerator.new()
	_rng.seed = 42


func after_each() -> void:
	_registry.free()


func test_create_hunter_from_definition() -> void:
	var hunter := _service.create_hunter(&"warrior", _rng)
	assert_not_null(hunter)
	assert_eq(hunter.definition_id, &"warrior")
	assert_eq(hunter.level, 1)
	assert_eq(hunter.state, HunterRuntime.LifecycleState.AVAILABLE)
	assert_almost_eq(hunter.mood, 60.0)
	assert_almost_eq(hunter.current_hp, _service.get_stat(hunter, HunterService.MAX_HP))
	assert_eq(_service.count(), 1)
	assert_eq(_service.get_hunter(hunter.unique_id), hunter)


func test_unknown_definition_returns_null() -> void:
	assert_null(_service.create_hunter(&"dragon", _rng))
	assert_eq(_service.count(), 0)


func test_unique_ids() -> void:
	var first := _service.create_hunter(&"warrior", _rng)
	var second := _service.create_hunter(&"warrior", _rng)
	assert_true(first.unique_id != second.unique_id)
	assert_true(first.display_name != second.display_name)


func test_stat_rolls_stay_within_variance() -> void:
	for i in 50:
		var hunter := _service.create_hunter(&"warrior", _rng)
		for stat in HunterService.ROLLED_STATS:
			var roll: float = hunter.stat_rolls[stat]
			assert_true(roll >= -0.1 and roll <= 0.1, "roll %f for %s" % [roll, stat])
		var attack := _service.get_stat(hunter, HunterService.ATTACK) / Tier.stat_scale(hunter.tier)
		assert_true(attack >= 14.0 * 0.9 - 0.001 and attack <= 14.0 * 1.1 + 0.001)
		assert_true(hunter.tier <= Tier.RANDOM_MAX, "LR and Mythic are never rolled")


func test_stats_without_rolls_match_balance() -> void:
	var hunter := _service.create_hunter(&"warrior", _rng)
	hunter.stat_rolls.clear()
	hunter.tier = Tier.Level.C
	assert_almost_eq(_service.get_stat(hunter, HunterService.MAX_HP), 120.0)
	assert_almost_eq(_service.get_stat(hunter, HunterService.ATTACK), 14.0)
	assert_almost_eq(_service.get_stat(hunter, HunterService.DEFENSE), 6.0)
	assert_almost_eq(_service.get_stat(hunter, HunterService.MOVE_SPEED), 80.0)
	assert_almost_eq(_service.get_stat(hunter, HunterService.CRITICAL_CHANCE), 0.05)


func test_set_level_grows_stats_and_emits() -> void:
	var hunter := _service.create_hunter(&"warrior", _rng)
	hunter.stat_rolls.clear()
	hunter.tier = Tier.Level.C
	var changed: Array[HunterRuntime] = []
	_service.hunter_changed.connect(func(h: HunterRuntime) -> void: changed.append(h))
	_service.set_level(hunter, 4)
	assert_eq(hunter.level, 4)
	assert_almost_eq(_service.get_stat(hunter, HunterService.MAX_HP), 156.0)
	assert_almost_eq(_service.get_stat(hunter, HunterService.ATTACK), 20.0)
	assert_eq(changed.size(), 1)


func test_tiers_scale_stats_and_survive_a_save() -> void:
	var hunter := _service.create_hunter(&"warrior", _rng)
	hunter.stat_rolls.clear()
	hunter.tier = Tier.Level.C
	var base := _service.get_stat(hunter, HunterService.ATTACK)
	hunter.tier = Tier.Level.SSR
	assert_almost_eq(_service.get_stat(hunter, HunterService.ATTACK), base * Tier.stat_scale(Tier.Level.SSR))
	assert_eq(HunterRuntime.from_dict(hunter.to_dict()).tier, Tier.Level.SSR)
	assert_eq(HunterRuntime.from_dict({"unique_id": "h_9"}).tier, Tier.Level.C, "old saves: Common")
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var seen := {}
	for i in 2000:
		seen[Tier.roll(rng, Tier.HUNTER_WEIGHTS)] = true
	assert_false(seen.has(Tier.Level.LR) or seen.has(Tier.Level.MYTHIC), "LR / Mythic are declared only")
	assert_true(seen.has(Tier.Level.UR), "UR can be rolled")
	assert_true(Tier.is_fixed(Tier.Level.LR) and Tier.is_fixed(Tier.Level.MYTHIC) and not Tier.is_fixed(Tier.Level.UR))
