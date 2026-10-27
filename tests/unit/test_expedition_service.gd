extends TestCase
## ExpeditionService rules without a scene (EXPEDITION_SYSTEM.md, DECISIONS.md D3–D5, D10).

const DataRegistryScript := preload("res://core/data_registry.gd")

var _registry: Node
var _hunters: HunterService
var _wallet: WalletService
var _progress: ProgressService
var _inventory: InventoryService
var _service: ExpeditionService
var _rng: RandomNumberGenerator


func before_each() -> void:
	_registry = DataRegistryScript.new()
	_registry.report_errors = false
	_registry.load_all(DataRegistryScript.DATA_ROOT, DataRegistryScript.CONFIG_PATH)
	var config: GameConfig = _registry.config
	var stats := StatService.new(config)
	_rng = RandomNumberGenerator.new()
	_rng.seed = 3
	_hunters = HunterService.new(_registry, stats, config)
	_wallet = WalletService.new()
	_progress = ProgressService.new()
	_inventory = InventoryService.new(_registry, _wallet)
	var loot := LootService.new(_registry, _rng)
	_service = ExpeditionService.new(_registry, _hunters, _wallet, _progress, _inventory, loot, stats, config, _rng)


func after_each() -> void:
	_registry.free()


func test_validation() -> void:
	var ids := _recruit(4)
	assert_eq(_service.validate(&"nowhere", _ids(ids, 1)), "Unknown expedition 'nowhere'")
	assert_false(_service.validate(&"dark_forest", _ids(ids, 0)).is_empty(), "empty party")
	assert_false(_service.validate(&"dark_forest", _ids(ids, 4)).is_empty(), "party of 4")
	var twice: Array[StringName] = [ids[0], ids[0]]
	assert_false(_service.validate(&"dark_forest", twice).is_empty(), "duplicate")
	_hunters.mark_injured(_hunters.get_hunter(ids[2]))
	assert_false(_service.validate(&"dark_forest", _ids(ids, 3)).is_empty(), "injured member")
	assert_eq(_service.validate(&"dark_forest", _ids(ids, 2)), "")


func test_start_sets_lifecycle_and_blocks_second_run() -> void:
	var ids := _recruit(2)
	var run := _service.start(&"dark_forest", ids)
	assert_not_null(run)
	assert_true(run.is_first_clear)
	for hunter_id in ids:
		assert_eq(_hunters.get_hunter(hunter_id).state, HunterRuntime.LifecycleState.TRAVELING)
	_service.begin_section(0)
	assert_eq(_hunters.get_hunter(ids[0]).state, HunterRuntime.LifecycleState.COMBAT)
	assert_null(_service.start(&"dark_forest", ids), "already running")


func test_kill_gives_stash_gold_and_xp_to_whole_party() -> void:
	var ids := _recruit(2)
	_service.start(&"dark_forest", ids)
	_service.mark_downed(ids[1])
	var goblin := _registry.find_def(&"enemy", &"goblin") as EnemyDefinition
	_service.record_kill(goblin)
	var run := _service.current_run
	assert_true(run.stash_gold >= 4 and run.stash_gold <= 8, "gold %d" % run.stash_gold)
	assert_eq(run.kills, 1)
	# Downed members still get XP (D5).
	assert_eq(_hunters.get_hunter(ids[0]).xp, 10)
	assert_eq(_hunters.get_hunter(ids[1]).xp, 10)
	assert_eq(_wallet.gold, 0, "gold only granted on return")


func test_level_up_from_kills() -> void:
	var ids := _recruit(1)
	_service.start(&"dark_forest", ids)
	var hunter := _hunters.get_hunter(ids[0])
	hunter.current_hp = 50.0
	var boss := _registry.find_def(&"enemy", &"forest_guardian") as EnemyDefinition
	_service.record_kill(boss)
	# 150 XP: L1→2 needs 30, L2→3 needs 138 → level 2 with 120 left (D44).
	assert_eq(hunter.level, 2)
	assert_eq(hunter.xp, 120)
	assert_eq(_service.current_run.levels_gained[ids[0]], 1)
	assert_true(hunter.current_hp > 50.0, "level-up heals")


func test_level_cap_keeps_extra_xp() -> void:
	var ids := _recruit(1)
	var hunter := _hunters.get_hunter(ids[0])
	_hunters.set_level(hunter, 10)
	assert_eq(_hunters.add_xp(hunter, 5000, 10), 0)
	assert_eq(hunter.level, 10)
	assert_eq(hunter.xp, 5000)
	assert_true(_hunters.add_xp(hunter, 1, 20) > 0, "levels once the cap rises")


