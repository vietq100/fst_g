extends TestCase
## Traits, mood, bonds, activities and history (HUNTER_LIFE_SYSTEM.md, DECISIONS.md D13, D14, D26).

const DataRegistryScript := preload("res://core/data_registry.gd")

var _registry: Node
var _config: GameConfig
var _stats: StatService
var _hunters: HunterService
var _progress: ProgressService
var _traits: TraitService
var _mood: MoodService
var _bonds: BondService
var _activities: ActivityService
var _rng: RandomNumberGenerator
var _party: Array[StringName] = []


func before_each() -> void:
	_registry = DataRegistryScript.new()
	_registry.report_errors = false
	_registry.load_all(DataRegistryScript.DATA_ROOT, DataRegistryScript.CONFIG_PATH)
	_config = _registry.config
	_rng = RandomNumberGenerator.new()
	_rng.seed = 21
	_stats = StatService.new(_config)
	_hunters = HunterService.new(_registry, _stats, _config)
	_progress = ProgressService.new()
	_traits = TraitService.new(_registry, _hunters, _config, _rng)
	_mood = MoodService.new(_hunters, _traits, _config)
	_bonds = BondService.new(_hunters, _config)
	_bonds.set_party_provider(func() -> Array[StringName]: return _party)
	_activities = ActivityService.new(_registry, _hunters, _traits, _mood, _bonds, _stats, _progress, _config)
	_party = []


func after_each() -> void:
	# The party provider lambda captures this test; drop it to break the cycle.
	_bonds.set_party_provider(func() -> Array: return [])
	_hunters.clear_modifier_sources()
	_registry.free()


func _hunter(trait_ids: Array[StringName] = []) -> HunterRuntime:
	var hunter := _hunters.create_hunter(&"warrior", _rng)
	hunter.stat_rolls.clear()
	hunter.trait_ids = trait_ids
	hunter.current_hp = _hunters.get_stat(hunter, HunterService.MAX_HP)
	return hunter


func _run(party: Array[HunterRuntime], success: bool, boss_reached: bool = true) -> ExpeditionRun:
	var run := ExpeditionRun.new()
	run.expedition_id = &"dark_forest"
	for hunter in party:
		run.party_ids.append(hunter.unique_id)
	run.phase = ExpeditionRun.Phase.SUCCESS if success else ExpeditionRun.Phase.FAILED
	run.boss_reached = boss_reached
	return run


func test_random_traits_are_distinct_and_in_range() -> void:
	for i in 30:
		var hunter := _hunter()
		_traits.assign_random_traits(hunter)
		assert_true(hunter.trait_ids.size() >= 1 and hunter.trait_ids.size() <= 2)
		if hunter.trait_ids.size() == 2:
			assert_true(hunter.trait_ids[0] != hunter.trait_ids[1])


func test_trait_stat_modifiers() -> void:
	var reckless := _hunter([&"reckless"])
	assert_almost_eq(_hunters.get_stat(reckless, HunterService.DAMAGE_DEALT), 1.15)
	assert_almost_eq(_hunters.get_stat(reckless, HunterService.DAMAGE_TAKEN), 1.10)
	var cautious := _hunter([&"cautious"])
	assert_almost_eq(_hunters.get_stat(cautious, HunterService.DAMAGE_TAKEN), 0.90)
	var brave := _hunter([&"brave"])
	assert_almost_eq(_hunters.get_stat(brave, HunterService.DAMAGE_DEALT), 1.0, 0.0001, "only vs boss")
	var vs_boss: Array[StringName] = [&"vs_boss"]
	assert_almost_eq(_hunters.get_stat(brave, HunterService.DAMAGE_DEALT, vs_boss), 1.15)
	assert_almost_eq(_hunters.get_stat(_hunter([&"greedy"]), HunterService.GOLD_FIND), 1.2)
	assert_almost_eq(_traits.get_activity_rate(_hunter([&"lazy"]), &"training"), 0.5)
	assert_almost_eq(_traits.get_activity_rate(_hunter([&"lazy"]), &"resting"), 1.5)
	assert_almost_eq(_traits.get_activity_rate(_hunter([&"disciplined", &"lazy"]), &"training"), 0.75)


