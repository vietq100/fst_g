class_name UIRoot
extends Control
## Mobile portrait UI (UI_DESIGN.md, DECISIONS.md D20, D23): top resource bar, bottom navigation,
## one bottom sheet at a time, toasts, and the expedition HUD. Respects the device safe area.
## UI never owns game state: it reads services, calls their actions and refreshes on signals.

## The player confirmed a party in the expedition sheet.
signal depart_requested(expedition_id: StringName, party: Array[StringName])

enum Mode { TOWN, EXPEDITION, SANDBOX }

const TOAST_TIME := 2.6
const MAX_TOASTS := 3
## Sheets cover at most this share of the screen height, above the navigation bar.
const SHEET_HEIGHT := 0.62

var mode := Mode.TOWN
## `func() -> Array[StringName]` giving the default party (Town.pick_party).
var party_picker: Callable = func() -> Array: return []

var _safe: MarginContainer
var _top_bar: PanelContainer
var _resources: Label
var _nav: PanelContainer
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
	layout.add_child(_sheet_area)
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
	if _expedition_hud != null:
		_expedition_hud.queue_free()
		_expedition_hud = null
	if mode == Mode.EXPEDITION:
		_expedition_hud = ExpeditionHud.new()
		_expedition_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
		_sheet_area.add_child(_expedition_hud)


## True if a screen point is covered by UI that should not let taps reach the world.
func blocks_point(point: Vector2) -> bool:
	for control: Control in [_top_bar, _nav, _sheet]:
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


func close_sheet() -> void:
	if _sheet != null and is_instance_valid(_sheet):
		_sheet.queue_free()
	_sheet = null


func has_sheet() -> bool:
	return _sheet != null and is_instance_valid(_sheet)


func open_building(building_id: StringName) -> void:
	if building_id == &"gate":
		open_expedition()
	else:
		open_sheet(BuildingSheet.new(building_id))


func open_hunters() -> void:
	open_sheet(HuntersSheet.new())


func open_hunter(runtime: HunterRuntime) -> void:
	open_sheet(HunterSheet.new(runtime))


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
	_top_bar.theme_type_variation = &"TopBar"
	_resources = UIKit.label("", &"", false)
	_top_bar.add_child(_resources)
	layout.add_child(_top_bar)


func _refresh_resources() -> void:
	var gm := GameManager
	_resources.text = "Gold %d    Dark Essence %d    Slots %d/%d    Town Lv %d" % [
		gm.wallet.gold, gm.inventory.count(&"dark_essence"), gm.inventory.used_slots(), gm.inventory.capacity, gm.progress.town_level]


## Bottom navigation: one-handed, primary actions in the bottom third (UI_DESIGN.md).
func _build_nav(layout: VBoxContainer) -> void:
	_nav = PanelContainer.new()
	_nav.theme_type_variation = &"TopBar"
	var buttons := UIKit.hbox([], 0)
	for entry in [["Town", close_sheet], ["Hunters", open_hunters], ["Expedition", open_expedition.bind(&"dark_forest")], ["Inventory", open_inventory]]:
		var button := UIKit.button(entry[0], entry[1], &"NavButton")
		button.custom_minimum_size.y = 48
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
	gm.buildings.building_upgraded.connect(func(id: StringName, level: int) -> void:
		_refresh_resources()
		toast("%s reached Lv %d" % [gm.buildings.get_definition(id).display_name, level]))
	gm.hunters.hunter_leveled_up.connect(func(hunter: HunterRuntime, level: int, _healed: float) -> void:
		if mode == Mode.TOWN:
			toast("%s reached Lv %d" % [hunter.display_name, level]))
	gm.recruitment.hunter_recruited.connect(func(hunter: HunterRuntime) -> void:
		toast("%s joined the roster" % hunter.display_name))
	gm.hospital.hunter_recovered.connect(func(hunter: HunterRuntime) -> void:
		toast("%s has recovered" % hunter.display_name))
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
