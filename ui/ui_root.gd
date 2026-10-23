class_name UIRoot
extends Control
## Mobile portrait UI (UI_DESIGN.md, DECISIONS.md D20, D23): top resource bar, bottom navigation,
## one bottom sheet at a time, toasts, and the expedition HUD. Respects the device safe area.
## UI never owns game state: it reads services, calls their actions and refreshes on signals.

## The player confirmed a party in the expedition sheet.
signal depart_requested(expedition_id: StringName, party: Array[StringName])
## Build menu "Place" / building sheet "Move": Main starts the world's placement mode (D33).
signal build_requested(building_id: StringName)
signal move_requested(instance_id: StringName)
## Placement bar buttons.
signal placement_confirmed
signal placement_cancelled
## Hunter sheet "Follow" / navigation "Town" (recenter the camera on the Town).
signal follow_requested(unique_id: StringName)
signal recenter_requested
## Settings → Switch profile: Main saves and shows the login screen.
signal logout_requested
## Height of the HUD at the top / navigation bar at the bottom (the map scrolls under them).
signal view_insets_changed(top: float, bottom: float)
## Screen px the open sheet / dialog covers at the bottom (0 when none): the camera keeps a
## followed Hunter in the free band above it.
signal sheet_cover_changed(height: float)
## Hex buttons I / II / III: look at a hunting region.
signal focus_region_requested(region_id: StringName)

enum Mode { TOWN, EXPEDITION, SANDBOX }

const TOAST_TIME := 2.6
const TOAST_FADE := 0.4
const MAX_TOASTS := 3
## Event feed lines (deposits, broken weapons): kept longer, fewer at once.
const FEED_TIME := 5.0
const FEED_FADE := 0.6
const MAX_FEED_LINES := 3
## Sheets cover at most this share of the screen height, above the navigation bar.
const SHEET_HEIGHT := 0.45
## Hunter / monster dialogs leave the top of the map free so the tapped Hunter stays in view.
const DIALOG_HEIGHT := 0.78

var mode := Mode.TOWN
## `func() -> Array[StringName]` giving the default party (Town.pick_party).
var party_picker: Callable = func() -> Array: return []

var _safe: MarginContainer
var _top_bar: PanelContainer
var _chips: Dictionary[StringName, Label] = {}
var _nav: PanelContainer
var _nav_buttons: Dictionary[StringName, Button] = {}
var _difficulty_button: Button
var _quest_title: Label
var _quest_text: Label
var _quest_bar: ProgressBar
var _waiting_button: Button
var _overlays: Array[Control] = []
var _feed: VBoxContainer
## Top-left notices without a background: the active quest, then the Hunters' event feed.
var _notices: VBoxContainer
var _quest_box: VBoxContainer
var _placement_bar: PanelContainer
var _placement_label: Label
var _placement_confirm: Button
var _sheet_area: Control
var _sheet: Sheet
var _toasts: VBoxContainer
## Navigation "Town" (lit while the camera is away from the Town).
var _town_button: Button
## Visible toast / feed lines by text: a repeat bumps a "×N" counter instead of adding a line.
var _toast_lines: Dictionary = {}
var _feed_lines: Dictionary = {}
## Last grade seen per Hunter (unique id → Step), for the "grade up" toast.
var _grade_seen: Dictionary = {}
var _expedition_hud: ExpeditionHud


func _ready() -> void:
	add_to_group(&"ui_root")
	theme = GameTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Ambient lighting over the map, under every HUD element.
	add_child(Vignette.new())
	_safe = MarginContainer.new()
	_safe.set_anchors_preset(Control.PRESET_FULL_RECT)
	_safe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_safe)
	var layout := UIKit.vbox([], 0)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_safe.add_child(layout)
	_build_top_bar(layout)
	_sheet_area = Control.new()
	_sheet_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sheet_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Sheets opened before the first layout pass (offline summary) need a re-layout.
	_sheet_area.resized.connect(_layout_sheet)
	layout.add_child(_sheet_area)
	_build_overlays()
	_build_placement_bar(layout)
	_build_nav(layout)
	_connect_notifications()
	for bar: Control in [_top_bar, _nav]:
		bar.resized.connect(_emit_insets)
		bar.visibility_changed.connect(_emit_insets)
	_emit_insets.call_deferred()
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()
	_refresh_resources()


