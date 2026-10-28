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
## Hair, skin, body type and dye colour (D47). The outfit comes from the equipped armor.
var appearance: HunterAppearance = HunterAppearance.new()
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
## D46: &"" = no talent.
var talent_id: StringName
var mood: float = 0.0
## Current town activity (ActivityService).
var activity: StringName
## Player choice; empty = automatic (DECISIONS.md D14).
var assigned_activity: StringName
var history: Dictionary[StringName, int] = {}
## Notable deeds and chronicle entries: [{"key": String, "details": String, "time": int}]
var chronicle: Array[Dictionary] = []
## Dynamic Hunter achievement title (e.g. &"goblin_slayer", &"undying", &"veteran").
var equipped_title: StringName = &""
var unlocked_titles: Array[StringName] = []


func record_chronicle(event_key: String, details: String = "") -> void:
	chronicle.append({
		"key": event_key,
		"details": details,
		"time": int(Time.get_unix_time_from_system()),
	})
	if chronicle.size() > 50:
		chronicle.pop_front()


var state: LifecycleState = LifecycleState.AVAILABLE
var expedition_id: StringName

## World redesign (DECISIONS.md D29–D34).
## Needs 0–100 (AUTONOMY_SYSTEM.md).
var stamina: float = 100.0
var energy: float = 100.0
## Personal gold.
var purse: int = 0
## &"" = Auto, a region id, or STAY_IN_TOWN.
var duty: StringName
## House instance id with this Hunter's bed (&"" = sleeps outdoors).
var home_id: StringName
## False while dead (a body lying in the world or carried, or a Hospital patient).
var alive: bool = true
## Where the Hunter (or its body) is in the world.
var world_position: Vector2 = Vector2.ZERO
## &"" = town life; HUNTING while out in a region (set by the Hunter brain).
var task: StringName
## Asleep on the Hibernation Mount (D83): no needs, no duty, no bed; not counted as active.
var hibernating := false
## Evil Hunter Tycoon systems: reincarnation count, unspent points (Academy traits), Academy skills.
var reincarnations: int = 0
## Tier (D60): rolled C..UR when the candidate is generated; scales HP / attack / defense.
var tier: int = Tier.Level.C
var rebirth_points: int = 0
var skills: Dictionary[StringName, int] = {}
## Class skills (D70): skill id -> level 1–6, in the order they were opened.
var class_skills: Dictionary[StringName, int] = {}
## Unspent class skill points (1 per 10 levels) and swap points (1 per reincarnation).
var skill_points: int = 0
var skill_swap_points: int = 0
## Hunter level up to which skill points were granted in this life (ClassSkillService.sync_points).
var skill_point_level: int = 1
## Mana for active class skills (D70).
var current_mana: float = 0.0
## Items carried back from hunting (item id -> quantity).
var loot_bag: Dictionary[StringName, int] = {}

const STAY_IN_TOWN := &"stay"
const HUNTING := &"hunting"
## Task while asleep on the Hibernation Mount (D83).
const HIBERNATING := &"hibernating"


## Plain data for saving (ids and primitive values only, SAVE_SYSTEM.md).
func to_dict() -> Dictionary:
	return {
		"unique_id": unique_id,
		"definition_id": definition_id,
		"display_name": display_name,
		"accent_index": accent_index,
		"appearance": appearance.to_dict(),
		"stat_rolls": stat_rolls.duplicate(),
		"level": level,
		"xp": xp,
		"current_hp": current_hp,
		"injured": injured,
		"recovery_remaining": recovery_remaining,
		"equipment": equipment.duplicate(),
		"trait_ids": trait_ids.duplicate(),
		"talent_id": talent_id,
		"mood": mood,
		"activity": activity,
		"assigned_activity": assigned_activity,
		"history": history.duplicate(),
		"state": state,
		"expedition_id": expedition_id,
		"stamina": stamina,
		"energy": energy,
		"purse": purse,
		"duty": duty,
		"task": task,
		"hibernating": hibernating,
		"home_id": home_id,
		"alive": alive,
		"world_position": [world_position.x, world_position.y],
		"loot_bag": loot_bag.duplicate(),
		"reincarnations": reincarnations,
		"tier": tier,
		"rebirth_points": rebirth_points,
		"skills": skills.duplicate(),
		"class_skills": _class_skill_list(),
		"skill_points": skill_points,
		"skill_swap_points": skill_swap_points,
		"skill_point_level": skill_point_level,
		"current_mana": current_mana,
		"chronicle": chronicle.duplicate(),
		"equipped_title": equipped_title,
		"unlocked_titles": unlocked_titles.duplicate(),
	}


