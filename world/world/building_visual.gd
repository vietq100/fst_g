@tool
class_name BuildingVisual
extends Node2D
## Front-facing 3/4 building on the top-down grid (BUILDING_DESIGN.md, D52, D58), in the style of
## 2D management games. Layers, back to front: ground shadow, stone plinth, front wall (stone
## blocks, wooden planks or plaster with a timber frame) with corner quoins and a base trim,
## windows with shutters, lintels and sills (flower boxes on homes and inns), a framed door with
## steps, then the roof: a hip roof (tiled slope up to a capped ridge) or a gable roof (tiled side
## slopes behind a gable with a round window and barge boards). Each building adds its own
## silhouette: clock tower, open forge, striped awnings, hanging signs, dormers, chimneys with
## rising smoke, spire, columns, crates and barrels; the Reincarnation Portal is a stone ring on a
## dais instead of a house. Lv2 adds height, a second storey where there is one, and a flag.
## Origin = middle of the footprint's bottom edge, so y-sorting with actors works. The footprint
## is `footprint` tiles wide and deep behind the origin; the wall and roof rise above it.
## `ghost` draws a translucent placement preview tinted green (valid) or red.

const OUTLINE := Color("16161c")
const SHADOW := Color(0, 0, 0, 0.22)
const SELECTION := Color("f2d16b")
const GLASS := Color("ffcf6b")
const GLASS_DARK := Color("c9792e")
const COLD_GLASS := Color("bfe3ff")
const STONE := Color("8a8a84")
const TIMBER := Color("4a3424")
const DOOR := Color("5a3a22")
const FLAG := Color("a83a3a")
const LABEL := Color("f4f1ea")
const PLAQUE := Color(0.08, 0.06, 0.05, 0.72)
const SMOKE := Color(0.82, 0.82, 0.86, 0.45)
const LEAF := Color("3f6a36")
const VALID := Color(0.4, 1.0, 0.45, 0.45)
const INVALID := Color(1.0, 0.35, 0.3, 0.45)
## Chimney smoke (and the portal's sparks) redraw at this rate.
const SMOKE_FPS := 6.0
const ANIMATED: Array[StringName] = [&"tavern", &"blacksmith", &"house", &"restaurant", &"forge", &"portal"]
## Roof eaves stick out this far past the walls.
const EAVE := 5.0
## The ridge of a hip roof is this much shorter than the eave line on each side.
const HIP := 10.0
## Homes with flower boxes under their ground-floor windows.
const FLOWER_BOXES: Array[StringName] = [&"house", &"inn", &"tavern", &"restaurant"]

enum Wall { STONE, WOOD, PLASTER }
enum Roof { HIP_ROOF, GABLE, NONE }

## height = front wall height (px); floors = window rows.
const STYLES := {
	&"town_hall": {"wall": Color("d8ccb0"), "roof": Color("3c5a8c"), "trim": Color("e2c46b"), "height": 40.0, "wall_type": Wall.STONE, "roof_type": Roof.HIP_ROOF, "floors": 2},
	&"tavern": {"wall": Color("e3d3b4"), "roof": Color("9a3b2e"), "trim": Color("e2a64b"), "height": 38.0, "wall_type": Wall.PLASTER, "roof_type": Roof.GABLE, "floors": 2},
	&"blacksmith": {"wall": Color("6d6a64"), "roof": Color("3f4247"), "trim": Color("ff8a3d"), "height": 30.0, "wall_type": Wall.STONE, "roof_type": Roof.HIP_ROOF, "floors": 1},
	&"hospital": {"wall": Color("eee9de"), "roof": Color("3f8a83"), "trim": Color("c94a4a"), "height": 34.0, "wall_type": Wall.PLASTER, "roof_type": Roof.HIP_ROOF, "floors": 1},
	&"warehouse": {"wall": Color("8d7050"), "roof": Color("6a4a30"), "trim": Color("b08d57"), "height": 32.0, "wall_type": Wall.WOOD, "roof_type": Roof.GABLE, "floors": 1},
	&"house": {"wall": Color("c09468"), "roof": Color("a8503a"), "trim": Color("e8d3a8"), "height": 28.0, "wall_type": Wall.WOOD, "roof_type": Roof.GABLE, "floors": 1},
	&"temple": {"wall": Color("e2dccb"), "roof": Color("b8913a"), "trim": Color("f2d16b"), "height": 40.0, "wall_type": Wall.STONE, "roof_type": Roof.GABLE, "floors": 1},
	&"trading_post": {"wall": Color("b08658"), "roof": Color("2f6f5e"), "trim": Color("f2d16b"), "height": 30.0, "wall_type": Wall.WOOD, "roof_type": Roof.HIP_ROOF, "floors": 1},
	&"restaurant": {"wall": Color("eadcc0"), "roof": Color("a83a3a"), "trim": Color("f4f1ea"), "height": 32.0, "wall_type": Wall.PLASTER, "roof_type": Roof.HIP_ROOF, "floors": 1},
	&"inn": {"wall": Color("e6d8bc"), "roof": Color("5b6c8f"), "trim": Color("f4f1ea"), "height": 40.0, "wall_type": Wall.PLASTER, "roof_type": Roof.HIP_ROOF, "floors": 2},
	&"academy": {"wall": Color("c4bfd2"), "roof": Color("5a3f8c"), "trim": Color("9fd6ff"), "height": 40.0, "wall_type": Wall.STONE, "roof_type": Roof.HIP_ROOF, "floors": 2},
	&"forge": {"wall": Color("55555c"), "roof": Color("8a3b24"), "trim": Color("ff7a2e"), "height": 30.0, "wall_type": Wall.STONE, "roof_type": Roof.HIP_ROOF, "floors": 1},
	&"portal": {"wall": Color("3a3458"), "roof": Color("6a3fb8"), "trim": Color("c79bff"), "height": 0.0, "wall_type": Wall.STONE, "roof_type": Roof.NONE, "floors": 0},
}
## Extra height above the roof (towers, spires, flags), for taps and the name plaque.
const EXTRA_HEIGHT := {&"town_hall": 56.0, &"temple": 26.0, &"academy": 16.0}
const PORTAL_HEIGHT := 72.0

