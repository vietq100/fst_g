class_name SettingsStore
extends RefCounted
## Player preferences outside audio (Audio keeps the bus volumes in the same file): read once and
## cached, saved at once when changed. Presentation only; nothing here touches gameplay or the save.

const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "display"

static var _cache: Dictionary = {}


## Camera shake on boss skills and fallen Hunters (CombatFeedback); on unless switched off.
static func get_screen_shake() -> bool:
	return bool(_get("screen_shake", true))


static func set_screen_shake(enabled: bool) -> void:
	_set("screen_shake", enabled)


## Card reveal when summoning (D83); off skips straight to the summary.
static func get_summon_effects() -> bool:
	return bool(_get("summon_effects", true))


static func set_summon_effects(enabled: bool) -> void:
	_set("summon_effects", enabled)


static func _get(key: String, fallback: Variant) -> Variant:
	if _cache.has(key):
		return _cache[key]
	var value: Variant = fallback
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		value = config.get_value(SECTION, key, fallback)
	_cache[key] = value
	return value


static func _set(key: String, value: Variant) -> void:
	_cache[key] = value
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(SECTION, key, value)
	config.save(SETTINGS_PATH)
