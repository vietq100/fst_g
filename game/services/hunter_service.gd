class_name HunterService
extends RefCounted
## Owns the Hunter roster and computes Hunter stats (CHARACTER_SYSTEM.md).
## Other systems add stat modifiers through modifier sources (equipment, traits, mood, bonds),
## so every stat goes through one pipeline (DECISIONS.md D18).

signal hunter_added(hunter: HunterRuntime)
## The Hunter left the roster for good (expelled at the Hunter Gate, D58).
signal hunter_removed(hunter: HunterRuntime)
signal hunter_changed(hunter: HunterRuntime)
## Emitted after level and HP were updated; `healed` is the HP restored by the level-up.
signal hunter_leveled_up(hunter: HunterRuntime, new_level: int, healed: float)

const MAX_HP := &"max_hp"
const ATTACK := &"attack"
const DEFENSE := &"defense"
const ATTACK_SPEED := &"attack_speed"
const MOVE_SPEED := &"move_speed"
const CRITICAL_CHANCE := &"critical_chance"
const CRITICAL_DAMAGE := &"critical_damage"
## Multiplier stats (base 1.0): only percent modifiers make sense for them.
const DAMAGE_DEALT := &"damage_dealt"
const DAMAGE_TAKEN := &"damage_taken"
const GOLD_FIND := &"gold_find"
const XP_GAIN := &"xp_gain"
## Healing done (class skills, D70). Multiplier stat.
const HEALING := &"healing"
## Mana for active class skills (D70).
const MAX_MANA := &"max_mana"
const MANA_REGEN := &"mana_regen"
## Additive fractions from 0 (D70): chance to dodge a hit, share of crowd control shrugged off.
const DODGE := &"dodge"
const TENACITY := &"tenacity"
## Extra attack range as a fraction (D70). Additive from 0.
const RANGE_BONUS := &"range_bonus"

const MULTIPLIER_STATS: Array[StringName] = [DAMAGE_DEALT, DAMAGE_TAKEN, GOLD_FIND, XP_GAIN, HEALING]
const ADDITIVE_STATS: Array[StringName] = [DODGE, TENACITY, RANGE_BONUS]
## Stats that receive a random roll at recruitment.
const ROLLED_STATS: Array[StringName] = [MAX_HP, ATTACK, DEFENSE]
const ACCENT_COUNT := 8

## DataRegistry autoload (or a test instance).
var _registry: Node
var _stats: StatService
var _config: GameConfig
var _hunters: Dictionary[StringName, HunterRuntime] = {}
var _next_id := 1
## Callables `func(hunter: HunterRuntime) -> Array[StatModifier]`.
var _modifier_sources: Array[Callable] = []
var buildings: BuildingService


## Achievement Titles
const TITLE_GOBLIN_SLAYER := &"goblin_slayer"
const TITLE_UNDYING := &"undying"
const TITLE_ARENA_CHAMPION := &"arena_champion"
const TITLE_MASTER_GATHERER := &"master_gatherer"
const TITLE_VETERAN := &"veteran"

const TITLE_MODIFIERS: Dictionary[StringName, Dictionary] = {
	TITLE_GOBLIN_SLAYER: {
		"stat": ATTACK,
		"type": StatModifier.Type.PERCENT,
		"value": 0.08,
	},
	TITLE_UNDYING: {
		"stat": MAX_HP,
		"type": StatModifier.Type.PERCENT,
		"value": 0.12,
	},
	TITLE_ARENA_CHAMPION: {
		"stat": CRITICAL_CHANCE,
		"type": StatModifier.Type.FLAT,
		"value": 0.05,
	},
	TITLE_MASTER_GATHERER: {
		"stat": MOVE_SPEED,
		"type": StatModifier.Type.PERCENT,
		"value": 0.10,
	},
	TITLE_VETERAN: {
		"stat": DEFENSE,
		"type": StatModifier.Type.PERCENT,
		"value": 0.08,
	},
}

func _init(registry: Node, stats: StatService, config: GameConfig) -> void:
	_registry = registry
	_stats = stats
	_config = config
	add_modifier_source(_get_title_modifiers)


## Registers a provider of stat modifiers for a Hunter (equipment, traits, mood, bonds).
func add_modifier_source(source: Callable) -> void:
	_modifier_sources.append(source)


## Breaks the service reference cycles created by modifier sources (tests, shutdown).
func clear_modifier_sources() -> void:
	_modifier_sources.clear()