func set_mode(new_mode: Mode) -> void:
	mode = new_mode
	close_sheet()
	_top_bar.visible = mode != Mode.EXPEDITION
	_nav.visible = mode == Mode.TOWN
	for overlay in _overlays:
		overlay.visible = mode == Mode.TOWN
	_highlight_nav()
	if mode == Mode.TOWN and _waiting_button != null:
		_refresh_resources()
	_placement_bar.visible = false
	if _expedition_hud != null:
		_expedition_hud.queue_free()
		_expedition_hud = null
	if mode == Mode.EXPEDITION:
		_expedition_hud = ExpeditionHud.new()
		_expedition_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
		_sheet_area.add_child(_expedition_hud)


## True if a screen point is covered by UI that should not let taps reach the world.
func blocks_point(point: Vector2) -> bool:
	# A modal over the screen (item details, equip picker) or a full-screen dialog (Hunter,
	# monster) takes every tap, not only the ones on its own rectangle.
	if _sheet is HunterDialog or _sheet is MonsterDialog:
		return true
	for child in get_children():
		if (child is ItemInfoModal or child is SkillInfoModal or child is EquipPickerModal or child is ColosseumMatchView) and (child as Control).is_visible_in_tree():
			return true
	for control: Control in [_top_bar, _nav, _sheet, _placement_bar] + _overlays:
		if control != null and is_instance_valid(control) and control.is_visible_in_tree() and control.get_global_rect().has_point(point):
			return true
	return false


# --- Sheets --------------------------------------------------------------------------------

func open_sheet(sheet: Sheet) -> void:
	close_sheet()
	_sheet = sheet
	sheet.closed.connect(close_sheet)
	sheet.open_requested.connect(open_sheet)
	sheet.toast_requested.connect(toast)
	sheet.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_sheet_area.add_child(sheet)
	_layout_sheet()
	_highlight_nav()


## Item details over everything (D64); the open sheet stays.
func open_item_info(item: ItemDefinition, instance_id: StringName = &"") -> void:
	if item == null:
		return
	var modal := ItemInfoModal.new().setup(item, instance_id)
	modal.toast_requested.connect(toast)
	add_child(modal)


## The summoning reveal (D83) over everything; the batch joins when it closes, confirmed or not.
func open_summon_reveal(hunters: Array[HunterRuntime], with_effects: bool) -> void:
	if hunters.is_empty():
		return
	var modal := SummonRevealModal.new().setup(hunters, with_effects)
	modal.confirmed.connect(func() -> void:
		var joined := GameManager.recruitment.confirm_arrivals()
		if not joined.is_empty():
			var asleep := joined.filter(func(h: HunterRuntime) -> bool: return h.hibernating).size()
			toast(Loc.t("ui.gate.summoned", {"count": joined.size(), "asleep": asleep}), false, &"hunters"))
	add_child(modal)


func request_logout() -> void:
	logout_requested.emit()


## Skill details over everything (class or monster skill); the open dialog stays.
func open_skill_info(skill: GameDefinition, options: Dictionary = {}) -> void:
	if skill != null:
		add_child(SkillInfoModal.new().setup(skill, options))


## What a Hunter can wear in one slot (D66), over everything; the open sheet stays.
func open_equip_picker(hunter: HunterRuntime, slot: StringName) -> void:
	if hunter == null or slot == &"":
		return
	add_child(EquipPickerModal.new().setup(hunter, slot))


func close_sheet() -> void:
	if _sheet != null and is_instance_valid(_sheet):
		_sheet.queue_free()
	_sheet = null
	_highlight_nav()
	sheet_cover_changed.emit(0.0)


## The camera has wandered off the Town: the "Town" button turns gold to offer the way back.
func set_camera_away(away: bool) -> void:
	if _town_button != null:
		_set_accent(_town_button, away)


## Gold text while `on` (a count that wants attention, the way back home); the theme's otherwise.
static func _set_accent(control: Control, on: bool) -> void:
	if on:
		control.add_theme_color_override(&"font_color", GameTheme.ACCENT)
	else:
		control.remove_theme_color_override(&"font_color")


## The nav tab of the open drawer is drawn as selected (light tab, dark text).
func _highlight_nav() -> void:
	var active := &""
	if _sheet is BuildSheet:
		active = &"construct"
	elif _sheet is ExpeditionSheet:
		active = &"dungeon"
	elif _sheet is HuntersSheet or _sheet is HunterSheet:
		active = &"hunters"
	elif _sheet is InventorySheet:
		active = &"storage"
	elif _sheet is ShopSheet:
		active = &"shop"
	# Notices never cover a drawer or dialog.
	if _notices != null:
		_notices.visible = mode == Mode.TOWN and not has_sheet()
	# The Hunter dialog takes the whole screen above the nav bar.
	if mode != Mode.EXPEDITION:
		_top_bar.visible = not (_sheet is HunterDialog or _sheet is MonsterDialog)
	for key in _nav_buttons:
		_nav_buttons[key].theme_type_variation = &"NavSelected" if key == active else &"NavButton"