@export var building_id: StringName = &"house":
	set(value):
		building_id = value
		queue_redraw()
@export var footprint := Vector2i(2, 2):
	set(value):
		footprint = value
		queue_redraw()
@export var level := 1:
	set(value):
		level = value
		queue_redraw()
@export var title := "":
	set(value):
		title = value
		queue_redraw()

var selected := false:
	set(value):
		selected = value
		queue_redraw()
var ghost := false:
	set(value):
		ghost = value
		queue_redraw()
var ghost_valid := true:
	set(value):
		ghost_valid = value
		queue_redraw()

var _smoke_time := 0.0
var _smoke_frame := 0


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or ghost or not ANIMATED.has(building_id):
		return
	_smoke_time += delta
	if _smoke_time >= 1.0 / SMOKE_FPS:
		_smoke_time -= 1.0 / SMOKE_FPS
		_smoke_frame += 1
		queue_redraw()


## Corners of the footprint relative to the origin (bottom-centre): top-left, top-right,
## bottom-right, bottom-left.
func get_corners() -> PackedVector2Array:
	var half := footprint.x * WorldService.TILE * 0.5
	var depth := footprint.y * WorldService.TILE
	return PackedVector2Array([Vector2(-half, -depth), Vector2(half, -depth), Vector2(half, 0), Vector2(-half, 0)])


## Footprint width in world units.
func get_width() -> float:
	return footprint.x * WorldService.TILE


## Height of the drawing above the origin (plinth, wall, roof and any tower), for taps.
func get_height() -> float:
	if building_id == &"portal":
		return PORTAL_HEIGHT
	return _plinth() + _wall_height() + _roof_height() + float(EXTRA_HEIGHT.get(building_id, 0.0)) + 4.0


func _wall_height() -> float:
	return float(_style()["height"]) * (1.15 if level >= 2 else 1.0)


func _plinth() -> float:
	return 6.0 if level >= 2 else 4.0


func _roof_height() -> float:
	return footprint.y * WorldService.TILE * 0.55 + 10.0


func _style() -> Dictionary:
	return STYLES.get(building_id, STYLES[&"house"])


func _floors() -> int:
	return int(_style()["floors"])


func _draw() -> void:
	if ghost:
		_draw_ghost()
		return
	if building_id == &"portal":
		_draw_portal()
	else:
		var style := _style()
		var half := get_width() * 0.5
		var h := _wall_height()
		var plinth := _plinth()
		_draw_ground_shadow(half)
		_draw_plinth(half, plinth)
		var wall := Rect2(Vector2(-half, -plinth - h), Vector2(half * 2.0, h))
		var wall_color: Color = style["wall"]
		draw_rect(wall, wall_color)
		_draw_wall_material(style, wall)
		_draw_quoins(style, wall)
		draw_rect(Rect2(Vector2(-half, -plinth - 3.0), Vector2(half * 2.0, 3.0)), wall_color.darkened(0.25))
		_draw_windows(style, wall)
		_draw_door(style, wall)
		draw_rect(wall, OUTLINE, false, 1.0)
		var ridge := _draw_roof(style, half, wall.position.y)
		_draw_details(style, wall, ridge)
	if selected:
		var corners := get_corners()
		draw_rect(Rect2(corners[0] - Vector2(4, 4), Vector2(get_width() + 8.0, footprint.y * WorldService.TILE + 8.0)), SELECTION, false, 2.0)
	if not title.is_empty():
		_draw_label(Vector2(0, -get_height()))


## Placement preview: tinted footprint, then the wall and roof block, translucent.
func _draw_ghost() -> void:
	var style := _style()
	var tint := Color(1, 1, 1, 0.55)
	draw_colored_polygon(get_corners(), VALID if ghost_valid else INVALID)
	if building_id == &"portal":
		var trim: Color = style["trim"]
		draw_circle(Vector2(0, -46), 22.0, Color(trim, 0.5))
		return
	var half := get_width() * 0.5
	var h := _wall_height()
	var top := -_plinth() - h
	var wall_color: Color = style["wall"]
	var roof_color: Color = style["roof"]
	draw_rect(Rect2(Vector2(-half, top), Vector2(half * 2.0, h + _plinth())), wall_color * tint)
	var eave := Vector2(0, top + 3.0)
	var ridge := top - _roof_height()
	draw_colored_polygon(PackedVector2Array([Vector2(-half - EAVE, eave.y), Vector2(half + EAVE, eave.y), Vector2(half - HIP, ridge),
		Vector2(-half + HIP, ridge)]), roof_color * tint)


## Shadow cast back and to the right onto the ground, and a soft contact shadow.
func _draw_ground_shadow(half: float) -> void:
	var depth := footprint.y * WorldService.TILE * 0.8
	draw_colored_polygon(PackedVector2Array([Vector2(-half - 2.0, -2.0), Vector2(half + 2.0, -2.0), Vector2(half + 14.0, -10.0),
		Vector2(half + 14.0, -depth), Vector2(-half + 10.0, -depth)]), SHADOW)
	draw_ellipse(Vector2(0, -1), half + 6.0, 5.0, Color(0, 0, 0, 0.25))


## Stone foundation band under the wall, slightly wider than it.
func _draw_plinth(half: float, plinth: float) -> void:
	var rect := Rect2(Vector2(-half - 2.0, -plinth), Vector2(half * 2.0 + 4.0, plinth))
	draw_rect(rect, STONE)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 1.0)), STONE.lightened(0.2))
	var blocks := int(rect.size.x / 10.0)
	for i in range(1, blocks):
		var x := rect.position.x + rect.size.x * i / blocks
		draw_line(Vector2(x, rect.position.y + 1.0), Vector2(x, rect.end.y), STONE.darkened(0.4), 1.0)
	draw_rect(rect, OUTLINE, false, 1.0)


