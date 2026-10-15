class_name CorpseService
extends RefCounted
## Death and bodies (AUTONOMY_SYSTEM.md → Bodies, DECISIONS.md D30, BALANCE.md → Bodies).
## A Hunter at 0 HP dies and leaves a body where it fell. A free Hunter is assigned as carrier,
## fetches the body and drags it to the Temple at a slower speed; there the dead Hunter becomes
## a patient (TempleService) and is revived with part of its HP and needs (HunterService.recover).
## Village staff (D43) carry first, for a fee per trip paid by the treasury; Hunters carry for free
## when no staff member is free or the treasury cannot pay.
## Carrier assignments are not saved: they are planned again after loading.

signal hunter_died(hunter: HunterRuntime)
signal carrier_assigned(body: HunterRuntime, carrier: HunterRuntime)
## A staff member was sent (fee paid).
signal staff_dispatched(body: HunterRuntime, staff_id: StringName)
signal body_picked_up(body: HunterRuntime, carrier: HunterRuntime)
## The carrier died or gave up: the body lies at its current position again.
signal body_dropped(body: HunterRuntime)
signal body_delivered(body: HunterRuntime)

var _hunters: HunterService
var _wallet: WalletService
var _config: GameConfig
var _staff_ids: Array[StringName] = []
## Body id -> carrier id (a Hunter's unique id or a staff id).
var _carriers: Dictionary[StringName, StringName] = {}
## Bodies currently being dragged (picked up), by body id.
var _carried: Dictionary[StringName, bool] = {}


func _init(hunters: HunterService, wallet: WalletService, config: GameConfig) -> void:
	_hunters = hunters
	_wallet = wallet
	_config = config
	for i in config.staff_count:
		_staff_ids.append(StringName("staff_%d" % (i + 1)))
	_hunters.add_modifier_source(get_modifiers)


## 0 HP in the world: the Hunter dies where it stands (no permanent death).
func die(hunter: HunterRuntime, at: Vector2) -> void:
	if not hunter.alive:
		return
	# A carrier that dies drops its body (D30).
	var carried := get_body_of(hunter)
	if carried != null:
		drop(carried, at)
	hunter.alive = false
	hunter.current_hp = 0.0
	hunter.task = &""
	hunter.activity = &""
	hunter.world_position = at
	hunter.state = HunterRuntime.LifecycleState.RECOVERING
	hunter_died.emit(hunter)
	_hunters.notify_changed(hunter)


## Bodies still lying in the world or being carried (not yet at the Temple).
func get_bodies() -> Array[HunterRuntime]:
	return _hunters.get_all().filter(func(h: HunterRuntime) -> bool: return is_body(h))


func is_body(hunter: HunterRuntime) -> bool:
	return not hunter.alive and not hunter.injured and hunter.expedition_id == &""


## A free Hunter may fetch a body: alive, healthy, in the world, rested enough, not asleep,
## not carrying already.
func can_carry(hunter: HunterRuntime) -> bool:
	return hunter.alive and not hunter.injured and hunter.expedition_id == &"" \
		and hunter.stamina >= _config.carrier_min_stamina and hunter.activity != ActivityService.SLEEPING \
		and get_body_of(hunter) == null


func assign(body: HunterRuntime, carrier: HunterRuntime) -> String:
	if not is_body(body):
		return Loc.t("err.corpse.not_body")
	if has_carrier(body):
		return Loc.t("err.corpse.has_carrier")
	if not can_carry(carrier):
		return Loc.t("err.corpse.cannot_carry", {"name": carrier.display_name})
	_carriers[body.unique_id] = carrier.unique_id
	carrier_assigned.emit(body, carrier)
	return ""


## The Hunter carrying (or fetching) this body; null when nobody or a staff member does.
func get_carrier(body: HunterRuntime) -> HunterRuntime:
	var carrier_id := get_carrier_id(body)
	return _hunters.get_hunter(carrier_id) if carrier_id != &"" and not is_staff(carrier_id) else null


