class_name ItemInfoModal
extends Control
## Item details (D64, look from the reference panel, D65), opened by tapping any item icon. It
## dims the screen and does not close the sheet or dialog underneath. Dark brown frame with a
## thin gold rim and corner ornaments; a lit title banner with the item's name; a gold-framed
## icon with its enhancement in Roman numerals and one star per tier step; kind, quality and
## enhancement as label / value lines and the main bonus in large type; a dark inner box with
## every bonus as a blue bullet, durability for weapons and who wears it as gold lines, the
## item's flavour text when it has one; small Repair / Change buttons; an orange Close button.
## Tapping outside the frame or Close dismisses it.

signal toast_requested(text: String, is_error: bool)

const WIDTH := 330.0
const FRAME_BG := Color("1d1713")
const FRAME_RIM := Color("8c7552")
const FRAME_RIM_DARK := Color("3a2f24")
const BOX_BG := Color("14110e")
const BOX_RIM := Color("3a3026")
const GOLD := Color("e8c35a")
const CREAM := Color("f4ead2")
const LABEL := Color("b9b0dc")
const STAT := Color("6fa8ff")
const NOTE := Color("c9bfa8")
const CLOSE := Color("c8562a")
const BUTTON := Color("2b2620")

var item: ItemDefinition
var instance_id: StringName
var _body: VBoxContainer


func setup(item_definition: ItemDefinition, instance: StringName = &"") -> ItemInfoModal:
	item = item_definition
	instance_id = instance
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
	var frame := Frame.new()
	frame.custom_minimum_size.x = WIDTH
	frame.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(frame)
	_body = UIKit.vbox([], 8)
	frame.add_child(_body)
	GameManager.inventory.inventory_changed.connect(_rebuild)
	GameManager.equipment.equipment_changed.connect(_on_equipment_changed)
	_rebuild()


func _exit_tree() -> void:
	if GameManager.inventory.inventory_changed.is_connected(_rebuild):
		GameManager.inventory.inventory_changed.disconnect(_rebuild)
	if GameManager.equipment.equipment_changed.is_connected(_on_equipment_changed):
		GameManager.equipment.equipment_changed.disconnect(_on_equipment_changed)


func _on_equipment_changed(_hunter: HunterRuntime) -> void:
	_rebuild()


