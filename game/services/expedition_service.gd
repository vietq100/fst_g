class_name ExpeditionService
extends RefCounted
## Expedition rules: validation, Hunter lifecycle, XP and gold per kill, success/failure
## rewards (EXPEDITION_SYSTEM.md, DECISIONS.md D2–D5, D10). The expedition scene drives the
## run (spawning, movement) and reports events; this service decides the outcome.

signal expedition_started(run: ExpeditionRun)
## `index` == enemy_groups.size() is the boss section.
signal section_started(run: ExpeditionRun, index: int)
signal expedition_finished(run: ExpeditionRun)
## SaveManager listens (Phase 9, DECISIONS.md D21).
signal autosave_requested(reason: StringName)

## `func(hunter: HunterRuntime, expedition_id: StringName)` for party members who fell: in the
## world they come out of the dungeon as bodies at its entrance (D30, D35). Unset: injured (D4).
var downed_handler: Callable
## Monster loadout rolls and drops (set by GameManager).
var regions: RegionService
var current_run: ExpeditionRun

var _registry: Node
var _hunters: HunterService
var _wallet: WalletService
var _progress: ProgressService
var _inventory: InventoryService
var _loot: LootService
var _stats: StatService
var _config: GameConfig
var _rng: RandomNumberGenerator


func _init(registry: Node, hunters: HunterService, wallet: WalletService, progress: ProgressService,
		inventory: InventoryService, loot: LootService, stats: StatService, config: GameConfig,
		rng: RandomNumberGenerator) -> void:
	_registry = registry
	_hunters = hunters
	_wallet = wallet
	_progress = progress
	_inventory = inventory
	_loot = loot
	_stats = stats
	_config = config
	_rng = rng


func is_running() -> bool:
	return current_run != null and not current_run.is_finished()


## Empty string when the expedition can start, otherwise the reason.
func validate(expedition_id: StringName, hunter_ids: Array[StringName]) -> String:
	if is_running():
		return Loc.t("err.expedition.running")
	var definition := get_definition(expedition_id)
	if definition == null:
		return Loc.t("err.expedition.unknown", {"expedition": expedition_id})
	if not _progress.has_flag(definition.unlock_flag):
		return Loc.t("err.expedition.locked", {"expedition": definition.display_name})
	if hunter_ids.is_empty() or hunter_ids.size() > _config.max_party_size:
		return Loc.t("err.expedition.party_size", {"max": _config.max_party_size})
	var seen: Dictionary[StringName, bool] = {}
	for hunter_id in hunter_ids:
		if seen.has(hunter_id):
			return Loc.t("err.expedition.duplicate_hunter")
		seen[hunter_id] = true
		var hunter := _hunters.get_hunter(hunter_id)
		if hunter == null:
			return Loc.t("err.expedition.unknown_hunter", {"hunter": hunter_id})
		if hunter.injured or not hunter.alive or hunter.state != HunterRuntime.LifecycleState.AVAILABLE:
			return Loc.t("err.expedition.unavailable", {"name": hunter.display_name})
	return ""


## Returns null (and starts nothing) if validation fails.
func start(expedition_id: StringName, hunter_ids: Array[StringName]) -> ExpeditionRun:
	if not validate(expedition_id, hunter_ids).is_empty():
		return null
	var definition := get_definition(expedition_id)
	var run := ExpeditionRun.new()
	run.expedition_id = expedition_id
	run.party_ids = hunter_ids.duplicate()
	run.is_first_clear = not _first_clear_done(definition)
	current_run = run
	for hunter in _party():
		hunter.expedition_id = expedition_id
		_hunters.set_lifecycle_state(hunter, HunterRuntime.LifecycleState.ASSIGNED)
	set_party_traveling()
	expedition_started.emit(run)
	return run


func get_definition(expedition_id: StringName) -> ExpeditionDefinition:
	return _registry.find_def(&"expedition", expedition_id) as ExpeditionDefinition


func get_current_definition() -> ExpeditionDefinition:
	return get_definition(current_run.expedition_id) if current_run != null else null


func is_boss_section(index: int) -> bool:
	return index == get_current_definition().enemy_groups.size()


func set_party_traveling() -> void:
	current_run.phase = ExpeditionRun.Phase.TRAVELING
	_set_party_state(HunterRuntime.LifecycleState.TRAVELING)


func begin_section(index: int) -> void:
	current_run.section_index = index
	if is_boss_section(index):
		current_run.boss_reached = true
	current_run.phase = ExpeditionRun.Phase.COMBAT
	_set_party_state(HunterRuntime.LifecycleState.COMBAT)
	section_started.emit(current_run, index)


## After the boss: the party walks to the exit.
func begin_return() -> void:
	current_run.phase = ExpeditionRun.Phase.RETURNING
	_set_party_state(HunterRuntime.LifecycleState.RETURNING)


