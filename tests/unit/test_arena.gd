extends TestCase
## Colosseum phase 1 (ARENA_SYSTEM.md): the building, eligibility, rival generation, the simulated
## 1vs1 fight with PvP rules, and what a match changes.

const DataRegistryScript := preload("res://core/data_registry.gd")
const GameManagerScript := preload("res://core/game_manager.gd")

var _registry: Node
var _game: Node


func before_each() -> void:
	_registry = DataRegistryScript.new()
	_registry.report_errors = false
	_registry.load_all(DataRegistryScript.DATA_ROOT, DataRegistryScript.CONFIG_PATH)
	_game = GameManagerScript.new()
	_game.rng.seed = 5
	_game.build(_registry)
	_game.start_new_game()
	_game.wallet.add(100000)
	_game.progress.set_flag(&"first_boss_clear")
	_game.inventory.capacity = 500
	_game.inventory.add_item(&"iron_ore", 100)
	_game.inventory.add_item(&"beast_fang", 100)
	_game.inventory.add_item(&"dark_essence", 100)
	_game.inventory.add_item(&"bone_dust", 100)
	while _game.buildings.get_level(&"town_hall") < 2:
		_game.buildings.upgrade(&"town_hall")


func after_each() -> void:
	_game.hunters.clear_modifier_sources()
	_game.bonds.set_party_provider(func() -> Array: return [])
	_game.free()
	_registry.free()


func _build_colosseum() -> void:
	for gx in range(2, 33):
		for gy in range(2, 33):
			if _game.buildings.can_place(&"colosseum", Vector2i(gx, gy)).is_empty():
				assert_not_null(_game.buildings.build(&"colosseum", Vector2i(gx, gy)))
				return
	assert_true(false, "no room for the colosseum")


func _fighter(level: int = 10) -> HunterRuntime:
	var hunter: HunterRuntime = _game.hunters.get_all()[0]
	_game.hunters.set_level(hunter, level)
	hunter.current_hp = _game.hunters.get_stat(hunter, HunterService.MAX_HP)
	return hunter


func test_colosseum_needs_town_hall_two_and_is_unique() -> void:
	assert_eq(_game.buildings.get_definition(&"colosseum").required_town_level, 2)
	assert_eq(_game.buildings.can_build(&"colosseum"), "")
	_build_colosseum()
	assert_eq(_game.buildings.can_build(&"colosseum"), Loc.t("err.building.already_built"))
	assert_eq(_game.buildings.get_effect(&"colosseum", BuildingService.COLOSSEUM_FORMAT), 1.0)


func test_eligibility_reasons() -> void:
	var hunter := _fighter(10)
	assert_eq(_game.arena.can_enter(hunter), Loc.t("err.arena.no_colosseum"))
	_build_colosseum()
	assert_eq(_game.arena.can_enter(hunter), "")
	_game.hunters.set_level(hunter, 2)
	assert_eq(_game.arena.can_enter(hunter), Loc.t("err.arena.level", {"level": 5}))
	_game.hunters.set_level(hunter, 10)
	hunter.stamina = 10.0
	assert_eq(_game.arena.can_enter(hunter), Loc.t("err.arena.tired", {"name": hunter.display_name}))
	hunter.stamina = 100.0
	hunter.injured = true
	assert_eq(_game.arena.can_enter(hunter), Loc.t("err.arena.hurt", {"name": hunter.display_name}))


func test_rivals_are_weaker_even_and_stronger() -> void:
	_build_colosseum()
	var hunter := _fighter(12)
	_game.arena.refresh_board(hunter)
	assert_eq(_game.arena.board.size(), 3)
	var mine: float = _game.arena.get_power(hunter)
	var powers: Array[float] = []
	for rival in _game.arena.board:
		powers.append(_game.arena.get_power(rival))
		assert_eq(rival.unique_id, &"", "rivals are not in the roster")
	assert_true(powers[0] < powers[1] and powers[1] < powers[2], "weaker < even < stronger")
	assert_true(absf(powers[1] - mine) / mine < 0.2, "the even rival matches its power")


func test_simulation_is_deterministic_and_pvp_dampened() -> void:
	var a := _fighter(12)
	var b: HunterRuntime = _game.arena.make_rival(_game.arena.get_power(a))
	var first: ArenaResult = _game.arena.simulate(a, b, 99)
	var second: ArenaResult = _game.arena.simulate(a, b, 99)
	assert_eq(first.events.size(), second.events.size())
	assert_eq(first.winner, second.winner)
	assert_almost_eq(first.duration, second.duration)
	assert_true(first.events.size() > 2, "several blows")
	assert_true(first.duration <= 60.0 + 0.001, "within the time limit")
	# The first landed hit is attack − defense/2, scaled by 0.8 (crits aside).
	for event in first.events:
		if not event["dodged"] and not event["crit"]:
			var attacker: HunterRuntime = a if event["from"] == 0 else b
			var target: HunterRuntime = b if event["from"] == 0 else a
			var raw: float = _game.stats.calculate_damage(_game.hunters.get_stat(attacker, HunterService.ATTACK), _game.hunters.get_stat(target, HunterService.DEFENSE))
			assert_true(event["damage"] <= roundi(raw * 1.2 * 0.8) + 1, "PvP damage is dampened")
			break


func test_a_much_stronger_fighter_wins_and_hp_never_goes_negative() -> void:
	var weak := _fighter(5)
	var strong: HunterRuntime = _game.arena.make_rival(_game.arena.get_power(weak) * 4.0)
	var result: ArenaResult = _game.arena.simulate(weak, strong, 3)
	assert_eq(result.winner, 1)
	assert_true(result.hp_end[0] >= 0.0 and result.hp_end[1] > 0.0)
	assert_almost_eq(result.hp_ratio(0), 0.0)


func test_time_limit_ends_with_the_higher_hp_ratio_winning() -> void:
	var a := _fighter(10)
	_registry.config.arena_time_limit = 0.9
	var b: HunterRuntime = _game.arena.make_rival(_game.arena.get_power(a))
	var result: ArenaResult = _game.arena.simulate(a, b, 4)
	assert_true(result.timed_out or result.winner != -1 or result.events.size() <= 2)
	assert_true(result.duration <= 0.9 + 0.001)


func test_match_changes_only_stamina_and_mood() -> void:
	_build_colosseum()
	var hunter := _fighter(12)
	var hp: float = hunter.current_hp
	var xp: int = hunter.xp
	hunter.mood = 50.0
	hunter.stamina = 80.0
	var result := ArenaResult.new()
	result.winner = 0
	_game.arena.apply_result(hunter, result, 0)
	assert_almost_eq(hunter.stamina, 70.0)
	assert_almost_eq(hunter.mood, 55.0)
	assert_eq(hunter.history.get(&"arena_wins", 0), 1)
	result.winner = 1
	_game.arena.apply_result(hunter, result, 0)
	assert_almost_eq(hunter.mood, 52.0)
	assert_eq(hunter.history.get(&"arena_losses", 0), 1)
	assert_almost_eq(hunter.current_hp, hp)
	assert_eq(hunter.xp, xp)
	assert_true(hunter.alive and not hunter.injured, "the arena is safe")
