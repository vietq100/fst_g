class_name HunterCard
extends PanelContainer
## A Hunter's card in the Hunters tab (D62), like the reference game's cards: background and rim
## tinted by the Hunter's tier, the talent star, name and tier code (C, U, R, SR…) on top; level,
## class (in its class colour) and the reincarnation count in Roman numerals under it; the whole
## figure with gear and pet over a glow, with what the Hunter is doing / where it stands on a
## translucent band across its feet; a large Info button and a green Locate button.

signal info_pressed
signal locate_pressed

const CLASS_COLORS := {
	&"warrior": Color("f0904a"), &"berserker": Color("f0904a"),
	&"ranger": Color("8fd36b"),
	&"rogue": Color("c79bff"),
	&"guardian": Color("f2c94c"), &"paladin": Color("f2c94c"),
	&"sorcerer": Color("5fa8ff"), &"mage": Color("5fa8ff"),
}
const DEFAULT_CLASS_COLOR := Color("6fd6d0")
const ROMAN := [[1000, "M"], [900, "CM"], [500, "D"], [400, "CD"], [100, "C"], [90, "XC"], [50, "L"], [40, "XL"],
	[10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]
const INFO_BUTTON := Color("3b3f2a")
const LOCATE_BUTTON := Color("4f7a2a")

var runtime: HunterRuntime


func setup(hunter: HunterRuntime, status_text: String) -> HunterCard:
	runtime = hunter
	var gm := GameManager
	var definition := gm.hunters.get_definition(hunter)
	var tier_color := Tier.color(hunter.tier)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_stylebox_override(&"panel", _card_style(tier_color))
	# Top: talent star, name, tier code.
	var star := PixelIcons.rect(&"star", 1)
	star.modulate = Color("f2c94c") if gm.talents.get_talent(hunter) != null else Color(1, 1, 1, 0.3)
	star.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var name_label := UIKit.label(hunter.display_name, &"HudSmallLabel", false)
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_size_override(&"font_size", 12)
	var code := UIKit.label(Tier.code(hunter.tier), &"HudSmallLabel", false)
	code.add_theme_color_override(&"font_color", tier_color)
	code.add_theme_font_size_override(&"font_size", 13)
	code.add_theme_constant_override(&"outline_size", 4)
	var top := UIKit.hbox([star, name_label, code], 3)
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	# Level, class in its colour, reincarnations in Roman numerals.
	# The level reads in the colour of the Hunter's grade against its level's average (D80).
	var grade := gm.grades.hunter_grade(hunter)
	var level := _small("Lv.%d" % hunter.level, StatGradeService.color(grade))
	level.tooltip_text = Loc.t("ui.common.grade", {"grade": StatGradeService.name_of(grade)})
	level.mouse_filter = Control.MOUSE_FILTER_PASS
	# The class takes the room left between the level and the numeral; long names shrink first.
	var class_name_text := definition.display_name if definition != null else ""
	var class_label := _small(class_name_text, class_color(definition))
	class_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	class_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	class_label.clip_text = true
	class_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var info_line := UIKit.hbox([level, class_label], 2)
	var numeral: Label = null
	if hunter.reincarnations > 0:
		numeral = _small(roman(hunter.reincarnations), Color("f4f1ea"))
		info_line.add_child(numeral)
	# Once the card has its real width, shrink the class name until the line fits.
	info_line.resized.connect(func() -> void: _fit_class(info_line, level, class_label, numeral))
	# Figure with the status band over its feet.
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(0, 92)
	stage.clip_contents = true
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var figure := HunterFigure.new().setup(hunter, gm.equipment)
	figure.accent = tier_color
	figure.set_anchors_preset(Control.PRESET_FULL_RECT)
	figure.offset_bottom = -4
	stage.add_child(figure)
	var band := PanelContainer.new()
	var band_style := StyleBoxFlat.new()
	band_style.bg_color = Color(0.02, 0.03, 0.06, 0.55)
	band_style.set_content_margin_all(1)
	band_style.content_margin_left = 4
	band_style.content_margin_right = 4
	band.add_theme_stylebox_override(&"panel", band_style)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	band.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var status := UIKit.label(status_text, &"HudLabel", false)
	status.add_theme_font_size_override(&"font_size", 11)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.clip_text = true
	status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	band.add_child(status)
	stage.add_child(band)
	# Buttons: Info and Locate.
	var info := UIKit.button(Loc.t("ui.common.info"), func() -> void: info_pressed.emit(), &"")
	info.custom_minimum_size = Vector2(0, 32)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_font_size_override(&"font_size", 13)
	_style_button(info, INFO_BUTTON)
	var locate := UIKit.button("", func() -> void: locate_pressed.emit(), &"")
	locate.icon = PixelIcons.texture(&"locate", 2)
	locate.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	locate.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	locate.custom_minimum_size = Vector2(32, 32)
	locate.tooltip_text = Loc.t("ui.hunters.locate")
	_style_button(locate, LOCATE_BUTTON)
	var buttons := UIKit.hbox([info, locate], 3)
	add_child(UIKit.vbox([top, info_line, stage, buttons], 2))
	return self


static func class_color(definition: HunterDefinition) -> Color:
	return CLASS_COLORS.get(ChibiBody.outfit_for(definition), DEFAULT_CLASS_COLOR)


## 4 → "IV" (reincarnation count).
static func roman(value: int) -> String:
	var result := ""
	var left := maxi(value, 0)
	for pair: Array in ROMAN:
		while left >= int(pair[0]):
			result += pair[1]
			left -= int(pair[0])
	return result


func _fit_class(line: HBoxContainer, level: Label, class_label: Label, numeral: Label) -> void:
	var gap := line.get_theme_constant(&"separation")
	var room := line.size.x - level.get_minimum_size().x - gap
	if numeral != null:
		room -= numeral.get_minimum_size().x + gap
	var font := class_label.get_theme_font(&"font")
	for font_size in [9, 8, 7]:
		if font.get_string_size(class_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= room or font_size == 7:
			if class_label.get_theme_font_size(&"font_size") != font_size:
				class_label.add_theme_font_size_override(&"font_size", font_size)
			return


## Small text without the HUD outline (it would steal width from the class name).
func _small(text: String, color: Color) -> Label:
	var label := UIKit.label(text, &"MutedLabel", false)
	label.add_theme_font_size_override(&"font_size", GameTheme.SMALL_SIZE)
	label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	label.add_theme_color_override(&"font_color", color)
	return label


## Dark card washed with the tier colour, rim in the tier colour, darker bottom edge.
static func _card_style(tier_color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("1b2030").lerp(tier_color, 0.22)
	box.border_color = tier_color.darkened(0.25)
	box.set_border_width_all(2)
	box.border_width_bottom = 3
	box.set_corner_radius_all(6)
	box.set_content_margin_all(3)
	box.shadow_color = Color(0, 0, 0, 0.35)
	box.shadow_size = 2
	return box


static func _style_button(button: Button, color: Color) -> void:
	for state: Array in [[&"normal", color], [&"hover", color.lightened(0.12)], [&"pressed", color.darkened(0.2)],
			[&"disabled", color.darkened(0.4)], [&"focus", color]]:
		var box := StyleBoxFlat.new()
		box.bg_color = state[1]
		box.border_color = color.darkened(0.5)
		box.set_border_width_all(1)
		box.border_width_bottom = 3 if state[0] != &"pressed" else 1
		box.set_corner_radius_all(5)
		box.set_content_margin_all(2)
		if state[0] == &"focus":
			box.draw_center = false
		button.add_theme_stylebox_override(state[0], box)
	button.add_theme_color_override(&"font_color", Color("f4f1ea"))
	button.add_theme_color_override(&"font_outline_color", GameTheme.INK)
	button.add_theme_constant_override(&"outline_size", 3)
