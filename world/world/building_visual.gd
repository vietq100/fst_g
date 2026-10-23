@tool
class_name BuildingVisual
extends Node2D
## Isometric building (BUILDING_DESIGN.md, D55, TOWN_DESIGN.md §4), in the style of 2.5D pixel
## management games: the box of the footprint rises from its diamond with two visible walls, the
## lit south-west face (+y side, with the door) and the shaded south-east face (+x side), in one
## of three materials (stone courses, wooden planks, plaster with a timber frame) with lit
## windows and an arched door with a step; a hip roof with a ridge along the tile x axis, shingle
## rows, a ridge cap and a round emblem on the front slope. One marker per building type; Lv2
## raises the plinth, adds height and a banner.
## Origin = the footprint's bottom (south) corner, so y-sorting with actors works. The footprint
## is `footprint` tiles (x axis runs up-right from the origin's left corner… see `_p`).
## `ghost` draws a translucent placement preview tinted green (valid) or red.

const OUTLINE := Color("16161c")
const SHADOW := Color(0, 0, 0, 0.3)
const SELECTION := Color("f2d16b")
const WINDOW := Color("ffcf6b")
const WINDOW_DARK := Color("c9792e")
const STONE := Color("8a8a84")
const TIMBER := Color("4a3424")
const DOOR := Color("4a3020")
const BANNER := Color("a83a3a")
const LABEL := Color("f4f1ea")
const PLAQUE := Color(0.08, 0.06, 0.05, 0.72)
const SMOKE := Color(0.82, 0.82, 0.86, 0.45)
const VALID := Color(0.4, 1.0, 0.45, 0.45)
const INVALID := Color(1.0, 0.35, 0.3, 0.45)
## Chimney smoke redraws at this rate.
const SMOKE_FPS := 6.0
const SMOKY: Array[StringName] = [&"tavern", &"blacksmith", &"house", &"restaurant", &"forge"]
## Roof eaves stick out this far (tiles) past the walls.
const EAVE := 0.12
## The ridge is this much (tiles) shorter than the eave line at each end (hip roof).
const HIP := 0.3
## Eave shadow band on the walls.
const EAVE_SHADOW := Color(0, 0, 0, 0.2)
## The south-east face is this much darker than the south-west one.
const SHADE := 0.28

enum Wall { STONE, WOOD, PLASTER }

const STYLES := {
	&"town_hall": {"wall": Color("d8ccb0"), "roof": Color("3c5a8c"), "trim": Color("e2c46b"), "height": 50.0, "wall_type": Wall.STONE},
	&"tavern": {"wall": Color("e3d3b4"), "roof": Color("8a3b2e"), "trim": Color("e2a64b"), "height": 36.0, "wall_type": Wall.PLASTER},
	&"blacksmith": {"wall": Color("6d6a64"), "roof": Color("3f4247"), "trim": Color("ff8a3d"), "height": 34.0, "wall_type": Wall.STONE},
	&"hospital": {"wall": Color("eee9de"), "roof": Color("3f8a83"), "trim": Color("c94a4a"), "height": 36.0, "wall_type": Wall.PLASTER},
	&"warehouse": {"wall": Color("8d7050"), "roof": Color("5b4430"), "trim": Color("b08d57"), "height": 34.0, "wall_type": Wall.WOOD},
	&"house": {"wall": Color("c09468"), "roof": Color("9a4b3a"), "trim": Color("e8d3a8"), "height": 30.0, "wall_type": Wall.WOOD},
	&"temple": {"wall": Color("e2dccb"), "roof": Color("b8913a"), "trim": Color("f2d16b"), "height": 42.0, "wall_type": Wall.STONE},
	&"trading_post": {"wall": Color("b08658"), "roof": Color("2f6f5e"), "trim": Color("f2d16b"), "height": 32.0, "wall_type": Wall.WOOD},
	&"restaurant": {"wall": Color("eadcc0"), "roof": Color("a83a3a"), "trim": Color("f4f1ea"), "height": 34.0, "wall_type": Wall.PLASTER},
	&"inn": {"wall": Color("e6d8bc"), "roof": Color("5b6c8f"), "trim": Color("f4f1ea"), "height": 38.0, "wall_type": Wall.PLASTER},
	&"academy": {"wall": Color("c4bfd2"), "roof": Color("5a3f8c"), "trim": Color("9fd6ff"), "height": 46.0, "wall_type": Wall.STONE},
	&"forge": {"wall": Color("55555c"), "roof": Color("8a3b24"), "trim": Color("ff7a2e"), "height": 34.0, "wall_type": Wall.STONE},
	&"market": {"wall": Color("d9b98a"), "roof": Color("c2453a"), "trim": Color("f2d16b"), "height": 30.0, "wall_type": Wall.WOOD},
	&"colosseum": {"wall": Color("c9bfa6"), "roof": Color("8a4b3a"), "trim": Color("e2c46b"), "height": 44.0, "wall_type": Wall.STONE},
	&"portal": {"wall": Color("3a3458"), "roof": Color("6a3fb8"), "trim": Color("c79bff"), "height": 30.0, "wall_type": Wall.STONE},
}

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