## Stone blocks in varied shades, alternating planks, or plaster with a timber frame.
func _draw_wall_material(style: Dictionary, rect: Rect2) -> void:
	var wall: Color = style["wall"]
	var wall_type: int = style["wall_type"]
	match wall_type:
		Wall.STONE:
			var rows := maxi(int(rect.size.y / 6.0), 2)
			var columns := maxi(int(rect.size.x / 12.0), 2)
			var row_height := rect.size.y / rows
			for k in rows:
				var y := rect.position.y + row_height * k
				var shift := 0.5 if k % 2 == 1 else 0.0
				for i in range(-1, columns + 1):
					var x0 := maxf(rect.position.x + rect.size.x * (i + shift) / columns, rect.position.x)
					var x1 := minf(rect.position.x + rect.size.x * (i + shift + 1.0) / columns, rect.end.x)
					if x1 - x0 < 2.0:
						continue
					var roll := _hash(i, k, 3) % 100
					var block := wall.lightened(0.07) if roll < 25 else (wall.darkened(0.08) if roll > 80 else wall)
					draw_rect(Rect2(Vector2(x0 + 0.5, y + 0.5), Vector2(x1 - x0 - 1.0, row_height - 1.0)), block)
					draw_rect(Rect2(Vector2(x0 + 0.5, y + 0.5), Vector2(x1 - x0 - 1.0, 1.0)), block.lightened(0.12))
		Wall.WOOD:
			var planks := maxi(int(rect.size.y / 4.0), 2)
			var plank := rect.size.y / planks
			for k in planks:
				var y := rect.position.y + plank * k
				draw_rect(Rect2(Vector2(rect.position.x, y), Vector2(rect.size.x, plank)), wall if k % 2 == 1 else wall.darkened(0.05))
				draw_line(Vector2(rect.position.x, y + plank - 0.5), Vector2(rect.end.x, y + plank - 0.5), wall.darkened(0.3), 1.0)
				draw_line(Vector2(rect.position.x, y + 0.5), Vector2(rect.end.x, y + 0.5), wall.lightened(0.1), 1.0)
		_:
			for t: float in [0.0, 0.5, 1.0]:
				var x := rect.position.x + rect.size.x * t
				draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), TIMBER, 3.0)
			var brace_y := rect.position.y + rect.size.y * (0.48 if _floors() >= 2 else 0.45)
			if _floors() >= 2:
				draw_line(Vector2(rect.position.x, brace_y), Vector2(rect.end.x, brace_y), TIMBER, 3.0)
			draw_line(rect.position + Vector2(0, 1.5), Vector2(rect.end.x, rect.position.y + 1.5), TIMBER, 3.0)
			var mid := rect.position.x + rect.size.x * 0.5
			for span: Vector2 in [Vector2(rect.position.x, mid), Vector2(mid, rect.end.x)]:
				draw_line(Vector2(span.x + 3.0, brace_y - 2.0), Vector2(span.y - 3.0, rect.position.y + 4.0), TIMBER.darkened(0.1), 1.5)


## Corner stones (stone and plaster) or dark corner posts (wood).
func _draw_quoins(style: Dictionary, rect: Rect2) -> void:
	var wall: Color = style["wall"]
	var wall_type: int = style["wall_type"]
	if wall_type == Wall.WOOD:
		for x: float in [rect.position.x + 1.0, rect.end.x - 3.0]:
			draw_rect(Rect2(Vector2(x, rect.position.y), Vector2(2, rect.size.y)), wall.darkened(0.35))
		return
	var stone := STONE.lightened(0.12) if wall_type == Wall.PLASTER else wall.lightened(0.12)
	var count := maxi(int(rect.size.y / 6.0), 2)
	var step := rect.size.y / count
	for k in count:
		var width := 5.0 if k % 2 == 0 else 3.0
		var y := rect.position.y + step * k + 0.5
		for x: float in [rect.position.x, rect.end.x - width]:
			var block := Rect2(Vector2(x, y), Vector2(width, step - 1.0))
			draw_rect(block, stone)
			draw_rect(block, stone.darkened(0.35), false, 1.0)


## Window rows (y of each row's top): one, or two for a two-storey front.
func _window_rows(rect: Rect2) -> Array[float]:
	var rows: Array[float] = [rect.position.y + rect.size.y * 0.28]
	if _floors() >= 2:
		rows = [rect.position.y + rect.size.y * 0.12, rect.position.y + rect.size.y * 0.58]
	return rows


