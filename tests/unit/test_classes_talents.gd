extends TestCase
## Hunter classes and talents (DECISIONS.md D45, D46, BALANCE.md → Classes / Talents).

const DataRegistryScript := preload("res://core/data_registry.gd")
const GameManagerScript := preload("res://core/game_manager.gd")

var _registry: Node
var _game: Node
var _talents: TalentService
var _hunter: HunterRuntime


func before_each() -> void:
	_registry = DataRegistryScript.new()
	_registry.report_errors = false
	_registry.load_all(DataRegistryScript.DATA_ROOT, DataRegistryScript.CONFIG_PATH)
	_game = GameManagerScript.new()
	_game.rng.seed = 21
	_game.build(_registry)
	_game.start_new_game()
	_talents = _game.talents
	_hunter = _game.hunters.get_all()[0]


func after_each() -> void:
	_game.hunters.clear_modifier_sources()
	_game.bonds.set_party_provider(func() -> Array: return [])
	_game.free()
	_registry.free()


func test_four_classes_match_balance() -> void:
	# id: [hp, atk, def, attack speed, move, crit, range, recruit cost, starting weapon]
	var expected := {
		&"warrior": [120.0, 14.0, 6.0, 1.0, 80.0, 0.05, 20.0, 100, &"rusty_sword"],
		&"ranger": [90.0, 12.0, 3.0, 1.1, 85.0, 0.1, 110.0, 120, &"short_bow"],
		&"rogue": [100.0, 13.0, 4.0, 1.4, 95.0, 0.2, 18.0, 110, &"rusty_dagger"],
		&"guardian": [160.0, 10.0, 9.0, 0.8, 70.0, 0.0, 22.0, 130, &"rusty_sword"],
	}
	assert_eq(_registry.get_count(&"hunter"), 12, "4 base classes + 8 subclasses")
	for class_id: StringName in expected:
		var d := _registry.find_def(&"hunter", class_id) as HunterDefinition
		var values: Array = expected[class_id]
		assert_eq([d.base_hp, d.base_attack, d.base_defense, d.attack_speed, d.move_speed, d.critical_chance,
			d.attack_range, d.recruit_cost, d.starting_items[0]], values, String(class_id))
		assert_true(d.name_pool.size() >= 20, "%s names" % class_id)


func test_tavern_offers_every_class() -> void:
	var seen := {}
	for i in 40:
		_game.recruitment.refresh_candidates()
		for candidate in _game.recruitment.candidates:
			seen[candidate.definition_id] = true
	assert_eq(seen.size(), 4)


func test_talent_roll_follows_weights() -> void:
	var counts := {&"": 0, &"cook": 0, &"herbalist": 0}
	var probe := HunterRuntime.new()
	for i in 2000:
		_talents.assign_random_talent(probe)
		counts[probe.talent_id] += 1
	assert_true(absf(counts[&"cook"] / 2000.0 - 0.35) < 0.05, str(counts))
	assert_true(absf(counts[&""] / 2000.0 - 0.3) < 0.05, str(counts))


func test_cook_makes_food_from_the_bag() -> void:
	_hunter.talent_id = &"cook"
	assert_null(_talents.pick_recipe(_hunter, TalentService.Kind.FOOD), "empty bag")
	_game.regions.add_to_bag(_hunter, &"raw_meat", 2)
	var recipe := _talents.pick_recipe(_hunter, TalentService.Kind.FOOD)
	assert_eq(recipe.id, &"meat_stew")
	assert_almost_eq(recipe.field_seconds, 8.0)
	assert_null(_talents.pick_recipe(_hunter, TalentService.Kind.MEDICINE), "a Cook brews nothing")
	assert_true(_talents.make_from_bag(_hunter, recipe))
	assert_eq(_hunter.loot_bag, {&"meat_stew": 3} as Dictionary[StringName, int])
	_hunter.energy = 10.0
	assert_true(_game.needs.eat(_hunter), "eats from the bag first")
	assert_almost_eq(_hunter.energy, 70.0)
	assert_eq(_hunter.purse, 20, "free")
	assert_eq(_hunter.loot_bag[&"meat_stew"], 2)


