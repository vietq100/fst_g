class_name InventorySheet
extends Sheet
## Inventory (UI_DESIGN.md → Main HUD / Warehouse): slots, materials, spare equipment; selling.


func _init() -> void:
	title = Loc.t("ui.inventory.title")


func _watch() -> Array:
	return [[GameManager.inventory, &"inventory_changed"], [GameManager.buildings, &"building_upgraded"]]


func _build(content: VBoxContainer) -> void:
	var inventory := GameManager.inventory
	content.add_child(UIKit.bar(inventory.used_slots(), inventory.capacity, &"TimerBar",
		Loc.t("ui.inventory.slots", {"used": inventory.used_slots(), "total": inventory.capacity})))
	content.add_child(UIKit.label(Loc.t("ui.inventory.materials"), &"AccentLabel"))
	var stacks := inventory.get_stacks()
	if stacks.is_empty():
		content.add_child(UIKit.label(Loc.t("ui.inventory.no_materials"), &"MutedLabel"))
	for item_id in stacks:
		var item := DataRegistry.get_item(item_id)
		var name_label := UIKit.label("%s ×%d" % [item.display_name, stacks[item_id]])
		name_label.add_theme_color_override(&"font_color", RarityColors.of(item.rarity))
		var sell := UIKit.button(Loc.t("ui.inventory.sell_one", {"gold": item.sell_price}), func() -> void:
			run_action("" if inventory.sell_item(item_id, 1) > 0 else Loc.t("ui.inventory.nothing_to_sell")), &"DangerButton")
		sell.size_flags_horizontal = Control.SIZE_SHRINK_END
		sell.custom_minimum_size.x = 64
		content.add_child(UIKit.card(UIKit.hbox([ItemIcon.new().setup(item, 32, "×%d" % stacks[item_id]), name_label, sell])))
	content.add_child(UIKit.label(Loc.t("ui.inventory.spare"), &"AccentLabel"))
	var instances := inventory.get_instances()
	if instances.is_empty():
		content.add_child(UIKit.label(Loc.t("ui.inventory.no_spare"), &"MutedLabel"))
	for instance_id in instances:
		var item := DataRegistry.get_item(instances[instance_id])
		var info := UIKit.vbox([UIKit.label("%s · %s" % [item.display_name, UIKit.rarity_name(item)]),
			UIKit.label(UIKit.describe_modifiers(item), &"MutedLabel")], 2)
		(info.get_child(0) as Label).add_theme_color_override(&"font_color", RarityColors.of(item.rarity))
		var sell := UIKit.button(Loc.t("ui.inventory.sell", {"gold": item.sell_price}), func() -> void:
			run_action("" if inventory.sell_instance(instance_id) > 0 else Loc.t("ui.inventory.cannot_sell")), &"DangerButton")
		sell.size_flags_horizontal = Control.SIZE_SHRINK_END
		sell.custom_minimum_size.x = 64
		var enhance := inventory.get_enhance(instance_id)
		content.add_child(UIKit.card(UIKit.hbox([ItemIcon.new().setup(item, 32, "+%d" % enhance if enhance > 0 else "", instance_id), info, sell])))
	content.add_child(UIKit.label(Loc.t("ui.inventory.equip_hint"), &"MutedLabel"))