## Windows with shutters, lintel and a sill (a flower box on homes), skipping the door column on
## the ground floor.
func _draw_windows(style: Dictionary, rect: Rect2) -> void:
	var trim: Color = style["trim"]
	var cold := building_id == &"hospital"
	var glass := COLD_GLASS if cold else GLASS
	var rows := _window_rows(rect)
	var columns: Array[float] = [0.22, 0.78]
	if footprint.x > 2:
		columns = [0.17, 0.38, 0.62, 0.83]
	var size := Vector2(8, 10)
	for row in rows.size():
		var y: float = rows[row]
		var ground_floor := row == rows.size() - 1
		for t in columns:
			if ground_floor and absf(t - 0.5) < 0.15:
				continue
			var x := rect.position.x + rect.size.x * t
			var pane := Rect2(Vector2(x - size.x * 0.5, y), size)
			for side: float in [-1.0, 1.0]:
				var shutter_x := x - size.x * 0.5 - 4.0 if side < 0.0 else x + size.x * 0.5 + 1.0
				draw_rect(Rect2(Vector2(shutter_x, y), Vector2(3, size.y)), trim.darkened(0.15))
				draw_line(Vector2(shutter_x + 0.5, y + size.y * 0.5), Vector2(shutter_x + 2.5, y + size.y * 0.5), trim.darkened(0.45), 1.0)
			draw_rect(pane.grow(1.0), OUTLINE)
			draw_rect(pane, glass)
			draw_rect(Rect2(pane.position, Vector2(size.x, 3.0)), glass.darkened(0.25) if cold else GLASS_DARK)
			draw_line(Vector2(pane.position.x, y + size.y * 0.5), Vector2(pane.end.x, y + size.y * 0.5), OUTLINE, 1.0)
			draw_line(Vector2(x, y), Vector2(x, pane.end.y), OUTLINE, 1.0)
			draw_rect(Rect2(pane.position - Vector2(2, 2), Vector2(size.x + 4.0, 2.0)), trim.darkened(0.1))
			if ground_floor and FLOWER_BOXES.has(building_id):
				draw_rect(Rect2(Vector2(pane.position.x - 2.0, pane.end.y + 1.0), Vector2(size.x + 4.0, 3.0)), Color("6a4a30"))
				for i in 3:
					var bloom := Vector2(x - 3.0 + i * 3.0, pane.end.y)
					draw_circle(bloom, 1.6, LEAF)
					draw_circle(bloom - Vector2(0, 0.5), 0.9, Color("f2c94c") if i == 1 else Color("e8789a"))
			else:
				draw_rect(Rect2(Vector2(pane.position.x - 2.0, pane.end.y + 1.0), Vector2(size.x + 4.0, 2.0)), STONE.lightened(0.15))


## Framed plank door (a wide barn door with braces on the Warehouse) and two stone steps.
func _draw_door(style: Dictionary, rect: Rect2) -> void:
	var wide := building_id == &"warehouse"
	var width := 20.0 if wide else 12.0
	var height := minf(20.0 if wide else 18.0, rect.size.y - 3.0)
	var base := rect.end.y
	var trim: Color = style["trim"]
	draw_rect(Rect2(Vector2(-width * 0.5 - 2.0, base - height - 2.0), Vector2(width + 4.0, height + 2.0)), OUTLINE)
	draw_rect(Rect2(Vector2(-width * 0.5 - 1.0, base - height - 1.0), Vector2(width + 2.0, height + 1.0)), TIMBER if wide else trim.darkened(0.2))
	var door := Rect2(Vector2(-width * 0.5, base - height), Vector2(width, height))
	draw_rect(door, DOOR)
	for i in range(1, int(width / 4.0)):
		var x := door.position.x + i * 4.0
		draw_line(Vector2(x, door.position.y), Vector2(x, base), DOOR.darkened(0.35), 1.0)
	if wide:
		var brace := DOOR.darkened(0.45)
		for half: float in [-1.0, 1.0]:
			var outer := width * 0.5 * half
			draw_line(Vector2(outer, door.position.y), Vector2(0, base), brace, 1.5)
			draw_line(Vector2(0, door.position.y), Vector2(outer, base), brace, 1.5)
		draw_line(Vector2(0, door.position.y), Vector2(0, base), OUTLINE, 1.0)
	else:
		draw_rect(Rect2(door.position, Vector2(width, 2.0)), DOOR.lightened(0.15))
		draw_circle(Vector2(width * 0.5 - 3.0, base - height * 0.5), 1.0, Color("e8c547"))
	draw_rect(Rect2(Vector2(-width * 0.5 - 3.0, base), Vector2(width + 6.0, 2.0)), STONE.lightened(0.2))
	draw_rect(Rect2(Vector2(-width * 0.5 - 5.0, base + 2.0), Vector2(width + 10.0, 2.0)), STONE)


## The roof over the wall top. Returns its peak as [left, right] (equal for a gable apex).
func _draw_roof(style: Dictionary, half: float, top: float) -> PackedVector2Array:
	var roof: Color = style["roof"]
	var roof_type: int = style["roof_type"]
	var height := _roof_height()
	var eave_y := top + 3.0
	var ridge_y := top - height
	var left := Vector2(-half - EAVE, eave_y)
	var right := Vector2(half + EAVE, eave_y)
	var ridge := PackedVector2Array()
	if roof_type == Roof.GABLE:
		# Side slopes up to a ridge across the whole width, a gable in front of them.
		var ridge_left := Vector2(-half - EAVE + 2.0, ridge_y + height * 0.15)
		var ridge_right := Vector2(half + EAVE - 2.0, ridge_y + height * 0.15)
		_draw_shingles(left, right, ridge_right, ridge_left, roof, int(height / 5.0))
		draw_polyline(PackedVector2Array([left, right, ridge_right, ridge_left, left]), OUTLINE, 1.0)
		var apex := Vector2(0, ridge_y - 2.0)
		var gable_left := Vector2(-half + 2.0, top + 1.0)
		var gable_right := Vector2(half - 2.0, top + 1.0)
		var wall: Color = style["wall"]
		draw_colored_polygon(PackedVector2Array([gable_left, gable_right, apex]), wall.darkened(0.06))
		if int(style["wall_type"]) == Wall.WOOD:
			for k in range(1, 6):
				var t := k / 6.0
				var y := top - (top - apex.y) * t
				draw_line(Vector2(gable_left.lerp(apex, t).x, y), Vector2(gable_right.lerp(apex, t).x, y), wall.darkened(0.3), 1.0)
		var window := Vector2(0, top - (top - apex.y) * 0.42)
		draw_circle(window, 5.5, OUTLINE)
		draw_circle(window, 4.5, COLD_GLASS if building_id == &"temple" else GLASS)
		draw_line(window + Vector2(-4.5, 0), window + Vector2(4.5, 0), OUTLINE, 1.0)
		draw_line(window + Vector2(0, -4.5), window + Vector2(0, 4.5), OUTLINE, 1.0)
		for corner: Vector2 in [gable_left + Vector2(-EAVE, 2.0), gable_right + Vector2(EAVE, 2.0)]:
			draw_line(corner, apex, OUTLINE, 4.0)
			draw_line(corner, apex, roof.lightened(0.25), 2.0)
		ridge.append(apex)
		ridge.append(apex)
	else:
		var ridge_left := Vector2(-half + HIP, ridge_y)
		var ridge_right := Vector2(half - HIP, ridge_y)
		_draw_shingles(left, right, ridge_right, ridge_left, roof, int(height / 5.0))
		draw_line(left, ridge_left, roof.darkened(0.45), 2.0)
		draw_line(right, ridge_right, roof.darkened(0.45), 2.0)
		draw_polyline(PackedVector2Array([left, right, ridge_right, ridge_left, left]), OUTLINE, 1.0)
		draw_line(ridge_left - Vector2(1, 0), ridge_right + Vector2(1, 0), OUTLINE, 4.0)
		draw_line(ridge_left, ridge_right, roof.lightened(0.4), 2.0)
		for i in int((ridge_right.x - ridge_left.x) / 6.0) + 1:
			draw_circle(Vector2(ridge_left.x + i * 6.0, ridge_y - 0.5), 1.2, roof.lightened(0.25))
		ridge.append(ridge_left)
		ridge.append(ridge_right)
	# Shadow of the eave on the wall, then the bright eave edge.
	draw_rect(Rect2(Vector2(-half, top + 3.0), Vector2(half * 2.0, 4.0)), Color(0, 0, 0, 0.25))
	draw_line(left, right, roof.lightened(0.3), 2.0)
	draw_line(left + Vector2(0, 1.5), right + Vector2(0, 1.5), OUTLINE, 1.0)
	return ridge