func _rebuild() -> void:
	if _body == null or item == null:
		return
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	var gm := GameManager
	var equipment := gm.equipment
	# The item is gone (sold): nothing left to show.
	if instance_id != &"" and gm.inventory.get_instance_item(instance_id) == &"":
		queue_free()
		return
	if instance_id == &"" and item.stackable and gm.inventory.count(item.id) <= 0:
		queue_free()
		return
	var enhance := gm.inventory.get_enhance(instance_id) if instance_id != &"" else 0
	var broken := instance_id != &"" and equipment.is_broken(instance_id)
	# Title banner.
	var banner := Banner.new()
	banner.text = item.display_name
	_body.add_child(banner)
	# Framed icon and the headline facts.
	var icon_frame := IconFrame.new()
	icon_frame.setup(item, instance_id, enhance)
	var facts := UIKit.vbox([], 3)
	facts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	facts.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	facts.add_child(_fact(Loc.t("ui.item.kind"), _kind_name(), CREAM, 16))
	facts.add_child(_fact(Loc.t("ui.item.quality"), Tier.name_of(item.rarity), Tier.color(item.rarity), 14))
	if enhance > 0:
		facts.add_child(_fact(Loc.t("ui.item.enhance"), "+%d" % enhance, CREAM, 14))
	if not item.modifiers.is_empty():
		facts.add_child(_text(_modifier_text(item.modifiers[0]), CREAM if not broken else NOTE, 16, true))
	_body.add_child(UIKit.hbox([icon_frame, facts], 12))
	# Inner box: bonuses (blue), state lines (gold), flavour text.
	var box := UIKit.vbox([], 4)
	for modifier in item.modifiers:
		box.add_child(_bullet(_modifier_text(modifier), STAT if not broken else NOTE, Color("8a8ea0")))
	if item.modifiers.is_empty():
		box.add_child(_bullet(_plain_info(), STAT, Color("8a8ea0")))
	var full := EquipmentService.max_durability(item)
	if full > 0:
		var current := equipment.get_durability(instance_id) if instance_id != &"" else full
		box.add_child(_bullet(Loc.t("ui.item.durability", {"current": current, "max": full}), GOLD, GOLD))
		var bar := UIKit.bar(current, full, &"HpBar" if current > full * EquipmentService.REPAIR_THRESHOLD else &"TimerBar", "")
		bar.custom_minimum_size.y = 6
		box.add_child(bar)
		if broken:
			box.add_child(_bullet(Loc.t("ui.item.broken"), GameTheme.DANGER, GameTheme.DANGER))
	var owner := gm.hunters.get_hunter(gm.inventory.get_owner_id(instance_id)) if instance_id != &"" else null
	if owner != null:
		box.add_child(_bullet(Loc.t("ui.item.worn_by", {"name": owner.display_name}), GOLD, GOLD))
	if item.sell_price > 0:
		box.add_child(_bullet(Loc.t("ui.item.value", {"gold": item.sell_price}), NOTE, Color("8a8ea0")))
	var flavour_key := "item.%s.desc" % item.id
	if Loc.has_key(flavour_key):
		var flavour := _text(Loc.t(flavour_key), NOTE, 13, false)
		flavour.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(flavour)
	elif full > 0 and not broken:
		var note := _text(Loc.t("ui.item.durability_note"), NOTE, 12, false)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(note)
	# Small action buttons at the bottom of the box (like the reference's option buttons).
	var actions := UIKit.hbox([], 6)
	if instance_id != &"" and full > 0 and gm.inventory.get_wear(instance_id) > 0:
		var repair := UIKit.button(Loc.t("ui.item.repair", {"gold": equipment.get_repair_cost(instance_id)}), func() -> void:
			var reason := equipment.repair(instance_id)
			toast_requested.emit(reason if not reason.is_empty() else Loc.t("ui.item.repaired", {"item": item.display_name}), not reason.is_empty())
			_rebuild(), &"", equipment.can_repair(instance_id))
		_style_button(repair, Color("2f5a2a"), GOLD.darkened(0.3))
		actions.add_child(repair)
	if owner != null:
		var slot: StringName = EquipmentService.SLOT_NAMES.get(item.equipment_slot, &"")
		var change := UIKit.button(Loc.t("ui.item.change"), func() -> void:
			get_tree().call_group(&"ui_root", &"open_equip_picker", owner, slot)
			queue_free())
		_style_button(change, BUTTON, FRAME_RIM.darkened(0.2))
		actions.add_child(change)
		var remove := UIKit.button(Loc.t("ui.common.remove"), func() -> void:
			var reason := equipment.unequip(owner, slot)
			if reason.is_empty():
				queue_free()
			else:
				toast_requested.emit(reason, true))
		_style_button(remove, BUTTON, FRAME_RIM.darkened(0.2))
		actions.add_child(remove)
	# Selling: stored stackables (one or all) and stored equipment; worn gear cannot be sold.
	if item.sell_price > 0 and instance_id == &"" and item.stackable:
		var owned: int = gm.inventory.count(item.id)
		var sell_one := UIKit.button(Loc.t("ui.inventory.sell_one", {"gold": item.sell_price}), func() -> void:
			gm.inventory.sell_item(item.id, 1), &"")
		_style_button(sell_one, Color("7a2a22"), Color("c8562a"))
		actions.add_child(sell_one)
		if owned > 1:
			var sell_all := UIKit.button(Loc.t("ui.inventory.sell_all", {"count": owned, "gold": item.sell_price * owned}), func() -> void:
				gm.inventory.sell_item(item.id, owned), &"")
			_style_button(sell_all, Color("7a2a22"), Color("c8562a"))
			actions.add_child(sell_all)
	elif item.sell_price > 0 and instance_id != &"" and owner == null:
		var sell := UIKit.button(Loc.t("ui.inventory.sell", {"gold": item.sell_price}), func() -> void:
			gm.inventory.sell_instance(instance_id), &"")
		_style_button(sell, Color("7a2a22"), Color("c8562a"))
		actions.add_child(sell)
	if actions.get_child_count() > 0:
		box.add_child(actions)
	var inner := PanelContainer.new()
	var inner_style := StyleBoxFlat.new()
	inner_style.bg_color = BOX_BG
	inner_style.border_color = BOX_RIM
	inner_style.set_border_width_all(1)
	inner_style.set_corner_radius_all(2)
	inner_style.set_content_margin_all(10)
	inner.add_theme_stylebox_override(&"panel", inner_style)
	inner.add_child(box)
	_body.add_child(inner)
	# Close: orange, centred, half width.
	var close := UIKit.button(Loc.t("ui.common.close"), queue_free, &"")
	close.custom_minimum_size = Vector2(150, 46)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.add_theme_font_size_override(&"font_size", 18)
	_style_button(close, CLOSE, CLOSE.darkened(0.45))
	_body.add_child(close)


