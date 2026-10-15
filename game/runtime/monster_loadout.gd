class_name MonsterLoadout
extends RefCounted
## What one spawned monster carries (like a Hunter): gear in three slots, gold, materials, two
## skills and meat. Rolled at spawn, shown in the monster info, dropped on death.

var weapon: StringName
var armor: StringName
var accessory: StringName
var gold: int = 0
## Material item id -> quantity (what it will drop).
var resources: Dictionary[StringName, int] = {}
var skills: Array[StringName] = []
var meat: int = 0


func get_gear() -> Array[StringName]:
	var gear: Array[StringName] = []
	for item_id in [weapon, armor, accessory]:
		if item_id != &"":
			gear.append(item_id)
	return gear
