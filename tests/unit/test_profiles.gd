extends TestCase
## Profiles (login stand-in): index, per-profile save files, legacy migration.

const SaveManagerScript := preload("res://core/save_manager.gd")
const ROOT := "user://test_profiles"

var _old_index := ""
var _old_folder := ""


func before_each() -> void:
	_old_index = ProfileStore.index_path
	_old_folder = ProfileStore.folder
	ProfileStore.index_path = ROOT + "_index.json"
	ProfileStore.folder = ROOT
	_clean()


func after_each() -> void:
	_clean()
	ProfileStore.index_path = _old_index
	ProfileStore.folder = _old_folder


func _clean() -> void:
	for profile in ProfileStore.list():
		ProfileStore.delete(profile["id"])
	if FileAccess.file_exists(ProfileStore.index_path):
		DirAccess.remove_absolute(ProfileStore.index_path)


func test_create_trims_names_and_lists_profiles() -> void:
	var a := ProfileStore.create("  Alice  ")
	var b := ProfileStore.create("")
	assert_true(a != b, "distinct ids")
	var names: Array = ProfileStore.list().map(func(p: Dictionary) -> String: return p["name"])
	assert_true(names.has("Alice"), "trimmed name")
	assert_eq(names.size(), 2)
	assert_eq(ProfileStore.create("x".repeat(40)).is_empty(), false)
	assert_true(String(ProfileStore.list().map(func(p: Dictionary) -> String: return p["name"]).filter(func(n: String) -> bool: return n.begins_with("xxx"))[0]).length() <= ProfileStore.MAX_NAME)


func test_delete_removes_files() -> void:
	var id := ProfileStore.create("Bob")
	DirAccess.make_dir_recursive_absolute(ProfileStore.save_path(id).get_base_dir())
	var file := FileAccess.open(ProfileStore.save_path(id), FileAccess.WRITE)
	file.store_string("{}")
	file.close()
	ProfileStore.delete(id)
	assert_false(FileAccess.file_exists(ProfileStore.save_path(id)))
	assert_true(ProfileStore.get_profile(id).is_empty())


func test_save_manager_keeps_profiles_apart() -> void:
	var registry: Node = preload("res://core/data_registry.gd").new()
	registry.report_errors = false
	registry.load_all(registry.DATA_ROOT, registry.CONFIG_PATH)
	var game: Node = preload("res://core/game_manager.gd").new()
	game.build(registry)
	game.start_new_game()
	var save: Node = SaveManagerScript.new()
	save.game = game
	var a := ProfileStore.create("A")
	var b := ProfileStore.create("B")
	save.select_profile(a)
	game.wallet.add(777)
	assert_true(save.save_game(&"test"))
	save.select_profile(b)
	assert_true(game.wallet.gold != game.registry.config.start_gold + 777, "profile B starts fresh")
	save.select_profile(a)
	assert_eq(game.wallet.gold, game.registry.config.start_gold + 777, "profile A restored")
	assert_eq(int(ProfileStore.get_profile(a)["gold"]), game.wallet.gold, "summary updated")
	save.logout()
	assert_false(save.has_profile())
	save.free()
	game.free()
	registry.free()


func test_login_screen_lists_profiles() -> void:
	ProfileStore.create("Carol")
	var screen := ProfileScreen.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(screen)
	var found := false
	var stack: Array[Node] = [screen]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is Label and (node as Label).text == "Carol":
			found = true
		stack.append_array(node.get_children())
	assert_true(found, "profile card shown")
	screen.queue_free()


func test_sample_slots_reach_their_levels() -> void:
	var registry: Node = preload("res://core/data_registry.gd").new()
	registry.report_errors = false
	registry.load_all(registry.DATA_ROOT, registry.CONFIG_PATH)
	for preset: Dictionary in ProfilePresets.PRESETS:
		var game: Node = preload("res://core/game_manager.gd").new()
		game.build(registry)
		game.start_new_game()
		ProfilePresets.apply(game, preset)
		assert_true(game.hunters.count() >= 1, "%s has hunters" % preset["id"])
		for hunter: HunterRuntime in game.hunters.get_all():
			assert_eq(hunter.level, int(preset["level"]), "%s hunter level" % preset["id"])
		game.free()
	registry.free()


func test_install_samples_creates_loadable_profiles_once() -> void:
	assert_eq(ProfilePresets.install_missing(), ProfilePresets.PRESETS.size())
	assert_eq(ProfilePresets.install_missing(), 0, "installed once")
	var profiles := ProfileStore.list()
	assert_eq(profiles.size(), ProfilePresets.PRESETS.size())
	var strongest: Dictionary = {}
	var weakest: Dictionary = {}
	for profile in profiles:
		assert_true(FileAccess.file_exists(ProfileStore.save_path(profile["id"])), "%s has a save" % profile["name"])
		if strongest.is_empty() or int(profile["town"]) > int(strongest["town"]):
			strongest = profile
		if weakest.is_empty() or int(profile["town"]) < int(weakest["town"]):
			weakest = profile
	assert_eq(int(strongest["town"]), 5, "Lv100 slot has a max Town Hall")
	assert_true(int(strongest["gold"]) > int(weakest["gold"]), "gold differs")
	SaveManager.select_profile(strongest["id"])
	assert_true(GameManager.hunters.get_all()[0].level > 1, "strong hunters reloaded")
	SaveManager.logout()
	assert_false(SaveManager.has_profile())
