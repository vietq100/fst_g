extends Node2D
## Isometric ground for every region and gate corridor (WORLD_DESIGN.md → Biome identity).
## Drawn once (static). Each region is a raised plateau with cliff faces; the Town has a cobbled
## plaza, dirt roads with kerbs, flowers, a pond and a back fence; the hunting regions have their
## own ground patterns (moss and leaves, cracked rock, pale paving).

const ROAD := Color("8f8a78")
const ROAD_EDGE := Color("6e6a5c")
const CORRIDOR := Color("837f72")
const WALL_LEFT := Color("45454e")
const WALL_RIGHT := Color("585863")
const WALL_CAP := Color("7a7a84")
const EDGE := Color(0, 0, 0, 0.3)
const CLIFF_DEPTH := 30.0
const CLIFF_LEFT := Color("5a4430")
const CLIFF_RIGHT := Color("6e5539")
const CLIFF_GRASS := Color("3f6a36")
const COBBLE := Color("b8b2a2")
const COBBLE_DARK := Color("9a9484")
const WATER := Color("3f86b8")
const WATER_LIGHT := Color("6bb0d8")
const SHORE := Color("c9b88a")
const FENCE := Color("8a6a44")
const FENCE_DARK := Color("5a4430")
const FLOWERS: Array[Color] = [Color("f4f1ea"), Color("f2c94c"), Color("e8789a"), Color("a78bfa")]

var world: WorldService
## Tiles drawn as road inside the Town.
var road_tiles: Dictionary[Vector2i, bool] = {}
## Tiles drawn as cobbled plaza (around the Town Hall).
var plaza_tiles: Dictionary[Vector2i, bool] = {}
var pond: Rect2i = Rect2i()


func setup(world_service: WorldService, town_roads: Dictionary[Vector2i, bool], town_plaza: Dictionary[Vector2i, bool] = {},
		town_pond: Rect2i = Rect2i()) -> void:
	world = world_service
	road_tiles = town_roads
	plaza_tiles = town_plaza
	pond = town_pond
	queue_redraw()


func _draw() -> void:
	if world == null:
		return
	# Cliffs first: neighbouring ground and corridors are drawn over their overlaps.
	for region in world.get_regions():
		_cliff(region.tile_rect, region.is_town)
	for gate in world.get_gates():
		_cliff(gate.tiles)
	for region in world.get_regions():
		var rect := region.tile_rect
		for gx in range(rect.position.x, rect.end.x):
			for gy in range(rect.position.y, rect.end.y):
				_ground_tile(region, Vector2i(gx, gy))
		var outline := WorldService.rect_polygon(rect)
		draw_polyline(outline + PackedVector2Array([outline[0]]), EDGE, 2.0)
		if region.is_town:
			_town_edges(region)
	for gate in world.get_gates():
		for gx in range(gate.tiles.position.x, gate.tiles.end.x):
			for gy in range(gate.tiles.position.y, gate.tiles.end.y):
				_tile(Vector2i(gx, gy), CORRIDOR)
				_speckle(Vector2i(gx, gy), CORRIDOR.darkened(0.2), 3)
	if pond.size != Vector2i.ZERO:
		_draw_pond()


# --- Cliffs ----------------------------------------------------------------------------------------

func _cliff(rect: Rect2i, stone: bool = false) -> void:
	var corners := WorldService.rect_polygon(rect)
	var left := corners[3]
	var bottom := corners[2]
	var right := corners[1]
	var down := Vector2(0, CLIFF_DEPTH)
	if stone:
		_stone_wall(left, bottom, right, down)
		return
	draw_colored_polygon(PackedVector2Array([left, bottom, bottom + down, left + down]), CLIFF_LEFT)
	draw_colored_polygon(PackedVector2Array([bottom, right, right + down, bottom + down]), CLIFF_RIGHT)
	# Grass lip and rock strata.
	draw_line(left, bottom, CLIFF_GRASS, 4.0)
	draw_line(bottom, right, CLIFF_GRASS.lightened(0.08), 4.0)
	for layer in [0.4, 0.72]:
		draw_line(left + down * layer, bottom + down * layer, CLIFF_LEFT.darkened(0.25), 1.0)
		draw_line(bottom + down * layer, right + down * layer, CLIFF_RIGHT.darkened(0.25), 1.0)
	draw_line(bottom, bottom + down, CLIFF_LEFT.darkened(0.35), 1.0)
	draw_line(left + down, bottom + down, Color(0, 0, 0, 0.4), 2.0)
	draw_line(bottom + down, right + down, Color(0, 0, 0, 0.4), 2.0)


