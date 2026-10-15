class_name BuildingService
extends RefCounted
## Placed buildings in the Town (BUILD_SYSTEM.md, DECISIONS.md D32, D33): build, move, remove,
## per-instance levels and upgrades, effects. Effects of unique buildings come from their single
## instance (missing building → missing effect); House beds add up.
## Warehouse → inventory capacity, Town Hall → town level.

signal building_upgraded(building_id: StringName, level: int)
signal building_placed(instance: Placed)
signal building_moved(instance: Placed)
signal building_removed(instance: Placed)
## Any placement change (build / move / remove / load): rebake navigation, re-plan paths.
signal layout_changed
## SaveManager listens (DECISIONS.md D21).
signal autosave_requested(reason: StringName)

const TOWN_HALL := &"town_hall"
const TAVERN := &"tavern"
const BLACKSMITH := &"blacksmith"
const HOSPITAL := &"hospital"
const TEMPLE := &"temple"
const WAREHOUSE := &"warehouse"
const HOUSE := &"house"
const TRADING_POST := &"trading_post"
const INN := &"inn"
const ACADEMY := &"academy"
const FORGE := &"forge"
const PORTAL := &"portal"
const RESTAURANT := &"restaurant"
## Buys Hunters' loot into the Warehouse (D63).
const MARKET := &"market"

## Effect keys used by code. Values live in data.
const HUNTER_CAPACITY := &"hunter_capacity"
const CANDIDATE_COUNT := &"candidate_count"
const REFRESH_COST := &"refresh_cost"
const RECIPE_LEVEL := &"recipe_level"
const RECOVERY_SECONDS := &"recovery_seconds"
const SPEEDUP_GOLD_PER_MINUTE := &"speedup_gold_per_minute"
const INVENTORY_SLOTS := &"inventory_slots"
const BEDS := &"beds"
const REQUEST_SLOTS := &"request_slots"
const MAX_ENHANCE := &"max_enhance"
const SKILL_LEVEL := &"skill_level"
const MAX_TRAITS := &"max_traits"
const FOOD_BONUS := &"food_bonus"
## Market: share of an item's price the treasury pays when it buys loot (D63).
const BUY_PRICE := &"buy_price"

## Share of the build cost refunded on removal (BALANCE.md → Building placement).
const REFUND_RATIO := 0.5
## Tiles next to each Town gate stay free so the gates are always reachable.
const GATE_APPROACH := 2

class Placed:
	var instance_id: StringName
	var building_id: StringName
	## Anchor tile (top corner of the footprint).
	var tile: Vector2i
	var level: int = 1

	func footprint_rect(definition: BuildingDefinition) -> Rect2i:
		return Rect2i(tile, definition.footprint)

	func to_dict() -> Dictionary:
		return {"instance_id": instance_id, "building_id": building_id, "tile": [tile.x, tile.y], "level": level}

var _registry: Node
var _wallet: WalletService
var _inventory: InventoryService
var _progress: ProgressService
var _town_rect := Rect2i(0, 0, 36, 36)
## The Town's tiles (its organic shape, D57); empty = the whole rectangle.
var _town_tiles: Dictionary = {}
var _reserved: Array[Rect2i] = []
var _pond := Rect2i()
var _placed: Array[Placed] = []
var _next_id := 1


func _init(registry: Node, wallet: WalletService, inventory: InventoryService, progress: ProgressService,
		world: WorldService = null) -> void:
	_registry = registry
	_wallet = wallet
	_inventory = inventory
	_progress = progress
	if world != null and world.get_town() != null:
		_town_rect = world.get_town().tile_rect
		_town_tiles = world.region_tiles(world.get_town().id)
		_pond = world.get_town_pond()
		for gate in world.gates_of(world.get_town().id):
			_reserved.append(_approach(gate.tiles))
	reset()


## New game: every building at its default tiles, level 1.
func reset() -> void:
	_placed.clear()
	_next_id = 1
	for building_id in _registry.get_ids(&"building"):
		var definition := get_definition(building_id)
		for tile in definition.default_tiles:
			_add(building_id, tile, 1)
	apply_effects()
	layout_changed.emit()


# --- Queries ---------------------------------------------------------------------------------

func get_ids() -> Array[StringName]:
	return _registry.get_ids(&"building")


func get_definition(building_id: StringName) -> BuildingDefinition:
	return _registry.find_def(&"building", building_id) as BuildingDefinition


func get_instances() -> Array[Placed]:
	return _placed.duplicate()


func get_instance(instance_id: StringName) -> Placed:
	for placed in _placed:
		if placed.instance_id == instance_id:
			return placed
	return null