## Tiled slope between the eave line (left → right) and the ridge (ridge_right ← ridge_left):
## rows shaded darker towards the eave, row lines, staggered tile joints and a lit row edge.
func _draw_shingles(left: Vector2, right: Vector2, ridge_right: Vector2, ridge_left: Vector2, roof: Color, rows: int) -> void:
	draw_colored_polygon(PackedVector2Array([left, right, ridge_right, ridge_left]), roof)
	rows = maxi(rows, 4)
	for k in rows:
		var t0 := float(k) / rows
		var t1 := float(k + 1) / rows
		var a0 := left.lerp(ridge_left, t0)
		var b0 := right.lerp(ridge_right, t0)
		var a1 := left.lerp(ridge_left, t1)
		var b1 := right.lerp(ridge_right, t1)
		var shade := roof.darkened(0.18 * (1.0 - t0))
		if k % 2 == 1:
			shade = shade.lightened(0.04)
		draw_colored_polygon(PackedVector2Array([a0, b0, b1, a1]), shade)
		draw_line(a0, b0, roof.darkened(0.38), 1.0)
		draw_line(a1 + Vector2(0, 1), b1 + Vector2(0, 1), shade.lightened(0.18), 1.0)
		var offset := 3.5 if k % 2 == 1 else 0.0
		for i in int((b0.x - a0.x) / 7.0):
			var x := a0.x + offset + i * 7.0
			if x > b1.x - 1.0 or x < a1.x + 1.0:
				continue
			draw_line(Vector2(x, a0.y - 0.5), Vector2(x, a1.y + 1.0), roof.darkened(0.32), 1.0)


