class_name LootEntry
extends Resource
## One possible drop in a loot table.

@export var item_id: StringName
@export var quantity_min: int = 1
@export var quantity_max: int = 1
@export_range(0.0, 1.0) var chance: float = 1.0
