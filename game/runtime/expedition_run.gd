class_name ExpeditionRun
extends RefCounted
## State of the expedition in progress (EXPEDITION_SYSTEM.md). Not saved in MVP (D21).

enum Phase { TRAVELING, COMBAT, RETURNING, SUCCESS, FAILED }

var expedition_id: StringName
var party_ids: Array[StringName] = []
var phase: Phase = Phase.TRAVELING
## Index into ExpeditionDefinition.enemy_groups; == enemy_groups.size() means the boss.
var section_index: int = -1
var is_first_clear: bool = false
## The party reached the boss section (trait event "boss_fight").
var boss_reached: bool = false

## Collected during the run, granted on return (DECISIONS.md D5).
var stash_gold: int = 0
## Item id -> quantity.
var stash_items: Dictionary[StringName, int] = {}
var kills: int = 0
var xp_per_hunter: int = 0
var downed_ids: Array[StringName] = []
## Hunter id -> levels gained during the run.
var levels_gained: Dictionary[StringName, int] = {}

## Filled when the run ends.
var gold_granted: int = 0
var tickets_granted: int = 0
## Items that went into the inventory (item id -> quantity).
var items_granted: Dictionary[StringName, int] = {}
## Items that did not fit and were auto-sold, and the gold they gave (already in gold_granted).
var items_overflowed: Dictionary[StringName, int] = {}
var overflow_gold: int = 0


func is_finished() -> bool:
	return phase == Phase.SUCCESS or phase == Phase.FAILED
