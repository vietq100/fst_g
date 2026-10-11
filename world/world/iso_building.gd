class_name IsoBuilding
extends StaticBody2D
## A placed building in the world: navigation obstacle + isometric visual, synced with
## BuildingService. Positioned at its footprint's bottom corner (see IsoBuildingVisual).

var instance_id: StringName
var building_id: StringName
var visual: IsoBuildingVisual
var _shape: CollisionPolygon2D


func _init() -> void:
	add_to_group(&"navigation_obstacles")
	collision_layer = 1
	collision_mask = 0
	visual = IsoBuildingVisual.new()
	add_child(visual)
	_shape = CollisionPolygon2D.new()
	add_child(_shape)


func setup(placed: BuildingService.Placed, definition: BuildingDefinition) -> void:
	instance_id = placed.instance_id
	building_id = placed.building_id
	name = String(instance_id)
	visual.building_id = building_id
	visual.footprint = definition.footprint
	visual.title = definition.display_name
	refresh(placed)
	# Slightly smaller than the footprint so Hunters can walk along the walls.
	_shape.polygon = IsoBuildingVisual._grow(visual.get_corners(), -3.0)


func refresh(placed: BuildingService.Placed) -> void:
	visual.level = placed.level
	position = WorldService.tile_to_world(Vector2(placed.tile + visual.footprint))


## World point in front of the building door (front-right face).
func get_door_point() -> Vector2:
	var corners := visual.get_corners()
	return global_position + corners[2].lerp(corners[1], 0.5) + Vector2(14, 10)


## Screen-space-ish area (world units) that selects this building on tap.
func hit_test(world_point: Vector2) -> bool:
	var corners := visual.get_corners()
	var local := world_point - global_position
	var height := visual.get_height()
	if Geometry2D.is_point_in_polygon(local, corners):
		return true
	# The walls and roof above the footprint.
	return local.x >= corners[3].x and local.x <= corners[1].x and local.y <= 0.0 and local.y >= corners[0].y - height
