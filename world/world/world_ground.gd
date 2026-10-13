extends Node2D
## Top-down ground for every region and bridge (WORLD_DESIGN.md → Biome identity, D52).
## Drawn once (static). The regions are plateaus over dark water (wave marks, foam at the cliff
## foot): each shows a cliff face below its bottom edge (the Town a stone retaining wall and a
## parapet around its other edges); bridges of planks cross the gaps; small rock ledges carry the
## dungeon entrances. The Town has a cobbled plaza, dirt roads with pebbles and kerbs, grass
## tufts, flowers, bushes, a pond and a back fence; the hunting regions have their own ground
## patterns (moss and leaves, cracked rock, pale paving).

const ROAD := Color("9c8566")
const ROAD_EDGE := Color("6f5d45")
const PEBBLE := Color("c2b293")
const WAVE := Color(0.62, 0.86, 0.92, 0.22)
const FOAM := Color(0.9, 0.97, 1.0, 0.35)
const DECK := Color("8a6a44")
const DECK_DARK := Color("5a4430")
const WALL := Color("4b4b55")
const WALL_LIGHT := Color("5e5e6a")
const WALL_CAP := Color("7a7a84")
const EDGE := Color(0, 0, 0, 0.35)
const CLIFF_DEPTH := 28.0
const CLIFF := Color("5a4430")
const CLIFF_GRASS := Color("3f6a36")
const COBBLE := Color("bdb6a4")
const COBBLE_DARK := Color("a69f8d")
const COBBLE_GAP := Color("7c7666")
const WATER := Color("3f86b8")
const WATER_LIGHT := Color("6bb0d8")
const SHORE := Color("c9b88a")
const FENCE := Color("8a6a44")
const FENCE_DARK := Color("5a4430")
const LEDGE := Color("5f5a52")
const FLOWERS: Array[Color] = [Color("f4f1ea"), Color("f2c94c"), Color("e8789a"), Color("a78bfa")]
const TILE := WorldService.TILE

var world: WorldService
## Tiles drawn as road inside the Town.
var road_tiles: Dictionary[Vector2i, bool] = {}
## Tiles drawn as cobbled plaza (around the Town Hall).
var plaza_tiles: Dictionary[Vector2i, bool] = {}
var pond: Rect2i = Rect2i()
## Dungeon entrance tiles (outside the regions): each gets a rock ledge.
var ledges: Array[Vector2i] = []


func setup(world_service: WorldService, town_roads: Dictionary[Vector2i, bool], town_plaza: Dictionary[Vector2i, bool] = {},
		town_pond: Rect2i = Rect2i(), entrance_tiles: Array[Vector2i] = []) -> void:
	world = world_service
	road_tiles = town_roads
	plaza_tiles = town_plaza
	pond = town_pond
	ledges = entrance_tiles
	queue_redraw()


func _draw() -> void:
	if world == null:
		return
	_draw_water()
	# Cliffs first: bridges and ledges are drawn over their overlaps.
	for region in world.get_regions():
		_cliff(region.tile_rect, region.is_town)
	for tile in ledges:
		_ledge(tile)
	for region in world.get_regions():
		var rect := region.tile_rect
		for gx in range(rect.position.x, rect.end.x):
			for gy in range(rect.position.y, rect.end.y):
				_ground_tile(region, Vector2i(gx, gy))
		var area := WorldService.rect_to_world(rect)
		draw_rect(area, EDGE, false, 2.0)
		if region.is_town:
			_town_edges(region)
		else:
			# Lit rim along the top edge.
			draw_line(area.position + Vector2(1, 1), Vector2(area.end.x - 1.0, area.position.y + 1.0), Color(1, 1, 0.85, 0.12), 2.0)
	for gate in world.get_gates():
		_bridge(gate)
	if pond.size != Vector2i.ZERO:
		_draw_pond()


# --- Water, cliffs, bridges ------------------------------------------------------------------------