## The Town sits behind a stone retaining wall over the moat (Evil Hunter Tycoon's town edge).
func _stone_wall(left: Vector2, bottom: Vector2, right: Vector2, down: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([left, bottom, bottom + down, left + down]), WALL_LEFT)
	draw_colored_polygon(PackedVector2Array([bottom, right, right + down, bottom + down]), WALL_RIGHT)
	for row in [0.25, 0.5, 0.75]:
		draw_line(left + down * row, bottom + down * row, WALL_LEFT.darkened(0.3), 1.0)
		draw_line(bottom + down * row, right + down * row, WALL_RIGHT.darkened(0.3), 1.0)
	# Vertical joints, staggered per row.
	var steps := int((bottom - left).length() / 22.0)
	for i in steps:
		var t := float(i) / steps
		for row in 3:
			var shift := 0.5 / steps if row % 2 == 1 else 0.0
			var a := left.lerp(bottom, clampf(t + shift, 0.0, 1.0)) + down * (row * 0.25)
			draw_line(a, a + down * 0.25, WALL_LEFT.darkened(0.3), 1.0)
			var b := bottom.lerp(right, clampf(t + shift, 0.0, 1.0)) + down * (row * 0.25)
			draw_line(b, b + down * 0.25, WALL_RIGHT.darkened(0.3), 1.0)
	draw_line(left, bottom, WALL_CAP, 5.0)
	draw_line(bottom, right, WALL_CAP.lightened(0.08), 5.0)
	draw_line(left + down, bottom + down, Color(0, 0, 0, 0.45), 2.0)
	draw_line(bottom + down, right + down, Color(0, 0, 0, 0.45), 2.0)


# --- Ground ----------------------------------------------------------------------------------------

func _ground_tile(region: RegionDefinition, tile: Vector2i) -> void:
	var variation := _hash(tile.x, tile.y, 1) % 100
	var color := region.ground_color
	if variation < 26:
		color = region.ground_alt_color
	elif variation > 88:
		color = region.ground_color.darkened(0.06)
	if region.is_town:
		_town_tile(region, tile, color)
		return
	_tile(tile, color)
	match region.props:
		RegionDefinition.Props.TREES:
			_speckle(tile, region.ground_color.lightened(0.18), 3)
			if variation % 7 == 0:
				_blob(tile, region.ground_color.darkened(0.25), 0.45)
			if variation % 11 == 0:
				_blob(tile, Color("7a5a2a", 0.5), 0.25)
		RegionDefinition.Props.ROCKS:
			_cracks(tile, region.ground_color.darkened(0.3))
			if variation % 9 == 0:
				_blob(tile, region.ground_color.lightened(0.1), 0.4)
		RegionDefinition.Props.COLUMNS:
			_paving(tile, region.ground_color.darkened(0.15))
			if variation % 8 == 0:
				_blob(tile, Color("5f7a4a", 0.55), 0.35)


func _town_tile(region: RegionDefinition, tile: Vector2i, color: Color) -> void:
	if pond.has_point(tile):
		_tile(tile, SHORE)
		return
	if plaza_tiles.has(tile):
		_tile(tile, COBBLE if (tile.x + tile.y) % 2 == 0 else COBBLE_DARK)
		_paving(tile, COBBLE_DARK.darkened(0.15))
		return
	if road_tiles.has(tile):
		_tile(tile, ROAD)
		_speckle(tile, ROAD_EDGE, 3)
		# Kerb towards grass neighbours.
		for step in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
			if not road_tiles.has(tile + step) and not plaza_tiles.has(tile + step) and region.tile_rect.has_point(tile + step):
				_edge(tile, step, ROAD_EDGE)
		return
	_tile(tile, color)
	var roll := _hash(tile.x, tile.y, 5) % 100
	if roll < 38:
		_speckle(tile, color.lightened(0.16), 4)
	if roll < 6:
		_flowers(tile)
	elif roll > 94:
		_blob(tile, color.darkened(0.12), 0.5)


func _town_edges(region: RegionDefinition) -> void:
	# Wooden fence along the two back edges (Town top corner), skipping nothing: gates sit on the
	# front edges.
	var rect := region.tile_rect
	for i in range(0, rect.size.x):
		_fence_post(Vector2(rect.position.x + i, rect.position.y))
	for j in range(0, rect.size.y):
		_fence_post(Vector2(rect.position.x, rect.position.y + j))
	var top := WorldService.tile_to_world(Vector2(rect.position))
	var right := WorldService.tile_to_world(Vector2(rect.end.x, rect.position.y))
	var left := WorldService.tile_to_world(Vector2(rect.position.x, rect.end.y))
	for end in [right, left]:
		draw_line(top + Vector2(0, -5), end + Vector2(0, -5), FENCE, 2.0)
		draw_line(top + Vector2(0, -9), end + Vector2(0, -9), FENCE, 2.0)


func _fence_post(tile_point: Vector2) -> void:
	var base := WorldService.tile_to_world(tile_point)
	draw_line(base, base + Vector2(0, -11), FENCE_DARK, 3.0)
	draw_line(base + Vector2(0, -11), base + Vector2(0, -12), FENCE.lightened(0.2), 3.0)


