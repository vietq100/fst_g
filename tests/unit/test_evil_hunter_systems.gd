extends TestCase
## Town Hall unlocks, Trading Post, Academy, Forge and Reincarnation (REFERENCE_EVIL_HUNTER_TYCOON.md).

const DataRegistryScript := preload("res://core/data_registry.gd")
const GameManagerScript := preload("res://core/game_manager.gd")

var _registry: Node
var _game: Node


func before_each() -> void:
	_registry = DataRegistryScript.new()
	_registry.report_errors = false
	_registry.load_all(DataRegistryScript.DATA_ROOT, DataRegistryScript.CONFIG_PATH)
	_game = GameManagerScript.new()
	_game.rng.seed = 3
	_game.build(_registry)
	_game.start_new_game()
	_game.wallet.add(100000)


func after_each() -> void:
	_game.hunters.clear_modifier_sources()
	_game.bonds.set_party_provider(func() -> Array: return [])
	_game.free()
	_registry.free()


func _unlock(town_level: int) -> void:
	_game.progress.set_flag(&"first_boss_clear")
	_game.inventory.capacity = 500
	for ore in [&"iron_ore", &"beast_fang", &"dark_essence", &"bone_dust"]:
		_game.inventory.add_item(ore, 200)
	while _game.buildings.get_level(&"town_hall") < town_level:
		assert_true(_game.buildings.upgrade(&"town_hall"))


func _build(building_id: StringName) -> void:
	for gx in range(2, 30):
		for gy in range(2, 30):
			if _game.buildings.can_place(building_id, Vector2i(gx, gy)).is_empty():
				assert_not_null(_game.buildings.build(building_id, Vector2i(gx, gy)), String(building_id))
				return
	assert_true(false, "no room for %s" % building_id)


func test_town_hall_gates_new_buildings() -> void:
	assert_eq(_game.buildings.can_build(&"trading_post"), "Requires Town Hall Lv 2")
	assert_eq(_game.buildings.can_build(&"academy"), "Requires Town Hall Lv 3")
	_unlock(3)
	for building_id in [&"trading_post", &"inn", &"academy", &"forge", &"portal"]:
		assert_eq(_game.buildings.can_build(building_id), "", String(building_id))
	assert_eq(_game.stats.level_cap(_game.progress.town_level), 30)


func test_inn_adds_beds() -> void:
	_unlock(2)
	var before: int = _game.housing.get_total_beds()
	_build(&"inn")
	assert_eq(_game.housing.get_total_beds(), before + 6)


func test_trading_post_bounty_and_completion() -> void:
	_unlock(2)
	assert_false(_game.trading.can_order(&"iron_ore", 3).is_empty(), "needs a Trading Post")
	_build(&"trading_post")
	assert_true(_game.trading.order(&"iron_ore", 3))
	assert_eq(_game.trading.can_order(&"iron_ore", 3), "Already requested")
	var hunter: HunterRuntime = _game.hunters.get_all()[0]
	var purse_before := hunter.purse
	var completed: Array = []
	_game.trading.request_completed.connect(func(item_id: StringName, quantity: int) -> void: completed.append([item_id, quantity]))
	hunter.loot_bag[&"iron_ore"] = 2
	_game.regions.deposit(hunter)
	assert_eq(_game.trading.requests.size(), 1)
	assert_eq(_game.trading.requests[0]["delivered"], 2)
	hunter.loot_bag[&"iron_ore"] = 5
	_game.regions.deposit(hunter)
	assert_eq(_game.trading.requests.size(), 0, "request completed")
	assert_eq(completed.size(), 1)
	assert_true(hunter.purse > purse_before)


func test_trading_post_slot_limit() -> void:
	_unlock(2)
	_build(&"trading_post")
	assert_true(_game.trading.order(&"iron_ore", 1))
	assert_true(_game.trading.order(&"beast_fang", 1))
	assert_eq(_game.trading.can_order(&"dark_essence", 1), "All request slots are used (2)")


func test_academy_skills_cost_gold_and_add_stats() -> void:
	_unlock(3)
	var hunter: HunterRuntime = _game.hunters.get_all()[0]
	assert_eq(_game.academy.can_learn_skill(hunter, &"power_strike"), "Needs an Academy")
	_build(&"academy")
	var attack: float = _game.hunters.get_stat(hunter, HunterService.ATTACK)
	var gold: int = _game.wallet.gold
	assert_true(_game.academy.learn_skill(hunter, &"power_strike"))
	assert_eq(_game.wallet.gold, gold - 120)
	assert_almost_eq(_game.hunters.get_stat(hunter, HunterService.ATTACK), attack + 2.0)
	assert_true(_game.academy.learn_skill(hunter, &"power_strike"))
	assert_eq(_game.wallet.gold, gold - 120 - 240, "next level costs more")
	assert_almost_eq(_game.hunters.get_stat(hunter, HunterService.ATTACK), attack + 4.0)
	assert_eq(_game.academy.can_learn_skill(hunter, &"keen_eye"), "Needs Academy Lv 2")


