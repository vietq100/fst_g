class_name RegionService
extends RefCounted
## Hunting rules for the world regions (AUTONOMY_SYSTEM.md → Hunting, BALANCE.md → Regions,
## DECISIONS.md D29): which region a Hunter's duty points to, monster level scaling, kill rewards
## (XP, purse gold, loot bag) and depositing the bag at the Warehouse. No Nodes here; the world's
## spawners and Hunter brains call these rules.

## Something was put into or taken out of a loot bag.
signal loot_bag_changed(hunter: HunterRuntime)
## A bag was sold to the village (D39). `report`: see `deposit`.
signal bag_deposited(hunter: HunterRuntime, report: Dictionary)

var _registry: Node
var _world: WorldService
var _hunters: HunterService
var _purses: PurseService
var _inventory: InventoryService
var _wallet: WalletService
var _loot: LootService
var _stats: StatService
## `func() -> Array[StringName]`: materials the Trading Post wants (Auto duty follows them).
var wanted_items: Callable = Callable()
var _progress: ProgressService
var _config: GameConfig
var _rng: RandomNumberGenerator


func _init(registry: Node, world: WorldService, hunters: HunterService, purses: PurseService,
		inventory: InventoryService, wallet: WalletService, loot: LootService, stats: StatService,
		progress: ProgressService, config: GameConfig, rng: RandomNumberGenerator) -> void:
	_registry = registry
	_world = world
	_hunters = hunters
	_purses = purses
	_inventory = inventory
	_wallet = wallet
	_loot = loot
	_stats = stats
	_progress = progress
	_config = config
	_rng = rng


## Monster regions (everything but the Town), easiest first.
func get_hunting_regions() -> Array[RegionDefinition]:
	var regions: Array[RegionDefinition] = _world.get_regions().filter(func(r: RegionDefinition) -> bool: return not r.is_town)
	regions.sort_custom(func(a: RegionDefinition, b: RegionDefinition) -> bool: return a.min_hunter_level < b.min_hunter_level)
	return regions


## Where the Hunter's duty sends it, or null for "Stay in town" (D29). Auto = the hardest region
## whose minimum level the Hunter has reached.
func get_duty_region(hunter: HunterRuntime) -> RegionDefinition:
	if hunter.duty == HunterRuntime.STAY_IN_TOWN:
		return null
	if hunter.duty != &"":
		var fixed := _world.get_region(hunter.duty)
		if fixed != null and not fixed.is_town:
			return fixed
	var best: RegionDefinition = null
	var wanted: Array[StringName] = wanted_items.call() if wanted_items.is_valid() else []
	var wanted_region: RegionDefinition = null
	for region in get_hunting_regions():
		if region.min_hunter_level <= hunter.level:
			best = region
			# Trading Post requests pull Auto Hunters to a region whose monsters drop the material.
			if region_drops_any(region, wanted):
				wanted_region = region
	return wanted_region if wanted_region != null else best


## True when a monster of the region can drop one of `item_ids`.
func region_drops_any(region: RegionDefinition, item_ids: Array[StringName]) -> bool:
	for monster_id in region.monster_ids:
		var enemy := _registry.find_def(&"enemy", monster_id) as EnemyDefinition
		var table := _registry.find_def(&"loot_table", enemy.loot_table_id) as LootTableDefinition if enemy != null else null
		if table == null:
			continue
		for entry in table.entries:
			if item_ids.has(entry.item_id):
				return true
	return false


## Valid duty choices: &"" (Auto), each hunting region id, STAY_IN_TOWN.
func get_duty_options() -> Array[StringName]:
	var options: Array[StringName] = [&""]
	for region in get_hunting_regions():
		options.append(region.id)
	options.append(HunterRuntime.STAY_IN_TOWN)
	return options


func get_duty_name(duty: StringName) -> String:
	if duty == &"":
		return "Auto"
	if duty == HunterRuntime.STAY_IN_TOWN:
		return "Stay in town"
	var region := _world.get_region(duty)
	return region.display_name if region != null else String(duty)


func set_duty(hunter: HunterRuntime, duty: StringName) -> String:
	if not get_duty_options().has(duty):
		return "Unknown duty"
	hunter.duty = duty
	_hunters.notify_changed(hunter)
	return ""


# --- Monsters ------------------------------------------------------------------------------------

func roll_monster(region: RegionDefinition) -> EnemyDefinition:
	if region.monster_ids.is_empty():
		return null
	return _registry.find_def(&"enemy", region.monster_ids[_rng.randi_range(0, region.monster_ids.size() - 1)]) as EnemyDefinition


func roll_level(region: RegionDefinition) -> int:
	return _rng.randi_range(region.monster_level_min, maxi(region.monster_level_max, region.monster_level_min))


