class_name BuildSheet
extends Sheet
## Build menu (BUILD_SYSTEM.md, D33, D63): a two-column grid of cards, each with a picture of the
## building (BuildingThumb, greyed out when it cannot be built), its name, cost and why it cannot
## be built right now. "Place" hands over to the world's placement mode.

signal build_requested(building_id: StringName)

const COLUMNS := 2
const THUMB := 84.0


func _watch() -> Array:
	var gm := GameManager
	return [[gm.wallet, &"gold_changed"], [gm.buildings, &"layout_changed"], [gm.housing, &"beds_changed"]]


func _build(content: VBoxContainer) -> void:
	set_title("Construct")
	var buildings := GameManager.buildings
	var housing := GameManager.housing
	content.add_child(UIKit.label("Beds %d / %d used. Place a building, tap a spot in the Town, then confirm." % [
		housing.get_used_beds(), housing.get_total_beds()], &"MutedLabel"))
	# Two columns of picture cards (D63), like the reference game's construction menu.
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override(&"h_separation", 6)
	grid.add_theme_constant_override(&"v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for building_id in buildings.get_ids():
		var definition := buildings.get_definition(building_id)
		if definition.build_cost <= 0:
			continue
		grid.add_child(_card(building_id, definition, buildings.can_build(building_id)))
	content.add_child(grid)


func _card(building_id: StringName, definition: BuildingDefinition, reason: String) -> Control:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"HunterCard"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.tooltip_text = BuildingSheet.DESCRIPTIONS.get(building_id, "")
	var thumb := BuildingThumb.new().setup(building_id, definition.footprint, 1, THUMB, not reason.is_empty())
	var name_label := UIKit.label(definition.display_name, &"HudSmallLabel", false)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	var cost := UIKit.label("%d" % definition.build_cost, &"HudAccentLabel", false)
	cost.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var price := UIKit.hbox([PixelIcons.rect(&"coin", 1), cost], 3)
	price.alignment = BoxContainer.ALIGNMENT_CENTER
	var column := UIKit.vbox([thumb, name_label, price], 3)
	if not reason.is_empty():
		var why := UIKit.label(reason, &"WarningLabel")
		why.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		why.add_theme_font_size_override(&"font_size", 9)
		column.add_child(why)
	var place := UIKit.button("Place", func() -> void: build_requested.emit(building_id), &"PrimaryButton", reason)
	place.custom_minimum_size.y = 34
	column.add_child(place)
	panel.add_child(column)
	return panel
