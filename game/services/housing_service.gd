class_name HousingService
extends RefCounted
## House beds (DECISIONS.md D32): 4 beds per House, assigned to Hunters automatically.
## A Hunter without a bed sleeps outdoors. Recruiting needs a free bed.

signal beds_changed

var _hunters: HunterService
var _buildings: BuildingService


func _init(hunters: HunterService, buildings: BuildingService) -> void:
	_hunters = hunters
	_buildings = buildings
	_buildings.layout_changed.connect(assign_beds)
	_hunters.hunter_added.connect(func(_h: HunterRuntime) -> void: assign_beds())


func get_total_beds() -> int:
	return int(_buildings.get_total_effect(BuildingService.HOUSE, BuildingService.BEDS)
		+ _buildings.get_total_effect(BuildingService.INN, BuildingService.BEDS))


func get_used_beds() -> int:
	return _hunters.get_all().filter(func(h: HunterRuntime) -> bool: return h.home_id != &"").size()


func get_free_beds() -> int:
	return maxi(get_total_beds() - get_used_beds(), 0)


## The House instance of a Hunter, or null (sleeps outdoors).
func get_home(hunter: HunterRuntime) -> BuildingService.Placed:
	return _buildings.get_instance(hunter.home_id) if hunter.home_id != &"" else null


## Keeps valid assignments, drops beds in removed Houses, fills free beds in House order.
func assign_beds() -> void:
	var used: Dictionary[StringName, int] = {}
	var houses := _buildings.get_instances_of(BuildingService.HOUSE) + _buildings.get_instances_of(BuildingService.INN)
	var capacity: Dictionary[StringName, int] = {}
	for house in houses:
		capacity[house.instance_id] = int(_buildings.get_instance_effect(house, BuildingService.BEDS))
	var changed := false
	for hunter in _hunters.get_all():
		if hunter.home_id != &"" and capacity.has(hunter.home_id) and used.get(hunter.home_id, 0) < capacity[hunter.home_id]:
			used[hunter.home_id] = used.get(hunter.home_id, 0) + 1
		elif hunter.home_id != &"":
			hunter.home_id = &""
			changed = true
	for hunter in _hunters.get_all():
		if hunter.home_id != &"":
			continue
		for house in houses:
			if used.get(house.instance_id, 0) < capacity[house.instance_id]:
				hunter.home_id = house.instance_id
				used[house.instance_id] = used.get(house.instance_id, 0) + 1
				changed = true
				break
	if changed:
		beds_changed.emit()
