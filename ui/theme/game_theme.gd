class_name GameTheme
extends RefCounted
## The game's UI theme (UI_DESIGN.md: fantasy management, clean, readable; Evil Hunter Tycoon
## palette: deep navy panels, gold rims, green confirm / red cancel buttons, white outlined
## numbers; DECISIONS.md D23: fonts ≥ 10 px, body 12, touch targets ≥ 40 px).
## Built in code so colours live in one place. Buttons are chunky (a darker bottom edge that
## flattens when pressed); panels have a warm gold rim and a soft drop shadow. Type variations:
## Button: PrimaryButton, DangerButton, SelectedButton, NavButton, RowButton
## PanelContainer: Sheet, Card, TopBar, Toast, Chip (HUD resource pill) · ProgressBar: HpBar, XpBar, MoodBar, TimerBar
## Label: TitleLabel, MutedLabel, AccentLabel, WarningLabel

const BACKGROUND := Color("12141c")
const PANEL := Color("1f2433")
const CARD := Color("2a3042")
const BORDER := Color("c9a24a")
const TEXT := Color("f1ecdf")
const MUTED := Color("9aa0b3")
const ACCENT := Color("f2c94c")
const DANGER := Color("c9503f")
const GOOD := Color("6fbf5f")
const INFO := Color("5fa8ff")
const MOOD := Color("e8c547")
const STAMINA := Color("4fc1b0")
const ENERGY := Color("e0874a")

const BODY_SIZE := 12
const SMALL_SIZE := 10
const TITLE_SIZE := 15
const TOUCH := 40.0
const INK := Color("0b0d12")
const RIM := Color("5a4b2a")

static var _cached: Theme


static func get_theme() -> Theme:
	if _cached == null:
		_cached = _create()
	return _cached


## Drops the cached theme (tests; lets the engine free it at exit).
static func clear_cache() -> void:
	_cached = null