func _ready() -> void:
	# The name plate is translated in _draw; redraw when the language changes.
	if not Engine.is_editor_hint():
		Loc.locale_changed.connect(_on_locale_changed)


func _on_locale_changed(_locale: String) -> void:
	queue_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or ghost or not SMOKY.has(building_id):
		return
	_smoke_time += delta
	if _smoke_time >= 1.0 / SMOKE_FPS:
		_smoke_time -= 1.0 / SMOKE_FPS
		_smoke_frame += 1
		queue_redraw()


# --- Geometry --------------------------------------------------------------------------------------

## World offset (from the origin) of footprint-local tile coordinates (u along x, v along y,
## both from the footprint's top corner) lifted `z` px off the ground.
func _p(u: float, v: float, z: float = 0.0) -> Vector2:
	return WorldService.tile_to_world(Vector2(u, v)) - WorldService.tile_to_world(Vector2(footprint)) + Vector2(0, -z)


## Diamond of a footprint-local rectangle at height z: top, right, bottom, left.
func _quad(u: float, v: float, w: float, d: float, z: float = 0.0) -> PackedVector2Array:
	return PackedVector2Array([_p(u, v, z), _p(u + w, v, z), _p(u + w, v + d, z), _p(u, v + d, z)])


## Corners of the footprint relative to the origin: top (north), right (east), bottom (south,
## the origin), left (west).
func get_corners() -> PackedVector2Array:
	return _quad(0, 0, footprint.x, footprint.y)


## Polygon (relative to the origin) covering everything the building draws, for tap selection.
func get_hit_polygon() -> PackedVector2Array:
	var corners := get_corners()
	var up := Vector2(0, -get_height())
	return PackedVector2Array([corners[3], corners[2], corners[1], corners[1] + up, corners[0] + up, corners[3] + up])


## Height of the drawing above the origin.
func get_height() -> float:
	return -minf(_p(-EAVE, -EAVE, _eave_height()).y, _ridge_height_y()) + 6.0


## Style heights were drawn for 64 px tiles; scaled with the tile (D56).
const HEIGHT_SCALE := WorldService.TILE_WIDTH / 64.0


func _wall_height() -> float:
	return float(_style()["height"]) * HEIGHT_SCALE * (1.15 if level >= 2 else 1.0)


func _plinth() -> float:
	return 7.0 if level >= 3 else (5.0 if level >= 2 else 3.0)


## Height of the eave line (a little below the wall top so the roof overlaps it).
func _eave_height() -> float:
	return _plinth() + _wall_height() - 2.0


## How far the ridge rises above the eave line.
func _ridge_rise() -> float:
	return footprint.y * WorldService.HALF_HEIGHT + 9.0 + (3.0 if level >= 2 else 0.0)


func _ridge_height_y() -> float:
	return _p(HIP, footprint.y * 0.5, _eave_height() + _ridge_rise()).y


func _style() -> Dictionary:
	return STYLES.get(building_id, STYLES[&"house"])


# --- Drawing ---------------------------------------------------------------------------------------