## Gentle wave marks on the water around the plateaus (the clear colour is the water).
func _draw_water() -> void:
	var area := world.get_bounds(360.0)
	var step := 34.0
	for ix in int(area.size.x / step):
		for iy in int(area.size.y / step):
			var roll := _hash(ix, iy, 31) % 100
			if roll > 40:
				continue
			var at := area.position + Vector2(ix * step + (roll % 17), iy * step + (roll % 11))
			var width := 4.0 + (roll % 5)
			draw_line(at, at + Vector2(width, 0), WAVE, 1.0)
			draw_line(at + Vector2(width + 2.0, 3.0), at + Vector2(width * 2.0, 3.0), Color(WAVE, WAVE.a * 0.6), 1.0)


## Face below a plateau's bottom edge: earth with strata and hanging grass, or (Town) a stone
## retaining wall. Foam where it meets the water.
func _cliff(rect: Rect2i, stone: bool = false) -> void:
	var area := WorldService.rect_to_world(rect)
	var left := Vector2(area.position.x, area.end.y)
	var right := area.end
	var face := Rect2(left, Vector2(area.size.x, CLIFF_DEPTH))
	if stone:
		_stone_wall(face)
	else:
		draw_rect(face, CLIFF)
		for layer: float in [0.35, 0.68]:
			var y := face.position.y + face.size.y * layer
			draw_line(Vector2(face.position.x, y), Vector2(face.end.x, y), CLIFF.darkened(0.25), 1.0)
		_cliff_details(face, CLIFF)
		draw_line(left, right, CLIFF_GRASS, 4.0)
		_hanging_grass(left, right, CLIFF_GRASS)
	draw_line(Vector2(face.position.x, face.end.y), face.end, Color(0, 0, 0, 0.45), 2.0)
	draw_line(face.position, Vector2(face.position.x, face.end.y), Color(0, 0, 0, 0.4), 1.0)
	draw_line(Vector2(face.end.x, face.position.y), face.end, Color(0, 0, 0, 0.4), 1.0)
	_foam(Vector2(face.position.x, face.end.y), face.end)


## The Town sits behind a stone retaining wall over the moat (Evil Hunter Tycoon's town edge).
func _stone_wall(face: Rect2) -> void:
	draw_rect(face, WALL)
	var rows := 4
	var columns := int(face.size.x / 22.0)
	for row in rows:
		var y := face.position.y + face.size.y * row / rows
		draw_line(Vector2(face.position.x, y), Vector2(face.end.x, y), WALL.darkened(0.35), 1.0)
		var shift := 0.5 if row % 2 == 1 else 0.0
		for i in columns:
			var x := face.position.x + face.size.x * (i + shift) / columns
			if x > face.position.x and x < face.end.x:
				draw_line(Vector2(x, y), Vector2(x, y + face.size.y / rows), WALL.darkened(0.35), 1.0)
				# A lit block now and then.
				if _hash(i, row, 17) % 5 == 0:
					draw_rect(Rect2(Vector2(x + 1.0, y + 1.0), Vector2(face.size.x / columns - 2.0, face.size.y / rows - 2.0)), WALL_LIGHT)
	draw_line(face.position, Vector2(face.end.x, face.position.y), WALL_CAP, 5.0)
	draw_line(face.position + Vector2(0, -2), Vector2(face.end.x, face.position.y - 2.0), WALL_CAP.lightened(0.15), 1.0)


