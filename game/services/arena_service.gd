class_name ArenaService
extends RefCounted
## Colosseum (ARENA_SYSTEM.md, phase 1): safe 1vs1 matches between Hunters. A fight is simulated
## from the Hunters' real stats (level, gear, traits, mood, skills' stat bonuses) with PvP rules:
## damage ×`pvp_damage_scale`, dodge and crit capped. Opponents are generated rivals (weaker / even /
## stronger than the chosen Hunter) or another of the player's own Hunters (friendly). The match
## changes nothing but the fighter's stamina and mood; no ranking or rewards yet.

signal match_finished(hunter: HunterRuntime, result: ArenaResult)
signal tickets_refreshed(count: int)

enum Format { ONE_VS_ONE = 1, FOUR_VS_FOUR = 4, SIX_VS_SIX = 6 }

## Seconds before the first blows land (the fighters walk up to each other).
const OPENING_DELAY := 0.8
## Rival strength relative to the chosen Hunter: weaker, even, stronger.
const RIVAL_POWER: Array[float] = [0.85, 1.0, 1.15]
## Grievous debuff: healing is reduced by 30% in Colosseum combat.
const GRIEVOUS_HEALING_FACTOR := 0.70
const MAX_DAILY_TICKETS := 5
const REFILL_COST_GOLD := 20

const TOKEN_SHOP := {
	&"summon_ticket": {"name_key": "item.summon_ticket.name", "cost": 3, "reward_type": &"ticket", "amount": 1},
	&"dark_essence": {"name_key": "item.dark_essence.name", "cost": 5, "reward_type": &"item", "item_id": &"dark_essence", "amount": 2},
	&"iron_ore": {"name_key": "item.iron_ore.name", "cost": 4, "reward_type": &"item", "item_id": &"iron_ore", "amount": 10},
	&"bone_dust": {"name_key": "item.bone_dust.name", "cost": 4, "reward_type": &"item", "item_id": &"bone_dust", "amount": 15},
	&"pet_slime": {"name_key": "item.pet_slime.name", "cost": 6, "reward_type": &"item", "item_id": &"pet_slime", "amount": 1},
	&"pet_pup": {"name_key": "item.pet_pup.name", "cost": 8, "reward_type": &"item", "item_id": &"pet_pup", "amount": 1},
	&"pet_wisp": {"name_key": "item.pet_wisp.name", "cost": 12, "reward_type": &"item", "item_id": &"pet_wisp", "amount": 1},
}

var _registry: Node
var _hunters: HunterService
var _traits: TraitService
var _buildings: BuildingService
var _stats: StatService
var _config: GameConfig
var _rng: RandomNumberGenerator
## The three rivals offered for `board_owner`.
var board: Array[HunterRuntime] = []
var board_owner: StringName = &""
var daily_tickets: int = MAX_DAILY_TICKETS
var wallet: WalletService
var inventory: InventoryService


func _init(registry: Node, hunters: HunterService, traits: TraitService, buildings: BuildingService,
		stats: StatService, config: GameConfig, rng: RandomNumberGenerator) -> void:
	_registry = registry
	_hunters = hunters
	_traits = traits
	_buildings = buildings
	_stats = stats
	_config = config
	_rng = rng


## Strength used to match rivals: HP × 0.2 + ATK × 2 + DEF × 1.5.
func get_power(hunter: HunterRuntime) -> float:
	return _hunters.get_stat(hunter, HunterService.MAX_HP) * 0.2 + _hunters.get_stat(hunter, HunterService.ATTACK) * 2.0 \
		+ _hunters.get_stat(hunter, HunterService.DEFENSE) * 1.5


## Empty string when `hunter` may fight now, otherwise the reason (translated).
func can_enter(hunter: HunterRuntime) -> String:
	if hunter == null:
		return Loc.t("err.arena.unknown")
	if not _buildings.has_building(BuildingService.COLOSSEUM):
		return Loc.t("err.arena.no_colosseum")
	if hunter.level < _config.colosseum_min_level:
		return Loc.t("err.arena.level", {"level": _config.colosseum_min_level})
	if not hunter.alive or hunter.injured:
		return Loc.t("err.arena.hurt", {"name": hunter.display_name})
	if hunter.hibernating:
		return Loc.t("err.hibernate.asleep", {"name": hunter.display_name})
	if hunter.expedition_id != &"":
		return Loc.t("err.arena.busy", {"name": hunter.display_name})
	if hunter.stamina < _config.arena_min_stamina:
		return Loc.t("err.arena.tired", {"name": hunter.display_name})
	return ""