func _draw() -> void:
	var style := _style()
	var fx := float(footprint.x)
	var fy := float(footprint.y)
	var tint := Color(1, 1, 1, 0.55) if ghost else Color.WHITE
	var wall: Color = style["wall"]
	var plinth := _plinth()
	var top := plinth + _wall_height()
	var n := _p(0, 0)
	var e := _p(fx, 0)
	var s := _p(fx, fy)
	var w := _p(0, fy)
	if ghost:
		draw_colored_polygon(get_corners(), VALID if ghost_valid else INVALID)
	else:
		var centre := _p(fx * 0.5, fy * 0.5)
		draw_ellipse(centre + Vector2(8, 4), (fx + fy) * WorldService.HALF_WIDTH * 0.5 + 10.0, (fx + fy) * WorldService.HALF_HEIGHT * 0.5 + 6.0, SHADOW)
	# Walls: south-west face (W → S, lit, with the door) and south-east face (S → E, shaded).
	var sw := _face(w, s, 0.0, top)
	var se := _face(s, e, 0.0, top)
	draw_colored_polygon(sw, wall * tint)
	draw_colored_polygon(se, wall.darkened(SHADE) * tint)
	if not ghost:
		_draw_plinth(w, s, plinth, false)
		_draw_plinth(s, e, plinth, true)
		_draw_wall_material(style, w, s, plinth, top, false)
		_draw_wall_material(style, s, e, plinth, top, true)
		# Contact shadow where the walls meet the plinth: the box reads as sitting on the ground.
		draw_colored_polygon(_face(w, s, plinth, plinth + 5.0), Color(0, 0, 0, 0.1))
		draw_colored_polygon(_face(s, e, plinth, plinth + 5.0), Color(0, 0, 0, 0.14))
		_draw_windows(style, w, s, plinth, top, [0.2, 0.8] if fx >= 3 else [0.25])
		# Lv2+ opens a second window on the shaded face (the front keeps room for the door and lantern).
		_draw_windows(style, s, e, plinth, top, [0.35, 0.7] if fy >= 3 or level >= 2 else [0.5], true)
		_draw_door(w, s, top)
		draw_colored_polygon(_face(w, s, top - 4.0, top), EAVE_SHADOW)
		draw_colored_polygon(_face(s, e, top - 4.0, top), EAVE_SHADOW)
	draw_polyline(sw + PackedVector2Array([sw[0]]), OUTLINE, 1.0)
	draw_polyline(se + PackedVector2Array([se[0]]), OUTLINE, 1.0)
	draw_line(s, s + Vector2(0, -top), OUTLINE, 1.5)
	var ridge := _draw_roof(style, tint)
	if not ghost:
		_draw_details(style, w, s, e, top, ridge)
	if selected:
		var ring := _quad(-0.12, -0.12, fx + 0.24, fy + 0.24)
		draw_polyline(ring + PackedVector2Array([ring[0]]), SELECTION, 2.0)
	if not title.is_empty() and not ghost:
		_draw_label((ridge[0] + ridge[1]) * 0.5)


## Wall face between ground points `a` and `b`, from height z0 to z1.
static func _face(a: Vector2, b: Vector2, z0: float, z1: float) -> PackedVector2Array:
	return PackedVector2Array([a + Vector2(0, -z0), b + Vector2(0, -z0), b + Vector2(0, -z1), a + Vector2(0, -z1)])


## Part of a face: fractions s0..s1 along a → b, heights z0..z1.
static func _patch(a: Vector2, b: Vector2, s0: float, s1: float, z0: float, z1: float) -> PackedVector2Array:
	return _face(a.lerp(b, s0), a.lerp(b, s1), z0, z1)


## Stone foundation band along the foot of a face.
func _draw_plinth(a: Vector2, b: Vector2, plinth: float, shaded: bool) -> void:
	var color := STONE.darkened(SHADE) if shaded else STONE
	draw_colored_polygon(_face(a, b, 0.0, plinth), color)
	draw_line(a + Vector2(0, -plinth), b + Vector2(0, -plinth), color.lightened(0.2), 1.0)
	var blocks := int(a.distance_to(b) / 10.0)
	for i in range(1, blocks):
		var at := a.lerp(b, float(i) / blocks)
		draw_line(at + Vector2(0, -plinth + 1.0), at, color.darkened(0.4), 1.0)
	draw_line(a, b, OUTLINE, 1.0)


## Stone courses with staggered joints, planks, or plaster with a timber frame, on one face.
func _draw_wall_material(style: Dictionary, a: Vector2, b: Vector2, z0: float, z1: float, shaded: bool) -> void:
	var wall: Color = style["wall"]
	if shaded:
		wall = wall.darkened(SHADE)
	var wall_type: int = style["wall_type"]
	var h := z1 - z0
	var length := a.distance_to(b)
	match wall_type:
		Wall.STONE:
			var rows := maxi(int(h / 6.0), 2)
			var columns := maxi(int(length / 12.0), 2)
			for k in range(1, rows):
				var z := z0 + h * k / rows
				draw_line(a + Vector2(0, -z), b + Vector2(0, -z), wall.darkened(0.35), 1.0)
				var shift := 0.5 if k % 2 == 1 else 0.0
				for i in columns:
					var t := (i + shift) / columns
					if t > 0.0 and t < 1.0:
						var at := a.lerp(b, t)
						draw_line(at + Vector2(0, -z), at + Vector2(0, -z + h / rows), wall.darkened(0.35), 1.0)
			draw_colored_polygon(_face(a, b, z1 - h / rows, z1), Color(1, 1, 1, 0.08))
		Wall.WOOD:
			var planks := maxi(int(h / 4.0), 2)
			for k in range(1, planks):
				var z := z0 + h * k / planks
				draw_line(a + Vector2(0, -z), b + Vector2(0, -z), wall.darkened(0.3), 1.0)
				draw_line(a + Vector2(0, -z + 1.0), b + Vector2(0, -z + 1.0), wall.lightened(0.08), 1.0)
		_:
			for t: float in [0.25, 0.75]:
				var at := a.lerp(b, t)
				draw_line(at + Vector2(0, -z0), at + Vector2(0, -z1), TIMBER, 2.0)
			var mid := z0 + h * 0.45
			draw_line(a + Vector2(0, -mid), b + Vector2(0, -mid), TIMBER, 2.0)
			# Diagonal braces in the upper panels.
			draw_line(a.lerp(b, 0.03) + Vector2(0, -mid - 2.0), a.lerp(b, 0.22) + Vector2(0, -z1 + 2.0), TIMBER, 1.5)
			draw_line(a.lerp(b, 0.97) + Vector2(0, -mid - 2.0), a.lerp(b, 0.78) + Vector2(0, -z1 + 2.0), TIMBER, 1.5)
	var post := wall.darkened(0.45) if wall_type == Wall.STONE else TIMBER
	draw_line(a + Vector2(0, -z0), a + Vector2(0, -z1), post, 2.0)
	draw_line(b + Vector2(0, -z0), b + Vector2(0, -z1), post, 2.0)
	draw_line(a + Vector2(0, -z1), b + Vector2(0, -z1), post, 2.0)


