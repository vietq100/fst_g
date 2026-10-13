class_name ShopSheet
extends Sheet
## Town services (the "Shop" tab of Evil Hunter Tycoon): one list of every service building with
## a shortcut to its panel, or what is needed to unlock it.

const SERVICES: Array[StringName] = [&"tavern", &"trading_post", &"academy", &"forge", &"portal", &"restaurant",
	&"blacksmith", &"hospital", &"temple", &"warehouse", &"town_hall", &"inn"]


func _watch() -> Array:
	var gm := GameManager
	return [[gm.buildings, &"layout_changed"], [gm.buildings, &"building_upgraded"]]


func _build(content: VBoxContainer) -> void:
	set_title(Loc.t("ui.shop.title"))
	var buildings := GameManager.buildings
	var quests := UIKit.button(Loc.t("ui.shop.quests", {"count": GameManager.quests.get_claimable_count()}),
		func() -> void: open_requested.emit(QuestSheet.new()), &"PrimaryButton" if GameManager.quests.get_claimable_count() > 0 else &"")
	content.add_child(quests)
	for building_id in SERVICES:
		var definition := buildings.get_definition(building_id)
		if definition == null:
			continue
		var level := buildings.get_level(building_id)
		var info := UIKit.vbox([
			UIKit.label(Loc.t("ui.shop.name_level", {"name": definition.display_name, "level": level}) if level > 0 else definition.display_name),
			UIKit.label(BuildingSheet.describe(building_id), &"MutedLabel"),
		], 2)
		var action: Button
		if level > 0:
			action = UIKit.button(Loc.t("ui.shop.open"), func() -> void: open_requested.emit(BuildingSheet.new(building_id)), &"PrimaryButton")
		else:
			var reason := buildings.can_build(building_id)
			info.add_child(UIKit.label(reason if not reason.is_empty() else Loc.t("ui.shop.not_built_hint"), &"WarningLabel"))
			action = UIKit.button(Loc.t("ui.shop.locked"), func() -> void: pass, &"", Loc.t("ui.shop.not_built"))
		action.size_flags_horizontal = Control.SIZE_SHRINK_END
		action.custom_minimum_size.x = 64
		content.add_child(UIKit.card(UIKit.hbox([info, action])))
