extends TestCase
## Validates the real content in res://data against BALANCE.md.

const DataRegistryScript := preload("res://core/data_registry.gd")

var _registry: Node


func before_each() -> void:
	_registry = DataRegistryScript.new()
	_registry.report_errors = false
	_registry.load_all(DataRegistryScript.DATA_ROOT, DataRegistryScript.CONFIG_PATH)


func after_each() -> void:
	_registry.free()


func test_real_data_loads_without_errors() -> void:
	assert_eq(_registry.load_errors.size(), 0, ", ".join(_registry.load_errors))


func test_config_matches_balance() -> void:
	var config: GameConfig = _registry.config
	assert_almost_eq(config.defense_factor, 0.5)
	assert_almost_eq(config.base_xp, 30.0)
	assert_almost_eq(config.xp_exponent, 2.2)
	assert_eq(config.level_cap_per_town_level, 10)
	assert_eq(config.max_party_size, 3)
	assert_almost_eq(config.offline_cap_hours, 8.0)
	assert_almost_eq(config.mood_start, 60.0)


func test_warrior_matches_balance() -> void:
	var warrior := _registry.find_def(&"hunter", &"warrior") as HunterDefinition
	assert_not_null(warrior)
	assert_almost_eq(warrior.base_hp, 120.0)
	assert_almost_eq(warrior.base_attack, 14.0)
	assert_almost_eq(warrior.base_defense, 6.0)
	assert_eq(warrior.recruit_cost, 100)


func test_phase4_enemies_match_balance() -> void:
	# [hp, attack, defense, attack_speed, move_speed, xp, gold_min, gold_max, range]
	var expected := {
		&"goblin": [50.0, 10.0, 3.0, 1.0, 70.0, 10, 4, 8, 20.0],
		&"wolf": [40.0, 12.0, 1.0, 1.4, 120.0, 12, 3, 6, 20.0],
		&"forest_guardian": [900.0, 28.0, 10.0, 0.5, 40.0, 150, 150, 150, 30.0],
	}
	for enemy_id: StringName in expected:
		var values: Array = expected[enemy_id]
		var enemy := _registry.find_def(&"enemy", enemy_id) as EnemyDefinition
		assert_not_null(enemy, String(enemy_id))
		var actual := [enemy.hp, enemy.attack, enemy.defense, enemy.attack_speed, enemy.move_speed,
				enemy.xp_reward, enemy.gold_min, enemy.gold_max, enemy.attack_range]
		assert_eq(actual, values, String(enemy_id))
		var actor := enemy.actor_scene.instantiate()
		assert_true(actor is Enemy, "%s scene root is Enemy" % enemy_id)
		actor.free()
	var boss := _registry.find_def(&"enemy", &"forest_guardian") as EnemyDefinition
	assert_true(boss.is_boss)
	assert_almost_eq(boss.hit_radius, 14.0)


func test_dark_forest_matches_balance() -> void:
	var forest := _registry.find_def(&"expedition", &"dark_forest") as ExpeditionDefinition
	assert_not_null(forest)
	assert_eq(forest.recommended_level, 4)
	assert_eq(forest.completion_bonus_gold, 50)
	assert_eq(forest.boss_id, &"forest_guardian")
	assert_eq(forest.first_clear_flags, [&"first_boss_clear"] as Array[StringName])
	var groups: Array = []
	for group in forest.enemy_groups:
		var spawns: Array = []
		for spawn in group.spawns:
			spawns.append([String(spawn.enemy_id), spawn.count])
		groups.append(spawns)
	assert_eq(groups, [
		[["slime", 3]],
		[["slime", 2], ["goblin", 2]],
		[["goblin", 3], ["wolf", 1]],
		[["goblin", 2], ["wolf", 2]],
	])
	assert_not_null(forest.scene)
	# Every enemy id used exists.
	for group in forest.enemy_groups:
		for spawn in group.spawns:
			assert_true(_registry.has_def(&"enemy", spawn.enemy_id), String(spawn.enemy_id))
	# Scene has one Sections marker per group.
	var scene := forest.scene.instantiate()
	assert_eq(scene.get_node("Markers/Sections").get_child_count(), forest.enemy_groups.size())
	scene.free()


func test_buildings_match_balance() -> void:
	# id: [[lv2 gold, {material: qty}, flags], lv1 effects, lv2 effects]
	var expected := {
		&"town_hall": [500, {&"iron_ore": 10}, [&"first_boss_clear"], {&"hunter_capacity": 3.0}, {&"hunter_capacity": 5.0}],
		&"tavern": [300, {}, [], {&"candidate_count": 3.0, &"refresh_cost": 30.0}, {&"candidate_count": 4.0, &"refresh_cost": 30.0}],
		&"blacksmith": [300, {&"iron_ore": 5}, [], {&"recipe_level": 1.0}, {&"recipe_level": 2.0}],
		&"hospital": [300, {}, [], {}, {}],
		&"temple": [300, {&"dark_essence": 2}, [], {&"recovery_seconds": 180.0, &"speedup_gold_per_minute": 20.0}, {&"recovery_seconds": 120.0, &"speedup_gold_per_minute": 20.0}],
		&"warehouse": [250, {&"iron_ore": 5}, [], {&"inventory_slots": 40.0}, {&"inventory_slots": 80.0}],
	}
	for building_id: StringName in expected:
		var values: Array = expected[building_id]
		var building := _registry.find_def(&"building", building_id) as BuildingDefinition
		assert_not_null(building, String(building_id))
		assert_eq(building.get_max_level(), 5 if building_id == &"town_hall" else 2, String(building_id))
		var lv1 := building.get_level(1)
		var lv2 := building.get_level(2)
		assert_eq(lv1.gold_cost, 0, String(building_id))
		assert_eq(lv2.gold_cost, values[0], String(building_id))
		var materials := {}
		for cost in lv2.material_costs:
			materials[cost.item_id] = cost.quantity
		assert_eq(materials, values[1], String(building_id))
		assert_eq(Array(lv2.required_flags), values[2], String(building_id))
		assert_eq(Dictionary(lv1.effects), values[3], String(building_id))
		assert_eq(Dictionary(lv2.effects), values[4], String(building_id))