func _draw_details(style: Dictionary, wall: Rect2, ridge: PackedVector2Array) -> void:
	var trim: Color = style["trim"]
	var wall_color: Color = style["wall"]
	var roof: Color = style["roof"]
	var apex := ridge[0].lerp(ridge[1], 0.5)
	var ridge_y := ridge[0].y
	match building_id:
		&"town_hall":
			_draw_clock_tower(wall_color, roof, apex)
			draw_line(wall.position + Vector2(0, 3), Vector2(wall.end.x, wall.position.y + 3.0), trim, 2.0)
			for x: float in [-14.0, 14.0]:
				_draw_column(Rect2(Vector2(x - 2.0, wall.end.y - 22.0), Vector2(4, 22)), wall_color)
		&"tavern":
			_draw_hanging_sign(Vector2(wall.end.x + 5.0, wall.position.y + wall.size.y * 0.42), trim, &"mug")
			_draw_chimney(Vector2(wall.end.x - 14.0, ridge_y + 18.0), Color("7a5a48"), false)
			_draw_barrel(Vector2(wall.position.x - 4.0, wall.end.y + 2.0))
			_draw_barrel(Vector2(wall.position.x + 4.0, wall.end.y + 4.0))
		&"blacksmith":
			_draw_chimney(Vector2(wall.end.x - 12.0, ridge_y + 6.0), Color("4a4542"), true)
			_draw_forge_bay(Vector2(wall.end.x - 22.0, wall.end.y))
			var anvil := Vector2(wall.position.x + 10.0, wall.end.y + 6.0)
			draw_rect(Rect2(anvil + Vector2(-6, -7), Vector2(12, 3)), OUTLINE)
			draw_rect(Rect2(anvil + Vector2(-5, -6.5), Vector2(10, 2)), Color("5d5a55"))
			draw_rect(Rect2(anvil + Vector2(-2, -4), Vector2(4, 4)), OUTLINE)
			_draw_awning(Vector2(wall.position.x + wall.size.x * 0.62, wall.position.y + wall.size.y * 0.32), 26.0, Color("6a4a30"), Color("8a6a44"))
		&"hospital":
			var cross := apex + Vector2(0, 12)
			draw_rect(Rect2(cross - Vector2(7, 7), Vector2(14, 14)), OUTLINE)
			draw_rect(Rect2(cross - Vector2(6, 6), Vector2(12, 12)), Color("f4f1ea"))
			draw_rect(Rect2(cross - Vector2(4.5, 1.5), Vector2(9, 3)), trim)
			draw_rect(Rect2(cross - Vector2(1.5, 4.5), Vector2(3, 9)), trim)
			draw_rect(Rect2(Vector2(-4, wall.position.y + 3.0), Vector2(8, 3)), trim)
			draw_rect(Rect2(Vector2(-1.5, wall.position.y + 0.5), Vector2(3, 8)), trim)
		&"warehouse":
			for offset: Vector2 in [Vector2(-8, 0), Vector2(0, 0), Vector2(-4, -7)]:
				_draw_crate(Vector2(wall.end.x + 6.0, wall.end.y + 2.0) + offset, trim)
			_draw_crate(Vector2(wall.position.x - 6.0, wall.end.y + 2.0), trim)
		&"house":
			_draw_chimney(Vector2(wall.position.x + 12.0, ridge_y + 16.0), Color("8a6a58"), false)
		&"trading_post":
			_draw_awning(Vector2(0, wall.position.y + wall.size.y * 0.25), wall.size.x - 8.0, Color("2f6f5e"), Color("f4f1ea"))
			_draw_hanging_sign(Vector2(wall.end.x + 5.0, wall.position.y + wall.size.y * 0.5), trim, &"coin")
			for offset: Vector2 in [Vector2(-6, 0), Vector2(2, 0)]:
				_draw_crate(Vector2(wall.position.x - 2.0, wall.end.y + 2.0) + offset, Color("b08d57"))
		&"restaurant":
			_draw_awning(Vector2(0, wall.position.y + wall.size.y * 0.22), wall.size.x - 6.0, Color("a83a3a"), Color("f4f1ea"))
			_draw_chimney(Vector2(wall.end.x - 12.0, ridge_y + 6.0), Color("8a6a58"), false)
			_draw_hanging_sign(Vector2(wall.position.x - 5.0, wall.position.y + wall.size.y * 0.5), trim, &"plate")
		&"inn":
			for x: float in [-14.0, 14.0]:
				_draw_dormer(Vector2(x, ridge_y + 16.0), wall_color, roof)
			_draw_hanging_sign(Vector2(wall.end.x + 5.0, wall.position.y + wall.size.y * 0.42), Color("5b6c8f"), &"bed")
			_draw_lantern(Vector2(wall.position.x + wall.size.x * 0.5 + 10.0, wall.end.y - 14.0))
		&"academy":
			_draw_flag(apex, Color("5a3f8c"))
			for x: float in [-22.0, 22.0]:
				_draw_dormer(Vector2(x, ridge_y + 18.0), wall_color, roof)
			for x: float in [-12.0, 12.0]:
				_draw_column(Rect2(Vector2(x - 2.0, wall.end.y - 24.0), Vector2(4, 24)), wall_color)
			var crest := Vector2(0, wall.position.y + wall.size.y * 0.32)
			draw_circle(crest, 5.0, OUTLINE)
			draw_circle(crest, 4.0, trim)
		&"forge":
			_draw_chimney(Vector2(wall.end.x - 12.0, ridge_y + 6.0), Color("4a4542"), true)
			draw_circle(Vector2(0, wall.end.y - 8.0), 12.0, Color(trim, 0.3))
		&"temple":
			var peak := ridge[0]
			draw_colored_polygon(PackedVector2Array([peak + Vector2(-5, 4), peak + Vector2(5, 4), peak + Vector2(0, -20)]), OUTLINE)
			draw_colored_polygon(PackedVector2Array([peak + Vector2(-4, 3), peak + Vector2(4, 3), peak + Vector2(0, -18)]), roof)
			draw_circle(peak + Vector2(0, -22), 4.5, OUTLINE)
			draw_circle(peak + Vector2(0, -22), 3.5, trim)
			for x: float in [-14.0, 14.0]:
				_draw_column(Rect2(Vector2(x - 2.0, wall.position.y + 2.0), Vector2(4, wall.size.y - 2.0)), wall_color)
	if level >= 2 and building_id != &"town_hall":
		_draw_flag(Vector2(wall.end.x - 2.0, wall.position.y - 2.0), FLAG)


## Town Hall: a square clock tower rising from the ridge, with its own pyramid roof and a flag.
func _draw_clock_tower(wall: Color, roof: Color, apex: Vector2) -> void:
	var width := 26.0
	var height := 30.0
	var base := apex.y + 12.0
	var body := Rect2(Vector2(-width * 0.5, base - height), Vector2(width, height))
	draw_rect(body.grow(1.0), OUTLINE)
	draw_rect(body, wall)
	for k in range(1, 5):
		draw_line(Vector2(body.position.x, body.position.y + k * 6.0), Vector2(body.end.x, body.position.y + k * 6.0), wall.darkened(0.25), 1.0)
	var clock := Vector2(0, base - height * 0.55)
	draw_circle(clock, 7.0, OUTLINE)
	draw_circle(clock, 6.0, Color("f4f1ea"))
	for i in 12:
		draw_circle(clock + Vector2.RIGHT.rotated(i * PI / 6.0) * 5.0, 0.5, OUTLINE)
	draw_line(clock, clock + Vector2(0, -4.5), OUTLINE, 1.0)
	draw_line(clock, clock + Vector2(3, 0), OUTLINE, 1.0)
	var left := Vector2(-width * 0.5 - 4.0, body.position.y)
	var right := Vector2(width * 0.5 + 4.0, body.position.y)
	var peak := Vector2(0, body.position.y - 18.0)
	draw_colored_polygon(PackedVector2Array([left, right, peak]), roof)
	draw_colored_polygon(PackedVector2Array([left, Vector2(0, body.position.y), peak]), roof.darkened(0.15))
	draw_polyline(PackedVector2Array([left, right, peak, left]), OUTLINE, 1.0)
	_draw_flag(peak, FLAG)


