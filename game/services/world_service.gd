class_name WorldService
extends RefCounted
## Isometric world geometry (DECISIONS.md D55, back to the projection of D27): tile ↔ world,
## regions, gates (bridges) between neighbouring regions, region lookup. Pure geometry: no Nodes,
## no gameplay rules. 2:1 isometric, tile 44 × 22 px (70% of D27's 64 × 32, D56): tile (gx, gy)
## → world ((gx − gy) × 22, (gx + gy) × 11); a tile's diamond has its top corner there. The tile x axis
## runs down-right on screen, the tile y axis down-left. Buildings are boxes with their two front
## faces (+y side = south-west, +x side = south-east) visible.

## Diamond width (one tile along either axis moves HALF_WIDTH right/left and HALF_HEIGHT down).
const TILE_WIDTH := 44.0
const TILE_HEIGHT := 22.0
const HALF_WIDTH := TILE_WIDTH * 0.5
const HALF_HEIGHT := TILE_HEIGHT * 0.5
## Kept for callers that need "about one tile" in world units (the diamond's half width).
const TILE := HALF_WIDTH
## Gates are this many tiles wide (the bridge between two regions).
const GATE_WIDTH := 2

## A passage between two regions across the 2-tile gap.
class Gate:
	var region_a: StringName
	var region_b: StringName
	## Tiles of the corridor (inside the gap).
	var tiles: Rect2i
	## Middle of the corridor in world space.
	var center: Vector2
	## Direction of travel across the gap in tile space: (1, 0) for a gap along x, (0, 1) along y.
	var axis: Vector2i = Vector2i(1, 0)


var _regions: Array[RegionDefinition] = []
var _gates: Array[Gate] = []
## Dungeon entrance tiles per region id (kept clear when shaping the regions).
var _entrances: Dictionary[StringName, Array] = {}
## Region id → its tiles (the organic shape, D57): a subset of `tile_rect`.
var _shapes: Dictionary[StringName, Dictionary] = {}
var _shape_lists: Dictionary[StringName, Array] = {}
var _outlines: Dictionary[StringName, PackedVector2Array] = {}
## Every ground tile of every region (for "is there land next to this tile").
var _land: Dictionary[Vector2i, bool] = {}

## Corner radius (tiles) of the Town and of the hunting regions (D57): the rectangle's corners
## are rounded along a quarter circle, the edges stay straight.
const TOWN_CORNER := 6
const WILD_CORNER := 8
## Tiles this close to a gate corridor or a dungeon entrance always stay ground.
const GATE_CLEARANCE := 3
## Depth (tiles) of the straight band of ground along a border shared with another region.
const BORDER_BAND := 16
## One bridge per this many tiles of shared border (1 to 3 bridges).
const BRIDGE_SPACING := 24
const ENTRANCE_CLEARANCE := 2


func _init(registry: Node) -> void:
	for definition in registry.get_all(&"region"):
		_regions.append(definition as RegionDefinition)
	_regions.sort_custom(func(a: RegionDefinition, b: RegionDefinition) -> bool: return String(a.id) < String(b.id))
	for definition in registry.get_all(&"expedition"):
		var region_id: StringName = definition.get("region_id")
		if region_id == &"" or region_id == null:
			continue
		if not _entrances.has(region_id):
			_entrances[region_id] = []
		_entrances[region_id].append(definition.get("entrance_tile"))
	_find_gates()
	for region in _regions:
		_build_shape(region)
	_finish_shapes()


## True when any region has ground on `tile`.
func is_land(tile: Vector2i) -> bool:
	return _land.has(tile)


static func tile_to_world(tile: Vector2) -> Vector2:
	return Vector2((tile.x - tile.y) * HALF_WIDTH, (tile.x + tile.y) * HALF_HEIGHT)


## Fractional tile coordinates of a world point (inverse projection).
static func world_to_tile(point: Vector2) -> Vector2:
	var a := point.x / HALF_WIDTH
	var b := point.y / HALF_HEIGHT
	return Vector2((a + b) * 0.5, (b - a) * 0.5)


## World point of a fractional tile position lifted `height` px off the ground.
static func tile_to_world_at(tile: Vector2, height: float) -> Vector2:
	return tile_to_world(tile) + Vector2(0, -height)


static func tile_at(point: Vector2) -> Vector2i:
	var tile := world_to_tile(point)
	return Vector2i(floori(tile.x), floori(tile.y))


## Centre of a tile in world space.
static func tile_center(tile: Vector2i) -> Vector2:
	return tile_to_world(Vector2(tile) + Vector2(0.5, 0.5))


