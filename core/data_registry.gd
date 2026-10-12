extends Node
## Autoload. Loads static definitions from res://data and serves them by category and id.
## Runtime state must reference definitions by id (ARCHITECTURE.md).

signal data_loaded

const DATA_ROOT := "res://data"
const CONFIG_PATH := "res://data/config/game_config.tres"

const HUNTER := &"hunter"
const TRAIT := &"trait"
const ACTIVITY := &"activity"
const ENEMY := &"enemy"
const LOOT_TABLE := &"loot_table"
const ITEM := &"item"
const RECIPE := &"recipe"
const BUILDING := &"building"
const EXPEDITION := &"expedition"
const REGION := &"region"
const TALENT := &"talent"
const STATUS_EFFECT := &"status_effect"
const SKILL := &"skill"
const QUEST := &"quest"

## Category -> [folder under the data root, expected definition class].
const CATEGORIES := {
	HUNTER: ["hunters", &"HunterDefinition"],
	TRAIT: ["traits", &"TraitDefinition"],
	ACTIVITY: ["activities", &"ActivityDefinition"],
	ENEMY: ["enemies", &"EnemyDefinition"],
	LOOT_TABLE: ["loot_tables", &"LootTableDefinition"],
	ITEM: ["items", &"ItemDefinition"],
	RECIPE: ["recipes", &"RecipeDefinition"],
	BUILDING: ["buildings", &"BuildingDefinition"],
	EXPEDITION: ["expeditions", &"ExpeditionDefinition"],
	REGION: ["regions", &"RegionDefinition"],
	TALENT: ["talents", &"TalentDefinition"],
	STATUS_EFFECT: ["status_effects", &"StatusEffectDefinition"],
	SKILL: ["skills", &"SkillDefinition"],
	QUEST: ["quests", &"QuestDefinition"],
}

## Push load problems to the Godot error log. Tests turn this off.
var report_errors := true
var config: GameConfig
var load_errors: PackedStringArray = []

## Category -> (id -> GameDefinition)
var _definitions: Dictionary[StringName, Dictionary] = {}


func _ready() -> void:
	load_all(DATA_ROOT, CONFIG_PATH)


func load_all(data_root: String, config_path: String) -> void:
	_definitions.clear()
	load_errors.clear()
	_load_config(config_path)
	for category: StringName in CATEGORIES:
		var folder := data_root.path_join(CATEGORIES[category][0])
		_load_category(category, folder, CATEGORIES[category][1])
	if report_errors:
		for error in load_errors:
			push_error("DataRegistry: " + error)
	data_loaded.emit()


## Returns null without reporting when the id is unknown.
func find_def(category: StringName, id: StringName) -> GameDefinition:
	if not _definitions.has(category):
		return null
	return _definitions[category].get(id) as GameDefinition


## Returns null and reports an error when the id is unknown.
func get_def(category: StringName, id: StringName) -> GameDefinition:
	if not CATEGORIES.has(category):
		push_error("DataRegistry: unknown category '%s'" % category)
		return null
	var definition := find_def(category, id)
	if definition == null:
		push_error("DataRegistry: unknown %s id '%s'" % [category, id])
	return definition


func has_def(category: StringName, id: StringName) -> bool:
	return find_def(category, id) != null


func get_all(category: StringName) -> Array[GameDefinition]:
	var result: Array[GameDefinition] = []
	if _definitions.has(category):
		result.assign(_definitions[category].values())
	return result


func get_ids(category: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	if _definitions.has(category):
		result.assign(_definitions[category].keys())
	return result


func get_count(category: StringName) -> int:
	return _definitions[category].size() if _definitions.has(category) else 0


func get_total_count() -> int:
	var total := 0
	for entries in _definitions.values():
		total += entries.size()
	return total


func get_hunter(id: StringName) -> HunterDefinition:
	return get_def(HUNTER, id) as HunterDefinition


func get_trait(id: StringName) -> TraitDefinition:
	return get_def(TRAIT, id) as TraitDefinition


func get_activity(id: StringName) -> ActivityDefinition:
	return get_def(ACTIVITY, id) as ActivityDefinition


func get_enemy(id: StringName) -> EnemyDefinition:
	return get_def(ENEMY, id) as EnemyDefinition


func get_loot_table(id: StringName) -> LootTableDefinition:
	return get_def(LOOT_TABLE, id) as LootTableDefinition


func get_item(id: StringName) -> ItemDefinition:
	return get_def(ITEM, id) as ItemDefinition


func get_recipe(id: StringName) -> RecipeDefinition:
	return get_def(RECIPE, id) as RecipeDefinition


func get_building(id: StringName) -> BuildingDefinition:
	return get_def(BUILDING, id) as BuildingDefinition


func get_region(id: StringName) -> RegionDefinition:
	return get_def(REGION, id) as RegionDefinition


func get_expedition(id: StringName) -> ExpeditionDefinition:
	return get_def(EXPEDITION, id) as ExpeditionDefinition


func _load_config(config_path: String) -> void:
	config = null
	if ResourceLoader.exists(config_path):
		config = ResourceLoader.load(config_path) as GameConfig
	if config == null:
		load_errors.append("%s: missing or not a GameConfig, using defaults" % config_path)
		config = GameConfig.new()


func _load_category(category: StringName, folder: String, expected_class: StringName) -> void:
	var entries: Dictionary[StringName, GameDefinition] = {}
	_definitions[category] = entries
	if not DirAccess.dir_exists_absolute(folder):
		return
	for path in _list_resource_files(folder):
		var definition := ResourceLoader.load(path) as GameDefinition
		if definition == null:
			load_errors.append("%s: not a GameDefinition" % path)
			continue
		if not _is_class(definition, expected_class):
			load_errors.append("%s: expected %s" % [path, expected_class])
			continue
		if definition.id == &"":
			load_errors.append("%s: missing id" % path)
			continue
		if entries.has(definition.id):
			load_errors.append("%s: duplicate %s id '%s' (first: %s)"
					% [path, category, definition.id, entries[definition.id].resource_path])
			continue
		entries[definition.id] = definition


func _list_resource_files(folder: String) -> PackedStringArray:
	var result := PackedStringArray()
	for file in DirAccess.get_files_at(folder):
		# Exported builds list converted resources as "*.tres.remap".
		var file_name := file.trim_suffix(".remap")
		if file_name.ends_with(".tres") or file_name.ends_with(".res"):
			result.append(folder.path_join(file_name))
	for directory in DirAccess.get_directories_at(folder):
		result.append_array(_list_resource_files(folder.path_join(directory)))
	result.sort()
	return result


func _is_class(definition: GameDefinition, expected_class: StringName) -> bool:
	var script := definition.get_script() as Script
	while script != null:
		if script.get_global_name() == expected_class:
			return true
		script = script.get_base_script()
	return false
