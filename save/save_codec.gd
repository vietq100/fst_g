class_name SaveCodec
extends RefCounted
## Converts the game state (a GameManager-like node with the service properties) to and from
## plain JSON-safe data (SAVE_SYSTEM.md, DECISIONS.md D21). No Nodes are ever saved.

const SCHEMA_VERSION := 1


## Snapshot of everything that persists. An expedition in progress is not saved: its party
## is written as back in town (D21); Hunters downed during the run come back injured.
static func capture(game: Node) -> Dictionary:
	var hunters: Dictionary = game.hunters.to_dict()
	for entry: Dictionary in hunters["hunters"]:
		if str(entry["expedition_id"]) == "":
			continue
		entry["expedition_id"] = ""
		if float(entry["current_hp"]) <= 0.0 or bool(entry["injured"]):
			entry["injured"] = true
			entry["current_hp"] = 0.0
			entry["recovery_remaining"] = HunterRuntime.RECOVERY_NOT_STARTED
			entry["state"] = HunterRuntime.LifecycleState.RECOVERING
		else:
			entry["state"] = HunterRuntime.LifecycleState.AVAILABLE
	return {
		"schema_version": SCHEMA_VERSION,
		"saved_at_unix": Time.get_unix_time_from_system(),
		"gold": game.wallet.gold,
		"progress": game.progress.to_dict(),
		"buildings": game.buildings.get_levels(),
		"hunters": hunters,
		"bonds": game.bonds.to_dict(),
		"inventory": game.inventory.to_dict(),
		"tavern_candidates": game.recruitment.to_dict(),
		"activity_time": game.activities.get_accumulator(),
	}


## Restores a (migrated) snapshot. Missing sections get defaults; invalid ids are dropped and
## reported in `warnings`. Order matters: buildings before inventory (capacity), Hunters before
## bonds/equipment (references).
static func restore(game: Node, data: Dictionary, warnings: PackedStringArray) -> void:
	var config: GameConfig = game.registry.config
	game.expeditions.current_run = null
	game.wallet.gold = maxi(int(data.get("gold", 0)), 0)
	game.progress.from_dict(_section(data, "progress", warnings))
	game.buildings.set_levels(_section(data, "buildings", warnings))
	game.hunters.from_dict(_section(data, "hunters", warnings), warnings)
	game.inventory.from_dict(_section(data, "inventory", warnings), warnings)
	for hunter: HunterRuntime in game.hunters.get_all():
		hunter.mood = clampf(hunter.mood, 0.0, config.mood_max)
		hunter.expedition_id = &""
		if hunter.injured:
			hunter.state = HunterRuntime.LifecycleState.RECOVERING
		elif hunter.state != HunterRuntime.LifecycleState.AVAILABLE:
			hunter.state = HunterRuntime.LifecycleState.AVAILABLE
		game.traits.validate(hunter, warnings)
	game.equipment.validate_all(warnings)
	# Max HP depends on equipment, so clamp only now.
	for hunter: HunterRuntime in game.hunters.get_all():
		hunter.current_hp = minf(hunter.current_hp, game.hunters.get_stat(hunter, HunterService.MAX_HP))
	game.bonds.from_dict(_section(data, "bonds", warnings), warnings)
	game.recruitment.from_dict(data.get("tavern_candidates", []), warnings)
	game.activities.set_accumulator(float(data.get("activity_time", 0.0)))


## Upgrades older snapshots step by step to SCHEMA_VERSION. Returns null if the data is from
## a newer, unknown version.
static func migrate(data: Dictionary, warnings: PackedStringArray) -> Variant:
	var version := int(data.get("schema_version", 0))
	if version > SCHEMA_VERSION:
		warnings.append("save is from a newer version (%d)" % version)
		return null
	while version < SCHEMA_VERSION:
		match version:
			0:
				data = _migrate_0_to_1(data)
		version += 1
		data["schema_version"] = version
		warnings.append("migrated save to schema %d" % version)
	return data


## Schema 0 (pre-release draft of SAVE_SYSTEM.md): materials were a top-level dictionary and
## there was no timestamp. Materials move into the inventory stacks.
static func _migrate_0_to_1(data: Dictionary) -> Dictionary:
	var inventory: Dictionary = data.get("inventory", {})
	var stacks: Dictionary = inventory.get("stacks", {})
	var materials: Variant = data.get("materials", {})
	if materials is Dictionary:
		for item_id in materials:
			stacks[item_id] = int(stacks.get(item_id, 0)) + int(materials[item_id])
	inventory["stacks"] = stacks
	data["inventory"] = inventory
	data.erase("materials")
	if not data.has("saved_at_unix"):
		data["saved_at_unix"] = Time.get_unix_time_from_system()
	return data


static func _section(data: Dictionary, key: String, warnings: PackedStringArray) -> Dictionary:
	var value: Variant = data.get(key, {})
	if value is Dictionary:
		return value
	warnings.append("%s: expected an object, using defaults" % key)
	return {}