## Lit windows with a sill at fractions `spots` along a face.
func _draw_windows(style: Dictionary, a: Vector2, b: Vector2, z0: float, z1: float, spots: Array, shaded := false) -> void:
	var glass := WINDOW if building_id != &"hospital" else Color("bfe3ff")
	if shaded:
		glass = glass.darkened(0.15)
	var trim: Color = style["trim"]
	var half := 4.0 / a.distance_to(b)
	var sill := z0 + (z1 - z0) * 0.42
	for t: float in spots:
		var pane := _patch(a, b, t - half, t + half, sill, sill + 10.0)
		# Soft spill of light on the wall around the pane.
		draw_colored_polygon(_grow(pane, 4.0), Color(glass, 0.12))
		draw_colored_polygon(_grow(pane, 1.0), OUTLINE)
		draw_colored_polygon(pane, glass)
		# Reflection in the lower-left of the glass.
		draw_colored_polygon(_patch(a, b, t - half * 0.8, t - half * 0.2, sill + 1.0, sill + 3.0), Color(1, 1, 1, 0.35))
		draw_colored_polygon(_patch(a, b, t - half, t + half, sill + 7.0, sill + 10.0), glass.darkened(0.25) if building_id == &"hospital" else WINDOW_DARK)
		draw_line(a.lerp(b, t - half) + Vector2(0, -sill - 5.0), a.lerp(b, t + half) + Vector2(0, -sill - 5.0), OUTLINE, 1.0)
		draw_line(a.lerp(b, t) + Vector2(0, -sill), a.lerp(b, t) + Vector2(0, -sill - 10.0), OUTLINE, 1.0)
		draw_line(a.lerp(b, t - half * 1.3) + Vector2(0, -sill + 1.5), a.lerp(b, t + half * 1.3) + Vector2(0, -sill + 1.5), trim.lightened(0.2), 1.5)


## Fraction along the south-west face where the door stands: over the door tile
## (BuildingService.get_door_tile: the tile in front of the middle of the +y edge).
func _door_fraction() -> float:
	@warning_ignore("integer_division")
	return (float(footprint.x / 2) + 0.5) / footprint.x


## Arched door on the south-west face, with a stone step at its foot.
func _draw_door(a: Vector2, b: Vector2, top: float) -> void:
	var t := _door_fraction()
	var length := a.distance_to(b)
	var half := 6.0 / length
	var step := _patch(a, b, t - half * 1.5, t + half * 1.5, -1.0, 2.5)
	draw_colored_polygon(step, STONE.lightened(0.15))
	draw_polyline(step + PackedVector2Array([step[0]]), OUTLINE, 1.0)
	var door: PackedVector2Array
	if building_id == &"warehouse":
		door = _patch(a, b, t - half * 1.6, t + half * 1.6, 0.0, 20.0)
	else:
		var l := a.lerp(b, t - half)
		var r := a.lerp(b, t + half)
		var lm := a.lerp(b, t - half * 0.5)
		var rm := a.lerp(b, t + half * 0.5)
		door = PackedVector2Array([l, l + Vector2(0, -14), lm + Vector2(0, -19), rm + Vector2(0, -19), r + Vector2(0, -14), r])
	draw_colored_polygon(_grow(door, 1.2), OUTLINE)
	draw_colored_polygon(door, DOOR)
	var mid := a.lerp(b, t)
	draw_line(mid + Vector2(0, -1), mid + Vector2(0, -18), DOOR.darkened(0.4), 1.0)
	if building_id == &"warehouse":
		draw_line(door[0] + Vector2(1, -1), door[2] + Vector2(-1, 1), DOOR.darkened(0.4), 1.0)
		draw_line(door[1] + Vector2(-1, -1), door[3] + Vector2(1, 1), DOOR.darkened(0.4), 1.0)
	draw_circle(a.lerp(b, t + half * 0.5) + Vector2(0, -8), 1.0, Color("e8c547"))
	if building_id != &"warehouse":
		_draw_wall_lantern(a.lerp(b, t - half * 2.0) + Vector2(0, -16))
		# Lv3: a pair of lanterns flanks the door.
		if level >= 3:
			_draw_wall_lantern(a.lerp(b, t + half * 2.0) + Vector2(0, -16))
	# Keep the top of the wall clear of the door arch for short walls.
	if top < 24.0:
		pass