## World-space diamond (top, right, bottom, left corners) covering a tile rectangle.
static func rect_polygon(rect: Rect2i, grow: float = 0.0) -> PackedVector2Array:
	var top := Vector2(rect.position) - Vector2(grow, grow)
	var size := Vector2(rect.size) + Vector2(grow, grow) * 2.0
	return PackedVector2Array([
		tile_to_world(top),
		tile_to_world(top + Vector2(size.x, 0)),
		tile_to_world(top + size),
		tile_to_world(top + Vector2(0, size.y)),
	])


## Diamond (top, right, bottom, left) covering a fractional tile rectangle.
static func quad(origin: Vector2, size: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		tile_to_world(origin),
		tile_to_world(origin + Vector2(size.x, 0)),
		tile_to_world(origin + size),
		tile_to_world(origin + Vector2(0, size.y)),
	])


## Axis-aligned world bounds of a tile rectangle's diamond.
static func rect_to_world(rect: Rect2i) -> Rect2:
	var polygon := rect_polygon(rect)
	var bounds := Rect2(polygon[0], Vector2.ZERO)
	for corner in polygon:
		bounds = bounds.expand(corner)
	return bounds


## True if a world point lies inside a tile rectangle's diamond.
static func rect_has_point(rect: Rect2i, point: Vector2) -> bool:
	var tile := world_to_tile(point)
	return tile.x >= rect.position.x and tile.x < rect.end.x and tile.y >= rect.position.y and tile.y < rect.end.y


## The Town's decorative pond (near the top corner): blocks building placement and walking.
func get_town_pond() -> Rect2i:
	var town := get_town()
	if town == null:
		return Rect2i()
	return Rect2i(town.tile_rect.position + Vector2i(6, 4), Vector2i(5, 4))


# --- Region shapes (D57) ----------------------------------------------------------------------

## The tiles of a region: its rectangle with rounded corners and gently wandering edges.
func region_tiles(region_id: StringName) -> Dictionary:
	return _shapes.get(region_id, {})


## The same tiles as an array (for random picks).
func region_tile_list(region_id: StringName) -> Array:
	return _shape_lists.get(region_id, [])


func has_tile(region: RegionDefinition, tile: Vector2i) -> bool:
	return region != null and _shapes.get(region.id, {}).has(tile)


## Walkable outline polygon of a region's shape (world space).
func region_outline(region: RegionDefinition) -> PackedVector2Array:
	return _outlines.get(region.id, rect_polygon(region.tile_rect))


## The rectangle with its four corners rounded along a quarter circle (straight edges
## otherwise); tiles near a gate corridor, a dungeon entrance or the pond always stay ground so
## bridges, ledges and the shore line up.
func _build_shape(region: RegionDefinition) -> void:
	if region.shape != RegionDefinition.Shape.ROUNDED:
		_build_free_shape(region)
		return
	var rect := region.tile_rect
	var radius := TOWN_CORNER if region.is_town else WILD_CORNER
	if not region.is_town and region.kind != RegionDefinition.Kind.HUNTING:
		radius = maxi(mini(rect.size.x, rect.size.y) / 4, 2)
	var protected: Dictionary[Vector2i, bool] = {}
	for gate in gates_of(region.id):
		_protect(protected, gate.tiles.grow(GATE_CLEARANCE), rect)
	for entrance: Vector2i in _entrances.get(region.id, []):
		_protect(protected, Rect2i(entrance, Vector2i.ONE).grow(ENTRANCE_CLEARANCE), rect)
	if region.is_town:
		_protect(protected, get_town_pond().grow(1), rect)
	var shape: Dictionary[Vector2i, bool] = {}
	var tiles: Array[Vector2i] = []
	for gx in range(rect.position.x, rect.end.x):
		for gy in range(rect.position.y, rect.end.y):
			var tile := Vector2i(gx, gy)
			var dl := gx - rect.position.x
			var dr := rect.end.x - 1 - gx
			var dt := gy - rect.position.y
			var db := rect.end.y - 1 - gy
			var keep := protected.has(tile) or (_in_corner(dl, dt, radius) and _in_corner(dr, dt, radius)
					and _in_corner(dr, db, radius) and _in_corner(dl, db, radius))
			if keep:
				shape[tile] = true
				tiles.append(tile)
	_shapes[region.id] = shape
	_shape_lists[region.id] = tiles
	_outlines[region.id] = _merge_rows(shape, rect)


