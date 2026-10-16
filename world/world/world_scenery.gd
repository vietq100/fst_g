class_name WorldScenery
extends Node2D
## One piece of scenery in the water around the plateaus (D75, from the D61 top-down scenery): an islet
## with trees or palms, a lighthouse islet, a sandbar, rocks in foam, kelp, a drifting log, a shipwreck.
## Each piece is its own small node, drawn once, so pieces off screen are culled (one big drawing of the
## whole surroundings made the game lag, D74). Nothing blocks movement: it all lies outside the regions.
## Island shapes are flattened for the isometric view. Origin = the piece's centre on the water.

enum Kind { ISLET_TREES, ISLET_PALMS, LIGHTHOUSE, SANDBAR, ROCKS, KELP, LOG, WRECK }

const OUTLINE := Color("10140f")
const SAND := Color("d9c48e")
const SAND_DARK := Color("b39d68")
const GRASS := Color("4f7d3c")
const GRASS_LIGHT := Color("68994a")
const ROCK := Color("6f6a62")
const MOSS := Color("4f7a3a")
const FOAM := Color(0.91, 0.96, 1.0, 0.5)
const SHALLOW := Color("2a6470")
const LAGOON := Color("3a8a92")
const WOOD_DARK := Color("5a4430")
const TRUNK := Color("5a3f2a")
const TREE_TINTS: Array[Color] = [Color("3a7a3c"), Color("44843f"), Color("356f38")]
## Island radius (world px) per kind; others use their own sizes.
const RADIUS := {Kind.ISLET_TREES: 62.0, Kind.ISLET_PALMS: 56.0, Kind.LIGHTHOUSE: 70.0, Kind.SANDBAR: 34.0}
## Vertical squash of round shapes on the isometric water.
const FLAT := 0.5
const LIGHTHOUSE_HEIGHT := 54.0
## The lighthouse lamp relative to its islet's origin (WorldAmbience puts the beacon there).
const LIGHTHOUSE_LAMP := Vector2(4, -4 - LIGHTHOUSE_HEIGHT - 7.0)

var kind := Kind.ROCKS
## Varies the shape of copies of the same kind.
var salt := 0


## Room a piece needs around it (world px), for placement.
static func reach_of(piece: Kind) -> float:
	match piece:
		Kind.ISLET_TREES, Kind.ISLET_PALMS, Kind.LIGHTHOUSE:
			return 90.0
		Kind.WRECK:
			return 70.0
	return 40.0


func _draw() -> void:
	match kind:
		Kind.ISLET_TREES, Kind.ISLET_PALMS, Kind.LIGHTHOUSE:
			_islet()
		Kind.SANDBAR:
			_sandbar()
		Kind.ROCKS:
			_rocks()
		Kind.KELP:
			_kelp()
		Kind.LOG:
			_log()
		Kind.WRECK:
			_wreck()


