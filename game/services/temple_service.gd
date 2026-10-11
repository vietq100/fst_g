class_name TempleService
extends RefCounted
## Revival at the Temple (DECISIONS.md D42, D24): dead (and legacy injured) Hunters wait the
## Temple's revival time on real time, including offline catch-up; gold can finish it early.
## A revived Hunter loses part of the XP of its current level (never a level).

signal hunter_recovered(hunter: HunterRuntime)

var _hunters: HunterService
var _buildings: BuildingService
var _wallet: WalletService
var _stats: StatService
var _config: GameConfig


func _init(hunters: HunterService, buildings: BuildingService, wallet: WalletService, stats: StatService,
		config: GameConfig) -> void:
	_hunters = hunters
	_buildings = buildings
	_wallet = wallet
	_stats = stats
	_config = config


## 0 without a Temple: the town revives at once.
func get_recovery_seconds() -> float:
	return _buildings.get_effect(BuildingService.TEMPLE, BuildingService.RECOVERY_SECONDS)


## Advances every revival by `seconds`. Returns the Hunters that came back.
func tick(seconds: float) -> Array[HunterRuntime]:
	var recovered: Array[HunterRuntime] = []
	for hunter in _hunters.get_all():
		if not hunter.injured:
			continue
		if hunter.recovery_remaining < 0.0:
			hunter.recovery_remaining = get_recovery_seconds()
		hunter.recovery_remaining -= seconds
		if hunter.recovery_remaining <= 0.0:
			_finish(hunter)
			recovered.append(hunter)
	return recovered


## Remaining seconds (a not-yet-started revival counts as a full one).
func get_remaining(hunter: HunterRuntime) -> float:
	if not hunter.injured:
		return 0.0
	return get_recovery_seconds() if hunter.recovery_remaining < 0.0 else hunter.recovery_remaining


## XP a dead Hunter loses when revived (D42).
func get_xp_loss(hunter: HunterRuntime) -> int:
	if hunter.alive:
		return 0
	return mini(floori(_stats.required_xp(hunter.level) * _config.revive_xp_loss_ratio), hunter.xp)


## Gold per started remaining minute (BALANCE.md → Temple speed-up).
func get_speed_up_cost(hunter: HunterRuntime) -> int:
	var per_minute := _buildings.get_effect(BuildingService.TEMPLE, BuildingService.SPEEDUP_GOLD_PER_MINUTE)
	return int(ceilf(get_remaining(hunter) / 60.0) * per_minute)


func speed_up(hunter: HunterRuntime) -> bool:
	if not hunter.injured or not _wallet.spend(get_speed_up_cost(hunter)):
		return false
	_finish(hunter)
	return true


func _finish(hunter: HunterRuntime) -> void:
	hunter.xp -= get_xp_loss(hunter)
	_hunters.recover(hunter)
	hunter_recovered.emit(hunter)
