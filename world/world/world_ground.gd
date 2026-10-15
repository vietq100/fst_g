class_name WorldGround
extends Node2D
## Top-down ground for every region and bridge (WORLD_DESIGN.md → Biome identity, D52, D57).
## Drawn once, and again when the Town layout changes (footpaths follow the doors).
## - Water: dark deep water (the clear colour) with lighter shallows around every plateau, wave
##   marks and foam at the cliff feet.
## - Plateaus: a cliff face below each region's bottom edge (earth bands, rock blocks, roots,
##   hanging grass; the Town a stone retaining wall with buttresses and moss), an inner shadow
##   along the edges and a lit top rim. Rock ledges carry the dungeon entrances; plank bridges
##   cross the gaps (GateVisual adds rails).
## - Ground colour comes from smooth value noise per biome (soft patches instead of a tile grid).
## - Town: grass tufts, flowers, clover, pebbles; dirt roads with wheel ruts, pebbles and grass
##   overhang; footpaths from every door to the nearest road or plaza; a cobbled plaza with a
##   curb and a compass mosaic; a pond; a stone parapet and a back fence.
## - Hunting regions: dirt trails from every bridge and dungeon entrance to the centre; Dark
##   Forest leaf litter, ferns, mushrooms, roots and moss; Goblin Cave gravel, cracks, stones,
##   bones and glowing crystals; Ancient Ruins broken paving slabs with cracks and moss.

const TILE := WorldService.TILE
const STEPS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
## Palette indices in BIOMES.
const DARK := 0
const MID := 1
const LIGHT := 2
const DETAIL := 3
## Region.props → [dark, mid, light, detail] ground colours.
const BIOMES := {
	RegionDefinition.Props.NONE: [Color("3d6331"), Color("4f7d3c"), Color("68994a"), Color("86b45c")],
	RegionDefinition.Props.TREES: [Color("16302a"), Color("1f4034"), Color("2c5540"), Color("3f7050")],
	RegionDefinition.Props.ROCKS: [Color("3e3329"), Color("54463a"), Color("6a5a4a"), Color("8a7660")],
	RegionDefinition.Props.COLUMNS: [Color("5e5d53"), Color("72716a"), Color("8a8980"), Color("a8a79c")],
}
## Deep water is the clear colour (WorldMap sets it).
const WATER_DEEP := Color("163846")
const WATER_SHALLOW := Color("2a6470")
const WATER_DEPTH := Color("0f2c38")
## Water (patches, waves) is drawn this far around the regions; the camera stops before it.
const WATER_MARGIN := 520.0
const WAVE := Color(0.62, 0.86, 0.92, 0.2)
const FOAM := Color(0.91, 0.96, 1.0, 0.45)
const ROAD := Color("a48a62")
const ROAD_DARK := Color("7a6446")
const ROAD_LIGHT := Color("bba377")
const PEBBLE := Color("cbb998")
const TRAIL := Color("5a4630")
const TRAIL_EDGE := Color("3c2e20")
const TRAIL_RUINS := Color("8a8270")
const TRAIL_RUINS_EDGE := Color("5e594c")
const COBBLE := Color("c3bcaa")
const COBBLE_DARK := Color("a8a08c")
const COBBLE_GAP := Color("6f6a5c")
const CURB := Color("8a8474")
const CLIFF_DEPTH := 40.0
const CLIFF_TOP := Color("7a5a3a")
const CLIFF_MID := Color("5f442c")
const CLIFF_LOW := Color("44301f")
const ROOT := Color("2e4a24")
const WALL := Color("55555f")
const WALL_LIGHT := Color("6c6c78")
const WALL_DARK := Color("3c3c46")
const WALL_CAP := Color("8a8a94")
const MOSS := Color("4f7a3a")
const DECK := Color("8a6a44")
const DECK_DARK := Color("5a4430")
const LEDGE := Color("5f5a52")
const WATER := Color("3f86b8")
const WATER_LIGHT := Color("6bb0d8")
const SHORE := Color("c9b88a")
const FENCE := Color("8a6a44")
const FENCE_DARK := Color("5a4430")
const OUTLINE := Color("10140f")
const FLOWERS: Array[Color] = [Color("f4f1ea"), Color("f2c94c"), Color("e8789a"), Color("a78bfa"), Color("ff9a5c")]
const MUSHROOMS: Array[Color] = [Color("c94a4a"), Color("d9b356"), Color("9aa0a6")]
const CRYSTALS: Array[Color] = [Color("b07cff"), Color("6fd3ff")]
## Footpath search gives up after this many tiles (a door with no way out keeps no path).
const MAX_PATH_SEARCH := 600

var world: WorldService
## Tiles drawn as road inside the Town.
var road_tiles: Dictionary[Vector2i, bool] = {}
## Tiles drawn as cobbled plaza (around the Town Hall).
var plaza_tiles: Dictionary[Vector2i, bool] = {}
var pond: Rect2i = Rect2i()
## Dungeon entrance tiles (outside the regions): each gets a rock ledge and a trail.
var ledges: Array[Vector2i] = []
## Footprints of the placed buildings (set_footprints); their doors get footpaths.
var footprints: Array[Rect2i] = []
## Footpath tiles from the doors to the roads (computed from `footprints`).
var path_tiles: Dictionary[Vector2i, bool] = {}
## Tiles a hunting-region trail crosses (props keep off them).
var trail_tiles: Dictionary[Vector2i, bool] = {}


