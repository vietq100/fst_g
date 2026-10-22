class_name ProfilePresets
extends RefCounted
## Ready-made sample profiles, for trying the game at three stages. Each one
## is built by changing a fresh game through the normal services, then saved as a profile
## (ProfileScreen installs them when it opens). Names are translation keys.

## The three sample slots: Hunters of level 10, 50 and 100. `town_hall` is the Town Hall level (max 5), `buildings` the share of every other building's max level.
const PRESETS := [
	{"id": "lv10", "name": "ui.profile.sample.lv10", "level": 10, "town_hall": 1, "buildings": 0.25, "rebirths": 0, "gold": 5000, "rarity": 2, "boss": false, "roster": 0.5},
	{"id": "lv50", "name": "ui.profile.sample.lv50", "level": 50, "town_hall": 5, "buildings": 0.6, "rebirths": 0, "gold": 150000, "rarity": 4, "boss": true, "roster": 0.8},
	{"id": "lv100", "name": "ui.profile.sample.lv100", "level": 100, "town_hall": 5, "buildings": 1.0, "rebirths": 1, "gold": 3000000, "rarity": 5, "boss": true, "roster": 1.0},
]


## Creates every sample profile that is not in the list yet. Returns how many were added. Needs no
## selected profile; leaves none selected.
static func install_missing() -> int:
	var existing := {}
	var current := PRESETS.map(func(entry: Dictionary) -> String: return entry["id"])
	for profile in ProfileStore.list():
		var preset_id := str(profile.get("preset", ""))
		if not preset_id.is_empty() and not current.has(preset_id):
			ProfileStore.delete(profile["id"])  # sample of an older set
			continue
		existing[preset_id] = true
	var added := 0
	for preset: Dictionary in PRESETS:
		if existing.has(preset["id"]):
			continue
		var id := ProfileStore.create(Loc.t(preset["name"]), preset["id"], 40)
		SaveManager.select_profile(id)
		apply(GameManager, preset)
		SaveManager.logout()
		added += 1
	return added


## Brings a fresh `game` to the preset's stage.
static func apply(game: Node, preset: Dictionary) -> void:
	var levels := {}
	for building_id in game.buildings.get_ids():
		var definition: BuildingDefinition = game.buildings.get_definition(building_id)
		levels[building_id] = maxi(1, roundi(definition.get_max_level() * float(preset["buildings"])))
		if building_id == BuildingService.TOWN_HALL:
			levels[building_id] = clampi(int(preset["town_hall"]), 1, definition.get_max_level())
	game.buildings.set_levels(levels)
	game.wallet.gold = int(preset["gold"])
	if preset["boss"]:
		game.progress.set_flag(&"first_boss_clear")
	game.progress.total_reincarnations = int(preset["rebirths"]) * 2
	game.inventory.capacity = maxi(game.inventory.capacity, 120)
	# Not clamped by the Town Hall's level cap: the cap only limits XP gain, and the Town Hall tops out at 5.
	var level := clampi(int(preset["level"]), 1, game.registry.config.max_hunter_level)
	var want := maxi(1, roundi(game.recruitment.get_capacity() * float(preset["roster"])))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var config: GameConfig = game.registry.config
	while game.hunters.count() < want:
		var candidate: HunterRuntime = game.hunters.generate_candidate(config.starting_hunter_class, rng)
		game.traits.assign_random_traits(candidate)
		game.talents.assign_random_talent(candidate)
		game.class_skills.grant_starting_skills(candidate)
		game.hunters.add_hunter(candidate)
	var gear: Array[ItemDefinition] = _gear_up_to(game, int(preset["rarity"]))
	for hunter: HunterRuntime in game.hunters.get_all():
		hunter.level = level
		hunter.xp = 0
		hunter.reincarnations = int(preset["rebirths"])
		hunter.rebirth_points = int(preset["rebirths"]) * 3
		hunter.current_hp = game.hunters.get_stat(hunter, HunterService.MAX_HP)
		_train_skills(game, hunter)
		for item in gear:
			game.inventory.add_item(item.id, 1)
		game.equipment.equip_best(hunter)


static func _gear_up_to(game: Node, rarity: int) -> Array[ItemDefinition]:
	var result: Array[ItemDefinition] = []
	for definition in game.registry.get_all(&"item"):
		var item := definition as ItemDefinition
		if item.equipment_slot != ItemDefinition.EquipmentSlot.NONE and item.equipment_slot != ItemDefinition.EquipmentSlot.SKIN \
				and item.equipment_slot != ItemDefinition.EquipmentSlot.PET and int(item.rarity) <= rarity:
			result.append(item)
	return result


## Learns and raises class skills with the points the Hunter's level gives.
static func _train_skills(game: Node, hunter: HunterRuntime) -> void:
	game.class_skills.sync_points(hunter)
	while game.class_skills.can_unlock(hunter).is_empty():
		if game.class_skills.unlock_random(hunter) == null:
			break
	var progressed := true
	while progressed:
		progressed = false
		for skill in game.class_skills.get_owned(hunter):
			if game.class_skills.upgrade(hunter, skill.id):
				progressed = true
