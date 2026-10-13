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
## Hex buttons I / II / III: look at a hunting region.
signal focus_region_requested(region_id: StringName)

enum Mode { TOWN, EXPEDITION, SANDBOX }

const TOAST_TIME := 2.6
const MAX_TOASTS := 3
## Sheets cover at most this share of the screen height, above the navigation bar.
const SHEET_HEIGHT := 0.45

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
var _placement_bar: PanelContainer
var _placement_label: Label
var _placement_confirm: Button
var _sheet_area: Control
var _sheet: Sheet
var _toasts: VBoxContainer
var _expedition_hud: ExpeditionHud


func _ready() -> void:
	theme = GameTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_safe = MarginContainer.new()
	_safe.set_anchors_preset(Control.PRESET_FULL_RECT)
	_safe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_safe)
	var layout := UIKit.vbox([], 0)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_safe.add_child(layout)
	_build_top_bar(layout)
	_toasts = UIKit.vbox([], 4)
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(_toasts)
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


func close_sheet() -> void:
	if _sheet != null and is_instance_valid(_sheet):
		_sheet.queue_free()
	_sheet = null
	_highlight_nav()


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
	# The Hunter dialog takes the whole screen above the nav bar.
	if mode != Mode.EXPEDITION:
		_top_bar.visible = not (_sheet is HunterDialog)
	for key in _nav_buttons:
		_nav_buttons[key].theme_type_variation = &"NavSelected" if key == active else &"NavButton"


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
	if _sheet is HunterDialog:
		# Centered dialog over the map: nearly full width, as tall as the area allows.
		_sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
		_sheet.offset_left = 12
		_sheet.offset_right = -12
		_sheet.offset_top = 4
		_sheet.offset_bottom = -4
		return
	_sheet.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	var height := minf(_sheet_area.size.y, get_viewport_rect().size.y * SHEET_HEIGHT)
	_sheet.offset_top = -height
	_sheet.offset_bottom = 0
	_sheet.offset_left = 0
	_sheet.offset_right = 0


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_sheet.call_deferred()


# --- Top bar, navigation, toasts ---------------------------------------------------------------

func _build_top_bar(layout: VBoxContainer) -> void:
	_top_bar = PanelContainer.new()
	_top_bar.theme_type_variation = &"Hud"
	var column := UIKit.vbox([], 4)
	# Row 1: difficulty badge, resources (left); hunters and shortcuts (right). Like Evil Hunter
	# Tycoon's header: big outlined numbers over the map.
	_difficulty_button = UIKit.button("", func() -> void: _open_portal_or_hint(), &"HudButton")
	_difficulty_button.icon = PixelIcons.texture(&"skull", 3)
	_difficulty_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_difficulty_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	_difficulty_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_difficulty_button.add_theme_font_size_override(&"font_size", GameTheme.SMALL_SIZE)
	_difficulty_button.custom_minimum_size = Vector2(48, 48)
	_difficulty_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var resources := GridContainer.new()
	resources.columns = 2
	resources.add_theme_constant_override(&"h_separation", 4)
	resources.add_theme_constant_override(&"v_separation", 3)
	for entry in [[&"gold", &"coin"], [&"food", &"food"], [&"slots", &"bag"], [&"chest", &"chest"]]:
		var line := UIKit.hbox([PixelIcons.rect(entry[1], 2)], 4)
		var label := UIKit.label("", &"HudLabel", false)
		label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		line.add_child(label)
		_chips[entry[0]] = label
		# Each resource sits in a dark pill so the numbers read over any part of the map.
		var chip := PanelContainer.new()
		chip.theme_type_variation = &"Chip"
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(line)
		resources.add_child(chip)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var right := UIKit.vbox([], 4)
	right.size_flags_horizontal = Control.SIZE_SHRINK_END
	var count_line := UIKit.hbox([PixelIcons.rect(&"hunters", 2)], 4)
	var count_label := UIKit.label("", &"HudLabel", false)
	count_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	count_line.add_child(count_label)
	count_line.alignment = BoxContainer.ALIGNMENT_END
	_chips[&"hunters"] = count_label
	right.add_child(count_line)
	var shortcuts := UIKit.hbox([], 2)
	for entry in [[&"book", "Quests", open_quests], [&"trophy", "Portal", _open_portal_or_hint], [&"mail", "Recruit", open_recruit]]:
		var button := UIKit.button("", entry[2], &"HudButton")
		button.icon = PixelIcons.texture(entry[0], 2)
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.tooltip_text = entry[1]
		button.custom_minimum_size = Vector2(30, 30)
		button.size_flags_horizontal = Control.SIZE_SHRINK_END
		shortcuts.add_child(button)
	right.add_child(shortcuts)
	column.add_child(UIKit.hbox([_difficulty_button, resources, spacer, right], 6))
	# Row 2: the active quest and the advisor's hint.
	var quest_box := UIKit.vbox([], 2)
	_quest_title = UIKit.label("Quest", &"HudAccentLabel", false)
	_quest_title.visible = false
	_quest_text = UIKit.label("", &"HudSmallLabel")
	_quest_text.add_theme_font_size_override(&"font_size", 10)
	_quest_bar = UIKit.bar(0, 1, &"XpBar", "")
	_quest_bar.custom_minimum_size = Vector2(0, 5)
	quest_box.add_child(_quest_text)
	quest_box.add_child(_quest_bar)
	var quest_button := UIKit.button("", open_quests, &"HudButton")
	quest_button.flat = true
	quest_button.mouse_filter = Control.MOUSE_FILTER_STOP
	var quest_panel := PanelContainer.new()
	quest_panel.theme_type_variation = &"HudBubble"
	quest_panel.add_child(quest_box)
	quest_panel.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			open_quests())
	column.add_child(quest_panel)
	_top_bar.add_child(column)
	layout.add_child(_top_bar)


