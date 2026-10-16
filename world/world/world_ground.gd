extends Node2D
## Isometric ground for every region and bridge (WORLD_DESIGN.md → Biome identity, D55, D57).
## Drawn once (static). The regions are organically shaped plateaus over dark water (wave marks,
## foam at the cliff foot): each shows cliff faces below its front edges (south-west and
## south-east; the Town a stone retaining wall, with a parapet and a fence along its back edges); bridges of
## planks cross the gaps; small rock ledges carry the dungeon entrances. The Town has a cobbled
## plaza, dirt roads with pebbles and kerbs, grass tufts, flowers, bushes and a pond; the hunting
## regions have their own ground patterns (moss and leaves, cracked rock, pale paving).
## The root node draws nothing itself: it spreads the drawing over child nodes of the same script (D75),
## the water, each region's cliffs, tiles and rims in horizontal strips (STRIP tile diagonals, back to
## front), bridges and the pond, so the parts off screen are culled. One big drawing of everything was
## re-rendered every frame (the lag of D74).

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
const CLIFF_DEPTH := 40.0
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
## Width of the parapet band (tiles).
const PARAPET := 0.18
## Tiny overlap between neighbouring tile diamonds so no hairline gaps show.
const SEAM := 0.015
## Tile diagonals (x + y) per strip: one screen band of STRIP × HALF_HEIGHT px.
const STRIP := 8

var world: WorldService
## Tiles drawn as road inside the Town.
var road_tiles: Dictionary[Vector2i, bool] = {}
## Tiles drawn as cobbled plaza (around the Town Hall).
var plaza_tiles: Dictionary[Vector2i, bool] = {}
var pond: Rect2i = Rect2i()
## Dungeon entrance tiles (outside the regions): each gets a rock ledge.
var ledges: Array[Vector2i] = []
## Baked pixel-art ground per region (GroundPainter, tools/bake_ground.gd): id -> {texture, origin}.
var _ground_art: Dictionary = {}
## Baked water around the plateaus (WaterPainter): {texture, origin}, empty when missing or stale.
var _water_art: Dictionary = {}
## What this node draws: {kind, region, tiles}; empty on the root (which only holds the parts).
var _part: Dictionary = {}


func setup(world_service: WorldService, town_roads: Dictionary[Vector2i, bool], town_plaza: Dictionary[Vector2i, bool] = {},
		town_pond: Rect2i = Rect2i(), entrance_tiles: Array[Vector2i] = []) -> void:
	world = world_service
	road_tiles = town_roads
	plaza_tiles = town_plaza
	pond = town_pond
	ledges = entrance_tiles
	_load_ground_art()
	_build_parts()


## Loads the baked textures whose size matches the region's current shape (else the region keeps
## the flat per-tile ground).
func _load_ground_art() -> void:
	_ground_art.clear()
	_water_art.clear()
	var water_path := "res://assets/ground/water.png"
	if ResourceLoader.exists(water_path):
		var water_texture := load(water_path) as Texture2D
		var water_box := WaterPainter.layout(world)
		if water_texture != null and Vector2i(water_texture.get_size()) == water_box["size"]:
			_water_art = {"texture": water_texture, "origin": water_box["origin"]}
	for region in world.get_regions():
		var path := "res://assets/ground/%s.png" % region.id
		if not ResourceLoader.exists(path):
			continue
		var texture := load(path) as Texture2D
		var box := GroundPainter.layout(world, region)
		if texture == null or box.is_empty() or Vector2i(texture.get_size()) != box["size"]:
			continue
		_ground_art[region.id] = {"texture": texture, "origin": box["origin"]}


## Child nodes in drawing order (the old single drawing's order): water; every region's cliffs;
## ledges; per region its baked art, tiles, rims and Town edges; bridges; pond.
func _build_parts() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_add_part({"kind": "water"})
	var strips := {}
	for region in world.get_regions():
		strips[region.id] = _strips(region)
	# Cliffs first: bridges and ledges are drawn over their overlaps.
	for region in world.get_regions():
		for strip: Array in strips[region.id]:
			_add_part({"kind": "cliffs", "region": region, "tiles": strip})
	if not ledges.is_empty():
		_add_part({"kind": "ledges"})
	for region in world.get_regions():
		var painted := _ground_art.has(region.id)
		if painted:
			_add_part({"kind": "art", "region": region})
		# Baked hunting grounds draw nothing per tile.
		if region.is_town or not painted:
			for strip: Array in strips[region.id]:
				_add_part({"kind": "tiles", "region": region, "tiles": strip})
		for strip: Array in strips[region.id]:
			_add_part({"kind": "rims", "region": region, "tiles": strip})
		if region.is_town:
			_add_part({"kind": "town_edges", "region": region})
	_add_part({"kind": "bridges"})
	if pond.size != Vector2i.ZERO:
		_add_part({"kind": "pond"})


