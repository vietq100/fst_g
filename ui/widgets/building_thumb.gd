class_name BuildingThumb
extends Control
## Picture of a building for menus (D77, from D63): the same isometric BuildingVisual as on the map (no
## name plaque), scaled to fit a rounded plate with a sky band and a grass diamond under it. A dimmed
## version marks buildings that cannot be built yet.

const PLATE := Color("1b2030")
const SKY := Color("2a3550")
const GRASS := Color("4f7d3c")
const GRASS_DARK := Color("3d6331")
const LOCKED_TINT := Color(0.45, 0.45, 0.5, 0.9)
## Room kept around the building inside the plate (px).
const MARGIN := Vector2(6, 8)

var _visual: BuildingVisual
var _locked := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


## `side` = width and height in px. `locked` greys the building out.
func setup(building_id: StringName, footprint: Vector2i, level: int = 1, side: float = 64.0, locked: bool = false) -> BuildingThumb:
	custom_minimum_size = Vector2(side, side)
	_locked = locked
	_visual = BuildingVisual.new()
	_visual.building_id = building_id
	_visual.footprint = footprint
	_visual.level = level
	if locked:
		_visual.modulate = LOCKED_TINT
	add_child(_visual)
	resized.connect(_fit)
	_fit()
	return self


## Scales the building to the plate: its diamond spans x from -footprint.x to +footprint.y half-tiles
## around the origin (the footprint's south corner), and it rises get_height() px above it.
func _fit() -> void:
	if _visual == null:
		return
	var area := size if size != Vector2.ZERO else custom_minimum_size
	var half := WorldService.HALF_WIDTH
	var left := -_visual.footprint.x * half
	var right := _visual.footprint.y * half
	var width := right - left
	var height := _visual.get_height()
	var factor := minf((area.x - MARGIN.x * 2.0) / width, (area.y - MARGIN.y * 2.0) / height)
	_visual.scale = Vector2(factor, factor)
	_visual.position = Vector2(area.x * 0.5 - (left + right) * 0.5 * factor, area.y - MARGIN.y)
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var plate := StyleBoxFlat.new()
	plate.bg_color = PLATE
	plate.set_corner_radius_all(6)
	draw_style_box(plate, rect)
	draw_rect(Rect2(Vector2(2, 2), Vector2(size.x - 4.0, size.y * 0.55)), Color(SKY, 0.6))
	if _visual != null:
		# Grass diamond under the footprint.
		var grass := GRASS_DARK if _locked else GRASS
		var corners := _visual.get_corners()
		var middle := (corners[0] + corners[2]) * 0.5
		var ground := PackedVector2Array()
		for corner in corners:
			ground.append(_visual.position + (middle + (corner - middle) * 1.18) * _visual.scale.x)
		draw_colored_polygon(ground, grass)
	var rim := StyleBoxFlat.new()
	rim.draw_center = false
	rim.border_color = Color(GameTheme.BORDER, 0.5)
	rim.set_border_width_all(1)
	rim.set_corner_radius_all(6)
	draw_style_box(rim, rect)
