class_name GameDefinition
extends Resource
## Base class for all static content definitions loaded by DataRegistry.
## Runtime state references definitions by `id`, never by Resource instance.

@export var id: StringName
## A translation key (D61), e.g. "item.iron_sword.name"; reading it returns the translated text.
## `get_name_key()` gives the key itself.
@export var display_name: String:
	set(value):
		_name_key = value
	get:
		return tr(_name_key) if not _name_key.is_empty() else _name_key

var _name_key := ""


func get_name_key() -> String:
	return _name_key