func test_mood_states_change_stats_and_xp() -> void:
	var hunter := _hunter()
	hunter.mood = 60.0
	assert_eq(_mood.get_state(hunter), MoodService.State.NORMAL)
	assert_almost_eq(_hunters.get_stat(hunter, HunterService.ATTACK), 14.0)
	_mood.change(hunter, 15.0)
	assert_eq(_mood.get_state(hunter), MoodService.State.HIGH)
	assert_almost_eq(_hunters.get_stat(hunter, HunterService.ATTACK), 14.7)
	assert_almost_eq(_hunters.get_stat(hunter, HunterService.XP_GAIN), 1.1)
	_mood.change(hunter, -60.0)
	assert_eq(_mood.get_state(hunter), MoodService.State.LOW)
	assert_almost_eq(_hunters.get_stat(hunter, HunterService.ATTACK), 12.6)
	_mood.change(hunter, -500.0)
	assert_almost_eq(hunter.mood, 0.0, 0.0001, "clamped")


func test_expedition_mood_events() -> void:
	var greedy := _hunter([&"greedy"])
	var cautious := _hunter([&"cautious"])
	greedy.mood = 50.0
	cautious.mood = 50.0
	var run := _run([greedy, cautious], true)
	_mood.on_expedition_finished(run, _registry.find_def(&"expedition", &"dark_forest"))
	# Greedy: success +10, likes boss kill +5. Cautious: +10, likes success +5,
	# dislikes being below the recommended level (Lv 1 < 4) −5.
	assert_almost_eq(greedy.mood, 65.0)
	assert_almost_eq(cautious.mood, 60.0)
	var failure := _run([greedy], false)
	failure.downed_ids.append(greedy.unique_id)
	_mood.on_expedition_finished(failure, null)
	# −15 failure, −10 injured, Greedy dislikes failure −5, back-to-back (2nd in a row) no reaction.
	assert_almost_eq(greedy.mood, 35.0)


func test_overwork_and_rest_resets_it() -> void:
	var hunter := _hunter()
	hunter.mood = 50.0
	for i in 3:
		_mood.on_expedition_finished(_run([hunter], true, false), null)
	# +10 ×3, third in a row −5.
	assert_almost_eq(hunter.mood, 75.0)
	assert_eq(hunter.history[HunterRuntime.CONSECUTIVE_EXPEDITIONS], 3)
	hunter.current_hp = 1.0
	_activities.tick(10.0)
	assert_eq(hunter.activity, ActivityService.RESTING)
	assert_eq(hunter.history[HunterRuntime.CONSECUTIVE_EXPEDITIONS], 0)


func test_brave_dislikes_staying_home() -> void:
	var brave := _hunter([&"brave"])
	var other := _hunter()
	brave.mood = 50.0
	_mood.on_expedition_finished(_run([other], true, false), null)
	assert_almost_eq(brave.mood, 50.0)
	_mood.on_expedition_finished(_run([other], true, false), null)
	assert_almost_eq(brave.mood, 45.0, 0.0001, "second cycle at home")


func test_default_activity_rule() -> void:
	var hunter := _hunter()
	hunter.mood = 60.0
	assert_eq(_activities.decide(hunter), ActivityService.TRAINING)
	hunter.mood = 40.0
	assert_eq(_activities.decide(hunter), ActivityService.RESTING)
	hunter.mood = 60.0
	hunter.current_hp -= 1.0
	assert_eq(_activities.decide(hunter), ActivityService.RESTING)
	_hunters.mark_injured(hunter)
	assert_eq(_activities.decide(hunter), ActivityService.RECOVERING)


func test_assignment() -> void:
	var hunter := _hunter()
	assert_eq(_activities.set_assignment(hunter, ActivityService.SOCIALIZING), "")
	assert_eq(_activities.decide(hunter), ActivityService.SOCIALIZING)
	assert_false(_activities.set_assignment(hunter, ActivityService.RECOVERING).is_empty())
	assert_eq(_activities.set_assignment(hunter, &""), "")
	assert_eq(_activities.decide(hunter), ActivityService.TRAINING)


