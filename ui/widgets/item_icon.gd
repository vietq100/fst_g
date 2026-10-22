class_name ItemIcon
extends Control
## Square item slot: dark rounded plate rimmed in the rarity colour, the item's pixel icon in the
## middle, an optional count or enhancement badge in the corner. Tapping it opens the item's
## details over the current screen (ItemInfoModal, D64); a worn-out weapon shows a red crack.

const PLATE := Color("141824")

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
	if _item != null and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
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
	plate.border_color = _rim.darkened(0.15)
	plate.set_border_width_all(1)
	plate.set_corner_radius_all(4)
	draw_style_box(plate, rect)
	draw_rect(Rect2(Vector2(2, 2), Vector2(size.x - 4.0, 2.0)), Color(_rim, 0.25))
	if _texture != null:
		var shown := _texture.get_size()
		draw_texture_rect(_texture, Rect2(((size - shown) * 0.5).floor(), shown), false)
	if _broken:
		draw_line(Vector2(3, 3), size - Vector2(3, 3), GameTheme.DANGER, 2.0)
	if not _badge.is_empty():
		var font := ThemeDB.fallback_font
		var font_size := 12 if size.x >= 48.0 else 9
		var width := font.get_string_size(_badge, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var at := Vector2(size.x - width - 3.0, size.y - 4.0)
		draw_string_outline(font, at, _badge, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color("0b0d12"))
		draw_string(font, at, _badge, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("fff3c4"))
