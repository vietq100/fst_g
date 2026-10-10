class_name EnemyGroup
extends Resource
## Enemies in one section of an expedition map, e.g. "clearing".

@export var section_id: StringName
@export var spawns: Array[EnemySpawn] = []