## Organic island outline: a wobbly circle, flattened for the isometric view, grown by `grow` px.
func _blob(centre: Vector2, radius: float, grow: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 28:
		var angle := i * TAU / 28.0
		var wobble := 0.5 + 0.5 * sin(angle * 3.0 + salt) * cos(angle * 2.0 + salt * 0.7)
		var r := radius * (0.82 + 0.3 * wobble) + grow
		points.append(centre + Vector2(cos(angle) * r, sin(angle) * r * FLAT))
	return points


# --- Islets ----------------------------------------------------------------------------------------

## Shallow lagoon rings, foam, beach, grass top with tufts, shore rocks, then trees, palms or the
## lighthouse.
func _islet() -> void:
	var radius: float = RADIUS[kind]
	draw_colored_polygon(_blob(Vector2.ZERO, radius, 18.0), Color(SHALLOW, 0.35))
	draw_colored_polygon(_blob(Vector2.ZERO, radius, 10.0), Color(LAGOON, 0.35))
	draw_colored_polygon(_blob(Vector2.ZERO, radius, 4.0), Color(FOAM, 0.55))
	draw_colored_polygon(_blob(Vector2.ZERO, radius, 0.0), SAND_DARK)
	draw_colored_polygon(_blob(Vector2(0, -2), radius, -1.0), SAND)
	draw_colored_polygon(_blob(Vector2(0, -3), radius, -12.0), GRASS.darkened(0.15))
	draw_colored_polygon(_blob(Vector2(-1, -4), radius, -14.0), GRASS)
	for i in 10:
		var angle := _unit(i, 3) * TAU
		var at := Vector2(cos(angle), sin(angle) * FLAT) * _unit(i, 4) * (radius - 18.0) + Vector2(0, -4)
		draw_line(at, at + Vector2(-1.5, -3), GRASS_LIGHT, 1.0)
		draw_line(at, at + Vector2(1.5, -3), GRASS_LIGHT, 1.0)
	for i in 3:
		var angle := _unit(i, 5) * TAU
		var at := Vector2(cos(angle), sin(angle) * FLAT) * (radius - 4.0)
		draw_ellipse(at + Vector2(0, 1), 3.2, 2.0, ROCK.darkened(0.4))
		draw_ellipse(at, 3.0, 1.8, ROCK)
		draw_ellipse(at + Vector2(-1, -0.6), 1.3, 0.7, ROCK.lightened(0.25))
	if kind == Kind.LIGHTHOUSE:
		_lighthouse(Vector2(4, -4))
		return
	var count := 3 if kind == Kind.ISLET_TREES else 2
	var spots: Array[Vector2] = []
	for i in count:
		var angle := _unit(i, 6) * TAU
		spots.append(Vector2(cos(angle), sin(angle) * FLAT) * _unit(i, 7) * (radius - 30.0) + Vector2(0, -4))
	spots.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.y < b.y)
	for i in spots.size():
		if kind == Kind.ISLET_TREES:
			_tree(spots[i], TREE_TINTS[(salt + i) % TREE_TINTS.size()], 0.9)
		else:
			_palm(spots[i], i)


func _tree(at: Vector2, tint: Color, factor: float) -> void:
	draw_ellipse(at + Vector2(3, 0) * factor, 12.0 * factor, 4.0 * factor, Color(0, 0, 0, 0.25))
	draw_rect(Rect2(at + Vector2(-3, -12) * factor, Vector2(6, 12) * factor), OUTLINE)
	draw_rect(Rect2(at + Vector2(-2, -12) * factor, Vector2(4, 12) * factor), TRUNK)
	var blobs := [[Vector2(0, -20), 11.0], [Vector2(-8, -24), 8.0], [Vector2(8, -23), 8.0], [Vector2(-3, -31), 8.0], [Vector2(5, -31), 7.0]]
	for blob: Array in blobs:
		var offset: Vector2 = blob[0]
		draw_circle(at + offset * factor, (blob[1] + 1.0) * factor, OUTLINE)
	for blob: Array in blobs:
		var offset: Vector2 = blob[0]
		draw_circle(at + offset * factor, blob[1] * factor, tint.darkened(0.3))
	for blob: Array in blobs:
		var offset: Vector2 = blob[0]
		draw_circle(at + (offset + Vector2(-1, -1.5)) * factor, blob[1] * 0.8 * factor, tint)
	for i in [3, 4]:
		var blob: Array = blobs[i]
		var offset: Vector2 = blob[0]
		draw_circle(at + (offset + Vector2(-2, -3)) * factor, blob[1] * 0.4 * factor, tint.lightened(0.16))


## Leaning palm: segmented trunk, seven drooping fronds, coconuts.
func _palm(at: Vector2, index: int) -> void:
	var lean := (_unit(index, 9) - 0.5) * 14.0
	draw_ellipse(at + Vector2(8, 0), 13.0, 4.0, Color(0, 0, 0, 0.25))
	var top := at + Vector2(lean, -40)
	for i in 10:
		var a := at + Vector2(lean * pow(i / 10.0, 1.5), -i * 4.0)
		var b := at + Vector2(lean * pow((i + 1) / 10.0, 1.5), -(i + 1) * 4.0)
		draw_line(a, b, OUTLINE, 4.0)
		draw_line(a, b, Color("8a6a44") if i % 2 == 1 else Color("6a4a2a"), 2.5)
	for i in 7:
		var angle := -PI * 0.5 + (i - 3) * 0.68
		var tip := top + Vector2(cos(angle) * 22.0, sin(angle) * 9.0 + 9.0)
		var mid := top + Vector2(cos(angle) * 12.0, sin(angle) * 9.0 - 3.0)
		var frond := PackedVector2Array([top, mid, tip])
		draw_polyline(frond, OUTLINE, 4.0)
		draw_polyline(frond, Color("3f8a3a"), 2.5)
		draw_line(top, mid, Color("68b04a"), 1.0)
	draw_circle(top + Vector2(-1, 2), 2.0, Color("6a4a2a"))
	draw_circle(top + Vector2(2, 2), 2.0, Color("6a4a2a"))


