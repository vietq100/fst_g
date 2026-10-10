class_name InventorySheet
extends Sheet
## Inventory (UI_DESIGN.md → Main HUD / Warehouse): slots, materials, spare equipment; selling.


func _init() -> void:
	title = "Inventory"


func _watch() -> Array:
	return [[GameManager.inventory, &"inventory_changed"], [GameManager.buildings, &"building_upgraded"]]


func _build(content: VBoxContainer) -> void:
	var inventory := GameManager.inventory
	content.add_child(UIKit.bar(inventory.used_slots(), inventory.capacity, &"TimerBar",
		"Warehouse slots %d / %d" % [inventory.used_slots(), inventory.capacity]))
	content.add_child(UIKit.label("Materials", &"AccentLabel"))
	var stacks := inventory.get_stacks()
	if stacks.is_empty():
		content.add_child(UIKit.label("No materials yet. Expeditions bring them home.", &"MutedLabel"))
	for item_id in stacks:
		var item := DataRegistry.get_item(item_id)
		var name_label := UIKit.label("%s ×%d" % [item.display_name, stacks[item_id]])
		name_label.add_theme_color_override(&"font_color", RarityColors.of(item.rarity))
		var sell := UIKit.button("Sell 1\n%d g" % item.sell_price, func() -> void:
			run_action("" if inventory.sell_item(item_id, 1) > 0 else "Nothing to sell"), &"DangerButton")
		sell.size_flags_horizontal = Control.SIZE_SHRINK_END
		sell.custom_minimum_size.x = 64
		content.add_child(UIKit.card(UIKit.hbox([UIKit.swatch(RarityColors.of(item.rarity), 14), name_label, sell])))
	content.add_child(UIKit.label("Spare equipment", &"AccentLabel"))
	var instances := inventory.get_instances()
	if instances.is_empty():
		content.add_child(UIKit.label("Nothing spare. Equipped items are on your Hunters.", &"MutedLabel"))
	for instance_id in instances:
		var item := DataRegistry.get_item(instances[instance_id])
		var info := UIKit.vbox([UIKit.label("%s · %s" % [item.display_name, UIKit.rarity_name(item)]),
			UIKit.label(UIKit.describe_modifiers(item), &"MutedLabel")], 2)
		(info.get_child(0) as Label).add_theme_color_override(&"font_color", RarityColors.of(item.rarity))
		var sell := UIKit.button("Sell\n%d g" % item.sell_price, func() -> void:
			run_action("" if inventory.sell_instance(instance_id) > 0 else "Cannot sell"), &"DangerButton")
		sell.size_flags_horizontal = Control.SIZE_SHRINK_END
		sell.custom_minimum_size.x = 64
		content.add_child(UIKit.card(UIKit.hbox([UIKit.swatch(RarityColors.of(item.rarity), 14), info, sell])))
	content.add_child(UIKit.label("Equip items from a Hunter's panel.", &"MutedLabel"))