func get_instances_of(building_id: StringName) -> Array[Placed]:
	return _placed.filter(func(placed: Placed) -> bool: return placed.building_id == building_id)


## The single instance of a unique building, or the first of its type, or null.
func find_first(building_id: StringName) -> Placed:
	for placed in _placed:
		if placed.building_id == building_id:
			return placed
	return null


func has_building(building_id: StringName) -> bool:
	return find_first(building_id) != null


## Level of the (unique) building of that type; 0 if it does not exist.
func get_level(building_id: StringName) -> int:
	var placed := find_first(building_id)
	return placed.level if placed != null else 0


func get_town_level() -> int:
	return maxi(get_level(TOWN_HALL), 1)


## Effect of the (unique) building's current level, or `default` if missing.
func get_effect(building_id: StringName, key: StringName, default: float = 0.0) -> float:
	var placed := find_first(building_id)
	return _instance_effect(placed, key, default) if placed != null else default


## Sum of an effect over every instance of a type (House beds).
func get_total_effect(building_id: StringName, key: StringName) -> float:
	var total := 0.0
	for placed in get_instances_of(building_id):
		total += _instance_effect(placed, key, 0.0)
	return total


func get_footprint_rect(placed: Placed) -> Rect2i:
	return placed.footprint_rect(get_definition(placed.building_id))


func instance_at_tile(tile: Vector2i) -> Placed:
	for placed in _placed:
		if get_footprint_rect(placed).has_point(tile):
			return placed
	return null


# --- Placement --------------------------------------------------------------------------------

## Empty string when `building_id` fits at `tile`, otherwise the reason. `ignore` lets a building
## overlap its own current footprint (moving).
func can_place(building_id: StringName, tile: Vector2i, ignore: StringName = &"") -> String:
	var definition := get_definition(building_id)
	if definition == null:
		return Loc.t("err.building.unknown")
	var rect := Rect2i(tile, definition.footprint)
	if not _town_rect.encloses(rect) or not _inside_town(rect):
		return Loc.t("err.building.outside_town")
	for reserved in _reserved:
		if reserved.intersects(rect):
			return Loc.t("err.building.gate_road")
	if _pond.intersects(rect):
		return Loc.t("err.building.pond")
	var door := get_door_tile(rect)
	if not _town_rect.has_point(door) or (not _town_tiles.is_empty() and not _town_tiles.has(door)):
		return Loc.t("err.building.door_outside")
	for placed in _placed:
		if placed.instance_id == ignore:
			continue
		var other := get_footprint_rect(placed)
		if other.intersects(rect):
			return Loc.t("err.building.space_taken")
		# Doors stay reachable: Hunters deliver loot and bodies there.
		if other.has_point(door) or rect.has_point(get_door_tile(other)):
			return Loc.t("err.building.blocks_door")
	return ""


## Every tile of `rect` is Town ground (not a cut corner or an eroded edge).
func _inside_town(rect: Rect2i) -> bool:
	if _town_tiles.is_empty():
		return true
	for gx in range(rect.position.x, rect.end.x):
		for gy in range(rect.position.y, rect.end.y):
			if not _town_tiles.has(Vector2i(gx, gy)):
				return false
	return true


## The tile in front of a footprint's door (middle of the front / bottom face,
## TownBuilding.get_door_point).
static func get_door_tile(rect: Rect2i) -> Vector2i:
	return Vector2i(rect.position.x + rect.size.x / 2, rect.end.y)


## Places a free copy of a missing building (save migrations): at its default tile, or the free
## spot nearest to it. Returns null if it exists already or nothing fits.
func ensure_building(building_id: StringName) -> Placed:
	var definition := get_definition(building_id)
	if definition == null or has_building(building_id) or definition.default_tiles.is_empty():
		return null
	var anchor := definition.default_tiles[0]
	var best := Vector2i(-1, -1)
	var best_distance := INF
	for gx in range(_town_rect.position.x, _town_rect.end.x):
		for gy in range(_town_rect.position.y, _town_rect.end.y):
			var tile := Vector2i(gx, gy)
			var distance := Vector2(tile - anchor).length_squared()
			if distance < best_distance and can_place(building_id, tile).is_empty():
				best = tile
				best_distance = distance
	if best_distance == INF:
		return null
	var placed := _add(building_id, best, 1)
	apply_effects()
	building_placed.emit(placed)
	layout_changed.emit()
	return placed


