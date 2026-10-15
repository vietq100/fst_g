extends TestCase
## Class skills, skill points, mana and reincarnation swaps (DECISIONS.md D69, D70).

const DataRegistryScript := preload("res://core/data_registry.gd")
const GameManagerScript := preload("res://core/game_manager.gd")
const HunterScene := preload("res://actors/hunter/hunter.tscn")

var _registry: Node
var _game: Node
var _skills: ClassSkillService
var _actors: Array[Node] = []


func before_each() -> void:
	_registry = DataRegistryScript.new()
	_registry.report_errors = false
	_registry.load_all(DataRegistryScript.DATA_ROOT, DataRegistryScript.CONFIG_PATH)
	_game = GameManagerScript.new()
	_game.rng.seed = 11
	_game.build(_registry)
	_game.start_new_game()
	_skills = _game.class_skills


func after_each() -> void:
	for actor in _actors:
		actor.free()
	_actors.clear()
	_game.hunters.clear_modifier_sources()
	_game.bonds.set_party_provider(func() -> Array: return [])
	_game.free()
	_registry.free()


func test_every_class_has_30_skills() -> void:
	assert_eq(_registry.load_errors.size(), 0, ", ".join(_registry.load_errors))
	assert_eq(_registry.get_count(&"class_skill"), 120)
	for class_id in [&"warrior", &"ranger", &"rogue", &"guardian"]:
		var pool := _skills.get_pool(class_id)
		assert_eq(pool.size(), 30, String(class_id))
		var actives := pool.filter(func(skill: ClassSkillDefinition) -> bool: return skill.is_active())
		assert_eq(actives.size(), 18, String(class_id))
		for skill in pool:
			assert_true(Loc.has_key("class_skill.%s.name" % skill.id), "name of %s" % skill.id)
			assert_true(Loc.has_key("class_skill.%s.desc" % skill.id), "desc of %s" % skill.id)
			if skill.is_active():
				assert_true(skill.cooldown > 0.0 and skill.mana_cost > 0.0, "cost of %s" % skill.id)
			assert_false(_skills.describe(skill, 1).is_empty(), "text of %s" % skill.id)


func test_promoted_classes_use_the_base_pool() -> void:
	var duelist := _game.hunters.create_hunter(&"duelist", _game.rng) as HunterRuntime
	assert_eq(_skills.get_base_class(duelist), &"warrior")
	var templar := _game.hunters.create_hunter(&"templar", _game.rng) as HunterRuntime
	assert_eq(_skills.get_base_class(templar), &"guardian")


func test_one_point_every_ten_levels() -> void:
	var hunter := _hunter()
	assert_eq(hunter.skill_points, 0, "recruits start without points")
	_game.hunters.set_level(hunter, 9)
	assert_eq(hunter.skill_points, 0)
	_game.hunters.set_level(hunter, 10)
	assert_eq(hunter.skill_points, 1)
	_game.hunters.set_level(hunter, 35)
	assert_eq(hunter.skill_points, 3)
	_skills.sync_points(hunter)
	assert_eq(hunter.skill_points, 3, "sync is idempotent")
	# Level-ups through XP grant points too.
	hunter.xp = 0
	_game.hunters.add_xp(hunter, 10_000_000, 40)
	assert_eq(hunter.level, 40)
	assert_eq(hunter.skill_points, 4)


func test_saves_before_class_skills_get_their_points() -> void:
	var data := _hunter().to_dict()
	data["level"] = 47
	data.erase("skill_points")
	data.erase("skill_point_level")
	var loaded := HunterRuntime.from_dict(data)
	_skills.sync_points(loaded)
	assert_eq(loaded.skill_points, 4)


func test_unlock_random_until_seven() -> void:
	var hunter := _hunter()
	assert_eq(_skills.can_unlock(hunter), "No skill points")
	hunter.skill_points = 10
	var seen: Dictionary = {}
	for i in 7:
		var skill := _skills.unlock_random(hunter)
		assert_not_null(skill)
		assert_eq(skill.class_id, &"warrior")
		assert_false(seen.has(skill.id), "no duplicates")
		seen[skill.id] = true
		assert_eq(_skills.get_level(hunter, skill.id), 1)
	assert_eq(hunter.class_skills.size(), 7)
	assert_eq(hunter.skill_points, 3)
	assert_eq(_skills.can_unlock(hunter), "Already has 7 skills")
	assert_null(_skills.unlock_random(hunter))