## Free-form hunting regions: the tiles of `tile_rect` for which the style's function says "inside",
## plus a corridor (5 tiles wide) from the centre to every gate and dungeon entrance so each
## bridge and ledge always connects to the main body, and a disc around the centre.
func _build_free_shape(region: RegionDefinition) -> void:
	var rect := region.tile_rect
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = hash(String(region.id)) & 0xFFFF
	noise.frequency = 1.0
	var half := Vector2(rect.size) * 0.5
	var centre := Vector2(rect.position) + half
	var protected: Dictionary[Vector2i, bool] = {}
	var anchors: Array[Vector2] = []
	for gate in gates_of(region.id):
		_protect(protected, gate.tiles.grow(GATE_CLEARANCE), rect)
		anchors.append(Vector2(gate.tiles.position) + Vector2(gate.tiles.size) * 0.5)
		# The side that faces a neighbour is a straight band of ground along the shared border.
		var info := _border_info(gate, region.id)
		if not info.is_empty():
			_protect(protected, info["band"], rect)
	for entrance: Vector2i in _entrances.get(region.id, []):
		_protect(protected, Rect2i(entrance, Vector2i.ONE).grow(ENTRANCE_CLEARANCE), rect)
		anchors.append(Vector2(entrance) + Vector2(0.5, 0.5))
	for anchor in anchors:
		_protect_corridor(protected, centre, anchor, 2.5, rect)
	_protect_disc(protected, centre, 5.0, rect)
	var shape: Dictionary[Vector2i, bool] = {}
	var tiles: Array[Vector2i] = []
	for gx in range(rect.position.x, rect.end.x):
		for gy in range(rect.position.y, rect.end.y):
			var tile := Vector2i(gx, gy)
			var u := (gx + 0.5 - centre.x) / half.x
			var v := (gy + 0.5 - centre.y) / half.y
			var edge := noise.get_noise_2d(gx * 0.05, gy * 0.05) * 0.10
			if protected.has(tile) or _free_inside(region.shape, u, v, edge, noise):
				shape[tile] = true
				tiles.append(tile)
	_smooth_shape(shape, protected, rect)
	tiles.clear()
	for tile: Vector2i in shape:
		tiles.append(tile)
	_keep_main_body(shape, tiles, Vector2i(floori(centre.x), floori(centre.y)))
	_shapes[region.id] = shape
	_shape_lists[region.id] = tiles
	_outlines[region.id] = _merge_rows(shape, rect)


## Tidies a free shape: a majority filter removes single-tile spurs and nicks, then every pocket of
## water that does not reach the rectangle's border is filled (no lakes inside a region).
static func _smooth_shape(shape: Dictionary[Vector2i, bool], protected: Dictionary[Vector2i, bool], rect: Rect2i) -> void:
	for pass_index in 2:
		var add: Array[Vector2i] = []
		var remove: Array[Vector2i] = []
		for gx in range(rect.position.x, rect.end.x):
			for gy in range(rect.position.y, rect.end.y):
				var tile := Vector2i(gx, gy)
				var count := 0
				for dx in range(-1, 2):
					for dy in range(-1, 2):
						if (dx != 0 or dy != 0) and shape.has(tile + Vector2i(dx, dy)):
							count += 1
				if shape.has(tile):
					if count <= 3 and not protected.has(tile):
						remove.append(tile)
				elif count >= 6:
					add.append(tile)
		for tile in remove:
			shape.erase(tile)
		for tile in add:
			shape[tile] = true
	# Fill pockets of water: flood the outside from the border of the rectangle.
	var outside: Dictionary[Vector2i, bool] = {}
	var queue: Array[Vector2i] = []
	for gx in range(rect.position.x - 1, rect.end.x + 1):
		queue.append(Vector2i(gx, rect.position.y - 1))
		queue.append(Vector2i(gx, rect.end.y))
	for gy in range(rect.position.y - 1, rect.end.y + 1):
		queue.append(Vector2i(rect.position.x - 1, gy))
		queue.append(Vector2i(rect.end.x, gy))
	for tile in queue:
		outside[tile] = true
	while not queue.is_empty():
		var tile: Vector2i = queue.pop_back()
		for step in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
			var next: Vector2i = tile + step
			if next.x < rect.position.x - 1 or next.y < rect.position.y - 1 or next.x > rect.end.x or next.y > rect.end.y:
				continue
			if not outside.has(next) and not shape.has(next):
				outside[next] = true
				queue.append(next)
	for gx in range(rect.position.x, rect.end.x):
		for gy in range(rect.position.y, rect.end.y):
			var tile := Vector2i(gx, gy)
			if not shape.has(tile) and not outside.has(tile):
				shape[tile] = true