func _open_portal_or_hint() -> void:
	if GameManager.buildings.has_building(BuildingService.PORTAL):
		open_building(BuildingService.PORTAL)
	else:
		toast("Build the Reincarnation Portal (Town Hall Lv 3) to change difficulty", true)


func open_recruit() -> void:
	if GameManager.buildings.has_building(BuildingService.TAVERN):
		open_building(BuildingService.TAVERN)
	else:
		toast("Build a Tavern to recruit Hunters", true)


func open_shop() -> void:
	open_sheet(ShopSheet.new())


func _refresh_resources() -> void:
	var gm := GameManager
	_chips[&"gold"].text = _format_number(gm.wallet.gold)
	_chips[&"food"].text = "%d" % gm.supply.get_food_stock()
	_chips[&"slots"].text = "%d/%d" % [gm.inventory.used_slots(), gm.inventory.capacity]
	_chips[&"chest"].text = "%d" % gm.quests.get_claimable_count()
	_chips[&"hunters"].text = "%d/%d" % [gm.hunters.count(), gm.recruitment.get_capacity()]
	_difficulty_button.text = gm.reincarnation.get_difficulty_name(gm.progress.difficulty)
	_refresh_quest_panel()
	if _waiting_button != null:
		var waiting := gm.recruitment.candidates.size()
		_waiting_button.text = "Hunters\nWaiting" if waiting > 0 else "No\ncandidates"
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
		_quest_title.text = "Quest"
		_quest_text.text = "All quests done. Play on at your own pace."
		_quest_bar.visible = false
		return
	var quest := active[0]
	var progress := quests.get_progress(quest)
	var done := quests.is_complete(quest)
	_quest_text.text = "%s%s (%d/%d)" % ["Claim reward! " if done else "Quest: ", quest.description, progress.x, progress.y]
	_quest_bar.visible = true
	_quest_bar.max_value = maxf(progress.y, 1)
	_quest_bar.value = progress.x


## Left: "Hunters Waiting" (Tavern candidates); right: Town / I / II / III region buttons; above
## them a small event feed, as in Evil Hunter Tycoon.
func _build_overlays() -> void:
	_waiting_button = UIKit.button("Hunters\nWaiting", open_recruit, &"HudButton")
	_waiting_button.icon = PixelIcons.texture(&"hunters", 2)
	_waiting_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_waiting_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	_waiting_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_waiting_button.add_theme_font_size_override(&"font_size", GameTheme.SMALL_SIZE)
	_waiting_button.add_theme_color_override(&"font_color", Color("7fe0d0"))
	_waiting_button.add_theme_color_override(&"font_outline_color", GameTheme.INK)
	_waiting_button.add_theme_constant_override(&"outline_size", 3)
	_waiting_button.custom_minimum_size = Vector2(52, 50)
	_waiting_button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_waiting_button.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_waiting_button.offset_left = 4
	_waiting_button.offset_bottom = -4
	_sheet_area.add_child(_waiting_button)
	_overlays.append(_waiting_button)
	var hex := GridContainer.new()
	hex.columns = 2
	hex.add_theme_constant_override(&"h_separation", 4)
	hex.add_theme_constant_override(&"v_separation", 4)
	hex.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hex.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hex.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hex.offset_right = -4
	hex.offset_bottom = -4
	var entries: Array = [["Town", &""]]
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
		button.custom_minimum_size = Vector2(38, 38)
		button.size_flags_horizontal = Control.SIZE_SHRINK_END
		button.add_theme_font_size_override(&"font_size", 13)
		button.tooltip_text = "Town" if entry[1] == &"" else GameManager.regions.get_duty_name(entry[1])
		if entry[1] == &"":
			button.text = ""
			button.icon = PixelIcons.texture(&"town", 2)
			button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hex.add_child(button)
	_sheet_area.add_child(hex)
	_overlays.append(hex)
	_feed = UIKit.vbox([], 2)
	_feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_feed.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_feed.offset_left = 6
	_feed.offset_top = 6
	_feed.offset_right = 250
	_sheet_area.add_child(_feed)