## A region's tiles in strips of STRIP diagonals, back to front (sorted by x + y inside each strip).
func _strips(region: RegionDefinition) -> Array:
	var bands := {}
	for tile: Vector2i in world.region_tile_list(region.id):
		var band := floori(float(tile.x + tile.y) / STRIP)
		if not bands.has(band):
			bands[band] = []
		(bands[band] as Array).append(tile)
	var keys := bands.keys()
	keys.sort()
	var strips: Array = []
	for band: int in keys:
		var tiles: Array = bands[band]
		tiles.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x + a.y < b.x + b.y)
		strips.append(tiles)
	return strips


func _add_part(part: Dictionary) -> void:
	var node := Node2D.new()
	node.set_script(get_script())
	node.world = world
	node.road_tiles = road_tiles
	node.plaza_tiles = plaza_tiles
	node.pond = pond
	node.ledges = ledges
	node._ground_art = _ground_art
	node._water_art = _water_art
	node._part = part
	node.name = "%s%d" % [String(part["kind"]).capitalize().replace(" ", ""), get_child_count()]
	add_child(node)


func _draw() -> void:
	if world == null or _part.is_empty():
		return
	var region: RegionDefinition = _part.get("region")
	var tiles: Array = _part.get("tiles", [])
	match _part["kind"]:
		"water":
			_draw_water()
		"cliffs":
			_cliffs(region, tiles)
		"ledges":
			for tile in ledges:
				_ledge(tile)
		"art":
			var art: Dictionary = _ground_art[region.id]
			var texture: Texture2D = art["texture"]
			draw_texture_rect(texture, Rect2(art["origin"], texture.get_size() * GroundPainter.SCALE), false)
		"tiles":
			var ground := world.region_tiles(region.id)
			var painted := _ground_art.has(region.id)
			for tile: Vector2i in tiles:
				_ground_tile(region, ground, tile, painted)
		"rims":
			_rims(region, tiles)
		"town_edges":
			_town_edges(region, world.region_tiles(region.id))
		"bridges":
			for gate in world.get_gates():
				_bridge(gate)
		"pond":
			_draw_pond()


# --- Water, cliffs, bridges ------------------------------------------------------------------------

## Gentle wave marks on the water around the plateaus (the clear colour is the water).
func _draw_water() -> void:
	if not _water_art.is_empty():
		var texture: Texture2D = _water_art["texture"]
		draw_texture_rect(texture, Rect2(_water_art["origin"], texture.get_size() * WaterPainter.SCALE), false)
		return
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


## Faces below every front edge of a region's shape (a tile's south-west edge when the +y
## neighbour is water, its south-east edge when the +x neighbour is): earth with strata and
## hanging grass, or (Town) a stone retaining wall. Foam where they meet the water. Drawn back to
## front so nearer faces cover farther ones.
## `tiles`: one strip of the region, sorted back to front.
func _cliffs(region: RegionDefinition, tiles: Array) -> void:
	for tile: Vector2i in tiles:
		var corners := WorldService.rect_polygon(Rect2i(tile, Vector2i.ONE))
		# Land of any region next door (only across a bridge) would be level: no cliff there.
		if not world.is_land(tile + Vector2i(0, 1)):
			_cliff_face(corners[3], corners[2], false, region.is_town)
		if not world.is_land(tile + Vector2i(1, 0)):
			_cliff_face(corners[2], corners[1], true, region.is_town)


