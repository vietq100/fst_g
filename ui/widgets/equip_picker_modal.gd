class_name EquipPickerModal
extends Control
## Choosing what a Hunter wears in one slot (D66), in the same frame as the item panel
## (ItemInfoModal): opened by tapping an empty paper-doll slot or "Change" in the item panel.
## Lists the worn item (Remove) and every stored item that fits (Equip); tapping an icon opens
## its details on top. Like the item panel it dims the screen and keeps the dialog underneath.

var runtime: HunterRuntime
var slot: StringName
var _body: VBoxContainer


func setup(hunter: HunterRuntime, slot_id: StringName) -> EquipPickerModal:
	runtime = hunter
	slot = slot_id
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
	if _body == null:
		return
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	var equipment := GameManager.equipment
	var banner := ItemInfoModal.Banner.new()
	banner.text = Loc.t("ui.equip_slot.title", {"slot": EquipmentService.slot_label(slot), "name": runtime.display_name})
	_body.add_child(banner)
	var box := UIKit.vbox([], 6)
	box.add_child(_heading(Loc.t("ui.equip_slot.worn")))
	var worn_id: StringName = runtime.equipment.get(slot, &"")
	var worn := equipment.get_item(worn_id) if worn_id != &"" else null
	if worn == null:
		box.add_child(_note(Loc.t("ui.equip_slot.empty")))
	else:
		var remove := UIKit.button(Loc.t("ui.common.remove"), func() -> void:
			var reason := equipment.unequip(runtime, slot)
			if not reason.is_empty():
				get_tree().call_group(&"ui_root", &"toast", reason, true))
		ItemInfoModal._style_button(remove, ItemInfoModal.BUTTON, ItemInfoModal.FRAME_RIM.darkened(0.2))
		box.add_child(_row(worn, worn_id, remove))
	box.add_child(_heading(Loc.t("ui.equip_slot.stored")))
	var options := 0
	for instance_id in GameManager.inventory.get_instances():
		var item := equipment.get_item(instance_id)
		if item == null or EquipmentService.SLOT_NAMES.get(item.equipment_slot, &"") != slot:
			continue
		options += 1
		var equip := UIKit.button(Loc.t("ui.equip_slot.equip"), func() -> void:
			var reason := equipment.equip(runtime, instance_id)
			get_tree().call_group(&"ui_root", &"toast", reason if not reason.is_empty() else Loc.t("ui.hunter.equipped", {"item": item.display_name}),
				not reason.is_empty()))
		ItemInfoModal._style_button(equip, Color("2f5a2a"), ItemInfoModal.GOLD.darkened(0.3))
		box.add_child(_row(item, instance_id, equip))
	if options == 0:
		box.add_child(_note(Loc.t("ui.equip_slot.none")))
	var inner := PanelContainer.new()
	var inner_style := StyleBoxFlat.new()
	inner_style.bg_color = ItemInfoModal.BOX_BG
	inner_style.border_color = ItemInfoModal.BOX_RIM
	inner_style.set_border_width_all(1)
	inner_style.set_corner_radius_all(2)
	inner_style.set_content_margin_all(10)
	inner.add_theme_stylebox_override(&"panel", inner_style)
	# Long lists scroll inside the frame.
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = mini(options + (1 if worn != null else 0), 5) * 52 + 70
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	inner.add_child(scroll)
	_body.add_child(inner)
	var close := UIKit.button(Loc.t("ui.common.close"), queue_free, &"")
	close.custom_minimum_size = Vector2(150, 46)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.add_theme_font_size_override(&"font_size", 18)
	ItemInfoModal._style_button(close, ItemInfoModal.CLOSE, ItemInfoModal.CLOSE.darkened(0.45))
	_body.add_child(close)


## Icon (tap for details), name in the tier colour, bonuses, and an action button.
func _row(item: ItemDefinition, instance_id: StringName, action: Button) -> Control:
	var enhance := GameManager.inventory.get_enhance(instance_id)
	var icon := ItemIcon.new().setup(item, 40, "+%d" % enhance if enhance > 0 else "", instance_id)
	var name_label := _label(item.display_name, Tier.color(item.rarity), 14)
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var mods := _label(UIKit.describe_modifiers(item), ItemInfoModal.STAT, 12)
	var info := UIKit.vbox([name_label, mods], 1)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action.size_flags_horizontal = Control.SIZE_SHRINK_END
	action.custom_minimum_size = Vector2(64, 36)
	return UIKit.hbox([icon, info, action], 8)


func _heading(text: String) -> Label:
	return _label(text, ItemInfoModal.GOLD, 14)


func _note(text: String) -> Label:
	var label := _label(text, ItemInfoModal.NOTE, 12)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _label(text: String, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_outline_color", Color("0b0805"))
	label.add_theme_constant_override(&"outline_size", 2)
	return label
