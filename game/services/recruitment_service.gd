class_name RecruitmentService
extends RefCounted
## Summoning, hibernation and dismissal (DECISIONS.md D83; D11 / D58 before it).
## - **Summon** at the Hunter Gate for tickets (`WalletService.summon_tickets`): a random class
##   and a rolled tier, joining at once. The newcomer is awake when an active slot and a bed are
##   free, otherwise it goes to sleep on the Hibernation Mount.
## - **Active cap**: `config.active_hunter_cap` (24), never above the Town Hall's capacity;
##   **hibernation cap**: `config.hibernation_cap` (100). `hibernate` / `activate` / `swap` move
##   Hunters between the two (they walk there themselves, HunterBrain).
## - The Tavern's gold board (candidates, `recruit`) stays as a second way in; it counts against
##   the active cap like a summon.
## Expelling sends a Hunter away for good.

signal candidates_changed
## Emitted after the Hunter joined the roster (starting gear and traits hook in here).
signal hunter_recruited(hunter: HunterRuntime)
## Emitted after the Hunter was taken off the roster.
signal hunter_dismissed(hunter: HunterRuntime)
## A Hunter fell asleep on the Mount or woke up (D83); its brain walks it there / back.
signal hibernation_changed(hunter: HunterRuntime)
## A confirmed batch joined the roster, in arrival order (the world lets them down one by one).
signal arrivals_confirmed(hunters: Array[HunterRuntime])
signal autosave_requested(reason: StringName)

## Fallbacks when no config is given (standalone service, tests).
const DEFAULT_ACTIVE_CAP := 24
const DEFAULT_HIBERNATION_CAP := 100
const DEFAULT_TICKET_COST := 1

var candidates: Array[HunterRuntime] = []
## Beds (DECISIONS.md D32); optional so the service also works standalone.
var housing: HousingService
## Bodies and carriers (D30); optional.
var corpses: CorpseService
## Summoning numbers (D83); optional.
var config: GameConfig
## Hunters called but not yet confirmed (tickets spent; the reveal is showing them).
var pending: Array[HunterRuntime] = []
## The last confirmed batch, in arrival order (the Gate sheet's "just arrived").
var last_arrivals: Array[HunterRuntime] = []
## Unique ids of confirmed Hunters still to be let down at the Gate (WorldMap plays their arrival).
var _arriving: Dictionary = {}

var _registry: Node
var _hunters: HunterService
var _buildings: BuildingService
var _wallet: WalletService
var _rng: RandomNumberGenerator
## Callables `func(candidate: HunterRuntime) -> void` run on every new candidate (traits).
var _candidate_decorators: Array[Callable] = []


func _init(registry: Node, hunters: HunterService, buildings: BuildingService, wallet: WalletService,
		rng: RandomNumberGenerator) -> void:
	_registry = registry
	_hunters = hunters
	_buildings = buildings
	_wallet = wallet
	_rng = rng


func add_candidate_decorator(decorator: Callable) -> void:
	_candidate_decorators.append(decorator)


# --- Caps ------------------------------------------------------------------------------------------

## Town Hall capacity (D11), the roster cap of the gold board.
func get_capacity() -> int:
	return int(_buildings.get_effect(BuildingService.TOWN_HALL, BuildingService.HUNTER_CAPACITY))


## Hunters awake at once: the Town Hall capacity, never above the configured cap (24).
func get_active_cap() -> int:
	var cap := config.active_hunter_cap if config != null else DEFAULT_ACTIVE_CAP
	return mini(get_capacity(), cap)


func get_hibernation_cap() -> int:
	return config.hibernation_cap if config != null else DEFAULT_HIBERNATION_CAP


func get_ticket_cost() -> int:
	return config.summon_ticket_cost if config != null else DEFAULT_TICKET_COST


func has_active_room() -> bool:
	return _hunters.count_active() < get_active_cap()


func has_hibernation_room() -> bool:
	return _hunters.count_hibernating() < get_hibernation_cap()


