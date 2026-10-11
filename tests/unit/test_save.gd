extends TestCase
## Save system (SAVE_SYSTEM.md → Validation, DECISIONS.md D21, D24) on fresh game instances.

const DataRegistryScript := preload("res://core/data_registry.gd")
const GameManagerScript := preload("res://core/game_manager.gd")
const SaveManagerScript := preload("res://core/save_manager.gd")
const SAVE := "user://test_save.json"
const BACKUP := "user://test_save.bak.json"

var _registry: Node
var _games: Array[Node] = []
var _saves: Array[Node] = []


func before_each() -> void:
	_registry = DataRegistryScript.new()
	_registry.report_errors = false
	_registry.load_all(DataRegistryScript.DATA_ROOT, DataRegistryScript.CONFIG_PATH)
	_delete_files()


func after_each() -> void:
	for game in _games:
		game.hunters.clear_modifier_sources()
		game.bonds.set_party_provider(func() -> Array: return [])
		game.free()
	for save in _saves:
		save.free()
	_games.clear()
	_saves.clear()
	_registry.free()
	_delete_files()


func _game(seed_value: int = 1) -> Node:
	var game: Node = GameManagerScript.new()
	game.rng.seed = seed_value
	game.build(_registry)
	game.start_new_game()
	_games.append(game)
	return game


func _save_manager(game: Node) -> Node:
	var save: Node = SaveManagerScript.new()
	save.game = game
	save.save_path = SAVE
	save.backup_path = BACKUP
	_saves.append(save)
	return save


## A game with a bit of everything: recruits, items, equipment, bonds, injury, upgrades.
func _rich_game() -> Node:
	var game := _game(7)
	game.wallet.add(2000)
	game.recruitment.recruit(0)
	game.recruitment.recruit(0)
	game.inventory.add_item(&"iron_ore", 30)
	game.inventory.add_item(&"dark_essence", 2)
	game.inventory.add_item(&"iron_sword", 2)
	var roster: Array[HunterRuntime] = game.hunters.get_all()
	game.equipment.equip_best(roster[0])
	game.bonds.add(roster[0].unique_id, roster[1].unique_id, 60.0)
	game.hunters.mark_injured(roster[2])
	game.temple.tick(30.0)
	game.progress.set_flag(&"first_boss_clear")
	game.buildings.upgrade(&"warehouse")
	game.buildings.build(&"house", Vector2i(14, 6))
	game.buildings.move(game.buildings.find_first(&"warehouse").instance_id, Vector2i(1, 1))
	game.mood.change(roster[1], 25.0)
	roster[1].duty = &"goblin_cave"
	roster[1].task = HunterRuntime.HUNTING
	roster[1].world_position = Vector2(400, 700)
	roster[1].stamina = 42.5
	game.regions.add_to_bag(roster[1], &"iron_ore", 2)
	game.purses.earn(roster[1], 33)
	game.activities.set_assignment(roster[1], ActivityService.SOCIALIZING)
	roster[0].history[HunterRuntime.BOSSES_DEFEATED] = 3
	game.advance_town_time(25.0)
	return game


func _comparable(game: Node) -> String:
	var data := SaveCodec.capture(game)
	data.erase("saved_at_unix")
	return JSON.stringify(data, "", true)


func test_round_trip_keeps_everything() -> void:
	var original := _rich_game()
	var copy := _game(99)
	var warnings := PackedStringArray()
	var data: Dictionary = JSON.parse_string(JSON.stringify(SaveCodec.capture(original)))
	SaveCodec.restore(copy, data, warnings)
	assert_eq(warnings.size(), 0, ", ".join(warnings))
	assert_eq(_comparable(copy), _comparable(original))
	# Derived values come back too.
	assert_eq(copy.inventory.capacity, 80)
	assert_eq(copy.progress.town_level, 1)
	var hunter: HunterRuntime = copy.hunters.get_all()[0]
	assert_almost_eq(copy.hunters.get_stat(hunter, HunterService.ATTACK), original.hunters.get_stat(original.hunters.get_all()[0], HunterService.ATTACK))
	# New recruits after loading get fresh ids.
	copy.wallet.add(1000)
	copy.buildings.set_levels({"town_hall": 2})
	var recruit: HunterRuntime = copy.recruitment.recruit(0)
	assert_eq(recruit.unique_id, &"h_4")


