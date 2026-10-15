class_name BuildingThumb
extends Control
## Picture of a building for menus (D63): the same BuildingVisual as on the map, scaled to fit a
## rounded plate with a strip of grass, smoke and all. A dimmed version marks locked buildings.

const PLATE := Color("1b2030")
const SKY := Color("2a3550")
const GRASS := Color("4f7d3c")
const GRASS_DARK := Color("3d6331")

var _visual: BuildingVisual
var _locked := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


## `side` = width and height in px. `locked` greys the building out.
func setup(building_id: StringName, footprint: Vector2i, level: int = 1, side: float = 72.0, locked: bool = false) -> BuildingThumb:
	custom_minimum_size = Vector2(side, side)
	_locked = locked
	_visual = BuildingVisual.new()
	_visual.building_id = building_id
	_visual.footprint = footprint
	_visual.level = level
	if locked:
		_visual.modulate = Color(0.45, 0.45, 0.5, 0.9)
	add_child(_visual)
	resized.connect(_fit)
	_fit()
	return self


func _fit() -> void:
	if _visual == null:
		return
	var area := size if size != Vector2.ZERO else custom_minimum_size
	var width := _visual.get_width() + 24.0
	var height := _visual.get_height() + 8.0
	var factor := minf((area.x - 6.0) / width, (area.y - 8.0) / height)
	_visual.scale = Vector2(factor, factor)
	_visual.position = Vector2(area.x * 0.5, area.y - 7.0)
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var plate := StyleBoxFlat.new()
	plate.bg_color = PLATE
	plate.set_corner_radius_all(6)
	draw_style_box(plate, rect)
	draw_rect(Rect2(Vector2(2, 2), Vector2(size.x - 4.0, size.y * 0.55)), Color(SKY, 0.6))
	draw_rect(Rect2(Vector2(2, size.y - 10.0), Vector2(size.x - 4.0, 8.0)), GRASS_DARK if _locked else GRASS)
	draw_rect(Rect2(Vector2(2, size.y - 10.0), Vector2(size.x - 4.0, 2.0)), (GRASS_DARK if _locked else GRASS).lightened(0.15))
	var rim := StyleBoxFlat.new()
	rim.draw_center = false
	rim.border_color = Color(GameTheme.BORDER, 0.5)
	rim.set_border_width_all(1)
	rim.set_corner_radius_all(6)
	draw_style_box(rim, rect)