# --- Summoning (D83) -------------------------------------------------------------------------------

## Empty string when a summon can go ahead, otherwise the reason: no tickets, or both the village
## and the Mount are full (pending, unconfirmed newcomers count as already there).
func can_summon() -> String:
	if not _wallet.can_spend_tickets(get_ticket_cost()):
		return Loc.t("err.summon.no_tickets", {"tickets": get_ticket_cost()})
	if _awake_room() <= 0 and _asleep_room() <= 0:
		return Loc.t("err.summon.everything_full", {"active": get_active_cap(), "asleep": get_hibernation_cap()})
	return ""


## Active slots (and beds) still free, the pending newcomers who will be awake deducted.
func _awake_room() -> int:
	var pending_awake := pending.filter(func(h: HunterRuntime) -> bool: return not h.hibernating).size()
	var room := get_active_cap() - _hunters.count_active() - pending_awake
	if housing != null:
		room = mini(room, housing.get_free_beds() - pending_awake)
	return room


func _asleep_room() -> int:
	var pending_asleep := pending.filter(func(h: HunterRuntime) -> bool: return h.hibernating).size()
	return get_hibernation_cap() - _hunters.count_hibernating() - pending_asleep


## Rolls one newcomer and spends its ticket; awake when the village has room for one more,
## asleep otherwise. Null when `can_summon` refuses or no base class exists.
func _call_one() -> HunterRuntime:
	if not can_summon().is_empty():
		return null
	var class_ids := _base_class_ids()
	if class_ids.is_empty():
		return null
	_wallet.spend_tickets(get_ticket_cost())
	var newcomer := _hunters.generate_candidate(class_ids[_rng.randi_range(0, class_ids.size() - 1)], _rng)
	for decorator in _candidate_decorators:
		decorator.call(newcomer)
	newcomer.hibernating = _awake_room() <= 0
	if newcomer.hibernating:
		newcomer.task = HunterRuntime.HIBERNATING
	return newcomer


## Calls up to `count` Hunters for the reveal: tickets are spent and their fate (village / Mount)
## fixed, but they join only on `confirm_arrivals`. Returns those called (may be fewer).
func summon_batch(count: int) -> Array[HunterRuntime]:
	var called: Array[HunterRuntime] = []
	for i in maxi(count, 0):
		var newcomer := _call_one()
		if newcomer == null:
			break
		pending.append(newcomer)
		called.append(newcomer)
	return called


## The pending newcomers join the roster in order; the world lets them down at the Gate one by one
## (`is_arriving` / `mark_arrived`). Returns them.
func confirm_arrivals() -> Array[HunterRuntime]:
	var joined: Array[HunterRuntime] = []
	for newcomer in pending:
		if newcomer.unique_id == &"":
			newcomer.unique_id = _hunters.next_id()
		_arriving[newcomer.unique_id] = true
		var hunter := _hunters.add_hunter(newcomer)
		joined.append(hunter)
		hunter_recruited.emit(hunter)
	pending.clear()
	if joined.is_empty():
		return joined
	last_arrivals = joined.duplicate()
	arrivals_confirmed.emit(joined)
	autosave_requested.emit(&"summon")
	return joined


func is_arriving(unique_id: StringName) -> bool:
	return _arriving.has(unique_id)


func mark_arrived(unique_id: StringName) -> void:
	_arriving.erase(unique_id)


## Calls one Hunter through the Gate for tickets and lets it join at once (no reveal: tests,
## debug). Awake when the village has room, asleep on the Mount otherwise. Null when refused.
func summon() -> HunterRuntime:
	var newcomer := _call_one()
	if newcomer == null:
		return null
	if newcomer.unique_id == &"":
		newcomer.unique_id = _hunters.next_id()
	_arriving[newcomer.unique_id] = true
	var hunter := _hunters.add_hunter(newcomer)
	hunter_recruited.emit(hunter)
	autosave_requested.emit(&"summon")
	return hunter


