class_name BuildSheet
extends Sheet
## Build menu (BUILD_SYSTEM.md, D33): every building that can be bought, its cost and why it
## cannot be built right now. "Place" hands over to the world's placement mode.

signal build_requested(building_id: StringName)


func _watch() -> Array:
	var gm := GameManager
	return [[gm.wallet, &"gold_changed"], [gm.buildings, &"layout_changed"], [gm.housing, &"beds_changed"]]


func _build(content: VBoxContainer) -> void:
	set_title("Build")
	var buildings := GameManager.buildings
	var housing := GameManager.housing
	content.add_child(UIKit.label("Beds %d / %d used. Tap a spot in the Town to place, then confirm." % [
		housing.get_used_beds(), housing.get_total_beds()], &"MutedLabel"))
	for building_id in buildings.get_ids():
		var definition := buildings.get_definition(building_id)
		if definition.build_cost <= 0:
			continue
		var reason := buildings.can_build(building_id)
		var info := UIKit.vbox([
			UIKit.label("%s — %d gold" % [definition.display_name, definition.build_cost]),
			UIKit.label(BuildingSheet.DESCRIPTIONS.get(building_id, ""), &"MutedLabel"),
		], 2)
		if not reason.is_empty():
			info.add_child(UIKit.label(reason, &"WarningLabel"))
		var place := UIKit.button("Place", func() -> void: build_requested.emit(building_id), &"PrimaryButton", reason)
		place.size_flags_horizontal = Control.SIZE_SHRINK_END
		place.custom_minimum_size.x = 64
		content.add_child(UIKit.card(UIKit.hbox([info, place])))
