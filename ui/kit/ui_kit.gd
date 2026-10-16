class_name UIKit
extends RefCounted
## Small builders for code-made UI so sheets stay short and consistent (GameTheme variations).


static func label(text: String, variation: StringName = &"", wrap: bool = true) -> Label:
	var node := Label.new()
	node.text = text
	node.theme_type_variation = variation
	if wrap:
		node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node


## A button that calls `action`. `reason` non-empty disables it and shows why below/in tooltip.
static func button(text: String, action: Callable, variation: StringName = &"", reason: String = "") -> Button:
	var node := Button.new()
	node.text = text
	node.theme_type_variation = variation
	node.custom_minimum_size = Vector2(GameTheme.TOUCH, GameTheme.TOUCH)
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.disabled = not reason.is_empty()
	node.tooltip_text = reason
	node.pressed.connect(action)
	# Every button clicks (D78).
	node.pressed.connect(func() -> void: Audio.play_ui(&"click"))
	return node


static func hbox(children: Array = [], separation: int = 6) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override(&"separation", separation)
	for child in children:
		box.add_child(child)
	return box


static func vbox(children: Array = [], separation: int = 4) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", separation)
	# Wrapped labels have no minimum width: the column must claim the free space.
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for child in children:
		box.add_child(child)
	return box


static func card(content: Control) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"Card"
	panel.add_child(content)
	return panel


static func bar(value: float, maximum: float, variation: StringName, text: String = "") -> ProgressBar:
	var node := ProgressBar.new()
	node.theme_type_variation = variation
	node.max_value = maxf(maximum, 0.001)
	node.value = clampf(value, 0.0, node.max_value)
	node.show_percentage = false
	node.custom_minimum_size = Vector2(0, 12)
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not text.is_empty():
		var caption := Label.new()
		caption.text = text
		caption.theme_type_variation = &"MutedLabel"
		caption.add_theme_color_override(&"font_color", GameTheme.TEXT)
		caption.add_theme_color_override(&"font_outline_color", GameTheme.INK)
		caption.add_theme_constant_override(&"outline_size", 3)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		caption.set_anchors_preset(Control.PRESET_FULL_RECT)
		node.add_child(caption)
	return node


## Small coloured square used as an item/currency icon placeholder.
static func swatch(color: Color, size: float = 10.0) -> Panel:
	var node := Panel.new()
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(2)
	node.add_theme_stylebox_override(&"panel", box)
	node.custom_minimum_size = Vector2(size, size)
	node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return node


static func separator() -> HSeparator:
	var node := HSeparator.new()
	node.add_theme_constant_override(&"separation", 6)
	return node


static func format_duration(seconds: float) -> String:
	var total := maxi(int(ceilf(seconds)), 0)
	if total >= 3600:
		return Loc.t("ui.kit.duration_hours", {"hours": "%d" % (total / 3600), "minutes": "%02d" % (total % 3600 / 60)})
	return "%d:%02d" % [total / 60, total % 60]


## "+3 ATK +10 HP +5% crit"
static func describe_modifiers(item: ItemDefinition) -> String:
	var parts := PackedStringArray()
	for modifier in item.modifiers:
		# Shared stat names (stat.<id>): "ATK", "HP", "crit"...
		var stat_name := Loc.t("stat.%s" % modifier.stat)
		# Small flat ratios (crit damage +0.2) would round to +0: show them as percentages too.
		if modifier.stat == HunterService.CRITICAL_CHANCE or modifier.type == StatModifier.Type.PERCENT or absf(modifier.value) < 1.0:
			parts.append("%+d%% %s" % [roundi(modifier.value * 100.0), stat_name])
		else:
			parts.append("%+d %s" % [roundi(modifier.value), stat_name])
	return " ".join(parts)


static func rarity_name(item: ItemDefinition) -> String:
	return "%s %s" % [Tier.code(item.rarity), Tier.name_of(item.rarity)]
