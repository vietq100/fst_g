class_name SaveCodec
extends RefCounted
## Converts the game state (a GameManager-like node with the service properties) to and from
## plain JSON-safe data (SAVE_SYSTEM.md, DECISIONS.md D21). No Nodes are ever saved.

const SCHEMA_VERSION := 3
## Purse given to Hunters of schema 1 saves (BALANCE.md → Money, new Hunter purse).
const MIGRATED_PURSE := 20


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
		"buildings": game.buildings.to_dict(),
		"hunters": hunters,
		"bonds": game.bonds.to_dict(),
		"inventory": game.inventory.to_dict(),
		"tavern_candidates": game.recruitment.to_dict(),
		"trading": game.trading.to_dict(),
		"quests": game.quests.to_dict(),
		"weekly_boss": game.weekly_boss.to_dict(),
		"activity_time": game.activities.get_accumulator(),
	}


## Restores a (migrated) snapshot. Missing sections get defaults; invalid ids are dropped and
## reported in `warnings`. Order matters: buildings before inventory (capacity), Hunters before
## bonds/equipment (references).
static func restore(game: Node, data: Dictionary, warnings: PackedStringArray) -> void:
	var config: GameConfig = game.registry.config
	game.expeditions.current_run = null
	game.corpses.clear()
	game.wallet.gold = maxi(int(data.get("gold", 0)), 0)
	game.progress.from_dict(_section(data, "progress", warnings))
	var buildings := _section(data, "buildings", warnings)
	if buildings.has("instances"):
		game.buildings.from_dict(buildings, warnings)
		var ensure: Variant = buildings.get("ensure", [])
		for building_id in (ensure if ensure is Array else []):
			game.buildings.ensure_building(StringName(str(building_id)))
	else:
		# Schema 1 levels, or no section at all: the default layout.
		var levels: Variant = buildings.get("legacy_levels", {})
		game.buildings.set_levels(levels if levels is Dictionary else {})
	game.hunters.from_dict(_section(data, "hunters", warnings), warnings)
	game.inventory.from_dict(_section(data, "inventory", warnings), warnings)
	for hunter: HunterRuntime in game.hunters.get_all():
		hunter.mood = clampf(hunter.mood, 0.0, config.mood_max)
		hunter.expedition_id = &""
		if hunter.injured or not hunter.alive:
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
	game.trading.from_dict(data.get("trading", []))
	game.quests.from_dict(data.get("quests", {}))
	game.weekly_boss.from_dict(data.get("weekly_boss", {}))
	game.activities.set_accumulator(float(data.get("activity_time", 0.0)))
	# Buildings were restored before the Hunters: hand out beds now (old saves have none).
	game.housing.assign_beds()


## Upgrades older snapshots step by step to SCHEMA_VERSION. Returns null if the data is from
## a newer, unknown version.
static func migrate(data: Dictionary, warnings: PackedStringArray) -> Variant:
	var version := int(data.get("schema_version", 0))
	if version > SCHEMA_VERSION:
		warnings.append(Loc.t("save.newer_version", {"version": version}))
		return null
	while version < SCHEMA_VERSION:
		match version:
			0:
				data = _migrate_0_to_1(data)
			1:
				data = _migrate_1_to_2(data)
			2:
				data = _migrate_2_to_3(data)
		version += 1
		data["schema_version"] = version
		warnings.append(Loc.t("save.migrated", {"version": version}))
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


## Schema 1 → 2 (D37): buildings were levels per type in a fixed layout; they become placed
## instances at their default tiles with those levels. Hunters get a starting purse; other new
## fields (needs, duty) take their defaults when HunterRuntime reads the entry.
static func _migrate_1_to_2(data: Dictionary) -> Dictionary:
	var levels: Variant = data.get("buildings", {})
	data["buildings"] = {"legacy_levels": levels if levels is Dictionary else {}}
	var hunters: Variant = data.get("hunters", {})
	var entries: Variant = hunters.get("hunters", []) if hunters is Dictionary else []
	if entries is Array:
		for entry: Variant in entries:
			if entry is Dictionary and not entry.has("purse"):
				entry["purse"] = MIGRATED_PURSE
	return data


## Schema 2 → 3 (D42): layouts saved before the Temple existed get one (default spot or the
## nearest free one).
static func _migrate_2_to_3(data: Dictionary) -> Dictionary:
	var buildings: Variant = data.get("buildings", {})
	if buildings is Dictionary and buildings.has("instances"):
		buildings["ensure"] = ["temple"]
	return data


static func _section(data: Dictionary, key: String, warnings: PackedStringArray) -> Dictionary:
	var value: Variant = data.get(key, {})
	if value is Dictionary:
		return value
	warnings.append(Loc.t("save.bad_section", {"section": key}))
	return {}