func get_eligible() -> Array[HunterRuntime]:
	var result: Array[HunterRuntime] = []
	for hunter in _hunters.get_all():
		if can_enter(hunter).is_empty():
			result.append(hunter)
	return result


# --- Rivals ---------------------------------------------------------------------------------------

## Three fresh rivals for `hunter` (weaker, even, stronger).
func refresh_board(hunter: HunterRuntime) -> void:
	board.clear()
	board_owner = hunter.unique_id if hunter != null else &""
	if hunter == null:
		return
	var base := get_power(hunter)
	for factor in RIVAL_POWER:
		board.append(make_rival(base * factor))


## A rival Hunter (not in the roster): random base class, traits, a level chosen so its power is as
## close as possible to `target_power`.
func make_rival(target_power: float) -> HunterRuntime:
	var class_ids: Array[StringName] = []
	for id: StringName in _registry.get_ids(&"hunter"):
		if (_registry.find_def(&"hunter", id) as HunterDefinition).promotion_of == &"":
			class_ids.append(id)
	var rival := _hunters.generate_candidate(class_ids[_rng.randi_range(0, class_ids.size() - 1)], _rng)
	_traits.assign_random_traits(rival)
	var best_level := 1
	var best_gap := INF
	for level in range(1, 121):
		rival.level = level
		var gap := absf(get_power(rival) - target_power)
		if gap < best_gap:
			best_gap = gap
			best_level = level
	rival.level = best_level
	rival.current_hp = _hunters.get_stat(rival, HunterService.MAX_HP)
	rival.mood = _config.mood_start
	return rival


# --- The fight ---------------------------------------------------------------------------------------

class Fighter:
	var runtime: HunterRuntime
	var max_hp := 1.0
	var hp := 1.0
	var attack := 0.0
	var defense := 0.0
	var interval := 1.0
	var crit := 0.0
	var crit_damage := 1.5
	var dodge := 0.0
	var dealt := 1.0
	var taken := 1.0
	var next_attack := 0.0


func _fighter(hunter: HunterRuntime) -> Fighter:
	var f := Fighter.new()
	f.runtime = hunter
	f.max_hp = _hunters.get_stat(hunter, HunterService.MAX_HP)
	f.hp = f.max_hp
	f.attack = _hunters.get_stat(hunter, HunterService.ATTACK)
	f.defense = _hunters.get_stat(hunter, HunterService.DEFENSE)
	f.interval = _stats.attack_cooldown(_hunters.get_stat(hunter, HunterService.ATTACK_SPEED))
	if is_inf(f.interval):
		f.interval = 5.0
	f.crit = minf(_hunters.get_stat(hunter, HunterService.CRITICAL_CHANCE), _config.pvp_crit_cap)
	f.crit_damage = _hunters.get_stat(hunter, HunterService.CRITICAL_DAMAGE)
	f.dodge = minf(_hunters.get_stat(hunter, HunterService.DODGE), _config.pvp_dodge_cap)
	f.dealt = _hunters.get_stat(hunter, HunterService.DAMAGE_DEALT)
	f.taken = _hunters.get_stat(hunter, HunterService.DAMAGE_TAKEN)
	f.next_attack = OPENING_DELAY
	return f