func _draw_pond() -> void:
	var shore := WorldService.rect_polygon(pond, 0.2)
	draw_colored_polygon(shore, SHORE)
	var water := WorldService.rect_polygon(pond, -0.35)
	draw_colored_polygon(water, WATER)
	var centre := (water[0] + water[2]) * 0.5
	for ring in [0.55, 0.3]:
		var points := PackedVector2Array()
		for corner in water:
			points.append(centre + (corner - centre) * ring)
		draw_polyline(points + PackedVector2Array([points[0]]), WATER_LIGHT, 1.0)
	draw_polyline(water + PackedVector2Array([water[0]]), WATER.darkened(0.3), 2.0)
	# Lily pads and reeds.
	for pad in [Vector2(-14, 4), Vector2(10, -4), Vector2(2, 10)]:
		draw_circle(centre + pad, 3.5, Color("4f9a4a"))
		draw_circle(centre + pad + Vector2(1, -1), 1.2, Color("e8789a"))
	for reed in [water[3] + Vector2(10, -2), water[2] + Vector2(-12, -3), water[1] + Vector2(-10, 3)]:
		draw_line(reed, reed + Vector2(0, -9), Color("5f7a3a"), 1.5)
		draw_line(reed + Vector2(2, 0), reed + Vector2(3, -7), Color("5f7a3a"), 1.5)


# --- Small decorations -----------------------------------------------------------------------------

func _tile(tile: Vector2i, color: Color) -> void:
	draw_colored_polygon(WorldService.rect_polygon(Rect2i(tile, Vector2i.ONE)), color)


## Tile-local point (0..1) in world space.
func _at(tile: Vector2i, u: float, v: float) -> Vector2:
	return WorldService.tile_to_world(Vector2(tile) + Vector2(u, v))


func _speckle(tile: Vector2i, color: Color, count: int) -> void:
	for i in count:
		var base := _at(tile, _unit(tile, i * 2 + 10), _unit(tile, i * 2 + 11))
		draw_line(base, base + Vector2(0, -2.5), color, 1.0)
		draw_line(base + Vector2(2, 0), base + Vector2(3, -2), color, 1.0)


func _flowers(tile: Vector2i) -> void:
	var color := FLOWERS[_hash(tile.x, tile.y, 9) % FLOWERS.size()]
	for i in 3:
		var base := _at(tile, 0.25 + _unit(tile, 20 + i) * 0.5, 0.25 + _unit(tile, 30 + i) * 0.5)
		draw_line(base, base + Vector2(0, -3), Color("3f6a36"), 1.0)
		draw_circle(base + Vector2(0, -4), 1.6, color)


func _blob(tile: Vector2i, color: Color, size: float) -> void:
	var centre := _at(tile, 0.3 + _unit(tile, 40) * 0.4, 0.3 + _unit(tile, 41) * 0.4)
	var points := PackedVector2Array([centre + Vector2(-14, 0) * size * 2.0, centre + Vector2(0, -7) * size * 2.0,
		centre + Vector2(14, 0) * size * 2.0, centre + Vector2(0, 7) * size * 2.0])
	draw_colored_polygon(points, color)


func _cracks(tile: Vector2i, color: Color) -> void:
	var start := _at(tile, 0.2 + _unit(tile, 50) * 0.3, 0.2 + _unit(tile, 51) * 0.3)
	var mid := start + Vector2(_unit(tile, 52) * 12.0 - 4.0, 5)
	draw_polyline(PackedVector2Array([start, mid, mid + Vector2(7, 4)]), color, 1.0)


func _paving(tile: Vector2i, color: Color) -> void:
	var a := _at(tile, 0.0, 0.5)
	var b := _at(tile, 1.0, 0.5)
	var c := _at(tile, 0.5, 0.0)
	var d := _at(tile, 0.5, 1.0)
	draw_line(a, b, Color(color, 0.5), 1.0)
	draw_line(c, d, Color(color, 0.5), 1.0)


## Dark line along one side of a tile (`step` points to the neighbour).
func _edge(tile: Vector2i, step: Vector2i, color: Color) -> void:
	var corners := WorldService.rect_polygon(Rect2i(tile, Vector2i.ONE))
	var points: PackedVector2Array
	if step == Vector2i(1, 0):
		points = PackedVector2Array([corners[1], corners[2]])
	elif step == Vector2i(0, 1):
		points = PackedVector2Array([corners[2], corners[3]])
	elif step == Vector2i(-1, 0):
		points = PackedVector2Array([corners[3], corners[0]])
	else:
		points = PackedVector2Array([corners[0], corners[1]])
	draw_line(points[0], points[1], color, 2.0)


static func _hash(x: int, y: int, salt: int) -> int:
	var h := (x * 73856093) ^ (y * 19349663) ^ (salt * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	return absi(h ^ (h >> 16))


static func _unit(tile: Vector2i, salt: int) -> float:
	return float(_hash(tile.x, tile.y, salt) % 1000) / 1000.0