func get_view_insets() -> Vector2:
	var top := _top_bar.size.y if _top_bar.visible else 0.0
	var bottom := _nav.size.y if _nav.visible else 0.0
	return Vector2(top, bottom)


func _emit_insets() -> void:
	var insets := get_view_insets()
	view_insets_changed.emit(insets.x, insets.y)


func has_sheet() -> bool:
	return _sheet != null and is_instance_valid(_sheet)


## `id`: a placed building instance id or a building type.
func open_building(id: StringName) -> void:
	var sheet := BuildingSheet.new(id)
	sheet.move_requested.connect(func(instance_id: StringName) -> void:
		close_sheet()
		move_requested.emit(instance_id))
	open_sheet(sheet)


func open_build() -> void:
	var sheet := BuildSheet.new()
	sheet.build_requested.connect(func(building_id: StringName) -> void:
		close_sheet()
		build_requested.emit(building_id))
	open_sheet(sheet)


## A dungeon entrance in the world was tapped (D35).
func open_entrance(expedition_id: StringName) -> void:
	var definition := DataRegistry.get_expedition(expedition_id)
	if definition == null:
		return
	open_expedition(expedition_id)


## Placement mode bar above the navigation (`active` false hides it). `reason` empty = can place.
func set_placement(active: bool, title: String = "", reason: String = "") -> void:
	_placement_bar.visible = active
	_nav.visible = mode == Mode.TOWN and not active
	if active:
		close_sheet()
		_placement_label.text = title if reason.is_empty() else "%s\n%s" % [title, reason]
		_placement_label.theme_type_variation = &"" if reason.is_empty() else &"WarningLabel"
		_placement_confirm.disabled = not reason.is_empty()


func open_hunters() -> void:
	var sheet := HuntersSheet.new()
	sheet.follow_requested.connect(func(unique_id: StringName) -> void:
		close_sheet()
		follow_requested.emit(unique_id))
	open_sheet(sheet)


func open_hunter(runtime: HunterRuntime) -> void:
	var sheet := HunterDialog.new(runtime)
	sheet.follow_requested.connect(func(unique_id: StringName) -> void:
		close_sheet()
		follow_requested.emit(unique_id))
	open_sheet(sheet)


func open_quests() -> void:
	open_sheet(QuestSheet.new())


func _refresh_quest_badge() -> void:
	_refresh_resources()


func open_monster(monster: Enemy) -> void:
	if is_instance_valid(monster):
		open_sheet(MonsterDialog.new(monster))


func open_inventory() -> void:
	open_sheet(InventorySheet.new())


func open_expedition(expedition_id: StringName = &"dark_forest") -> void:
	var party: Array[StringName] = []
	party.assign(party_picker.call())
	var sheet := ExpeditionSheet.new(expedition_id, party)
	sheet.depart_requested.connect(func(id: StringName, chosen: Array[StringName]) -> void:
		close_sheet()
		depart_requested.emit(id, chosen))
	open_sheet(sheet)


func show_message(sheet: MessageSheet) -> void:
	open_sheet(sheet)


func _layout_sheet() -> void:
	if not has_sheet():
		return
	var height: float
	_sheet.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	if _sheet is HunterDialog or _sheet is MonsterDialog:
		# Dialog over the map: nearly full width, with a band of the map free above it where the
		# camera keeps the tapped Hunter (sheet_cover_changed).
		height = minf(_sheet_area.size.y - 8.0, get_viewport_rect().size.y * DIALOG_HEIGHT)
		_sheet.offset_left = 12
		_sheet.offset_right = -12
		_sheet.offset_top = -height - 4
		_sheet.offset_bottom = -4
	else:
		height = minf(_sheet_area.size.y, get_viewport_rect().size.y * SHEET_HEIGHT)
		_sheet.offset_top = -height
		_sheet.offset_bottom = 0
		_sheet.offset_left = 0
		_sheet.offset_right = 0
	sheet_cover_changed.emit(height)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_sheet.call_deferred()


# --- Top bar, navigation, toasts ---------------------------------------------------------------