## Stone parapet just inside the Town's top, left and right edges.
func _town_edges(region: RegionDefinition) -> void:
	var area := WorldService.rect_to_world(region.tile_rect)
	var thickness := 6.0
	var bands := [
		Rect2(area.position, Vector2(area.size.x, thickness)),
		Rect2(area.position, Vector2(thickness, area.size.y)),
		Rect2(Vector2(area.end.x - thickness, area.position.y), Vector2(thickness, area.size.y)),
	]
	for band: Rect2 in bands:
		draw_rect(band, WALL_CAP)
		draw_rect(band, WALL.darkened(0.3), false, 1.0)
		var horizontal := band.size.x > band.size.y
		var length := band.size.x if horizontal else band.size.y
		for i in range(1, int(length / 14.0)):
			var at := band.position + (Vector2(i * 14.0, 0) if horizontal else Vector2(0, i * 14.0))
			var to := at + (Vector2(0, thickness) if horizontal else Vector2(thickness, 0))
			draw_line(at, to, WALL.darkened(0.3), 1.0)
	# Wooden fence a tile inside the back (top) edge.
	var fence_y := area.position.y + TILE * 0.5
	for i in range(0, region.tile_rect.size.x + 1):
		_fence_post(Vector2(area.position.x + i * TILE, fence_y))
	draw_line(Vector2(area.position.x, fence_y - 5.0), Vector2(area.end.x, fence_y - 5.0), FENCE, 2.0)
	draw_line(Vector2(area.position.x, fence_y - 9.0), Vector2(area.end.x, fence_y - 9.0), FENCE, 2.0)


func _fence_post(base: Vector2) -> void:
	draw_line(base, base + Vector2(0, -11), FENCE_DARK, 3.0)
	draw_line(base + Vector2(0, -11), base + Vector2(0, -12), FENCE.lightened(0.2), 3.0)


## Light streaks and darker cracks on a rock face (deterministic per position).
func _cliff_details(face: Rect2, color: Color) -> void:
	var steps := int(face.size.x / 9.0)
	for i in steps:
		var roll := _hash(int(face.position.x) + i, int(face.position.y), 21) % 100
		var top := Vector2(face.position.x + face.size.x * (i + 0.5) / steps, face.position.y + face.size.y * (0.15 + (roll % 30) / 100.0))
		if roll < 35:
			draw_line(top, top + Vector2(0, face.size.y * 0.25), color.lightened(0.15), 1.0)
		elif roll < 55:
			draw_line(top, top + Vector2(2, face.size.y * 0.2), color.darkened(0.35), 1.0)


## Grass tufts hanging over a cliff lip.
func _hanging_grass(a: Vector2, b: Vector2, color: Color) -> void:
	var steps := int((b - a).length() / 7.0)
	for i in steps:
		var roll := _hash(int(a.x) + i, int(a.y), 23) % 100
		if roll < 45:
			continue
		var at := a.lerp(b, (i + 0.5) / steps)
		var drop := 3.0 + (roll % 4)
		draw_colored_polygon(PackedVector2Array([at + Vector2(-2.5, 0), at + Vector2(2.5, 0), at + Vector2(0.5, drop)]), color)


## Foam where a face meets the water.
func _foam(a: Vector2, b: Vector2) -> void:
	for offset: float in [3.0, 6.0]:
		var alpha := FOAM.a * (1.0 if offset < 4.0 else 0.45)
		draw_line(a + Vector2(0, offset), b + Vector2(0, offset), Color(FOAM, alpha), 1.5)


## Plank deck across a gate corridor, reaching a little onto both banks (GateVisual adds rails).
func _bridge(gate: WorldService.Gate) -> void:
	var a := world.region_center(world.get_region(gate.region_a))
	var b := world.region_center(world.get_region(gate.region_b))
	var horizontal := absf(b.x - a.x) > absf(b.y - a.y)
	var deck := WorldService.rect_to_world(gate.tiles)
	deck = deck.grow_individual(10.0, 0.0, 10.0, 0.0) if horizontal else deck.grow_individual(0.0, 10.0, 0.0, 10.0)
	# Shadow on the water under the deck.
	draw_rect(Rect2(deck.position + Vector2(0, 6), deck.size), Color(0, 0, 0, 0.3))
	draw_rect(deck, DECK)
	var planks := int((deck.size.x if horizontal else deck.size.y) / 6.0)
	for i in range(1, planks):
		var t := float(i) / planks
		if horizontal:
			var x := deck.position.x + deck.size.x * t
			draw_line(Vector2(x, deck.position.y), Vector2(x, deck.end.y), DECK_DARK, 1.0)
		else:
			var y := deck.position.y + deck.size.y * t
			draw_line(Vector2(deck.position.x, y), Vector2(deck.end.x, y), DECK_DARK, 1.0)
	# Beams along the edges.
	if horizontal:
		draw_line(deck.position, Vector2(deck.end.x, deck.position.y), DECK_DARK, 3.0)
		draw_line(Vector2(deck.position.x, deck.end.y), deck.end, DECK_DARK, 3.0)
	else:
		draw_line(deck.position, Vector2(deck.position.x, deck.end.y), DECK_DARK, 3.0)
		draw_line(Vector2(deck.end.x, deck.position.y), deck.end, DECK_DARK, 3.0)
	draw_rect(deck, EDGE, false, 1.0)


