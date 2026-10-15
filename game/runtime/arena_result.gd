class_name ArenaResult
extends RefCounted
## What one simulated Colosseum match produced: every hit in order (for the replay) and the outcome.

## Who won: 0 = the first fighter, 1 = the second, -1 = a draw.
var winner: int = -1
## Seconds the fight lasted (the time limit when it ran out).
var duration: float = 0.0
var timed_out := false
var names: Array[String] = ["", ""]
var max_hp: Array[float] = [1.0, 1.0]
## Remaining HP at the end.
var hp_end: Array[float] = [1.0, 1.0]
## Dictionaries: {"t": seconds, "from": 0|1, "damage": int, "crit": bool, "dodged": bool, "hp": [a, b]}.
var events: Array[Dictionary] = []


func hp_ratio(side: int) -> float:
	return clampf(hp_end[side] / maxf(max_hp[side], 1.0), 0.0, 1.0)