func _kind_name() -> String:
	var slot: StringName = EquipmentService.SLOT_NAMES.get(item.equipment_slot, &"")
	if slot != &"":
		return EquipmentService.slot_label(slot)
	return Loc.t("ui.item.kind.consumable" if item.item_type == ItemDefinition.ItemType.CONSUMABLE else "ui.item.kind.material")


func _plain_info() -> String:
	if item.energy > 0.0:
		return Loc.t("ui.item.food", {"energy": roundi(item.energy)})
	if item.heal_ratio > 0.0:
		return Loc.t("ui.item.medicine", {"percent": roundi(item.heal_ratio * 100.0)})
	return Loc.t("ui.item.material_note")


static func _modifier_text(modifier: StatModifier) -> String:
	var name := Loc.t("stat.%s" % modifier.stat)
	# Percent modifiers, crit chance and small ratios (crit damage +0.2) read as percentages.
	if modifier.stat == HunterService.CRITICAL_CHANCE or modifier.type == StatModifier.Type.PERCENT or absf(modifier.value) < 1.0:
		return "%s %+d%%" % [name, roundi(modifier.value * 100.0)]
	return "%s %+d" % [name, roundi(modifier.value)]


## "Label  Value" on one line, the label in lavender, the value in its own colour.
func _fact(label: String, value: String, color: Color, font_size: int) -> Control:
	var key := _text(label, LABEL, font_size - 1, false)
	var shown := _text(value, color, font_size, false)
	shown.clip_text = true
	shown.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	shown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return UIKit.hbox([key, shown], 8)


func _text(text: String, color: Color, font_size: int, big: bool) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_outline_color", Color("0b0805"))
	label.add_theme_constant_override(&"outline_size", 4 if big else 2)
	return label


func _bullet(text: String, color: Color, dot_color: Color) -> Control:
	var dot := _text("◆", dot_color, 11, false)
	dot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var line := _text(text, color, 14, false)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return UIKit.hbox([dot, line], 6)


static func _style_button(button: Button, color: Color, rim: Color) -> void:
	if button.size_flags_horizontal != Control.SIZE_SHRINK_CENTER:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for state: Array in [[&"normal", color], [&"hover", color.lightened(0.1)], [&"pressed", color.darkened(0.2)],
			[&"disabled", color.darkened(0.45)], [&"focus", color]]:
		var box := StyleBoxFlat.new()
		box.bg_color = state[1]
		box.border_color = rim
		box.set_border_width_all(1)
		box.border_width_bottom = 3 if state[0] != &"pressed" else 1
		box.set_corner_radius_all(6)
		box.set_content_margin_all(4)
		if state[0] == &"focus":
			box.draw_center = false
		button.add_theme_stylebox_override(state[0], box)
	button.add_theme_color_override(&"font_color", CREAM)
	button.add_theme_color_override(&"font_outline_color", Color("0b0805"))
	button.add_theme_constant_override(&"outline_size", 3)


