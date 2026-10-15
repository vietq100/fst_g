class_name InventorySheet
extends Sheet
## Storage (UI_DESIGN.md → Main HUD / Warehouse, D63): a grid of slots like the reference game —
## materials with their counts, then spare equipment with its enhancement — and a detail card for
## the tapped slot (name, rarity, effect, price) with its sell buttons.

const COLUMNS := 6
const SLOT := 44.0
const DETAIL_ICON := 56.0

## Selected stack (item id) or equipment piece (instance id); empty = nothing selected.
var _selected: StringName = &""
var _selected_is_instance := false


func _init() -> void:
	title = "Storage"


func _watch() -> Array:
	return [[GameManager.inventory, &"inventory_changed"], [GameManager.buildings, &"building_upgraded"]]


func _build(content: VBoxContainer) -> void:
	var inventory := GameManager.inventory
	content.add_child(UIKit.bar(inventory.used_slots(), inventory.capacity, &"TimerBar",
		"Warehouse slots %d / %d" % [inventory.used_slots(), inventory.capacity]))
	var stacks := inventory.get_stacks()
	var instances := inventory.get_instances()
	content.add_child(UIKit.label("Materials", &"AccentLabel"))
	if stacks.is_empty():
		content.add_child(UIKit.label("No materials yet. Hunters bring them home.", &"MutedLabel"))
	else:
		var grid := _grid()
		for item_id in stacks:
			var item := DataRegistry.get_item(item_id)
			grid.add_child(_slot(item, "×%d" % stacks[item_id], item_id, false))
		content.add_child(grid)
	content.add_child(UIKit.label("Equipment", &"AccentLabel"))
	if instances.is_empty():
		content.add_child(UIKit.label("Nothing spare. Equipped items are on your Hunters.", &"MutedLabel"))
	else:
		var grid := _grid()
		for instance_id in instances:
			var item := DataRegistry.get_item(instances[instance_id])
			var enhance := inventory.get_enhance(instance_id)
			grid.add_child(_slot(item, "+%d" % enhance if enhance > 0 else "", instance_id, true))
		content.add_child(grid)
	content.add_child(UIKit.separator())
	var detail := _detail(stacks, instances)
	content.add_child(detail if detail != null else UIKit.label("Tap an item to see it. Equip items from a Hunter's panel.", &"MutedLabel"))


func _grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override(&"h_separation", 4)
	grid.add_theme_constant_override(&"v_separation", 4)
	return grid


func _slot(item: ItemDefinition, badge: String, key: StringName, is_instance: bool) -> ItemIcon:
	var slot := ItemIcon.new().setup(item, SLOT, badge).tappable()
	slot.selected = key == _selected and is_instance == _selected_is_instance
	slot.tooltip_text = item.display_name
	slot.pressed.connect(func() -> void:
		_selected = key
		_selected_is_instance = is_instance
		request_rebuild())
	return slot


## Card for the selected slot, or null when nothing (still) selected.
func _detail(stacks: Dictionary[StringName, int], instances: Dictionary[StringName, StringName]) -> Control:
	if _selected == &"":
		return null
	var inventory := GameManager.inventory
	var item: ItemDefinition = null
	var count := 1
	if _selected_is_instance:
		if not instances.has(_selected):
			return null
		item = DataRegistry.get_item(instances[_selected])
	else:
		if not stacks.has(_selected):
			return null
		item = DataRegistry.get_item(_selected)
		count = stacks[_selected]
	var name_label := UIKit.label(item.display_name, &"TitleLabel", false)
	name_label.add_theme_color_override(&"font_color", RarityColors.of(item.rarity))
	var rarity := UIKit.label(UIKit.rarity_name(item) + ("  ×%d" % count if not _selected_is_instance else ""), &"MutedLabel", false)
	var info := UIKit.vbox([name_label, rarity], 2)
	var effect := _effect_text(item)
	if not effect.is_empty():
		info.add_child(UIKit.label(effect, &"AccentLabel"))
	info.add_child(UIKit.label("Sells for %d gold each" % item.sell_price, &"MutedLabel"))
	var icon := ItemIcon.new().setup(item, DETAIL_ICON)
	var column := UIKit.vbox([UIKit.hbox([icon, info], 8)], 6)
	var selected := _selected
	if _selected_is_instance:
		column.add_child(UIKit.button("Sell  %d g" % item.sell_price, func() -> void:
			run_action("" if inventory.sell_instance(selected) > 0 else "Cannot sell", "Sold %s" % item.display_name), &"DangerButton"))
	else:
		var sell_one := UIKit.button("Sell 1  %d g" % item.sell_price, func() -> void:
			run_action("" if inventory.sell_item(selected, 1) > 0 else "Nothing to sell"), &"DangerButton")
		var sell_all := UIKit.button("Sell all  %d g" % (item.sell_price * count), func() -> void:
			run_action("" if inventory.sell_item(selected, count) > 0 else "Nothing to sell", "Sold %d %s" % [count, item.display_name]), &"DangerButton")
		column.add_child(UIKit.hbox([sell_one, sell_all], 4))
	return UIKit.card(column)


static func _effect_text(item: ItemDefinition) -> String:
	if item.item_type == ItemDefinition.ItemType.CONSUMABLE:
		if item.heal_ratio > 0.0:
			return "Heals %d%% HP" % roundi(item.heal_ratio * 100.0)
		if item.energy > 0.0:
			return "Restores %d energy" % roundi(item.energy)
		return ""
	return UIKit.describe_modifiers(item)
