extends TestCase
## LootService and InventoryService (INVENTORY_SYSTEM.md, BALANCE.md → Drops / Materials).

const DataRegistryScript := preload("res://core/data_registry.gd")

var _registry: Node
var _wallet: WalletService
var _inventory: InventoryService
var _rng: RandomNumberGenerator


func before_each() -> void:
	_registry = DataRegistryScript.new()
	_registry.report_errors = false
	_registry.load_all(DataRegistryScript.DATA_ROOT, DataRegistryScript.CONFIG_PATH)
	_wallet = WalletService.new()
	_inventory = InventoryService.new(_registry, _wallet)
	_rng = RandomNumberGenerator.new()
	_rng.seed = 99


func after_each() -> void:
	_registry.free()


func test_loot_chances_over_many_rolls() -> void:
	var loot := LootService.new(_registry, _rng)
	var goblin_ore := 0
	var wolf_fangs := 0
	var rolls := 2000
	for i in rolls:
		goblin_ore += loot.roll(&"goblin").get(&"iron_ore", 0)
		wolf_fangs += loot.roll(&"wolf").get(&"beast_fang", 0)
	# 40% and 50% chances, quantity 1.
	assert_almost_eq(goblin_ore / float(rolls), 0.4, 0.04)
	assert_almost_eq(wolf_fangs / float(rolls), 0.5, 0.04)


func test_loot_unknown_or_empty_table() -> void:
	var loot := LootService.new(_registry, _rng)
	assert_true(loot.roll(&"").is_empty())


func test_stacks_and_slots() -> void:
	assert_eq(_inventory.add_item(&"iron_ore", 100), 100)
	# 99 per stack → 2 slots.
	assert_eq(_inventory.used_slots(), 2)
	assert_eq(_inventory.count(&"iron_ore"), 100)
	assert_true(_inventory.has(&"iron_ore", 100))
	assert_false(_inventory.has(&"iron_ore", 101))
	assert_true(_inventory.remove_item(&"iron_ore", 2))
	assert_eq(_inventory.used_slots(), 1)


func test_equipment_instances_take_one_slot_each() -> void:
	assert_eq(_inventory.add_item(&"iron_sword", 2), 2)
	assert_eq(_inventory.count(&"iron_sword"), 2)
	assert_eq(_inventory.used_slots(), 2)
	var instances := _inventory.get_instances_of(&"iron_sword")
	assert_eq(instances.size(), 2)
	assert_true(instances[0] != instances[1])
	assert_eq(_inventory.get_instance_item(instances[0]), &"iron_sword")
	assert_true(_inventory.remove_instance(instances[0]))
	assert_false(_inventory.remove_instance(instances[0]), "already removed")


func test_capacity_limits_adds() -> void:
	_inventory.capacity = 2
	assert_eq(_inventory.add_item(&"iron_sword", 1), 1)
	# One free slot left: up to 99 ore fit, not 150.
	assert_eq(_inventory.add_item(&"iron_ore", 150), 99)
	assert_eq(_inventory.free_slots(), 0)
	assert_eq(_inventory.add_item(&"beast_fang", 1), 0)
	assert_eq(_inventory.add_item(&"fang_blade", 1), 0)


func test_validation() -> void:
	assert_eq(_inventory.add_item(&"not_an_item", 1), 0)
	assert_eq(_inventory.add_item(&"iron_ore", 0), 0)
	assert_eq(_inventory.add_item(&"iron_ore", -3), 0)
	assert_false(_inventory.remove_item(&"iron_ore", 1))
	assert_false(_inventory.remove_item(&"iron_ore", -1))


func test_sell() -> void:
	_inventory.add_item(&"dark_essence", 2)
	_inventory.add_item(&"iron_armor", 1)
	assert_eq(_inventory.sell_item(&"dark_essence", 2), 50)
	assert_eq(_inventory.sell_item(&"dark_essence", 1), 0, "none left")
	assert_eq(_inventory.sell_instance(_inventory.get_instances_of(&"iron_armor")[0]), 25)
	assert_eq(_wallet.gold, 75)
	assert_eq(_inventory.used_slots(), 0)


func test_changed_signal() -> void:
	var changes: Array[int] = [0]
	_inventory.inventory_changed.connect(func() -> void: changes[0] += 1)
	_inventory.add_item(&"iron_ore", 1)
	_inventory.add_item(&"not_an_item", 1)
	_inventory.remove_item(&"iron_ore", 1)
	assert_eq(changes[0], 2)