func _build_top_bar(layout: VBoxContainer) -> void:
	_top_bar = PanelContainer.new()
	_top_bar.theme_type_variation = &"Hud"
	# Difficulty badge and resources (left); Hunters and shortcuts (right). Like Evil Hunter
	# Tycoon's header: big outlined numbers over the map, each in its own dark pill.
	_difficulty_button = _badge_button(&"skull", func() -> void: _open_portal_or_hint())
	_difficulty_button.add_theme_color_override(&"font_color", GameTheme.ACCENT)
	_difficulty_button.custom_minimum_size = Vector2(52, 56)
	_difficulty_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_difficulty_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var resources := GridContainer.new()
	resources.columns = 2
	resources.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	resources.add_theme_constant_override(&"h_separation", 5)
	resources.add_theme_constant_override(&"v_separation", 5)
	for entry in [[&"gold", &"coin"], [&"food", &"food"], [&"slots", &"bag"], [&"chest", &"chest"]]:
		resources.add_child(_resource_chip(entry[0], entry[1], 66))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var right := UIKit.vbox([], 5)
	right.size_flags_horizontal = Control.SIZE_SHRINK_END
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var hunters_chip := _resource_chip(&"hunters", &"hunters", 0)
	hunters_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var count_line := UIKit.hbox([hunters_chip], 6)
	count_line.alignment = BoxContainer.ALIGNMENT_END
	right.add_child(count_line)
	var shortcuts := UIKit.hbox([], 4)
	shortcuts.alignment = BoxContainer.ALIGNMENT_END
	for entry in [[&"book", "ui.root.tip_quests", open_quests], [&"trophy", "ui.root.tip_portal", _open_portal_or_hint],
			[&"mail", "ui.root.tip_recruit", open_recruit], [&"gear", "ui.settings.title", open_settings]]:
		var button := UIKit.button("", entry[2], &"HudIconButton")
		button.icon = PixelIcons.texture(entry[0], 2)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.tooltip_text = Loc.t(entry[1])
		button.custom_minimum_size = Vector2(GameTheme.TOUCH, GameTheme.TOUCH)
		button.size_flags_horizontal = Control.SIZE_SHRINK_END
		# Settings sits beside the Hunter count so the header keeps three shortcuts per row.
		if entry[0] == &"gear":
			count_line.add_child(button)
		else:
			shortcuts.add_child(button)
	right.add_child(shortcuts)
	_top_bar.add_child(UIKit.hbox([_difficulty_button, resources, spacer, right], 8))
	layout.add_child(_top_bar)


## A resource in a dark pill (icon, outlined number) so it reads over any part of the map.
func _resource_chip(key: StringName, icon: StringName, min_width: float) -> PanelContainer:
	var label := UIKit.label("", &"HudLabel", false)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chips[key] = label
	var glyph := PixelIcons.rect(icon, 2)
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var chip := PanelContainer.new()
	chip.theme_type_variation = &"Chip"
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.custom_minimum_size.x = min_width
	chip.add_child(UIKit.hbox([glyph, label], 5))
	return chip


## HUD badge button: pixel icon over a small outlined caption, on a rounded plate.
func _badge_button(icon: StringName, action: Callable) -> Button:
	var button := UIKit.button("", action, &"HudBadge")
	button.icon = PixelIcons.texture(icon, 3)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.add_theme_font_size_override(&"font_size", GameTheme.SMALL_SIZE)
	return button


func _open_portal_or_hint() -> void:
	if GameManager.buildings.has_building(BuildingService.PORTAL):
		open_building(BuildingService.PORTAL)
	else:
		toast(Loc.t("toast.root.build_portal"), true)


func open_colosseum() -> void:
	if not GameManager.buildings.has_building(BuildingService.COLOSSEUM):
		toast(Loc.t("err.arena.no_colosseum"), true)
		return
	var sheet := ColosseumSheet.new()
	sheet.match_requested.connect(func(first: HunterRuntime, second: HunterRuntime, result: ArenaResult) -> void:
		close_sheet()
		var view := ColosseumMatchView.new().setup(first, second, result)
		view.finished.connect(open_colosseum)
		add_child(view))
	open_sheet(sheet)


func open_recruit() -> void:
	open_gate()


## Settings (gear button): the language picker.
func open_settings() -> void:
	open_sheet(SettingsSheet.new())


## The Hunter Gate sheet (D58): hire and expel.
func open_gate() -> void:
	open_sheet(GateSheet.new())


