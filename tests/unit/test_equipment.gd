extends TestCase
## EquipmentService, CraftingService and equipped-instance inventory rules.

const DataRegistryScript := preload("res://core/data_registry.gd")

var _registry: Node
var _wallet: WalletService
var _inventory: InventoryService
var _hunters: HunterService
var _equipment: EquipmentService
var _buildings: BuildingService
var _crafting: CraftingService
var _rng: RandomNumberGenerator


func before_each() -> void:
	_registry = DataRegistryScript.new()
	_registry.report_errors = false
	_registry.load_all(DataRegistryScript.DATA_ROOT, DataRegistryScript.CONFIG_PATH)
	var config: GameConfig = _registry.config
	_rng = RandomNumberGenerator.new()
	_rng.seed = 11
	_wallet = WalletService.new()
	_inventory = InventoryService.new(_registry, _wallet)
	_hunters = HunterService.new(_registry, StatService.new(config), config)
	_equipment = EquipmentService.new(_registry, _hunters, _inventory)
	_buildings = BuildingService.new(_registry, _wallet, _inventory, ProgressService.new())
	_crafting = CraftingService.new(_registry, _buildings, _wallet, _inventory)


func after_each() -> void:
	_hunters.clear_modifier_sources()
	_registry.free()


func _hunter() -> HunterRuntime:
	var hunter := _hunters.create_hunter(&"warrior", _rng)
	hunter.stat_rolls.clear()
	return hunter


func test_starting_gear_is_equipped_and_uses_no_slots() -> void:
	var hunter := _hunter()
	_equipment.give_starting_gear(hunter)
	assert_eq(_equipment.get_equipped_item(hunter, &"weapon").id, &"rusty_sword")
	assert_eq(_equipment.get_equipped_item(hunter, &"armor").id, &"leather_armor")
	assert_eq(_inventory.used_slots(), 0)
	# 14 + 3 attack, 6 + 3 defense, 120 + 10 HP.
	assert_almost_eq(_hunters.get_stat(hunter, HunterService.ATTACK), 17.0)
	assert_almost_eq(_hunters.get_stat(hunter, HunterService.DEFENSE), 9.0)
	assert_almost_eq(_hunters.get_stat(hunter, HunterService.MAX_HP), 130.0)


func test_equip_swaps_and_changes_stats() -> void:
	var hunter := _hunter()
	_equipment.give_starting_gear(hunter)
	_inventory.add_item(&"iron_sword", 1)
	var sword := _inventory.get_instances_of(&"iron_sword")[0]
	assert_eq(_equipment.equip(hunter, sword), "")
	assert_almost_eq(_hunters.get_stat(hunter, HunterService.ATTACK), 21.0)
	# The rusty sword went back to the Warehouse; the iron sword left it.
	assert_eq(_inventory.count(&"rusty_sword"), 1)
	assert_eq(_inventory.count(&"iron_sword"), 0)
	assert_eq(_inventory.used_slots(), 1)
	assert_false(_equipment.equip(hunter, sword).is_empty(), "already equipped")


func test_fang_blade_crit() -> void:
	var hunter := _hunter()
	_inventory.add_item(&"fang_blade", 1)
	assert_eq(_equipment.equip(hunter, _inventory.get_instances_of(&"fang_blade")[0]), "")
	assert_almost_eq(_hunters.get_stat(hunter, HunterService.CRITICAL_CHANCE), 0.10)
	assert_almost_eq(_hunters.get_stat(hunter, HunterService.ATTACK), 24.0)


func test_rules() -> void:
	var hunter := _hunter()
	_inventory.add_item(&"iron_ore", 1)
	assert_false(_equipment.equip(hunter, &"e_999").is_empty(), "unknown instance")
	_inventory.add_item(&"iron_sword", 1)
	var sword := _inventory.get_instances_of(&"iron_sword")[0]
	hunter.expedition_id = &"dark_forest"
	assert_false(_equipment.equip(hunter, sword).is_empty(), "on an expedition")
	hunter.expedition_id = &""
	assert_eq(_equipment.unequip(hunter, &"weapon"), "Nothing equipped")