## Inside test of a free style at normalised coordinates (u, v in -1..1), `edge` the wobble.
static func _free_inside(style: RegionDefinition.Shape, u: float, v: float, edge: float, noise: FastNoiseLite) -> bool:
	match style:
		RegionDefinition.Shape.WINDING:
			# Four glades along an S-shaped path.
			var glades := [[-0.5, -0.45, 0.58, 0.45], [-0.12, -0.08, 0.6, 0.52], [0.22, 0.28, 0.58, 0.5], [0.55, 0.58, 0.5, 0.44]]
			for glade: Array in glades:
				var dx: float = (u - glade[0]) / glade[2]
				var dy: float = (v - glade[1]) / glade[3]
				if dx * dx + dy * dy < 1.0 + edge * 2.4:
					return true
			return false
		RegionDefinition.Shape.LOBED:
			# Radial blob: the reach changes with the angle, giving peninsulas and bays.
			var angle := atan2(v, u)
			var reach := 0.62 + 0.40 * (noise.get_noise_2d(cos(angle) * 1.6 + 7.0, sin(angle) * 1.6 + 7.0) * 0.5 + 0.5) + edge * 0.6
			return sqrt(u * u + v * v) < reach
		RegionDefinition.Shape.CROSS:
			var arm := 0.31 + edge * 0.5
			var in_plus := (absf(u) < arm and absf(v) < 0.96) or (absf(v) < arm and absf(u) < 0.96)
			var cu := absf(u) - 0.6
			var cv := absf(v) - 0.6
			var in_court := cu * cu + cv * cv < 0.37 * 0.37 + edge * 0.4
			return in_plus or in_court
	return true


## Where a gate's region faces its neighbour across the channel: {"band": the ground band inside
## this region along the border (BORDER_BAND deep), so facing coasts are straight}.
func _border_info(gate: Gate, region_id: StringName) -> Dictionary:
	var a := get_region(gate.region_a)
	var b := get_region(gate.region_b)
	var mine := a if a.id == region_id else b
	var other := b if a.id == region_id else a
	var r := mine.tile_rect
	var o := other.tile_rect
	if gate.axis == Vector2i(1, 0):
		var y0 := maxi(r.position.y, o.position.y)
		var y1 := mini(r.end.y, o.end.y)
		if o.position.x >= r.end.x:
			return {"band": Rect2i(r.end.x - BORDER_BAND, y0, BORDER_BAND, y1 - y0), "edge": Rect2i(r.end.x - 1, y0, 1, y1 - y0),
				"outside": Rect2i(r.end.x, y0, 1, y1 - y0)}
		return {"band": Rect2i(r.position.x, y0, BORDER_BAND, y1 - y0), "edge": Rect2i(r.position.x, y0, 1, y1 - y0),
			"outside": Rect2i(r.position.x - 1, y0, 1, y1 - y0)}
	var x0 := maxi(r.position.x, o.position.x)
	var x1 := mini(r.end.x, o.end.x)
	if o.position.y >= r.end.y:
		return {"band": Rect2i(x0, r.end.y - BORDER_BAND, x1 - x0, BORDER_BAND), "edge": Rect2i(x0, r.end.y - 1, x1 - x0, 1),
			"outside": Rect2i(x0, r.end.y, x1 - x0, 1)}
	return {"band": Rect2i(x0, r.position.y, x1 - x0, BORDER_BAND), "edge": Rect2i(x0, r.position.y, x1 - x0, 1),
		"outside": Rect2i(x0, r.position.y - 1, x1 - x0, 1)}


## Outlines (navigation) and the global land lookup, once every shape exists.
func _finish_shapes() -> void:
	for region in _regions:
		_outlines[region.id] = _merge_rows(_shapes[region.id], _bounds_of(_shapes[region.id]))
	_land.clear()
	for region in _regions:
		for tile: Vector2i in _shapes[region.id]:
			_land[tile] = true


static func _bounds_of(shape: Dictionary[Vector2i, bool]) -> Rect2i:
	var low := Vector2i(1 << 30, 1 << 30)
	var high := Vector2i(-(1 << 30), -(1 << 30))
	for tile: Vector2i in shape:
		low = Vector2i(mini(low.x, tile.x), mini(low.y, tile.y))
		high = Vector2i(maxi(high.x, tile.x), maxi(high.y, tile.y))
	return Rect2i(low, high - low + Vector2i.ONE)


