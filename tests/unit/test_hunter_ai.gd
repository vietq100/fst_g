extends TestCase
## Hunter tactics and personality (AI_SYSTEM.md → Hunter tactics): targeting score, retreat ratio.

const DataRegistryScript := preload("res://core/data_registry.gd")
const GameManagerScript := preload("res://core/game_manager.gd")

var _registry: Node
var _game: Node
var _hunter: HunterRuntime


func before_each() -> void:
	_registry = DataRegistryScript.new()
	_registry.report_errors = false
	_registry.load_all(DataRegistryScript.DATA_ROOT, DataRegistryScript.CONFIG_PATH)
	_game = GameManagerScript.new()
	_game.build(_registry)
	_game.start_new_game()
	_hunter = _game.hunters.get_all()[0]


func after_each() -> void:
	_game.free()
	_registry.free()


func _with_traits(ids: Array[StringName]) -> Dictionary:
	_hunter.trait_ids.assign(ids)
	return _game.traits.get_behavior(_hunter)


func test_personality_moves_the_retreat_ratio() -> void:
	_with_traits([])
	var base: float = _game.regions.get_retreat_ratio(_hunter)
	assert_almost_eq(base, _game.registry.config.rest_below_hp_ratio, 0.001)
	_with_traits([&"coward"])
	assert_true(_game.regions.get_retreat_ratio(_hunter) > base + 0.2, "a coward runs early")
	_with_traits([&"reckless"])
	assert_true(_game.regions.get_retreat_ratio(_hunter) < base, "a reckless one fights on")
	_with_traits([&"coward", &"cautious"])
	assert_true(_game.regions.get_retreat_ratio(_hunter) <= 0.8, "capped")
	var max_hp: float = _game.hunters.get_stat(_hunter, HunterService.MAX_HP)
	_with_traits([&"coward"])
	_hunter.current_hp = max_hp * 0.5
	assert_true(_game.regions.needs_rest(_hunter, false), "a coward breaks off at half HP")
	_with_traits([&"reckless"])
	assert_false(_game.regions.needs_rest(_hunter, false), "a reckless one does not")


func test_behavior_numbers_combine() -> void:
	var none := _with_traits([])
	assert_eq(none["aggro"], 1.0)
	var brave := _with_traits([&"brave"])
	assert_true(brave["aggro"] > 1.0 and brave["boss"] > 0.0)
	var timid := _with_traits([&"coward", &"lazy"])
	assert_true(timid["aggro"] < 0.6, "multipliers multiply")


func test_score_prefers_wounded_close_protective_and_focused_targets() -> void:
	var calm := _with_traits([])
	var plain := {"enemy_hp": 1.0, "is_boss": false, "allies_on_it": 0, "hits_ally_in_trouble": false, "my_hp": 1.0}
	var base := HunterTactics.score(100.0, 150.0, plain, calm)
	assert_true(HunterTactics.score(100.0, 150.0, plain.merged({"enemy_hp": 0.2}, true), calm) < base, "wounded first")
	assert_true(HunterTactics.score(100.0, 150.0, plain.merged({"allies_on_it": 1}, true), calm) < base, "focus fire")
	assert_true(HunterTactics.score(100.0, 150.0, plain.merged({"hits_ally_in_trouble": true}, true), calm) < base, "protect allies")
	assert_true(HunterTactics.score(40.0, 150.0, plain, calm) < base, "nearer first")
	var discipled := _with_traits([&"disciplined"])
	var wounded := plain.merged({"enemy_hp": 0.3}, true)
	var gain_calm := base - HunterTactics.score(100.0, 150.0, wounded, calm)
	var gain_disciplined := HunterTactics.score(100.0, 150.0, plain, discipled) - HunterTactics.score(100.0, 150.0, wounded, discipled)
	assert_true(gain_disciplined > gain_calm, "a disciplined Hunter values finishing wounded enemies more")


func test_bosses_attract_the_brave_and_scare_the_hurt_cautious() -> void:
	var boss := {"enemy_hp": 1.0, "is_boss": true, "allies_on_it": 0, "hits_ally_in_trouble": false, "my_hp": 1.0}
	var brave := _with_traits([&"brave"])
	var cautious := _with_traits([&"cautious"])
	assert_true(HunterTactics.score(100.0, 150.0, boss, brave) < HunterTactics.score(100.0, 150.0, boss, cautious))
	var hurt := boss.merged({"my_hp": 0.3}, true)
	assert_true(HunterTactics.score(100.0, 150.0, hurt, cautious) > HunterTactics.score(100.0, 150.0, boss, cautious), "hurt: avoid the boss")


func test_potion_comes_before_the_retreat() -> void:
	var careful := _with_traits([&"disciplined"])
	var retreat := 0.35
	assert_true(HunterTactics.potion_ratio(retreat, careful) > HunterTactics.potion_ratio(retreat, {"potion": 0.0}))
	assert_true(HunterTactics.potion_ratio(retreat, {"potion": 0.0}) > retreat, "drinks before breaking off")