## Gold and items go to the stash; every party member (downed included) gets the full XP (D5).
## The boss drops from the expedition's first-clear / repeat loot table instead of its own.
func record_kill(enemy: EnemyDefinition, loadout: MonsterLoadout = null, tier: int = -1) -> KillReward:
	var reward := KillReward.new()
	if not is_running() or enemy == null:
		return reward
	current_run.kills += 1
	reward.gold = _rng.randi_range(enemy.gold_min, enemy.gold_max)
	# A monster that carried a loadout drops what it carried (stash, collected automatically, D5).
	var carried: Dictionary[StringName, int] = {}
	if loadout != null and regions != null:
		carried = regions.get_drops(loadout, enemy.tier if tier < 0 else tier)
		if not enemy.is_boss:
			reward.gold = loadout.gold
	var table_id := enemy.loot_table_id
	if enemy.is_boss:
		var definition := get_current_definition()
		if current_run.is_first_clear:
			table_id = definition.first_clear_loot_table_id
		else:
			reward.gold = floori(reward.gold * 0.5)
			table_id = definition.repeat_clear_loot_table_id
	if loadout != null and regions != null and not enemy.is_boss:
		reward.items = carried
	else:
		reward.items = _loot.roll(table_id)
		# Bosses keep their special loot tables and add their worn gear on top.
		if loadout != null and regions != null:
			for item_id in loadout.get_gear():
				if carried.has(item_id):
					reward.items[item_id] = reward.items.get(item_id, 0) + carried[item_id]
	reward.gold = roundi(reward.gold * _party_gold_multiplier())
	current_run.stash_gold += reward.gold
	for item_id in reward.items:
		current_run.stash_items[item_id] = current_run.stash_items.get(item_id, 0) + reward.items[item_id]
	current_run.xp_per_hunter += enemy.xp_reward
	var cap := _stats.level_cap(_progress.town_level)
	for hunter in _party():
		var gained := _hunters.add_xp(hunter, enemy.xp_reward, cap)
		if gained > 0:
			current_run.levels_gained[hunter.unique_id] = current_run.levels_gained.get(hunter.unique_id, 0) + gained
	return reward


func mark_downed(hunter_id: StringName) -> void:
	if is_running() and not current_run.downed_ids.has(hunter_id):
		current_run.downed_ids.append(hunter_id)


func is_party_wiped() -> bool:
	return current_run.downed_ids.size() >= current_run.party_ids.size()


func complete() -> void:
	if not is_running():
		return
	var definition := get_current_definition()
	current_run.gold_granted = current_run.stash_gold + definition.completion_bonus_gold
	var tickets := definition.completion_bonus_summon_tickets
	if current_run.is_first_clear:
		tickets += definition.first_clear_bonus_summon_tickets
	if tickets > 0:
		current_run.tickets_granted = tickets
		_wallet.add_tickets(tickets)
	_grant_items(1.0)
	if current_run.is_first_clear:
		for flag in definition.first_clear_flags:
			_progress.set_flag(flag)
	_finish(ExpeditionRun.Phase.SUCCESS)


## Party wiped: keep part of the stash, no bonus, everyone injured (D4).
func fail() -> void:
	if not is_running():
		return
	for hunter_id in current_run.party_ids:
		mark_downed(hunter_id)
	current_run.gold_granted = floori(current_run.stash_gold * _config.failure_loot_keep_ratio)
	_grant_items(_config.failure_loot_keep_ratio)
	_finish(ExpeditionRun.Phase.FAILED)


func _finish(result: ExpeditionRun.Phase) -> void:
	current_run.phase = result
	_wallet.add(current_run.gold_granted)
	for hunter in _party():
		hunter.expedition_id = &""
		_add_history(hunter, HunterRuntime.EXPEDITIONS_COMPLETED if result == ExpeditionRun.Phase.SUCCESS else HunterRuntime.EXPEDITIONS_FAILED)
		if result == ExpeditionRun.Phase.SUCCESS:
			_add_history(hunter, HunterRuntime.BOSSES_DEFEATED)
		if current_run.downed_ids.has(hunter.unique_id):
			_add_history(hunter, HunterRuntime.TIMES_INJURED)
			if downed_handler.is_valid():
				downed_handler.call(hunter, current_run.expedition_id)
			else:
				_hunters.mark_injured(hunter)
		else:
			_hunters.set_lifecycle_state(hunter, HunterRuntime.LifecycleState.AVAILABLE)
	expedition_finished.emit(current_run)
	autosave_requested.emit(&"expedition_end")


## Greedy and other gold_find bonuses of the party add up (e.g. two Greedy Hunters: +40%).
func _party_gold_multiplier() -> float:
	var multiplier := 1.0
	for hunter in _party():
		multiplier += _hunters.get_stat(hunter, HunterService.GOLD_FIND) - 1.0
	return maxf(multiplier, 0.0)


static func _add_history(hunter: HunterRuntime, key: StringName) -> void:
	hunter.history[key] = hunter.history.get(key, 0) + 1


## Moves `ratio` of each stashed item (rounded down) into the inventory. What does not fit
## is auto-sold at sell price and added to gold_granted (DECISIONS.md D9).
func _grant_items(ratio: float) -> void:
	for item_id in current_run.stash_items:
		var quantity := floori(current_run.stash_items[item_id] * ratio)
		if quantity <= 0:
			continue
		var added := _inventory.add_item(item_id, quantity)
		if added > 0:
			current_run.items_granted[item_id] = added
		var overflow := quantity - added
		if overflow > 0:
			var item := _registry.find_def(&"item", item_id) as ItemDefinition
			current_run.items_overflowed[item_id] = overflow
			var gold := overflow * (item.sell_price if item != null else 0)
			current_run.overflow_gold += gold
			current_run.gold_granted += gold


func _first_clear_done(definition: ExpeditionDefinition) -> bool:
	if definition.first_clear_flags.is_empty():
		return false
	for flag in definition.first_clear_flags:
		if not _progress.has_flag(flag):
			return false
	return true


func _party() -> Array[HunterRuntime]:
	var result: Array[HunterRuntime] = []
	for hunter_id in current_run.party_ids:
		var hunter := _hunters.get_hunter(hunter_id)
		if hunter != null:
			result.append(hunter)
	return result


func _set_party_state(state: HunterRuntime.LifecycleState) -> void:
	for hunter in _party():
		if not current_run.downed_ids.has(hunter.unique_id):
			_hunters.set_lifecycle_state(hunter, state)