func setup(world_service: WorldService, town_roads: Dictionary[Vector2i, bool], town_plaza: Dictionary[Vector2i, bool] = {},
		town_pond: Rect2i = Rect2i(), entrance_tiles: Array[Vector2i] = []) -> void:
	world = world_service
	road_tiles = town_roads
	plaza_tiles = town_plaza
	pond = town_pond
	ledges = entrance_tiles
	trail_tiles.clear()
	for region in world.get_regions():
		if region.is_town:
			continue
		for line in _region_trails(region):
			for point in _dense(line, 8.0):
				var tile := WorldService.tile_at(point)
				trail_tiles[tile] = true
				for step in STEPS:
					trail_tiles[tile + step] = true
	queue_redraw()


## The placed buildings changed: recompute the footpaths and redraw.
func set_footprints(rects: Array[Rect2i]) -> void:
	footprints = rects
	path_tiles = _footpaths()
	queue_redraw()


func is_trail_tile(tile: Vector2i) -> bool:
	return trail_tiles.has(tile)


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
		_draw_region(region)
	_draw_roads()
	_draw_paths()
	_draw_plaza()
	if pond.size != Vector2i.ZERO:
		_draw_pond()
	var town := world.get_town()
	if town != null:
		_town_edges(town)
	for gate in world.get_gates():
		_bridge(gate)


# --- Water, cliffs, bridges ------------------------------------------------------------------------

## Soft darker / lighter patches (depth), shallows around every plateau, then gentle wave marks
## (the clear colour is the deep water).
func _draw_water() -> void:
	var patches := world.get_bounds(WATER_MARGIN + 64.0)
	var step := 64.0
	for ix in int(patches.size.x / step):
		for iy in int(patches.size.y / step):
			var n := _noise(ix, iy, 3.5, 23)
			var centre := patches.position + Vector2(ix * step + _hash(ix, iy, 24) % 40 - 20.0, iy * step + _hash(ix, iy, 25) % 40 - 20.0)
			if n < 0.4:
				draw_ellipse(centre, 56.0, 30.0, Color(WATER_DEPTH, 0.3 * (0.4 - n) / 0.4))
			elif n > 0.62:
				draw_ellipse(centre, 56.0, 30.0, Color(WATER_SHALLOW, 0.18 * (n - 0.62) / 0.38))
	for region in world.get_regions():
		var area := WorldService.rect_to_world(region.tile_rect)
		area.size.y += CLIFF_DEPTH
		for band: Array in [[36.0, 0.16], [22.0, 0.2], [10.0, 0.26]]:
			var grow: float = band[0]
			var strength: float = band[1]
			draw_colored_polygon(_rounded(area.grow(grow), grow), Color(WATER_SHALLOW, strength))
	var bounds := world.get_bounds(WATER_MARGIN)
	step = 34.0
	for ix in int(bounds.size.x / step):
		for iy in int(bounds.size.y / step):
			var roll := _hash(ix, iy, 31) % 100
			if roll > 24:
				continue
			var at := bounds.position + Vector2(ix * step + (roll % 17), iy * step + (roll % 11))
			var width := 4.0 + (roll % 5)
			draw_line(at, at + Vector2(width, 0), WAVE, 1.0)
			draw_line(at + Vector2(width + 2.0, 3.0), at + Vector2(width * 2.0, 3.0), Color(WAVE, 0.12), 1.0)


## Face below a plateau's bottom edge: earth bands with rock blocks, roots and hanging grass, or
## (Town) a stone retaining wall. Shadow and foam where it meets the water.
func _cliff(rect: Rect2i, stone: bool = false) -> void:
	var area := WorldService.rect_to_world(rect)
	var face := Rect2(Vector2(area.position.x, area.end.y), Vector2(area.size.x, CLIFF_DEPTH))
	if stone:
		_stone_wall(face)
	else:
		for band: Array in [[0.0, 0.3, CLIFF_TOP], [0.3, 0.7, CLIFF_MID], [0.7, 1.0, CLIFF_LOW]]:
			var top: float = band[0]
			var bottom: float = band[1]
			var color: Color = band[2]
			draw_rect(Rect2(face.position + Vector2(0, face.size.y * top), Vector2(face.size.x, face.size.y * (bottom - top) + 0.5)), color)
		var steps := int(face.size.x / 14.0)
		for i in steps:
			var roll := _hash(int(face.position.x) + i, int(face.position.y), 21) % 100
			var block := Rect2(Vector2(face.position.x + face.size.x * i / steps, face.position.y + face.size.y * (0.25 + (roll % 40) / 100.0)),
				Vector2(8 + roll % 9, 5 + roll % 6))
			draw_rect(block, CLIFF_MID.darkened(0.18))
			draw_rect(Rect2(block.position, Vector2(block.size.x, 1.0)), CLIFF_MID.lightened(0.15))
			if roll < 20:
				var root := Vector2(block.position.x + 3.0, face.position.y + 2.0)
				draw_line(root, root + Vector2(-1.0 + roll % 3, 10.0 + roll % 10), ROOT, 1.5)
		_hanging_grass(face.position, face.size.x)
	draw_rect(Rect2(Vector2(face.position.x, face.end.y - 3.0), Vector2(face.size.x, 3.0)), Color(0, 0, 0, 0.35))
	_foam(Vector2(face.position.x, face.end.y), face.size.x)


