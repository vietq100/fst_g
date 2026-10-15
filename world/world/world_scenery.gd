class_name WorldScenery
extends Node2D
## Static scenery in the water around the map (D61), drawn once: islets with beaches, grass, rocks
## and trees or palms, one with a striped lighthouse; sandbars; rock clusters with foam; kelp;
## drifting logs; a shipwreck; lily pads and reeds off the Town's west shore; and a fishing dock
## on the Town's west edge. Nothing here blocks movement: it all lies outside the walkable regions.
## Animated pieces (the moored boat, the lighthouse beam, gulls, clouds) live in WorldAmbience.
## Positions are in tiles around the D27/D52 layout (regions over tiles 0..73).

## Camera bounds and water reach this far around the regions, so the scenery is visible.
const MARGIN := 420.0
const TILE := WorldService.TILE
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
const WOOD := Color("8a6a44")
const WOOD_DARK := Color("5a4430")
const POST := Color("3a2414")
const TRUNK := Color("5a3f2a")
const TREE_TINTS: Array[Color] = [Color("3a7a3c"), Color("44843f"), Color("356f38")]

enum Islet { LIGHTHOUSE, TREES, PALMS }

## [centre tile, radius in tiles, kind].
const ISLETS := [
	[Vector2(-7, -7), 3.8, Islet.LIGHTHOUSE], [Vector2(37, -8), 3.0, Islet.TREES], [Vector2(83, 30), 3.6, Islet.TREES],
	[Vector2(22, 84), 3.4, Islet.TREES], [Vector2(-9, 40), 3.0, Islet.PALMS], [Vector2(83, 82), 4.0, Islet.PALMS],
	[Vector2(-10, 14), 2.2, Islet.TREES], [Vector2(50, -9), 2.4, Islet.PALMS], [Vector2(85, 62), 2.6, Islet.TREES],
	[Vector2(-8, 84), 3.0, Islet.PALMS],
]
const SANDBARS: Array[Vector2] = [Vector2(12, -6), Vector2(85, 18), Vector2(34, 85), Vector2(-11, 58)]
const ROCKS: Array[Vector2] = [Vector2(-5, 22), Vector2(62, -6), Vector2(84, 46), Vector2(46, 83), Vector2(-6, 68),
	Vector2(24, -6), Vector2(80, 8), Vector2(6, 82)]
const KELP: Array[Vector2] = [Vector2(4, -9), Vector2(28, -10), Vector2(70, -9), Vector2(85, 40), Vector2(85, 71),
	Vector2(60, 85), Vector2(10, 85), Vector2(-12, 30), Vector2(-12, 70)]
const LOGS: Array[Vector2] = [Vector2(-6, 48), Vector2(77, -5), Vector2(40, 84)]
const WRECK := Vector2(66, 83)
## West end of the dock (tile); it runs east to the Town edge.
const DOCK := Vector2(-3, 9)
## The lighthouse lamp, relative to its islet centre (WorldAmbience pulses its light).
const LIGHTHOUSE_OFFSET := Vector2(4, -4)
const LIGHTHOUSE_HEIGHT := 54.0


static func tile_point(tile: Vector2) -> Vector2:
	return (tile + Vector2(0.5, 0.5)) * TILE


## World position of the lighthouse lamp.
static func lighthouse_lamp() -> Vector2:
	for islet: Array in ISLETS:
		if islet[2] == Islet.LIGHTHOUSE:
			return tile_point(islet[0]) + LIGHTHOUSE_OFFSET + Vector2(0, -LIGHTHOUSE_HEIGHT - 7.0)
	return Vector2.ZERO


## Where the boat is moored beside the dock.
static func boat_mooring() -> Vector2:
	return (DOCK + Vector2(-1.6, 2.2)) * TILE


func _draw() -> void:
	for i in KELP.size():
		_kelp(KELP[i], i)
	for i in SANDBARS.size():
		_sandbar(SANDBARS[i], i * 7 + 5)
	for log_tile in LOGS:
		_log(log_tile)
	for i in ISLETS.size():
		var islet: Array = ISLETS[i]
		_islet(islet[0], islet[1], islet[2], i * 17 + 3)
	for i in ROCKS.size():
		_rocks(ROCKS[i], i)
	_wreck(WRECK)
	_lilies()
	_dock()


