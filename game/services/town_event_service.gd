class_name TownEventService
extends RefCounted
## Ambient town events (HUNTER_LIFE_SYSTEM.md): periodic occurrences that enliven the settlement.
## Wandering Caravan brings merchant opportunities; Village Festival boosts stamina and mood recovery.

signal event_started(event_type: int, duration: float)
signal event_ended(event_type: int)

enum EventType {
	NONE = 0,
	WANDERING_CARAVAN = 1,
	VILLAGE_FESTIVAL = 2,
	BLOOD_MOON = 3,
}

const DEFAULT_EVENT_DURATION := 180.0
const BLOOD_MOON_DURATION := 120.0
const MIN_INTERVAL := 240.0
const MAX_INTERVAL := 480.0

var active_event: int = EventType.NONE
var remaining_time: float = 0.0
var _next_event_timer: float = 180.0
var _rng: RandomNumberGenerator
var _hunters: HunterService
var wallet: WalletService
var inventory: InventoryService

signal invasion_repelled(reward_gold: int, tickets: int)


func _init(hunters: HunterService, rng: RandomNumberGenerator) -> void:
	_hunters = hunters
	_rng = rng
	_next_event_timer = _rng.randf_range(MIN_INTERVAL, MAX_INTERVAL)


func tick(delta: float) -> void:
	if active_event != EventType.NONE:
		remaining_time -= delta
		if active_event == EventType.VILLAGE_FESTIVAL:
			_apply_festival_tick(delta)
		elif active_event == EventType.BLOOD_MOON:
			_apply_blood_moon_tick(delta)
		if remaining_time <= 0.0:
			var finished := active_event
			if finished == EventType.BLOOD_MOON:
				_on_blood_moon_finished()
			active_event = EventType.NONE
			remaining_time = 0.0
			_next_event_timer = _rng.randf_range(MIN_INTERVAL, MAX_INTERVAL)
			event_ended.emit(finished)
	else:
		_next_event_timer -= delta
		if _next_event_timer <= 0.0:
			var roll := _rng.randi_range(1, 3)
			var dur := BLOOD_MOON_DURATION if roll == EventType.BLOOD_MOON else DEFAULT_EVENT_DURATION
			start_event(roll, dur)


func start_event(event_type: int, duration: float = DEFAULT_EVENT_DURATION) -> void:
	active_event = event_type
	remaining_time = duration
	event_started.emit(active_event, remaining_time)


func is_festival_active() -> bool:
	return active_event == EventType.VILLAGE_FESTIVAL


func is_caravan_active() -> bool:
	return active_event == EventType.WANDERING_CARAVAN


func is_blood_moon() -> bool:
	return active_event == EventType.BLOOD_MOON


func _apply_festival_tick(delta: float) -> void:
	if _hunters == null:
		return
	for hunter in _hunters.get_active():
		if hunter.state == HunterRuntime.LifecycleState.AVAILABLE:
			hunter.stamina = minf(hunter.stamina + 2.0 * delta, 100.0)
			hunter.mood = minf(hunter.mood + 1.0 * delta, 100.0)


func _apply_blood_moon_tick(delta: float) -> void:
	if _hunters == null:
		return
	for hunter in _hunters.get_active():
		if hunter.state == HunterRuntime.LifecycleState.AVAILABLE and hunter.stamina > 10.0:
			hunter.stamina = maxf(hunter.stamina - 0.5 * delta, 0.0)


func _on_blood_moon_finished() -> void:
	var reward_gold := 150
	var reward_tickets := 2
	if wallet != null:
		wallet.add(reward_gold)
		wallet.add_tickets(reward_tickets)
	if inventory != null:
		inventory.add(&"dark_essence", 5)
	if _hunters != null:
		for hunter in _hunters.get_active():
			if hunter.state == HunterRuntime.LifecycleState.AVAILABLE:
				hunter.record_chronicle("chronicle.blood_moon_defense")
				hunter.mood = minf(hunter.mood + 10.0, 100.0)
				_hunters.notify_changed(hunter)
	invasion_repelled.emit(reward_gold, reward_tickets)


func to_dict() -> Dictionary:
	return {
		"active_event": active_event,
		"remaining_time": remaining_time,
		"next_event_timer": _next_event_timer,
	}


func from_dict(data: Dictionary) -> void:
	active_event = clampi(int(data.get("active_event", EventType.NONE)), 0, 3)
	remaining_time = maxf(float(data.get("remaining_time", 0.0)), 0.0)
	_next_event_timer = maxf(float(data.get("next_event_timer", 180.0)), 0.0)