## Hunter id or staff id of the carrier, &"" if none.
func get_carrier_id(body: HunterRuntime) -> StringName:
	return _carriers.get(body.unique_id, &"")


func has_carrier(body: HunterRuntime) -> bool:
	return _carriers.has(body.unique_id)


## The body this Hunter is assigned to (fetching or dragging), or null.
func get_body_of(carrier: HunterRuntime) -> HunterRuntime:
	return get_body_of_id(carrier.unique_id)


func get_body_of_id(carrier_id: StringName) -> HunterRuntime:
	for body_id in _carriers:
		if _carriers[body_id] == carrier_id:
			return _hunters.get_hunter(body_id)
	return null


# --- Village staff (D43) --------------------------------------------------------------------------

func get_staff_ids() -> Array[StringName]:
	return _staff_ids


func is_staff(carrier_id: StringName) -> bool:
	return _staff_ids.has(carrier_id)


func is_staff_free(staff_id: StringName) -> bool:
	return is_staff(staff_id) and get_body_of_id(staff_id) == null


func get_free_staff() -> Array[StringName]:
	return _staff_ids.filter(func(id: StringName) -> bool: return is_staff_free(id))


## Sends a staff member for a body; the treasury pays the fee now. Returns the error.
func assign_staff(body: HunterRuntime, staff_id: StringName) -> String:
	if not is_body(body):
		return Loc.t("err.corpse.not_body")
	if has_carrier(body):
		return Loc.t("err.corpse.has_carrier")
	if not is_staff_free(staff_id):
		return Loc.t("err.corpse.staff_busy")
	if not _wallet.spend(_config.staff_fee):
		return Loc.t("err.corpse.staff_fee", {"gold": _config.staff_fee})
	_carriers[body.unique_id] = staff_id
	staff_dispatched.emit(body, staff_id)
	return ""


func describe_staff() -> String:
	return Loc.t("game.corpse.staff_info", {"total": _staff_ids.size(), "free": get_free_staff().size(),
		"gold": _config.staff_fee})


func is_carried(body: HunterRuntime) -> bool:
	return _carried.has(body.unique_id)


## The carrier reached the body and starts dragging it.
func pick_up(body: HunterRuntime) -> void:
	if not has_carrier(body) or is_carried(body):
		return
	_carried[body.unique_id] = true
	var carrier := get_carrier(body)
	if carrier != null:
		_hunters.notify_changed(carrier)
	body_picked_up.emit(body, carrier)


## The body is let go at `at` (carrier died, or gave up); a new carrier is needed.
func drop(body: HunterRuntime, at: Vector2) -> void:
	var carrier := get_carrier(body)
	_carriers.erase(body.unique_id)
	_carried.erase(body.unique_id)
	body.world_position = at
	if carrier != null:
		_hunters.notify_changed(carrier)
	body_dropped.emit(body)


## At the Temple: the body becomes a patient; the carrier is free again.
func deliver(body: HunterRuntime) -> void:
	if not is_body(body):
		return
	var carrier := get_carrier(body)
	_carriers.erase(body.unique_id)
	_carried.erase(body.unique_id)
	if carrier != null:
		_hunters.notify_changed(carrier)
	_hunters.mark_injured(body)
	body_delivered.emit(body)


## Dragging a body slows the carrier (BALANCE.md → Bodies).
func get_modifiers(hunter: HunterRuntime) -> Array[StatModifier]:
	var modifiers: Array[StatModifier] = []
	var body := get_body_of(hunter)
	if body != null and is_carried(body):
		var modifier := StatModifier.new()
		modifier.stat = HunterService.MOVE_SPEED
		modifier.type = StatModifier.Type.PERCENT
		modifier.value = _config.carry_speed_ratio - 1.0
		modifiers.append(modifier)
	return modifiers


## Forgets every assignment (new game / load).
func clear() -> void:
	_carriers.clear()
	_carried.clear()
