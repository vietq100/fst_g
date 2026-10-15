class_name ItemIcon
extends Control
## Square item slot: dark rounded plate rimmed in the rarity colour, the item's pixel icon in the
## middle, an optional count or enhancement badge in the corner. `tappable()` turns it into a
## button (`pressed`); `selected` draws a gold frame (Storage grid, D63).

signal pressed

const PLATE := Color("141824")
const SELECTED := Color("f2c94c")

var selected := false:
	set(value):
		selected = value
		queue_redraw()

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
	var icon_scale := maxi(1, int((side - 8.0) / ItemIcons.SIZE))
	_texture = ItemIcons.texture(item, icon_scale)
	_badge = badge
	queue_redraw()
	return self


## Makes the slot react to taps (emits `pressed`).
func tappable() -> ItemIcon:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return self


func _gui_input(event: InputEvent) -> void:
	if mouse_filter != Control.MOUSE_FILTER_STOP:
		return
	var tapped := (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed)
	if tapped:
		accept_event()
		pressed.emit()


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
	if selected:
		var frame := StyleBoxFlat.new()
		frame.draw_center = false
		frame.border_color = SELECTED
		frame.set_border_width_all(2)
		frame.set_corner_radius_all(4)
		frame.shadow_color = Color(SELECTED, 0.35)
		frame.shadow_size = 3
		draw_style_box(frame, rect)