## Simulates `a` against `b` from full HP. Deterministic for a given `seed_value`. Changes nothing in
## the game state.
func simulate(a: HunterRuntime, b: HunterRuntime, seed_value: int = -1) -> ArenaResult:
	var rng := RandomNumberGenerator.new()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	var fighters: Array[Fighter] = [_fighter(a), _fighter(b)]
	var result := ArenaResult.new()
	for i in 2:
		result.names[i] = fighters[i].runtime.display_name
		result.max_hp[i] = fighters[i].max_hp
	var time := 0.0
	while true:
		var side := 0 if fighters[0].next_attack <= fighters[1].next_attack else 1
		var actor := fighters[side]
		time = actor.next_attack
		if time > _config.arena_time_limit:
			result.timed_out = true
			time = _config.arena_time_limit
			break
		var target := fighters[1 - side]
		var event := {"t": time, "from": side, "damage": 0, "crit": false, "dodged": false}
		if rng.randf() < target.dodge:
			event["dodged"] = true
		else:
			var damage := _stats.calculate_damage(actor.attack, target.defense)
			if rng.randf() < actor.crit:
				damage = _stats.apply_critical(damage, actor.crit_damage)
				event["crit"] = true
			damage = maxf(damage * actor.dealt * target.taken * _config.pvp_damage_scale, 1.0)
			target.hp = maxf(target.hp - damage, 0.0)
			event["damage"] = roundi(damage)
		event["hp"] = [fighters[0].hp, fighters[1].hp]
		result.events.append(event)
		actor.next_attack += actor.interval
		if target.hp <= 0.0:
			break
	result.duration = time
	for i in 2:
		result.hp_end[i] = fighters[i].hp
	if fighters[0].hp <= 0.0:
		result.winner = 1
	elif fighters[1].hp <= 0.0:
		result.winner = 0
	else:
		var ra := result.hp_ratio(0)
		var rb := result.hp_ratio(1)
		result.winner = -1 if absf(ra - rb) < 0.005 else (0 if ra > rb else 1)
	return result


## Match consequences for the Hunter who entered (the arena is safe): stamina and mood only, and
## arena records in its history.
func apply_result(hunter: HunterRuntime, result: ArenaResult, side: int = 0) -> void:
	hunter.stamina = maxf(hunter.stamina - _config.arena_stamina_cost, 0.0)
	var delta := _config.arena_mood_draw
	var key := &"arena_draws"
	if result.winner == side:
		delta = _config.arena_mood_win
		key = &"arena_wins"
		if wallet != null:
			wallet.add_tokens(1)
	elif result.winner != -1:
		delta = _config.arena_mood_loss
		key = &"arena_losses"
	hunter.mood = clampf(hunter.mood + delta, 0.0, _config.mood_max)
	hunter.history[key] = hunter.history.get(key, 0) + 1
	_hunters.notify_changed(hunter)
	match_finished.emit(hunter, result)


## Mood change a result gives the Hunter on `side` (for the result screen).
func mood_delta(result: ArenaResult, side: int = 0) -> float:
	if result.winner == side:
		return _config.arena_mood_win
	return _config.arena_mood_draw if result.winner == -1 else _config.arena_mood_loss


# --- Phase 2: Tickets, Teams & Token Shop -----------------------------------------------------------

func can_fight() -> bool:
	return daily_tickets > 0


func spend_ticket() -> bool:
	if daily_tickets <= 0:
		return false
	daily_tickets -= 1
	tickets_refreshed.emit(daily_tickets)
	return true


func refill_tickets() -> bool:
	if wallet == null or not wallet.can_spend(REFILL_COST_GOLD):
		return false
	wallet.spend(REFILL_COST_GOLD)
	daily_tickets = MAX_DAILY_TICKETS
	tickets_refreshed.emit(daily_tickets)
	return true


func reset_daily_tickets() -> void:
	daily_tickets = MAX_DAILY_TICKETS
	tickets_refreshed.emit(daily_tickets)


func make_rival_team(target_avg_power: float, count: int) -> Array[HunterRuntime]:
	var team: Array[HunterRuntime] = []
	for i in count:
		var factor: float = _rng.randf_range(0.85, 1.15)
		team.append(make_rival(target_avg_power * factor))
	return team


