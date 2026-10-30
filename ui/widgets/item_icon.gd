class_name ItemIcon
extends Control
## Square item slot: dark rounded plate rimmed in the rarity colour, the item's pixel icon in the
## middle, an optional count or enhancement badge in the corner. Tapping it opens the item's
## details over the current screen (ItemInfoModal, D64); a worn-out weapon shows a red crack.

const PLATE := Color("12151f")

var _texture: Texture2D
var _rim := Color.WHITE
var _badge := ""
var _item: ItemDefinition
var _instance: StringName = &""
var _broken := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


## `instance` (optional) is the item instance shown, for its enhancement and durability.
func setup(item: ItemDefinition, side: float = 28.0, badge: String = "", instance: StringName = &"") -> ItemIcon:
	custom_minimum_size = Vector2(side, side)
	_item = item
	_instance = instance
	_broken = instance != &"" and Engine.get_main_loop() != null and _is_broken(instance)
	_rim = RarityColors.of(item.rarity) if item != null else RarityColors.COMMON
	var scale := maxi(1, int((side - 8.0) / ItemIcons.SIZE))
	_texture = ItemIcons.texture(item, scale)
	_badge = badge
	queue_redraw()
	return self


func _gui_input(event: InputEvent) -> void:
	if _item == null:
		return
	var is_tap: bool = (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if is_tap:
		accept_event()
		get_tree().call_group(&"ui_root", &"open_item_info", _item, _instance)


static func _is_broken(instance: StringName) -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var gm := tree.root.get_node_or_null(^"GameManager") if tree != null else null
	return gm != null and gm.equipment != null and gm.equipment.is_broken(instance)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var plate := StyleBoxFlat.new()
	plate.bg_color = PLATE
	plate.border_color = _rim.darkened(0.2)
	plate.set_border_width_all(1)
	plate.border_width_bottom = 2
	plate.set_corner_radius_all(4)
	plate.shadow_color = Color(0, 0, 0, 0.45)
	plate.shadow_size = 2
	plate.shadow_offset = Vector2(0, 1)
	draw_style_box(plate, rect)

	# Top sheen highlight
	draw_rect(Rect2(Vector2(2, 2), Vector2(size.x - 4.0, 2.0)), Color(_rim.lightened(0.25), 0.3))

	# High tier (SR and above) ornate corner brackets
	if _item != null and int(_item.rarity) >= Tier.Level.SR and size.x >= 28.0:
		var blen := 4.0 if size.x < 48.0 else 6.0
		var glow := Color(_rim.lightened(0.15), 0.85)
		for c in [Vector2(3, 3), Vector2(size.x - 3, 3), Vector2(3, size.y - 3), Vector2(size.x - 3, size.y - 3)]:
			var sx := 1.0 if c.x < size.x * 0.5 else -1.0
			var sy := 1.0 if c.y < size.y * 0.5 else -1.0
			draw_line(c, c + Vector2(blen * sx, 0), glow, 1.0)
			draw_line(c, c + Vector2(0, blen * sy), glow, 1.0)

	if _texture != null:
		var shown := _texture.get_size()
		draw_texture_rect(_texture, Rect2(((size - shown) * 0.5).floor(), shown), false)

	if _broken:
		var mid := size * 0.5
		draw_line(Vector2(4, 4), mid + Vector2(2, -2), Color("090b0f"), 3.0)
		draw_line(mid + Vector2(2, -2), size - Vector2(4, 4), Color("090b0f"), 3.0)
		draw_line(Vector2(4, 4), mid + Vector2(2, -2), GameTheme.DANGER, 2.0)
		draw_line(mid + Vector2(2, -2), size - Vector2(4, 4), GameTheme.DANGER, 2.0)

	if not _badge.is_empty():
		var font := ThemeDB.fallback_font
		var font_size := 12 if size.x >= 48.0 else 9
		var width := font.get_string_size(_badge, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var at := Vector2(size.x - width - 3.0, size.y - 4.0)
		var text_color := Color("fde047") if _badge.begins_with("+") else Color("fdf8e2")
		draw_string_outline(font, at, _badge, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color("090b0f"))
		draw_string(font, at, _badge, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
