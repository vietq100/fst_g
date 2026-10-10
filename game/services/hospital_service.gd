class_name HospitalService
extends RefCounted
## Timed recovery of injured Hunters (DECISIONS.md D9, D24). Runs on real time, including
## offline catch-up; gold can finish a recovery early.

signal hunter_recovered(hunter: HunterRuntime)

var _hunters: HunterService
var _buildings: BuildingService
var _wallet: WalletService


func _init(hunters: HunterService, buildings: BuildingService, wallet: WalletService) -> void:
	_hunters = hunters
	_buildings = buildings
	_wallet = wallet


func get_recovery_seconds() -> float:
	return _buildings.get_effect(BuildingService.HOSPITAL, BuildingService.RECOVERY_SECONDS)


## Advances every recovery by `seconds`. Returns the Hunters that recovered.
func tick(seconds: float) -> Array[HunterRuntime]:
	var recovered: Array[HunterRuntime] = []
	for hunter in _hunters.get_all():
		if not hunter.injured:
			continue
		if hunter.recovery_remaining < 0.0:
			hunter.recovery_remaining = get_recovery_seconds()
		hunter.recovery_remaining -= seconds
		if hunter.recovery_remaining <= 0.0:
			_hunters.recover(hunter)
			recovered.append(hunter)
			hunter_recovered.emit(hunter)
	return recovered


## Remaining seconds (a not-yet-started recovery counts as a full one).
func get_remaining(hunter: HunterRuntime) -> float:
	if not hunter.injured:
		return 0.0
	return get_recovery_seconds() if hunter.recovery_remaining < 0.0 else hunter.recovery_remaining


## Gold per started remaining minute (BALANCE.md → Hospital speed-up).
func get_speed_up_cost(hunter: HunterRuntime) -> int:
	var per_minute := _buildings.get_effect(BuildingService.HOSPITAL, BuildingService.SPEEDUP_GOLD_PER_MINUTE)
	return int(ceilf(get_remaining(hunter) / 60.0) * per_minute)


func speed_up(hunter: HunterRuntime) -> bool:
	if not hunter.injured or not _wallet.spend(get_speed_up_cost(hunter)):
		return false
	_hunters.recover(hunter)
	hunter_recovered.emit(hunter)
	return true