static func _create() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = BODY_SIZE
	theme.set_color(&"font_color", &"Label", TEXT)
	theme.set_constant(&"line_spacing", &"Label", 1)
	_label_variation(theme, &"TitleLabel", Color("f6e3b4"), TITLE_SIZE)
	theme.set_color(&"font_shadow_color", &"TitleLabel", Color(0, 0, 0, 0.6))
	theme.set_constant(&"shadow_offset_x", &"TitleLabel", 1)
	theme.set_constant(&"shadow_offset_y", &"TitleLabel", 1)
	_label_variation(theme, &"MutedLabel", MUTED, SMALL_SIZE)
	_label_variation(theme, &"AccentLabel", ACCENT, BODY_SIZE)
	_label_variation(theme, &"WarningLabel", DANGER.lightened(0.15), SMALL_SIZE)
	_outlined_label(theme, &"HudLabel", Color("ffffff"), 13, 4)
	_outlined_label(theme, &"HudSmallLabel", Color("f1e8da"), 11, 3)
	_outlined_label(theme, &"HudAccentLabel", Color("e8d36a"), 12, 3)

	_button(theme, &"Button", Color("3a4258"), TEXT)
	_button(theme, &"PrimaryButton", Color("2f8f4e"), Color("f4fff0"))
	_button(theme, &"DangerButton", Color("b8372b"), Color("ffe8e2"))
	_button(theme, &"SelectedButton", Color("3b6fb5"), Color("eef5ff"))
	_button(theme, &"RowButton", CARD, TEXT, 4)
	_flat_button(theme, &"NavButton", Color(0, 0, 0, 0), Color("b9bfd0"), 0)
	theme.set_color(&"font_pressed_color", &"NavButton", ACCENT)
	theme.set_color(&"font_hover_color", &"NavButton", Color("f6e3b4"))
	# Selected tab: lighter plate with a gold bar on top.
	var nav_selected := _box(Color("2d3650"), ACCENT, 0, 0, 8)
	nav_selected.border_width_top = 3
	_flat_button(theme, &"NavSelected", Color("2d3650"), Color("fff3c4"), 0, nav_selected)
	_flat_button(theme, &"AlertNavButton", Color(0.75, 0.55, 0.15, 0.35), Color("ffe9a8"), 0)
	var round_box := _box(Color(0.07, 0.08, 0.12, 0.88), Color(BORDER, 0.85), 20, 2, 8)
	round_box.shadow_color = Color(0, 0, 0, 0.35)
	round_box.shadow_size = 2
	_flat_button(theme, &"RoundButton", Color(0.07, 0.08, 0.12, 0.88), Color("f6e3b4"), 20, round_box)
	_flat_button(theme, &"HudButton", Color(0, 0, 0, 0), Color("f1ecdf"), 6)
	for name: StringName in [&"HudButton", &"RoundButton"]:
		theme.set_color(&"font_outline_color", name, INK)
		theme.set_constant(&"outline_size", name, 3)

	theme.set_stylebox(&"panel", &"PanelContainer", _box(Color(0, 0, 0, 0)))
	var sheet := _box(PANEL, BORDER, 0, 0, 10)
	sheet.corner_radius_top_left = 14
	sheet.corner_radius_top_right = 14
	sheet.border_width_top = 2
	sheet.border_width_left = 1
	sheet.border_width_right = 1
	sheet.shadow_color = Color(0, 0, 0, 0.45)
	sheet.shadow_size = 6
	_panel_variation(theme, &"Sheet", sheet)
	var card := _box(CARD, Color("3a4258"), 6, 1, 6)
	card.border_width_bottom = 2
	card.border_color = Color("141824")
	_panel_variation(theme, &"Card", card)
	_panel_variation(theme, &"TopBar", _box(Color(BACKGROUND, 0.92), BORDER, 0, 1, 6))
	var hud := _box(Color(0.03, 0.04, 0.07, 0.6), Color(BORDER, 0.55), 0, 0, 6)
	hud.border_width_bottom = 1
	_panel_variation(theme, &"Hud", hud)
	var hunter_card := _box(Color("1b2030"), RIM, 6, 1, 4)
	hunter_card.border_width_bottom = 2
	_panel_variation(theme, &"HunterCard", hunter_card)
	var chip := _box(Color(0.04, 0.05, 0.08, 0.65), Color(BORDER, 0.35), 9, 1, 1)
	chip.content_margin_left = 3.0
	chip.content_margin_right = 6.0
	_panel_variation(theme, &"Chip", chip)
	_panel_variation(theme, &"HudBubble", _box(Color(0.06, 0.07, 0.11, 0.78), Color(BORDER, 0.6), 8, 1, 5))
	var nav := _box(Color("0d0f16"), BORDER, 0, 0, 2)
	nav.border_width_top = 2
	nav.shadow_color = Color(0, 0, 0, 0.4)
	nav.shadow_size = 4
	_panel_variation(theme, &"NavBar", nav)
	var toast := _box(Color(BACKGROUND, 0.95), Color(ACCENT, 0.6), 8, 1, 8)
	toast.border_width_left = 4
	toast.border_color = ACCENT
	toast.shadow_color = Color(0, 0, 0, 0.4)
	toast.shadow_size = 3
	_panel_variation(theme, &"Toast", toast)

	var separator := StyleBoxLine.new()
	separator.color = Color(BORDER, 0.45)
	separator.thickness = 1
	theme.set_stylebox(&"separator", &"HSeparator", separator)
	theme.set_stylebox(&"panel", &"TooltipPanel", _box(Color(BACKGROUND, 0.96), BORDER, 4, 1, 6))
	theme.set_color(&"font_color", &"TooltipLabel", TEXT)
	_scrollbar(theme)

	_bar(theme, &"HpBar", GOOD)
	_bar(theme, &"XpBar", INFO)
	_bar(theme, &"MoodBar", MOOD)
	_bar(theme, &"StaminaBar", STAMINA)
	_bar(theme, &"EnergyBar", ENERGY)
	_bar(theme, &"TimerBar", ACCENT)
	theme.set_stylebox(&"panel", &"ScrollContainer", StyleBoxEmpty.new())
	return theme


static func _box(color: Color, border: Color = Color(0, 0, 0, 0), radius: int = 6, border_width: int = 0, margin: int = 8) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(margin)
	return box


static func _label_variation(theme: Theme, name: StringName, color: Color, size: int) -> void:
	theme.set_type_variation(name, &"Label")
	theme.set_color(&"font_color", name, color)
	theme.set_font_size(&"font_size", name, size)


static func _outlined_label(theme: Theme, name: StringName, color: Color, size: int, outline: int) -> void:
	_label_variation(theme, name, color, size)
	theme.set_color(&"font_outline_color", name, INK)
	theme.set_constant(&"outline_size", name, outline)


static func _panel_variation(theme: Theme, name: StringName, box: StyleBox) -> void:
	theme.set_type_variation(name, &"PanelContainer")
	theme.set_stylebox(&"panel", name, box)


