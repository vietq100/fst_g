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
		BuildSheet.new(), ExpeditionSheet.new(&"sunken_crypt", [] as Array[StringName]), GateSheet.new(), BossSheet.new(),
	]
	for building_id in _game.buildings.get_ids():
		sheets.append(BuildingSheet.new(building_id))
	for sheet in sheets:
		_show(sheet)
		assert_true(sheet._content.get_child_count() > 0, "%s has content" % sheet.get_script().get_global_name())


## No sheet may be wider than a phone screen in any language (owner report: the Life tab spilled
## off screen in Vietnamese). Every tab of the Hunter dialog is checked too.
func test_sheets_fit_the_screen_in_every_language() -> void:
	var width := 360.0
	var hunter: HunterRuntime = _game.hunters.get_all()[0]
	for code in Loc.LOCALES:
		Loc.set_locale(code, false)
		var sheets: Array[Sheet] = [HuntersSheet.new(), HunterSheet.new(hunter), InventorySheet.new(), BuildSheet.new(),
			ExpeditionSheet.new(&"dark_forest", [hunter.unique_id] as Array[StringName]), GateSheet.new(), BossSheet.new(),
			SettingsSheet.new(), QuestSheet.new(), ShopSheet.new()]
		for tab in HunterDialog.Tab.values():
			var dialog := HunterDialog.new(hunter)
			dialog._tab = tab
			sheets.append(dialog)
		for building_id in _game.buildings.get_ids():
			sheets.append(BuildingSheet.new(building_id))
		for sheet in sheets:
			_show(sheet)
			var needed := sheet.get_combined_minimum_size().x
			assert_true(needed <= width, "%s (%s, tab %s) needs %d px" % [sheet.get_script().get_global_name(), code,
				sheet.get("_tab"), needed])
	Loc.set_locale("en", false)


## Class skills section (D70) with skills, points and swap buttons fits a phone in every language.
func test_class_skills_tab_fits_the_screen() -> void:
	var hunter: HunterRuntime = _game.hunters.get_all()[0]
	var saved_skills := hunter.class_skills.duplicate()
	var saved := [hunter.skill_points, hunter.skill_swap_points]
	for skill in _game.class_skills.get_pool(_game.class_skills.get_base_class(hunter)).slice(0, 7):
		hunter.class_skills[skill.id] = 3
	hunter.skill_points = 2
	hunter.skill_swap_points = 1
	for code in Loc.LOCALES:
		Loc.set_locale(code, false)
		var dialog := HunterDialog.new(hunter)
		dialog._tab = HunterDialog.Tab.SKILLS
		_show(dialog)
		assert_true(dialog.get_combined_minimum_size().x <= 360.0, "skills tab (%s) needs %d px" % [code, dialog.get_combined_minimum_size().x])
	Loc.set_locale("en", false)
	hunter.class_skills = saved_skills
	hunter.skill_points = saved[0]
	hunter.skill_swap_points = saved[1]


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


## The item panel and the slot picker are modals (D64–D66) and fit a phone screen.
func test_item_modal_and_picker_build_and_fit() -> void:
	var hunter: HunterRuntime = _game.hunters.get_all()[0]
	var weapon: StringName = hunter.equipment.get(&"weapon", &"")
	var root := (Engine.get_main_loop() as SceneTree).root
	for code in Loc.LOCALES:
		Loc.set_locale(code, false)
		var modals: Array[Control] = [EquipPickerModal.new().setup(hunter, &"weapon"), EquipPickerModal.new().setup(hunter, &"helmet")]
		if weapon != &"":
			modals.append(ItemInfoModal.new().setup(_game.equipment.get_item(weapon), weapon))
		for modal in modals:
			root.add_child(modal)
			_nodes.append(modal)
			var frame := modal.get_child(1).get_child(0) as Control
			assert_true(frame.get_child(0).get_child_count() > 1, "%s has content" % modal.get_script().get_global_name())
			assert_true(frame.get_combined_minimum_size().x <= 360.0, "%s fits (%s): %d" % [modal.get_script().get_global_name(), code,
				frame.get_combined_minimum_size().x])
	Loc.set_locale("en", false)



func test_monster_sheet_shows_stats_rewards_and_drops() -> void:
	var definition := DataRegistry.get_enemy(&"wolf")
	var enemy := definition.actor_scene.instantiate() as Enemy
	(Engine.get_main_loop() as SceneTree).root.add_child(enemy)
	_nodes.append(enemy)
	enemy.setup(definition, _game.combat, 0.5, 3, 1.2, Tier.Level.R)
	var sheet := _show(MonsterDialog.new(enemy))
	assert_true(sheet._content.get_child_count() >= 6, "monster sheet has content")
	var text := _all_text(sheet)
	assert_true(text.contains(Loc.t("stat.attack")), "stats shown")
	assert_true(text.contains("3"), "level shown")


func _all_text(node: Node) -> String:
	var text := ""
	if node is Label:
		text += (node as Label).text + "\n"
	for child in node.get_children():
		text += _all_text(child)
	return text


func test_open_modal_blocks_taps_to_the_map() -> void:
	var ui := UIRoot.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(ui)
	_nodes.append(ui)
	var corner := Vector2(2, 2)
	ui.open_building(&"town_hall")
	assert_false(ui.blocks_point(Vector2(1.0e5, 1.0e5)), "a normal sheet only blocks its own area")
	ui.open_hunter(_game.hunters.get_all()[0])
	assert_true(ui.blocks_point(Vector2(1.0e5, 1.0e5)), "a full-screen dialog blocks every tap")
	ui.close_sheet()
	var item := DataRegistry.get_item(&"iron_sword")
	ui.open_item_info(item)
	assert_true(ui.blocks_point(corner), "an item modal blocks every tap")


func test_colosseum_sheet_and_replay_build() -> void:
	var hunter: HunterRuntime = _game.hunters.get_all()[0]
	var sheet := _show(ColosseumSheet.new())
	assert_true(sheet._content.get_child_count() > 0, "sheet has content")
	var rival: HunterRuntime = _game.arena.make_rival(_game.arena.get_power(hunter))
	var result: ArenaResult = _game.arena.simulate(hunter, rival, 7)
	var view := ColosseumMatchView.new().setup(hunter, rival, result)
	(Engine.get_main_loop() as SceneTree).root.add_child(view)
	_nodes.append(view)
	view._skip()
	assert_true(view._ended, "skip jumps to the result")
	assert_true(view._next_event >= result.events.size(), "every blow was replayed")
