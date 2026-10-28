class_name MoodService
extends RefCounted
## Hunter mood 0..100 (HUNTER_LIFE_SYSTEM.md §2, BALANCE.md → Mood, DECISIONS.md D13, D26).
## High/Low mood adds stat and XP modifiers; expedition results and trait likes/dislikes
## move it. Low mood never blocks anything.

signal mood_changed(hunter: HunterRuntime, mood: float)

enum State { LOW, NORMAL, HIGH }

var _hunters: HunterService
var _traits: TraitService
var _config: GameConfig
var buildings: BuildingService


func _init(hunters: HunterService, traits: TraitService, config: GameConfig) -> void:
	_hunters = hunters
	_traits = traits
	_config = config
	_hunters.add_modifier_source(get_modifiers)


func get_state(hunter: HunterRuntime) -> State:
	if hunter.mood >= _config.mood_high_threshold:
		return State.HIGH
	if hunter.mood < _config.mood_low_threshold:
		return State.LOW
	return State.NORMAL


func get_modifiers(hunter: HunterRuntime) -> Array[StatModifier]:
	var modifiers: Array[StatModifier] = []
	match get_state(hunter):
		State.HIGH:
			modifiers.append_array(_percent([HunterService.ATTACK, HunterService.DEFENSE], _config.mood_high_stat_bonus))
			modifiers.append_array(_percent([HunterService.XP_GAIN], _config.mood_high_xp_bonus))
		State.LOW:
			modifiers.append_array(_percent([HunterService.ATTACK, HunterService.DEFENSE], _config.mood_low_stat_penalty))
			modifiers.append_array(_percent([HunterService.XP_GAIN], _config.mood_low_xp_penalty))
	return modifiers


func change(hunter: HunterRuntime, amount: float) -> void:
	if is_zero_approx(amount):
		return
	if amount > 0.0 and buildings != null:
		var bonus: float = buildings.get_effect(BuildingService.TOWN_FOUNTAIN, BuildingService.MOOD_AURA, 0.0)
		if bonus > 0.0:
			amount *= (1.0 + bonus)
	var before := get_state(hunter)
	hunter.mood = clampf(hunter.mood + amount, 0.0, _config.mood_max)
	mood_changed.emit(hunter, hunter.mood)
	if get_state(hunter) != before:
		# Mood state changes stats.
		_hunters.notify_changed(hunter)


## Applies trait likes (+5 each) and dislikes (-5 each) for an event tag.
func trait_event(hunter: HunterRuntime, tag: StringName) -> void:
	var reactions := _traits.count_reactions(hunter, tag)
	change(hunter, reactions.x * _config.mood_trait_like + reactions.y * _config.mood_trait_dislike)


## Mood after an expedition for the party and for Hunters who stayed home (D26).
func on_expedition_finished(run: ExpeditionRun, definition: ExpeditionDefinition) -> void:
	var success := run.phase == ExpeditionRun.Phase.SUCCESS
	var party: Array[HunterRuntime] = []
	for hunter_id in run.party_ids:
		var hunter := _hunters.get_hunter(hunter_id)
		if hunter != null:
			party.append(hunter)
	var reckless_count := party.filter(func(h: HunterRuntime) -> bool: return _traits.has_trait(h, TraitService.RECKLESS)).size()
	for hunter in party:
		change(hunter, _config.mood_success if success else _config.mood_failure)
		if run.downed_ids.has(hunter.unique_id):
			change(hunter, _config.mood_injured)
		trait_event(hunter, TraitService.SUCCESS if success else TraitService.FAILURE)
		if run.boss_reached:
			trait_event(hunter, TraitService.BOSS_FIGHT)
		if success:
			trait_event(hunter, TraitService.BOSS_KILL)
		if definition != null and hunter.level < definition.recommended_level:
			trait_event(hunter, TraitService.ABOVE_LEVEL)
		var other_reckless := reckless_count - (1 if _traits.has_trait(hunter, TraitService.RECKLESS) else 0)
		if other_reckless > 0:
			trait_event(hunter, TraitService.RECKLESS_PARTNER)
		var in_a_row: int = hunter.history.get(HunterRuntime.CONSECUTIVE_EXPEDITIONS, 0) + 1
		hunter.history[HunterRuntime.CONSECUTIVE_EXPEDITIONS] = in_a_row
		if in_a_row >= _config.back_to_back_expeditions:
			trait_event(hunter, TraitService.BACK_TO_BACK)
		if in_a_row >= _config.overwork_expeditions:
			change(hunter, _config.mood_overwork)
		hunter.history[HunterRuntime.IDLE_CYCLES] = 0
	for hunter in _hunters.get_all():
		if party.has(hunter) or hunter.hibernating:
			continue
		var idle: int = hunter.history.get(HunterRuntime.IDLE_CYCLES, 0) + 1
		if idle >= _config.idle_cycles_for_event:
			trait_event(hunter, TraitService.IDLE_CYCLES)
			idle = 0
		hunter.history[HunterRuntime.IDLE_CYCLES] = idle


static func _percent(stats: Array[StringName], value: float) -> Array[StatModifier]:
	var result: Array[StatModifier] = []
	for stat in stats:
		var modifier := StatModifier.new()
		modifier.stat = stat
		modifier.type = StatModifier.Type.PERCENT
		modifier.value = value
		result.append(modifier)
	return result
