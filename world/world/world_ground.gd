extends Node2D
## Isometric ground for every region and gate corridor (WORLD_DESIGN.md → Biome identity).
## Drawn once (static); roads in the Town lead from the Town Hall to each gate.

const ROAD := Color("a88a63")
const CORRIDOR := Color("6d5a44")
const EDGE := Color(0, 0, 0, 0.35)

var world: WorldService
## Tiles drawn as road inside the Town.
var road_tiles: Dictionary[Vector2i, bool] = {}


func setup(world_service: WorldService, town_roads: Dictionary[Vector2i, bool]) -> void:
	world = world_service
	road_tiles = town_roads
	queue_redraw()


func _draw() -> void:
	if world == null:
		return
	for region in world.get_regions():
		var rect := region.tile_rect
		for gx in range(rect.position.x, rect.end.x):
			for gy in range(rect.position.y, rect.end.y):
				var tile := Vector2i(gx, gy)
				var color := region.ground_color if (gx * 7 + gy * 3) % 5 != 0 else region.ground_alt_color
				if region.is_town and road_tiles.has(tile):
					color = ROAD
				_tile(tile, color)
		draw_polyline(WorldService.rect_polygon(rect) + PackedVector2Array([WorldService.rect_polygon(rect)[0]]), EDGE, 2.0)
	for gate in world.get_gates():
		for gx in range(gate.tiles.position.x, gate.tiles.end.x):
			for gy in range(gate.tiles.position.y, gate.tiles.end.y):
				_tile(Vector2i(gx, gy), CORRIDOR)


func _tile(tile: Vector2i, color: Color) -> void:
	var points := WorldService.rect_polygon(Rect2i(tile, Vector2i.ONE))
	draw_colored_polygon(points, color)
