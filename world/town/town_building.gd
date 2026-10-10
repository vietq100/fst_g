class_name TownBuilding
extends StaticBody2D
## A building in the town scene: navigation obstacle + visual, synced with BuildingService.
## Origin is the middle of the front wall base; the collision covers the footprint behind it.

@export var building_id: StringName

@onready var visual: BuildingVisual = $Visual


func _ready() -> void:
	add_to_group(&"navigation_obstacles")
	refresh()


func refresh() -> void:
	var definition := GameManager.buildings.get_definition(building_id)
	visual.title = definition.display_name if definition != null else String(building_id)
	visual.level = GameManager.buildings.get_level(building_id)


## Screen-space area that selects this building on tap (whole drawing, roof included).
func get_hit_rect() -> Rect2:
	var height := visual.get_height()
	return Rect2(global_position + Vector2(-visual.width * 0.5 - 6, -height - 4), Vector2(visual.width + 12, height + 10))