## The Town sits behind a stone retaining wall over the moat (Evil Hunter Tycoon's town edge):
## staggered blocks, buttresses every four tiles, moss drips and a capstone.
func _stone_wall(face: Rect2) -> void:
	draw_rect(face, WALL)
	var rows := 5
	var row_height := face.size.y / rows
	for row in rows:
		var y := face.position.y + row * row_height
		var shift := 0.5 if row % 2 == 1 else 0.0
		for i in range(-1, int(face.size.x / 24.0) + 1):
			var x0 := maxf(face.position.x + (i + shift) * 24.0, face.position.x)
			var x1 := minf(face.position.x + (i + shift + 1.0) * 24.0, face.end.x)
			if x1 - x0 < 3.0:
				continue
			var roll := _hash(i, row, 17) % 100
			var color := WALL_LIGHT if roll < 18 else (WALL_DARK if roll > 85 else WALL)
			draw_rect(Rect2(Vector2(x0 + 1.0, y + 1.0), Vector2(x1 - x0 - 2.0, row_height - 2.0)), color)
			draw_rect(Rect2(Vector2(x0 + 1.0, y + 1.0), Vector2(x1 - x0 - 2.0, 1.0)), color.lightened(0.15))
	for i in range(1, int(face.size.x / (TILE * 4.0))):
		var x := face.position.x + i * TILE * 4.0 - 6.0
		draw_rect(Rect2(Vector2(x, face.position.y - 2.0), Vector2(12, face.size.y + 2.0)), WALL_DARK)
		draw_rect(Rect2(Vector2(x + 1.0, face.position.y - 2.0), Vector2(4, face.size.y + 2.0)), WALL)
	for i in int(face.size.x / 10.0):
		var roll := _hash(i, int(face.position.y), 29) % 100
		if roll < 55:
			continue
		draw_rect(Rect2(Vector2(face.position.x + i * 10.0 + roll % 6, face.position.y), Vector2(3 + roll % 3, 4 + roll % 9)), Color(MOSS, 0.85))
	draw_rect(Rect2(face.position + Vector2(0, -4), Vector2(face.size.x, 6)), WALL_CAP)
	draw_rect(Rect2(face.position + Vector2(0, -4), Vector2(face.size.x, 1)), WALL_CAP.lightened(0.25))


## Grass lip and tufts hanging over a cliff edge.
func _hanging_grass(start: Vector2, width: float) -> void:
	var grass: Color = BIOMES[RegionDefinition.Props.NONE][MID]
	draw_rect(Rect2(start + Vector2(0, -1), Vector2(width, 4)), grass.darkened(0.1))
	for i in int(width / 6.0):
		var roll := _hash(int(start.x) + i, int(start.y), 23) % 100
		if roll < 40:
			continue
		var x := start.x + i * 6.0 + 3.0
		var drop := 3.0 + roll % 6
		draw_colored_polygon(PackedVector2Array([Vector2(x - 3.0, start.y + 2.0), Vector2(x + 3.0, start.y + 2.0),
			Vector2(x + 0.5, start.y + 2.0 + drop)]), grass.darkened(0.15))


## Foam line and broken foam dashes where a face meets the water.
func _foam(start: Vector2, width: float) -> void:
	draw_line(start + Vector2(0, 2), start + Vector2(width, 2), FOAM, 2.0)
	for i in int(width / 12.0):
		var roll := _hash(i, int(start.y), 41) % 100
		var x := start.x + i * 12.0 + roll % 5
		draw_line(Vector2(x, start.y + 6.0), Vector2(x + 5.0 + roll % 4, start.y + 6.0), Color(FOAM, 0.3), 1.0)


## Plank deck across a gate corridor, reaching a little onto both banks (GateVisual adds rails).
func _bridge(gate: WorldService.Gate) -> void:
	var a := world.region_center(world.get_region(gate.region_a))
	var b := world.region_center(world.get_region(gate.region_b))
	var horizontal := absf(b.x - a.x) > absf(b.y - a.y)
	var deck := WorldService.rect_to_world(gate.tiles)
	deck = deck.grow_individual(10.0, 0.0, 10.0, 0.0) if horizontal else deck.grow_individual(0.0, 10.0, 0.0, 10.0)
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
	if horizontal:
		draw_line(deck.position, Vector2(deck.end.x, deck.position.y), DECK_DARK, 3.0)
		draw_line(Vector2(deck.position.x, deck.end.y), deck.end, DECK_DARK, 3.0)
	else:
		draw_line(deck.position, Vector2(deck.position.x, deck.end.y), DECK_DARK, 3.0)
		draw_line(Vector2(deck.end.x, deck.position.y), deck.end, DECK_DARK, 3.0)
	draw_rect(deck, Color(0, 0, 0, 0.35), false, 1.0)


## Rock ledge in the water under a dungeon entrance.
func _ledge(tile: Vector2i) -> void:
	var centre := WorldService.tile_center(tile)
	var slab := Rect2(centre - Vector2(TILE * 0.95, TILE * 0.75), Vector2(TILE * 1.9, TILE * 1.5))
	draw_rect(Rect2(Vector2(slab.position.x, slab.end.y), Vector2(slab.size.x, 14.0)), LEDGE.darkened(0.3))
	_foam(Vector2(slab.position.x, slab.end.y + 14.0), slab.size.x)
	draw_rect(slab, LEDGE)
	draw_rect(Rect2(slab.position, Vector2(slab.size.x, 2.0)), LEDGE.lightened(0.2))
	draw_rect(slab, Color(0, 0, 0, 0.35), false, 1.0)
	for i in 3:
		var at := slab.position + Vector2(_unit(tile, 40 + i) * slab.size.x, _unit(tile, 50 + i) * slab.size.y)
		draw_circle(at, 1.5, LEDGE.lightened(0.15))


