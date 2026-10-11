class_name NeedsService
extends RefCounted
## Stamina and energy (AUTONOMY_SYSTEM.md → Needs, BALANCE.md → Needs, DECISIONS.md D31, D32).
## Changed once per activity tick according to what the Hunter does; meals are paid from the
## purse for food from the village stock (SupplyService, D40). Empty stamina slows the Hunter;
## empty energy drains HP and mood.
## Decisions (sleep / eat) are asked by ActivityService now and by the Hunter brain later.

signal needs_changed(hunter: HunterRuntime)

var _hunters: HunterService
var _housing: HousingService
var _supply: SupplyService
## Optional (set by GameManager): food in the Hunter's own bag comes first (D46).
var talents: TalentService
var _mood: MoodService
var _config: GameConfig
## Counters since the last `take_report()` (offline summary).
var _meals := 0
var _hungry_ticks := 0


func _init(hunters: HunterService, housing: HousingService, supply: SupplyService, mood: MoodService,
		config: GameConfig) -> void:
	_hunters = hunters
	_housing = housing
	_supply = supply
	_mood = mood
	_config = config
	_hunters.add_modifier_source(get_modifiers)


func is_exhausted(hunter: HunterRuntime) -> bool:
	return hunter.stamina <= 0.0


func is_starving(hunter: HunterRuntime) -> bool:
	return hunter.energy <= 0.0


## Sleep below the threshold; once asleep, keep sleeping until rested.
func wants_sleep(hunter: HunterRuntime, sleeping: bool) -> bool:
	return hunter.stamina < (_config.wake_at_stamina if sleeping else _config.sleep_below_stamina)


func is_hungry(hunter: HunterRuntime) -> bool:
	return hunter.energy < _config.eat_below_energy


## Hungry, and there is food in its bag or food it can pay for.
func wants_meal(hunter: HunterRuntime) -> bool:
	return is_hungry(hunter) and (_has_bag_food(hunter) or _supply.best_food(hunter) != null)


## One tick of needs. `active`: walking / hunting / training / carrying. `sleeping`: in a bed
## (or outdoors without one).
func tick_hunter(hunter: HunterRuntime, active: bool, sleeping: bool) -> void:
	var was_exhausted := is_exhausted(hunter)
	var top := _config.needs_max
	if sleeping:
		var in_bed := _housing.get_home(hunter) != null
		hunter.stamina = minf(hunter.stamina + (_config.stamina_sleep_bed if in_bed else _config.stamina_sleep_outdoors), top)
		if not in_bed:
			_mood.change(hunter, _config.outdoors_sleep_mood)
		hunter.energy = maxf(hunter.energy - _config.energy_drain_sleeping, 0.0)
	else:
		if active:
			hunter.stamina = maxf(hunter.stamina - _config.stamina_drain_active, 0.0)
		hunter.energy = maxf(hunter.energy - _config.energy_drain, 0.0)
	if is_starving(hunter):
		_hungry_ticks += 1
		var max_hp := _hunters.get_stat(hunter, HunterService.MAX_HP)
		if hunter.current_hp > 1.0:
			hunter.current_hp = maxf(hunter.current_hp - max_hp * _config.starving_hp_ratio, 1.0)
		_mood.change(hunter, _config.starving_mood)
	if was_exhausted != is_exhausted(hunter):
		# Stats change (speed penalties).
		_hunters.notify_changed(hunter)
	needs_changed.emit(hunter)


## Eats from its own bag first, otherwise buys and eats one portion of the best food it can
## afford. Returns true when eaten.
func eat(hunter: HunterRuntime) -> bool:
	if talents != null and talents.eat_from_bag(hunter) > 0.0:
		_meals += 1
		needs_changed.emit(hunter)
		return true
	var food := _supply.buy_food(hunter)
	if food == null:
		return false
	hunter.energy = minf(hunter.energy + food.energy, _config.needs_max)
	_meals += 1
	needs_changed.emit(hunter)
	return true


## Revival / restore helper: sets both needs to a share of the maximum.
func set_ratio(hunter: HunterRuntime, ratio: float) -> void:
	hunter.stamina = _config.needs_max * ratio
	hunter.energy = _config.needs_max * ratio
	needs_changed.emit(hunter)
	_hunters.notify_changed(hunter)


func _has_bag_food(hunter: HunterRuntime) -> bool:
	return talents != null and talents.has_in_bag(hunter, TalentService.Kind.FOOD)


func get_modifiers(hunter: HunterRuntime) -> Array[StatModifier]:
	var modifiers: Array[StatModifier] = []
	if is_exhausted(hunter):
		modifiers.append(_percent(HunterService.MOVE_SPEED, _config.exhausted_move_speed))
		modifiers.append(_percent(HunterService.ATTACK_SPEED, _config.exhausted_attack_speed))
	return modifiers


## {"meals": n, "hungry_ticks": n} since the last call; resets the counters.
func take_report() -> Dictionary:
	var report := {"meals": _meals, "hungry_ticks": _hungry_ticks}
	_meals = 0
	_hungry_ticks = 0
	return report


static func _percent(stat: StringName, value: float) -> StatModifier:
	var modifier := StatModifier.new()
	modifier.stat = stat
	modifier.type = StatModifier.Type.PERCENT
	modifier.value = value
	return modifier