## One line of the event feed ("Ana sold 3 items (+40 g)"), fades out.
func feed(text: String) -> void:
	if _feed == null or text.is_empty():
		return
	while _feed.get_child_count() >= 3:
		var oldest := _feed.get_child(0)
		_feed.remove_child(oldest)
		oldest.queue_free()
	var line := UIKit.label(text, &"HudSmallLabel")
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_feed.add_child(line)
	var tween := line.create_tween()
	tween.tween_interval(5.0)
	tween.tween_property(line, ^"modulate:a", 0.0, 0.6)
	tween.tween_callback(line.queue_free)


func _build_placement_bar(layout: VBoxContainer) -> void:
	_placement_bar = PanelContainer.new()
	_placement_bar.theme_type_variation = &"TopBar"
	_placement_label = UIKit.label("")
	_placement_confirm = UIKit.button("Confirm", func() -> void: placement_confirmed.emit(), &"PrimaryButton")
	_placement_confirm.size_flags_horizontal = Control.SIZE_SHRINK_END
	_placement_confirm.custom_minimum_size.x = 76
	var cancel := UIKit.button("Cancel", func() -> void: placement_cancelled.emit())
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
	for entry in [["Construct", open_build, &"build"], ["Dungeon", open_expedition.bind(&"dark_forest"), &"arch"],
			["Hunters", open_hunters, &"hunters"], ["Storage", open_inventory, &"chest"], ["Shop", open_shop, &"shop"]]:
		var button := UIKit.button(entry[0], entry[1], &"NavButton")
		button.icon = PixelIcons.texture(entry[2], 3)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.add_theme_font_size_override(&"font_size", 10)
		button.add_theme_color_override(&"font_outline_color", GameTheme.INK)
		button.add_theme_constant_override(&"outline_size", 3)
		button.custom_minimum_size.y = 58
		_nav_buttons[StringName(entry[0].to_lower())] = button
		buttons.add_child(button)
	_nav.add_child(buttons)
	layout.add_child(_nav)


func toast(text: String, is_error: bool = false) -> void:
	if text.is_empty():
		return
	while _toasts.get_child_count() >= MAX_TOASTS:
		var oldest := _toasts.get_child(0)
		_toasts.remove_child(oldest)
		oldest.queue_free()
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"Toast"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := UIKit.label(text, &"WarningLabel" if is_error else &"AccentLabel")
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	_toasts.add_child(panel)
	var tween := panel.create_tween()
	tween.tween_interval(TOAST_TIME)
	tween.tween_property(panel, ^"modulate:a", 0.0, 0.4)
	tween.tween_callback(panel.queue_free)


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
		toast("%s reached Lv %d" % [gm.buildings.get_definition(id).display_name, level]))
	gm.hunters.hunter_leveled_up.connect(func(hunter: HunterRuntime, level: int, _healed: float) -> void:
		if mode == Mode.TOWN:
			toast("%s reached Lv %d" % [hunter.display_name, level]))
	gm.quests.quests_changed.connect(_refresh_quest_badge)
	gm.regions.bag_deposited.connect(func(hunter: HunterRuntime, report: Dictionary) -> void:
		var count := 0
		for quantity in report["items"].values():
			count += quantity
		if count > 0:
			feed("%s has sold %d items (+%d g)" % [hunter.display_name, count, report["village_gold"] + report["trader_gold"]]))
	gm.recruitment.candidates_changed.connect(_refresh_resources)
	gm.quests.quest_completed.connect(func(quest: QuestDefinition) -> void:
		toast("Quest done: %s — claim your reward" % quest.display_name))
	_refresh_quest_badge()
	gm.reincarnation.difficulty_changed.connect(func(_d: int) -> void: _refresh_resources())
	gm.reincarnation.reincarnated.connect(func(hunter: HunterRuntime) -> void:
		toast("%s was reborn (×%d)" % [hunter.display_name, hunter.reincarnations]))
	gm.trading.request_completed.connect(func(item_id: StringName, quantity: int) -> void:
		toast("Request done: %d %s" % [quantity, DataRegistry.get_item(item_id).display_name]))
	gm.recruitment.hunter_recruited.connect(func(hunter: HunterRuntime) -> void:
		toast("%s joined the roster" % hunter.display_name))
	gm.temple.hunter_recovered.connect(func(hunter: HunterRuntime) -> void:
		toast("%s is back on their feet" % hunter.display_name))
	gm.corpses.hunter_died.connect(func(hunter: HunterRuntime) -> void:
		toast("%s has fallen" % hunter.display_name, true))
	gm.corpses.body_delivered.connect(func(hunter: HunterRuntime) -> void:
		toast("%s was carried to the Temple" % hunter.display_name))
	gm.bonds.bond_changed.connect(func(a: StringName, b: StringName, _value: float) -> void:
		if gm.bonds.is_bonded(a, b):
			toast("%s and %s are now bonded" % [gm.hunters.get_hunter(a).display_name, gm.hunters.get_hunter(b).display_name]))


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