# --- Regions ---------------------------------------------------------------------------------------

## Noise-coloured ground, biome details, trails (hunting regions) and the edge shading.
func _draw_region(region: RegionDefinition) -> void:
	var palette: Array = BIOMES.get(region.props, BIOMES[RegionDefinition.Props.NONE])
	var rect := region.tile_rect
	for gx in range(rect.position.x, rect.end.x):
		for gy in range(rect.position.y, rect.end.y):
			_tile(Vector2i(gx, gy), _ground_color(palette, gx, gy))
	for gx in range(rect.position.x, rect.end.x):
		for gy in range(rect.position.y, rect.end.y):
			var tile := Vector2i(gx, gy)
			match region.props:
				RegionDefinition.Props.TREES:
					_forest_details(tile, palette)
				RegionDefinition.Props.ROCKS:
					_cave_details(tile, palette)
				RegionDefinition.Props.COLUMNS:
					_ruins_details(tile, palette)
				_:
					if not (pond.has_point(tile) or plaza_tiles.has(tile) or road_tiles.has(tile) or path_tiles.has(tile)):
						_town_details(tile, palette)
	if not region.is_town:
		_draw_trails(region)
	var area := WorldService.rect_to_world(rect)
	var shades: Array[float] = [0.22, 0.14, 0.07]
	for i in shades.size():
		draw_rect(area.grow(-2.0 * i - 1.0), Color(0, 0, 0, shades[i]), false, 2.0)
	draw_line(area.position + Vector2(0, 1), Vector2(area.end.x, area.position.y + 1.0), Color(1.0, 0.96, 0.85, 0.18), 2.0)


## Soft patches: two octaves of value noise blended between the biome's dark, mid and light.
func _ground_color(palette: Array, gx: int, gy: int) -> Color:
	var n := _noise(gx, gy, 6.0, 7) * 0.75 + _noise(gx, gy, 2.5, 8) * 0.25
	var dark: Color = palette[DARK]
	var mid: Color = palette[MID]
	var light: Color = palette[LIGHT]
	if n < 0.62:
		return dark.lerp(mid, minf(1.0, n * 1.6))
	return mid.lerp(light, (n - 0.62) / 0.38)


func _town_details(tile: Vector2i, palette: Array) -> void:
	var roll := _hash(tile.x, tile.y, 5) % 100
	_tufts(tile, palette, 1 + roll % 3)
	if roll < 6:
		_flowers(tile)
	elif roll < 9:
		_clover(tile, palette)
	elif roll > 96:
		_stones(tile, Color("9a9488"))


func _forest_details(tile: Vector2i, palette: Array) -> void:
	var roll := _hash(tile.x, tile.y, 5) % 100
	_tufts(tile, palette, roll % 3)
	if roll < 14:
		for i in 4:
			draw_ellipse(_at(tile, _unit(tile, 40 + i), _unit(tile, 50 + i)), 2.5, 1.5, Color("6a4a2a", 0.75))
	elif roll < 20:
		_fern(tile, palette)
	elif roll < 24:
		_mushrooms(tile)
	elif roll < 27:
		_roots(tile)
	elif roll < 34:
		draw_ellipse(_at(tile, 0.5, 0.5), 12.0, 6.0, Color("2f6a3a", 0.45))


func _cave_details(tile: Vector2i, palette: Array) -> void:
	var roll := _hash(tile.x, tile.y, 5) % 100
	if roll < 30:
		for i in 5:
			var color: Color = palette[DETAIL] if i % 2 == 1 else (palette[DARK] as Color).darkened(0.2)
			draw_ellipse(_at(tile, _unit(tile, 10 + i), _unit(tile, 20 + i)), 1.4, 0.9, color)
	if roll % 7 == 0:
		var start := _at(tile, 0.2 + _unit(tile, 50) * 0.3, 0.2 + _unit(tile, 51) * 0.3)
		var mid := start + Vector2(_unit(tile, 52) * 12.0 - 4.0, 7.0)
		draw_polyline(PackedVector2Array([start, mid, mid + Vector2(6, 6)]), (palette[DARK] as Color).darkened(0.35), 1.0)
	elif roll > 94:
		_stones(tile, Color("8a7a68"))
	elif roll > 91:
		_bones(tile)
	elif roll < 4:
		_crystals(tile)
	elif roll < 9:
		var centre := _at(tile, 0.5, 0.5)
		var light: Color = palette[LIGHT]
		var bright: Color = palette[DETAIL]
		draw_ellipse(centre, 13.0, 8.0, Color(light, 0.5))
		draw_ellipse(centre - Vector2(2, 2), 8.0, 4.0, Color(bright, 0.35))