## Simulates a team relay battle (striker vs striker). When a fighter falls, the next steps in.
func simulate_team(team_a: Array[HunterRuntime], team_b: Array[HunterRuntime], seed_value: int = -1) -> ArenaResult:
	var rng := RandomNumberGenerator.new()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	var result := ArenaResult.new()
	if team_a.is_empty() or team_b.is_empty():
		return result

	result.names[0] = "%s & Squad (%d)" % [team_a[0].display_name, team_a.size()]
	result.names[1] = "%s & Squad (%d)" % [team_b[0].display_name, team_b.size()]

	var total_max_hp_a := 0.0
	for h in team_a:
		total_max_hp_a += _hunters.get_stat(h, HunterService.MAX_HP)
	var total_max_hp_b := 0.0
	for h in team_b:
		total_max_hp_b += _hunters.get_stat(h, HunterService.MAX_HP)

	result.max_hp[0] = total_max_hp_a
	result.max_hp[1] = total_max_hp_b

	var idx_a := 0
	var idx_b := 0
	var f_a := _fighter(team_a[0])
	var f_b := _fighter(team_b[0])

	var time := 0.0
	while idx_a < team_a.size() and idx_b < team_b.size():
		var side := 0 if f_a.next_attack <= f_b.next_attack else 1
		var actor := f_a if side == 0 else f_b
		time = actor.next_attack
		if time > _config.arena_time_limit * 2.0:
			result.timed_out = true
			time = _config.arena_time_limit * 2.0
			break
		var target := f_b if side == 0 else f_a
		var event := {"t": time, "from": side, "damage": 0, "crit": false, "dodged": false}
		if rng.randf() < target.dodge:
			event["dodged"] = true
		else:
			var damage := _stats.calculate_damage(actor.attack, target.defense)
			if rng.randf() < actor.crit:
				damage = _stats.apply_critical(damage, actor.crit_damage)
				event["crit"] = true
			damage = maxf(damage * actor.dealt * target.taken * _config.pvp_damage_scale, 1.0)
			target.hp = maxf(target.hp - damage, 0.0)
			event["damage"] = roundi(damage)

		var rem_a := f_a.hp
		for i in range(idx_a + 1, team_a.size()):
			rem_a += _hunters.get_stat(team_a[i], HunterService.MAX_HP)
		var rem_b := f_b.hp
		for i in range(idx_b + 1, team_b.size()):
			rem_b += _hunters.get_stat(team_b[i], HunterService.MAX_HP)
		event["hp"] = [rem_a, rem_b]
		result.events.append(event)
		actor.next_attack += actor.interval

		if f_a.hp <= 0.0:
			idx_a += 1
			if idx_a < team_a.size():
				f_a = _fighter(team_a[idx_a])
				f_a.next_attack = time + OPENING_DELAY
		if f_b.hp <= 0.0:
			idx_b += 1
			if idx_b < team_b.size():
				f_b = _fighter(team_b[idx_b])
				f_b.next_attack = time + OPENING_DELAY

	result.duration = time
	var final_a := 0.0
	if idx_a < team_a.size():
		final_a += f_a.hp
		for i in range(idx_a + 1, team_a.size()):
			final_a += _hunters.get_stat(team_a[i], HunterService.MAX_HP)
	var final_b := 0.0
	if idx_b < team_b.size():
		final_b += f_b.hp
		for i in range(idx_b + 1, team_b.size()):
			final_b += _hunters.get_stat(team_b[i], HunterService.MAX_HP)
	result.hp_end[0] = final_a
	result.hp_end[1] = final_b

	if final_a <= 0.0:
		result.winner = 1
	elif final_b <= 0.0:
		result.winner = 0
	else:
		var ra := result.hp_ratio(0)
		var rb := result.hp_ratio(1)
		result.winner = -1 if absf(ra - rb) < 0.005 else (0 if ra > rb else 1)
	return result


func apply_team_result(team_a: Array[HunterRuntime], result: ArenaResult, format: int) -> void:
	var tokens := 1
	if format == Format.FOUR_VS_FOUR:
		tokens = 3
	elif format == Format.SIX_VS_SIX:
		tokens = 4
	if wallet != null and result.winner == 0:
		wallet.add_tokens(tokens)
	for hunter in team_a:
		apply_result(hunter, result, 0)


func buy_token_shop_item(item_key: StringName) -> bool:
	if not TOKEN_SHOP.has(item_key) or wallet == null:
		return false
	var entry: Dictionary = TOKEN_SHOP[item_key]
	var cost: int = entry["cost"]
	if not wallet.can_spend_tokens(cost):
		return false
	wallet.spend_tokens(cost)
	match entry["reward_type"]:
		&"ticket":
			wallet.add_tickets(entry["amount"])
		&"item":
			if inventory != null:
				inventory.add(entry["item_id"], entry["amount"])
	return true


func to_dict() -> Dictionary:
	return {
		"daily_tickets": daily_tickets,
	}


func from_dict(data: Dictionary) -> void:
	daily_tickets = maxi(int(data.get("daily_tickets", MAX_DAILY_TICKETS)), 0)

