extends TestCase
## Monster loadouts: 10 skills per type (2 per monster), gear for goblins and skeletons only,
## loot on the ground, meat, passive/active skill effects.

var _game: Node
var _nodes: Array[Node] = []


func before_each() -> void:
	_game = (Engine.get_main_loop() as SceneTree).root.get_node("GameManager")


func after_each() -> void:
	for node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()


func _enemy(enemy_id: StringName, level: int = 3, tier: int = Tier.Level.C) -> Enemy:
	var definition := DataRegistry.get_enemy(enemy_id)
	var enemy := definition.actor_scene.instantiate() as Enemy
	(Engine.get_main_loop() as SceneTree).root.add_child(enemy)
	_nodes.append(enemy)
	enemy.setup(definition, _game.combat, 0.5, level, 1.0, tier)
	return enemy


func test_every_monster_type_has_ten_skills() -> void:
	for enemy_id in [&"slime", &"wolf", &"goblin", &"skeleton"]:
		var pool: Array[MonsterSkillDefinition] = _game.regions.get_monster_skills(enemy_id)
		assert_eq(pool.size(), 10, "%s skills" % enemy_id)
		var passives := pool.filter(func(skill: MonsterSkillDefinition) -> bool: return not skill.is_active())
		assert_true(passives.size() >= 1 and passives.size() < 10, "%s mixes passive and active" % enemy_id)


func test_each_monster_rolls_two_distinct_skills_of_its_type() -> void:
	for enemy_id in [&"slime", &"wolf", &"goblin", &"skeleton"]:
		var definition := DataRegistry.get_enemy(enemy_id)
		var seen: Dictionary = {}
		for i in 30:
			var skills: Array[StringName] = _game.regions.roll_skills(definition)
			assert_eq(skills.size(), 2)
			assert_true(skills[0] != skills[1])
			for skill_id in skills:
				assert_eq((DataRegistry.find_def(&"monster_skill", skill_id) as MonsterSkillDefinition).enemy_id, enemy_id)
				seen[skill_id] = true
		assert_true(seen.size() > 4, "%s varies" % enemy_id)


func test_only_goblins_and_skeletons_carry_gear() -> void:
	for enemy_id in [&"slime", &"wolf"]:
		var definition := DataRegistry.get_enemy(enemy_id)
		for i in 40:
			assert_eq(_game.regions.roll_loadout(definition, 3, Tier.Level.C).get_gear().size(), 0, "%s has no gear" % enemy_id)
	for enemy_id in [&"goblin", &"skeleton"]:
		var definition := DataRegistry.get_enemy(enemy_id)
		var worn := 0
		for i in 40:
			var loadout: MonsterLoadout = _game.regions.roll_loadout(definition, 3, Tier.Level.C)
			worn += loadout.get_gear().size()
			assert_true(loadout.gold > 0)
			if loadout.weapon != &"":
				assert_true(definition.weapon_pool.has(loadout.weapon))
		assert_true(worn > 10, "%s wears gear" % enemy_id)


func test_gear_raises_a_monsters_stats() -> void:
	var enemy := _enemy(&"goblin")
	var base_attack := enemy.get_combat_stats().attack
	var loadout := MonsterLoadout.new()
	loadout.weapon = &"iron_sword"
	loadout.armor = &"iron_armor"
	enemy.apply_loadout(loadout)
	assert_true(enemy.get_combat_stats().attack > base_attack)
	assert_true(enemy.health.max_health > DataRegistry.get_enemy(&"goblin").hp, "armor adds HP")


func test_passive_skill_changes_stats() -> void:
	var enemy := _enemy(&"slime")
	var hp := enemy.health.max_health
	var loadout := MonsterLoadout.new()
	loadout.skills = [&"slime_swollen"] as Array[StringName]
	enemy.apply_loadout(loadout)
	assert_almost_eq(enemy.health.max_health, hp * 1.3, 0.01)


func test_active_skill_heals_and_buffs_the_caster() -> void:
	var enemy := _enemy(&"slime")
	var loadout := MonsterLoadout.new()
	loadout.skills = [&"slime_regrow"] as Array[StringName]
	enemy.apply_loadout(loadout)
	enemy.health.take_damage(enemy.health.max_health * 0.5)
	var before := enemy.health.current_health
	var caster := enemy.get_node("MonsterSkillCaster") as MonsterSkillCaster
	var skill := DataRegistry.find_def(&"monster_skill", &"slime_regrow") as MonsterSkillDefinition
	assert_true(caster.try_cast(skill, enemy))
	assert_true(enemy.health.current_health > before)
	assert_true(enemy.effects.has_effect(&"regeneration"))
	assert_true(caster.get_cooldown(skill.id) > 0.0)