## Small lantern on a bracket beside the door, with a warm pool of light on the wall.
func _draw_wall_lantern(at: Vector2) -> void:
	draw_circle(at + Vector2(0, 1), 6.0, Color(1.0, 0.8, 0.35, 0.22))
	draw_line(at + Vector2(0, -4), at + Vector2(0, -2), OUTLINE, 1.0)
	draw_rect(Rect2(at - Vector2(2.5, 2.5), Vector2(5, 6)), OUTLINE)
	draw_rect(Rect2(at - Vector2(1.5, 1.5), Vector2(3, 4)), WINDOW)
	draw_rect(Rect2(at - Vector2(1.5, 1.5), Vector2(3, 1)), Color("fff2a8"))


## Hip roof: eave diamond just below the wall top, ridge along the tile x axis half-way back.
## Draws the back slope and hips first, then the front slope with shingle rows and the emblem.
## Returns the ridge ends [west, east].
func _draw_roof(style: Dictionary, tint: Color) -> PackedVector2Array:
	var roof: Color = style["roof"]
	var trim: Color = style["trim"]
	var fx := float(footprint.x)
	var fy := float(footprint.y)
	var z := _eave_height()
	var rz := z + _ridge_rise()
	var n := _p(-EAVE, -EAVE, z)
	var e := _p(fx + EAVE, -EAVE, z)
	var s := _p(fx + EAVE, fy + EAVE, z)
	var w := _p(-EAVE, fy + EAVE, z)
	var ridge_w := _p(HIP, fy * 0.5, rz)
	var ridge_e := _p(fx - HIP, fy * 0.5, rz)
	var back := PackedVector2Array([n, e, ridge_e, ridge_w])
	var hip_w := PackedVector2Array([n, ridge_w, w])
	var hip_e := PackedVector2Array([e, s, ridge_e])
	var front := PackedVector2Array([w, s, ridge_e, ridge_w])
	draw_colored_polygon(back, roof.lightened(0.1) * tint)
	draw_colored_polygon(hip_w, roof.lightened(0.05) * tint)
	draw_colored_polygon(hip_e, roof.darkened(0.3) * tint)
	draw_colored_polygon(front, roof * tint)
	if not ghost:
		# The front slope darkens toward the eave, under the overhang of the rows above.
		draw_colored_polygon(PackedVector2Array([w, s, s.lerp(ridge_e, 0.3), w.lerp(ridge_w, 0.3)]), Color(0, 0, 0, 0.08))
		for t: float in [0.16, 0.3, 0.43, 0.55, 0.65, 0.74, 0.82, 0.89]:
			draw_line(w.lerp(ridge_w, t), s.lerp(ridge_e, t), roof.darkened(0.3), 1.0)
			# Lit upper edge of each shingle row.
			draw_line(w.lerp(ridge_w, t + 0.025), s.lerp(ridge_e, t + 0.025), roof.lightened(0.12), 1.0)
		for t: float in [0.3, 0.55, 0.78]:
			draw_line(s.lerp(ridge_e, t), e.lerp(ridge_e, t), roof.darkened(0.45), 1.0)
		for t: float in [0.35, 0.7]:
			draw_line(n.lerp(ridge_w, t), w.lerp(ridge_w, t), roof.darkened(0.12), 1.0)
		# Hip edges, bright front eave, ridge cap.
		draw_line(w, ridge_w, roof.darkened(0.4), 2.0)
		draw_line(s, ridge_e, roof.darkened(0.45), 2.0)
		draw_line(n, ridge_w, roof.darkened(0.2), 1.0)
		draw_line(e, ridge_e, roof.darkened(0.35), 1.0)
		draw_line(w, s, roof.lightened(0.25), 2.0)
		draw_line(w, s, OUTLINE, 1.0)
		draw_line(s, e, OUTLINE, 1.0)
		draw_line(ridge_w + Vector2(-1, 0), ridge_e + Vector2(1, 0), OUTLINE, 4.0)
		draw_line(ridge_w, ridge_e, roof.lightened(0.35), 2.0)
		# Lv3: the ridge is capped in the trim colour with a finial at its middle.
		if level >= 3:
			draw_line(ridge_w, ridge_e, trim, 1.0)
			var finial := (ridge_w + ridge_e) * 0.5 + Vector2(0, -2)
			draw_circle(finial, 3.5, OUTLINE)
			draw_circle(finial, 2.5, trim)
		_draw_emblem((w + s + ridge_e + ridge_w) * 0.25, trim)
	var outline := PackedVector2Array([n, e, s, w])
	draw_polyline(outline + PackedVector2Array([outline[0]]), OUTLINE, 1.0)
	return PackedVector2Array([ridge_w, ridge_e])


