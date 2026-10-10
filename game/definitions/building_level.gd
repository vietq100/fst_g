class_name BuildingLevel
extends Resource
## Cost, requirements and effects of one building level.

@export var gold_cost: int = 0
@export var material_costs: Array[ItemAmount] = []
## Progress flags required to build this level, e.g. &"first_boss_clear".
@export var required_flags: Array[StringName] = []
## Effect key -> value, e.g. { &"hunter_capacity": 3, &"inventory_slots": 40 }.
@export var effects: Dictionary[StringName, float] = {}
@export var visual_variant: StringName
