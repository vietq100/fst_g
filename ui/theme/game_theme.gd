class_name GameTheme
extends RefCounted
## The game's UI theme (UI_DESIGN.md: fantasy management, clean, readable, slightly dark, warm
## accents; DECISIONS.md D23: fonts ≥ 10 px, body 12, touch targets ≥ 40 px).
## Built in code so colours live in one place. Type variations:
## Button: PrimaryButton, DangerButton, SelectedButton, NavButton, RowButton
## PanelContainer: Sheet, Card, TopBar, Toast · ProgressBar: HpBar, XpBar, MoodBar, TimerBar
## Label: TitleLabel, MutedLabel, AccentLabel, WarningLabel

const BACKGROUND := Color("1d1814")
const PANEL := Color("3a2b1f")
const CARD := Color("4a382a")
const BORDER := Color("b08d57")
const TEXT := Color("f1e8da")
const MUTED := Color("b3a593")
const ACCENT := Color("e2b55a")
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
	_label_variation(theme, &"TitleLabel", TEXT, TITLE_SIZE)
	_label_variation(theme, &"MutedLabel", MUTED, SMALL_SIZE)
	_label_variation(theme, &"AccentLabel", ACCENT, BODY_SIZE)
	_label_variation(theme, &"WarningLabel", DANGER, SMALL_SIZE)
	_label_variation(theme, &"HudLabel", Color("ffffff"), 13)
	theme.set_color(&"font_outline_color", &"HudLabel", Color("14100d"))
	theme.set_constant(&"outline_size", &"HudLabel", 4)
	_label_variation(theme, &"HudSmallLabel", Color("f1e8da"), 11)
	theme.set_color(&"font_outline_color", &"HudSmallLabel", Color("14100d"))
	theme.set_constant(&"outline_size", &"HudSmallLabel", 3)
	_label_variation(theme, &"HudAccentLabel", Color("e8d36a"), 12)
	theme.set_color(&"font_outline_color", &"HudAccentLabel", Color("14100d"))
	theme.set_constant(&"outline_size", &"HudAccentLabel", 3)

	_button(theme, &"Button", Color("4a3c30"), TEXT)
	_button(theme, &"PrimaryButton", Color("8a6a2e"), Color("fff6e0"))
	_button(theme, &"DangerButton", Color("7a2f26"), Color("ffe8e2"))
	_button(theme, &"SelectedButton", Color("5d7a3e"), Color("f4ffe8"))
	_button(theme, &"NavButton", Color(0, 0, 0, 0), Color("e6dcc8"), 0)
	_button(theme, &"NavSelected", Color("cfc6b0"), Color("1d1814"), 0)
	_button(theme, &"RoundButton", Color(0.1, 0.08, 0.07, 0.8), Color("e6dcc8"), 20)
	_button(theme, &"HudButton", Color(0, 0, 0, 0), Color("e6dcc8"), 6)
	theme.set_color(&"font_pressed_color", &"NavButton", ACCENT)
	_button(theme, &"AlertNavButton", Color(0.75, 0.55, 0.15, 0.35), Color("ffe9a8"), 0)
	_button(theme, &"RowButton", CARD, TEXT, 4)

	theme.set_stylebox(&"panel", &"PanelContainer", _box(Color(0, 0, 0, 0)))
	_panel_variation(theme, &"Sheet", _box(PANEL, BORDER, 10, 2, 10))
	_panel_variation(theme, &"Card", _box(CARD, Color(0, 0, 0, 0), 6, 0, 6))
	_panel_variation(theme, &"TopBar", _box(Color(BACKGROUND, 0.92), BORDER, 0, 1, 6))
	_panel_variation(theme, &"Hud", _box(Color(0.05, 0.04, 0.05, 0.55), Color(0, 0, 0, 0), 0, 0, 6))
	_panel_variation(theme, &"HunterCard", _box(Color("2b2330"), Color("6b5338"), 4, 1, 4))
	_panel_variation(theme, &"HudBubble", _box(Color(0.1, 0.08, 0.07, 0.7), Color("6b5338"), 6, 1, 5))
	_panel_variation(theme, &"NavBar", _box(Color("14100d"), Color("6b5338"), 0, 2, 2))
	_panel_variation(theme, &"Toast", _box(Color(BACKGROUND, 0.94), ACCENT, 8, 1, 8))

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


static func _panel_variation(theme: Theme, name: StringName, box: StyleBox) -> void:
	theme.set_type_variation(name, &"PanelContainer")
	theme.set_stylebox(&"panel", name, box)


static func _button(theme: Theme, name: StringName, color: Color, text: Color, radius: int = 6) -> void:
	if name != &"Button":
		theme.set_type_variation(name, &"Button")
	var normal := _box(color, Color(0, 0, 0, 0), radius, 0, 8)
	var hover := _box(color.lightened(0.08), Color(0, 0, 0, 0), radius, 0, 8)
	var pressed := _box(color.darkened(0.2), ACCENT if color.a > 0.0 else Color(0, 0, 0, 0), radius, 1 if color.a > 0.0 else 0, 8)
	var disabled := _box(Color(color.darkened(0.4), 0.6 if color.a > 0.0 else 0.0), Color(0, 0, 0, 0), radius, 0, 8)
	theme.set_stylebox(&"normal", name, normal)
	theme.set_stylebox(&"hover", name, hover)
	theme.set_stylebox(&"pressed", name, pressed)
	theme.set_stylebox(&"disabled", name, disabled)
	theme.set_stylebox(&"focus", name, StyleBoxEmpty.new())
	theme.set_color(&"font_color", name, text)
	theme.set_color(&"font_hover_color", name, text)
	theme.set_color(&"font_pressed_color", name, text)
	theme.set_color(&"font_disabled_color", name, Color(MUTED, 0.6))
	theme.set_constant(&"h_separation", name, 6)


static func _bar(theme: Theme, name: StringName, fill: Color) -> void:
	theme.set_type_variation(name, &"ProgressBar")
	theme.set_stylebox(&"background", name, _box(Color("14100d"), Color(0, 0, 0, 0), 3, 0, 0))
	theme.set_stylebox(&"fill", name, _box(fill, Color(0, 0, 0, 0), 3, 0, 0))
	theme.set_font_size(&"font_size", name, SMALL_SIZE)
	theme.set_color(&"font_color", name, TEXT)
	theme.set_color(&"font_outline_color", name, Color("14100d"))
	theme.set_constant(&"outline_size", name, 3)