## The Boss Arena sheet (D58).
func open_arena() -> void:
	var sheet := BossSheet.new()
	sheet.focus_requested.connect(func(region_id: StringName) -> void: focus_region_requested.emit(region_id))
	open_sheet(sheet)


## The Hunter Gate or the arena altar was tapped in the world.
func open_structure(region_id: StringName) -> void:
	var region := DataRegistry.get_region(region_id)
	if region != null and region.kind == RegionDefinition.Kind.BOSS:
		open_arena()
	elif region != null and region.kind == RegionDefinition.Kind.MOUNT:
		open_sheet(HibernationSheet.new())
	else:
		open_gate()


func open_shop() -> void:
	open_sheet(ShopSheet.new())


func _refresh_resources() -> void:
	var gm := GameManager
	_chips[&"gold"].text = _format_number(gm.wallet.gold)
	_chips[&"food"].text = "%d" % gm.supply.get_food_stock()
	_chips[&"slots"].text = "%d/%d" % [gm.inventory.used_slots(), gm.inventory.capacity]
	var claimable := gm.quests.get_claimable_count()
	_chips[&"chest"].text = "%d" % claimable
	# Rewards waiting: the count lights up so the chest draws the eye.
	_set_accent(_chips[&"chest"], claimable > 0)
	_chips[&"hunters"].text = "%d/%d" % [gm.hunters.count_active(), gm.recruitment.get_active_cap()]
	_difficulty_button.text = gm.reincarnation.get_difficulty_name(gm.progress.difficulty)
	_refresh_quest_panel()
	if _waiting_button != null:
		var waiting := gm.recruitment.candidates.size()
		_waiting_button.text = Loc.t("ui.root.hunters_waiting") if waiting > 0 else Loc.t("ui.root.no_candidates")
		_waiting_button.visible = gm.buildings.has_building(BuildingService.TAVERN)


static func _format_number(value: int) -> String:
	var text := str(absi(value))
	var out := ""
	for i in text.length():
		if i > 0 and (text.length() - i) % 3 == 0:
			out += ","
		out += text[i]
	return ("-" if value < 0 else "") + out


func _refresh_quest_panel() -> void:
	if _quest_text == null:
		return
	var quests := GameManager.quests
	var active := quests.get_active()
	if active.is_empty():
		_quest_title.text = Loc.t("ui.root.quest_title")
		_quest_text.text = Loc.t("ui.root.all_quests_done")
		_quest_bar.visible = false
		return
	var quest := active[0]
	var progress := quests.get_progress(quest)
	var done := quests.is_complete(quest)
	var quest_args := {"quest": quest.description, "progress": "%d" % progress.x, "goal": "%d" % progress.y}
	_quest_text.text = Loc.t("ui.root.quest_claim" if done else "ui.root.quest_progress", quest_args)
	_quest_bar.visible = true
	_quest_bar.max_value = maxf(progress.y, 1)
	_quest_bar.value = progress.x