## Open forge bay at the right of the Blacksmith's front: dark opening and a glowing hearth.
func _draw_forge_bay(at: Vector2) -> void:
	draw_rect(Rect2(at + Vector2(-1, -17), Vector2(18, 17)), OUTLINE)
	draw_rect(Rect2(at + Vector2(0, -16), Vector2(16, 16)), Color("2a1c14"))
	draw_circle(at + Vector2(8, -6), 8.0, Color("ff8a3d", 0.35))
	draw_rect(Rect2(at + Vector2(3, -8), Vector2(10, 6)), Color("ff8a3d"))
	draw_rect(Rect2(at + Vector2(5, -7), Vector2(6, 3)), Color("fff2a8"))


func _draw_column(rect: Rect2, wall: Color) -> void:
	draw_rect(rect, wall.lightened(0.15))
	draw_rect(rect, wall.darkened(0.3), false, 1.0)


func _draw_flag(at: Vector2, color: Color) -> void:
	draw_line(at, at + Vector2(0, -16), OUTLINE, 2.0)
	draw_colored_polygon(PackedVector2Array([at + Vector2(1, -16), at + Vector2(12, -13), at + Vector2(1, -9)]), color)
	draw_line(at + Vector2(1, -15), at + Vector2(10, -13), color.lightened(0.3), 1.0)


## Brick chimney on the roof with three smoke puffs rising and fading (animated, ANIMATED).
func _draw_chimney(at: Vector2, color: Color, tall: bool) -> void:
	var height := 22.0 if tall else 16.0
	draw_rect(Rect2(at + Vector2(-5, -height), Vector2(10, height + 2.0)), OUTLINE)
	draw_rect(Rect2(at + Vector2(-4, -height + 1.0), Vector2(8, height)), color)
	for k in range(1, int(height / 4.0)):
		var y := at.y - height + 1.0 + k * 4.0
		draw_line(Vector2(at.x - 4.0, y), Vector2(at.x + 4.0, y), color.darkened(0.3), 1.0)
	draw_rect(Rect2(at + Vector2(-4, -height + 1.0), Vector2(2, height)), color.lightened(0.15))
	draw_rect(Rect2(at + Vector2(-6, -height - 2.0), Vector2(12, 3)), OUTLINE)
	draw_rect(Rect2(at + Vector2(-5, -height - 1.5), Vector2(10, 2)), color.lightened(0.1))
	for i in 3:
		var t := fmod((_smoke_frame + i * 6) / 18.0, 1.0)
		draw_circle(at + Vector2(1.0 + t * 8.0 + i, -height - 6.0 - t * 18.0), 2.0 + t * 2.5, Color(SMOKE, SMOKE.a * (1.0 - t)))


## Striped scalloped awning centred at `at` (top edge).
func _draw_awning(at: Vector2, width: float, color_a: Color, color_b: Color) -> void:
	var stripes := maxi(int(width / 6.0), 3)
	var stripe := width / stripes
	for i in stripes:
		var color := color_a if i % 2 == 0 else color_b
		var x0 := at.x - width * 0.5 + i * stripe
		draw_colored_polygon(PackedVector2Array([Vector2(x0, at.y), Vector2(x0 + stripe, at.y), Vector2(x0 + stripe + 1.0, at.y + 7.0),
			Vector2(x0 + 1.0, at.y + 7.0)]), color)
		draw_circle(Vector2(x0 + stripe * 0.5 + 0.5, at.y + 7.0), stripe * 0.5, color)
	draw_line(Vector2(at.x - width * 0.5, at.y), Vector2(at.x + width * 0.5, at.y), OUTLINE, 1.0)
	draw_rect(Rect2(Vector2(at.x - width * 0.5, at.y + 10.0), Vector2(width, 2.0)), Color(0, 0, 0, 0.2))


## Board on a bracket sticking out of the wall, with an emblem (mug, coin, plate, bed).
func _draw_hanging_sign(at: Vector2, color: Color, emblem: StringName) -> void:
	draw_line(at + Vector2(-9, -5), at + Vector2(7, -5), OUTLINE, 2.0)
	draw_line(at + Vector2(-4, -5), at + Vector2(-4, -1), OUTLINE, 1.0)
	draw_line(at + Vector2(4, -5), at + Vector2(4, -1), OUTLINE, 1.0)
	draw_rect(Rect2(at + Vector2(-7, -1), Vector2(14, 10)), OUTLINE)
	draw_rect(Rect2(at + Vector2(-6, 0), Vector2(12, 8)), color.darkened(0.25))
	draw_rect(Rect2(at + Vector2(-6, 0), Vector2(12, 1)), color.lightened(0.1))
	match emblem:
		&"mug":
			draw_rect(Rect2(at + Vector2(-2.5, 2), Vector2(4, 5)), Color("f4f1ea"))
			draw_rect(Rect2(at + Vector2(1.5, 3), Vector2(1.5, 3)), Color("f4f1ea"))
		&"coin":
			draw_circle(at + Vector2(0, 4), 2.6, Color("b8892a"))
			draw_circle(at + Vector2(0, 4), 1.6, Color("f2c94c"))
		&"plate":
			draw_circle(at + Vector2(0, 4), 3.0, Color("f4f1ea"))
			draw_circle(at + Vector2(0, 4), 1.5, Color("c9503f"))
		&"bed":
			draw_rect(Rect2(at + Vector2(-4, 3), Vector2(8, 3)), Color("f4f1ea"))
			draw_rect(Rect2(at + Vector2(-4, 2), Vector2(3, 2)), Color("e8c35a"))


