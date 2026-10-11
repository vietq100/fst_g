class_name WorldService
extends RefCounted
## Isometric world geometry (DECISIONS.md D27): tile ↔ world, regions, gates between
## neighbouring regions, region lookup. Pure geometry: no Nodes, no gameplay rules.
## Tile (gx, gy) → world ((gx − gy) × 32, (gx + gy) × 16); a tile's diamond has its top corner there.

const TILE_W := 64.0
const TILE_H := 32.0
## Gates are this many tiles wide (the corridor between two regions).
const GATE_WIDTH := 2

## A passage between two regions across the 2-tile gap.
class Gate:
	var region_a: StringName
	var region_b: StringName
	## Tiles of the corridor (inside the gap).
	var tiles: Rect2i
	## Middle of the corridor in world space.
	var center: Vector2

var _regions: Array[RegionDefinition] = []
var _gates: Array[Gate] = []


func _init(registry: Node) -> void:
	for definition in registry.get_all(&"region"):
		_regions.append(definition as RegionDefinition)
	_regions.sort_custom(func(a: RegionDefinition, b: RegionDefinition) -> bool: return String(a.id) < String(b.id))
	_find_gates()


static func tile_to_world(tile: Vector2) -> Vector2:
	return Vector2((tile.x - tile.y) * TILE_W * 0.5, (tile.x + tile.y) * TILE_H * 0.5)


## Fractional tile coordinates of a world point.
static func world_to_tile(point: Vector2) -> Vector2:
	var a := point.x / (TILE_W * 0.5)
	var b := point.y / (TILE_H * 0.5)
	return Vector2((a + b) * 0.5, (b - a) * 0.5)


static func tile_at(point: Vector2) -> Vector2i:
	var tile := world_to_tile(point)
	return Vector2i(floori(tile.x), floori(tile.y))


## Centre of a tile in world space.
static func tile_center(tile: Vector2i) -> Vector2:
	return tile_to_world(Vector2(tile) + Vector2(0.5, 0.5))


## World-space diamond (top, right, bottom, left) covering a tile rectangle.
static func rect_polygon(rect: Rect2i, grow: float = 0.0) -> PackedVector2Array:
	var top := Vector2(rect.position) - Vector2(grow, grow)
	var size := Vector2(rect.size) + Vector2(grow, grow) * 2.0
	return PackedVector2Array([
		tile_to_world(top),
		tile_to_world(top + Vector2(size.x, 0)),
		tile_to_world(top + size),
		tile_to_world(top + Vector2(0, size.y)),
	])


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


## The region containing a world point, or null (gates, outside).
func region_at(point: Vector2) -> RegionDefinition:
	var tile := tile_at(point)
	for region in _regions:
		if region.tile_rect.has_point(tile):
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


## Walkable outlines: every region diamond plus every gate corridor (overlapping the regions
## by one tile so the baked mesh connects).
func navigation_outlines() -> Array[PackedVector2Array]:
	var outlines: Array[PackedVector2Array] = []
	for region in _regions:
		outlines.append(rect_polygon(region.tile_rect))
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
			var gate := _gate_between(a, b)
			if gate.size == Vector2i.ZERO:
				continue
			var entry := Gate.new()
			entry.region_a = _regions[i].id
			entry.region_b = _regions[j].id
			entry.tiles = gate
			entry.center = tile_to_world(Vector2(gate.position) + Vector2(gate.size) * 0.5)
			_gates.append(entry)


static func _gate_between(a: Rect2i, b: Rect2i) -> Rect2i:
	for flip in [false, true]:
		var first := b if flip else a
		var second := a if flip else b
		# Gap along x (first left of second), overlap along y.
		if second.position.x - first.end.x == GATE_WIDTH:
			var y0 := maxi(first.position.y, second.position.y)
			var y1 := mini(first.end.y, second.end.y)
			if y1 - y0 >= GATE_WIDTH:
				var mid := (y0 + y1) / 2 - GATE_WIDTH / 2
				return Rect2i(first.end.x, mid, GATE_WIDTH, GATE_WIDTH)
		# Gap along y, overlap along x.
		if second.position.y - first.end.y == GATE_WIDTH:
			var x0 := maxi(first.position.x, second.position.x)
			var x1 := mini(first.end.x, second.end.x)
			if x1 - x0 >= GATE_WIDTH:
				var mid := (x0 + x1) / 2 - GATE_WIDTH / 2
				return Rect2i(mid, first.end.y, GATE_WIDTH, GATE_WIDTH)
	return Rect2i()