## Left: "Hunters Waiting" (Tavern candidates); right: Town / I / II / III region buttons; above
## them a small event feed, as in Evil Hunter Tycoon.
func _build_overlays() -> void:
	_waiting_button = _badge_button(&"hunters", open_recruit)
	_waiting_button.add_theme_color_override(&"font_color", Color("7fe0d0"))
	_waiting_button.add_theme_color_override(&"font_hover_color", Color("a8f0e4"))
	_waiting_button.custom_minimum_size = Vector2(64, 56)
	_waiting_button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_waiting_button.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_waiting_button.offset_left = 8
	_waiting_button.offset_bottom = -8
	_sheet_area.add_child(_waiting_button)
	_overlays.append(_waiting_button)
	var hex := GridContainer.new()
	hex.columns = 2
	hex.add_theme_constant_override(&"h_separation", 6)
	hex.add_theme_constant_override(&"v_separation", 6)
	hex.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hex.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hex.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hex.offset_right = -8
	hex.offset_bottom = -8
	var entries: Array = [[Loc.t("ui.root.town"), &""]]
	var numerals := ["I", "II", "III", "IV", "V"]
	var regions := GameManager.regions.get_hunting_regions()
	for i in regions.size():
		entries.append([numerals[mini(i, numerals.size() - 1)], regions[i].id])
	for entry in entries:
		var button := UIKit.button(entry[0], func() -> void:
			close_sheet()
			if entry[1] == &"":
				recenter_requested.emit()
			else:
				focus_region_requested.emit(entry[1]), &"RoundButton")
		button.custom_minimum_size = Vector2(40, 40)
		button.size_flags_horizontal = Control.SIZE_SHRINK_END
		button.add_theme_font_size_override(&"font_size", 14)
		button.tooltip_text = Loc.t("ui.root.town") if entry[1] == &"" else GameManager.regions.get_duty_name(entry[1])
		if entry[1] == &"":
			_town_button = button
		if entry[1] == &"":
			button.text = ""
			button.icon = PixelIcons.texture(&"town", 2)
			button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hex.add_child(button)
	_sheet_area.add_child(hex)
	_overlays.append(hex)
	# Top-left corner, above drawers and dialogs: the notices (quest card, feed; hidden while a
	# drawer or dialog is open) and the toasts (always shown), outlined text over the map.
	var corner := UIKit.vbox([], 6)
	corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corner.set_anchors_preset(Control.PRESET_TOP_LEFT)
	corner.offset_left = 8
	corner.offset_top = 8
	corner.offset_right = 248
	corner.z_index = 5
	_sheet_area.add_child(corner)
	_notices = UIKit.vbox([], 6)
	_notices.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corner.add_child(_notices)
	_toasts = UIKit.vbox([], 3)
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corner.add_child(_toasts)
	# The active quest: a small translucent card over the map, tap to open the quest list.
	var quest_card := PanelContainer.new()
	quest_card.theme_type_variation = &"QuestCard"
	quest_card.mouse_filter = Control.MOUSE_FILTER_STOP
	quest_card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			open_quests())
	_quest_box = UIKit.vbox([], 3)
	_quest_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quest_title = UIKit.label(Loc.t("ui.root.quest_title"), &"HudAccentLabel", false)
	_quest_text = UIKit.label("", &"HudSmallLabel")
	_quest_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quest_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quest_bar = UIKit.bar(0, 1, &"XpBar", "")
	_quest_bar.custom_minimum_size = Vector2(0, 6)
	_quest_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quest_box.add_child(_quest_title)
	_quest_box.add_child(_quest_text)
	_quest_box.add_child(_quest_bar)
	quest_card.add_child(_quest_box)
	_notices.add_child(quest_card)
	_overlays.append(quest_card)
	_feed = UIKit.vbox([], 2)
	_feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notices.add_child(_feed)


## One line of the event feed ("Ana sold 3 items (+40 g)"), fades out.
func feed(text: String) -> void:
	if _feed == null or text.is_empty():
		return
	if _bump_repeat(_feed_lines, text, FEED_TIME, FEED_FADE):
		return
	_evict_oldest(_feed, _feed_lines, MAX_FEED_LINES)
	var line := UIKit.label(text, &"HudSmallLabel")
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_feed.add_child(line)
	_hold_line(_feed_lines, line, line, text, FEED_TIME, FEED_FADE)


func _build_placement_bar(layout: VBoxContainer) -> void:
	_placement_bar = PanelContainer.new()
	_placement_bar.theme_type_variation = &"TopBar"
	_placement_label = UIKit.label("")
	_placement_confirm = UIKit.button(Loc.t("ui.common.confirm"), func() -> void: placement_confirmed.emit(), &"PrimaryButton")
	_placement_confirm.size_flags_horizontal = Control.SIZE_SHRINK_END
	_placement_confirm.custom_minimum_size.x = 76
	var cancel := UIKit.button(Loc.t("ui.common.cancel"), func() -> void: placement_cancelled.emit())
	cancel.size_flags_horizontal = Control.SIZE_SHRINK_END
	cancel.custom_minimum_size.x = 68
	_placement_bar.add_child(UIKit.hbox([_placement_label, _placement_confirm, cancel]))
	_placement_bar.visible = false
	layout.add_child(_placement_bar)


## Bottom navigation like Evil Hunter Tycoon: Construct, Dungeon, Hunters, Storage, Shop.
func _build_nav(layout: VBoxContainer) -> void:
	_nav = PanelContainer.new()
	_nav.theme_type_variation = &"NavBar"
	var buttons := UIKit.hbox([], 0)
	# [id, action, icon]; the label is the key ui.nav.<id>.
	for entry in [[&"construct", open_build, &"build"], [&"dungeon", open_expedition.bind(&"dark_forest"), &"arch"],
			[&"hunters", open_hunters, &"hunters"], [&"storage", open_inventory, &"chest"], [&"shop", open_shop, &"shop"]]:
		var button := UIKit.button(Loc.t("ui.nav.%s" % entry[0]), entry[1], &"NavButton")
		button.icon = PixelIcons.texture(entry[2], 3)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.add_theme_font_size_override(&"font_size", 11)
		button.add_theme_constant_override(&"h_separation", 3)
		button.custom_minimum_size.y = 62
		_nav_buttons[entry[0]] = button
		buttons.add_child(button)
	_nav.add_child(buttons)
	layout.add_child(_nav)