func _cliff_face(a: Vector2, b: Vector2, shaded: bool, stone: bool) -> void:
	var face := _drop(a, b, CLIFF_DEPTH)
	if stone:
		_stone_wall(a, b, shaded)
	else:
		var color := CLIFF.darkened(0.2) if shaded else CLIFF
		draw_colored_polygon(face, color)
		# Darker towards the water so the drop reads as depth.
		draw_colored_polygon(_band(a, b, CLIFF_DEPTH * 0.55, CLIFF_DEPTH), color.darkened(0.18))
		draw_colored_polygon(_band(a, b, CLIFF_DEPTH * 0.8, CLIFF_DEPTH), color.darkened(0.32))
		for layer: float in [0.35, 0.68]:
			draw_line(a + Vector2(0, CLIFF_DEPTH * layer), b + Vector2(0, CLIFF_DEPTH * layer), color.darkened(0.25), 1.0)
		_cliff_details(a, b, CLIFF_DEPTH, color)
		draw_line(a, b, CLIFF_GRASS, 4.0)
		_hanging_grass(a, b, CLIFF_GRASS)
	draw_line(a + Vector2(0, CLIFF_DEPTH), b + Vector2(0, CLIFF_DEPTH), Color(0, 0, 0, 0.45), 2.0)
	draw_line(b, b + Vector2(0, CLIFF_DEPTH), Color(0, 0, 0, 0.25), 1.0)
	_foam(a + Vector2(0, CLIFF_DEPTH), b + Vector2(0, CLIFF_DEPTH))


## Dark line along every boundary edge of the shape, and a lit rim along the back edges of the
## hunting regions.
func _rims(region: RegionDefinition, tiles: Array) -> void:
	for tile: Vector2i in tiles:
		var corners := WorldService.rect_polygon(Rect2i(tile, Vector2i.ONE))
		var steps := [[Vector2i(0, -1), 0, 1], [Vector2i(1, 0), 1, 2], [Vector2i(0, 1), 2, 3], [Vector2i(-1, 0), 3, 0]]
		for step: Array in steps:
			if world.is_land(tile + step[0]):
				continue
			draw_line(corners[step[1]], corners[step[2]], EDGE, 2.0)
			if not region.is_town and (step[0] == Vector2i(0, -1) or step[0] == Vector2i(-1, 0)):
				draw_line(corners[step[1]] + Vector2(0, 1.5), corners[step[2]] + Vector2(0, 1.5), Color(1, 1, 0.85, 0.12), 2.0)


## Face hanging `depth` px below the edge a → b.
static func _drop(a: Vector2, b: Vector2, depth: float) -> PackedVector2Array:
	return PackedVector2Array([a, b, b + Vector2(0, depth), a + Vector2(0, depth)])


## Part of a hanging face between two depths.
static func _band(a: Vector2, b: Vector2, d0: float, d1: float) -> PackedVector2Array:
	return PackedVector2Array([a + Vector2(0, d0), b + Vector2(0, d0), b + Vector2(0, d1), a + Vector2(0, d1)])


## The Town sits behind a stone retaining wall over the moat (the reference game's town edge).
func _stone_wall(a: Vector2, b: Vector2, shaded: bool) -> void:
	var wall := WALL.darkened(0.2) if shaded else WALL
	draw_colored_polygon(_drop(a, b, CLIFF_DEPTH), wall)
	draw_colored_polygon(_band(a, b, CLIFF_DEPTH * 0.7, CLIFF_DEPTH), wall.darkened(0.25))
	var rows := 5
	var columns := maxi(int(a.distance_to(b) / 11.0), 1)
	for row in rows:
		var d0 := CLIFF_DEPTH * row / rows
		var d1 := CLIFF_DEPTH * (row + 1) / rows
		draw_line(a + Vector2(0, d0), b + Vector2(0, d0), wall.darkened(0.35), 1.0)
		var shift := 0.5 if row % 2 == 1 else 0.0
		for i in columns:
			var t := (i + shift) / columns
			if t > 0.0 and t < 1.0:
				var at := a.lerp(b, t)
				draw_line(at + Vector2(0, d0), at + Vector2(0, d1), wall.darkened(0.35), 1.0)
				# A lit block now and then.
				if _hash(i, row, 17) % 5 == 0:
					var next := a.lerp(b, (i + shift + 1.0) / columns)
					draw_colored_polygon(PackedVector2Array([at + Vector2(1, d0 + 1), next + Vector2(-1, d0 + 1), next + Vector2(-1, d1 - 1), at + Vector2(1, d1 - 1)]),
						WALL_LIGHT.darkened(0.2) if shaded else WALL_LIGHT)
	draw_line(a, b, WALL_CAP, 5.0)
	draw_line(a + Vector2(0, -2), b + Vector2(0, -2), WALL_CAP.lightened(0.15), 1.0)


