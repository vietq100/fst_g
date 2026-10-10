class_name ActivityService
extends RefCounted
## Town life between expeditions (HUNTER_LIFE_SYSTEM.md §4, DECISIONS.md D14, D24).
## Every tick (10 s of real time, also offline) each Hunter in town does an activity:
## Resting / Training / Socializing, or Recovering while injured.

signal activity_changed(hunter: HunterRuntime)

const RESTING := &"resting"
const SOCIALIZING := &"socializing"
const TRAINING := &"training"
const RECOVERING := &"recovering"

var _registry: Node
var _hunters: HunterService
var _traits: TraitService
var _mood: MoodService
var _bonds: BondService
var _stats: StatService
var _progress: ProgressService
var _config: GameConfig
var _accumulator := 0.0


func _init(registry: Node, hunters: HunterService, traits: TraitService, mood: MoodService,
		bonds: BondService, stats: StatService, progress: ProgressService, config: GameConfig) -> void:
	_registry = registry
	_hunters = hunters
	_traits = traits
	_mood = mood
	_bonds = bonds
	_stats = stats
	_progress = progress
	_config = config


func get_definition(activity_id: StringName) -> ActivityDefinition:
	return _registry.find_def(&"activity", activity_id) as ActivityDefinition


func get_tick_seconds() -> float:
	var resting := get_definition(RESTING)
	return resting.tick_seconds if resting != null else 10.0


## Advances real time; runs one activity tick per tick_seconds. Returns the ticks run.
func tick(seconds: float) -> int:
	_accumulator += seconds
	var ticks := 0
	var length := get_tick_seconds()
	while _accumulator >= length:
		_accumulator -= length
		_tick_once()
		ticks += 1
	return ticks


## Player choice: an assignable activity id, or &"" for automatic.
func set_assignment(hunter: HunterRuntime, activity_id: StringName) -> String:
	if activity_id != &"":
		var definition := get_definition(activity_id)
		if definition == null or not definition.player_assignable:
			return "Cannot assign '%s'" % activity_id
	hunter.assigned_activity = activity_id
	_update_activity(hunter)
	return ""


## What the Hunter does right now (D14).
func decide(hunter: HunterRuntime) -> StringName:
	if hunter.injured:
		return RECOVERING
	if hunter.assigned_activity != &"":
		return hunter.assigned_activity
	var hp_full := hunter.current_hp >= _hunters.get_stat(hunter, HunterService.MAX_HP) - 0.01
	if not hp_full or hunter.mood < _config.rest_when_mood_below:
		return RESTING
	return TRAINING


func is_in_town(hunter: HunterRuntime) -> bool:
	return hunter.expedition_id == &""


## Partial tick time (saved so short sessions add up).
func get_accumulator() -> float:
	return _accumulator


func set_accumulator(seconds: float) -> void:
	_accumulator = clampf(seconds, 0.0, get_tick_seconds())


func _tick_once() -> void:
	var socializing: Array[HunterRuntime] = []
	for hunter in _hunters.get_all():
		if not is_in_town(hunter):
			continue
		_update_activity(hunter)
		var definition := get_definition(hunter.activity)
		if definition == null:
			continue
		var rate := _traits.get_activity_rate(hunter, hunter.activity)
		var ticks: int = hunter.history.get(HunterRuntime.ACTIVITY_TICKS, 0) + 1
		hunter.history[HunterRuntime.ACTIVITY_TICKS] = ticks
		match hunter.activity:
			RESTING:
				var max_hp := _hunters.get_stat(hunter, HunterService.MAX_HP)
				hunter.current_hp = minf(hunter.current_hp + max_hp * definition.hp_percent * rate, max_hp)
				_mood.change(hunter, definition.mood * rate)
				hunter.history[HunterRuntime.CONSECUTIVE_EXPEDITIONS] = 0
				if ticks % _config.long_rest_ticks == 0:
					_mood.trait_event(hunter, TraitService.LONG_REST)
				_hunters.notify_changed(hunter)
			TRAINING:
				var xp := roundi(definition.xp * rate)
				_hunters.add_xp(hunter, xp, _stats.level_cap(_progress.town_level))
			SOCIALIZING:
				_mood.change(hunter, definition.mood * rate)
				socializing.append(hunter)
		if ticks % _config.activity_event_every_ticks == 0:
			_mood.trait_event(hunter, hunter.activity)
	_socialize(socializing)


## Socializing Hunters grow bonds with each other; bonded partners enjoy it more.
func _socialize(group: Array[HunterRuntime]) -> void:
	var bond := get_definition(SOCIALIZING).bond if get_definition(SOCIALIZING) != null else 0.0
	for i in group.size():
		for j in range(i + 1, group.size()):
			var a := group[i]
			var b := group[j]
			if _bonds.is_bonded(a.unique_id, b.unique_id):
				_mood.change(a, _config.bonded_social_mood)
				_mood.change(b, _config.bonded_social_mood)
			_bonds.add(a.unique_id, b.unique_id, bond)


func _update_activity(hunter: HunterRuntime) -> void:
	var activity := decide(hunter)
	if hunter.activity == activity:
		return
	hunter.activity = activity
	hunter.history[HunterRuntime.ACTIVITY_TICKS] = 0
	activity_changed.emit(hunter)
