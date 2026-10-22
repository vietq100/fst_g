extends TestCase
## Storage grid: one slot per used inventory slot (x99 at most), filtered by the tab.


func test_stacks_split_into_slots_of_99_and_tabs_filter() -> void:
	var inventory: InventoryService = GameManager.inventory
	var saved_capacity := inventory.capacity
	inventory.capacity = 500
	var ore_before := inventory.count(&"iron_ore")
	inventory.add_item(&"iron_ore", 250)
	inventory.add_item(&"healing_potion", 5)
	var sheet := InventorySheet.new()
	var counts: Array[int] = []
	sheet._tab = InventorySheet.Tab.MATERIAL
	for slot: Dictionary in sheet._slots_for_tab(inventory):
		assert_eq((slot["item"] as ItemDefinition).item_type, ItemDefinition.ItemType.MATERIAL, "material tab only")
		if (slot["item"] as ItemDefinition).id == &"iron_ore":
			counts.append(String(slot["badge"]).trim_prefix("x").to_int())
	var total := ore_before + 250
	assert_eq(counts.size(), ceili(total / 99.0), "one slot per started stack")
	assert_true(counts.max() <= 99, "x99 at most")
	assert_eq(counts.reduce(func(a: int, b: int) -> int: return a + b, 0), total)
	sheet._tab = InventorySheet.Tab.FOOD
	var food := sheet._slots_for_tab(inventory)
	assert_true(food.size() >= 1, "potion in the food tab")
	for slot: Dictionary in food:
		assert_eq((slot["item"] as ItemDefinition).item_type, ItemDefinition.ItemType.CONSUMABLE)
	inventory.remove_item(&"iron_ore", 250)
	inventory.remove_item(&"healing_potion", 5)
	inventory.capacity = saved_capacity
	sheet.free()