## Rock ledge in the water under a dungeon entrance.
func _ledge(tile: Vector2i) -> void:
	var centre := WorldService.tile_center(tile)
	var slab := Rect2(centre - Vector2(TILE * 0.95, TILE * 0.75), Vector2(TILE * 1.9, TILE * 1.5))
	var face := Rect2(Vector2(slab.position.x, slab.end.y), Vector2(slab.size.x, 14.0))
	draw_rect(face, LEDGE.darkened(0.3))
	_cliff_details(face, LEDGE.darkened(0.3))
	_foam(Vector2(face.position.x, face.end.y), face.end)
	draw_rect(slab, LEDGE)
	draw_rect(Rect2(slab.position, Vector2(slab.size.x, 2.0)), LEDGE.lightened(0.2))
	draw_rect(slab, EDGE, false, 1.0)
	for i in 3:
		var at := slab.position + Vector2(_unit(tile, 40 + i) * slab.size.x, _unit(tile, 50 + i) * slab.size.y)
		draw_circle(at, 1.5, LEDGE.lightened(0.15))


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
		_cobbles(tile)
		return
	if road_tiles.has(tile):
		_tile(tile, ROAD)
		_pebbles(tile)
		# Kerb towards grass neighbours.
		for step in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
			if not road_tiles.has(tile + step) and not plaza_tiles.has(tile + step) and region.tile_rect.has_point(tile + step):
				_edge(tile, step, ROAD_EDGE)
		return
	_tile(tile, color)
	var roll := _hash(tile.x, tile.y, 5) % 100
	_tufts(tile, color, 2 + roll % 3)
	if roll < 38:
		_speckle(tile, color.lightened(0.16), 3)
	if roll < 7:
		_flowers(tile)
	elif roll > 95:
		_bush(tile, color)
	elif roll > 90:
		_blob(tile, color.darkened(0.12), 0.5)


## Rounded pond with ripple rings, lily pads and reeds.
func _draw_pond() -> void:
	var shore := _rounded(WorldService.rect_to_world(pond).grow(TILE * 0.2), 12.0)
	draw_colored_polygon(shore, SHORE)
	var water_rect := WorldService.rect_to_world(pond).grow(-TILE * 0.35)
	var water := _rounded(water_rect, 14.0)
	draw_colored_polygon(water, WATER)
	var centre := water_rect.get_center()
	for ring: float in [0.55, 0.3]:
		var points := PackedVector2Array()
		for corner in water:
			points.append(centre + (corner - centre) * ring)
		draw_polyline(points + PackedVector2Array([points[0]]), WATER_LIGHT, 1.0)
	draw_polyline(water + PackedVector2Array([water[0]]), WATER.darkened(0.3), 2.0)
	for pad: Vector2 in [Vector2(-14, 4), Vector2(10, -4), Vector2(2, 10)]:
		draw_circle(centre + pad, 3.5, Color("4f9a4a"))
		draw_circle(centre + pad + Vector2(1, -1), 1.2, Color("e8789a"))
	for reed: Vector2 in [Vector2(water_rect.position.x + 10.0, water_rect.end.y - 2.0), Vector2(water_rect.end.x - 12.0, water_rect.end.y - 3.0),
			Vector2(water_rect.end.x - 10.0, water_rect.position.y + 6.0)]:
		draw_line(reed, reed + Vector2(0, -9), Color("5f7a3a"), 1.5)
		draw_line(reed + Vector2(2, 0), reed + Vector2(3, -7), Color("5f7a3a"), 1.5)