## Round sign on the front slope with the building's glyph (the reference game's roof icons).
func _draw_emblem(at: Vector2, trim: Color) -> void:
	var glyph: Color = Color("f4f1ea")
	match building_id:
		&"town_hall", &"house", &"temple", &"portal":
			return
		_:
			pass
	draw_circle(at, 9.5, OUTLINE)
	draw_circle(at, 8.0, trim)
	draw_circle(at + Vector2(-2, -2), 3.0, Color(1, 1, 1, 0.18))
	match building_id:
		&"tavern":
			draw_rect(Rect2(at + Vector2(-3, -4), Vector2(6, 8)), glyph)
			draw_rect(Rect2(at + Vector2(3, -2), Vector2(2, 4)), glyph)
			draw_rect(Rect2(at + Vector2(-3, -5), Vector2(6, 2)), Color("fff2a8"))
		&"blacksmith":
			draw_line(at + Vector2(-5, 4), at + Vector2(4, -5), glyph, 2.5)
			draw_line(at + Vector2(2, -5), at + Vector2(5, -2), glyph, 2.0)
		&"hospital":
			draw_rect(Rect2(at + Vector2(-5, -1.5), Vector2(10, 3)), glyph)
			draw_rect(Rect2(at + Vector2(-1.5, -5), Vector2(3, 10)), glyph)
		&"warehouse":
			draw_rect(Rect2(at + Vector2(-5, -4), Vector2(10, 8)), glyph)
			draw_line(at + Vector2(-5, -4), at + Vector2(5, 4), trim, 1.0)
		&"trading_post":
			draw_circle(at, 4.5, glyph)
			draw_circle(at, 3.0, Color("f2c94c"))
		&"restaurant":
			draw_rect(Rect2(at + Vector2(-5, -1), Vector2(10, 4)), glyph)
			draw_line(at + Vector2(-2, -1), at + Vector2(-2, -6), glyph, 1.5)
			draw_line(at + Vector2(2, -1), at + Vector2(2, -6), glyph, 1.5)
		&"inn":
			draw_rect(Rect2(at + Vector2(-5, -1), Vector2(10, 4)), glyph)
			draw_rect(Rect2(at + Vector2(-5, -4), Vector2(3, 3)), Color("e8c35a"))
		&"colosseum":
			draw_line(at + Vector2(-5, 5), at + Vector2(5, -5), glyph, 2.0)
			draw_line(at + Vector2(5, 5), at + Vector2(-5, -5), glyph, 2.0)
		&"academy":
			draw_rect(Rect2(at + Vector2(-5, -4), Vector2(10, 8)), glyph)
			draw_line(at + Vector2(0, -4), at + Vector2(0, 4), trim, 1.0)
		&"market":
			# A coin sack.
			draw_colored_polygon(PackedVector2Array([at + Vector2(-5, 5), at + Vector2(5, 5), at + Vector2(4, -1), at + Vector2(2, -3),
				at + Vector2(-2, -3), at + Vector2(-4, -1)]), glyph)
			draw_line(at + Vector2(-2, -4), at + Vector2(2, -4), glyph, 2.0)
			draw_circle(at + Vector2(0, 2), 2.0, Color("f2c94c"))
		&"forge":
			draw_colored_polygon(PackedVector2Array([at + Vector2(-4, 4), at + Vector2(4, 4), at + Vector2(2, -1), at + Vector2(0, -6), at + Vector2(-2, -1)]), Color("ffd27a"))


