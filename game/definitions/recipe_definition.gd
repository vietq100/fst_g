class_name RecipeDefinition
extends GameDefinition
## Crafting recipe made in a village building (Blacksmith equipment, Tavern food, Hospital
## medicine; DECISIONS.md D7, D40, D41).

@export var result_item_id: StringName
## How many of the result one craft makes (stackable results).
@export var result_quantity: int = 1
@export var gold_cost: int = 0
@export var material_costs: Array[ItemAmount] = []
## Building that crafts it and its minimum level.
@export var building_id: StringName = &"blacksmith"
@export var required_level: int = 1
## Seconds a talented Hunter needs to make it in the field (D46).
@export var field_seconds: float = 8.0