func test_academy_traits_use_rebirth_points() -> void:
	_unlock(3)
	_build(&"academy")
	var hunter: HunterRuntime = _game.hunters.get_all()[0]
	hunter.trait_ids.clear()
	assert_eq(_game.academy.can_learn_trait(hunter, &"sturdy"), "Needs 1 rebirth point(s)")
	hunter.rebirth_points = 3
	assert_true(_game.academy.learn_trait(hunter, &"sturdy"))
	assert_eq(hunter.rebirth_points, 2)
	assert_true(hunter.trait_ids.has(&"sturdy"))
	assert_eq(_game.academy.can_learn_trait(hunter, &"coward"), "Cannot be learned")
	assert_true(_game.academy.forget_trait(hunter, &"sturdy"))
	assert_false(hunter.trait_ids.has(&"sturdy"))


func test_forge_enhances_equipment_up_to_its_level() -> void:
	_unlock(3)
	var hunter: HunterRuntime = _game.hunters.get_all()[0]
	var instance_id: StringName = hunter.equipment[&"weapon"]
	assert_eq(_game.forge.can_enhance(instance_id), "Needs an Enhancement Forge")
	_build(&"forge")
	var attack: float = _game.hunters.get_stat(hunter, HunterService.ATTACK)
	assert_true(_game.forge.enhance(instance_id))
	assert_eq(_game.forge.get_level(instance_id), 1)
	assert_true(_game.hunters.get_stat(hunter, HunterService.ATTACK) > attack)
	assert_true(_game.forge.enhance(instance_id))
	assert_true(_game.forge.enhance(instance_id))
	assert_true(_game.forge.can_enhance(instance_id).begins_with("Forge limit"))


func test_reincarnation_resets_level_and_unlocks_difficulty() -> void:
	_unlock(3)
	var hunter: HunterRuntime = _game.hunters.get_all()[0]
	_game.hunters.set_level(hunter, 20)
	assert_eq(_game.reincarnation.can_reincarnate(hunter), "Needs a Reincarnation Portal")
	_build(&"portal")
	var attack: float = _game.hunters.get_stat(hunter, HunterService.ATTACK)
	assert_true(_game.reincarnation.reincarnate(hunter))
	assert_eq(hunter.level, 1)
	assert_eq(hunter.reincarnations, 1)
	assert_eq(hunter.rebirth_points, 1)
	assert_eq(_game.progress.total_reincarnations, 1)
	assert_false(_game.reincarnation.can_reincarnate(hunter).is_empty(), "level is 1 again")
	assert_true(_game.hunters.get_stat(hunter, HunterService.ATTACK) > 0.0)
	assert_true(attack > 0.0)
	assert_eq(_game.reincarnation.set_difficulty(1), "", "one rebirth unlocks Normal")
	assert_false(_game.reincarnation.set_difficulty(2).is_empty(), "Hard is still locked")
	assert_eq(_game.progress.difficulty, 1)
	assert_almost_eq(_game.regions.get_stat_scale(1), 1.4)


func test_new_systems_survive_save_round_trip() -> void:
	_unlock(3)
	_build(&"trading_post")
	_build(&"academy")
	_build(&"forge")
	var hunter: HunterRuntime = _game.hunters.get_all()[0]
	_game.trading.order(&"iron_ore", 4)
	_game.academy.learn_skill(hunter, &"vitality")
	hunter.reincarnations = 2
	hunter.rebirth_points = 3
	_game.progress.total_reincarnations = 2
	_game.progress.difficulty = 1
	var instance_id: StringName = hunter.equipment[&"weapon"]
	_game.forge.enhance(instance_id)
	var data: Dictionary = SaveCodec.capture(_game)
	var other: Node = GameManagerScript.new()
	other.build(_registry)
	other.start_new_game()
	var warnings := PackedStringArray()
	SaveCodec.restore(other, JSON.parse_string(JSON.stringify(data)), warnings)
	var copy: HunterRuntime = other.hunters.get_all()[0]
	assert_eq(copy.skills.get(&"vitality", 0), 1)
	assert_eq(copy.reincarnations, 2)
	assert_eq(copy.rebirth_points, 3)
	assert_eq(other.progress.difficulty, 1)
	assert_eq(other.progress.total_reincarnations, 2)
	assert_eq(other.trading.requests.size(), 1)
	assert_eq(other.forge.get_level(copy.equipment[&"weapon"]), 1)
	assert_true(other.buildings.has_building(&"forge"))
	other.hunters.clear_modifier_sources()
	other.bonds.set_party_provider(func() -> Array: return [])
	other.free()


