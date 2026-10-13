class_name ItemIcon
extends Control
## Square item slot: dark rounded plate rimmed in the rarity colour, the item's pixel icon in the
## middle, an optional count or enhancement badge in the corner.

const PLATE := Color("141824")

var _texture: Texture2D
var _rim := Color.WHITE
var _badge := ""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


func setup(item: ItemDefinition, side: float = 28.0, badge: String = "") -> ItemIcon:
	custom_minimum_size = Vector2(side, side)
	_rim = RarityColors.of(item.rarity) if item != null else RarityColors.COMMON
	var scale := maxi(1, int((side - 8.0) / ItemIcons.SIZE))
	_texture = ItemIcons.texture(item, scale)
	_badge = badge
	queue_redraw()
	return self


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
	if not _badge.is_empty():
		var font := ThemeDB.fallback_font
		var width := font.get_string_size(_badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
		var at := Vector2(size.x - width - 2.0, size.y - 3.0)
		draw_string_outline(font, at, _badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, 2, Color("0b0d12"))
		draw_string(font, at, _badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("fff3c4"))