## Dark brown panel with a double rim (dark outer, thin gold inner) and gold corner ornaments.
class Frame extends PanelContainer:
	func _init() -> void:
		var box := StyleBoxFlat.new()
		box.bg_color = ItemInfoModal.FRAME_BG
		box.border_color = ItemInfoModal.FRAME_RIM_DARK
		box.set_border_width_all(3)
		box.set_corner_radius_all(3)
		box.content_margin_left = 14
		box.content_margin_right = 14
		box.content_margin_top = 12
		box.content_margin_bottom = 14
		box.shadow_color = Color(0, 0, 0, 0.5)
		box.shadow_size = 6
		add_theme_stylebox_override(&"panel", box)

	func _draw() -> void:
		var rim := ItemInfoModal.FRAME_RIM
		draw_rect(Rect2(Vector2(4, 4), size - Vector2(8, 8)), rim, false, 1.0)
		for corner: Vector2 in [Vector2(4, 4), Vector2(size.x - 4, 4), Vector2(4, size.y - 4), Vector2(size.x - 4, size.y - 4)]:
			var sx := 1.0 if corner.x < size.x * 0.5 else -1.0
			var sy := 1.0 if corner.y < size.y * 0.5 else -1.0
			draw_line(corner, corner + Vector2(12 * sx, 0), ItemInfoModal.GOLD, 2.0)
			draw_line(corner, corner + Vector2(0, 12 * sy), ItemInfoModal.GOLD, 2.0)
			draw_rect(Rect2(corner + Vector2(3 * sx - 1.5, 3 * sy - 1.5), Vector2(3, 3)), ItemInfoModal.GOLD)


## The title over a dark band lit from the middle, gold line underneath.
class Banner extends Control:
	var text := ""

	func _init() -> void:
		custom_minimum_size = Vector2(0, 40)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("2a221b"))
		for i in 6:
			var t := float(i) / 6.0
			draw_rect(Rect2(Vector2(size.x * (0.1 + t * 0.4), 2), Vector2(size.x * (0.8 - t * 0.8), size.y - 4)), Color(1.0, 0.92, 0.75, 0.035))
		draw_line(Vector2(0, size.y - 1), Vector2(size.x, size.y - 1), ItemInfoModal.FRAME_RIM, 1.0)
		var font := ThemeDB.fallback_font
		var font_size := 19
		while font_size > 12 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > size.x - 12:
			font_size -= 1
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var at := Vector2((size.x - width) * 0.5, size.y * 0.5 + font.get_ascent(font_size) * 0.5 - 2.0)
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 5, Color("0b0805"))
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ItemInfoModal.CREAM)


## Gold frame around the item icon, Roman numeral of the enhancement in the top-left corner,
## one star per tier step under the icon.
class IconFrame extends VBoxContainer:
	var _enhance := 0
	var _tier := 0
	var _icon: ItemIcon

	func setup(item: ItemDefinition, instance: StringName, enhance: int) -> void:
		_enhance = enhance
		_tier = int(item.rarity)
		add_theme_constant_override(&"separation", 2)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_icon = ItemIcon.new().setup(item, 76, "", instance)
		_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_icon)
		if enhance > 0:
			# Over the icon, like the reference's "IV" badge.
			var numeral := Label.new()
			numeral.text = HunterCard.roman(enhance)
			numeral.position = Vector2(4, 0)
			numeral.add_theme_font_size_override(&"font_size", 16)
			numeral.add_theme_color_override(&"font_color", ItemInfoModal.GOLD)
			numeral.add_theme_color_override(&"font_outline_color", Color("3a2408"))
			numeral.add_theme_constant_override(&"outline_size", 5)
			numeral.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_icon.add_child(numeral)
		var stars := HBoxContainer.new()
		stars.add_theme_constant_override(&"separation", 0)
		stars.alignment = BoxContainer.ALIGNMENT_CENTER
		for i in mini(_tier + 1, 8):
			var star := PixelIcons.rect(&"star", 1)
			star.modulate = Tier.color(_tier).lerp(Color.WHITE, 0.2)
			stars.add_child(star)
		add_child(stars)

	func _draw() -> void:
		if _icon == null:
			return
		var rect := Rect2(_icon.position, _icon.size).grow(3)
		draw_rect(rect, Color("6b4f1e"), false, 3.0)
		draw_rect(rect.grow(-1), ItemInfoModal.GOLD, false, 1.0)