## Stone parapet (a low wall with a cap and a short front face) just inside the Town's back
## edges (every tile edge whose −x or −y neighbour is water), and a wooden fence a little
## further in. Drawn tile by tile so it follows the shape.
func _town_edges(region: RegionDefinition, ground: Dictionary) -> void:
	var tiles: Array = world.region_tile_list(region.id).duplicate()
	tiles.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x + a.y < b.x + b.y)
	var fences: Array[PackedVector2Array] = []
	for tile: Vector2i in tiles:
		var origin := Vector2(tile)
		if not ground.has(tile + Vector2i(0, -1)):
			_parapet(WorldService.quad(origin, Vector2(1, PARAPET)), 3, 2)
			fences.append(PackedVector2Array([WorldService.tile_to_world(origin + Vector2(0, 0.6)), WorldService.tile_to_world(origin + Vector2(1, 0.6))]))
		if not ground.has(tile + Vector2i(-1, 0)):
			_parapet(WorldService.quad(origin, Vector2(PARAPET, 1)), 1, 2)
			fences.append(PackedVector2Array([WorldService.tile_to_world(origin + Vector2(0.6, 0)), WorldService.tile_to_world(origin + Vector2(0.6, 1))]))
	for segment in fences:
		draw_line(segment[0] + Vector2(0, -5), segment[1] + Vector2(0, -5), FENCE, 2.0)
		draw_line(segment[0] + Vector2(0, -9), segment[1] + Vector2(0, -9), FENCE, 2.0)
	for segment in fences:
		_fence_post(segment[0])
		_fence_post(segment[1])


## One tile's length of parapet: cap band, short face under its inner edge, a joint.
func _parapet(polygon: PackedVector2Array, inner_a: int, inner_b: int) -> void:
	var face := _drop(polygon[inner_a], polygon[inner_b], 5.0)
	draw_colored_polygon(face, WALL)
	draw_polyline(face + PackedVector2Array([face[0]]), WALL.darkened(0.3), 1.0)
	draw_colored_polygon(polygon, WALL_CAP)
	draw_polyline(polygon + PackedVector2Array([polygon[0]]), WALL.darkened(0.3), 1.0)
	if inner_a == 3:
		draw_line(polygon[0].lerp(polygon[1], 0.5), polygon[3].lerp(polygon[2], 0.5), WALL.darkened(0.3), 1.0)
	else:
		draw_line(polygon[0].lerp(polygon[3], 0.5), polygon[1].lerp(polygon[2], 0.5), WALL.darkened(0.3), 1.0)


func _fence_post(base: Vector2) -> void:
	draw_line(base, base + Vector2(0, -11), FENCE_DARK, 3.0)
	draw_line(base + Vector2(0, -11), base + Vector2(0, -12), FENCE.lightened(0.2), 3.0)


## Light streaks and darker cracks on a rock face (deterministic per position).
func _cliff_details(a: Vector2, b: Vector2, depth: float, color: Color) -> void:
	var steps := int(a.distance_to(b) / 9.0)
	for i in steps:
		var roll := _hash(int(a.x) + i, int(a.y), 21) % 100
		var top := a.lerp(b, (i + 0.5) / steps) + Vector2(0, depth * (0.15 + (roll % 30) / 100.0))
		if roll < 35:
			draw_line(top, top + Vector2(0, depth * 0.25), color.lightened(0.15), 1.0)
		elif roll < 55:
			draw_line(top, top + Vector2(2, depth * 0.2), color.darkened(0.35), 1.0)


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
	var along_x := gate.axis.x != 0
	var origin := Vector2(gate.tiles.position)
	var size := Vector2(gate.tiles.size)
	if along_x:
		origin.x -= 0.35
		size.x += 0.7
	else:
		origin.y -= 0.35
		size.y += 0.7
	var deck := WorldService.quad(origin, size)
	# Shadow on the water under the deck.
	var shadow := PackedVector2Array()
	for corner in deck:
		shadow.append(corner + Vector2(0, 6))
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.3))
	draw_colored_polygon(deck, DECK)
	var planks := int((size.x if along_x else size.y) * WorldService.TILE_WIDTH / 7.0)
	for i in range(1, planks):
		var t := float(i) / planks
		if along_x:
			var u := origin.x + size.x * t
			draw_line(WorldService.tile_to_world(Vector2(u, origin.y)), WorldService.tile_to_world(Vector2(u, origin.y + size.y)), DECK_DARK, 1.0)
		else:
			var v := origin.y + size.y * t
			draw_line(WorldService.tile_to_world(Vector2(origin.x, v)), WorldService.tile_to_world(Vector2(origin.x + size.x, v)), DECK_DARK, 1.0)
	# Beams along the long edges.
	if along_x:
		draw_line(deck[0], deck[1], DECK_DARK, 3.0)
		draw_line(deck[3], deck[2], DECK_DARK, 3.0)
	else:
		draw_line(deck[0], deck[3], DECK_DARK, 3.0)
		draw_line(deck[1], deck[2], DECK_DARK, 3.0)
	draw_polyline(deck + PackedVector2Array([deck[0]]), EDGE, 1.0)