func _draw_details(style: Dictionary, w: Vector2, s: Vector2, e: Vector2, top: float, ridge: PackedVector2Array) -> void:
	var trim: Color = style["trim"]
	var apex := (ridge[0] + ridge[1]) * 0.5
	var ground_dir := (s - w).normalized()
	# Sign spot: on the south-west face, left of the door, under the window line.
	var sign_at := w.lerp(s, 0.2) + Vector2(0, -top * 0.5)
	var door_at := w.lerp(s, _door_fraction())
	match building_id:
		&"market":
			# Produce stall in front: striped awning over crates of goods.
			var stall := s + Vector2(-34, -2)
			for k in 4:
				var stripe := Rect2(stall + Vector2(-12 + k * 6, -20), Vector2(6, 5))
				draw_rect(stripe, Color("f4f1ea") if k % 2 == 0 else trim.darkened(0.1).lerp(Color("c2453a"), 0.7))
			draw_rect(Rect2(stall + Vector2(-12, -20), Vector2(24, 5)), OUTLINE, false, 1.0)
			draw_line(stall + Vector2(-11, -15), stall + Vector2(-11, -2), OUTLINE, 1.5)
			draw_line(stall + Vector2(11, -15), stall + Vector2(11, -2), OUTLINE, 1.5)
			for offset: Vector2 in [Vector2(-6, 0), Vector2(3, 0)]:
				_draw_crate(stall + offset, Color("b08d57"))
			draw_circle(stall + Vector2(-6, -9), 1.6, Color("e05a4a"))
			draw_circle(stall + Vector2(-4, -9), 1.6, Color("f2c94c"))
			draw_circle(stall + Vector2(3, -9), 1.6, Color("6fbf5f"))
		&"town_hall":
			_draw_banner(ridge[0] + Vector2(2, 0))
			_draw_banner(ridge[1] + Vector2(-2, 0))
			# Clock over the door.
			var clock := door_at + Vector2(0, -top * 0.72)
			draw_circle(clock, 5.5, OUTLINE)
			draw_circle(clock, 4.5, Color("f4f1ea"))
			draw_line(clock, clock + Vector2(0, -3), OUTLINE, 1.0)
			draw_line(clock, clock + Vector2(2, 0), OUTLINE, 1.0)
		&"tavern":
			_draw_hanging_sign(sign_at, trim)
			draw_rect(Rect2(sign_at + Vector2(-2, 1), Vector2(4, 5)), Color("f4f1ea"))
			draw_rect(Rect2(sign_at + Vector2(2, 2), Vector2(1, 3)), Color("f4f1ea"))
			_draw_chimney(ridge[1] + Vector2(-8, 3), Color("7a5a48"), true)
		&"blacksmith":
			_draw_chimney(ridge[1] + Vector2(-8, 3), Color("4a4542"), true)
			# Forge glow and an anvil by the front corner.
			var anvil := s + ground_dir * -14.0 + Vector2(10, 2)
			draw_circle(anvil + Vector2(0, -4), 9.0, Color(trim, 0.25))
			draw_rect(Rect2(anvil + Vector2(-5, -5), Vector2(10, 3)), OUTLINE)
			draw_rect(Rect2(anvil + Vector2(-2, -2), Vector2(4, 2)), OUTLINE)
		&"hospital":
			var cross := door_at + Vector2(0, -top * 0.72)
			draw_rect(Rect2(cross - Vector2(6, 6), Vector2(12, 12)), OUTLINE)
			draw_rect(Rect2(cross - Vector2(5, 5), Vector2(10, 10)), Color("f4f1ea"))
			draw_rect(Rect2(cross - Vector2(4, 1.5), Vector2(8, 3)), trim)
			draw_rect(Rect2(cross - Vector2(1.5, 4), Vector2(3, 8)), trim)
		&"warehouse":
			for offset: Vector2 in [Vector2(-8, 0), Vector2(0, 0), Vector2(-4, -6)]:
				_draw_crate(w + Vector2(14, 10) + offset, trim)
		&"house":
			_draw_chimney(ridge[0] + Vector2(8, 3), Color("7a5a48"), true)
		&"trading_post":
			_draw_hanging_sign(sign_at, trim)
			draw_circle(sign_at + Vector2(0, 3.5), 2.5, Color("b8892a"))
			draw_circle(sign_at + Vector2(0, 3.5), 1.5, Color("f2c94c"))
			for offset: Vector2 in [Vector2(-6, 0), Vector2(2, 0)]:
				_draw_crate(s + Vector2(16, -2) + offset, Color("b08d57"))
		&"restaurant":
			_draw_hanging_sign(sign_at, trim)
			draw_circle(sign_at + Vector2(0, 3.5), 2.5, Color("c9503f"))
			_draw_chimney(ridge[1] + Vector2(-8, 3), Color("8a6a58"), true)
		&"inn":
			_draw_hanging_sign(sign_at, Color("5b6c8f"))
			draw_rect(Rect2(sign_at + Vector2(-3, 2), Vector2(6, 3)), Color("f4f1ea"))
			draw_rect(Rect2(sign_at + Vector2(-3, 1), Vector2(2, 2)), Color("e8c35a"))
		&"academy":
			_draw_banner(apex)
			var crest := door_at + Vector2(0, -top * 0.72)
			draw_circle(crest, 4.0, OUTLINE)
			draw_circle(crest, 3.0, trim)
		&"forge":
			_draw_chimney(ridge[1] + Vector2(-8, 3), Color("4a4542"), true)
			draw_circle(door_at + Vector2(0, -8), 11.0, Color(trim, 0.3))
		&"portal":
			var ring := apex + Vector2(0, -12)
			draw_circle(ring, 12.0, Color(trim, 0.2))
			draw_arc(ring, 9.0, 0.0, TAU, 24, OUTLINE, 4.0)
			draw_arc(ring, 9.0, 0.0, TAU, 24, trim, 2.0)
			draw_circle(ring, 6.0, Color("120d24"))
			draw_circle(ring + Vector2(-2, -2), 2.0, Color(trim, 0.6))
		&"temple":
			# Spire with a golden sun; pale columns either side of the door.
			draw_line(apex, apex + Vector2(0, -14), OUTLINE, 3.0)
			draw_line(apex, apex + Vector2(0, -14), trim.darkened(0.3), 1.0)
			draw_circle(apex + Vector2(0, -18), 5.0, OUTLINE)
			draw_circle(apex + Vector2(0, -18), 4.0, trim)
			for t: float in [-0.2, 0.2]:
				var at := door_at + ground_dir * (t * 60.0)
				draw_line(at + Vector2(0, -2), at + Vector2(0, -top + 4.0), Color(1, 1, 1, 0.5), 3.0)
	if level >= 2 and building_id != &"town_hall":
		_draw_banner(e + Vector2(2, -top))