func get_stat_scale(level: int) -> float:
	return (1.0 + _config.monster_stat_per_level * (maxi(level, 1) - 1)) * _difficulty_value(_config.difficulty_stat_scale)


func get_reward_scale(level: int) -> float:
	return (1.0 + _config.monster_reward_per_level * (maxi(level, 1) - 1)) * _difficulty_value(_config.difficulty_reward_scale)


func _difficulty_value(values: Array[float]) -> float:
	if values.is_empty():
		return 1.0
	return values[clampi(_progress.difficulty, 0, values.size() - 1)]


# --- Kill rewards and the loot bag ---------------------------------------------------------------

## The killer gets gold (×gold_find) into its purse and items into its bag (what does not fit is
## left behind); the killer and every helper get the XP. Returns the reward for popups.
func record_kill(killer: HunterRuntime, helpers: Array[HunterRuntime], enemy: EnemyDefinition, level: int) -> KillReward:
	var reward := KillReward.new()
	if killer == null or enemy == null:
		return reward
	var scale := get_reward_scale(level)
	reward.gold = roundi(_rng.randi_range(enemy.gold_min, enemy.gold_max) * scale * _hunters.get_stat(killer, HunterService.GOLD_FIND))
	_purses.earn(killer, reward.gold)
	var rolled: Dictionary[StringName, int] = {}
	if enemy.loot_table_id != &"":
		rolled = _loot.roll(enemy.loot_table_id)
	for item_id in rolled:
		var added := add_to_bag(killer, item_id, rolled[item_id])
		if added > 0:
			reward.items[item_id] = added
	var xp := roundi(enemy.xp_reward * scale)
	var cap := _stats.level_cap(_progress.town_level)
	var credited: Array[HunterRuntime] = [killer]
	for helper in helpers:
		if helper != null and not credited.has(helper):
			credited.append(helper)
	for hunter in credited:
		_hunters.add_xp(hunter, xp, cap)
	return reward


func get_bag_count(hunter: HunterRuntime) -> int:
	var total := 0
	for item_id in hunter.loot_bag:
		total += hunter.loot_bag[item_id]
	return total


func is_bag_full(hunter: HunterRuntime) -> bool:
	return get_bag_count(hunter) >= _config.loot_bag_capacity


## Adds up to the bag's free room. Returns how many were added.
func add_to_bag(hunter: HunterRuntime, item_id: StringName, quantity: int) -> int:
	var added := mini(quantity, _config.loot_bag_capacity - get_bag_count(hunter))
	if added <= 0:
		return 0
	hunter.loot_bag[item_id] = hunter.loot_bag.get(item_id, 0) + added
	loot_bag_changed.emit(hunter)
	return added


## Takes up to `quantity` out of the bag. Returns how many were taken.
func remove_from_bag(hunter: HunterRuntime, item_id: StringName, quantity: int) -> int:
	var taken := mini(quantity, hunter.loot_bag.get(item_id, 0))
	if taken <= 0:
		return 0
	hunter.loot_bag[item_id] -= taken
	if hunter.loot_bag[item_id] <= 0:
		hunter.loot_bag.erase(item_id)
	loot_bag_changed.emit(hunter)
	return taken


## Sells the bag to the village (D39): the treasury buys what it can pay for and store, at the
## item's price, into the Hunter's purse; a passing trader buys the rest at the same price.
## Report: {"items": {id: qty stored}, "village_gold": paid by the treasury, "trader_gold": int}.
func deposit(hunter: HunterRuntime) -> Dictionary:
	var report := {"items": {}, "village_gold": 0, "trader_gold": 0}
	if hunter.loot_bag.is_empty():
		return report
	for item_id in hunter.loot_bag:
		var quantity: int = hunter.loot_bag[item_id]
		var item := _registry.find_def(&"item", item_id) as ItemDefinition
		var price := item.sell_price if item != null else 0
		var affordable := quantity if price <= 0 else mini(quantity, floori(float(_wallet.gold) / price))
		var stored := _inventory.add_item(item_id, affordable) if affordable > 0 else 0
		if stored > 0:
			report["items"][item_id] = stored
			_wallet.spend(stored * price)
			report["village_gold"] += stored * price
		report["trader_gold"] += (quantity - stored) * price
	_purses.earn(hunter, report["village_gold"] + report["trader_gold"])
	hunter.loot_bag.clear()
	loot_bag_changed.emit(hunter)
	bag_deposited.emit(hunter, report)
	return report


## Low HP: go home (below rest_below_hp_ratio); once resting, stay until rest_until_hp_ratio.
func needs_rest(hunter: HunterRuntime, resting: bool) -> bool:
	var max_hp := _hunters.get_stat(hunter, HunterService.MAX_HP)
	return hunter.current_hp < max_hp * (_config.rest_until_hp_ratio if resting else _config.rest_below_hp_ratio)