## Empty string when a new building of this type can be bought now.
func can_build(building_id: StringName) -> String:
	var definition := get_definition(building_id)
	if definition == null:
		return Loc.t("err.building.unknown")
	if definition.build_cost <= 0:
		return Loc.t("err.building.not_buildable", {"building": definition.display_name})
	if definition.unique and has_building(building_id):
		return Loc.t("err.building.already_built")
	if get_town_level() < definition.required_town_level:
		return Loc.t("err.building.needs_town_level", {"level": definition.required_town_level})
	if not _wallet.can_spend(definition.build_cost):
		return Loc.t("ui.common.needs_gold", {"gold": definition.build_cost})
	return ""


## Pays and places a new building. Returns null if it cannot.
func build(building_id: StringName, tile: Vector2i) -> Placed:
	if not can_build(building_id).is_empty() or not can_place(building_id, tile).is_empty():
		return null
	_wallet.spend(get_definition(building_id).build_cost)
	var placed := _add(building_id, tile, 1)
	apply_effects()
	building_placed.emit(placed)
	layout_changed.emit()
	autosave_requested.emit(&"build")
	return placed


func move(instance_id: StringName, tile: Vector2i) -> String:
	var placed := get_instance(instance_id)
	if placed == null:
		return Loc.t("err.building.unknown")
	var reason := can_place(placed.building_id, tile, instance_id)
	if not reason.is_empty():
		return reason
	placed.tile = tile
	building_moved.emit(placed)
	layout_changed.emit()
	autosave_requested.emit(&"build")
	return ""


func can_remove(instance_id: StringName) -> String:
	var placed := get_instance(instance_id)
	if placed == null:
		return Loc.t("err.building.unknown")
	var definition := get_definition(placed.building_id)
	if not definition.removable:
		return Loc.t("err.building.not_removable", {"building": definition.display_name})
	return ""


func get_refund(instance_id: StringName) -> int:
	var placed := get_instance(instance_id)
	return floori(get_definition(placed.building_id).build_cost * REFUND_RATIO) if placed != null else 0


## Removes a building and refunds part of its cost.
func remove(instance_id: StringName) -> String:
	var reason := can_remove(instance_id)
	if not reason.is_empty():
		return reason
	var placed := get_instance(instance_id)
	_wallet.add(get_refund(instance_id))
	_placed.erase(placed)
	apply_effects()
	building_removed.emit(placed)
	layout_changed.emit()
	autosave_requested.emit(&"build")
	return ""


# --- Upgrades ----------------------------------------------------------------------------------

## Next level data of the (unique) building of that type, or null.
func get_next_level(building_id: StringName) -> BuildingLevel:
	var placed := find_first(building_id)
	return get_instance_next_level(placed.instance_id) if placed != null else null


func get_instance_next_level(instance_id: StringName) -> BuildingLevel:
	var placed := get_instance(instance_id)
	if placed == null:
		return null
	return get_definition(placed.building_id).get_level(placed.level + 1)


func can_upgrade(building_id: StringName) -> String:
	var placed := find_first(building_id)
	if placed == null:
		var definition := get_definition(building_id)
		return Loc.t("err.building.not_built", {"building": definition.display_name if definition != null else String(building_id)})
	return can_upgrade_instance(placed.instance_id)


func can_upgrade_instance(instance_id: StringName) -> String:
	var placed := get_instance(instance_id)
	if placed == null:
		return Loc.t("err.building.unknown")
	var definition := get_definition(placed.building_id)
	var next := definition.get_level(placed.level + 1)
	if next == null:
		return Loc.t("err.building.max_level", {"building": definition.display_name})
	for flag in next.required_flags:
		if not _progress.has_flag(flag):
			var flag_key := "game.flag.%s" % flag
			var flag_text := Loc.t(flag_key) if Loc.has_key(flag_key) else String(flag).replace("_", " ")
			return Loc.t("err.building.requires_flag", {"flag": flag_text})
	if not _wallet.can_spend(next.gold_cost):
		return Loc.t("ui.common.needs_gold", {"gold": next.gold_cost})
	for cost in next.material_costs:
		if not _inventory.has(cost.item_id, cost.quantity):
			var item := _registry.find_def(&"item", cost.item_id) as ItemDefinition
			return Loc.t("err.building.needs_items", {"count": cost.quantity, "item": item.display_name if item != null else String(cost.item_id)})
	return ""


func upgrade(building_id: StringName) -> bool:
	var placed := find_first(building_id)
	return placed != null and upgrade_instance(placed.instance_id)


func upgrade_instance(instance_id: StringName) -> bool:
	if not can_upgrade_instance(instance_id).is_empty():
		return false
	var placed := get_instance(instance_id)
	var next := get_definition(placed.building_id).get_level(placed.level + 1)
	_wallet.spend(next.gold_cost)
	for cost in next.material_costs:
		_inventory.remove_item(cost.item_id, cost.quantity)
	placed.level += 1
	apply_effects()
	building_upgraded.emit(placed.building_id, placed.level)
	autosave_requested.emit(&"building_upgrade")
	return true