## Chunky button: a darker bottom edge (3 px) that moves to the top when pressed, so the face
## and its text sink by 2 px.
static func _button(theme: Theme, name: StringName, color: Color, text: Color, radius: int = 6) -> void:
	if name != &"Button":
		theme.set_type_variation(name, &"Button")
	var edge := color.darkened(0.45)
	var normal := _chunky(color, edge, radius, false)
	var hover := _chunky(color.lightened(0.1), edge, radius, false)
	var pressed := _chunky(color.darkened(0.12), edge, radius, true)
	var disabled := _chunky(Color(color.darkened(0.45), 0.7), Color(edge, 0.6), radius, false)
	_button_boxes(theme, name, normal, hover, pressed, disabled, text)


static func _chunky(color: Color, edge: Color, radius: int, pressed: bool) -> StyleBoxFlat:
	var box := _box(color, edge, radius, 1, 8)
	box.border_width_bottom = 1 if pressed else 3
	box.border_width_top = 3 if pressed else 1
	box.content_margin_top = 9.0 if pressed else 7.0
	box.content_margin_bottom = 7.0 if pressed else 9.0
	return box


## Flat button (navigation, HUD, round buttons): no edge; `normal_box` overrides the normal style.
static func _flat_button(theme: Theme, name: StringName, color: Color, text: Color, radius: int = 6,
		normal_box: StyleBoxFlat = null) -> void:
	theme.set_type_variation(name, &"Button")
	var shown := color.a > 0.0
	var normal := normal_box if normal_box != null else _box(color, Color(0, 0, 0, 0), radius, 0, 8)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = color.lightened(0.08) if shown else Color(1, 1, 1, 0.06)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = color.darkened(0.2) if shown else Color(0, 0, 0, 0.2)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(color.darkened(0.4), 0.6 if shown else 0.0)
	_button_boxes(theme, name, normal, hover, pressed, disabled, text)


static func _button_boxes(theme: Theme, name: StringName, normal: StyleBox, hover: StyleBox, pressed: StyleBox,
		disabled: StyleBox, text: Color) -> void:
	theme.set_stylebox(&"normal", name, normal)
	theme.set_stylebox(&"hover", name, hover)
	theme.set_stylebox(&"pressed", name, pressed)
	theme.set_stylebox(&"hover_pressed", name, pressed)
	theme.set_stylebox(&"disabled", name, disabled)
	theme.set_stylebox(&"focus", name, StyleBoxEmpty.new())
	theme.set_color(&"font_color", name, text)
	theme.set_color(&"font_hover_color", name, text)
	theme.set_color(&"font_pressed_color", name, text)
	theme.set_color(&"font_hover_pressed_color", name, text)
	theme.set_color(&"font_disabled_color", name, Color(MUTED, 0.6))
	theme.set_constant(&"h_separation", name, 6)


## Thin rounded scroll bars in the panel colours.
static func _scrollbar(theme: Theme) -> void:
	var track := _box(Color(0, 0, 0, 0.18), Color(0, 0, 0, 0), 3, 0, 0)
	track.content_margin_left = 3.0
	track.content_margin_right = 3.0
	var grabber := _box(Color(BORDER, 0.55), Color(0, 0, 0, 0), 3, 0, 0)
	var grabber_lit := _box(Color(BORDER, 0.8), Color(0, 0, 0, 0), 3, 0, 0)
	for bar: StringName in [&"VScrollBar", &"HScrollBar"]:
		theme.set_stylebox(&"scroll", bar, track)
		theme.set_stylebox(&"grabber", bar, grabber)
		theme.set_stylebox(&"grabber_highlight", bar, grabber_lit)
		theme.set_stylebox(&"grabber_pressed", bar, grabber_lit)


## Rounded bar: dark inset track, fill with a darker lower edge.
static func _bar(theme: Theme, name: StringName, fill: Color) -> void:
	theme.set_type_variation(name, &"ProgressBar")
	var background := _box(INK, Color(0, 0, 0, 0.7), 4, 1, 0)
	var front := _box(fill, fill.darkened(0.3), 4, 0, 0)
	front.border_width_bottom = 2
	theme.set_stylebox(&"background", name, background)
	theme.set_stylebox(&"fill", name, front)
	theme.set_font_size(&"font_size", name, SMALL_SIZE)
	theme.set_color(&"font_color", name, TEXT)
	theme.set_color(&"font_outline_color", name, INK)
	theme.set_constant(&"outline_size", name, 3)