## Rock ledge in the water under a dungeon entrance.
func _ledge(tile: Vector2i) -> void:
	var slab := WorldService.rect_polygon(Rect2i(tile, Vector2i.ONE), 0.45)
	for pair: Array in [[slab[3], slab[2]], [slab[2], slab[1]]]:
		var face := _drop(pair[0], pair[1], 14.0)
		draw_colored_polygon(face, LEDGE.darkened(0.3))
		_cliff_details(pair[0], pair[1], 14.0, LEDGE.darkened(0.3))
		_foam(pair[0] + Vector2(0, 14), pair[1] + Vector2(0, 14))
	draw_colored_polygon(slab, LEDGE)
	draw_polyline(PackedVector2Array([slab[3], slab[0], slab[1]]), LEDGE.lightened(0.2), 2.0)
	draw_polyline(slab + PackedVector2Array([slab[0]]), EDGE, 1.0)
	for i in 3:
		var at := _at(tile, 0.2 + _unit(tile, 40 + i) * 0.6, 0.2 + _unit(tile, 50 + i) * 0.6)
		draw_circle(at, 1.5, LEDGE.lightened(0.15))


# --- Ground ----------------------------------------------------------------------------------------

func _ground_tile(region: RegionDefinition, ground: Dictionary, tile: Vector2i, painted: bool = false) -> void:
	var variation := _hash(tile.x, tile.y, 1) % 100
	var color := region.ground_color
	if variation < 26:
		color = region.ground_alt_color
	elif variation > 88:
		color = region.ground_color.darkened(0.06)
	if region.is_town:
		_town_tile(ground, tile, color, painted)
		return
	if painted:
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


func _town_tile(ground: Dictionary, tile: Vector2i, color: Color, painted: bool = false) -> void:
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
			if not road_tiles.has(tile + step) and not plaza_tiles.has(tile + step) and ground.has(tile + step):
				_edge(tile, step, ROAD_EDGE)
		return
	if painted:
		# The baked grass already has tufts and flowers; only bushes stay as objects.
		if _hash(tile.x, tile.y, 5) % 100 > 95:
			_bush(tile, color)
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


## Pond: a sandy shore diamond, the water inside it with ripple rings, lily pads and reeds.
func _draw_pond() -> void:
	var shore := _rounded(WorldService.rect_polygon(pond, 0.2))
	draw_colored_polygon(shore, SHORE)
	var water := _rounded(WorldService.rect_polygon(pond, -0.35))
	draw_colored_polygon(water, WATER)
	var centre := WorldService.tile_to_world(Vector2(pond.position) + Vector2(pond.size) * 0.5)
	for ring: float in [0.55, 0.3]:
		var points := PackedVector2Array()
		for corner in water:
			points.append(centre + (corner - centre) * ring)
		draw_polyline(points + PackedVector2Array([points[0]]), WATER_LIGHT, 1.0)
	draw_polyline(water + PackedVector2Array([water[0]]), WATER.darkened(0.3), 2.0)
	for pad: Vector2 in [Vector2(-18, 4), Vector2(12, -4), Vector2(2, 10)]:
		draw_circle(centre + pad, 3.5, Color("4f9a4a"))
		draw_circle(centre + pad + Vector2(1, -1), 1.2, Color("e8789a"))
	for reed: Vector2 in [water[3] + Vector2(8, -2), water[2] + Vector2(-6, -6), water[1] + Vector2(-10, 2)]:
		draw_line(reed, reed + Vector2(0, -9), Color("5f7a3a"), 1.5)
		draw_line(reed + Vector2(2, 0), reed + Vector2(3, -7), Color("5f7a3a"), 1.5)