## Paving slabs two tiles square; about a third are missing and show grass, some cracked or
## mossy.
func _ruins_details(tile: Vector2i, palette: Array) -> void:
	var slab := Vector2i(floori(tile.x / 2.0), floori(tile.y / 2.0))
	var roll := _hash(slab.x, slab.y, 61) % 100
	if roll < 70:
		if tile.x % 2 != 0 or tile.y % 2 != 0:
			return
		var light: Color = palette[LIGHT]
		var bright: Color = palette[DETAIL]
		var color := light.lerp(bright, (roll % 10) / 20.0)
		if roll < 8:
			color = palette[MID]
		var origin := Vector2(tile) * TILE
		draw_rect(Rect2(origin + Vector2.ONE, Vector2(TILE * 2.0 - 2.0, TILE * 2.0 - 2.0)), color.darkened(0.3))
		draw_rect(Rect2(origin + Vector2.ONE, Vector2(TILE * 2.0 - 3.0, TILE * 2.0 - 3.0)), color)
		draw_rect(Rect2(origin + Vector2(2, 2), Vector2(TILE * 2.0 - 5.0, 1.0)), color.lightened(0.2))
		if roll % 5 == 0:
			draw_polyline(PackedVector2Array([origin + Vector2(10, 8), origin + Vector2(22, 20), origin + Vector2(20, 34),
				origin + Vector2(30, 44)]), color.darkened(0.4), 1.0)
		if roll % 4 == 1:
			draw_ellipse(origin + Vector2(TILE * 1.6, TILE * 1.7), 9.0, 4.0, Color(MOSS, 0.6))
		return
	draw_ellipse(_at(tile, 0.5, 0.5), 12.0, 7.0, Color("5f7a4a", 0.55))
	_tufts(tile, BIOMES[RegionDefinition.Props.NONE], 2)
	if _hash(tile.x, tile.y, 62) % 100 > 94:
		_stones(tile, Color("b8b4a6"))


## Dirt trails (paler paving in the Ruins) from every bridge and dungeon entrance of a hunting
## region to its centre: edge pass, fill pass, then pebbles.
func _draw_trails(region: RegionDefinition) -> void:
	var ruins := region.props == RegionDefinition.Props.COLUMNS
	var width := 18.0 if ruins else 22.0
	var fill := TRAIL_RUINS if ruins else TRAIL
	var edge := TRAIL_RUINS_EDGE if ruins else TRAIL_EDGE
	var lines := _region_trails(region)
	for pass_index in 2:
		for line in lines:
			for point in _dense(line, 6.0):
				if pass_index == 0:
					draw_circle(point, width * 0.5 + 2.0, Color(edge, 0.9))
				else:
					draw_circle(point, width * 0.5, fill)
	for line in lines:
		for point in _dense(line, 18.0):
			var roll := _hash(int(point.x), int(point.y), 71) % 100
			if roll < 40:
				draw_ellipse(point + Vector2(roll % 13 - 6, roll % 7 - 3), 1.6, 1.0, fill.lightened(0.25))


## Trail polylines of a hunting region (bridges and dungeon entrances → centre), slightly bent.
func _region_trails(region: RegionDefinition) -> Array[PackedVector2Array]:
	var centre := world.region_center(region)
	var lines: Array[PackedVector2Array] = []
	for gate in world.gates_of(region.id):
		lines.append(_bent(gate.center, centre, Vector2(20, -12)))
	for tile in ledges:
		if region.tile_rect.grow(1).has_point(tile):
			lines.append(_bent(WorldService.tile_center(tile), centre, Vector2(-16, 14)))
	return lines


static func _bent(from: Vector2, to: Vector2, bend: Vector2) -> PackedVector2Array:
	return PackedVector2Array([from, from.lerp(to, 0.5) + bend, to])