## `icon` (a PixelIcons kind) leads the line, so kinds of news tell apart at a glance.
func toast(text: String, is_error: bool = false, icon: StringName = &"") -> void:
	if text.is_empty():
		return
	if _bump_repeat(_toast_lines, text, TOAST_TIME, TOAST_FADE):
		return
	if is_error:
		Audio.play_ui(&"error")
	_evict_oldest(_toasts, _toast_lines, MAX_TOASTS)
	var label := UIKit.label(text, &"HudLabel")
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override(&"font_color", GameTheme.DANGER if is_error else Color("f2d36b"))
	var line: Control = label
	if icon != &"":
		var glyph := PixelIcons.rect(icon, 1)
		glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line = UIKit.hbox([glyph, label], 4)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toasts.add_child(line)
	# Fades in, so a new toast is noticed rather than popping in place (the box lays it out).
	line.modulate.a = 0.0
	line.create_tween().tween_property(line, ^"modulate:a", 1.0, 0.15)
	_hold_line(_toast_lines, line, label, text, TOAST_TIME, TOAST_FADE)


## Drops the oldest lines of `box` until fewer than `keep` remain, forgetting them in `lines`.
func _evict_oldest(box: Container, lines: Dictionary, keep: int) -> void:
	while box.get_child_count() >= keep:
		var oldest := box.get_child(0)
		lines.erase(oldest.get_meta(&"line_text", ""))
		box.remove_child(oldest)
		oldest.queue_free()


## Shows `node` (holding `label`) for `hold` s, fades it over `fade` s and frees it; remembers it in
## `lines` by its text so a repeat of the same text bumps a "×N" counter on it (_bump_repeat).
func _hold_line(lines: Dictionary, node: Control, label: Label, text: String, hold: float, fade: float) -> void:
	node.set_meta(&"line_text", text)
	var tween := node.create_tween()
	tween.tween_interval(hold)
	tween.tween_property(node, ^"modulate:a", 0.0, fade)
	tween.tween_callback(func() -> void:
		if lines.get(text, {}).get("node") == node:
			lines.erase(text)
		node.queue_free())
	lines[text] = {"node": node, "label": label, "tween": tween, "count": lines.get(text, {}).get("count", 1)}


## A line with this text is still showing: count the repeat on it and restart its timer.
func _bump_repeat(lines: Dictionary, text: String, hold: float, fade: float) -> bool:
	if not lines.has(text):
		return false
	var entry: Dictionary = lines[text]
	var node: Control = entry["node"]
	var label: Label = entry["label"]
	if not is_instance_valid(node) or not is_instance_valid(label):
		lines.erase(text)
		return false
	entry["count"] += 1
	label.text = Loc.t("ui.root.repeat_count", {"text": text, "count": entry["count"]})
	node.modulate.a = 1.0
	entry["tween"].kill()
	_hold_line(lines, node, label, text, hold, fade)
	return true