func _draw_banner(at: Vector2) -> void:
	draw_line(at, at + Vector2(0, -16), OUTLINE, 2.0)
	draw_colored_polygon(PackedVector2Array([at + Vector2(1, -16), at + Vector2(12, -13), at + Vector2(1, -9)]), BANNER)
	draw_line(at + Vector2(1, -15), at + Vector2(10, -13), BANNER.lightened(0.3), 1.0)


## Wooden board on a bracket sticking out of the wall; the caller draws its emblem at +3 px.
func _draw_hanging_sign(at: Vector2, color: Color) -> void:
	draw_line(at + Vector2(-6, -4), at + Vector2(6, -4), OUTLINE, 2.0)
	draw_line(at + Vector2(-4, -4), at + Vector2(-4, -1), OUTLINE, 1.0)
	draw_line(at + Vector2(4, -4), at + Vector2(4, -1), OUTLINE, 1.0)
	draw_rect(Rect2(at + Vector2(-6, -1), Vector2(12, 9)), OUTLINE)
	draw_rect(Rect2(at + Vector2(-5, 0), Vector2(10, 7)), color.darkened(0.25))


func _draw_chimney(at: Vector2, color: Color, smoke: bool) -> void:
	draw_rect(Rect2(at + Vector2(-4, -14), Vector2(8, 16)), OUTLINE)
	draw_rect(Rect2(at + Vector2(-3, -13), Vector2(6, 14)), color)
	draw_rect(Rect2(at + Vector2(-3, -13), Vector2(2, 14)), color.lightened(0.15))
	draw_rect(Rect2(at + Vector2(-5, -16), Vector2(10, 3)), OUTLINE)
	if smoke:
		# Three puffs rising and drifting right, each fading as it climbs.
		for i in 3:
			var t := fmod((_smoke_frame + i * 6) / 18.0, 1.0)
			draw_circle(at + Vector2(1.0 + t * 8.0 + i, -18.0 - t * 18.0), 2.0 + t * 2.5, Color(SMOKE, SMOKE.a * (1.0 - t)))


func _draw_crate(at: Vector2, color: Color) -> void:
	draw_rect(Rect2(at + Vector2(-4, -8), Vector2(8, 8)), OUTLINE)
	draw_rect(Rect2(at + Vector2(-3, -7), Vector2(6, 6)), color)
	draw_line(at + Vector2(-3, -7), at + Vector2(3, -1), color.darkened(0.35), 1.0)
	draw_rect(Rect2(at + Vector2(-3, -7), Vector2(6, 1)), color.lightened(0.25))


## Name (and level) on a dark plaque above the roof.
func _draw_label(apex: Vector2) -> void:
	var font := ThemeDB.fallback_font
	# `title` is the building name key; translate here so a redraw shows the current language.
	var name_text := tr(title)
	var text := name_text
	if level > 1:
		# Autoloads do not run in the editor (@tool): keep a plain plaque there.
		text = "%s  Lv%d" % [name_text, level] if Engine.is_editor_hint() \
				else Loc.t("world.building.plaque_level", {"name": name_text, "level": level})
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
	var top := apex.y - 8.0 - size.y
	if building_id == &"temple" or building_id == &"portal":
		top -= 18.0
	var plaque := Rect2(Vector2(apex.x - size.x * 0.5 - 4.0, top), Vector2(size.x + 8.0, size.y + 2.0))
	draw_rect(plaque, PLAQUE)
	var trim: Color = _style()["trim"]
	draw_rect(plaque, Color(trim, 0.7), false, 1.0)
	var at := Vector2(apex.x - size.x * 0.5, top + font.get_ascent(10) + 1.0)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 2, OUTLINE)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, LABEL)


static func _grow(points: PackedVector2Array, amount: float) -> PackedVector2Array:
	var grown := Geometry2D.offset_polygon(points, amount)
	return grown[0] if not grown.is_empty() else points
