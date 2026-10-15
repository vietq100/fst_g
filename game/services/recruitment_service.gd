class_name RecruitmentService
extends RefCounted
## Hunter Gate recruitment and dismissal (DECISIONS.md D11, D58): N candidates, refreshed after
## each expedition return or for gold; recruiting costs the class recruit cost and needs roster
## capacity (Town Hall) and a bed. Expelling sends a Hunter away for good.

signal candidates_changed
## Emitted after the Hunter joined the roster (starting gear and traits hook in here).
signal hunter_recruited(hunter: HunterRuntime)
## Emitted after the Hunter was taken off the roster.
signal hunter_dismissed(hunter: HunterRuntime)
signal autosave_requested(reason: StringName)

var candidates: Array[HunterRuntime] = []
## Beds (DECISIONS.md D32); optional so the service also works standalone.
var housing: HousingService
## Bodies and carriers (D30); optional.
var corpses: CorpseService

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


func get_capacity() -> int:
	return int(_buildings.get_effect(BuildingService.TOWN_HALL, BuildingService.HUNTER_CAPACITY))


func get_refresh_cost() -> int:
	return int(_buildings.get_effect(BuildingService.TAVERN, BuildingService.REFRESH_COST))


## Free refresh (after an expedition returns / new game).
func refresh_candidates() -> void:
	candidates.clear()
	var class_ids: Array[StringName] = _registry.get_ids(&"hunter").filter(func(id: StringName) -> bool:
		return (_registry.find_def(&"hunter", id) as HunterDefinition).promotion_of == &"")
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


## Empty string when candidate `index` can be recruited, otherwise the reason.
func can_recruit(index: int) -> String:
	if index < 0 or index >= candidates.size():
		return Loc.t("err.recruit.no_candidate")
	if _hunters.count() >= get_capacity():
		return Loc.t("err.recruit.roster_full", {"count": _hunters.count(), "max": get_capacity()})
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