func test_upgrade_to_level_six_and_power() -> void:
	var hunter := _hunter()
	hunter.class_skills[&"heavy_slash"] = 1
	hunter.skill_points = 10
	for i in 5:
		assert_true(_skills.upgrade(hunter, &"heavy_slash"))
	assert_eq(_skills.get_level(hunter, &"heavy_slash"), 6)
	assert_eq(_skills.can_upgrade(hunter, &"heavy_slash"), "Already at level 6")
	assert_eq(hunter.skill_points, 5)
	assert_almost_eq(_skills.get_power(1), 1.0)
	assert_almost_eq(_skills.get_power(6), 1.75)
	var skill := _skills.get_skill(&"heavy_slash")
	assert_almost_eq(_skills.get_mana_cost(skill, 1), 17.0)
	assert_almost_eq(_skills.get_mana_cost(skill, 6), 22.0)
	assert_eq(_skills.can_upgrade(hunter, &"whirlwind"), "Skill not learned")


func test_passives_scale_with_level() -> void:
	var hunter := _hunter()
	var defense: float = _game.hunters.get_stat(hunter, HunterService.DEFENSE)
	hunter.class_skills[&"thick_skin"] = 1
	var at_one: float = _game.hunters.get_stat(hunter, HunterService.DEFENSE)
	assert_almost_eq(at_one, defense * 1.08, 0.01)
	hunter.class_skills[&"thick_skin"] = 6
	assert_almost_eq(_game.hunters.get_stat(hunter, HunterService.DEFENSE), defense * 1.14, 0.01)
	# Conditional passive only against bosses.
	hunter.class_skills[&"giant_slayer"] = 1
	assert_almost_eq(_game.hunters.get_stat(hunter, HunterService.DAMAGE_DEALT), 1.0)
	assert_almost_eq(_game.hunters.get_stat(hunter, HunterService.DAMAGE_DEALT, [&"vs_boss"] as Array[StringName]), 1.12)


func test_mana_stats() -> void:
	var hunter := _hunter()
	assert_almost_eq(_game.hunters.get_stat(hunter, HunterService.MAX_MANA), 100.0)
	assert_almost_eq(_game.hunters.get_stat(hunter, HunterService.MANA_REGEN), 5.0)
	_game.hunters.set_level(hunter, 11)
	assert_almost_eq(_game.hunters.get_stat(hunter, HunterService.MAX_MANA), 120.0)


func test_reincarnation_keeps_skills_and_gives_a_swap_point() -> void:
	var hunter := _hunter()
	hunter.class_skills[&"heavy_slash"] = 4
	hunter.class_skills[&"rend"] = 2
	_game.hunters.set_level(hunter, 99)
	_game.progress.set_flag(&"first_boss_clear")
	_game.inventory.capacity = 500
	for ore in [&"iron_ore", &"beast_fang", &"dark_essence", &"bone_dust"]:
		_game.inventory.add_item(ore, 200)
	_game.wallet.add(100000)
	while _game.buildings.get_level(&"town_hall") < 3:
		assert_true(_game.buildings.upgrade(&"town_hall"))
	_build(&"portal")
	assert_eq(_game.reincarnation.can_reincarnate(hunter), "Needs level 100")
	_game.hunters.set_level(hunter, 100)
	assert_eq(hunter.skill_points, 10)
	assert_true(_game.reincarnation.reincarnate(hunter))
	assert_eq(hunter.level, 1)
	assert_eq(hunter.class_skills.size(), 2)
	assert_eq(_skills.get_level(hunter, &"heavy_slash"), 4)
	assert_eq(_skills.get_level(hunter, &"rend"), 2)
	assert_eq(hunter.skill_swap_points, 1)
	assert_eq(hunter.skill_points, 10, "unspent points stay")
	_game.hunters.set_level(hunter, 10)
	assert_eq(hunter.skill_points, 11, "the new life earns points again")
	# Swap: same slot and level, a skill the Hunter did not own.
	var swapped := _skills.swap(hunter, &"heavy_slash")
	assert_not_null(swapped)
	assert_false(swapped.id in [&"heavy_slash", &"rend"])
	assert_eq(hunter.class_skills.keys()[0], swapped.id, "same slot")
	assert_eq(hunter.class_skills.keys()[1], &"rend")
	assert_eq(_skills.get_level(hunter, swapped.id), 4)
	assert_eq(hunter.skill_swap_points, 0)
	assert_eq(_skills.can_swap(hunter, &"rend"), "No swap points")


func test_save_round_trip_keeps_order_and_points() -> void:
	var hunter := _hunter()
	hunter.class_skills[&"rend"] = 3
	hunter.class_skills[&"heavy_slash"] = 1
	hunter.skill_points = 2
	hunter.skill_swap_points = 1
	hunter.skill_point_level = 20
	hunter.current_mana = 42.0
	var loaded := HunterRuntime.from_dict(JSON.parse_string(JSON.stringify(hunter.to_dict())))
	assert_eq(loaded.class_skills.keys()[0], &"rend")
	assert_eq(loaded.class_skills.keys()[1], &"heavy_slash")
	assert_eq(loaded.class_skills[&"rend"], 3)
	assert_eq(loaded.skill_points, 2)
	assert_eq(loaded.skill_swap_points, 1)
	assert_eq(loaded.skill_point_level, 20)
	assert_almost_eq(loaded.current_mana, 42.0)


