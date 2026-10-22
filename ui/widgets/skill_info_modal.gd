class_name SkillInfoModal
extends Control
## Skill details over the current screen (same frame as ItemInfoModal), opened by tapping a
## SkillTile: the big icon, active / passive, level, cooldown and mana, the description and the
## numbers at the current level, plus optional action buttons (upgrade, swap). Tapping outside the
## frame or Close dismisses it; an action closes it too (the dialog below rebuilds itself).
## `options`: level (int, 0 = none), max_level, lines (Array[String]), actions (Array of
## {text, action: Callable, reason: String}).

var skill: GameDefinition
var options: Dictionary = {}


func setup(definition: GameDefinition, extra: Dictionary = {}) -> SkillInfoModal:
	skill = definition
	options = extra
	return self


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			queue_free())
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var frame := ItemInfoModal.Frame.new()
	frame.custom_minimum_size.x = ItemInfoModal.WIDTH
	frame.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(frame)
	var body := UIKit.vbox([], 8)
	frame.add_child(body)
	_build(body)


func _build(body: VBoxContainer) -> void:
	var active := SkillIcons.is_active(skill)
	var banner := ItemInfoModal.Banner.new()
	banner.text = skill.display_name
	body.add_child(banner)
	# Icon in a gold frame beside the headline facts.
	var icon := TextureRect.new()
	icon.texture = SkillIcons.texture(skill, 8)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.custom_minimum_size = Vector2(84, 84)
	var icon_frame := PanelContainer.new()
	var icon_style := StyleBoxFlat.new()
	icon_style.bg_color = ItemInfoModal.BOX_BG
	icon_style.border_color = ItemInfoModal.GOLD
	icon_style.set_border_width_all(2)
	icon_style.set_corner_radius_all(3)
	icon_style.set_content_margin_all(3)
	icon_frame.add_theme_stylebox_override(&"panel", icon_style)
	icon_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_frame.add_child(icon)
	var facts := UIKit.vbox([], 3)
	facts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	facts.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var kind_key := "class_skill.kind.active" if active else "class_skill.kind.passive"
	facts.add_child(_fact(Loc.t("ui.skill.type"), Loc.t(kind_key), Color("e0874a") if active else Color("5fa8ff")))
	var level: int = options.get("level", 0)
	if level > 0:
		facts.add_child(_fact(Loc.t("ui.skill.level"), Loc.t("ui.class_skill.level", {"level": level, "max": options.get("max_level", level)}), ItemInfoModal.CREAM))
	var cooldown: float = skill.get(&"cooldown") if skill.get(&"cooldown") != null else 0.0
	if cooldown > 0.0:
		facts.add_child(_fact(Loc.t("ui.skill.cooldown"), Loc.t("ui.skill.seconds", {"seconds": "%.1f" % cooldown}), ItemInfoModal.CREAM))
	var mana: float = skill.get(&"mana_cost") if skill.get(&"mana_cost") != null else 0.0
	if mana > 0.0:
		facts.add_child(_fact(Loc.t("ui.skill.mana"), str(roundi(mana)), GameTheme.ENERGY))
	body.add_child(UIKit.hbox([icon_frame, facts], 12))
	# Description and numbers.
	var box := UIKit.vbox([], 5)
	var description := _text(skill.description, ItemInfoModal.CREAM, 14)
	box.add_child(description)
	for line: String in options.get("lines", []):
		if line != "":
			box.add_child(_bullet(line))
	var inner := PanelContainer.new()
	var inner_style := StyleBoxFlat.new()
	inner_style.bg_color = ItemInfoModal.BOX_BG
	inner_style.border_color = ItemInfoModal.BOX_RIM
	inner_style.set_border_width_all(1)
	inner_style.set_corner_radius_all(2)
	inner_style.set_content_margin_all(10)
	inner.add_theme_stylebox_override(&"panel", inner_style)
	inner.add_child(box)
	body.add_child(inner)
	var actions := UIKit.hbox([], 6)
	for entry: Dictionary in options.get("actions", []):
		var action: Callable = entry["action"]
		var button := UIKit.button(entry["text"], func() -> void:
			queue_free()
			action.call(), &"", entry.get("reason", ""))
		ItemInfoModal._style_button(button, Color("2f5a2a"), ItemInfoModal.GOLD.darkened(0.3))
		actions.add_child(button)
	if actions.get_child_count() > 0:
		body.add_child(actions)
	var close := UIKit.button(Loc.t("ui.common.close"), queue_free, &"")
	close.custom_minimum_size = Vector2(150, 46)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.add_theme_font_size_override(&"font_size", 18)
	ItemInfoModal._style_button(close, ItemInfoModal.CLOSE, ItemInfoModal.CLOSE.darkened(0.45))
	body.add_child(close)


func _text(text: String, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_outline_color", Color("0b0805"))
	label.add_theme_constant_override(&"outline_size", 2)
	return label


func _fact(label: String, value: String, color: Color) -> Control:
	var key := _text(label, ItemInfoModal.LABEL, 13)
	key.autowrap_mode = TextServer.AUTOWRAP_OFF
	var shown := _text(value, color, 14)
	shown.autowrap_mode = TextServer.AUTOWRAP_OFF
	return UIKit.hbox([key, shown], 8)


func _bullet(text: String) -> Control:
	var dot := _text("◆", ItemInfoModal.STAT, 11)
	dot.autowrap_mode = TextServer.AUTOWRAP_OFF
	dot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var line := _text(text, ItemInfoModal.STAT, 14)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return UIKit.hbox([dot, line], 6)
