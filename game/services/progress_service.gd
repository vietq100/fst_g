class_name ProgressService
extends RefCounted
## Progress flags (e.g. &"first_boss_clear"), the town level used for unlocks and the Hunter
## level cap (set from the Town Hall), and the in-game day counter used for Hunter history.

signal flag_set(flag: StringName)
signal day_passed(day: int)

var town_level: int = 1
## Selected difficulty (index into GameConfig.difficulty_*) and reincarnations done in total.
var difficulty: int = 0
var total_reincarnations: int = 0
var day: int = 1
## Seconds into the current day.
var day_time: float = 0.0
var _flags: Dictionary[StringName, bool] = {}


func has_flag(flag: StringName) -> bool:
	return flag == &"" or _flags.has(flag)


func set_flag(flag: StringName) -> void:
	if flag == &"" or _flags.has(flag):
		return
	_flags[flag] = true
	flag_set.emit(flag)


func get_flags() -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(_flags.keys())
	return result


func clear_flags() -> void:
	_flags.clear()


func to_dict() -> Dictionary:
	return {"flags": get_flags(), "day": day, "day_time": day_time,
		"difficulty": difficulty, "total_reincarnations": total_reincarnations}


## Town level is not saved: BuildingService derives it from the Town Hall level.
func from_dict(data: Dictionary) -> void:
	_flags.clear()
	var flags: Variant = data.get("flags", [])
	if flags is Array:
		for flag in flags:
			_flags[StringName(str(flag))] = true
	difficulty = maxi(int(data.get("difficulty", 0)), 0)
	total_reincarnations = maxi(int(data.get("total_reincarnations", 0)), 0)
	day = maxi(int(data.get("day", 1)), 1)
	day_time = maxf(float(data.get("day_time", 0.0)), 0.0)


## Advances the day counter by real seconds (`day_length` seconds per day).
func advance(seconds: float, day_length: float) -> void:
	if day_length <= 0.0 or seconds <= 0.0:
		return
	day_time += seconds
	while day_time >= day_length:
		day_time -= day_length
		day += 1
		day_passed.emit(day)