## A new Hunter that is NOT in the roster yet (Tavern candidate). Null if the class is unknown.
func generate_candidate(definition_id: StringName, rng: RandomNumberGenerator) -> HunterRuntime:
	var definition := _get_definition_by_id(definition_id)
	if definition == null:
		return null
	var hunter := HunterRuntime.new()
	hunter.definition_id = definition_id
	hunter.display_name = _pick_name(definition, rng)
	hunter.accent_index = rng.randi_range(0, ACCENT_COUNT - 1)
	var variance := definition.stat_roll_variance
	for stat in ROLLED_STATS:
		hunter.stat_rolls[stat] = rng.randf_range(-variance, variance)
	# Tier from its own seed so the shared RNG sequence is not changed (D60).
	var tier_rng := RandomNumberGenerator.new()
	tier_rng.seed = hash("tier|%s|%s|%s" % [hunter.display_name, definition_id, hunter.stat_rolls])
	hunter.tier = Tier.roll(tier_rng, Tier.HUNTER_WEIGHTS)
	hunter.mood = _config.mood_start
	hunter.current_hp = get_stat(hunter, MAX_HP)
	hunter.stamina = _config.needs_max
	hunter.energy = _config.needs_max
	hunter.purse = _config.purse_start
	# Seeded from the rolls above so the shared RNG sequence is not changed (D47).
	hunter.appearance = HunterAppearance.from_seed("%s|%s|%s" % [hunter.display_name, definition_id, hunter.stat_rolls], hunter.accent_index)
	return hunter


## Generates the next sequential Hunter ID.
func next_id() -> StringName:
	var id := StringName("h_%d" % _next_id)
	_next_id += 1
	return id


## Adds a generated Hunter to the roster and gives it a unique id.
func add_hunter(hunter: HunterRuntime) -> HunterRuntime:
	if hunter.unique_id == &"":
		hunter.unique_id = next_id()
	_hunters[hunter.unique_id] = hunter
	hunter_added.emit(hunter)
	return hunter


## Takes a Hunter off the roster (D58). Returns it, or null if unknown.
func remove_hunter(unique_id: StringName) -> HunterRuntime:
	var hunter: HunterRuntime = _hunters.get(unique_id)
	if hunter == null:
		return null
	_hunters.erase(unique_id)
	hunter_removed.emit(hunter)
	return hunter


## Generate + add in one step (debug, tests, new game).
func create_hunter(definition_id: StringName, rng: RandomNumberGenerator) -> HunterRuntime:
	var hunter := generate_candidate(definition_id, rng)
	return add_hunter(hunter) if hunter != null else null


func get_hunter(unique_id: StringName) -> HunterRuntime:
	return _hunters.get(unique_id)


func get_all() -> Array[HunterRuntime]:
	var result: Array[HunterRuntime] = []
	result.assign(_hunters.values())
	return result


func count() -> int:
	return _hunters.size()


## Hunters awake in the village (not on the Hibernation Mount, D83).
func get_active() -> Array[HunterRuntime]:
	var result: Array[HunterRuntime] = []
	for hunter: HunterRuntime in _hunters.values():
		if not hunter.hibernating:
			result.append(hunter)
	return result


func get_hibernating() -> Array[HunterRuntime]:
	var result: Array[HunterRuntime] = []
	for hunter: HunterRuntime in _hunters.values():
		if hunter.hibernating:
			result.append(hunter)
	return result


func count_active() -> int:
	return get_active().size()


func count_hibernating() -> int:
	return count() - count_active()


func get_definition(hunter: HunterRuntime) -> HunterDefinition:
	return _get_definition_by_id(hunter.definition_id)


## Final stat after all modifiers. `conditions` activates conditional modifiers (e.g. &"vs_boss").
func get_stat(hunter: HunterRuntime, stat: StringName, conditions: Array[StringName] = []) -> float:
	var definition := get_definition(hunter)
	if definition == null:
		return 0.0
	var base := 0.0
	var growth := 0.0
	match stat:
		MAX_HP:
			base = definition.base_hp
			growth = definition.hp_per_level
		ATTACK:
			base = definition.base_attack
			growth = definition.attack_per_level
		DEFENSE:
			base = definition.base_defense
			growth = definition.defense_per_level
		ATTACK_SPEED:
			base = definition.attack_speed
		MOVE_SPEED:
			base = definition.move_speed
		CRITICAL_CHANCE:
			base = definition.critical_chance
		CRITICAL_DAMAGE:
			base = definition.critical_damage
		MAX_MANA:
			base = definition.base_mana
			growth = definition.mana_per_level
		MANA_REGEN:
			base = definition.mana_regen
		_:
			if ADDITIVE_STATS.has(stat):
				return _stats.compute_stat(stat, 0.0, 0.0, hunter.level, get_modifiers(hunter), conditions)
			if not MULTIPLIER_STATS.has(stat):
				push_error("HunterService: unknown stat '%s'" % stat)
				return 0.0
			base = 1.0
	base *= 1.0 + hunter.stat_rolls.get(stat, 0.0)
	if stat == MAX_HP or stat == ATTACK or stat == DEFENSE:
		# Tier (D60) scales base and growth alike.
		var scale := Tier.stat_scale(hunter.tier)
		base *= scale
		growth *= scale
	return _stats.compute_stat(stat, base, growth, hunter.level, get_modifiers(hunter), conditions)