func test_recipes_match_balance() -> void:
	# id: [gold, {material: qty}, blacksmith level]
	var expected := {
		&"iron_sword": [50, {&"iron_ore": 5}, 1],
		&"iron_armor": [60, {&"iron_ore": 6}, 1],
		&"fang_blade": [150, {&"beast_fang": 8, &"dark_essence": 1}, 2],
	}
	for recipe_id: StringName in expected:
		var recipe := _registry.find_def(&"recipe", recipe_id) as RecipeDefinition
		assert_not_null(recipe, String(recipe_id))
		assert_eq(recipe.result_item_id, recipe_id)
		var materials := {}
		for cost in recipe.material_costs:
			materials[cost.item_id] = cost.quantity
		assert_eq([recipe.gold_cost, materials, recipe.required_level], expected[recipe_id], String(recipe_id))
	var warrior := _registry.find_def(&"hunter", &"warrior") as HunterDefinition
	assert_eq(warrior.starting_items, [&"rusty_sword", &"leather_armor"] as Array[StringName])


func test_items_match_balance() -> void:
	# id: [sell_price, rarity, stackable, slot, {stat: value}]
	var expected := {
		&"iron_ore": [3, ItemDefinition.Rarity.COMMON, true, ItemDefinition.EquipmentSlot.NONE, {}],
		&"beast_fang": [4, ItemDefinition.Rarity.COMMON, true, ItemDefinition.EquipmentSlot.NONE, {}],
		&"dark_essence": [25, ItemDefinition.Rarity.RARE, true, ItemDefinition.EquipmentSlot.NONE, {}],
		&"rusty_sword": [5, ItemDefinition.Rarity.COMMON, false, ItemDefinition.EquipmentSlot.WEAPON, {&"attack": 3.0}],
		&"leather_armor": [5, ItemDefinition.Rarity.COMMON, false, ItemDefinition.EquipmentSlot.ARMOR, {&"defense": 3.0, &"max_hp": 10.0}],
		&"iron_sword": [20, ItemDefinition.Rarity.UNCOMMON, false, ItemDefinition.EquipmentSlot.WEAPON, {&"attack": 7.0}],
		&"iron_armor": [25, ItemDefinition.Rarity.UNCOMMON, false, ItemDefinition.EquipmentSlot.ARMOR, {&"defense": 6.0, &"max_hp": 20.0}],
		&"fang_blade": [60, ItemDefinition.Rarity.RARE, false, ItemDefinition.EquipmentSlot.WEAPON, {&"attack": 10.0, &"critical_chance": 0.05}],
	}
	for item_id: StringName in expected:
		var values: Array = expected[item_id]
		var item := _registry.find_def(&"item", item_id) as ItemDefinition
		assert_not_null(item, String(item_id))
		assert_eq([item.sell_price, item.rarity, item.stackable, item.equipment_slot], values.slice(0, 4), String(item_id))
		if item.stackable:
			assert_eq(item.max_stack, 99, String(item_id))
		var mods := {}
		for modifier in item.modifiers:
			assert_eq(modifier.type, StatModifier.Type.FLAT, String(item_id))
			mods[modifier.stat] = modifier.value
		assert_eq(mods, values[4], String(item_id))


func test_loot_tables_reference_real_items() -> void:
	assert_eq(_registry.get_count(&"loot_table"), 6)
	for table: LootTableDefinition in _registry.get_all(&"loot_table"):
		for entry in table.entries:
			assert_true(_registry.has_def(&"item", entry.item_id), "%s → %s" % [table.id, entry.item_id])
	for enemy: EnemyDefinition in _registry.get_all(&"enemy"):
		if enemy.loot_table_id != &"":
			assert_true(_registry.has_def(&"loot_table", enemy.loot_table_id), String(enemy.id))
	var forest := _registry.find_def(&"expedition", &"dark_forest") as ExpeditionDefinition
	assert_true(_registry.has_def(&"loot_table", forest.first_clear_loot_table_id))
	assert_true(_registry.has_def(&"loot_table", forest.repeat_clear_loot_table_id))


func test_slime_matches_balance() -> void:
	var slime := _registry.find_def(&"enemy", &"slime") as EnemyDefinition
	assert_not_null(slime)
	assert_almost_eq(slime.hp, 30.0)
	assert_almost_eq(slime.attack, 6.0)
	assert_almost_eq(slime.defense, 1.0)
	assert_almost_eq(slime.attack_speed, 0.7)
	assert_almost_eq(slime.move_speed, 40.0)
	assert_eq(slime.xp_reward, 5)
	assert_eq([slime.gold_min, slime.gold_max], [2, 4])
	assert_not_null(slime.actor_scene)
	var actor := slime.actor_scene.instantiate()
	assert_true(actor is Enemy, "actor scene root is Enemy")
	actor.free()
