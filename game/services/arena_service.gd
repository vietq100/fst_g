class_name ArenaService
extends RefCounted
## Colosseum (ARENA_SYSTEM.md, phase 1): safe 1vs1 matches between Hunters. A fight is simulated
## from the Hunters' real stats (level, gear, traits, mood, skills' stat bonuses) with PvP rules:
## damage ×`pvp_damage_scale`, dodge and crit capped. Opponents are generated rivals (weaker / even /
## stronger than the chosen Hunter) or another of the player's own Hunters (friendly). The match
## changes nothing but the fighter's stamina and mood; no ranking or rewards yet.

signal match_finished(hunter: HunterRuntime, result: ArenaResult)

## Seconds before the first blows land (the fighters walk up to each other).
const OPENING_DELAY := 0.8
## Rival strength relative to the chosen Hunter: weaker, even, stronger.
const RIVAL_POWER: Array[float] = [0.85, 1.0, 1.15]

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