func get_modifiers(hunter: HunterRuntime) -> Array[StatModifier]:
	var modifiers: Array[StatModifier] = []
	for source in _modifier_sources:
		modifiers.append_array(source.call(hunter))
	return modifiers


## Re-emits hunter_changed after something that affects stats changed (equipment, mood…).
func notify_changed(hunter: HunterRuntime) -> void:
	hunter.current_hp = minf(hunter.current_hp, get_stat(hunter, MAX_HP))
	hunter_changed.emit(hunter)


## Debug/progression hook. Keeps current HP but clamps it to the new max.
func set_level(hunter: HunterRuntime, level: int) -> void:
	hunter.level = maxi(level, 1)
	notify_changed(hunter)


## Adds XP (scaled by the Hunter's xp_gain multiplier) and levels up while XP allows, up to
## `level_cap`. XP beyond the cap is kept for when the cap rises (PROGRESSION_SYSTEM.md).
## Returns the number of levels gained.
func add_xp(hunter: HunterRuntime, amount: int, level_cap: int) -> int:
	if amount <= 0:
		return 0
	if buildings != null:
		var bonus: float = buildings.get_effect(BuildingService.HERO_MONUMENT, BuildingService.TOWN_EXP_BONUS, 0.0)
		if bonus > 0.0:
			amount = roundi(amount * (1.0 + bonus))
	hunter.xp += maxi(roundi(amount * get_stat(hunter, XP_GAIN)), 0)
	var gained := 0
	while hunter.level < level_cap and hunter.xp >= _stats.required_xp(hunter.level):
		hunter.xp -= _stats.required_xp(hunter.level)
		hunter.level += 1
		gained += 1
		var max_hp := get_stat(hunter, MAX_HP)
		var healed := 0.0
		if not hunter.injured and hunter.current_hp > 0.0:
			healed = minf(max_hp * _config.level_up_heal_ratio, max_hp - hunter.current_hp)
			hunter.current_hp += healed
		hunter_leveled_up.emit(hunter, hunter.level, healed)
		if hunter.level in [10, 20, 50, 100]:
			hunter.record_chronicle("chronicle.level_milestone", str(hunter.level))
	if gained > 0:
		check_titles(hunter)
		hunter_changed.emit(hunter)
	return gained


func _get_title_modifiers(hunter: HunterRuntime) -> Array[StatModifier]:
	var result: Array[StatModifier] = []
	if hunter.equipped_title == &"":
		return result
	if TITLE_MODIFIERS.has(hunter.equipped_title):
		var info: Dictionary = TITLE_MODIFIERS[hunter.equipped_title]
		result.append(StatModifier.new(info.stat, info.type, info.value))
	return result


## Checks and unlocks achievement titles based on history and progression.
func check_titles(hunter: HunterRuntime) -> Array[StringName]:
	var newly_unlocked: Array[StringName] = []
	if hunter.history.get(HunterRuntime.BOSSES_DEFEATED, 0) >= 3 or hunter.history.get(HunterRuntime.EXPEDITIONS_COMPLETED, 0) >= 15:
		if not hunter.unlocked_titles.has(TITLE_GOBLIN_SLAYER):
			hunter.unlocked_titles.append(TITLE_GOBLIN_SLAYER)
			newly_unlocked.append(TITLE_GOBLIN_SLAYER)
	if hunter.history.get(HunterRuntime.TIMES_INJURED, 0) >= 3 or hunter.history.get(HunterRuntime.EXPEDITIONS_COMPLETED, 0) >= 20:
		if not hunter.unlocked_titles.has(TITLE_UNDYING):
			hunter.unlocked_titles.append(TITLE_UNDYING)
			newly_unlocked.append(TITLE_UNDYING)
	if hunter.history.get(&"arena_wins", 0) >= 5 or hunter.reincarnations >= 1:
		if not hunter.unlocked_titles.has(TITLE_ARENA_CHAMPION):
			hunter.unlocked_titles.append(TITLE_ARENA_CHAMPION)
			newly_unlocked.append(TITLE_ARENA_CHAMPION)
	if hunter.history.get(HunterRuntime.ACTIVITY_TICKS, 0) >= 30:
		if not hunter.unlocked_titles.has(TITLE_MASTER_GATHERER):
			hunter.unlocked_titles.append(TITLE_MASTER_GATHERER)
			newly_unlocked.append(TITLE_MASTER_GATHERER)
	if hunter.level >= 15 or hunter.history.get(HunterRuntime.EXPEDITIONS_COMPLETED, 0) >= 15:
		if not hunter.unlocked_titles.has(TITLE_VETERAN):
			hunter.unlocked_titles.append(TITLE_VETERAN)
			newly_unlocked.append(TITLE_VETERAN)
	if hunter.equipped_title == &"" and not hunter.unlocked_titles.is_empty():
		hunter.equipped_title = hunter.unlocked_titles[0]
		notify_changed(hunter)
	return newly_unlocked


