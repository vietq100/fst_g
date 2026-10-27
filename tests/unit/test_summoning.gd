extends TestCase
## Summoning tickets, the active cap and hibernation (D83).

const DataRegistryScript := preload("res://core/data_registry.gd")

var _registry: Node
var _wallet: WalletService
var _hunters: HunterService
var _buildings: BuildingService
var _recruitment: RecruitmentService
var _rng: RandomNumberGenerator


func before_each() -> void:
	_registry = DataRegistryScript.new()
	_registry.report_errors = false
	_registry.load_all(DataRegistryScript.DATA_ROOT, DataRegistryScript.CONFIG_PATH)
	var config: GameConfig = _registry.config
	_rng = RandomNumberGenerator.new()
	_rng.seed = 11
	var stats := StatService.new(config)
	_wallet = WalletService.new()
	_hunters = HunterService.new(_registry, stats, config)
	_buildings = BuildingService.new(_registry, _wallet, InventoryService.new(_registry, _wallet), ProgressService.new())
	_recruitment = RecruitmentService.new(_registry, _hunters, _buildings, _wallet, _rng)
	_recruitment.config = config


func after_each() -> void:
	_registry.free()


func test_tickets_are_a_currency() -> void:
	assert_eq(_wallet.summon_tickets, 0)
	_wallet.add_tickets(3)
	assert_true(_wallet.can_spend_tickets(3))
	assert_false(_wallet.spend_tickets(4), "not enough")
	assert_true(_wallet.spend_tickets(2))
	assert_eq(_wallet.summon_tickets, 1)


func test_buy_ticket_with_gold() -> void:
	assert_eq(_recruitment.get_ticket_gold_price(), 300)
	assert_eq(_wallet.gold, 0)
	assert_false(_recruitment.can_buy_ticket().is_empty())
	assert_false(_recruitment.buy_ticket())
	_wallet.add(350)
	assert_eq(_recruitment.can_buy_ticket(), "")
	assert_true(_recruitment.buy_ticket())
	assert_eq(_wallet.gold, 50)
	assert_eq(_wallet.summon_tickets, 2)


func test_summon_costs_a_ticket_and_fills_the_village_first() -> void:
	assert_false(_recruitment.can_summon().is_empty(), "no tickets: refused")
	assert_null(_recruitment.summon())
	_wallet.add_tickets(5)
	var first := _recruitment.summon()
	assert_not_null(first)
	assert_eq(_wallet.summon_tickets, 4)
	assert_false(first.hibernating, "an active slot is free: awake")
	assert_eq(_hunters.count_active(), 1)
	# The Town Hall's capacity is the active cap at level 1 (3, BALANCE.md): the fourth sleeps.
	var cap := _recruitment.get_active_cap()
	assert_true(cap <= _registry.config.active_hunter_cap, "never above the configured cap")
	while _hunters.count_active() < cap and _wallet.summon_tickets > 0:
		assert_not_null(_recruitment.summon())
	_wallet.add_tickets(1)
	var extra := _recruitment.summon()
	assert_not_null(extra, "the Mount has room")
	assert_true(extra.hibernating, "village full: straight to the Mount")
	assert_eq(extra.task, HunterRuntime.HIBERNATING)
	assert_eq(_hunters.count_hibernating(), 1)


func test_summon_many_stops_when_tickets_run_out() -> void:
	_wallet.add_tickets(3)
	var called := _recruitment.summon_many(10)
	assert_eq(called.size(), 3)
	assert_eq(_wallet.summon_tickets, 0)


func test_hibernate_activate_and_swap() -> void:
	_wallet.add_tickets(10)
	var a := _recruitment.summon()
	var b := _recruitment.summon()
	assert_false(_recruitment.can_activate(a).is_empty(), "awake: cannot wake")
	assert_eq(_recruitment.hibernate(a), "")
	assert_true(a.hibernating)
	assert_eq(a.task, HunterRuntime.HIBERNATING)
	assert_false(_recruitment.hibernate(a).is_empty(), "already asleep")
	assert_eq(_recruitment.activate(a), "")
	assert_false(a.hibernating)
	assert_eq(a.task, &"")
	assert_eq(_recruitment.hibernate(b), "")
	assert_eq(_recruitment.swap(a, b), "", "a sleeps, b wakes")
	assert_true(a.hibernating)
	assert_false(b.hibernating)
	assert_eq(_hunters.count_active() + _hunters.count_hibernating(), _hunters.count())


func test_sleepers_free_their_active_slot() -> void:
	_wallet.add_tickets(2)
	var sleeper := _recruitment.summon()
	assert_eq(_recruitment.hibernate(sleeper), "")
	# A sleeper does not count as active, so the slot it held is free again.
	assert_eq(_hunters.count_active(), 0)
	assert_eq(_hunters.get_hibernating().size(), 1)
	assert_true(_recruitment.has_active_room())


func test_the_mount_is_a_region_bridged_to_the_gate() -> void:
	var world := WorldService.new(_registry)
	var mount := world.get_region(&"hibernation_mount")
	assert_not_null(mount)
	assert_eq(mount.kind, RegionDefinition.Kind.MOUNT)
	var bridged := false
	for gate in world.get_gates():
		if (gate.region_a == &"hibernation_mount" and gate.region_b == &"hunter_gate") or (gate.region_a == &"hunter_gate" and gate.region_b == &"hibernation_mount"):
			bridged = true
	assert_true(bridged, "a bridge joins the Mount to the Hunter Gate island")
	assert_true(world.region_tile_list(mount.id).size() >= 60, "room for a hundred sleepers")


func test_save_keeps_tickets_and_sleepers() -> void:
	_wallet.add_tickets(7)
	var hunter := _recruitment.summon()
	_recruitment.hibernate(hunter)
	var copy := HunterRuntime.from_dict(hunter.to_dict())
	assert_true(copy.hibernating)
	assert_eq(copy.task, HunterRuntime.HIBERNATING)
	var warnings := PackedStringArray()
	var migrated: Dictionary = SaveCodec.migrate({"schema_version": 3, "gold": 5}, warnings)
	assert_eq(int(migrated["schema_version"]), SaveCodec.SCHEMA_VERSION)
	assert_true(migrated.has("summon_tickets"), "old villages get tickets")


func test_batch_summons_join_only_on_confirm_in_order() -> void:
	_wallet.add_tickets(10)
	var called := _recruitment.summon_batch(5)
	assert_eq(called.size(), 5)
	assert_eq(_wallet.summon_tickets, 5, "tickets are spent at the call")
	assert_eq(_hunters.count(), 0, "nobody joins before Confirm")
	assert_eq(_recruitment.pending.size(), 5)
	# Pending newcomers already hold their slots: with the Lv1 Town Hall only some are awake.
	var awake := called.filter(func(h: HunterRuntime) -> bool: return not h.hibernating).size()
	assert_true(awake <= _recruitment.get_active_cap(), "no more awake than the active cap")
	var joined := _recruitment.confirm_arrivals()
	assert_eq(joined.size(), 5)
	assert_eq(_hunters.count(), 5)
	assert_true(_recruitment.pending.is_empty())
	for i in joined.size():
		assert_eq(joined[i], called[i], "arrival order is the call order")
		assert_true(_recruitment.is_arriving(joined[i].unique_id), "the world still has to let it down")
	_recruitment.mark_arrived(joined[0].unique_id)
	assert_false(_recruitment.is_arriving(joined[0].unique_id))
	assert_eq(_recruitment.last_arrivals.size(), 5)
	assert_true(_recruitment.confirm_arrivals().is_empty(), "nothing pending: nothing joins")
