extends TestCase
## NeedsService, PurseService and their link with town activities
## (AUTONOMY_SYSTEM.md → Needs / Money, BALANCE.md → Needs / Money, DECISIONS.md D31, D32, D34).

const DataRegistryScript := preload("res://core/data_registry.gd")
const GameManagerScript := preload("res://core/game_manager.gd")

var _registry: Node
var _game: Node
var _hunter: HunterRuntime


func before_each() -> void:
	_registry = DataRegistryScript.new()
	_registry.report_errors = false
	_registry.load_all(DataRegistryScript.DATA_ROOT, DataRegistryScript.CONFIG_PATH)
	_game = GameManagerScript.new()
	_game.rng.seed = 3
	_game.build(_registry)
	_game.start_new_game()
	_hunter = _game.hunters.get_all()[0]


func after_each() -> void:
	_game.hunters.clear_modifier_sources()
	_game.bonds.set_party_provider(func() -> Array: return [])
	_game.free()
	_registry.free()


func test_new_hunters_start_full_with_a_purse() -> void:
	assert_almost_eq(_hunter.stamina, 100.0)
	assert_almost_eq(_hunter.energy, 100.0)
	assert_eq(_hunter.purse, 20)
	assert_eq(_hunter.home_id, _game.buildings.find_first(&"house").instance_id, "bed in the first House")


func test_active_tick_drains_both_needs() -> void:
	_game.needs.tick_hunter(_hunter, true, false)
	assert_almost_eq(_hunter.stamina, 98.5)
	assert_almost_eq(_hunter.energy, 99.4)
	_game.needs.tick_hunter(_hunter, false, false)
	assert_almost_eq(_hunter.stamina, 98.5, 0.0001, "idle does not tire")
	assert_almost_eq(_hunter.energy, 98.8)


func test_sleeping_in_a_bed_is_twice_as_good_as_outdoors() -> void:
	_hunter.stamina = 50.0
	_game.needs.tick_hunter(_hunter, false, true)
	assert_almost_eq(_hunter.stamina, 56.0)
	assert_almost_eq(_hunter.energy, 99.7)
	var mood := _hunter.mood
	_hunter.home_id = &""
	_game.needs.tick_hunter(_hunter, false, true)
	assert_almost_eq(_hunter.stamina, 59.0)
	assert_almost_eq(_hunter.mood, mood - 1.0, 0.0001, "outdoors costs mood")


func test_food_comes_from_the_village_stock() -> void:
	# A new village has 6 Meat Stew (12 g, +60 energy) (D40).
	var treasury: int = _game.wallet.gold
	_hunter.energy = 20.0
	assert_true(_game.needs.wants_meal(_hunter))
	assert_true(_game.needs.eat(_hunter))
	assert_almost_eq(_hunter.energy, 80.0)
	assert_eq(_hunter.purse, 8)
	assert_eq(_game.wallet.gold, treasury + 12)
	assert_eq(_game.inventory.count(&"meat_stew"), 5)
	_hunter.energy = 20.0
	assert_false(_game.needs.wants_meal(_hunter), "8 gold cannot pay for a stew")
	assert_eq(_game.supply.food_reason(_hunter), SupplyService.NO_MONEY_FOR_FOOD)
	_game.inventory.add_item(&"herb_soup", 1)
	assert_true(_game.needs.eat(_hunter), "the soup is affordable")
	assert_almost_eq(_hunter.energy, 60.0)
	assert_eq(_hunter.purse, 0)
	_game.inventory.remove_item(&"meat_stew", 5)
	_hunter.purse = 100
	assert_false(_game.needs.eat(_hunter))
	assert_eq(_game.supply.food_reason(_hunter), SupplyService.NO_FOOD)