## Game events worth telling the player (UI_DESIGN.md → Feedback).
func _connect_notifications() -> void:
	var gm := GameManager
	gm.wallet.gold_changed.connect(func(_g: int, _d: int) -> void: _refresh_resources())
	gm.inventory.inventory_changed.connect(_refresh_resources)
	gm.buildings.layout_changed.connect(_refresh_resources)
	gm.housing.beds_changed.connect(_refresh_resources)
	gm.hunters.hunter_added.connect(func(_h: HunterRuntime) -> void: _refresh_resources())
	gm.buildings.building_upgraded.connect(func(id: StringName, level: int) -> void:
		_refresh_resources()
		toast(Loc.t("toast.root.reached_level", {"name": gm.buildings.get_definition(id).display_name, "level": level}), false, &"build"))
	gm.hunters.hunter_leveled_up.connect(func(hunter: HunterRuntime, level: int, _healed: float) -> void:
		if mode == Mode.TOWN:
			toast(Loc.t("toast.root.reached_level", {"name": hunter.display_name, "level": level}), false, &"build"))
	gm.quests.quests_changed.connect(_refresh_quest_badge)
	gm.hunters.hunter_changed.connect(func(hunter: HunterRuntime) -> void:
		# A Hunter measuring up to a higher grade (level, gear, awakening) is news (D80).
		var grade: int = gm.grades.hunter_grade(hunter)
		var before: int = _grade_seen.get(hunter.unique_id, grade)
		_grade_seen[hunter.unique_id] = grade
		if grade > before and mode == Mode.TOWN:
			toast(Loc.t("toast.root.grade_up", {"name": hunter.display_name, "grade": StatGradeService.name_of(grade)}), false, &"trophy"))
	gm.regions.bag_deposited.connect(func(hunter: HunterRuntime, report: Dictionary) -> void:
		var count := 0
		for quantity in report["items"].values():
			count += quantity
		if count > 0:
			feed(Loc.t("ui.root.feed_sold", {"name": hunter.display_name, "count": count,
				"gold": "%d" % (report["village_gold"] + report["trader_gold"])})))
	gm.equipment.weapon_broken.connect(func(hunter: HunterRuntime, item: ItemDefinition) -> void:
		feed(Loc.t("ui.root.feed_weapon_broken", {"name": hunter.display_name, "item": item.display_name})))
	gm.equipment.weapon_repaired.connect(func(hunter: HunterRuntime, item: ItemDefinition, cost: int) -> void:
		feed(Loc.t("ui.root.feed_weapon_repaired", {"name": hunter.display_name, "item": item.display_name, "gold": cost})))
	gm.recruitment.candidates_changed.connect(_refresh_resources)
	gm.quests.quest_completed.connect(func(quest: QuestDefinition) -> void:
		toast(Loc.t("toast.root.quest_done", {"quest": quest.display_name}), false, &"book"))
	_refresh_quest_badge()
	gm.reincarnation.difficulty_changed.connect(func(_d: int) -> void: _refresh_resources())
	gm.reincarnation.reincarnated.connect(func(hunter: HunterRuntime) -> void:
		toast(Loc.t("toast.root.reborn", {"name": hunter.display_name, "count": hunter.reincarnations}), false, &"star"))
	gm.trading.request_completed.connect(func(item_id: StringName, quantity: int) -> void:
		toast(Loc.t("toast.root.request_done", {"count": quantity, "item": DataRegistry.get_item(item_id).display_name}), false, &"shop"))
	gm.recruitment.hunter_recruited.connect(func(hunter: HunterRuntime) -> void:
		toast(Loc.t("toast.root.recruited", {"name": hunter.display_name}), false, &"hunters"))
	gm.temple.hunter_recovered.connect(func(hunter: HunterRuntime) -> void:
		toast(Loc.t("toast.root.recovered", {"name": hunter.display_name}), false, &"bed"))
	gm.corpses.hunter_died.connect(func(hunter: HunterRuntime) -> void:
		toast(Loc.t("toast.root.fallen", {"name": hunter.display_name}), true, &"skull"))
	gm.corpses.body_delivered.connect(func(hunter: HunterRuntime) -> void:
		toast(Loc.t("toast.root.delivered", {"name": hunter.display_name}), false, &"skull"))
	gm.bonds.bond_changed.connect(func(a: StringName, b: StringName, _value: float) -> void:
		if gm.bonds.is_bonded(a, b):
			toast(Loc.t("toast.root.bonded", {"a": gm.hunters.get_hunter(a).display_name, "b": gm.hunters.get_hunter(b).display_name}), false, &"hunters"))


func _apply_safe_area() -> void:
	var margins := Vector4.ZERO
	if OS.has_feature("mobile"):
		var window := Vector2(DisplayServer.window_get_size())
		var safe := Rect2(DisplayServer.get_display_safe_area())
		var scale := get_viewport_rect().size / window if window.x > 0.0 else Vector2.ONE
		margins = Vector4(safe.position.x, safe.position.y, window.x - safe.end.x, window.y - safe.end.y)
		margins = Vector4(margins.x * scale.x, margins.y * scale.y, margins.z * scale.x, margins.w * scale.y)
	_safe.add_theme_constant_override(&"margin_left", int(maxf(margins.x, 0.0)))
	_safe.add_theme_constant_override(&"margin_top", int(maxf(margins.y, 0.0)))
	_safe.add_theme_constant_override(&"margin_right", int(maxf(margins.z, 0.0)))
	_safe.add_theme_constant_override(&"margin_bottom", int(maxf(margins.w, 0.0)))