func test_unequip_needs_a_free_slot() -> void:
	var hunter := _hunter()
	_equipment.give_starting_gear(hunter)
	_inventory.capacity = 1
	_inventory.add_item(&"iron_ore", 1)
	assert_eq(_equipment.unequip(hunter, &"weapon"), "Warehouse is full")
	_inventory.capacity = 2
	assert_eq(_equipment.unequip(hunter, &"weapon"), "")
	assert_null(_equipment.get_equipped_item(hunter, &"weapon"))
	assert_almost_eq(_hunters.get_stat(hunter, HunterService.ATTACK), 14.0)


func test_equipped_items_cannot_be_sold() -> void:
	var hunter := _hunter()
	_equipment.give_starting_gear(hunter)
	var sword: StringName = hunter.equipment[&"weapon"]
	assert_eq(_inventory.sell_instance(sword), 0)
	assert_eq(_inventory.get_instances().size(), 0, "equipped instances are not listed as stored")


func test_equip_best() -> void:
	var hunter := _hunter()
	_equipment.give_starting_gear(hunter)
	_inventory.add_item(&"iron_sword", 1)
	_inventory.add_item(&"iron_armor", 1)
	var equipped := _equipment.equip_best(hunter)
	assert_eq(Array(equipped), ["Iron Sword", "Iron Armor"])
	assert_eq(_equipment.equip_best(hunter).size(), 0, "nothing better left")


func test_crafting_requirements_and_costs() -> void:
	assert_eq(_crafting.get_recipes(&"blacksmith").size(), 3)
	assert_eq(_crafting.get_recipes().size(), 7, "+ 2 Tavern food, 2 Hospital medicine")
	assert_eq(_crafting.can_craft(&"iron_sword"), "Needs 50 gold")
	_wallet.add(500)
	assert_eq(_crafting.can_craft(&"iron_sword"), "Needs 5 Iron Ore")
	_inventory.add_item(&"iron_ore", 7)
	var instance := _crafting.craft(&"iron_sword")
	assert_true(instance != &"")
	assert_eq(_inventory.get_instance_item(instance), &"iron_sword")
	assert_eq(_wallet.gold, 450)
	assert_eq(_inventory.count(&"iron_ore"), 2)
	# Fang Blade needs Blacksmith Lv2.
	_inventory.add_item(&"beast_fang", 8)
	_inventory.add_item(&"dark_essence", 1)
	assert_eq(_crafting.can_craft(&"fang_blade"), "Needs Blacksmith Lv 2")
	_inventory.add_item(&"iron_ore", 3)
	assert_true(_buildings.upgrade(&"blacksmith"))
	assert_eq(_crafting.can_craft(&"fang_blade"), "")


func test_crafting_needs_a_free_slot() -> void:
	_wallet.add(500)
	_inventory.capacity = 1
	_inventory.add_item(&"iron_ore", 5)
	assert_eq(_crafting.can_craft(&"iron_sword"), "Warehouse is full")


func test_inventory_round_trip_with_equipped() -> void:
	var hunter := _hunter()
	_equipment.give_starting_gear(hunter)
	_inventory.add_item(&"iron_ore", 4)
	_inventory.add_item(&"iron_sword", 1)
	var data := _inventory.to_dict()
	var copy := InventoryService.new(_registry, _wallet)
	var warnings := PackedStringArray()
	copy.from_dict(JSON.parse_string(JSON.stringify(data)), warnings)
	assert_eq(warnings.size(), 0)
	assert_eq(copy.count(&"iron_ore"), 4)
	assert_eq(copy.count(&"iron_sword"), 1)
	assert_true(copy.is_equipped(hunter.equipment[&"weapon"]))
	assert_eq(copy.used_slots(), _inventory.used_slots())
