class_name TownBuilding
extends StaticBody2D
## A placed building in the world: navigation obstacle + front-facing visual, synced with
## BuildingService. Positioned at the middle of its footprint's bottom edge (see BuildingVisual).

var instance_id: StringName
var building_id: StringName
var visual: BuildingVisual
var _shape: CollisionPolygon2D


func _init() -> void:
	add_to_group(&"navigation_obstacles")
	collision_layer = 1
	collision_mask = 0
	visual = BuildingVisual.new()
	add_child(visual)
	_shape = CollisionPolygon2D.new()
	add_child(_shape)


## World position of a building anchored at `tile` with `footprint`: bottom-centre of the footprint.
static func origin_for(tile: Vector2i, footprint: Vector2i) -> Vector2:
	return WorldService.tile_to_world(Vector2(tile) + Vector2(footprint.x * 0.5, footprint.y))


func setup(placed: BuildingService.Placed, definition: BuildingDefinition) -> void:
	instance_id = placed.instance_id
	building_id = placed.building_id
	name = String(instance_id)
	visual.building_id = building_id
	visual.footprint = definition.footprint
	visual.title = definition.display_name
	refresh(placed)
	# Slightly smaller than the footprint so Hunters can walk along the walls.
	_shape.polygon = BuildingVisual._grow(visual.get_corners(), -3.0)


func refresh(placed: BuildingService.Placed) -> void:
	visual.level = placed.level
	position = origin_for(placed.tile, visual.footprint)


## World point in front of the building door (middle of the bottom face).
func get_door_point() -> Vector2:
	return global_position + Vector2(0, 12)


## Area (world units) that selects this building on tap: the footprint plus the wall and roof.
func hit_test(world_point: Vector2) -> bool:
	var corners := visual.get_corners()
	var local := world_point - global_position
	var height := visual.get_height()
	var area := Rect2(Vector2(corners[3].x - 6.0, -height), Vector2(visual.get_width() + 12.0, height + 6.0))
	return area.has_point(local)