func test_herbalist_heals_from_the_bag() -> void:
	_hunter.talent_id = &"herbalist"
	_game.regions.add_to_bag(_hunter, &"slime_gel", 2)
	_game.regions.add_to_bag(_hunter, &"wild_herb", 1)
	_game.regions.add_to_bag(_hunter, &"bone_dust", 1)
	var recipe := _talents.pick_recipe(_hunter, TalentService.Kind.MEDICINE)
	assert_eq(recipe.id, &"healing_potion", "the stronger medicine first, no Hospital level needed")
	_talents.make_from_bag(_hunter, recipe)
	var max_hp: float = _game.hunters.get_stat(_hunter, HunterService.MAX_HP)
	_hunter.current_hp = max_hp * 0.2
	var healed := _talents.use_medicine_from_bag(_hunter)
	assert_almost_eq(healed, max_hp * 0.7, 0.01)
	assert_eq(_talents.pick_recipe(_hunter, TalentService.Kind.MEDICINE).id, &"bandage")


func test_no_talent_crafts_nothing() -> void:
	_hunter.talent_id = &""
	_game.regions.add_to_bag(_hunter, &"raw_meat", 4)
	assert_null(_talents.pick_recipe(_hunter, TalentService.Kind.FOOD))


func test_talent_is_saved() -> void:
	_hunter.talent_id = &"cook"
	var copy := HunterRuntime.from_dict(_hunter.to_dict())
	assert_eq(copy.talent_id, &"cook")


func test_every_class_has_thirty_active_skills_and_monsters_two() -> void:
	for owner_class in [&"warrior", &"ranger", &"rogue", &"guardian"]:
		var skills := ActiveSkills.for_class(_registry, owner_class)
		assert_eq(skills.size(), 30, "%s skills" % owner_class)
		var last_level := 0
		for skill in skills:
			assert_true(skill.required_level >= last_level, "%s sorted by level" % skill.id)
			last_level = skill.required_level
			assert_true(ChibiAnimations.has_animation(skill.animation), "%s animation" % skill.id)
			assert_true(skill.cooldown > 0.0 and skill.targets >= 1, String(skill.id))
			assert_true(skill.damage > 0.0 or skill.self_effect_id != &"" or skill.heal_ratio > 0.0 or skill.effect_id != &"", "%s does something" % skill.id)
			for effect_id in [skill.effect_id, skill.self_effect_id]:
				if effect_id != &"":
					assert_not_null(_registry.find_def(&"status_effect", effect_id), "%s effect %s" % [skill.id, effect_id])
	for definition in _registry.get_all(&"enemy"):
		var enemy := definition as EnemyDefinition
		assert_eq(enemy.skill_ids.size(), 2, "%s has two skills" % enemy.id)
		for skill_id in enemy.skill_ids:
			var skill := ActiveSkills.get_skill(_registry, skill_id)
			assert_not_null(skill, String(skill_id))
			assert_eq(skill.owner_class, &"monster", String(skill_id))
		for item_id in [enemy.weapon_id, enemy.armor_id]:
			if item_id != &"":
				assert_not_null(_registry.find_def(&"item", item_id), "%s gear %s" % [enemy.id, item_id])


func test_loadout_picks_highest_unlocked_and_respects_choices() -> void:
	var hunter := HunterRuntime.new()
	hunter.definition_id = &"warrior"
	var warrior := _registry.find_def(&"hunter", &"warrior") as HunterDefinition
	hunter.level = 1
	var picks := ActiveSkills.loadout(_registry, hunter, warrior)
	assert_eq(picks.size(), 1, "one skill at level 1")
	assert_eq(picks[0].id, &"power_slam")
	hunter.level = 5
	picks = ActiveSkills.loadout(_registry, hunter, warrior)
	assert_eq(picks.size(), 2)
	assert_eq(picks[0].required_level, 5, "highest unlocked first")
	assert_eq(picks[1].required_level, 4)
	assert_eq(ActiveSkills.set_slot(_registry, hunter, warrior, 0, &"cleave"), "")
	assert_eq(ActiveSkills.loadout(_registry, hunter, warrior)[0].id, &"cleave")
	assert_false(ActiveSkills.set_slot(_registry, hunter, warrior, 0, &"executioner").is_empty(), "locked")
	assert_false(ActiveSkills.set_slot(_registry, hunter, warrior, 0, &"arrow_volley").is_empty(), "other class")
	# A subclass uses its base class's skills; choices survive the save round trip.
	var templar := _registry.find_def(&"hunter", &"templar") as HunterDefinition
	hunter.active_skills.clear()
	assert_eq(ActiveSkills.loadout(_registry, hunter, templar)[1].owner_class, &"guardian")
	hunter.active_skills.assign([&"cleave"])
	assert_eq(HunterRuntime.from_dict(hunter.to_dict()).active_skills, [&"cleave"] as Array[StringName])