# --- Islets ----------------------------------------------------------------------------------------

## Organic island outline: a noisy circle, flattened for the top-down view, grown by `grow` px.
func _blob(centre: Vector2, radius: float, salt: int, grow: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 28:
		var angle := i * TAU / 28.0
		var r := radius * (0.82 + 0.3 * WorldGround._noise(cos(angle) * 2.0 + salt, sin(angle) * 2.0 + salt, 1.3, salt)) + grow
		points.append(centre + Vector2(cos(angle) * r, sin(angle) * r * 0.8))
	return points


## Shallow lagoon rings, foam, beach, grass top with tufts, shore rocks, then trees, palms or the
## lighthouse.
func _islet(tile: Vector2, size: float, kind: int, salt: int) -> void:
	var centre := tile_point(tile)
	var radius := size * TILE
	draw_colored_polygon(_blob(centre, radius, salt, 18.0), Color(SHALLOW, 0.35))
	draw_colored_polygon(_blob(centre, radius, salt, 10.0), Color(LAGOON, 0.35))
	draw_colored_polygon(_blob(centre, radius, salt, 4.0), Color(FOAM, 0.55))
	draw_colored_polygon(_blob(centre, radius, salt, 0.0), SAND_DARK)
	draw_colored_polygon(_blob(centre + Vector2(0, -2), radius, salt, -1.0), SAND)
	draw_colored_polygon(_blob(centre + Vector2(0, -3), radius, salt, -9.0), GRASS.darkened(0.15))
	draw_colored_polygon(_blob(centre + Vector2(-1, -5), radius, salt, -11.0), GRASS)
	for i in 10:
		var angle := _unit(salt, i, 3) * TAU
		var at := centre + Vector2(cos(angle), sin(angle) * 0.8) * _unit(salt, i, 4) * (radius - 14.0) + Vector2(0, -5)
		draw_line(at, at + Vector2(-1.5, -3), GRASS_LIGHT, 1.0)
		draw_line(at, at + Vector2(1.5, -3), GRASS_LIGHT, 1.0)
	for i in 3:
		var angle := _unit(salt, i, 5) * TAU
		var at := centre + Vector2(cos(angle), sin(angle) * 0.8) * (radius - 4.0)
		draw_ellipse(at + Vector2(0, 1), 3.2, 2.0, ROCK.darkened(0.4))
		draw_ellipse(at, 3.0, 1.8, ROCK)
		draw_ellipse(at + Vector2(-1, -0.6), 1.3, 0.7, ROCK.lightened(0.25))
	match kind:
		Islet.LIGHTHOUSE:
			_lighthouse(centre + LIGHTHOUSE_OFFSET)
		Islet.TREES, Islet.PALMS:
			var count := int(size) + (1 if kind == Islet.TREES else 0)
			var spread := radius - (26.0 if kind == Islet.TREES else 24.0)
			var spots: Array[Vector2] = []
			for i in count:
				var angle := _unit(salt, i, 6) * TAU
				spots.append(centre + Vector2(cos(angle), sin(angle) * 0.6) * _unit(salt, i, 7) * spread + Vector2(0, -4))
			spots.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.y < b.y)
			for i in spots.size():
				if kind == Islet.TREES:
					_tree(spots[i], TREE_TINTS[posmod(int(spots[i].x), TREE_TINTS.size())], 0.9)
				else:
					_palm(spots[i], salt + i)


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
func _palm(at: Vector2, salt: int) -> void:
	var lean := (_unit(salt, 1, 9) - 0.5) * 14.0
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

func _sandbar(tile: Vector2, salt: int) -> void:
	var centre := tile_point(tile)
	var radius := 1.6 * TILE
	draw_colored_polygon(_blob(centre, radius, salt, 12.0), Color(LAGOON, 0.35))
	draw_colored_polygon(_blob(centre, radius, salt, 3.0), Color(FOAM, 0.45))
	draw_colored_polygon(_blob(centre, radius, salt, 0.0), SAND_DARK)
	draw_colored_polygon(_blob(centre + Vector2(0, -1), radius, salt, -3.0), SAND)
	for i in 4:
		draw_ellipse(centre + Vector2((_unit(salt, i, 8) - 0.5) * radius, (_unit(salt, i, 9) - 0.5) * radius * 0.6), 1.6, 1.0, Color("f4f1ea"))
	draw_line(centre + Vector2(-8, -2), centre + Vector2(6, 3), Color("6a4a2a"), 2.0)