## Tapered white tower with red bands, door, gallery, lamp room and red cap.
func _lighthouse(at: Vector2) -> void:
	var height := LIGHTHOUSE_HEIGHT
	var base_half := 9.0
	var top_half := 6.0
	draw_ellipse(at + Vector2(8, 0), 14.0, 4.0, Color(0, 0, 0, 0.28))
	draw_colored_polygon(PackedVector2Array([at + Vector2(-base_half - 1.0, 1), at + Vector2(base_half + 1.0, 1),
		at + Vector2(top_half + 1.0, -height - 1.0), at + Vector2(-top_half - 1.0, -height - 1.0)]), OUTLINE)
	draw_colored_polygon(PackedVector2Array([at + Vector2(-base_half, 0), at + Vector2(base_half, 0), at + Vector2(top_half, -height),
		at + Vector2(-top_half, -height)]), Color("f4f1ea"))
	for k in 3:
		var low := 0.15 + k * 0.3
		var high := low + 0.13
		var w0 := lerpf(base_half, top_half, low)
		var w1 := lerpf(base_half, top_half, high)
		draw_colored_polygon(PackedVector2Array([at + Vector2(-w0, -height * low), at + Vector2(w0, -height * low),
			at + Vector2(w1, -height * high), at + Vector2(-w1, -height * high)]), Color("c94a4a"))
	draw_colored_polygon(PackedVector2Array([at + Vector2(2, 0), at + Vector2(base_half, 0), at + Vector2(top_half, -height),
		at + Vector2(1, -height)]), Color(0, 0, 0, 0.12))
	draw_rect(Rect2(at + Vector2(-2, -10), Vector2(4, 8)), Color("4a3020"))
	draw_rect(Rect2(at + Vector2(-9, -height - 2.0), Vector2(18, 3)), OUTLINE)
	draw_rect(Rect2(at + Vector2(-8, -height - 1.5), Vector2(16, 2)), Color("5d5a55"))
	draw_rect(Rect2(at + Vector2(-5, -height - 12.0), Vector2(10, 10)), OUTLINE)
	draw_rect(Rect2(at + Vector2(-4, -height - 11.0), Vector2(8, 9)), Color("ffe08a"))
	draw_rect(Rect2(at + Vector2(-1, -height - 11.0), Vector2(2, 9)), Color("fff6cc"))
	draw_colored_polygon(PackedVector2Array([at + Vector2(-7, -height - 12.0), at + Vector2(7, -height - 12.0), at + Vector2(0, -height - 20.0)]), OUTLINE)
	draw_colored_polygon(PackedVector2Array([at + Vector2(-6, -height - 12.5), at + Vector2(6, -height - 12.5), at + Vector2(0, -height - 19.0)]), Color("c94a4a"))


# --- Water features --------------------------------------------------------------------------------

func _sandbar() -> void:
	var radius: float = RADIUS[Kind.SANDBAR]
	draw_colored_polygon(_blob(Vector2.ZERO, radius, 12.0), Color(LAGOON, 0.35))
	draw_colored_polygon(_blob(Vector2.ZERO, radius, 3.0), Color(FOAM, 0.45))
	draw_colored_polygon(_blob(Vector2.ZERO, radius, 0.0), SAND_DARK)
	draw_colored_polygon(_blob(Vector2(0, -1), radius, -3.0), SAND)
	for i in 4:
		draw_ellipse(Vector2((_unit(i, 8) - 0.5) * radius, (_unit(i, 9) - 0.5) * radius * FLAT), 1.6, 1.0, Color("f4f1ea"))
	draw_line(Vector2(-8, -2), Vector2(6, 3), Color("6a4a2a"), 2.0)


