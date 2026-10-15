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
	hunter.tier = Tier.Level.C
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
	assert_eq(_crafting.get_recipes(&"blacksmith").size(), 26, "7 weapons / tops + 19 helmets, pants, boots, jewelry, charms (D59)")
	assert_eq(_crafting.get_recipes(&"trading_post").size(), 9, "5 skins + 4 pets (D59)")
	assert_eq(_crafting.get_recipes().size(), 40, "26 Blacksmith, 9 Trading Post, 3 Tavern food, 2 Hospital medicine")
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


func test_every_slot_equips_and_dresses_the_figure() -> void:
	var hunter := _hunters.create_hunter(&"warrior", _rng)
	for item_id: StringName in [&"iron_helm", &"leather_pants", &"swift_boots", &"fang_necklace", &"ruby_ring", &"lucky_charm",
			&"crimson_suit", &"pet_teddy"]:
		assert_eq(_inventory.add_item(item_id, 1), 1, "stored %s" % item_id)
		var instance: StringName = _inventory.get_instances_of(item_id)[0]
		assert_eq(_equipment.equip(hunter, instance), "", String(item_id))
	for slot: StringName in [&"helmet", &"pants", &"boots", &"necklace", &"ring", &"accessory", &"skin", &"pet"]:
		assert_true(hunter.equipment.has(slot), "slot %s" % slot)
	assert_eq(EquipmentService.SLOT_ORDER.size(), EquipmentService.SLOT_NAMES.size())
	var dress := _equipment.get_dress(hunter)
	assert_eq(dress.hat, &"helm")
	assert_eq(dress.pet, &"teddy")
	assert_eq(dress.outfit, &"warrior", "Crimson Suit uses the warrior pattern")
	assert_true(dress.skin and dress.has_cloth and dress.has_pants and dress.has_boots)
	var figure := ChibiBody.get_figure(hunter.appearance, dress)
	assert_true(figure.get_height() >= 30 and figure.get_width() <= ChibiBody.CANVAS.x, "whole body, cropped")
	assert_not_null(PetSprites.texture(dress.pet, dress.pet_tint, 1))
	var styles := {}
	for item_id: StringName in [&"wizard_hat", &"shadow_hood", &"leather_cap", &"golden_crown", &"steel_helm"]:
		styles[ChibiBody.hat_style_for(_registry.find_def(&"item", item_id) as ItemDefinition)] = true
	assert_eq(styles.size(), 5, "five hat styles")


func test_weapon_durability_wears_breaks_and_repairs() -> void:
	var hunter := _hunters.create_hunter(&"warrior", _rng)
	hunter.stat_rolls.clear()
	hunter.tier = Tier.Level.C
	_equipment.buildings = _buildings
	_equipment.wallet = _wallet
	_equipment.purses = PurseService.new(_wallet, _registry.config)
	_inventory.add_item(&"iron_sword", 1)
	var instance: StringName = _inventory.get_instances_of(&"iron_sword")[0]
	assert_eq(_equipment.equip(hunter, instance), "")
	var sword := _registry.find_def(&"item", &"iron_sword") as ItemDefinition
	var full := EquipmentService.max_durability(sword)
	assert_eq(full, EquipmentService.DURABILITY_BASE + EquipmentService.DURABILITY_PER_TIER * int(sword.rarity))
	assert_eq(EquipmentService.max_durability(_registry.find_def(&"item", &"leather_armor") as ItemDefinition), 0, "only weapons wear")
	var armed := _hunters.get_stat(hunter, HunterService.ATTACK)
	_equipment.wear_weapon(hunter, 5)
	assert_eq(_equipment.get_durability(instance), full - 5)
	var broken := []
	_equipment.weapon_broken.connect(func(_h: HunterRuntime, _i: ItemDefinition) -> void: broken.append(true))
	_equipment.wear_weapon(hunter, full)
	assert_true(_equipment.is_broken(instance))
	assert_eq(broken.size(), 1)
	assert_true(_hunters.get_stat(hunter, HunterService.ATTACK) < armed, "a broken weapon gives no bonus")
	var cost := _equipment.get_repair_cost(instance)
	assert_eq(cost, full * (EquipmentService.REPAIR_GOLD_PER_POINT + int(sword.rarity)))
	_wallet.add(cost)
	assert_eq(_equipment.repair(instance), "")
	assert_eq(_equipment.get_durability(instance), full)
	assert_almost_eq(_hunters.get_stat(hunter, HunterService.ATTACK), armed)
	# The Hunter's own trip to the Blacksmith: worn below the threshold, paid from the purse.
	_equipment.wear_weapon(hunter, full - 1)
	hunter.purse = 10000
	assert_true(_equipment.wants_repair(hunter))
	assert_true(_equipment.repair_by_hunter(hunter))
	assert_eq(_equipment.get_durability(instance), full)
	assert_false(_equipment.wants_repair(hunter))
	# Saved with the inventory.
	_equipment.wear_weapon(hunter, 3)
	var copy := InventoryService.new(_registry, _wallet)
	copy.from_dict(_inventory.to_dict(), PackedStringArray())
	assert_eq(copy.get_wear(instance), 3)

