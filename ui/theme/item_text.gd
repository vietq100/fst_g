class_name ItemText
extends RefCounted
## Short text for item quantities in debug panels and summaries.


## "Iron Ore ×3, Beast Fang ×1" or "–" when empty. `registry` is the DataRegistry.
static func describe(items: Dictionary, registry: Node) -> String:
	if items.is_empty():
		return "–"
	var parts := PackedStringArray()
	for item_id in items:
		var item := registry.find_def(&"item", item_id) as ItemDefinition
		parts.append("%s ×%d" % [item.display_name if item != null else String(item_id), items[item_id]])
	return ", ".join(parts)
