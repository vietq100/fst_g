class_name TownBuilding
extends StaticBody2D
## A placed building in the world: navigation obstacle + isometric visual, synced with
## BuildingService. Positioned at its footprint's bottom (south) corner (see BuildingVisual).

var instance_id: StringName
var building_id: StringName
var visual: BuildingVisual
var _tile := Vector2i.ZERO
var _shape: CollisionPolygon2D


func _init() -> void:
	add_to_group(&"navigation_obstacles")
	collision_layer = 1
	collision_mask = 0
	visual = BuildingVisual.new()
	add_child(visual)
	_shape = CollisionPolygon2D.new()
	add_child(_shape)


## World position of a building anchored at `tile` with `footprint`: the footprint's south corner.
static func origin_for(tile: Vector2i, footprint: Vector2i) -> Vector2:
	return WorldService.tile_to_world(Vector2(tile + footprint))


func setup(placed: BuildingService.Placed, definition: BuildingDefinition) -> void:
	instance_id = placed.instance_id
	building_id = placed.building_id
	name = String(instance_id)
	visual.building_id = building_id
	visual.footprint = definition.footprint
	visual.title = definition.get_name_key()
	refresh(placed)
	# Slightly smaller than the footprint so Hunters can walk along the walls.
	_shape.polygon = BuildingVisual._grow(visual.get_corners(), -3.0)


func refresh(placed: BuildingService.Placed) -> void:
	visual.level = placed.level
	_tile = placed.tile
	position = origin_for(placed.tile, visual.footprint)


## World point in front of the building door: the centre of the door tile
## (BuildingService.get_door_tile, on the south-west face).
func get_door_point() -> Vector2:
	return WorldService.tile_center(BuildingService.get_door_tile(Rect2i(_tile, visual.footprint)))


## Area (world units) that selects this building on tap: everything it draws (footprint
## diamond, walls and roof).
func hit_test(world_point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(world_point - global_position, visual.get_hit_polygon())