static func _protect_corridor(protected: Dictionary[Vector2i, bool], from: Vector2, to: Vector2, radius: float, rect: Rect2i) -> void:
	var length := from.distance_to(to)
	var steps := maxi(int(length * 2.0), 1)
	for i in steps + 1:
		_protect_disc(protected, from.lerp(to, float(i) / steps), radius, rect)


static func _protect_disc(protected: Dictionary[Vector2i, bool], centre: Vector2, radius: float, rect: Rect2i) -> void:
	for gx in range(floori(centre.x - radius), ceili(centre.x + radius) + 1):
		for gy in range(floori(centre.y - radius), ceili(centre.y + radius) + 1):
			var tile := Vector2i(gx, gy)
			if rect.has_point(tile) and Vector2(gx + 0.5, gy + 0.5).distance_to(centre) <= radius:
				protected[tile] = true


## Drops tiles that are not connected (4-neighbour) to the centre tile, so a region is one piece.
static func _keep_main_body(shape: Dictionary[Vector2i, bool], tiles: Array[Vector2i], seed_tile: Vector2i) -> void:
	if not shape.has(seed_tile):
		return
	var seen: Dictionary[Vector2i, bool] = {seed_tile: true}
	var queue: Array[Vector2i] = [seed_tile]
	while not queue.is_empty():
		var tile: Vector2i = queue.pop_back()
		for step in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
			var next: Vector2i = tile + step
			if shape.has(next) and not seen.has(next):
				seen[next] = true
				queue.append(next)
	for tile in shape.keys():
		if not seen.has(tile):
			shape.erase(tile)
	tiles.clear()
	for tile: Vector2i in seen:
		tiles.append(tile)


static func _protect(protected: Dictionary[Vector2i, bool], area: Rect2i, rect: Rect2i) -> void:
	var clipped := area.intersection(rect)
	for gx in range(clipped.position.x, clipped.end.x):
		for gy in range(clipped.position.y, clipped.end.y):
			protected[Vector2i(gx, gy)] = true


## A tile `a` and `b` tiles from the two edges of a corner is inside the rounded corner
## (quarter circle of `radius` tiles) unless it lies outside the circle.
static func _in_corner(a: int, b: int, radius: int) -> bool:
	if a >= radius or b >= radius:
		return true
	var dx := radius - 0.5 - a
	var dy := radius - 0.5 - b
	return dx * dx + dy * dy <= radius * radius


## One polygon for the shape: each row's runs of tiles as diamonds, merged together. Pieces that
## only join up in later rows (a dungeon ledge corridor, a peninsula) are kept apart until then.
static func _merge_rows(shape: Dictionary[Vector2i, bool], rect: Rect2i) -> PackedVector2Array:
	var pieces: Array[PackedVector2Array] = []
	for gy in range(rect.position.y, rect.end.y):
		var gx := rect.position.x
		while gx < rect.end.x:
			if not shape.has(Vector2i(gx, gy)):
				gx += 1
				continue
			var start := gx
			while gx < rect.end.x and shape.has(Vector2i(gx, gy)):
				gx += 1
			var run := quad(Vector2(start, gy), Vector2(gx - start, 1))
			var remaining: Array[PackedVector2Array] = []
			for piece in pieces:
				var result := Geometry2D.merge_polygons(run, piece)
				var joined := PackedVector2Array()
				var joined_area := 0.0
				for polygon in result:
					var area := absf(_area(polygon))
					if area > joined_area:
						joined_area = area
						joined = polygon
				# Separate shapes come back unchanged; touching ones as one bigger outline.
				if joined_area > maxf(absf(_area(run)), absf(_area(piece))) + 1.0:
					run = joined
				else:
					remaining.append(piece)
			remaining.append(run)
			pieces = remaining
	var best := PackedVector2Array()
	var best_area := 0.0
	for piece in pieces:
		var area := absf(_area(piece))
		if area > best_area:
			best_area = area
			best = piece
	return best if not best.is_empty() else rect_polygon(rect)


static func _area(polygon: PackedVector2Array) -> float:
	var total := 0.0
	for i in polygon.size():
		var a := polygon[i]
		var b := polygon[(i + 1) % polygon.size()]
		total += a.x * b.y - b.x * a.y
	return total * 0.5


func get_regions() -> Array[RegionDefinition]:
	return _regions