## Two or three rocks breaking the surface, with foam around them.
func _rocks(tile: Vector2, salt: int) -> void:
	var centre := tile_point(tile)
	draw_ellipse(centre + Vector2(0, 4), 22.0, 9.0, Color(FOAM, 0.35))
	draw_ellipse(centre + Vector2(0, 4), 16.0, 6.0, Color(SHALLOW, 0.5))
	var stones := [Vector3(-6, 0, 7), Vector3(5, 2, 5), Vector3(1, -2, 4)]
	for i in 2 + salt % 2:
		var stone: Vector3 = stones[i]
		var at := centre + Vector2(stone.x, stone.y)
		var r := stone.z
		var shape := PackedVector2Array([at + Vector2(-r, 2), at + Vector2(-r * 0.7, -r * 0.6), at + Vector2(0, -r),
			at + Vector2(r * 0.8, -r * 0.5), at + Vector2(r, 2)])
		draw_colored_polygon(BuildingVisual._grow(shape, 1.0), OUTLINE)
		draw_colored_polygon(shape, ROCK)
		draw_colored_polygon(PackedVector2Array([shape[1], shape[2], at + Vector2(1, -r * 0.3), at + Vector2(-r * 0.4, -r * 0.1)]), ROCK.lightened(0.2))
		draw_colored_polygon(PackedVector2Array([shape[2], shape[3], shape[4], at + Vector2(1, 2)]), ROCK.darkened(0.25))
		if i == 0:
			draw_circle(at + Vector2(-2, -r * 0.7), 1.6, MOSS)
	draw_line(centre + Vector2(-14, 8), centre + Vector2(-6, 8), Color(FOAM, 0.7), 1.0)
	draw_line(centre + Vector2(6, 9), centre + Vector2(14, 8), Color(FOAM, 0.7), 1.0)


func _kelp(tile: Vector2, salt: int) -> void:
	var centre := tile_point(tile)
	for i in 7:
		var base := centre + Vector2((_unit(salt, i, 1) - 0.5) * 40.0, (_unit(salt, i, 2) - 0.5) * 24.0)
		var strand := PackedVector2Array()
		for k in 5:
			strand.append(base + Vector2(sin(k * 0.9 + i) * 2.5, -k * 3.0))
		draw_polyline(strand, Color("1f5a3a", 0.75), 2.0)
		draw_polyline(strand, Color("3a8a52", 0.6), 1.0)


func _log(tile: Vector2) -> void:
	var centre := tile_point(tile)
	draw_ellipse(centre + Vector2(0, 3), 18.0, 5.0, Color(FOAM, 0.3))
	draw_rect(Rect2(centre + Vector2(-16, -4), Vector2(32, 8)), OUTLINE)
	draw_rect(Rect2(centre + Vector2(-15, -3), Vector2(30, 6)), Color("7a5636"))
	draw_rect(Rect2(centre + Vector2(-15, -3), Vector2(30, 2)), Color("9a7650"))
	draw_ellipse(centre + Vector2(15, 0), 3.0, 4.0, Color("c9a26a"))
	draw_circle(centre + Vector2(15, 0), 1.2, Color("7a5636"))
	draw_line(centre + Vector2(-6, -3), centre + Vector2(-10, -8), WOOD_DARK, 1.5)


