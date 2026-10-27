extends TestCase
## Hunter Gate dismissal and the weekly boss (DECISIONS.md D58).

const DataRegistryScript := preload("res://core/data_registry.gd")

var _registry: Node
var _wallet: WalletService
var _inventory: InventoryService
var _progress: ProgressService
var _hunters: HunterService
var _buildings: BuildingService
var _recruitment: RecruitmentService
var _world: WorldService
var _boss: WeeklyBossService
var _rng: RandomNumberGenerator


func before_each() -> void:
	_registry = DataRegistryScript.new()
	_registry.load_all(DataRegistryScript.DATA_ROOT, DataRegistryScript.CONFIG_PATH)
	var config: GameConfig = _registry.config
	_rng = RandomNumberGenerator.new()
	_rng.seed = 7
	_wallet = WalletService.new()
	_inventory = InventoryService.new(_registry, _wallet)
	_progress = ProgressService.new()
	_hunters = HunterService.new(_registry, StatService.new(config), config)
	_world = WorldService.new(_registry)
	_buildings = BuildingService.new(_registry, _wallet, _inventory, _progress, _world)
	_recruitment = RecruitmentService.new(_registry, _hunters, _buildings, _wallet, _rng)
	_boss = WeeklyBossService.new(_registry, _world, _hunters, _wallet, _inventory)


func after_each() -> void:
	_registry.free()


func test_expel_removes_the_hunter_for_good() -> void:
	var hunter := _hunters.create_hunter(&"warrior", _rng)
	var removed: Array[StringName] = []
	_hunters.hunter_removed.connect(func(h: HunterRuntime) -> void: removed.append(h.unique_id))
	assert_eq(_recruitment.can_dismiss(hunter), "")
	assert_eq(_recruitment.dismiss(hunter), "")
	assert_eq(_hunters.count(), 0)
	assert_eq(removed, [hunter.unique_id])
	assert_null(_hunters.get_hunter(hunter.unique_id))
	assert_eq(_recruitment.dismiss(hunter), "Unknown Hunter")


func test_expel_refuses_dungeon_runs_and_the_dead() -> void:
	var hunter := _hunters.create_hunter(&"warrior", _rng)
	hunter.expedition_id = &"dark_forest"
	assert_eq(_recruitment.can_dismiss(hunter), "On a dungeon run")
	hunter.expedition_id = &""
	hunter.alive = false
	assert_eq(_recruitment.can_dismiss(hunter), "Revive this Hunter first")
	assert_eq(_hunters.count(), 1)


func test_weekly_boss_rewards_then_returns_in_a_week() -> void:
	assert_not_null(_boss.get_region(), "boss arena region")
	assert_eq(_boss.get_boss().id, &"weekly_boss")
	assert_true(_boss.is_available(1000))
	var gold := _wallet.gold
	var tickets := _wallet.summon_tickets
	var reward := _boss.record_defeat(1000)
	assert_eq(reward["gold"], WeeklyBossService.BONUS_GOLD)
	assert_eq(reward["tickets"], WeeklyBossService.BONUS_TICKETS)
	assert_eq(_wallet.gold, gold + WeeklyBossService.BONUS_GOLD)
	assert_eq(_wallet.summon_tickets, tickets + WeeklyBossService.BONUS_TICKETS)
	assert_eq(_boss.kills, 1)
	assert_false(_boss.is_available(1000))
	assert_almost_eq(_boss.seconds_until_available(1000), float(WeeklyBossService.WEEK_SECONDS))
	assert_true(_boss.is_available(1000 + WeeklyBossService.WEEK_SECONDS))
	var copy := WeeklyBossService.new(_registry, _world, _hunters, _wallet, _inventory)
	copy.from_dict(_boss.to_dict())
	assert_eq(copy.next_available_unix, 1000 + WeeklyBossService.WEEK_SECONDS)
	assert_eq(copy.kills, 1)


func test_arena_is_a_duty_but_never_auto() -> void:
	var regions := RegionService.new(_registry, _world, _hunters, PurseService.new(_wallet, _registry.config), _inventory, _wallet,
		LootService.new(_registry, _rng), StatService.new(_registry.config), _progress, _registry.config, _rng)
	var hunting := regions.get_hunting_regions().map(func(r: RegionDefinition) -> StringName: return r.id)
	assert_false(hunting.has(&"boss_arena"))
	assert_false(hunting.has(&"hunter_gate"))
	assert_eq(hunting.size(), 3)
	assert_true(regions.get_duty_options().has(&"boss_arena"))
	assert_false(regions.get_duty_options().has(&"hunter_gate"))
	var hunter := _hunters.create_hunter(&"warrior", _rng)
	hunter.level = 50
	assert_true(regions.get_duty_region(hunter).id != &"boss_arena", "Auto never picks the arena")
	assert_eq(regions.set_duty(hunter, &"boss_arena"), "")
	assert_eq(regions.get_duty_region(hunter).id, &"boss_arena")
	assert_eq(_boss.get_assigned().size(), 1)
	assert_eq(regions.set_duty(hunter, &"hunter_gate"), "Unknown duty")


func test_market_buys_loot_into_the_warehouse_at_its_price() -> void:
	var regions := RegionService.new(_registry, _world, _hunters, PurseService.new(_wallet, _registry.config), _inventory, _wallet,
		LootService.new(_registry, _rng), StatService.new(_registry.config), _progress, _registry.config, _rng)
	var ore := _registry.find_def(&"item", &"iron_ore") as ItemDefinition
	assert_eq(regions.get_buy_price(ore), ore.sell_price, "no Market: full price")
	assert_eq(_buildings.get_definition(BuildingService.MARKET).levels.size(), 3)
	regions.buy_ratio = func() -> float: return 0.5
	assert_eq(regions.get_buy_price(ore), maxi(roundi(ore.sell_price * 0.5), 1))
	var hunter := _hunters.create_hunter(&"warrior", _rng)
	var purse := hunter.purse
	hunter.loot_bag[&"iron_ore"] = 4
	_wallet.add(1000)
	var gold := _wallet.gold
	var report := regions.deposit(hunter)
	assert_eq(report["items"].get(&"iron_ore", 0), 4)
	assert_eq(_inventory.count(&"iron_ore"), 4, "stored in the Warehouse")
	assert_eq(_wallet.gold, gold - 4 * regions.get_buy_price(ore))
	assert_eq(hunter.purse, purse + 4 * regions.get_buy_price(ore))
	assert_true(hunter.loot_bag.is_empty())

