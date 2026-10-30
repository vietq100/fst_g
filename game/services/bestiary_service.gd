class_name BestiaryService
extends RefCounted
## Bestiary & Monster Lore encyclopedia service.
## Tracks monster kills across expeditions and dungeons, unlocking knowledge,
## weakness lore, and mastery combat bonuses (+3% / +7% damage, +10% drop chance).

signal kill_recorded(monster_id: StringName, total_kills: int)
signal mastery_unlocked(monster_id: StringName, stars: int)
signal autosave_requested(reason: StringName)

const MONSTER_DEFS: Array[Dictionary] = [
	{
		"id": &"slime",
		"name_key": "bestiary.slime.name",
		"lore_key": "bestiary.slime.lore",
		"weakness_key": "bestiary.slime.weakness",
		"is_boss": false,
		"thresholds": [10, 30, 100],
	},
	{
		"id": &"goblin",
		"name_key": "bestiary.goblin.name",
		"lore_key": "bestiary.goblin.lore",
		"weakness_key": "bestiary.goblin.weakness",
		"is_boss": false,
		"thresholds": [10, 30, 100],
	},
	{
		"id": &"wolf",
		"name_key": "bestiary.wolf.name",
		"lore_key": "bestiary.wolf.lore",
		"weakness_key": "bestiary.wolf.weakness",
		"is_boss": false,
		"thresholds": [10, 30, 100],
	},
	{
		"id": &"skeleton",
		"name_key": "bestiary.skeleton.name",
		"lore_key": "bestiary.skeleton.lore",
		"weakness_key": "bestiary.skeleton.weakness",
		"is_boss": false,
		"thresholds": [10, 30, 100],
	},
	{
		"id": &"forest_guardian",
		"name_key": "bestiary.forest_guardian.name",
		"lore_key": "bestiary.forest_guardian.lore",
		"weakness_key": "bestiary.forest_guardian.weakness",
		"is_boss": true,
		"thresholds": [1, 3, 10],
	},
	{
		"id": &"goblin_warlord",
		"name_key": "bestiary.goblin_warlord.name",
		"lore_key": "bestiary.goblin_warlord.lore",
		"weakness_key": "bestiary.goblin_warlord.weakness",
		"is_boss": true,
		"thresholds": [1, 3, 10],
	},
	{
		"id": &"crypt_lord",
		"name_key": "bestiary.crypt_lord.name",
		"lore_key": "bestiary.crypt_lord.lore",
		"weakness_key": "bestiary.crypt_lord.weakness",
		"is_boss": true,
		"thresholds": [1, 3, 10],
	},
	{
		"id": &"abyss_warden",
		"name_key": "bestiary.abyss_warden.name",
		"lore_key": "bestiary.abyss_warden.lore",
		"weakness_key": "bestiary.abyss_warden.weakness",
		"is_boss": true,
		"thresholds": [1, 3, 10],
	},
]

var _kills: Dictionary[StringName, int] = {}


func get_all_monsters() -> Array[Dictionary]:
	return MONSTER_DEFS


func get_monster_info(monster_id: StringName) -> Dictionary:
	for m in MONSTER_DEFS:
		if m.id == monster_id:
			return m
	return {}


func record_kill(monster_id: StringName) -> void:
	if monster_id == &"":
		return
	var old_stars := get_mastery_stars(monster_id)
	var new_kills: int = _kills.get(monster_id, 0) + 1
	_kills[monster_id] = new_kills
	kill_recorded.emit(monster_id, new_kills)
	var new_stars := get_mastery_stars(monster_id)
	if new_stars > old_stars:
		mastery_unlocked.emit(monster_id, new_stars)
		autosave_requested.emit(&"bestiary_mastery")


func get_kills(monster_id: StringName) -> int:
	return _kills.get(monster_id, 0)


func get_mastery_stars(monster_id: StringName) -> int:
	var kills := get_kills(monster_id)
	var info := get_monster_info(monster_id)
	if info.is_empty():
		return 0
	var th: Array = info.thresholds
	if kills >= th[2]:
		return 3
	elif kills >= th[1]:
		return 2
	elif kills >= th[0]:
		return 1
	return 0


## Mastery damage multiplier against this monster species.
func get_damage_bonus(monster_id: StringName) -> float:
	var stars := get_mastery_stars(monster_id)
	match stars:
		1: return 0.0
		2: return 0.03
		3: return 0.07
		_: return 0.0


## Mastery extra loot drop chance against this monster species.
func get_drop_bonus(monster_id: StringName) -> float:
	return 0.10 if get_mastery_stars(monster_id) >= 3 else 0.0


func to_dict() -> Dictionary:
	var dict: Dictionary = {}
	for k in _kills:
		dict[String(k)] = _kills[k]
	return {"kills": dict}


func from_dict(data: Dictionary) -> void:
	_kills.clear()
	var saved: Variant = data.get("kills", {})
	if saved is Dictionary:
		for k in saved:
			_kills[StringName(str(k))] = int(saved[k])