func equip_title(hunter: HunterRuntime, title_id: StringName) -> bool:
	if title_id != &"" and not hunter.unlocked_titles.has(title_id):
		return false
	hunter.equipped_title = title_id
	notify_changed(hunter)
	return true


func set_lifecycle_state(hunter: HunterRuntime, state: HunterRuntime.LifecycleState) -> void:
	if hunter.state == state:
		return
	hunter.state = state
	hunter_changed.emit(hunter)


## Downed on an expedition: the Hospital starts the recovery timer on its next tick.
func mark_injured(hunter: HunterRuntime) -> void:
	hunter.injured = true
	hunter.current_hp = 0.0
	hunter.recovery_remaining = HunterRuntime.RECOVERY_NOT_STARTED
	hunter.state = HunterRuntime.LifecycleState.RECOVERING
	hunter_changed.emit(hunter)


## Fully recovered (Hospital finished / debug). A dead Hunter is revived instead, with
## `revive_ratio` of its HP, stamina and energy (D30).
func recover(hunter: HunterRuntime) -> void:
	var reviving := not hunter.alive
	hunter.alive = true
	hunter.injured = false
	hunter.recovery_remaining = 0.0
	hunter.current_hp = get_stat(hunter, MAX_HP) * (_config.revive_ratio if reviving else 1.0)
	if reviving:
		var floor_value := _config.needs_max * _config.revive_ratio
		hunter.stamina = maxf(hunter.stamina, floor_value)
		hunter.energy = maxf(hunter.energy, floor_value)
	hunter.state = HunterRuntime.LifecycleState.AVAILABLE
	hunter_changed.emit(hunter)


## Plain data for saving.
func to_dict() -> Dictionary:
	var list: Array = []
	for hunter in _hunters.values():
		list.append(hunter.to_dict())
	return {"next_id": _next_id, "hunters": list}


## Replaces the roster with saved data. Entries with a missing/duplicate id or an unknown
## class are dropped and reported. Does not emit hunter_added (not new recruits).
func from_dict(data: Dictionary, warnings: PackedStringArray) -> void:
	_hunters.clear()
	var highest := 0
	var entries: Variant = data.get("hunters", [])
	if not entries is Array:
		entries = []
	for entry in entries:
		if not entry is Dictionary:
			warnings.append("hunters: dropped a non-object entry")
			continue
		var hunter := HunterRuntime.from_dict(entry)
		if hunter.unique_id == &"" or _hunters.has(hunter.unique_id):
			warnings.append("hunters: dropped entry with missing/duplicate id '%s'" % hunter.unique_id)
			continue
		if get_definition(hunter) == null:
			warnings.append("hunters: dropped %s (unknown class '%s')" % [hunter.unique_id, hunter.definition_id])
			continue
		_hunters[hunter.unique_id] = hunter
		highest = maxi(highest, String(hunter.unique_id).trim_prefix("h_").to_int())
	_next_id = maxi(int(data.get("next_id", 1)), highest + 1)


func _pick_name(definition: HunterDefinition, rng: RandomNumberGenerator) -> String:
	var used: Dictionary[String, bool] = {}
	for hunter in _hunters.values():
		used[hunter.display_name] = true
	var free := Array(definition.name_pool).filter(func(name: String) -> bool: return not used.has(name))
	if not free.is_empty():
		return free[rng.randi_range(0, free.size() - 1)]
	return "%s #%d" % [definition.display_name, _next_id]


func _get_definition_by_id(definition_id: StringName) -> HunterDefinition:
	return _registry.find_def(&"hunter", definition_id) as HunterDefinition
