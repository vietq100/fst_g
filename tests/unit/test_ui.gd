extends TestCase
## UI smoke tests: every sheet builds against the live game services without script errors,
## and the UI kit helpers format values as the panels expect.

var _game: Node
var _nodes: Array[Node] = []


func before_each() -> void:
	_game = (Engine.get_main_loop() as SceneTree).root.get_node("GameManager")


func after_each() -> void:
	for node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()
	GameTheme.clear_cache()


func _show(sheet: Sheet) -> Sheet:
	# _ready builds the content once.
	(Engine.get_main_loop() as SceneTree).root.add_child(sheet)
	_nodes.append(sheet)
	return sheet


func test_every_sheet_builds() -> void:
	var hunter: HunterRuntime = _game.hunters.get_all()[0]
	var sheets: Array[Sheet] = [
		HuntersSheet.new(), HunterSheet.new(hunter), HunterDialog.new(hunter), InventorySheet.new(),
		ExpeditionSheet.new(&"dark_forest", [hunter.unique_id] as Array[StringName]),
		MessageSheet.new("Test", PackedStringArray(["line"])),
		MessageSheet.for_offline({"seconds": 4000.0, "capped": false, "recovered": PackedStringArray(["A"]), "xp": 10, "levels": 1,
			"meals": 2, "hungry_ticks": 1}),
		BuildSheet.new(), ExpeditionSheet.new(&"sunken_crypt", [] as Array[StringName]),
	]
	for building_id in _game.buildings.get_ids():
		sheets.append(BuildingSheet.new(building_id))
	for sheet in sheets:
		_show(sheet)
		assert_true(sheet._content.get_child_count() > 0, "%s has content" % sheet.get_script().get_global_name())


func test_sheet_actions_report_errors() -> void:
	var sheet := _show(InventorySheet.new())
	var messages: Array = []
	sheet.toast_requested.connect(func(text: String, error: bool) -> void: messages.append([text, error]))
	sheet.run_action("Not enough gold")
	sheet.run_action("", "Done")
	assert_eq(messages, [["Not enough gold", true], ["Done", false]])


func test_expedition_sheet_party_validation() -> void:
	var sheet := _show(ExpeditionSheet.new(&"dark_forest", [] as Array[StringName]))
	var depart := _find_button(sheet, "Walk to the entrance")
	assert_not_null(depart)
	assert_true(depart.disabled, "empty party cannot depart")


func test_locked_dungeon_has_no_depart_button() -> void:
	var sheet := _show(ExpeditionSheet.new(&"goblin_warren", [] as Array[StringName]))
	assert_null(_find_button(sheet, "Walk to the entrance"))


func test_hunter_sheet_offers_follow_and_duty() -> void:
	var hunter: HunterRuntime = _game.hunters.get_all()[0]
	var sheet := _show(HunterSheet.new(hunter)) as HunterSheet
	var followed: Array = []
	sheet.follow_requested.connect(func(id: StringName) -> void: followed.append(id))
	_find_button(sheet, "Follow").pressed.emit()
	assert_eq(followed, [hunter.unique_id])
	assert_not_null(_find_button(sheet, "Auto"))
	assert_not_null(_find_button(sheet, "Give 50"))


func test_kit_formatting() -> void:
	assert_eq(UIKit.format_duration(65.0), "1:05")
	assert_eq(UIKit.format_duration(3700.0), "1h 01m")
	assert_eq(UIKit.format_duration(-3.0), "0:00")
	var blade := DataRegistry.get_item(&"fang_blade")
	assert_eq(UIKit.describe_modifiers(blade), "+10 ATK +5% crit")
	assert_eq(UIKit.describe_modifiers(DataRegistry.get_item(&"iron_armor")), "+6 DEF +20 HP")


func test_ui_kit_controls_meet_touch_and_font_rules() -> void:
	var button := UIKit.button("X", func() -> void: pass)
	_nodes.append(button)
	assert_true(button.custom_minimum_size.x >= 40.0 and button.custom_minimum_size.y >= 40.0, "D23 touch target")
	var theme := GameTheme.get_theme()
	for variation in [&"MutedLabel", &"WarningLabel", &"TitleLabel", &"AccentLabel"]:
		assert_true(theme.get_font_size(&"font_size", variation) >= 10, "D23 font size %s" % variation)


func _find_button(node: Node, prefix: String) -> Button:
	if node is Button and (node as Button).text.begins_with(prefix):
		return node
	for child in node.get_children():
		var found := _find_button(child, prefix)
		if found != null:
			return found
	return null
