class_name HunterRuntime
extends RefCounted
## Persistent state of one recruited Hunter (CHARACTER_SYSTEM.md → Runtime model).
## Holds ids and plain values only, so it can be serialized without Nodes.

## Expedition cycle (CHARACTER_SYSTEM.md → Lifecycle).
enum LifecycleState { AVAILABLE, ASSIGNED, TRAVELING, COMBAT, RETURNING, RECOVERING }

## `recovery_remaining` value for an injured Hunter whose Hospital timer has not started.
const RECOVERY_NOT_STARTED := -1.0

## `history` keys (HUNTER_LIFE_SYSTEM.md §5) and internal counters for trait events.
const RECRUIT_DAY := &"recruit_day"
const EXPEDITIONS_COMPLETED := &"expeditions_completed"
const EXPEDITIONS_FAILED := &"expeditions_failed"
const BOSSES_DEFEATED := &"bosses_defeated"
const TIMES_INJURED := &"times_injured"
const CONSECUTIVE_EXPEDITIONS := &"consecutive_expeditions"
const IDLE_CYCLES := &"idle_cycles"
const ACTIVITY_TICKS := &"activity_ticks"

var unique_id: StringName
## Class template id (HunterDefinition).
var definition_id: StringName
var display_name: String
## Index into the placeholder/art colour accent palette.
var accent_index: int = 0
## Stat id -> fraction rolled at recruitment, e.g. { &"attack": 0.07 } = +7% base attack.
var stat_rolls: Dictionary[StringName, float] = {}

var level: int = 1
var xp: int = 0
var current_hp: float = 0.0
var injured: bool = false
var recovery_remaining: float = 0.0

## Equipment slot -> item instance id (Phase 7).
var equipment: Dictionary[StringName, StringName] = {}
## Phase 8 (HUNTER_LIFE_SYSTEM.md).
var trait_ids: Array[StringName] = []
var mood: float = 0.0
## Current town activity (ActivityService).
var activity: StringName
## Player choice; empty = automatic (DECISIONS.md D14).
var assigned_activity: StringName
var history: Dictionary[StringName, int] = {}

var state: LifecycleState = LifecycleState.AVAILABLE
var expedition_id: StringName


## Plain data for saving (ids and primitive values only, SAVE_SYSTEM.md).
func to_dict() -> Dictionary:
	return {
		"unique_id": unique_id,
		"definition_id": definition_id,
		"display_name": display_name,
		"accent_index": accent_index,
		"stat_rolls": stat_rolls.duplicate(),
		"level": level,
		"xp": xp,
		"current_hp": current_hp,
		"injured": injured,
		"recovery_remaining": recovery_remaining,
		"equipment": equipment.duplicate(),
		"trait_ids": trait_ids.duplicate(),
		"mood": mood,
		"activity": activity,
		"assigned_activity": assigned_activity,
		"history": history.duplicate(),
		"state": state,
		"expedition_id": expedition_id,
	}


## Builds a Hunter from saved data. Missing fields get defaults; values are sanitized.
## Class/trait/item ids are validated by the services that own them.
static func from_dict(data: Dictionary) -> HunterRuntime:
	var hunter := HunterRuntime.new()
	hunter.unique_id = StringName(str(data.get("unique_id", "")))
	hunter.definition_id = StringName(str(data.get("definition_id", "")))
	hunter.display_name = str(data.get("display_name", ""))
	hunter.accent_index = int(data.get("accent_index", 0))
	var rolls: Variant = data.get("stat_rolls", {})
	if rolls is Dictionary:
		for stat in rolls:
			hunter.stat_rolls[StringName(str(stat))] = float(rolls[stat])
	hunter.level = maxi(int(data.get("level", 1)), 1)
	hunter.xp = maxi(int(data.get("xp", 0)), 0)
	hunter.current_hp = maxf(float(data.get("current_hp", 0.0)), 0.0)
	hunter.injured = bool(data.get("injured", false))
	hunter.recovery_remaining = float(data.get("recovery_remaining", RECOVERY_NOT_STARTED if hunter.injured else 0.0))
	var gear: Variant = data.get("equipment", {})
	if gear is Dictionary:
		for slot in gear:
			hunter.equipment[StringName(str(slot))] = StringName(str(gear[slot]))
	var traits: Variant = data.get("trait_ids", [])
	if traits is Array:
		for trait_id in traits:
			hunter.trait_ids.append(StringName(str(trait_id)))
	hunter.mood = float(data.get("mood", 60.0))
	hunter.activity = StringName(str(data.get("activity", "")))
	hunter.assigned_activity = StringName(str(data.get("assigned_activity", "")))
	var saved_history: Variant = data.get("history", {})
	if saved_history is Dictionary:
		for key in saved_history:
			hunter.history[StringName(str(key))] = int(saved_history[key])
	hunter.state = clampi(int(data.get("state", LifecycleState.AVAILABLE)), 0, LifecycleState.size() - 1) as LifecycleState
	hunter.expedition_id = StringName(str(data.get("expedition_id", "")))
	return hunter