## Summons up to `count` Hunters; stops at the first refusal. Returns those who came.
func summon_many(count: int) -> Array[HunterRuntime]:
	var called: Array[HunterRuntime] = []
	for i in maxi(count, 0):
		var hunter := summon()
		if hunter == null:
			break
		called.append(hunter)
	return called


func _base_class_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id: StringName in _registry.get_ids(&"hunter"):
		if (_registry.find_def(&"hunter", id) as HunterDefinition).promotion_of == &"":
			ids.append(id)
	return ids


# --- Hibernation (D83) -----------------------------------------------------------------------------

## Empty string when the Hunter can go to sleep on the Mount, otherwise the reason.
func can_hibernate(hunter: HunterRuntime) -> String:
	if hunter == null or _hunters.get_hunter(hunter.unique_id) == null:
		return Loc.t("err.recruit.unknown_hunter")
	if hunter.hibernating:
		return Loc.t("err.hibernate.already")
	if hunter.expedition_id != &"":
		return Loc.t("err.recruit.on_dungeon")
	if not hunter.alive:
		return Loc.t("err.recruit.dead")
	if corpses != null and corpses.get_body_of(hunter) != null:
		return Loc.t("err.recruit.carrying")
	if not has_hibernation_room():
		return Loc.t("err.hibernate.mount_full", {"max": get_hibernation_cap()})
	return ""


## Sends a Hunter to sleep on the Mount: it drops its duty and activity, gives up its bed and
## walks there (HunterBrain). Returns the reason when refused.
func hibernate(hunter: HunterRuntime) -> String:
	var reason := can_hibernate(hunter)
	if not reason.is_empty():
		return reason
	hunter.hibernating = true
	hunter.task = HunterRuntime.HIBERNATING
	hunter.activity = &""
	hunter.assigned_activity = &""
	hunter.home_id = &""
	if housing != null:
		housing.assign_beds()
	_hunters.notify_changed(hunter)
	hibernation_changed.emit(hunter)
	autosave_requested.emit(&"hibernate")
	return ""


## Empty string when the sleeper can wake into the village, otherwise the reason.
func can_activate(hunter: HunterRuntime) -> String:
	if hunter == null or _hunters.get_hunter(hunter.unique_id) == null:
		return Loc.t("err.recruit.unknown_hunter")
	if not hunter.hibernating:
		return Loc.t("err.hibernate.awake")
	if not has_active_room():
		return Loc.t("err.recruit.roster_full", {"count": _hunters.count_active(), "max": get_active_cap()})
	if housing != null and housing.get_free_beds() <= 0:
		return Loc.t("err.recruit.no_bed")
	return ""


## Wakes a sleeper: it walks back over the bridge into the village and takes a bed.
func activate(hunter: HunterRuntime) -> String:
	var reason := can_activate(hunter)
	if not reason.is_empty():
		return reason
	hunter.hibernating = false
	hunter.task = &""
	if housing != null:
		housing.assign_beds()
	_hunters.notify_changed(hunter)
	hibernation_changed.emit(hunter)
	autosave_requested.emit(&"activate")
	return ""


## Trades places: `awake` goes to sleep and `sleeper` wakes up; both walk. Returns the reason
## when either step is refused (nothing changes then).
func swap(awake: HunterRuntime, sleeper: HunterRuntime) -> String:
	var reason := can_hibernate(awake)
	if not reason.is_empty():
		return reason
	if sleeper == null or not sleeper.hibernating:
		return Loc.t("err.hibernate.awake")
	if housing != null and housing.get_free_beds() <= 0 and awake.home_id == &"":
		return Loc.t("err.recruit.no_bed")
	hibernate(awake)
	var woke := activate(sleeper)
	if not woke.is_empty():
		# Undo: the first one keeps its place.
		activate(awake)
		return woke
	return ""


# --- The Tavern's gold board (D11, kept) ------------------------------------------------------------

func get_refresh_cost() -> int:
	return int(_buildings.get_effect(BuildingService.TAVERN, BuildingService.REFRESH_COST))


