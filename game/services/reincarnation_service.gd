class_name ReincarnationService
extends RefCounted
## Reincarnation Portal and difficulty (Evil Hunter Tycoon style, but repeatable: no final goal).
## A Hunter at `reincarnate_level` restarts at level 1, keeps gear, traits and skills, gains a
## permanent stat bonus and rebirth points (spent on Academy traits). Total reincarnations unlock
## harder difficulties that scale monster stats and rewards.

signal reincarnated(hunter: HunterRuntime)
signal difficulty_changed(difficulty: int)
signal autosave_requested(reason: StringName)

var _hunters: HunterService
var _buildings: BuildingService
var _progress: ProgressService
var _config: GameConfig


func _init(hunters: HunterService, buildings: BuildingService, progress: ProgressService, config: GameConfig) -> void:
	_hunters = hunters
	_buildings = buildings
	_progress = progress
	_config = config
	_hunters.add_modifier_source(get_modifiers)


## Permanent bonus: every reincarnation adds a share of max HP, attack and defense.
func get_modifiers(hunter: HunterRuntime) -> Array[StatModifier]:
	var modifiers: Array[StatModifier] = []
	if hunter.reincarnations <= 0:
		return modifiers
	for stat in HunterService.ROLLED_STATS:
		var modifier := StatModifier.new()
		modifier.stat = stat
		modifier.type = StatModifier.Type.PERCENT
		modifier.value = _config.reincarnation_stat_bonus * hunter.reincarnations
		modifiers.append(modifier)
	# Reborn Hunters level faster, so the next climb feels quicker.
	var learning := StatModifier.new()
	learning.stat = HunterService.XP_GAIN
	learning.type = StatModifier.Type.PERCENT
	learning.value = 0.1 * hunter.reincarnations
	modifiers.append(learning)
	return modifiers


## Empty string when the Hunter can reincarnate now, otherwise the reason.
func can_reincarnate(hunter: HunterRuntime) -> String:
	if hunter == null:
		return Loc.t("err.reincarnation.unknown_hunter")
	if not _buildings.has_building(BuildingService.PORTAL):
		return Loc.t("err.reincarnation.no_portal")
	if hunter.level < _config.reincarnate_level:
		return Loc.t("err.reincarnation.needs_level", {"level": _config.reincarnate_level})
	if not hunter.alive or hunter.injured:
		return Loc.t("err.reincarnation.hurt", {"name": hunter.display_name})
	if hunter.expedition_id != &"":
		return Loc.t("err.reincarnation.on_expedition", {"name": hunter.display_name})
	return ""


## Points a reincarnation gives (1, +1 every third time).
func points_for_next(hunter: HunterRuntime) -> int:
	return 1 + (1 if (hunter.reincarnations + 1) % 3 == 0 else 0)


func reincarnate(hunter: HunterRuntime) -> bool:
	if not can_reincarnate(hunter).is_empty():
		return false
	hunter.rebirth_points += points_for_next(hunter)
	hunter.reincarnations += 1
	hunter.level = 1
	hunter.xp = 0
	hunter.stamina = _config.needs_max
	hunter.energy = _config.needs_max
	hunter.current_hp = _hunters.get_stat(hunter, HunterService.MAX_HP)
	hunter.record_chronicle("chronicle.reincarnated", str(hunter.reincarnations))
	_progress.total_reincarnations += 1
	_hunters.hunter_changed.emit(hunter)
	reincarnated.emit(hunter)
	autosave_requested.emit(&"reincarnation")
	return true


# --- Difficulty ---------------------------------------------------------------------------------

func get_difficulty_count() -> int:
	return _config.difficulty_names.size()


func get_difficulty_name(difficulty: int) -> String:
	return Loc.t(_config.difficulty_names[clampi(difficulty, 0, get_difficulty_count() - 1)])


func get_unlock_requirement(difficulty: int) -> int:
	return _config.difficulty_unlocks[clampi(difficulty, 0, _config.difficulty_unlocks.size() - 1)]


func is_unlocked(difficulty: int) -> bool:
	return difficulty >= 0 and difficulty < get_difficulty_count() \
		and _progress.total_reincarnations >= get_unlock_requirement(difficulty)


func get_difficulty() -> int:
	return _progress.difficulty


## Empty string on success.
func set_difficulty(difficulty: int) -> String:
	if difficulty < 0 or difficulty >= get_difficulty_count():
		return Loc.t("err.reincarnation.unknown_difficulty")
	if not is_unlocked(difficulty):
		return Loc.t("err.reincarnation.difficulty_locked", {"count": get_unlock_requirement(difficulty), "have": _progress.total_reincarnations})
	_progress.difficulty = difficulty
	difficulty_changed.emit(difficulty)
	autosave_requested.emit(&"difficulty")
	return ""
