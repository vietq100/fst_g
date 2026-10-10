class_name BuildingService
extends RefCounted
## Building levels, upgrade costs/requirements and effects (BUILDING_DESIGN.md, BALANCE.md).
## Effects are data (`BuildingLevel.effects`); this service applies the global ones:
## Warehouse → inventory capacity, Town Hall → town level (Hunter level cap, unlocks).

signal building_upgraded(building_id: StringName, level: int)
## SaveManager listens (DECISIONS.md D21).
signal autosave_requested(reason: StringName)

const TOWN_HALL := &"town_hall"
const TAVERN := &"tavern"
const BLACKSMITH := &"blacksmith"
const HOSPITAL := &"hospital"
const WAREHOUSE := &"warehouse"

## Effect keys used by code. Values live in data.
const HUNTER_CAPACITY := &"hunter_capacity"
const CANDIDATE_COUNT := &"candidate_count"
const REFRESH_COST := &"refresh_cost"
const RECIPE_LEVEL := &"recipe_level"
const RECOVERY_SECONDS := &"recovery_seconds"
const SPEEDUP_GOLD_PER_MINUTE := &"speedup_gold_per_minute"
const INVENTORY_SLOTS := &"inventory_slots"

var _registry: Node
var _wallet: WalletService
var _inventory: InventoryService
var _progress: ProgressService
var _levels: Dictionary[StringName, int] = {}


func _init(registry: Node, wallet: WalletService, inventory: InventoryService, progress: ProgressService) -> void:
	_registry = registry
	_wallet = wallet
	_inventory = inventory
	_progress = progress
	reset()


## Every defined building at level 1 (new game).
func reset() -> void:
	_levels.clear()
	for building_id in _registry.get_ids(&"building"):
		_levels[building_id] = 1
	apply_effects()


func get_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_levels.keys())
	return ids


func get_definition(building_id: StringName) -> BuildingDefinition:
	return _registry.find_def(&"building", building_id) as BuildingDefinition


func get_level(building_id: StringName) -> int:
	return _levels.get(building_id, 0)


## Effect of the building's current level, or `default` if the building/key is missing.
func get_effect(building_id: StringName, key: StringName, default: float = 0.0) -> float:
	var definition := get_definition(building_id)
	if definition == null:
		return default
	var level := definition.get_level(get_level(building_id))
	return level.effects.get(key, default) if level != null else default


## Next level data, or null at max level.
func get_next_level(building_id: StringName) -> BuildingLevel:
	var definition := get_definition(building_id)
	return definition.get_level(get_level(building_id) + 1) if definition != null else null


## Empty string when the upgrade is possible, otherwise the reason.
func can_upgrade(building_id: StringName) -> String:
	var definition := get_definition(building_id)
	if definition == null:
		return "Unknown building '%s'" % building_id
	var next := get_next_level(building_id)
	if next == null:
		return "%s is at max level" % definition.display_name
	for flag in next.required_flags:
		if not _progress.has_flag(flag):
			return "Requires %s" % String(flag).replace("_", " ")
	if not _wallet.can_spend(next.gold_cost):
		return "Needs %d gold" % next.gold_cost
	for cost in next.material_costs:
		if not _inventory.has(cost.item_id, cost.quantity):
			var item := _registry.find_def(&"item", cost.item_id) as ItemDefinition
			return "Needs %d %s" % [cost.quantity, item.display_name if item != null else String(cost.item_id)]
	return ""


func upgrade(building_id: StringName) -> bool:
	if not can_upgrade(building_id).is_empty():
		return false
	var next := get_next_level(building_id)
	_wallet.spend(next.gold_cost)
	for cost in next.material_costs:
		_inventory.remove_item(cost.item_id, cost.quantity)
	_levels[building_id] = get_level(building_id) + 1
	apply_effects()
	building_upgraded.emit(building_id, _levels[building_id])
	autosave_requested.emit(&"building_upgrade")
	return true


## Pushes global effects into the other services (after upgrades and loads).
func apply_effects() -> void:
	if _levels.has(WAREHOUSE):
		_inventory.capacity = int(get_effect(WAREHOUSE, INVENTORY_SLOTS, _inventory.capacity))
	if _levels.has(TOWN_HALL):
		_progress.town_level = get_level(TOWN_HALL)


func get_levels() -> Dictionary[StringName, int]:
	return _levels.duplicate()


## Restores saved levels; unknown ids are ignored, levels are clamped to what the data defines.
func set_levels(levels: Dictionary) -> void:
	reset()
	for building_id in levels:
		var definition := get_definition(StringName(building_id))
		if definition != null:
			_levels[definition.id] = clampi(int(levels[building_id]), 1, definition.get_max_level())
	apply_effects()