## Points every `step` px along a polyline.
static func _dense(line: PackedVector2Array, step: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(line.size() - 1):
		var count := maxi(1, int(line[i].distance_to(line[i + 1]) / step))
		for k in count:
			points.append(line[i].lerp(line[i + 1], float(k) / count))
	if not line.is_empty():
		points.append(line[line.size() - 1])
	return points


# --- Town ------------------------------------------------------------------------------------------

## Dirt roads: dark border, fill, lighter worn patches, wheel ruts, pebbles, grass overhang.
func _draw_roads() -> void:
	for tile in road_tiles:
		draw_rect(Rect2(Vector2(tile) * TILE - Vector2(3, 3), Vector2(TILE + 6.0, TILE + 6.0)), ROAD_DARK)
	for tile in road_tiles:
		draw_rect(Rect2(Vector2(tile) * TILE - Vector2.ONE, Vector2(TILE + 2.0, TILE + 2.0)), ROAD)
	for tile in road_tiles:
		var origin := Vector2(tile) * TILE
		if _noise(tile.x, tile.y, 3.0, 19) > 0.6:
			draw_rect(Rect2(origin + Vector2(4, 4), Vector2(TILE - 8.0, TILE - 8.0)), Color(ROAD_LIGHT, 0.35))
		var horizontal := (road_tiles.has(tile + Vector2i(-1, 0)) or road_tiles.has(tile + Vector2i(1, 0))) \
			and not (road_tiles.has(tile + Vector2i(0, -1)) and road_tiles.has(tile + Vector2i(0, 1)))
		for f: float in [0.3, 0.7]:
			if horizontal:
				draw_line(origin + Vector2(0, TILE * f), origin + Vector2(TILE, TILE * f), Color(ROAD_DARK, 0.45), 1.5)
			else:
				draw_line(origin + Vector2(TILE * f, 0), origin + Vector2(TILE * f, TILE), Color(ROAD_DARK, 0.45), 1.5)
		_pebbles(tile)
	var town := world.get_town()
	var grass: Color = BIOMES[RegionDefinition.Props.NONE][MID]
	for tile in road_tiles:
		for step in STEPS:
			var neighbour := tile + step
			if road_tiles.has(neighbour) or plaza_tiles.has(neighbour) or path_tiles.has(neighbour) \
					or town == null or not town.tile_rect.has_point(neighbour):
				continue
			for i in 4:
				var u := _unit(tile, 100 + i + step.x * 7 + step.y * 3)
				var at: Vector2
				if step.x != 0:
					at = Vector2(tile.x * TILE + (TILE + 1.0 if step.x > 0 else -1.0), tile.y * TILE + u * TILE)
				else:
					at = Vector2(tile.x * TILE + u * TILE, tile.y * TILE + (TILE + 1.0 if step.y > 0 else -1.0))
				var tip := at + Vector2(0, -4.0 if step.y >= 0 else 4.0)
				draw_colored_polygon(PackedVector2Array([at + Vector2(-3, 0), at + Vector2(3, 0), tip]), grass)


## Narrow footpaths: a strip through the tile centres, joined to neighbouring paths and roads.
func _draw_paths() -> void:
	for pass_index in 2:
		var color := ROAD_DARK if pass_index == 0 else ROAD
		var half := 9.0 if pass_index == 0 else 7.0
		for tile in path_tiles:
			var centre := (Vector2(tile) + Vector2(0.5, 0.5)) * TILE
			draw_rect(Rect2(centre - Vector2(half, half), Vector2(half, half) * 2.0), color)
			for step in STEPS:
				var next := tile + step
				if not (path_tiles.has(next) or road_tiles.has(next) or plaza_tiles.has(next)):
					continue
				var box := Rect2(centre, Vector2.ZERO).expand(centre + Vector2(step) * TILE * 0.6)
				if step.x != 0:
					box = box.grow_individual(0.0, half, 0.0, half)
				else:
					box = box.grow_individual(half, 0.0, half, 0.0)
				draw_rect(box, color)
	for tile in path_tiles:
		draw_ellipse(_at(tile, 0.3 + _unit(tile, 5) * 0.4, 0.5), 1.5, 0.8, PEBBLE)


## Shortest 4-way path from every door to the nearest road or plaza tile, around the other
## buildings and the pond.
func _footpaths() -> Dictionary[Vector2i, bool]:
	var result: Dictionary[Vector2i, bool] = {}
	var town := world.get_town() if world != null else null
	if town == null:
		return result
	var area := town.tile_rect.grow(-1)
	var blocked: Dictionary[Vector2i, bool] = {}
	for rect in footprints:
		for x in range(rect.position.x, rect.end.x):
			for y in range(rect.position.y, rect.end.y):
				blocked[Vector2i(x, y)] = true
	for x in range(pond.position.x, pond.end.x):
		for y in range(pond.position.y, pond.end.y):
			blocked[Vector2i(x, y)] = true
	for rect in footprints:
		var door := BuildingService.get_door_tile(rect)
		if road_tiles.has(door) or plaza_tiles.has(door):
			continue
		var previous: Dictionary[Vector2i, Vector2i] = {door: door}
		var queue: Array[Vector2i] = [door]
		var head := 0
		var reached := false
		var found := door
		while head < queue.size() and queue.size() < MAX_PATH_SEARCH:
			var current := queue[head]
			head += 1
			if road_tiles.has(current) or plaza_tiles.has(current):
				found = current
				reached = true
				break
			for step in STEPS:
				var next := current + step
				if previous.has(next) or blocked.has(next) or not area.has_point(next):
					continue
				previous[next] = current
				queue.append(next)
		if not reached:
			continue
		var at: Vector2i = previous[found]
		while true:
			result[at] = true
			if at == door:
				break
			at = previous[at]
	return result


## Cobbled plaza with a curb on its outer edges and a compass mosaic in front of the Town Hall.
func _draw_plaza() -> void:
	if plaza_tiles.is_empty():
		return
	var low := Vector2i(1 << 30, 1 << 30)
	var high := Vector2i(-(1 << 30), -(1 << 30))
	for tile in plaza_tiles:
		_cobbles(tile)
		low = Vector2i(mini(low.x, tile.x), mini(low.y, tile.y))
		high = Vector2i(maxi(high.x, tile.x), maxi(high.y, tile.y))
	for tile in plaza_tiles:
		var origin := Vector2(tile) * TILE
		if not plaza_tiles.has(tile + Vector2i(1, 0)):
			draw_rect(Rect2(origin + Vector2(TILE - 4.0, 0), Vector2(4, TILE)), CURB)
		if not plaza_tiles.has(tile + Vector2i(-1, 0)):
			draw_rect(Rect2(origin, Vector2(4, TILE)), CURB)
		if not plaza_tiles.has(tile + Vector2i(0, 1)):
			draw_rect(Rect2(origin + Vector2(0, TILE - 4.0), Vector2(TILE, 4)), CURB)
		if not plaza_tiles.has(tile + Vector2i(0, -1)):
			draw_rect(Rect2(origin, Vector2(TILE, 4)), CURB)
	var centre := Vector2((low.x + high.x + 1) * 0.5 * TILE, high.y * TILE)
	draw_circle(centre, 22.0, COBBLE_GAP)
	draw_circle(centre, 20.0, Color("d8cfb4"))
	draw_circle(centre, 14.0, Color("8a6a44"))
	draw_circle(centre, 12.0, Color("e2c46b"))
	for i in 8:
		var direction := Vector2.RIGHT.rotated(i * PI * 0.25)
		draw_line(centre + direction * 4.0, centre + direction * 19.0, COBBLE_GAP, 1.5)
	draw_circle(centre, 4.0, Color("a83a3a"))


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
			draw_rect(Rect2(stone.position, Vector2(stone.size.x, 1.0)), color.lightened(0.2))


## Rounded pond with ripple rings, lily pads and reeds.
func _draw_pond() -> void:
	var shore := _rounded(WorldService.rect_to_world(pond).grow(6.0), 16.0)
	draw_colored_polygon(shore, SHORE)
	draw_colored_polygon(_rounded(WorldService.rect_to_world(pond).grow(-2.0), 14.0), WATER.darkened(0.2))
	var water_rect := WorldService.rect_to_world(pond).grow(-8.0)
	var water := _rounded(water_rect, 10.0)
	draw_colored_polygon(water, WATER)
	var centre := water_rect.get_center()
	for ring: float in [0.55, 0.3]:
		var points := PackedVector2Array()
		for corner in water:
			points.append(centre + (corner - centre) * ring)
		draw_polyline(points + PackedVector2Array([points[0]]), Color(WATER_LIGHT, 0.6), 1.0)
	for pad: Vector2 in [Vector2(-34, 6), Vector2(-10, -12), Vector2(22, 8), Vector2(40, -10), Vector2(2, 16)]:
		draw_circle(centre + pad, 4.0, Color("4f9a4a"))
		draw_circle(centre + pad + Vector2(1, -1), 1.4, Color("e8789a"))
	for reed: Vector2 in [Vector2(water_rect.position.x, water_rect.end.y + 4.0), Vector2(water_rect.end.x - 2.0, water_rect.end.y + 4.0)]:
		for k in 3:
			draw_line(reed + Vector2(k * 2.0, 0), reed + Vector2(k * 2.0 + 1.0, -10.0 - k * 2.0), Color("5f7a3a"), 1.5)


## Stone parapet just inside the Town's top, left and right edges, and a fence behind the back row.
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
		draw_rect(band, WALL_DARK, false, 1.0)
		var horizontal := band.size.x > band.size.y
		var length := band.size.x if horizontal else band.size.y
		for i in range(1, int(length / 14.0)):
			var at := band.position + (Vector2(i * 14.0, 0) if horizontal else Vector2(0, i * 14.0))
			var to := at + (Vector2(0, thickness) if horizontal else Vector2(thickness, 0))
			draw_line(at, to, WALL_DARK, 1.0)
	var fence_y := area.position.y + TILE * 0.5
	for i in range(0, region.tile_rect.size.x + 1):
		var base := Vector2(area.position.x + i * TILE, fence_y)
		draw_line(base, base + Vector2(0, -11), FENCE_DARK, 3.0)
		draw_line(base + Vector2(0, -11), base + Vector2(0, -12), FENCE.lightened(0.2), 3.0)
	draw_line(Vector2(area.position.x, fence_y - 5.0), Vector2(area.end.x, fence_y - 5.0), FENCE, 2.0)
	draw_line(Vector2(area.position.x, fence_y - 9.0), Vector2(area.end.x, fence_y - 9.0), FENCE, 2.0)


# --- Small decorations -----------------------------------------------------------------------------

func _tile(tile: Vector2i, color: Color) -> void:
	draw_rect(Rect2(Vector2(tile) * TILE, Vector2(TILE, TILE)), color)


## Tile-local point (0..1) in world space.
func _at(tile: Vector2i, u: float, v: float) -> Vector2:
	return WorldService.tile_to_world(Vector2(tile) + Vector2(u, v))


## Grass tufts: a dark root shadow under three blades.
func _tufts(tile: Vector2i, palette: Array, count: int) -> void:
	var shadow := (palette[DARK] as Color).darkened(0.2)
	var light: Color = palette[LIGHT]
	var bright: Color = palette[DETAIL]
	for i in count:
		var base := _at(tile, 0.12 + _unit(tile, 60 + i) * 0.76, 0.15 + _unit(tile, 70 + i) * 0.75)
		draw_line(base + Vector2(-2.5, 0.5), base + Vector2(2.5, 0.5), shadow, 1.0)
		draw_line(base, base + Vector2(-2, -3.5), light, 1.0)
		draw_line(base, base + Vector2(0, -5), bright, 1.0)
		draw_line(base, base + Vector2(2, -3.5), light, 1.0)


func _flowers(tile: Vector2i) -> void:
	var color := FLOWERS[_hash(tile.x, tile.y, 9) % FLOWERS.size()]
	for i in 4:
		var base := _at(tile, 0.2 + _unit(tile, 20 + i) * 0.6, 0.25 + _unit(tile, 30 + i) * 0.6)
		draw_line(base, base + Vector2(0, -3), Color("3f6a36"), 1.0)
		draw_circle(base + Vector2(0, -4), 1.8, color.darkened(0.25))
		draw_circle(base + Vector2(-0.4, -4.4), 1.2, color)


## A ring of clover leaves.
func _clover(tile: Vector2i, palette: Array) -> void:
	var centre := _at(tile, 0.5, 0.6)
	for i in 6:
		var leaf := centre + Vector2(cos(i * 1.05) * 6.0, sin(i * 1.05) * 3.0)
		var dark: Color = palette[DARK]
		var light: Color = palette[LIGHT]
		var bright: Color = palette[DETAIL]
		draw_circle(leaf + Vector2(0, 0.8), 2.2, dark.darkened(0.15))
		draw_circle(leaf, 2.0, light)
		draw_circle(leaf - Vector2(0.6, 0.6), 0.8, bright)


func _stones(tile: Vector2i, color: Color) -> void:
	for i in 2:
		var at := _at(tile, 0.25 + _unit(tile, 80 + i) * 0.5, 0.3 + _unit(tile, 90 + i) * 0.5)
		var r := 2.0 + _unit(tile, 95 + i) * 2.0
		draw_ellipse(at + Vector2(0, 1), r + 0.5, r * 0.6, color.darkened(0.45))
		draw_ellipse(at, r, r * 0.6, color)
		draw_ellipse(at - Vector2(r * 0.3, r * 0.2), r * 0.4, r * 0.25, color.lightened(0.25))


func _pebbles(tile: Vector2i) -> void:
	for i in 3:
		var at := _at(tile, 0.15 + _unit(tile, 80 + i) * 0.7, 0.15 + _unit(tile, 90 + i) * 0.7)
		draw_ellipse(at + Vector2(0, 0.6), 1.8, 0.9, ROAD_DARK)
		draw_ellipse(at, 1.5, 0.8, PEBBLE)


func _fern(tile: Vector2i, palette: Array) -> void:
	var base := _at(tile, 0.5, 0.7)
	var color: Color = palette[DETAIL]
	for i in 5:
		var tip := base + Vector2.RIGHT.rotated(-PI * 0.5 + (i - 2) * 0.45) * (9.0 + (i % 2) * 3.0)
		draw_line(base, tip, color.darkened(0.3), 2.0)
		draw_line(base, tip, color, 1.0)


func _mushrooms(tile: Vector2i) -> void:
	var color := MUSHROOMS[_hash(tile.x, tile.y, 9) % MUSHROOMS.size()]
	for i in 3:
		var base := _at(tile, 0.3 + _unit(tile, 20 + i) * 0.4, 0.4 + _unit(tile, 30 + i) * 0.4)
		var height := 3.0 + (i % 2) * 2.0
		draw_line(base, base + Vector2(0, -height), Color("e6e2d8"), 1.5)
		draw_ellipse(base + Vector2(0, -height), 3.0, 2.0, OUTLINE)
		draw_ellipse(base + Vector2(0, -height - 0.5), 2.5, 1.5, color)


## A root snaking across the forest floor.
func _roots(tile: Vector2i) -> void:
	var a := _at(tile, 0.1, 0.4 + _unit(tile, 3) * 0.3)
	var b := _at(tile, 0.9, 0.5)
	var line := PackedVector2Array([a, (a + b) * 0.5 + Vector2(0, -4), b])
	draw_polyline(line, Color("2a1c10"), 3.0)
	draw_polyline(line, Color("5a3f2a"), 1.5)


func _bones(tile: Vector2i) -> void:
	var centre := _at(tile, 0.5, 0.5)
	draw_line(centre + Vector2(-5, -2), centre + Vector2(5, 2), Color("e6dfcc"), 2.0)
	for end: Vector2 in [Vector2(-5, -2), Vector2(5, 2)]:
		draw_circle(centre + end, 1.6, Color("e6dfcc"))


## Glowing crystal cluster (Goblin Cave).
func _crystals(tile: Vector2i) -> void:
	var base := _at(tile, 0.5, 0.7)
	var color := CRYSTALS[_hash(tile.x, tile.y, 77) % CRYSTALS.size()]
	draw_ellipse(base + Vector2(0, -4), 9.0, 6.0, Color(color, 0.18))
	for shard: Vector2 in [Vector2(-4, 7), Vector2(0, 11), Vector2(4, 6)]:
		var points := PackedVector2Array([base + Vector2(shard.x - 2.0, 0), base + Vector2(shard.x + 2.0, 0), base + Vector2(shard.x, -shard.y)])
		var shadow := PackedVector2Array()
		for point in points:
			shadow.append(point + Vector2(0, 1))
		draw_colored_polygon(shadow, Color("1a1420"))
		draw_colored_polygon(points, color)
		draw_line(base + Vector2(shard.x - 0.5, -1.0), base + Vector2(shard.x - 0.5, -shard.y + 2.0), color.lightened(0.5), 1.0)


## Rectangle with rounded corners as a polygon.
static func _rounded(rect: Rect2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var centres: Array[Vector2] = [rect.position + Vector2(r, r), Vector2(rect.end.x - r, rect.position.y + r),
		rect.end - Vector2(r, r), Vector2(rect.position.x + r, rect.end.y - r)]
	for i in 4:
		var start := PI + i * PI * 0.5
		for j in 7:
			points.append(centres[i] + Vector2.RIGHT.rotated(start + j * PI / 12.0) * r)
	return points


## Smooth value noise in 0..1 over tile coordinates (bilinear between hashed lattice values).
static func _noise(x: float, y: float, period: float, salt: int) -> float:
	var gx := x / period
	var gy := y / period
	var x0 := floori(gx)
	var y0 := floori(gy)
	var fx := gx - x0
	var fy := gy - y0
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	var top := lerpf(_lattice(x0, y0, salt), _lattice(x0 + 1, y0, salt), fx)
	var bottom := lerpf(_lattice(x0, y0 + 1, salt), _lattice(x0 + 1, y0 + 1, salt), fx)
	return lerpf(top, bottom, fy)


static func _lattice(x: int, y: int, salt: int) -> float:
	return float(_hash(x, y, salt) % 1000) / 1000.0


static func _hash(x: int, y: int, salt: int) -> int:
	var h := (x * 73856093) ^ (y * 19349663) ^ (salt * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	return absi(h ^ (h >> 16))


static func _unit(tile: Vector2i, salt: int) -> float:
	return float(_hash(tile.x, tile.y, salt) % 1000) / 1000.0