## Pushes global effects into the other services (after any change and loads).
func apply_effects() -> void:
	_inventory.capacity = int(get_effect(WAREHOUSE, INVENTORY_SLOTS, 0.0))
	_progress.town_level = maxi(get_level(TOWN_HALL), 1)


# --- Save ------------------------------------------------------------------------------------

## Level per building type (schema 1 compatibility, migration).
func get_levels() -> Dictionary[StringName, int]:
	var levels: Dictionary[StringName, int] = {}
	for placed in _placed:
		levels[placed.building_id] = maxi(levels.get(placed.building_id, 0), placed.level)
	return levels


## Schema 1: default layout with these levels per type.
func set_levels(levels: Dictionary) -> void:
	reset()
	for building_id in levels:
		var definition := get_definition(StringName(building_id))
		if definition == null:
			continue
		for placed in get_instances_of(definition.id):
			placed.level = clampi(int(levels[building_id]), 1, maxi(definition.get_max_level(), 1))
	apply_effects()
	layout_changed.emit()


func to_dict() -> Dictionary:
	var list: Array = []
	for placed in _placed:
		list.append(placed.to_dict())
	return {"next_id": _next_id, "instances": list}


## Restores placed buildings. Unknown types, invalid or overlapping placements are dropped and
## reported; a missing Town Hall is put back at its default tile.
func from_dict(data: Dictionary, warnings: PackedStringArray) -> void:
	_placed.clear()
	_next_id = 1
	var entries: Variant = data.get("instances", [])
	for entry in (entries if entries is Array else []):
		if not entry is Dictionary:
			continue
		var building_id := StringName(str(entry.get("building_id", "")))
		var definition := get_definition(building_id)
		var tile_data: Variant = entry.get("tile", [])
		if definition == null or not tile_data is Array or tile_data.size() != 2:
			warnings.append("buildings: dropped '%s'" % building_id)
			continue
		var tile := Vector2i(int(tile_data[0]), int(tile_data[1]))
		if definition.unique and has_building(building_id) or not can_place(building_id, tile).is_empty():
			warnings.append("buildings: dropped %s at %s (%s)" % [building_id, tile, "duplicate" if has_building(building_id) else can_place(building_id, tile)])
			continue
		var placed := _add(building_id, tile, clampi(int(entry.get("level", 1)), 1, maxi(definition.get_max_level(), 1)))
		var saved_id := StringName(str(entry.get("instance_id", "")))
		if saved_id != &"" and get_instance(saved_id) == null:
			placed.instance_id = saved_id
	_next_id = maxi(int(data.get("next_id", 1)), _next_id)
	for placed in _placed:
		_next_id = maxi(_next_id, String(placed.instance_id).trim_prefix("b_").to_int() + 1)
	if not has_building(TOWN_HALL):
		var town_hall := get_definition(TOWN_HALL)
		if town_hall != null and not town_hall.default_tiles.is_empty():
			warnings.append("buildings: Town Hall restored at its default place")
			_add(TOWN_HALL, town_hall.default_tiles[0], 1)
	apply_effects()
	layout_changed.emit()


func _add(building_id: StringName, tile: Vector2i, level: int) -> Placed:
	var placed := Placed.new()
	placed.instance_id = StringName("b_%d" % _next_id)
	_next_id += 1
	placed.building_id = building_id
	placed.tile = tile
	placed.level = level
	_placed.append(placed)
	return placed


func get_instance_effect(placed: Placed, key: StringName, default: float = 0.0) -> float:
	return _instance_effect(placed, key, default)


func _instance_effect(placed: Placed, key: StringName, default: float) -> float:
	var level := get_definition(placed.building_id).get_level(placed.level)
	return level.effects.get(key, default) if level != null else default


## Town tiles in front of a gate (inside the Town) that must stay free.
func _approach(gate: Rect2i) -> Rect2i:
	var rect := gate
	if gate.position.x >= _town_rect.end.x:
		rect = Rect2i(_town_rect.end.x - GATE_APPROACH, gate.position.y, GATE_APPROACH, gate.size.y)
	elif gate.position.y >= _town_rect.end.y:
		rect = Rect2i(gate.position.x, _town_rect.end.y - GATE_APPROACH, gate.size.x, GATE_APPROACH)
	elif gate.end.x <= _town_rect.position.x:
		rect = Rect2i(_town_rect.position.x, gate.position.y, GATE_APPROACH, gate.size.y)
	elif gate.end.y <= _town_rect.position.y:
		rect = Rect2i(gate.position.x, _town_rect.position.y, gate.size.x, GATE_APPROACH)
	return rect
