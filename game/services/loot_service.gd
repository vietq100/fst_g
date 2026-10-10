class_name LootService
extends RefCounted
## Rolls loot tables (DATA_SPEC.md → LootTableDefinition). Each entry is rolled independently.

var _registry: Node
var _rng: RandomNumberGenerator


func _init(registry: Node, rng: RandomNumberGenerator) -> void:
	_registry = registry
	_rng = rng


## Item id -> quantity. Unknown or empty table ids give no drops.
func roll(table_id: StringName) -> Dictionary[StringName, int]:
	var drops: Dictionary[StringName, int] = {}
	if table_id == &"":
		return drops
	var table := _registry.find_def(&"loot_table", table_id) as LootTableDefinition
	if table == null:
		push_warning("LootService: unknown loot table '%s'" % table_id)
		return drops
	for entry in table.entries:
		if entry == null or _rng.randf() >= entry.chance:
			continue
		var quantity := _rng.randi_range(entry.quantity_min, maxi(entry.quantity_min, entry.quantity_max))
		if quantity > 0:
			drops[entry.item_id] = drops.get(entry.item_id, 0) + quantity
	return drops