## Two or three rocks breaking the surface, with foam around them.
func _rocks() -> void:
	draw_ellipse(Vector2(0, 4), 22.0, 9.0, Color(FOAM, 0.35))
	draw_ellipse(Vector2(0, 4), 16.0, 6.0, Color(SHALLOW, 0.5))
	var stones := [Vector3(-6, 0, 7), Vector3(5, 2, 5), Vector3(1, -2, 4)]
	for i in 2 + salt % 2:
		var stone: Vector3 = stones[i]
		var at := Vector2(stone.x, stone.y)
		var r := stone.z
		var shape := PackedVector2Array([at + Vector2(-r, 2), at + Vector2(-r * 0.7, -r * 0.6), at + Vector2(0, -r),
			at + Vector2(r * 0.8, -r * 0.5), at + Vector2(r, 2)])
		draw_colored_polygon(BuildingVisual._grow(shape, 1.0), OUTLINE)
		draw_colored_polygon(shape, ROCK)
		draw_colored_polygon(PackedVector2Array([shape[1], shape[2], at + Vector2(1, -r * 0.3), at + Vector2(-r * 0.4, -r * 0.1)]), ROCK.lightened(0.2))
		draw_colored_polygon(PackedVector2Array([shape[2], shape[3], shape[4], at + Vector2(1, 2)]), ROCK.darkened(0.25))
		if i == 0:
			draw_circle(at + Vector2(-2, -r * 0.7), 1.6, MOSS)
	draw_line(Vector2(-14, 8), Vector2(-6, 8), Color(FOAM, 0.7), 1.0)
	draw_line(Vector2(6, 9), Vector2(14, 8), Color(FOAM, 0.7), 1.0)


func _kelp() -> void:
	for i in 7:
		var base := Vector2((_unit(i, 1) - 0.5) * 40.0, (_unit(i, 2) - 0.5) * 20.0)
		var strand := PackedVector2Array()
		for k in 5:
			strand.append(base + Vector2(sin(k * 0.9 + i) * 2.5, -k * 3.0))
		draw_polyline(strand, Color("1f5a3a", 0.75), 2.0)
		draw_polyline(strand, Color("3a8a52", 0.6), 1.0)


func _log() -> void:
	draw_ellipse(Vector2(0, 3), 18.0, 5.0, Color(FOAM, 0.3))
	draw_rect(Rect2(Vector2(-16, -4), Vector2(32, 8)), OUTLINE)
	draw_rect(Rect2(Vector2(-15, -3), Vector2(30, 6)), Color("7a5636"))
	draw_rect(Rect2(Vector2(-15, -3), Vector2(30, 2)), Color("9a7650"))
	draw_ellipse(Vector2(15, 0), 3.0, 4.0, Color("c9a26a"))
	draw_circle(Vector2(15, 0), 1.2, Color("7a5636"))
	draw_line(Vector2(-6, -3), Vector2(-10, -8), WOOD_DARK, 1.5)


## Broken hull with ribs, a snapped mast and a torn sail.
func _wreck() -> void:
	draw_ellipse(Vector2(0, 6), 56.0, 16.0, Color(LAGOON, 0.3))
	draw_ellipse(Vector2(0, 6), 40.0, 12.0, Color(FOAM, 0.3))
	var hull := PackedVector2Array([Vector2(-34, 0), Vector2(22, -6), Vector2(36, 2), Vector2(20, 10), Vector2(-26, 10)])
	var shadow := PackedVector2Array()
	for point in hull:
		shadow.append(point + Vector2(0, 1))
	draw_colored_polygon(shadow, OUTLINE)
	draw_colored_polygon(hull, Color("5a3a22"))
	for i in 6:
		var x := -26.0 + i * 9.0
		draw_line(Vector2(x, -3.0 - i * 0.6), Vector2(x + 2.0, 9.0), Color("3a2414"), 1.5)
	draw_colored_polygon(PackedVector2Array([Vector2(-20, 1), Vector2(18, -4), Vector2(18, 0), Vector2(-20, 5)]), Color("2a1a0e"))
	draw_line(Vector2(-4, -1), Vector2(-10, -30), OUTLINE, 4.0)
	draw_line(Vector2(-4, -1), Vector2(-10, -30), Color("6a4a2a"), 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-9, -27), Vector2(6, -20), Vector2(-6, -12)]), Color("d8cfb4", 0.85))
	draw_line(Vector2(-9, -27), Vector2(-6, -12), OUTLINE, 1.0)
	draw_line(Vector2(-30, 12), Vector2(-20, 12), Color(FOAM, 0.7), 1.0)
	draw_line(Vector2(24, 12), Vector2(34, 11), Color(FOAM, 0.7), 1.0)


## 0..1, stable per piece (its salt), index and channel.
func _unit(index: int, channel: int) -> float:
	var h := (salt * 73856093) ^ (index * 19349663) ^ (channel * 83492791)
	return float(posmod(h, 1000)) / 1000.0