## Free refresh (after an expedition returns / new game).
func refresh_candidates() -> void:
	candidates.clear()
	var class_ids := _base_class_ids()
	if class_ids.is_empty():
		return
	var count := int(_buildings.get_effect(BuildingService.TAVERN, BuildingService.CANDIDATE_COUNT))
	for i in count:
		var candidate := _hunters.generate_candidate(class_ids[_rng.randi_range(0, class_ids.size() - 1)], _rng)
		for decorator in _candidate_decorators:
			decorator.call(candidate)
		candidates.append(candidate)
	candidates_changed.emit()


func paid_refresh() -> bool:
	if not _wallet.spend(get_refresh_cost()):
		return false
	refresh_candidates()
	return true


func get_recruit_cost(index: int) -> int:
	if index < 0 or index >= candidates.size():
		return 0
	var definition := _hunters.get_definition(candidates[index])
	# Higher tiers cost more (D60).
	return roundi(definition.recruit_cost * Tier.reward_scale(candidates[index].tier)) if definition != null else 0


## Empty string when candidate `index` can be hired, otherwise the reason. Hiring needs an active
## slot (the board never sends anyone to the Mount) and a bed.
func can_recruit(index: int) -> String:
	if index < 0 or index >= candidates.size():
		return Loc.t("err.recruit.no_candidate")
	if not has_active_room():
		return Loc.t("err.recruit.roster_full", {"count": _hunters.count_active(), "max": get_active_cap()})
	if housing != null and housing.get_free_beds() <= 0:
		return Loc.t("err.recruit.no_bed")
	if not _wallet.can_spend(get_recruit_cost(index)):
		return Loc.t("ui.common.needs_gold", {"gold": get_recruit_cost(index)})
	return ""


func recruit(index: int) -> HunterRuntime:
	if not can_recruit(index).is_empty():
		return null
	_wallet.spend(get_recruit_cost(index))
	var hunter := _hunters.add_hunter(candidates[index])
	candidates.remove_at(index)
	candidates_changed.emit()
	hunter_recruited.emit(hunter)
	autosave_requested.emit(&"recruitment")
	return hunter


# --- Dismissal (D58) -------------------------------------------------------------------------------

## Empty string when the Hunter can be expelled, otherwise the reason.
func can_dismiss(hunter: HunterRuntime) -> String:
	if hunter == null or _hunters.get_hunter(hunter.unique_id) == null:
		return Loc.t("err.recruit.unknown_hunter")
	if hunter.expedition_id != &"":
		return Loc.t("err.recruit.on_dungeon")
	if not hunter.alive:
		return Loc.t("err.recruit.dead")
	if corpses != null and corpses.get_body_of(hunter) != null:
		return Loc.t("err.recruit.carrying")
	return ""


## Expels a Hunter through the gate: gone for good, no refund (D58).
func dismiss(hunter: HunterRuntime) -> String:
	var reason := can_dismiss(hunter)
	if not reason.is_empty():
		return reason
	_hunters.remove_hunter(hunter.unique_id)
	hunter_dismissed.emit(hunter)
	autosave_requested.emit(&"dismissal")
	return ""


func to_dict() -> Array:
	var list: Array = []
	for candidate in candidates:
		list.append(candidate.to_dict())
	return list


## Restores Tavern candidates; unknown classes are dropped. Refreshes if none are left.
func from_dict(data: Variant, warnings: PackedStringArray) -> void:
	candidates.clear()
	if data is Array:
		for entry in data:
			if not entry is Dictionary:
				continue
			var candidate := HunterRuntime.from_dict(entry)
			candidate.unique_id = &""
			if _hunters.get_definition(candidate) == null:
				warnings.append("tavern: dropped candidate with unknown class '%s'" % candidate.definition_id)
				continue
			candidates.append(candidate)
	if candidates.is_empty():
		refresh_candidates()
	else:
		candidates_changed.emit()