## Ordered [[id, level], …] so the opening order survives JSON.
func _class_skill_list() -> Array:
	var list: Array = []
	for skill_id: StringName in class_skills:
		list.append([String(skill_id), class_skills[skill_id]])
	return list


## Builds a Hunter from saved data. Missing fields get defaults; values are sanitized.
## Class/trait/item ids are validated by the services that own them.
static func from_dict(data: Dictionary) -> HunterRuntime:
	var hunter := HunterRuntime.new()
	hunter.unique_id = StringName(str(data.get("unique_id", "")))
	hunter.definition_id = StringName(str(data.get("definition_id", "")))
	hunter.display_name = str(data.get("display_name", ""))
	hunter.accent_index = int(data.get("accent_index", 0))
	var look: Variant = data.get("appearance", null)
	if look is Dictionary:
		hunter.appearance = HunterAppearance.from_dict(look)
	else:
		# Saves made before D47: give a stable look derived from the Hunter's id.
		hunter.appearance = HunterAppearance.from_seed(str(hunter.unique_id) + hunter.display_name, hunter.accent_index)
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
	hunter.talent_id = StringName(str(data.get("talent_id", "")))
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
	hunter.stamina = clampf(float(data.get("stamina", 100.0)), 0.0, 100.0)
	hunter.energy = clampf(float(data.get("energy", 100.0)), 0.0, 100.0)
	hunter.purse = maxi(int(data.get("purse", 0)), 0)
	hunter.duty = StringName(str(data.get("duty", "")))
	hunter.task = StringName(str(data.get("task", "")))
	hunter.hibernating = bool(data.get("hibernating", false))
	hunter.home_id = StringName(str(data.get("home_id", "")))
	hunter.alive = bool(data.get("alive", true))
	var at: Variant = data.get("world_position", [])
	if at is Array and at.size() == 2:
		hunter.world_position = Vector2(float(at[0]), float(at[1]))
	var bag: Variant = data.get("loot_bag", {})
	if bag is Dictionary:
		for item_id in bag:
			hunter.loot_bag[StringName(str(item_id))] = maxi(int(bag[item_id]), 0)
	hunter.reincarnations = maxi(int(data.get("reincarnations", 0)), 0)
	hunter.tier = Tier.clamp_level(int(data.get("tier", Tier.Level.C)))
	hunter.rebirth_points = maxi(int(data.get("rebirth_points", 0)), 0)
	var learned: Variant = data.get("skills", {})
	if learned is Dictionary:
		for skill_id in learned:
			hunter.skills[StringName(str(skill_id))] = maxi(int(learned[skill_id]), 0)
	var class_list: Variant = data.get("class_skills", [])
	if class_list is Array:
		for entry: Variant in class_list:
			if entry is Array and entry.size() == 2:
				hunter.class_skills[StringName(str(entry[0]))] = clampi(int(entry[1]), 1, 99)
	hunter.skill_points = maxi(int(data.get("skill_points", 0)), 0)
	hunter.skill_swap_points = maxi(int(data.get("skill_swap_points", 0)), 0)
	# Missing (saves before D70): 1, so ClassSkillService.sync_points grants the earned points.
	hunter.skill_point_level = maxi(int(data.get("skill_point_level", 1)), 1)
	hunter.current_mana = maxf(float(data.get("current_mana", 0.0)), 0.0)
	var saved_chronicle: Variant = data.get("chronicle", [])
	if saved_chronicle is Array:
		for entry in saved_chronicle:
			if entry is Dictionary:
				hunter.chronicle.append(entry.duplicate())
	hunter.equipped_title = StringName(str(data.get("equipped_title", "")))
	var saved_titles: Variant = data.get("unlocked_titles", [])
	if saved_titles is Array:
		for t in saved_titles:
			hunter.unlocked_titles.append(StringName(str(t)))
	return hunter