## Broken hull with ribs, a snapped mast and a torn sail.
func _wreck(tile: Vector2) -> void:
	var centre := tile_point(tile)
	draw_ellipse(centre + Vector2(0, 6), 56.0, 16.0, Color(LAGOON, 0.3))
	draw_ellipse(centre + Vector2(0, 6), 40.0, 12.0, Color(FOAM, 0.3))
	var hull := PackedVector2Array([centre + Vector2(-34, 0), centre + Vector2(22, -6), centre + Vector2(36, 2), centre + Vector2(20, 10),
		centre + Vector2(-26, 10)])
	var shadow := PackedVector2Array()
	for point in hull:
		shadow.append(point + Vector2(0, 1))
	draw_colored_polygon(shadow, OUTLINE)
	draw_colored_polygon(hull, Color("5a3a22"))
	for i in 6:
		var x := centre.x - 26.0 + i * 9.0
		draw_line(Vector2(x, centre.y - 3.0 - i * 0.6), Vector2(x + 2.0, centre.y + 9.0), Color("3a2414"), 1.5)
	draw_colored_polygon(PackedVector2Array([centre + Vector2(-20, 1), centre + Vector2(18, -4), centre + Vector2(18, 0), centre + Vector2(-20, 5)]), Color("2a1a0e"))
	draw_line(centre + Vector2(-4, -1), centre + Vector2(-10, -30), OUTLINE, 4.0)
	draw_line(centre + Vector2(-4, -1), centre + Vector2(-10, -30), Color("6a4a2a"), 2.0)
	draw_colored_polygon(PackedVector2Array([centre + Vector2(-9, -27), centre + Vector2(6, -20), centre + Vector2(-6, -12)]), Color("d8cfb4", 0.85))
	draw_line(centre + Vector2(-9, -27), centre + Vector2(-6, -12), OUTLINE, 1.0)
	draw_line(centre + Vector2(-30, 12), centre + Vector2(-20, 12), Color(FOAM, 0.7), 1.0)
	draw_line(centre + Vector2(24, 12), centre + Vector2(34, 11), Color(FOAM, 0.7), 1.0)


## Lily pads and reeds in the shallows off the Town's west shore.
func _lilies() -> void:
	for i in 14:
		var at := Vector2((-1.5 - _unit(i, 2, 7) * 2.0) * TILE, (14.0 + _unit(i, 3, 7) * 16.0) * TILE)
		draw_circle(at, 4.0, Color("4f9a4a"))
		draw_colored_polygon(PackedVector2Array([at, at + Vector2(4, -1), at + Vector2(4, 1)]), SHALLOW)
		if i % 4 == 0:
			draw_circle(at + Vector2(1, -1), 1.5, Color("f4b6c8"))
	for i in 6:
		var at := Vector2((-0.6 - _unit(i, 4, 7) * 0.6) * TILE, (26.0 + _unit(i, 5, 7) * 6.0) * TILE)
		for k in 3:
			draw_line(at + Vector2(k * 2.0, 0), at + Vector2(k * 2.0 + 1.0, -10.0 - k * 2.0), Color("5f7a3a"), 1.5)


## Plank dock from the Town's west edge, on posts, with a crate and a fishing rod.
func _dock() -> void:
	var start := DOCK * TILE + Vector2(0, 8)
	var size := Vector2(-DOCK.x * TILE, 28)
	for i in 4:
		var x := start.x + 6.0 + i * (size.x - 10.0) / 3.0
		for y: float in [start.y + size.y - 2.0, start.y + 2.0]:
			draw_rect(Rect2(Vector2(x - 2.0, y), Vector2(4, 10)), POST)
	draw_rect(Rect2(start + Vector2(0, 6), size), Color(0, 0, 0, 0.25))
	draw_rect(Rect2(start, size), WOOD)
	for i in range(1, int(size.x / 7.0)):
		draw_line(start + Vector2(i * 7.0, 0), start + Vector2(i * 7.0, size.y), WOOD_DARK, 1.0)
	draw_rect(Rect2(start, size), OUTLINE, false, 1.0)
	draw_rect(Rect2(start + Vector2(2, -6), Vector2(3, 8)), POST)
	draw_rect(Rect2(start + Vector2(2, size.y - 2.0), Vector2(3, 8)), POST)
	draw_rect(Rect2(start + Vector2(20, 4), Vector2(8, 8)), OUTLINE)
	draw_rect(Rect2(start + Vector2(21, 5), Vector2(6, 6)), Color("b08d57"))
	draw_line(start + Vector2(10, 18), start + Vector2(-14, -6), Color("5a3a22"), 1.5)
	draw_line(start + Vector2(-14, -6), start + Vector2(-16, 22), Color(0.91, 0.89, 0.82, 0.7), 1.0)


static func _unit(x: int, y: int, salt: int) -> float:
	return float(WorldGround._hash(x, y, salt) % 1000) / 1000.0