func test_success_grants_gold_bonus_flag_and_states() -> void:
	var ids := _recruit(2)
	_service.start(&"dark_forest", ids)
	_service.current_run.stash_gold = 100
	_service.mark_downed(ids[1])
	var finished: Array[ExpeditionRun] = []
	_service.expedition_finished.connect(func(run: ExpeditionRun) -> void: finished.append(run))
	_service.complete()
	assert_eq(_wallet.gold, 150, "stash + completion bonus 50")
	assert_true(_progress.has_flag(&"first_boss_clear"))
	assert_eq(_hunters.get_hunter(ids[0]).state, HunterRuntime.LifecycleState.AVAILABLE)
	assert_true(_hunters.get_hunter(ids[1]).injured, "downed member returns injured")
	assert_eq(_hunters.get_hunter(ids[1]).state, HunterRuntime.LifecycleState.RECOVERING)
	assert_eq(finished.size(), 1)
	assert_false(_service.is_running())


func test_failure_keeps_half_and_injures_everyone() -> void:
	var ids := _recruit(2)
	_service.start(&"dark_forest", ids)
	_service.current_run.stash_gold = 31
	_service.mark_downed(ids[0])
	assert_false(_service.is_party_wiped())
	_service.mark_downed(ids[1])
	assert_true(_service.is_party_wiped())
	_service.fail()
	assert_eq(_wallet.gold, 15, "floor(31 × 0.5), no bonus")
	assert_false(_progress.has_flag(&"first_boss_clear"))
	for hunter_id in ids:
		assert_true(_hunters.get_hunter(hunter_id).injured)


func test_repeat_clear_halves_boss_gold() -> void:
	_progress.set_flag(&"first_boss_clear")
	var ids := _recruit(1)
	var run := _service.start(&"dark_forest", ids)
	assert_false(run.is_first_clear)
	_service.record_kill(_registry.find_def(&"enemy", &"forest_guardian") as EnemyDefinition)
	assert_eq(run.stash_gold, 75)


func test_boss_first_clear_loot_goes_to_stash_then_inventory() -> void:
	var ids := _recruit(1)
	_service.start(&"dark_forest", ids)
	var reward := _service.record_kill(_registry.find_def(&"enemy", &"forest_guardian") as EnemyDefinition)
	# First-clear table: Iron Ore 5, Beast Fang 3, Dark Essence 2 guaranteed (+ Fang Blade 10%).
	assert_eq(reward.items.get(&"iron_ore"), 5)
	assert_eq(reward.items.get(&"beast_fang"), 3)
	assert_eq(reward.items.get(&"dark_essence"), 2)
	assert_eq(_service.current_run.stash_items.get(&"iron_ore"), 5)
	assert_eq(_inventory.count(&"iron_ore"), 0, "not granted before return")
	_service.complete()
	assert_eq(_inventory.count(&"iron_ore"), 5)
	assert_eq(_inventory.count(&"dark_essence"), 2)
	assert_eq(_service.current_run.items_granted.get(&"beast_fang"), 3)
	assert_eq(_service.current_run.tickets_granted, 6, "1 completion + 5 first-clear")
	assert_eq(_wallet.summon_tickets, 6)


func test_failure_keeps_half_of_items_rounded_down() -> void:
	var ids := _recruit(1)
	_service.start(&"dark_forest", ids)
	_service.current_run.stash_items = {&"iron_ore": 5, &"beast_fang": 1} as Dictionary[StringName, int]
	_service.fail()
	assert_eq(_inventory.count(&"iron_ore"), 2)
	assert_eq(_inventory.count(&"beast_fang"), 0)


func test_overflow_is_auto_sold() -> void:
	_inventory.capacity = 1
	_inventory.add_item(&"beast_fang", 1)
	var ids := _recruit(1)
	_service.start(&"dark_forest", ids)
	_service.current_run.stash_items = {&"beast_fang": 2, &"iron_ore": 4} as Dictionary[StringName, int]
	_service.complete()
	# Beast Fang stacks into the existing slot; Iron Ore needs a new slot → sold 4 × 3 gold.
	assert_eq(_inventory.count(&"beast_fang"), 3)
	assert_eq(_inventory.count(&"iron_ore"), 0)
	assert_eq(_service.current_run.items_overflowed.get(&"iron_ore"), 4)
	assert_eq(_service.current_run.overflow_gold, 12)
	assert_eq(_wallet.gold, 50 + 12, "completion bonus + overflow sale")


func test_wallet() -> void:
	_wallet.add(10)
	assert_false(_wallet.spend(11))
	assert_true(_wallet.spend(4))
	assert_eq(_wallet.gold, 6)


func _recruit(count: int) -> Array[StringName]:
	var ids: Array[StringName] = []
	for i in count:
		ids.append(_hunters.create_hunter(&"warrior", _rng).unique_id)
	return ids


func _ids(all: Array[StringName], count: int) -> Array[StringName]:
	return all.slice(0, count)