func test_caster_spends_mana_and_hits() -> void:
	var hunter := _hunter()
	hunter.class_skills[&"heavy_slash"] = 1
	var actor := _spawn_hunter(hunter)
	var slime := _slime(Vector2(10, 0))
	actor.combat.force_target(slime)
	var caster := actor.skill_caster
	assert_not_null(caster)
	caster.refresh()
	hunter.current_mana = 100.0
	var hp := slime.health.current_health
	caster.advance(0.0)
	assert_true(slime.health.current_health < hp, "heavy slash hit")
	assert_almost_eq(hunter.current_mana, 100.0 - 17.0, 0.01)
	assert_almost_eq(caster.get_cooldown(&"heavy_slash"), 6.0)
	# On cooldown: nothing more.
	var mana := hunter.current_mana
	caster.advance(1.0)
	assert_almost_eq(hunter.current_mana, minf(mana + 5.0, 100.0), 0.01, "regen only")


func test_caster_needs_mana() -> void:
	var hunter := _hunter()
	hunter.class_skills[&"heavy_slash"] = 1
	var actor := _spawn_hunter(hunter)
	var slime := _slime(Vector2(10, 0))
	actor.combat.force_target(slime)
	actor.skill_caster.refresh()
	hunter.current_mana = 5.0
	actor.skill_caster.advance(0.0)
	assert_almost_eq(actor.skill_caster.get_cooldown(&"heavy_slash"), 0.0, 0.001, "not cast without mana")


func test_boss_gets_stagger_instead_of_stun() -> void:
	var hunter := _hunter()
	var actor := _spawn_hunter(hunter)
	var boss := _slime(Vector2(10, 0), &"forest_guardian")
	actor.combat.force_target(boss)
	assert_true(actor.skill_caster.try_cast(_skills.get_skill(&"shoulder_bash"), 1))
	assert_false(boss.effects.has_effect(&"stun"))
	assert_true(boss.effects.has_effect(&"stagger"))
	# Soft debuffs last half as long on bosses.
	assert_true(actor.skill_caster.try_cast(_skills.get_skill(&"crushing_blow"), 1))
	var armor_break := boss.effects.get_effect(&"armor_break")
	assert_almost_eq(armor_break.remaining, armor_break.definition.duration * 0.5, 0.01)
	# Bleed (% of max HP) deals a quarter on bosses.
	var bleed := _registry.find_def(&"status_effect", &"bleed") as StatusEffectDefinition
	var hp := boss.health.current_health
	boss.effects.apply(bleed, null, 1)
	boss.effects.advance(bleed.tick_interval)
	assert_almost_eq(hp - boss.health.current_health, boss.health.max_health * bleed.damage_per_tick * 0.25, 0.5)
	var slime := _slime(Vector2(-10, 0))
	actor.combat.force_target(slime)
	assert_true(actor.skill_caster.try_cast(_skills.get_skill(&"shoulder_bash"), 1))
	assert_true(slime.effects.has_effect(&"stun") or slime.health.is_dead())


func test_heal_waits_for_a_wounded_ally() -> void:
	var hunter := _hunter(&"guardian")
	var actor := _spawn_hunter(hunter)
	var slime := _slime(Vector2(10, 0))
	actor.combat.force_target(slime)
	var heal := _skills.get_skill(&"healing_light")
	assert_false(actor.skill_caster.try_cast(heal, 1), "everyone is healthy")
	actor.health.take_damage(actor.health.max_health * 0.5)
	var before := actor.health.current_health
	assert_true(actor.skill_caster.try_cast(heal, 1))
	assert_true(actor.health.current_health > before)


func test_effect_durations_grow_with_skill_level() -> void:
	var hunter := _hunter()
	var actor := _spawn_hunter(hunter)
	var slime := _slime(Vector2(10, 0), &"skeleton")
	actor.combat.force_target(slime)
	var cry := _skills.get_skill(&"battle_cry")
	assert_true(actor.skill_caster.try_cast(cry, 6))
	var strength := actor.effects.get_effect(&"strength")
	assert_almost_eq(strength.remaining, strength.definition.duration * 1.75, 0.01, "buffs × power")
	assert_true(actor.skill_caster.try_cast(_skills.get_skill(&"hamstring"), 6))
	var slow := slime.effects.get_effect(&"slow")
	assert_almost_eq(slow.remaining, slow.definition.duration * 1.375, 0.01, "debuffs × half the bonus")


