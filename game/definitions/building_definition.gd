class_name BuildingDefinition
extends GameDefinition
## Town building. Index 0 of `levels` is level 1. More levels can be added over time.

@export var levels: Array[BuildingLevel] = []

@export_group("Placement")
## Gold to build one (0 = cannot be built from the build menu, e.g. Town Hall).
@export var build_cost: int = 0
## Tiles occupied (gx × gy), anchored at the building's tile.
@export var footprint: Vector2i = Vector2i(2, 2)
## Only one may exist (core buildings). Houses are not unique.
@export var unique: bool = true
## May the player remove it?
@export var removable: bool = true
## Where new games place it (one entry per instance).
@export var default_tiles: Array[Vector2i] = []


func get_max_level() -> int:
	return levels.size()


## Returns null when the level does not exist.
func get_level(level: int) -> BuildingLevel:
	if level < 1 or level > levels.size():
		return null
	return levels[level - 1]