func test_kill_leaves_loot_on_the_ground_for_hunters() -> void:
	var killer: HunterRuntime = _game.hunters.create_hunter(&"warrior", _game.rng)
	var definition := DataRegistry.get_enemy(&"goblin")
	var loadout := MonsterLoadout.new()
	loadout.gold = 25
	loadout.weapon = &"iron_sword"
	loadout.resources = {&"iron_ore": 2} as Dictionary[StringName, int]
	loadout.meat = 2
	var purse: int = killer.purse
	var xp: int = killer.xp
	var reward: KillReward = _game.regions.record_kill(killer, [] as Array[HunterRuntime], definition, 3, Tier.Level.UR, loadout)
	assert_true(reward.on_ground)
	assert_eq(killer.purse, purse, "gold is not handed over")
	assert_true(killer.loot_bag.is_empty(), "nothing goes into the bag yet")
	assert_true(killer.xp > xp or killer.level > 1, "XP is immediate")
	assert_eq(reward.items.get(&"iron_ore", 0), 2)
	assert_eq(reward.items.get(&"monster_meat", 0), 2)
	# Picking it up.
	var left: Dictionary[StringName, int] = _game.regions.collect_drop(killer, reward.gold, reward.items)
	assert_true(left.is_empty())
	assert_eq(killer.purse, purse + reward.gold)
	assert_eq(killer.loot_bag.get(&"iron_ore", 0), 2)
	assert_eq(killer.loot_bag.get(&"monster_meat", 0), 2)


func test_full_bag_leaves_items_on_the_ground() -> void:
	var hunter: HunterRuntime = _game.hunters.create_hunter(&"warrior", _game.rng)
	var items: Dictionary[StringName, int] = {&"iron_ore": 50}
	var left: Dictionary[StringName, int] = _game.regions.collect_drop(hunter, 10, items)
	assert_eq(_game.regions.get_bag_count(hunter), DataRegistry.config.loot_bag_capacity)
	assert_eq(left.get(&"iron_ore", 0), 50 - DataRegistry.config.loot_bag_capacity)


func test_meat_can_be_cooked() -> void:
	assert_not_null(DataRegistry.find_def(&"recipe", &"monster_steak"))
	assert_true(DataRegistry.get_item(&"monster_steak").energy > 0.0)


func test_bosses_carry_gear_and_three_of_ten_skills() -> void:
	for boss_id in [&"forest_guardian", &"weekly_boss"]:
		var definition := DataRegistry.get_enemy(boss_id)
		assert_eq(_game.regions.get_monster_skills(boss_id).size(), 10, "%s skills" % boss_id)
		var loadout: MonsterLoadout = _game.regions.roll_loadout(definition, 1, definition.tier)
		assert_eq(loadout.skills.size(), 3)
		assert_eq(loadout.get_gear().size(), 3, "bosses are fully equipped")


func test_monster_dialog_slots_open_item_details() -> void:
	var enemy := _enemy(&"skeleton")
	var loadout := MonsterLoadout.new()
	loadout.weapon = &"iron_sword"
	enemy.apply_loadout(loadout)
	var dialog := MonsterDialog.new(enemy)
	(Engine.get_main_loop() as SceneTree).root.add_child(dialog)
	_nodes.append(dialog)
	var icons: Array = []
	_collect_icons(dialog, icons)
	assert_true(icons.size() >= 1, "worn weapon has a tappable icon")


func _collect_icons(node: Node, out: Array) -> void:
	if node is ItemIcon:
		out.append(node)
	for child in node.get_children():
		_collect_icons(child, out)


func test_dungeon_kill_drops_the_loadout_into_the_stash() -> void:
	var hunter: HunterRuntime = _game.hunters.create_hunter(&"warrior", _game.rng)
	var run: ExpeditionRun = _game.expeditions.start(&"dark_forest", [hunter.unique_id] as Array[StringName])
	assert_not_null(run, "expedition started")
	if run == null:
		return
	var definition := DataRegistry.get_enemy(&"goblin")
	var loadout := MonsterLoadout.new()
	loadout.gold = 40
	loadout.resources = {&"iron_ore": 3} as Dictionary[StringName, int]
	loadout.meat = 2
	var reward: KillReward = _game.expeditions.record_kill(definition, loadout, Tier.Level.C)
	assert_eq(reward.gold, roundi(40 * _game.expeditions._party_gold_multiplier()))
	assert_eq(reward.items.get(&"iron_ore", 0), 3)
	assert_eq(reward.items.get(&"monster_meat", 0), 2)
	assert_eq(run.stash_items.get(&"iron_ore", 0), 3)
	_game.expeditions.current_run = null