func test_quests_complete_and_pay_rewards() -> void:
	var first: QuestDefinition = _game.quests.get_active()[0]
	assert_eq(first.id, &"hire_two")
	assert_false(_game.quests.is_complete(first))
	assert_eq(_game.quests.can_claim(first), "Not finished yet")
	var completed: Array = []
	_game.quests.quest_completed.connect(func(quest: QuestDefinition) -> void: completed.append(quest.id))
	_game.recruitment.recruit(0)
	assert_true(_game.quests.is_complete(first))
	assert_eq(completed, [&"hire_two"])
	assert_eq(_game.quests.get_claimable_count(), 1)
	var gold: int = _game.wallet.gold
	assert_true(_game.quests.claim(first))
	assert_eq(_game.wallet.gold, gold + first.reward_gold)
	assert_false(_game.quests.claim(first), "only once")
	assert_eq(_game.quests.get_claimed_count(), 1)
	assert_false(_game.quests.get_active().any(func(q: QuestDefinition) -> bool: return q.id == &"hire_two"))
	var data: Dictionary = _game.quests.to_dict()
	_game.quests.from_dict(JSON.parse_string(JSON.stringify(data)))
	assert_true(_game.quests.is_claimed(&"hire_two"))


func test_subclasses_are_not_recruited_and_academy_promotes() -> void:
	for i in 40:
		_game.recruitment.refresh_candidates()
		for candidate: HunterRuntime in _game.recruitment.candidates:
			assert_eq((_registry.find_def(&"hunter", candidate.definition_id) as HunterDefinition).promotion_of, &"")
	_unlock(3)
	_build(&"academy")
	var hunter: HunterRuntime = _game.hunters.get_all()[0]
	var options: Array[HunterDefinition] = _game.academy.get_promotions(hunter)
	assert_eq(options.size(), 2)
	assert_eq(_game.academy.can_change_class(hunter, options[0].id), "Needs 2 reincarnations")
	hunter.reincarnations = 2
	var gold: int = _game.wallet.gold
	assert_true(_game.academy.change_class(hunter, options[0].id))
	assert_eq(hunter.definition_id, options[0].id)
	assert_eq(_game.wallet.gold, gold - AcademyService.PROMOTION_COST)
	assert_eq(_game.academy.get_promotions(hunter).size(), 0, "no further promotion")


func test_restaurant_boosts_meals() -> void:
	_unlock(2)
	assert_almost_eq(_game.supply.get_food_bonus(), 0.0)
	_build(&"restaurant")
	assert_almost_eq(_game.supply.get_food_bonus(), 0.25)


func test_auto_duty_follows_trading_post_requests() -> void:
	_unlock(2)
	_build(&"trading_post")
	var hunter: HunterRuntime = _game.hunters.get_all()[0]
	hunter.duty = &""
	_game.hunters.set_level(hunter, 20)
	var normal: RegionDefinition = _game.regions.get_duty_region(hunter)
	var other: RegionDefinition = null
	for region in _game.regions.get_hunting_regions():
		if region != normal and region.min_hunter_level <= hunter.level:
			other = region
	if other == null:
		return
	for monster_id in other.monster_ids:
		var enemy := _registry.find_def(&"enemy", monster_id) as EnemyDefinition
		var table := _registry.find_def(&"loot_table", enemy.loot_table_id) as LootTableDefinition
		for entry in table.entries:
			_game.trading.order(entry.item_id, 5)
			if _game.regions.get_duty_region(hunter) == other:
				return
			_game.trading.cancel(0)
	assert_true(false, "a request should pull Auto Hunters to the region that drops it")


func test_higher_item_tiers_exist() -> void:
	for item_id in [&"steel_sword", &"shadow_blade", &"steel_armor", &"shadow_armor"]:
		var item := _registry.find_def(&"item", item_id) as ItemDefinition
		assert_not_null(item, String(item_id))
		assert_true(item.rarity >= ItemDefinition.Rarity.SUPERIOR)
		assert_not_null(_registry.find_def(&"recipe", item_id), String(item_id))