func test_medicine_heals_and_pays_the_village() -> void:
	var max_hp: float = _game.hunters.get_stat(_hunter, HunterService.MAX_HP)
	_hunter.current_hp = max_hp * 0.2
	_hunter.purse = 40
	assert_null(_game.supply.best_medicine(_hunter), "nothing made yet")
	_game.inventory.add_item(&"bandage", 2)
	_game.inventory.add_item(&"healing_potion", 1)
	var treasury: int = _game.wallet.gold
	var healed: float = _game.supply.treat(_hunter)
	assert_almost_eq(healed, max_hp * 0.7, 0.01, "the strongest affordable medicine")
	assert_eq(_hunter.purse, 15)
	assert_eq(_game.wallet.gold, treasury + 25)
	assert_almost_eq(_game.supply.treat(_hunter), max_hp * 0.1, 0.01, "a bandage, capped at max HP")
	assert_eq(_game.inventory.count(&"bandage"), 1)


func test_starving_drains_hp_but_never_kills() -> void:
	var max_hp: float = _game.hunters.get_stat(_hunter, HunterService.MAX_HP)
	_hunter.energy = 0.0
	_hunter.current_hp = max_hp
	_game.needs.tick_hunter(_hunter, false, false)
	assert_almost_eq(_hunter.current_hp, max_hp * 0.98, 0.001)
	_hunter.current_hp = 1.5
	_game.needs.tick_hunter(_hunter, false, false)
	assert_almost_eq(_hunter.current_hp, 1.0)
	assert_eq(int(_game.needs.take_report()["hungry_ticks"]), 2)


func test_exhaustion_slows_move_and_attacks() -> void:
	var speed: float = _game.hunters.get_stat(_hunter, HunterService.MOVE_SPEED)
	var attack_speed: float = _game.hunters.get_stat(_hunter, HunterService.ATTACK_SPEED)
	_hunter.stamina = 1.0
	_game.needs.tick_hunter(_hunter, true, false)
	assert_true(_game.needs.is_exhausted(_hunter))
	assert_almost_eq(_game.hunters.get_stat(_hunter, HunterService.MOVE_SPEED), speed * 0.6, 0.01)
	assert_almost_eq(_game.hunters.get_stat(_hunter, HunterService.ATTACK_SPEED), attack_speed * 0.7, 0.01)


func test_transfers_cost_ten_percent() -> void:
	var purses: PurseService = _game.purses
	_game.wallet.gold = 100
	assert_eq(purses.give(_hunter, 50), "")
	assert_eq(_game.wallet.gold, 50)
	assert_eq(_hunter.purse, 65, "20 + 45")
	assert_eq(purses.take(_hunter, 65), "")
	assert_eq(_hunter.purse, 0)
	assert_eq(_game.wallet.gold, 108, "50 + floor(65 × 0.9)")
	assert_false(purses.take(_hunter, 1).is_empty())
	assert_false(purses.give(_hunter, 500).is_empty())
	assert_eq(purses.get_fee(50), 5)


func test_town_life_sleeps_and_eats_on_its_own() -> void:
	var activities: ActivityService = _game.activities
	_hunter.stamina = 10.0
	activities.tick(10.0)
	assert_eq(_hunter.activity, ActivityService.SLEEPING)
	# Keeps sleeping until rested (95), then goes back to normal life.
	activities.tick(10.0 * 15)
	assert_true(_hunter.stamina >= 95.0)
	assert_false(_hunter.activity == ActivityService.SLEEPING)
	_hunter.energy = 20.0
	var purse := _hunter.purse
	activities.tick(10.0)
	assert_eq(_hunter.purse, purse - 12, "ate a Meat Stew")
	assert_true(_hunter.energy > 70.0)


func test_offline_summary_counts_meals() -> void:
	var save: Node = preload("res://core/save_manager.gd").new()
	save.game = _game
	_hunter.energy = 36.0
	var summary: Dictionary = save.apply_offline_progress(600.0)
	assert_true(int(summary.get("meals", 0)) >= 1, str(summary))
	save.free()
