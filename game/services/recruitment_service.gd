class_name RecruitmentService
extends RefCounted
## Tavern recruitment (DECISIONS.md D11): N candidates, refreshed after each expedition
## return or for gold; recruiting costs the class recruit cost and needs roster capacity
## (Town Hall).

signal candidates_changed
## Emitted after the Hunter joined the roster (starting gear and traits hook in here).
signal hunter_recruited(hunter: HunterRuntime)
signal autosave_requested(reason: StringName)

var candidates: Array[HunterRuntime] = []

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
	var class_ids: Array[StringName] = _registry.get_ids(&"hunter")
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
	return definition.recruit_cost if definition != null else 0


## Empty string when candidate `index` can be recruited, otherwise the reason.
func can_recruit(index: int) -> String:
	if index < 0 or index >= candidates.size():
		return "No such candidate"
	if _hunters.count() >= get_capacity():
		return "Roster full (%d/%d) — upgrade the Town Hall" % [_hunters.count(), get_capacity()]
	if not _wallet.can_spend(get_recruit_cost(index)):
		return "Needs %d gold" % get_recruit_cost(index)
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