## Rectangle with rounded corners as a polygon.
static func _rounded(rect: Rect2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var centres: Array[Vector2] = [rect.position + Vector2(r, r), Vector2(rect.end.x - r, rect.position.y + r),
		rect.end - Vector2(r, r), Vector2(rect.position.x + r, rect.end.y - r)]
	for i in 4:
		var start := PI + i * PI * 0.5
		for j in 5:
			points.append(centres[i] + Vector2.RIGHT.rotated(start + j * PI * 0.125) * r)
	return points


# --- Small decorations -----------------------------------------------------------------------------

func _tile(tile: Vector2i, color: Color) -> void:
	draw_rect(Rect2(Vector2(tile) * TILE, Vector2(TILE, TILE)), color)


## Tile-local point (0..1) in world space.
func _at(tile: Vector2i, u: float, v: float) -> Vector2:
	return WorldService.tile_to_world(Vector2(tile) + Vector2(u, v))


func _speckle(tile: Vector2i, color: Color, count: int) -> void:
	for i in count:
		var base := _at(tile, _unit(tile, i * 2 + 10), _unit(tile, i * 2 + 11))
		draw_line(base, base + Vector2(0, -2.5), color, 1.0)
		draw_line(base + Vector2(2, 0), base + Vector2(3, -2), color, 1.0)


## Grass tufts: a dark root shadow under three light blades.
func _tufts(tile: Vector2i, color: Color, count: int) -> void:
	for i in count:
		var base := _at(tile, 0.15 + _unit(tile, 60 + i) * 0.7, 0.15 + _unit(tile, 70 + i) * 0.7)
		draw_line(base + Vector2(-2, 0.5), base + Vector2(2, 0.5), color.darkened(0.25), 1.0)
		draw_line(base, base + Vector2(-1.5, -3), color.lightened(0.22), 1.0)
		draw_line(base, base + Vector2(0, -4), color.lightened(0.3), 1.0)
		draw_line(base, base + Vector2(1.5, -3), color.lightened(0.22), 1.0)


## Small round bush (decoration only; buildings may cover it).
func _bush(tile: Vector2i, color: Color) -> void:
	var centre := _at(tile, 0.5, 0.6)
	draw_ellipse(centre + Vector2(1, 1), 8.0, 3.0, Color(0, 0, 0, 0.25))
	for blob: Array in [[Vector2(-4, -3), 4.0], [Vector2(3, -3), 4.0], [Vector2(0, -6), 4.5]]:
		draw_circle(centre + blob[0], blob[1] + 1.0, Color("10140f"))
	for blob: Array in [[Vector2(-4, -3), 4.0], [Vector2(3, -3), 4.0], [Vector2(0, -6), 4.5]]:
		draw_circle(centre + blob[0], blob[1], color.darkened(0.15))
		draw_circle(centre + blob[0] + Vector2(-1, -1), blob[1] * 0.55, color.lightened(0.12))


## Plaza tile split into 3×3 cobblestones with mortar gaps and varied shades.
func _cobbles(tile: Vector2i) -> void:
	_tile(tile, COBBLE_GAP)
	var size := TILE / 3.0
	for i in 3:
		for j in 3:
			var roll := _hash(tile.x * 3 + i, tile.y * 3 + j, 13) % 3
			var color := COBBLE if roll == 0 else (COBBLE_DARK if roll == 1 else COBBLE.lerp(COBBLE_DARK, 0.5))
			var stone := Rect2(Vector2(tile) * TILE + Vector2(i, j) * size + Vector2(1, 1), Vector2(size - 2.0, size - 2.0))
			draw_rect(stone, color)
			draw_rect(Rect2(stone.position, Vector2(stone.size.x, 1.0)), color.lightened(0.15))


## Pebbles and a rut on a dirt road tile.
func _pebbles(tile: Vector2i) -> void:
	for i in 3:
		var at := _at(tile, 0.15 + _unit(tile, 80 + i) * 0.7, 0.15 + _unit(tile, 90 + i) * 0.7)
		draw_ellipse(at + Vector2(0, 0.6), 1.8, 0.9, ROAD_EDGE)
		draw_ellipse(at, 1.5, 0.8, PEBBLE)
	var rut := _at(tile, 0.2, 0.5)
	draw_line(rut, rut + Vector2(10, 2), ROAD.darkened(0.12), 1.0)


func _flowers(tile: Vector2i) -> void:
	var color := FLOWERS[_hash(tile.x, tile.y, 9) % FLOWERS.size()]
	for i in 3:
		var base := _at(tile, 0.25 + _unit(tile, 20 + i) * 0.5, 0.25 + _unit(tile, 30 + i) * 0.5)
		draw_line(base, base + Vector2(0, -3), Color("3f6a36"), 1.0)
		draw_circle(base + Vector2(0, -4), 1.6, color)


func _blob(tile: Vector2i, color: Color, size: float) -> void:
	var centre := _at(tile, 0.3 + _unit(tile, 40) * 0.4, 0.3 + _unit(tile, 41) * 0.4)
	draw_ellipse(centre, 11.0 * size, 7.0 * size, color)


func _cracks(tile: Vector2i, color: Color) -> void:
	var start := _at(tile, 0.2 + _unit(tile, 50) * 0.3, 0.2 + _unit(tile, 51) * 0.3)
	var mid := start + Vector2(_unit(tile, 52) * 12.0 - 4.0, 7)
	draw_polyline(PackedVector2Array([start, mid, mid + Vector2(6, 6)]), color, 1.0)


func _paving(tile: Vector2i, color: Color) -> void:
	var origin := Vector2(tile) * TILE
	draw_line(origin + Vector2(0, TILE * 0.5), origin + Vector2(TILE, TILE * 0.5), Color(color, 0.5), 1.0)
	draw_line(origin + Vector2(TILE * 0.5, 0), origin + Vector2(TILE * 0.5, TILE), Color(color, 0.5), 1.0)


## Dark line along one side of a tile (`step` points to the neighbour).
func _edge(tile: Vector2i, step: Vector2i, color: Color) -> void:
	var rect := Rect2(Vector2(tile) * TILE, Vector2(TILE, TILE))
	var a: Vector2
	var b: Vector2
	if step == Vector2i(1, 0):
		a = Vector2(rect.end.x - 1.0, rect.position.y)
		b = Vector2(rect.end.x - 1.0, rect.end.y)
	elif step == Vector2i(0, 1):
		a = Vector2(rect.position.x, rect.end.y - 1.0)
		b = Vector2(rect.end.x, rect.end.y - 1.0)
	elif step == Vector2i(-1, 0):
		a = Vector2(rect.position.x + 1.0, rect.position.y)
		b = Vector2(rect.position.x + 1.0, rect.end.y)
	else:
		a = Vector2(rect.position.x, rect.position.y + 1.0)
		b = Vector2(rect.end.x, rect.position.y + 1.0)
	draw_line(a, b, color, 2.0)


static func _hash(x: int, y: int, salt: int) -> int:
	var h := (x * 73856093) ^ (y * 19349663) ^ (salt * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	return absi(h ^ (h >> 16))


static func _unit(tile: Vector2i, salt: int) -> float:
	return float(_hash(tile.x, tile.y, salt) % 1000) / 1000.0
