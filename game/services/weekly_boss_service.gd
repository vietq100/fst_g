class_name WeeklyBossService
extends RefCounted
## The weekly boss (DECISIONS.md D58): one boss lives in the Boss Arena (a `RegionDefinition` of
## kind BOSS off the Ancient Ruins). While it is up, Hunters on the arena duty fight it like any
## monster (kill rewards go to the killer's purse and bag); when it falls the treasury gets a
## bonus chest (gold + materials into the Warehouse) and the boss returns a week later.
## Pure rules: the world's spawner asks `is_available` and reports the kill here.

signal state_changed
## The boss fell; `reward`: {"gold": int, "items": {item_id: stored}}.
signal boss_defeated(reward: Dictionary)
signal autosave_requested(reason: StringName)

const WEEK_SECONDS := 7 * 24 * 3600
const REGION_ID := &"boss_arena"
const BONUS_GOLD := 1500
const BONUS_ITEMS := {&"dark_essence": 3, &"iron_ore": 10, &"beast_fang": 6}

## Unix time when the boss is back (0 = it is up now).
var next_available_unix := 0
var kills := 0

var _registry: Node
var _world: WorldService
var _hunters: HunterService
var _wallet: WalletService
var _inventory: InventoryService


func _init(registry: Node, world: WorldService, hunters: HunterService, wallet: WalletService,
		inventory: InventoryService) -> void:
	_registry = registry
	_world = world
	_hunters = hunters
	_wallet = wallet
	_inventory = inventory


func get_region() -> RegionDefinition:
	return _world.get_region(REGION_ID)


func get_boss() -> EnemyDefinition:
	var region := get_region()
	if region == null or region.monster_ids.is_empty():
		return null
	return _registry.find_def(&"enemy", region.monster_ids[0]) as EnemyDefinition


func is_available(now: int = int(Time.get_unix_time_from_system())) -> bool:
	return now >= next_available_unix


func seconds_until_available(now: int = int(Time.get_unix_time_from_system())) -> float:
	return maxf(float(next_available_unix - now), 0.0)


## Hunters whose duty is the arena.
func get_assigned() -> Array[HunterRuntime]:
	return _hunters.get_all().filter(func(h: HunterRuntime) -> bool: return h.duty == REGION_ID)


## The boss fell: bonus chest to the treasury and Warehouse, next boss in a week.
func record_defeat(now: int = int(Time.get_unix_time_from_system())) -> Dictionary:
	kills += 1
	next_available_unix = now + WEEK_SECONDS
	_wallet.add(BONUS_GOLD)
	var reward := {"gold": BONUS_GOLD, "items": {}}
	for item_id: StringName in BONUS_ITEMS:
		var stored := _inventory.add_item(item_id, BONUS_ITEMS[item_id])
		if stored > 0:
			reward["items"][item_id] = stored
	state_changed.emit()
	boss_defeated.emit(reward)
	autosave_requested.emit(&"weekly_boss")
	return reward


func to_dict() -> Dictionary:
	return {"next_available_unix": next_available_unix, "kills": kills}


func from_dict(data: Variant) -> void:
	var dict: Dictionary = data if data is Dictionary else {}
	next_available_unix = maxi(int(dict.get("next_available_unix", 0)), 0)
	kills = maxi(int(dict.get("kills", 0)), 0)
	state_changed.emit()
