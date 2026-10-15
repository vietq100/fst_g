class_name ForgeData
extends RefCounted
## Data of the Pixel Hero Forge (parts, items, animations, effects), exported by
## tools/character_forge/export_forge.js into forge_data.json. Loaded once and cached.

const PATH := "res://actors/hunter/forge/forge_data.json"

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var file := FileAccess.open(PATH, FileAccess.READ)
		if file == null:
			push_error("ForgeData: missing %s" % PATH)
			return _data
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			_data = parsed
	return _data


## Item definition of a category ("hair", "shirt"...) by id; the first (none) item when unknown.
static func find_item(category: String, id: String) -> Dictionary:
	var list: Array = data()["items"][category]
	for item: Dictionary in list:
		if item["id"] == id:
			return item
	return list[0]


static func item_ids(category: String) -> Array[String]:
	var ids: Array[String] = []
	for item: Dictionary in data()["items"][category]:
		ids.append(item["id"])
	return ids
