extends TestCase
## BuildingService, RecruitmentService, HospitalService (BUILDING_DESIGN.md, DECISIONS.md D9–D12, D25).

const DataRegistryScript := preload("res://core/data_registry.gd")

var _registry: Node
var _wallet: WalletService
var _inventory: InventoryService
var _progress: ProgressService
var _hunters: HunterService
var _buildings: BuildingService
var _recruitment: RecruitmentService
var _hospital: HospitalService
var _stats: StatService
var _rng: RandomNumberGenerator


func before_each() -> void:
	_registry = DataRegistryScript.new()
	_registry.report_errors = false
	_registry.load_all(DataRegistryScript.DATA_ROOT, DataRegistryScript.CONFIG_PATH)
	var config: GameConfig = _registry.config
	_rng = RandomNumberGenerator.new()
	_rng.seed = 5
	_stats = StatService.new(config)
	_wallet = WalletService.new()
	_inventory = InventoryService.new(_registry, _wallet)
	_progress = ProgressService.new()
	_hunters = HunterService.new(_registry, _stats, config)
	_buildings = BuildingService.new(_registry, _wallet, _inventory, _progress)
	_recruitment = RecruitmentService.new(_registry, _hunters, _buildings, _wallet, _rng)
	_hospital = HospitalService.new(_hunters, _buildings, _wallet)


func after_each() -> void:
	_registry.free()


func test_buildings_start_at_level_one_with_effects() -> void:
	assert_eq(_buildings.get_ids().size(), 5)
	for building_id in _buildings.get_ids():
		assert_eq(_buildings.get_level(building_id), 1, String(building_id))
	assert_eq(_inventory.capacity, 40, "warehouse Lv1")
	assert_eq(_progress.town_level, 1)
	assert_eq(_recruitment.get_capacity(), 3)
	assert_almost_eq(_hospital.get_recovery_seconds(), 120.0)


func test_upgrade_requires_gold_materials_and_flags() -> void:
	assert_eq(_buildings.can_upgrade(&"warehouse"), "Needs 250 gold")
	_wallet.add(1000)
	assert_eq(_buildings.can_upgrade(&"warehouse"), "Needs 5 Iron Ore")
	_inventory.add_item(&"iron_ore", 12)
	assert_true(_buildings.upgrade(&"warehouse"))
	assert_eq(_buildings.get_level(&"warehouse"), 2)
	assert_eq(_inventory.capacity, 80)
	assert_eq(_wallet.gold, 750)
	assert_eq(_inventory.count(&"iron_ore"), 7)
	assert_false(_buildings.can_upgrade(&"warehouse").is_empty(), "max level")
	# Town Hall Lv2 needs the first boss clear (and 10 Iron Ore).
	_inventory.add_item(&"iron_ore", 3)
	assert_eq(_buildings.can_upgrade(&"town_hall"), "Requires first boss clear")
	_progress.set_flag(&"first_boss_clear")
	assert_true(_buildings.upgrade(&"town_hall"))
	assert_eq(_progress.town_level, 2)
	assert_eq(_recruitment.get_capacity(), 5)
	assert_eq(_stats.level_cap(_progress.town_level), 20)


func test_failed_upgrade_changes_nothing() -> void:
	_wallet.add(100)
	assert_false(_buildings.upgrade(&"tavern"))
	assert_eq(_wallet.gold, 100)
	assert_eq(_buildings.get_level(&"tavern"), 1)


func test_set_levels_clamps_and_ignores_unknown() -> void:
	_buildings.set_levels({"warehouse": 9, "castle": 3, "tavern": 0})
	assert_eq(_buildings.get_level(&"warehouse"), 2)
	assert_eq(_buildings.get_level(&"tavern"), 1)
	assert_eq(_buildings.get_level(&"castle"), 0)
	assert_eq(_inventory.capacity, 80)


func test_candidates_are_not_in_roster_until_recruited() -> void:
	_recruitment.refresh_candidates()
	assert_eq(_recruitment.candidates.size(), 3)
	assert_eq(_hunters.count(), 0)
	assert_eq(_recruitment.can_recruit(0), "Needs 100 gold")
	_wallet.add(150)
	var name := _recruitment.candidates[0].display_name
	var hunter := _recruitment.recruit(0)
	assert_not_null(hunter)
	assert_eq(hunter.display_name, name)
	assert_eq(_hunters.count(), 1)
	assert_true(hunter.unique_id != &"")
	assert_eq(_wallet.gold, 50)
	assert_eq(_recruitment.candidates.size(), 2)


func test_roster_capacity() -> void:
	_wallet.add(10000)
	for i in 3:
		_hunters.create_hunter(&"warrior", _rng)
	_recruitment.refresh_candidates()
	assert_true(_recruitment.can_recruit(0).begins_with("Roster full"))
	assert_null(_recruitment.recruit(0))


func test_paid_refresh() -> void:
	_recruitment.refresh_candidates()
	assert_false(_recruitment.paid_refresh(), "no gold")
	_wallet.add(30)
	assert_true(_recruitment.paid_refresh())
	assert_eq(_wallet.gold, 0)


func test_names_come_from_pool_without_repeats() -> void:
	var names: Dictionary[String, bool] = {}
	for i in 10:
		var hunter := _hunters.create_hunter(&"warrior", _rng)
		assert_false(names.has(hunter.display_name), "repeat " + hunter.display_name)
		names[hunter.display_name] = true
		assert_true(Array((_registry.find_def(&"hunter", &"warrior") as HunterDefinition).name_pool).has(hunter.display_name))


func test_hospital_recovery_over_time() -> void:
	var hunter := _hunters.create_hunter(&"warrior", _rng)
	_hunters.mark_injured(hunter)
	assert_almost_eq(_hospital.get_remaining(hunter), 120.0)
	_hospital.tick(60.0)
	assert_almost_eq(hunter.recovery_remaining, 60.0)
	assert_true(hunter.injured)
	var recovered := _hospital.tick(61.0)
	assert_eq(recovered, [hunter] as Array[HunterRuntime])
	assert_false(hunter.injured)
	assert_eq(hunter.state, HunterRuntime.LifecycleState.AVAILABLE)
	assert_almost_eq(hunter.current_hp, _hunters.get_stat(hunter, HunterService.MAX_HP))


func test_hospital_speed_up_cost() -> void:
	var hunter := _hunters.create_hunter(&"warrior", _rng)
	_hunters.mark_injured(hunter)
	# 120 s left → 2 started minutes × 20 gold.
	assert_eq(_hospital.get_speed_up_cost(hunter), 40)
	_hospital.tick(70.0)
	assert_eq(_hospital.get_speed_up_cost(hunter), 20)
	assert_false(_hospital.speed_up(hunter), "no gold")
	_wallet.add(20)
	assert_true(_hospital.speed_up(hunter))
	assert_false(hunter.injured)
	assert_eq(_wallet.gold, 0)