## Diamond with its four corners cut (rounded look).
static func _rounded(diamond: PackedVector2Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 4:
		var prev := diamond[(i + 3) % 4]
		var corner := diamond[i]
		var next := diamond[(i + 1) % 4]
		points.append(corner.lerp(prev, 0.18))
		points.append(corner.lerp(next, 0.18))
	return points


# --- Small decorations -----------------------------------------------------------------------------

func _tile(tile: Vector2i, color: Color) -> void:
	draw_colored_polygon(WorldService.rect_polygon(Rect2i(tile, Vector2i.ONE), SEAM), color)


## Tile-local point (0..1 along each tile axis) in world space.
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
	var centre := _at(tile, 0.5, 0.5)
	draw_ellipse(centre + Vector2(1, 1), 8.0, 3.0, Color(0, 0, 0, 0.25))
	for blob: Array in [[Vector2(-4, -3), 4.0], [Vector2(3, -3), 4.0], [Vector2(0, -6), 4.5]]:
		draw_circle(centre + blob[0], blob[1] + 1.0, Color("10140f"))
	for blob: Array in [[Vector2(-4, -3), 4.0], [Vector2(3, -3), 4.0], [Vector2(0, -6), 4.5]]:
		draw_circle(centre + blob[0], blob[1], color.darkened(0.15))
		draw_circle(centre + blob[0] + Vector2(-1, -1), blob[1] * 0.55, color.lightened(0.12))


## Plaza tile split into 3×3 cobblestones with mortar gaps and varied shades.
func _cobbles(tile: Vector2i) -> void:
	_tile(tile, COBBLE_GAP)
	for i in 3:
		for j in 3:
			var roll := _hash(tile.x * 3 + i, tile.y * 3 + j, 13) % 3
			var color := COBBLE if roll == 0 else (COBBLE_DARK if roll == 1 else COBBLE.lerp(COBBLE_DARK, 0.5))
			var stone := WorldService.quad(Vector2(tile) + Vector2(i + 0.08, j + 0.08) / 3.0, Vector2(0.84, 0.84) / 3.0)
			draw_colored_polygon(stone, color)
			draw_line(stone[3], stone[0], color.lightened(0.15), 1.0)
			draw_line(stone[0], stone[1], color.lightened(0.15), 1.0)


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
	draw_ellipse(centre, 11.0 * size, 5.5 * size, color)


func _cracks(tile: Vector2i, color: Color) -> void:
	var start := _at(tile, 0.2 + _unit(tile, 50) * 0.3, 0.2 + _unit(tile, 51) * 0.3)
	var mid := start + Vector2(_unit(tile, 52) * 12.0 - 4.0, 5)
	draw_polyline(PackedVector2Array([start, mid, mid + Vector2(6, 4)]), color, 1.0)


## Paving joints along both tile axes.
func _paving(tile: Vector2i, color: Color) -> void:
	draw_line(_at(tile, 0.5, 0.0), _at(tile, 0.5, 1.0), Color(color, 0.5), 1.0)
	draw_line(_at(tile, 0.0, 0.5), _at(tile, 1.0, 0.5), Color(color, 0.5), 1.0)


## Dark line along one side of a tile (`step` points to the neighbour).
func _edge(tile: Vector2i, step: Vector2i, color: Color) -> void:
	var corners := WorldService.rect_polygon(Rect2i(tile, Vector2i.ONE))
	var centre := _at(tile, 0.5, 0.5)
	var pair: Array[int]
	if step == Vector2i(1, 0):
		pair = [1, 2]
	elif step == Vector2i(0, 1):
		pair = [2, 3]
	elif step == Vector2i(-1, 0):
		pair = [3, 0]
	else:
		pair = [0, 1]
	var a := corners[pair[0]] + (centre - corners[pair[0]]).normalized() * 1.5
	var b := corners[pair[1]] + (centre - corners[pair[1]]).normalized() * 1.5
	draw_line(a, b, color, 2.0)


static func _hash(x: int, y: int, salt: int) -> int:
	var h := (x * 73856093) ^ (y * 19349663) ^ (salt * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	return absi(h ^ (h >> 16))


static func _unit(tile: Vector2i, salt: int) -> float:
	return float(_hash(tile.x, tile.y, salt) % 1000) / 1000.0