func test_file_save_load_and_backup() -> void:
	var original := _rich_game()
	var save := _save_manager(original)
	assert_true(save.save_game())
	assert_true(FileAccess.file_exists(SAVE))
	assert_false(FileAccess.file_exists(SAVE + ".tmp"), "temp file replaced")
	assert_true(save.save_game())
	assert_true(FileAccess.file_exists(BACKUP), "previous save kept as backup")
	var copy := _game(5)
	var loader := _save_manager(copy)
	assert_true(loader.load_game())
	assert_eq(copy.wallet.gold, original.wallet.gold)
	assert_eq(copy.hunters.count(), 3)


func test_corrupt_save_falls_back_to_backup() -> void:
	var original := _rich_game()
	var save := _save_manager(original)
	save.save_game()
	save.save_game()
	_write(SAVE, "{ this is not json")
	var copy := _game(5)
	var loader := _save_manager(copy)
	assert_true(loader.load_game())
	assert_eq(copy.hunters.count(), 3)
	assert_true(Array(loader.last_warnings).has("restored from backup"))


func test_both_corrupt_starts_new_game() -> void:
	_write(SAVE, "nope")
	_write(BACKUP, "[1, 2")
	var game := _game(5)
	game.wallet.add(999)
	var loader := _save_manager(game)
	assert_false(loader.load_game())
	assert_eq(game.wallet.gold, 200, "new game")
	assert_eq(game.hunters.count(), 1)


func test_missing_and_extra_fields() -> void:
	var game := _game(5)
	var warnings := PackedStringArray()
	SaveCodec.restore(game, {"schema_version": 1, "gold": 50, "unknown_future_field": {"x": 1}, "progress": "oops"}, warnings)
	assert_eq(game.wallet.gold, 50)
	assert_eq(game.hunters.count(), 0)
	assert_eq(game.buildings.get_level(&"warehouse"), 1)
	assert_eq(game.recruitment.candidates.size(), 3, "candidates regenerated")
	assert_eq(warnings.size(), 1, "only the malformed progress section is reported")
	# A Hunter entry with almost nothing in it gets defaults.
	SaveCodec.restore(game, {"hunters": {"hunters": [{"unique_id": "h_7", "definition_id": "warrior"}]}}, warnings)
	var hunter: HunterRuntime = game.hunters.get_hunter(&"h_7")
	assert_not_null(hunter)
	assert_eq(hunter.level, 1)
	assert_eq(hunter.state, HunterRuntime.LifecycleState.AVAILABLE)


func test_invalid_ids_are_dropped_and_reported() -> void:
	var original := _rich_game()
	var data: Dictionary = JSON.parse_string(JSON.stringify(SaveCodec.capture(original)))
	data["inventory"]["stacks"]["unobtainium"] = 5
	data["inventory"]["instances"]["e_500"] = "laser_sword"
	var first: Dictionary = data["hunters"]["hunters"][0]
	first["trait_ids"].append("telepathic")
	first["equipment"]["weapon"] = "e_404"
	data["hunters"]["hunters"].append({"unique_id": "h_9", "definition_id": "dragon"})
	data["bonds"]["h_1|h_9"] = 80
	var copy := _game(5)
	var warnings := PackedStringArray()
	SaveCodec.restore(copy, data, warnings)
	var text := "\n".join(warnings)
	assert_true(text.contains("unobtainium"))
	assert_true(text.contains("laser_sword"))
	assert_true(text.contains("telepathic"))
	assert_true(text.contains("e_404"))
	assert_true(text.contains("dragon"))
	assert_true(text.contains("h_1|h_9"))
	assert_eq(copy.hunters.count(), 3)
	assert_false(copy.inventory.has(&"unobtainium"))
	assert_null(copy.equipment.get_equipped_item(copy.hunters.get_hunter(first["unique_id"]), &"weapon"))
	# The sword the first Hunter wore before the edit is no longer referenced: back in storage.
	assert_eq(copy.inventory.count(&"iron_sword") + copy.inventory.count(&"rusty_sword") >= 2, true)