func test_resting_heals_and_lazy_rests_faster() -> void:
	var normal := _hunter()
	var lazy := _hunter([&"lazy"])
	for hunter in [normal, lazy]:
		hunter.current_hp = 20.0
		hunter.mood = 40.0
	_activities.tick(10.0)
	# 5% of 120 = 6 HP, ×1.5 for Lazy; mood +2 / +3.
	assert_almost_eq(normal.current_hp, 26.0)
	assert_almost_eq(lazy.current_hp, 29.0)
	assert_almost_eq(normal.mood, 42.0)
	assert_almost_eq(lazy.mood, 43.0)


func test_training_xp_with_trait_rates() -> void:
	var normal := _hunter()
	var disciplined := _hunter([&"disciplined"])
	for hunter in [normal, disciplined]:
		hunter.mood = 60.0
	_activities.tick(30.0)
	assert_eq(normal.xp, 3)
	# 1 × 1.5 per tick; fractions carry over: 1.5, 3.0, 4.5 → 4.
	assert_eq(disciplined.xp, 4)


func test_offline_training_gives_a_quarter() -> void:
	var hunter := _hunter()
	hunter.mood = 60.0
	_activities.tick(400.0, false)
	assert_eq(hunter.xp, 10, "40 ticks × 1 XP × 0.25")


func test_hunters_on_expedition_do_nothing_in_town() -> void:
	var hunter := _hunter()
	hunter.expedition_id = &"dark_forest"
	hunter.current_hp = 10.0
	_activities.tick(100.0)
	assert_almost_eq(hunter.current_hp, 10.0)


func test_socializing_builds_bonds() -> void:
	var a := _hunter()
	var b := _hunter()
	for hunter in [a, b]:
		_activities.set_assignment(hunter, ActivityService.SOCIALIZING)
	_activities.tick(10.0 * 50)
	assert_true(_bonds.is_bonded(a.unique_id, b.unique_id), "2 per tick × 50 = 100")
	var mood_before := a.mood
	_activities.tick(10.0)
	# +3 socializing, +2 bonded partner.
	assert_almost_eq(a.mood, minf(mood_before + 5.0, 100.0))


func test_shared_expeditions_and_party_bonus() -> void:
	var a := _hunter()
	var b := _hunter()
	var c := _hunter()
	for i in 5:
		_bonds.on_expedition_finished(_run([a, b], true))
	assert_true(_bonds.is_bonded(a.unique_id, b.unique_id))
	assert_false(_bonds.is_bonded(a.unique_id, c.unique_id))
	assert_almost_eq(_hunters.get_stat(a, HunterService.ATTACK), 14.0, 0.0001, "no bonus outside a running party")
	_party = [a.unique_id, b.unique_id, c.unique_id]
	assert_almost_eq(_hunters.get_stat(a, HunterService.ATTACK), 14.7)
	assert_almost_eq(_hunters.get_stat(c, HunterService.ATTACK), 14.0, 0.0001, "c has no bonded partner")


func test_bond_round_trip_drops_unknown_hunters() -> void:
	var a := _hunter()
	var b := _hunter()
	_bonds.add(a.unique_id, b.unique_id, 40.0)
	var data := _bonds.to_dict()
	data["h_1|h_999"] = 50.0
	var warnings := PackedStringArray()
	_bonds.from_dict(data, warnings)
	assert_almost_eq(_bonds.get_value(b.unique_id, a.unique_id), 40.0)
	assert_eq(warnings.size(), 1)


func test_day_counter() -> void:
	_progress.advance(299.0, 300.0)
	assert_eq(_progress.day, 1)
	_progress.advance(2.0, 300.0)
	assert_eq(_progress.day, 2)
	_progress.advance(900.0, 300.0)
	assert_eq(_progress.day, 5)