func test_tenacity_shortens_crowd_control() -> void:
	var hunter := _hunter()
	hunter.class_skills[&"iron_will"] = 1
	var actor := _spawn_hunter(hunter)
	var stun := _registry.find_def(&"status_effect", &"stun") as StatusEffectDefinition
	var effect := actor.effects.apply(stun)
	# Iron Will Lv1 at Hunter level 1: 30% + 0.5% = 30.5%.
	assert_almost_eq(effect.remaining, stun.duration * (1.0 - 0.305), 0.01)


func test_dodge_makes_attacks_miss() -> void:
	var hunter := _hunter(&"rogue")
	hunter.class_skills[&"advanced_evasion"] = 6
	var actor := _spawn_hunter(hunter)
	assert_almost_eq(actor.get_combat_stats().dodge, 0.08 * 1.75, 0.001)
	var slime := _slime(Vector2(10, 0))
	var misses := [0]
	_game.combat.attack_dodged.connect(func(_a: Actor, _t: Actor) -> void: misses[0] += 1)
	for i in 200:
		_game.combat.resolve_attack(slime, actor)
		actor.health.heal(1000.0)
	assert_true(misses[0] > 5 and misses[0] < 60, "about 14%% dodged, got %d" % misses[0])


func test_every_skill_runs_in_a_fight() -> void:
	for class_id in [&"warrior", &"ranger", &"rogue", &"guardian"]:
		var hunter := _hunter(class_id)
		for skill in _skills.get_pool(class_id):
			hunter.class_skills[skill.id] = 6
		var actor := _spawn_hunter(hunter)
		var ally := _spawn_hunter(_hunter(class_id))
		ally.global_position = Vector2(0, 12)
		ally.health.take_damage(ally.health.max_health * 0.6)
		actor.health.take_damage(actor.health.max_health * 0.8)
		var poison := _registry.find_def(&"status_effect", &"poison") as StatusEffectDefinition
		actor.effects.apply(poison)
		var cast := 0
		for skill in _skills.get_pool(class_id):
			var slime := _slime(Vector2(10, 0), &"skeleton")
			slime.effects.apply(poison, null, 3)
			_slime(Vector2(20, 6))
			# Wounded (heals and low-HP triggers fire) but alive.
			actor.health.setup(actor.health.max_health, actor.health.max_health * 0.1)
			actor.combat.force_target(slime)
			if not skill.is_castable():
				continue
			if actor.skill_caster.try_cast(skill, 6):
				cast += 1
			else:
				assert_true(false, "%s did not fire" % skill.id)
		var castable := _skills.get_pool(class_id).filter(func(skill: ClassSkillDefinition) -> bool: return skill.is_castable())
		assert_eq(cast, castable.size(), "%s: every castable skill fires in a fight" % class_id)
		# Passive modifiers of all 30 skills at level 6 stay sane.
		assert_true(_game.hunters.get_stat(hunter, HunterService.ATTACK) > 0.0)
		assert_true(actor.get_combat_stats().dodge <= _registry.config.dodge_cap)
		assert_true(actor.get_tenacity() <= _registry.config.tenacity_cap)


# --- helpers -----------------------------------------------------------------------------------

## A Hunter without traits and with neutral mood, so stat checks are exact.
func _hunter(class_id: StringName = &"warrior") -> HunterRuntime:
	var hunter: HunterRuntime = _game.hunters.create_hunter(class_id, _game.rng)
	hunter.trait_ids.clear()
	hunter.mood = 50.0
	return hunter


func _spawn_hunter(hunter: HunterRuntime) -> Hunter:
	var actor := HunterScene.instantiate() as Hunter
	(Engine.get_main_loop() as SceneTree).root.add_child(actor)
	actor._config_override = _registry.config
	actor.setup(hunter, _game.hunters, _game.combat, 0.5, null, _skills)
	_actors.append(actor)
	return actor


func _slime(at: Vector2, enemy_id: StringName = &"slime") -> Enemy:
	var definition := _registry.find_def(&"enemy", enemy_id) as EnemyDefinition
	var enemy := definition.actor_scene.instantiate() as Enemy
	(Engine.get_main_loop() as SceneTree).root.add_child(enemy)
	enemy.setup(definition, _game.combat, 0.5)
	enemy.global_position = at
	_actors.append(enemy)
	return enemy


func _build(building_id: StringName) -> void:
	for gx in range(2, 30):
		for gy in range(2, 30):
			if _game.buildings.can_place(building_id, Vector2i(gx, gy)).is_empty():
				assert_not_null(_game.buildings.build(building_id, Vector2i(gx, gy)), String(building_id))
				return
	assert_true(false, "no room for %s" % building_id)
