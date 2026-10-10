class_name BuildingDefinition
extends GameDefinition
## Town building. Index 0 of `levels` is level 1. More levels can be added over time.

@export var levels: Array[BuildingLevel] = []


func get_max_level() -> int:
	return levels.size()


## Returns null when the level does not exist.
func get_level(level: int) -> BuildingLevel:
	if level < 1 or level > levels.size():
		return null
	return levels[level - 1]
