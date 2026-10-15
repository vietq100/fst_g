class_name MountainRange
extends Node2D
## Mountains filling the water behind the north-west (top-left) coast: a band of rock blocks (iso
## prisms, like the cliffs) up to `BAND` tiles wide, low foothills at the shore growing into snowy
## peaks farther out. Scenery only: no collision, never on land (it only covers water tiles and
## rises up-screen, away from the land). Drawn once, back to front.

const BAND := 9
## Only coast tiles left of this tile column get mountains on their north side.
const NORTH_LIMIT := 14
const OUTLINE := Color("1a1d26")
const ROCK_TOP := Color("9a9cab")
const ROCK_LEFT := Color("747687")
const ROCK_RIGHT := Color("565869")
const SNOW := Color("eef4fa")
const SNOW_SHADE := Color("b9c8d8")
const MOSS := Color("587a4e")
const MOSS_DARK := Color("3f5d3c")

var _world: WorldService
var _noise := FastNoiseLite.new()
var _detail := FastNoiseLite.new()
## Mountain tile -> its distance (tiles) from the coast.
var _tiles: Dictionary[Vector2i, int] = {}
var _order: Array[Vector2i] = []


func setup(world: WorldService) -> void:
	_world = world
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.seed = 2026
	_noise.frequency = 0.09
	_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_detail.seed = 77
	_detail.frequency = 0.31
	_collect()
	queue_redraw()


## Water tiles within BAND tiles of the Town's and the forest's coast on the upper-left part of the
## map: to the -x side of a coast tile with no land there (west coasts) and, for tiles with
## x < NORTH_LIMIT, to its -y side (the forest's north coast). The Hunter Gate island is left clear.
func _collect() -> void:
	_tiles.clear()
	var skip: Array[Rect2i] = []
	for region in _world.get_regions():
		if region.kind == RegionDefinition.Kind.GATE:
			skip.append(region.tile_rect.grow(BAND + 2))
	for region in _world.get_regions():
		if not (region.is_town or region.id == &"dark_forest"):
			continue
		for tile: Vector2i in _world.region_tile_list(region.id):
			for direction: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
				if direction == Vector2i(0, 1) and tile.x >= NORTH_LIMIT:
					continue
				var open := true
				for k in range(1, BAND + 2):
					if _world.is_land(tile - direction * k):
						open = false
						break
				if not open:
					continue
				for k in range(1, BAND + 1):
					var m: Vector2i = tile - direction * k
					if _world.is_land(m) or skip.any(func(rect: Rect2i) -> bool: return rect.has_point(m)):
						continue
					if not _tiles.has(m) or _tiles[m] > k:
						_tiles[m] = k
	_order = []
	for tile: Vector2i in _tiles:
		_order.append(tile)
	_order.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.x + a.y < b.x + b.y or (a.x + a.y == b.x + b.y and a.x < b.x))


func _height(tile: Vector2i) -> float:
	var k := float(_tiles[tile])
	# Foothills at the shore, rising with the distance, with ridges and crags from noise.
	var rise := smoothstep(0.0, 1.0, (k - 1.0) / float(BAND - 1))
	var ridge := _noise.get_noise_2d(tile.x, tile.y) * 0.5 + 0.5
	var crag := _detail.get_noise_2d(tile.x, tile.y) * 0.5 + 0.5
	return 26.0 + 260.0 * rise * (0.45 + 0.55 * ridge) + 28.0 * crag * rise + 14.0 * crag


func _draw() -> void:
	if _world == null:
		return
	for tile in _order:
		_draw_block(tile)


func _draw_block(tile: Vector2i) -> void:
	var corners := WorldService.rect_polygon(Rect2i(tile, Vector2i.ONE))
	var h := _height(tile)
	var up := Vector2(0, -h)
	var top := PackedVector2Array([corners[0] + up, corners[1] + up, corners[2] + up, corners[3] + up])
	var left := PackedVector2Array([corners[3], corners[2], corners[2] + up, corners[3] + up])
	var right := PackedVector2Array([corners[2], corners[1], corners[1] + up, corners[2] + up])
	var tone := float(hash(tile) % 100) / 100.0
	var shade := 0.94 + tone * 0.12
	draw_colored_polygon(left, ROCK_LEFT * Color(shade, shade, shade))
	draw_colored_polygon(right, ROCK_RIGHT * Color(shade, shade, shade))
	# Strata on both faces.
	for layer: float in [0.25, 0.5, 0.75]:
		draw_line(corners[3] + up * layer, corners[2] + up * layer, ROCK_LEFT.darkened(0.28), 1.0)
		draw_line(corners[2] + up * layer, corners[1] + up * layer, ROCK_RIGHT.darkened(0.28), 1.0)
	# A crack or two.
	if tone > 0.55:
		var x := corners[3].lerp(corners[2], 0.3 + tone * 0.4)
		draw_line(x + up * 0.15, x + up * 0.7, ROCK_LEFT.darkened(0.4), 1.0)
	# Moss and scrub on the lower part near the shore.
	if _tiles[tile] <= 2:
		var low := minf(h, 22.0)
		draw_colored_polygon(PackedVector2Array([corners[3], corners[2], corners[2] + Vector2(0, -low), corners[3] + Vector2(0, -low)]), MOSS_DARK)
		draw_colored_polygon(PackedVector2Array([corners[2], corners[1], corners[1] + Vector2(0, -low), corners[2] + Vector2(0, -low)]), MOSS.darkened(0.2))
	# Top: rock, or snow on the high ones (with a ragged snow line down the faces).
	var snowy := h > 175.0
	draw_colored_polygon(top, SNOW if snowy else ROCK_TOP)
	if snowy:
		var drip := 14.0 + 18.0 * tone
		draw_colored_polygon(PackedVector2Array([top[3], top[2], top[2] + Vector2(0, drip * 0.5), top[3] + Vector2(0, drip)]), SNOW_SHADE)
		draw_colored_polygon(PackedVector2Array([top[2], top[1], top[1] + Vector2(0, drip), top[2] + Vector2(0, drip * 0.5)]), SNOW_SHADE.darkened(0.12))
	draw_polyline(PackedVector2Array([top[3], top[0], top[1]]), Color(1, 1, 1, 0.25), 1.0)
	# Pines on the low foothills.
	if _tiles[tile] <= 3 and not snowy:
		var centre := (top[0] + top[2]) * 0.5
		for i in 2:
			_pine(centre + Vector2((i - 0.5) * 12.0, 3.0 * i - 2.0), 11.0 + 5.0 * float((hash(tile) >> i) % 3))
	draw_polyline(PackedVector2Array([corners[3] + up, corners[3], corners[2], corners[1], corners[1] + up]), OUTLINE, 1.0)
	draw_line(corners[2], corners[2] + up, OUTLINE, 1.0)


func _pine(base: Vector2, height: float) -> void:
	draw_rect(Rect2(base + Vector2(-1, -3), Vector2(2, 4)), Color("3b2e22"))
	for layer in 3:
		var y := base.y - 2.0 - layer * height * 0.28
		var width := (height * 0.34) * (1.0 - layer * 0.25)
		var tri := PackedVector2Array([Vector2(base.x - width, y), Vector2(base.x + width, y), Vector2(base.x, y - height * 0.42)])
		draw_colored_polygon(tri, Color("1c3a2a").lerp(Color("2f6a42"), layer * 0.4))
