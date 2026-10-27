extends TestCase
## RegionService: duty, monster scaling, kill rewards, loot bag, deposit; hunting Hunters in
## ActivityService (AUTONOMY_SYSTEM.md → Hunting, BALANCE.md → Regions, DECISIONS.md D29, D36).

const DataRegistryScript := preload("res://core/data_registry.gd")
const GameManagerScript := preload("res://core/game_manager.gd")

var _registry: Node
var _game: Node
var _regions: RegionService
var _hunter: HunterRuntime


func before_each() -> void:
	_registry = DataRegistryScript.new()
	_registry.report_errors = false
	_registry.load_all(DataRegistryScript.DATA_ROOT, DataRegistryScript.CONFIG_PATH)
	_game = GameManagerScript.new()
	_game.rng.seed = 9
	_game.build(_registry)
	_game.start_new_game()
	_regions = _game.regions
	_hunter = _game.hunters.get_all()[0]


func after_each() -> void:
	_game.hunters.clear_modifier_sources()
	_game.bonds.set_party_provider(func() -> Array: return [])
	_game.free()
	_registry.free()


func test_auto_duty_follows_level() -> void:
	assert_eq(_regions.get_duty_region(_hunter).id, &"dark_forest")
	_hunter.level = 5
	assert_eq(_regions.get_duty_region(_hunter).id, &"goblin_cave")
	_hunter.level = 12
	assert_eq(_regions.get_duty_region(_hunter).id, &"ancient_ruins")


func test_fixed_duty_and_stay_in_town() -> void:
	assert_eq(_regions.set_duty(_hunter, &"ancient_ruins"), "")
	assert_eq(_regions.get_duty_region(_hunter).id, &"ancient_ruins")
	assert_eq(_regions.set_duty(_hunter, HunterRuntime.STAY_IN_TOWN), "")
	assert_null(_regions.get_duty_region(_hunter))
	assert_false(_regions.set_duty(_hunter, &"town").is_empty(), "the Town is not a hunting duty")
	assert_eq(_regions.get_duty_options().size(), 6, "Auto, 3 regions, the Boss Arena, Stay in town")


func test_monster_level_scaling() -> void:
	assert_almost_eq(_regions.get_stat_scale(1), 1.0)
	assert_almost_eq(_regions.get_stat_scale(6), 1.6)
	assert_almost_eq(_regions.get_reward_scale(11), 2.0)
	var ruins: RegionDefinition = _game.world.get_region(&"ancient_ruins")
	for i in 20:
		var level := _regions.roll_level(ruins)
		assert_true(level >= 8 and level <= 12, str(level))
		assert_true([&"skeleton", &"goblin"].has(_regions.roll_monster(ruins).id))


func test_kill_rewards_go_to_purse_bag_and_xp() -> void:
	var helper: HunterRuntime = _game.hunters.create_hunter(&"warrior", _game.rng)
	var skeleton := _registry.find_def(&"enemy", &"skeleton") as EnemyDefinition
	var purse := _hunter.purse
	var reward := _regions.record_kill(_hunter, [helper] as Array[HunterRuntime], skeleton, 1)
	assert_true(reward.gold >= 8 and reward.gold <= 14, str(reward.gold))
	assert_eq(_hunter.purse, purse + reward.gold)
	assert_eq(helper.purse, 20, "helpers get XP only")
	assert_true(_hunter.xp > 0 and helper.xp > 0, "killer and helper both get XP")
	assert_eq(_regions.get_bag_count(_hunter), reward.items.values().reduce(func(a: int, b: int) -> int: return a + b, 0))


func test_loot_bag_capacity_and_selling_to_the_village() -> void:
	assert_eq(_regions.add_to_bag(_hunter, &"iron_ore", 7), 7)
	assert_eq(_regions.add_to_bag(_hunter, &"beast_fang", 7), 3, "bag holds 10")
	assert_true(_regions.is_bag_full(_hunter))
	var before: int = _game.inventory.count(&"iron_ore")
	var treasury: int = _game.wallet.gold
	var purse := _hunter.purse
	var report := _regions.deposit(_hunter)
	# Iron Ore 3 g, Beast Fang 4 g: the village pays 7 × 3 + 3 × 4 = 33 (D39).
	assert_eq(_game.inventory.count(&"iron_ore"), before + 7)
	assert_eq(int(report["items"][&"beast_fang"]), 3)
	assert_eq(int(report["village_gold"]), 33)
	assert_eq(_game.wallet.gold, treasury - 33)
	assert_eq(_hunter.purse, purse + 33)
	assert_eq(_regions.get_bag_count(_hunter), 0)


func test_trader_buys_what_the_village_cannot() -> void:
	_game.wallet.gold = 7
	var purse := _hunter.purse
	_regions.add_to_bag(_hunter, &"iron_ore", 4)
	var report := _regions.deposit(_hunter)
	assert_eq(int(report["items"][&"iron_ore"]), 2, "the treasury could pay for 2")
	assert_eq(int(report["village_gold"]), 6)
	assert_eq(int(report["trader_gold"]), 6)
	assert_eq(_game.wallet.gold, 1)
	assert_eq(_hunter.purse, purse + 12, "the Hunter is always paid")
	_game.buildings.remove(_game.buildings.find_first(&"warehouse").instance_id)
	_game.wallet.gold = 500
	_regions.add_to_bag(_hunter, &"bone_dust", 2)
	report = _regions.deposit(_hunter)
	assert_eq(int(report["trader_gold"]), 10, "no Warehouse (no free slot): all to the trader")


func test_trader_tax_credited_to_treasury() -> void:
	_game.config.trader_tax_rate = 0.20  # 20% tax
	_game.wallet.gold = 100
	var initial_treasury: int = _game.wallet.gold
	var purse := _hunter.purse
	_game.buildings.remove(_game.buildings.find_first(&"warehouse").instance_id)
	_regions.add_to_bag(_hunter, &"bone_dust", 2)  # 2 * 5g = 10g
	var report := _regions.deposit(_hunter)
	# 20% of 10g is 2g tax -> 8g to hunter, 2g to treasury
	assert_eq(int(report["trader_gold"]), 8)
	assert_eq(int(report["trader_tax"]), 2)
	assert_eq(_hunter.purse, purse + 8)
	assert_eq(_game.wallet.gold, initial_treasury + 2)
	_game.config.trader_tax_rate = 0.0


func test_rest_threshold_has_hysteresis() -> void:
	_hunter.trait_ids.clear()  # personality moves the threshold (test_hunter_ai.gd)
	var max_hp: float = _game.hunters.get_stat(_hunter, HunterService.MAX_HP)
	_hunter.current_hp = max_hp * 0.5
	assert_false(_regions.needs_rest(_hunter, false))
	assert_true(_regions.needs_rest(_hunter, true), "keeps resting until 90%")
	_hunter.current_hp = max_hp * 0.3
	assert_true(_regions.needs_rest(_hunter, false))


func test_hunting_hunters_tire_online_and_freeze_offline() -> void:
	_hunter.task = HunterRuntime.HUNTING
	_game.advance_town_time(10.0)
	assert_eq(_hunter.activity, ActivityService.HUNTING)
	assert_almost_eq(_hunter.stamina, 98.5)
	_game.advance_town_time(100.0, true)
	assert_almost_eq(_hunter.stamina, 98.5, 0.0001, "frozen while the app is closed")
