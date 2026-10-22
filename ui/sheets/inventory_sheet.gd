class_name InventorySheet
extends Sheet
## Storage (UI_DESIGN.md → Warehouse): tabs by kind, then a grid of square icon slots, one per used
## inventory slot: a stack of 250 shows as 99, 99 and 52 (x99 is the most one slot holds); a spare
## equipment piece shows its enhancement. Tapping a slot opens the item's details, where it is sold.

enum Tab { ALL, EQUIPMENT, FOOD, MATERIAL }

## Translation keys of the tab titles.
const TAB_NAMES := ["ui.inventory.tab.all", "ui.inventory.tab.equipment", "ui.inventory.tab.food", "ui.inventory.tab.material"]
const COLUMNS := 5
const SLOT_SIZE := 56.0

## The tab stays chosen while the game runs.
static var _last_tab := Tab.ALL

var _tab: Tab = _last_tab


func _init() -> void:
	title = Loc.t("ui.inventory.title")


func _watch() -> Array:
	return [[GameManager.inventory, &"inventory_changed"], [GameManager.buildings, &"building_upgraded"]]


func _build(content: VBoxContainer) -> void:
	var inventory := GameManager.inventory
	content.add_child(UIKit.bar(inventory.used_slots(), inventory.capacity, &"TimerBar",
		Loc.t("ui.inventory.slots", {"used": inventory.used_slots(), "total": inventory.capacity})))
	var tabs := UIKit.hbox([], 0)
	for i in TAB_NAMES.size():
		var tab_button := UIKit.button(Loc.t(TAB_NAMES[i]), func() -> void:
			_tab = i as Tab
			_last_tab = _tab
			request_rebuild(), &"NavSelected" if _tab == i else &"NavButton")
		tab_button.custom_minimum_size = Vector2(0, 34)
		tab_button.add_theme_font_size_override(&"font_size", 12)
		tab_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_button.clip_text = true
		tab_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		tabs.add_child(tab_button)
	content.add_child(tabs)
	var slots := _slots_for_tab(inventory)
	if slots.is_empty():
		content.add_child(UIKit.label(Loc.t("ui.inventory.empty"), &"MutedLabel"))
		return
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override(&"h_separation", 4)
	grid.add_theme_constant_override(&"v_separation", 4)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for slot: Dictionary in slots:
		grid.add_child(ItemIcon.new().setup(slot["item"], SLOT_SIZE, slot["badge"], slot.get("instance", &"")))
	content.add_child(grid)
	content.add_child(UIKit.label(Loc.t("ui.inventory.tap_hint"), &"MutedLabel"))


## The slots of the chosen tab: {item, badge, instance?}, best first.
func _slots_for_tab(inventory: InventoryService) -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	var stacks := inventory.get_stacks()
	for item_id in stacks:
		var item := DataRegistry.get_item(item_id)
		if item == null or not _in_tab(item):
			continue
		var left: int = stacks[item_id]
		var per := maxi(item.max_stack, 1)
		while left > 0:
			var count := mini(left, per)
			slots.append({"item": item, "badge": "x%d" % count if count > 1 else ""})
			left -= count
	var instances := inventory.get_instances()
	for instance_id in instances:
		var item := DataRegistry.get_item(instances[instance_id])
		if item == null or not _in_tab(item):
			continue
		var enhance := inventory.get_enhance(instance_id)
		slots.append({"item": item, "badge": "+%d" % enhance if enhance > 0 else "", "instance": instance_id})
	slots.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ia: ItemDefinition = a["item"]
		var ib: ItemDefinition = b["item"]
		if ia.rarity != ib.rarity:
			return ia.rarity > ib.rarity
		return String(ia.id) < String(ib.id))
	return slots


func _in_tab(item: ItemDefinition) -> bool:
	match _tab:
		Tab.EQUIPMENT:
			return item.item_type in [ItemDefinition.ItemType.WEAPON, ItemDefinition.ItemType.ARMOR, ItemDefinition.ItemType.ACCESSORY,
				ItemDefinition.ItemType.SKIN, ItemDefinition.ItemType.PET]
		Tab.FOOD:
			return item.item_type == ItemDefinition.ItemType.CONSUMABLE
		Tab.MATERIAL:
			return item.item_type == ItemDefinition.ItemType.MATERIAL
	return true