func get_region(region_id: StringName) -> RegionDefinition:
	for region in _regions:
		if region.id == region_id:
			return region
	return null


func get_town() -> RegionDefinition:
	for region in _regions:
		if region.is_town:
			return region
	return null


## The region containing a world point, or null (gates, water, outside).
func region_at(point: Vector2) -> RegionDefinition:
	var tile := tile_at(point)
	for region in _regions:
		if _shapes.get(region.id, {}).has(tile):
			return region
	return null


func region_center(region: RegionDefinition) -> Vector2:
	return tile_to_world(Vector2(region.tile_rect.position) + Vector2(region.tile_rect.size) * 0.5)


func get_gates() -> Array[Gate]:
	return _gates


## Gates touching a region.
func gates_of(region_id: StringName) -> Array[Gate]:
	return _gates.filter(func(gate: Gate) -> bool: return gate.region_a == region_id or gate.region_b == region_id)


## Where a party gathers before a dungeon and where it comes out: the entrance pulled
## `inside` px towards the centre of its region (the entrance tile itself is off the map).
func get_entrance_point(definition: ExpeditionDefinition, inside: float = 48.0) -> Vector2:
	var door := tile_center(definition.entrance_tile)
	var region := get_region(definition.region_id)
	if region == null:
		return door
	return door + (region_center(region) - door).normalized() * inside


## World bounds of everything (regions + a margin).
func get_bounds(margin: float = 64.0) -> Rect2:
	var bounds := Rect2()
	var first := true
	for region in _regions:
		for corner in rect_polygon(region.tile_rect):
			if first:
				bounds = Rect2(corner, Vector2.ZERO)
				first = false
			else:
				bounds = bounds.expand(corner)
	return bounds.grow(margin)


## Walkable outlines: every region shape plus every gate corridor (overlapping the regions
## by one tile so the baked mesh connects).
func navigation_outlines() -> Array[PackedVector2Array]:
	var outlines: Array[PackedVector2Array] = []
	for region in _regions:
		outlines.append(region_outline(region))
	for gate in _gates:
		outlines.append(rect_polygon(gate.tiles.grow(1)))
	return outlines


## Two regions separated by a gap of GATE_WIDTH tiles along one axis and overlapping along the
## other get a gate in the middle of the shared edge.
func _find_gates() -> void:
	for i in _regions.size():
		for j in range(i + 1, _regions.size()):
			var a := _regions[i].tile_rect
			var b := _regions[j].tile_rect
			for gate in _gates_between(a, b):
				var entry := Gate.new()
				entry.region_a = _regions[i].id
				entry.region_b = _regions[j].id
				entry.tiles = gate
				entry.center = tile_to_world(Vector2(gate.position) + Vector2(gate.size) * 0.5)
				entry.axis = Vector2i(1, 0) if gate.position.x >= a.end.x or gate.end.x <= a.position.x else Vector2i(0, 1)
				_gates.append(entry)


## Bridges across the gap between two rectangles: a long shared border gets several (one per
## `BRIDGE_SPACING` tiles of overlap, at least one), spread evenly.
static func _gates_between(a: Rect2i, b: Rect2i) -> Array[Rect2i]:
	var result: Array[Rect2i] = []
	for flip in [false, true]:
		var first := b if flip else a
		var second := a if flip else b
		# Gap along x (first left of second), overlap along y.
		if second.position.x - first.end.x == GATE_WIDTH:
			var y0 := maxi(first.position.y, second.position.y)
			var y1 := mini(first.end.y, second.end.y)
			if y1 - y0 >= GATE_WIDTH:
				for t in _bridge_positions(y0, y1):
					result.append(Rect2i(first.end.x, t, GATE_WIDTH, GATE_WIDTH))
				return result
		# Gap along y, overlap along x.
		if second.position.y - first.end.y == GATE_WIDTH:
			var x0 := maxi(first.position.x, second.position.x)
			var x1 := mini(first.end.x, second.end.x)
			if x1 - x0 >= GATE_WIDTH:
				for t in _bridge_positions(x0, x1):
					result.append(Rect2i(t, first.end.y, GATE_WIDTH, GATE_WIDTH))
				return result
	return result


## Start tiles of the bridges along an overlap of [from, to).
static func _bridge_positions(from: int, to: int) -> Array[int]:
	var count := clampi((to - from) / BRIDGE_SPACING, 1, 3)
	var positions: Array[int] = []
	for i in count:
		var mid := from + int((to - from) * (i + 0.5) / count)
		positions.append(mid - GATE_WIDTH / 2)
	return positions
