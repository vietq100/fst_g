class_name RecipeDefinition
extends GameDefinition
## Blacksmith crafting recipe.

@export var result_item_id: StringName
@export var gold_cost: int = 0
@export var material_costs: Array[ItemAmount] = []
@export var required_blacksmith_level: int = 1