## Small roof window with its own little gable.
func _draw_dormer(at: Vector2, wall: Color, roof: Color) -> void:
	draw_rect(Rect2(at + Vector2(-7, -10), Vector2(14, 11)), OUTLINE)
	draw_rect(Rect2(at + Vector2(-6, -9), Vector2(12, 10)), wall)
	draw_rect(Rect2(at + Vector2(-3, -7), Vector2(6, 6)), OUTLINE)
	draw_rect(Rect2(at + Vector2(-2.5, -6.5), Vector2(5, 5)), GLASS)
	draw_colored_polygon(PackedVector2Array([at + Vector2(-9, -9), at + Vector2(9, -9), at + Vector2(0, -17)]), OUTLINE)
	draw_colored_polygon(PackedVector2Array([at + Vector2(-8, -9.5), at + Vector2(8, -9.5), at + Vector2(0, -16)]), roof.lightened(0.05))


func _draw_barrel(at: Vector2) -> void:
	draw_ellipse(at + Vector2(1, 0), 5.0, 2.0, Color(0, 0, 0, 0.3))
	draw_rect(Rect2(at + Vector2(-4, -10), Vector2(8, 10)), OUTLINE)
	draw_rect(Rect2(at + Vector2(-3, -10), Vector2(6, 10)), Color("8a5a30"))
	draw_rect(Rect2(at + Vector2(-3, -8), Vector2(6, 1)), Color("4a4a54"))
	draw_rect(Rect2(at + Vector2(-3, -3), Vector2(6, 1)), Color("4a4a54"))
	draw_ellipse(at + Vector2(0, -10), 3.5, 1.5, Color("6a4422"))


func _draw_crate(at: Vector2, color: Color) -> void:
	draw_rect(Rect2(at + Vector2(-4, -8), Vector2(8, 8)), OUTLINE)
	draw_rect(Rect2(at + Vector2(-3, -7), Vector2(6, 6)), color)
	draw_line(at + Vector2(-3, -7), at + Vector2(3, -1), color.darkened(0.35), 1.0)
	draw_rect(Rect2(at + Vector2(-3, -7), Vector2(6, 1)), color.lightened(0.25))


func _draw_lantern(at: Vector2) -> void:
	draw_circle(at, 5.0, Color(1.0, 0.8, 0.35, 0.3))
	draw_rect(Rect2(at + Vector2(-2, -3), Vector2(4, 5)), OUTLINE)
	draw_rect(Rect2(at + Vector2(-1.5, -2.5), Vector2(3, 4)), GLASS)


## Reincarnation Portal: a round stone dais with glowing runes and a stone ring arch around a
## swirling violet gate.
func _draw_portal() -> void:
	var style := _style()
	var trim: Color = style["trim"]
	var half := get_width() * 0.5
	var stone := Color("8a8496")
	draw_ellipse(Vector2(0, -14), half + 6.0, 14.0, Color(0, 0, 0, 0.25))
	draw_ellipse(Vector2(0, -14), half + 2.0, 13.0, OUTLINE)
	draw_ellipse(Vector2(0, -15), half + 1.0, 12.0, Color("6a6478"))
	draw_ellipse(Vector2(0, -18), half - 6.0, 9.0, Color("7d778c"))
	draw_ellipse(Vector2(0, -19), half - 8.0, 7.5, Color("2e2a45"))
	for i in 8:
		var angle := i * PI * 0.25
		draw_circle(Vector2(cos(angle) * (half - 12.0), -19.0 + sin(angle) * 6.0), 1.4, trim)
	var centre := Vector2(0, -46)
	var radius := 22.0
	for x: float in [-radius + 2.0, radius - 2.0]:
		draw_rect(Rect2(Vector2(x - 4.0, -34), Vector2(8, 16)), OUTLINE)
		draw_rect(Rect2(Vector2(x - 3.0, -33), Vector2(6, 15)), stone)
		draw_rect(Rect2(Vector2(x - 3.0, -33), Vector2(2, 15)), stone.lightened(0.15))
	draw_circle(centre, radius - 4.0, Color(trim, 0.25))
	draw_circle(centre, radius - 8.0, Color("6a3fb8", 0.6))
	draw_circle(centre, radius - 13.0, Color(trim, 0.55))
	draw_circle(centre, 4.0, Color(1, 1, 1, 0.8))
	var spin := _smoke_frame * 0.2
	for i in 4:
		draw_circle(centre + Vector2.RIGHT.rotated(i * PI * 0.5 + 0.4 + spin) * (radius - 9.0), 1.5, Color(1, 1, 1, 0.7))
	draw_arc(centre, radius, PI * 0.85, PI * 2.15, 24, OUTLINE, 8.0)
	draw_arc(centre, radius, PI * 0.85, PI * 2.15, 24, stone, 6.0)
	for i in 9:
		var angle := PI * 0.85 + i * PI * 1.3 / 8.0
		var direction := Vector2.RIGHT.rotated(angle)
		draw_line(centre + direction * (radius - 3.0), centre + direction * (radius + 3.0), stone.darkened(0.35), 1.0)


## Name (and level) on a dark plaque above the building.
func _draw_label(top: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var text := "%s%s" % [title, "  Lv%d" % level if level > 1 else ""]
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
	var plaque := Rect2(Vector2(top.x - size.x * 0.5 - 4.0, top.y - 6.0 - size.y), Vector2(size.x + 8.0, size.y + 2.0))
	draw_rect(plaque, PLAQUE)
	var trim: Color = _style()["trim"]
	draw_rect(plaque, Color(trim, 0.7), false, 1.0)
	var at := Vector2(top.x - size.x * 0.5, plaque.position.y + font.get_ascent(10) + 1.0)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 2, OUTLINE)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, LABEL)


static func _hash(x: int, y: int, salt: int) -> int:
	var h := (x * 73856093) ^ (y * 19349663) ^ (salt * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	return absi(h ^ (h >> 16))


static func _grow(points: PackedVector2Array, amount: float) -> PackedVector2Array:
	var grown := Geometry2D.offset_polygon(points, amount)
	return grown[0] if not grown.is_empty() else points