func test_migration_from_schema_0() -> void:
	var warnings := PackedStringArray()
	var old := {"gold": 10, "materials": {"iron_ore": 4}, "inventory": {"stacks": {"iron_ore": 1}}}
	var migrated: Dictionary = SaveCodec.migrate(old, warnings)
	assert_eq(int(migrated["schema_version"]), SaveCodec.SCHEMA_VERSION)
	assert_eq(int(migrated["inventory"]["stacks"]["iron_ore"]), 5)
	assert_false(migrated.has("materials"))
	assert_true(migrated.has("saved_at_unix"))
	var game := _game(5)
	SaveCodec.restore(game, migrated, warnings)
	assert_eq(game.inventory.count(&"iron_ore"), 5)
	assert_null(SaveCodec.migrate({"schema_version": 99}, warnings), "newer schema refused")


func test_migration_from_schema_2_adds_a_temple() -> void:
	var warnings := PackedStringArray()
	var game := _game(5)
	var data := SaveCodec.capture(game)
	data["schema_version"] = 2
	var instances: Array = data["buildings"]["instances"]
	data["buildings"]["instances"] = instances.filter(func(entry: Dictionary) -> bool: return entry["building_id"] != "temple")
	var copy := _game(6)
	SaveCodec.restore(copy, SaveCodec.migrate(data, warnings), warnings)
	assert_true(copy.buildings.has_building(&"temple"))
	assert_eq(copy.buildings.get_instances().size(), 7)


func test_migration_from_schema_1_keeps_building_levels() -> void:
	var warnings := PackedStringArray()
	var old := {"schema_version": 1, "gold": 10, "buildings": {"town_hall": 2, "warehouse": 2, "tavern": 1},
		"hunters": {"hunters": [{"unique_id": "h_3", "definition_id": "warrior"}]}}
	var migrated: Dictionary = SaveCodec.migrate(old, warnings)
	assert_eq(int(migrated["schema_version"]), SaveCodec.SCHEMA_VERSION)
	var game := _game(5)
	SaveCodec.restore(game, migrated, warnings)
	assert_eq(game.buildings.get_level(&"town_hall"), 2)
	assert_eq(game.buildings.get_level(&"warehouse"), 2)
	assert_eq(game.buildings.get_instances().size(), 7, "default layout incl. the first House and the Temple")
	assert_eq(game.inventory.capacity, 80)
	assert_eq(game.hunters.get_hunter(&"h_3").purse, SaveCodec.MIGRATED_PURSE)
	assert_eq(game.housing.get_used_beds(), game.hunters.count(), "migrated Hunters get beds")


func test_expedition_in_progress_is_not_saved() -> void:
	var game := _game(5)
	game.wallet.add(500)
	game.recruitment.recruit(0)
	var ids: Array[StringName] = []
	for hunter: HunterRuntime in game.hunters.get_all():
		ids.append(hunter.unique_id)
	game.expeditions.start(&"dark_forest", ids)
	game.hunters.get_hunter(ids[1]).current_hp = 0.0
	var copy := _game(9)
	SaveCodec.restore(copy, JSON.parse_string(JSON.stringify(SaveCodec.capture(game))), PackedStringArray())
	assert_false(copy.expeditions.is_running())
	var standing: HunterRuntime = copy.hunters.get_hunter(ids[0])
	var downed: HunterRuntime = copy.hunters.get_hunter(ids[1])
	assert_eq(standing.expedition_id, &"")
	assert_eq(standing.state, HunterRuntime.LifecycleState.AVAILABLE)
	assert_true(downed.injured, "downed during the run → injured")
	assert_eq(downed.state, HunterRuntime.LifecycleState.RECOVERING)


func test_offline_progress_cap_and_clock_changes() -> void:
	var game := _game(5)
	var hunter: HunterRuntime = game.hunters.get_all()[0]
	game.hunters.mark_injured(hunter)
	var save := _save_manager(game)
	var negative: Dictionary = save.apply_offline_progress(-3600.0)
	assert_almost_eq(negative["seconds"], 0.0)
	assert_true(hunter.injured, "clock went back: nothing happens")
	var long: Dictionary = save.apply_offline_progress(20.0 * 3600.0)
	assert_almost_eq(long["seconds"], 8.0 * 3600.0)
	assert_true(long["capped"])
	assert_false(hunter.injured)
	assert_eq(Array(long["recovered"]), [hunter.display_name])
	assert_true(int(long["xp"]) > 0, "trained while away")


func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _delete_files() -> void:
	for path in [SAVE, BACKUP, SAVE + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
