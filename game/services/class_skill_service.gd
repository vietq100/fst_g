class_name ClassSkillService
extends RefCounted
## Class skills of Hunters (DECISIONS.md D69, D70; guide/skills_guide.md).
## - Pool: the 30 skills of the Hunter's base class (promoted classes use their base class).
## - A Hunter earns 1 skill point every `class_skill_point_every` levels (10, 20 … 100).
##   A point opens a random new skill (level 1, up to `class_skill_max_count`) or raises an
##   owned skill by one level (up to `class_skill_max_level`).
## - Reincarnation keeps skills and levels and grants a swap point: replace one skill with a
##   random skill the Hunter does not own; the new skill keeps the old one's level.
## - Power at skill level L = 1 + power_per_level × (L − 1): damage, heals, passive bonuses.
## Combat casting lives in ClassSkillCaster (one per Hunter actor).

signal skills_changed(hunter: HunterRuntime)
signal autosave_requested(reason: StringName)

## Stats a skill can scale with that are not HunterService stats.
const RANGE_STAT := &"attack_range"
const LEVEL_STAT := &"level"

var _registry: Node
var _hunters: HunterService
var _config: GameConfig
var _rng: RandomNumberGenerator
## class id -> skills sorted by `order` (built on first use).
var _pools: Dictionary[StringName, Array] = {}


func _init(registry: Node, hunters: HunterService, config: GameConfig, rng: RandomNumberGenerator) -> void:
	_registry = registry
	_hunters = hunters
	_config = config
	_rng = rng
	_hunters.add_modifier_source(get_modifiers)
	_hunters.hunter_leveled_up.connect(_on_leveled_up)
	_hunters.hunter_changed.connect(sync_points)


# --- Definitions ---------------------------------------------------------------------------------

func get_skill(skill_id: StringName) -> ClassSkillDefinition:
	return _registry.find_def(&"class_skill", skill_id) as ClassSkillDefinition


func get_effect(effect_id: StringName) -> StatusEffectDefinition:
	return _registry.find_def(&"status_effect", effect_id) as StatusEffectDefinition


## Base class of a Hunter: follows `promotion_of` up to a recruitable class.
func get_base_class(hunter: HunterRuntime) -> StringName:
	var definition := _hunters.get_definition(hunter)
	var guard := 0
	while definition != null and definition.promotion_of != &"" and guard < 8:
		var parent := _registry.find_def(&"hunter", definition.promotion_of) as HunterDefinition
		if parent == null:
			break
		definition = parent
		guard += 1
	return definition.id if definition != null else &""


## The class's skills in display order.
func get_pool(class_id: StringName) -> Array[ClassSkillDefinition]:
	if not _pools.has(class_id):
		var list: Array = []
		for definition in _registry.get_all(&"class_skill"):
			var skill := definition as ClassSkillDefinition
			if skill != null and skill.class_id == class_id:
				list.append(skill)
		list.sort_custom(func(a: ClassSkillDefinition, b: ClassSkillDefinition) -> bool: return a.order < b.order)
		_pools[class_id] = list
	var result: Array[ClassSkillDefinition] = []
	result.assign(_pools[class_id])
	return result


func get_hunter_pool(hunter: HunterRuntime) -> Array[ClassSkillDefinition]:
	return get_pool(get_base_class(hunter))


# --- Numbers ---------------------------------------------------------------------------------------

func get_power(level: int) -> float:
	return 1.0 + _config.class_skill_power_per_level * (clampi(level, 1, _config.class_skill_max_level) - 1)


func get_mana_cost(skill: ClassSkillDefinition, level: int) -> float:
	if skill == null or not skill.is_active():
		return 0.0
	return roundf(skill.mana_cost * (1.0 + _config.class_skill_mana_per_level * (clampi(level, 1, _config.class_skill_max_level) - 1)))


## Duration multiplier of a skill's effect at `power` (D70): buffs get the whole power bonus,
## debuffs a share of it (crowd control would get out of hand otherwise).
func get_duration_scale(effect: StatusEffectDefinition, power: float) -> float:
	var share := 1.0 if effect.kind == StatusEffectDefinition.Kind.BUFF else _config.class_skill_debuff_duration_share
	return 1.0 + (power - 1.0) * share


func get_level(hunter: HunterRuntime, skill_id: StringName) -> int:
	return hunter.class_skills.get(skill_id, 0)


## Value of the stat a skill scales with, for this Hunter.
func get_scale_value(hunter: HunterRuntime, stat: StringName) -> float:
	match stat:
		RANGE_STAT:
			var definition := _hunters.get_definition(hunter)
			return get_attack_range(hunter, definition.attack_range if definition != null else 0.0)
		LEVEL_STAT:
			return float(hunter.level)
	return _hunters.get_stat(hunter, stat)


## The class's base value of a stat (for `stat_multiplier` skills). 1 if unknown.
func get_base_value(hunter: HunterRuntime, stat: StringName) -> float:
	var definition := _hunters.get_definition(hunter)
	if definition == null:
		return 1.0
	match stat:
		HunterService.MOVE_SPEED:
			return maxf(definition.move_speed, 1.0)
		HunterService.ATTACK_SPEED:
			return maxf(definition.attack_speed, 0.01)
		RANGE_STAT:
			return maxf(definition.attack_range, 1.0)
		HunterService.CRITICAL_CHANCE:
			return maxf(definition.critical_chance, 0.05)
		HunterService.CRITICAL_DAMAGE:
			return maxf(definition.critical_damage, 1.0)
	return 1.0


## Attack range after range passives (RANGE_BONUS stat).
func get_attack_range(hunter: HunterRuntime, base_range: float) -> float:
	return base_range * (1.0 + _hunters.get_stat(hunter, HunterService.RANGE_BONUS))


# --- Owned skills and points ------------------------------------------------------------------------

## Owned skills in the order they were opened.
func get_owned(hunter: HunterRuntime) -> Array[ClassSkillDefinition]:
	var result: Array[ClassSkillDefinition] = []
	for skill_id: StringName in hunter.class_skills:
		var skill := get_skill(skill_id)
		if skill != null:
			result.append(skill)
	return result


## Skills that act in combat on their own (actives and triggered passives), with their levels.
func get_castables(hunter: HunterRuntime) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for skill in get_owned(hunter):
		if skill.is_castable():
			result.append({"skill": skill, "level": get_level(hunter, skill.id)})
	return result


## Skill points earned by reaching `level` in one life.
func points_up_to(level: int) -> int:
	return floori(float(maxi(level, 0)) / maxi(_config.class_skill_point_every, 1))


## Grants the points for levels reached since the last sync (idempotent). Also migrates saves
## from before D70 (skill_point_level 1 → points for the current level).
func sync_points(hunter: HunterRuntime) -> void:
	if hunter == null or hunter.level <= hunter.skill_point_level:
		return
	var gained := points_up_to(hunter.level) - points_up_to(hunter.skill_point_level)
	hunter.skill_point_level = hunter.level
	if gained > 0:
		hunter.skill_points += gained
		skills_changed.emit(hunter)


## Empty string when a point can open a new random skill now, otherwise the reason.
func can_unlock(hunter: HunterRuntime) -> String:
	if hunter == null:
		return Loc.t("err.class_skill.unknown_hunter")
	if hunter.skill_points <= 0:
		return Loc.t("err.class_skill.no_points")
	if hunter.class_skills.size() >= _config.class_skill_max_count:
		return Loc.t("err.class_skill.full", {"max": _config.class_skill_max_count})
	if _unowned(hunter).is_empty():
		return Loc.t("err.class_skill.pool_empty")
	return ""


## Spends a point on a random new skill. Returns it, or null.
func unlock_random(hunter: HunterRuntime) -> ClassSkillDefinition:
	if not can_unlock(hunter).is_empty():
		return null
	var skill := _pick_unowned(hunter)
	hunter.skill_points -= 1
	hunter.class_skills[skill.id] = 1
	_changed(hunter, &"class_skill")
	return skill


func can_upgrade(hunter: HunterRuntime, skill_id: StringName) -> String:
	if hunter == null:
		return Loc.t("err.class_skill.unknown_hunter")
	if not hunter.class_skills.has(skill_id):
		return Loc.t("err.class_skill.not_owned")
	if get_level(hunter, skill_id) >= _config.class_skill_max_level:
		return Loc.t("err.class_skill.max_level", {"max": _config.class_skill_max_level})
	if hunter.skill_points <= 0:
		return Loc.t("err.class_skill.no_points")
	return ""


func upgrade(hunter: HunterRuntime, skill_id: StringName) -> bool:
	if not can_upgrade(hunter, skill_id).is_empty():
		return false
	hunter.skill_points -= 1
	hunter.class_skills[skill_id] += 1
	_changed(hunter, &"class_skill")
	return true


func can_swap(hunter: HunterRuntime, skill_id: StringName) -> String:
	if hunter == null:
		return Loc.t("err.class_skill.unknown_hunter")
	if not hunter.class_skills.has(skill_id):
		return Loc.t("err.class_skill.not_owned")
	if hunter.skill_swap_points <= 0:
		return Loc.t("err.class_skill.no_swap_points")
	if _unowned(hunter).is_empty():
		return Loc.t("err.class_skill.pool_empty")
	return ""


## Spends a swap point: replaces `skill_id` (same slot, same level) with a random skill the
## Hunter does not own. Returns the new skill, or null.
func swap(hunter: HunterRuntime, skill_id: StringName) -> ClassSkillDefinition:
	if not can_swap(hunter, skill_id).is_empty():
		return null
	var skill := _pick_unowned(hunter)
	var replaced: Dictionary[StringName, int] = {}
	for owned_id: StringName in hunter.class_skills:
		if owned_id == skill_id:
			replaced[skill.id] = hunter.class_skills[owned_id]
		else:
			replaced[owned_id] = hunter.class_skills[owned_id]
	hunter.class_skills = replaced
	hunter.skill_swap_points -= 1
	_changed(hunter, &"class_skill")
	return skill


## Candidate decorator: the configured number of random starting skills.
func grant_starting_skills(hunter: HunterRuntime) -> void:
	for i in _config.class_skill_start_count:
		if hunter.class_skills.size() >= _config.class_skill_max_count or _unowned(hunter).is_empty():
			return
		hunter.class_skills[_pick_unowned(hunter).id] = 1


## After a reincarnation (level 1 again): skills stay, a swap point is added and the point
## counter restarts for the new life.
func on_reincarnated(hunter: HunterRuntime) -> void:
	hunter.skill_swap_points += _config.class_skill_swap_per_reincarnation
	hunter.skill_point_level = hunter.level
	hunter.current_mana = _hunters.get_stat(hunter, HunterService.MAX_MANA)
	_changed(hunter, &"reincarnation")


# --- Passive effects ---------------------------------------------------------------------------

## Stat modifiers from owned passives, scaled by their level (modifier source of HunterService).
func get_modifiers(hunter: HunterRuntime) -> Array[StatModifier]:
	var result: Array[StatModifier] = []
	for skill_id: StringName in hunter.class_skills:
		var skill := get_skill(skill_id)
		if skill == null or skill.is_active():
			continue
		var power := get_power(hunter.class_skills[skill_id])
		for modifier in skill.modifiers:
			result.append(_scaled(modifier, power))
		if not skill.level_modifiers.is_empty():
			var steps := mini(floori(float(hunter.level) / maxi(skill.level_step, 1)), skill.level_step_cap)
			for modifier in skill.level_modifiers:
				result.append(_scaled(modifier, power * steps))
	return result


## On-hit effects of owned passives (chance × power, at most 1).
func get_on_hit_effects(hunter: HunterRuntime) -> Array[StatusEffectChance]:
	var result: Array[StatusEffectChance] = []
	for skill in get_owned(hunter):
		if skill.is_active():
			continue
		var power := get_power(get_level(hunter, skill.id))
		for entry in skill.on_hit_effects:
			if entry == null or entry.effect == null:
				continue
			var scaled := StatusEffectChance.new()
			scaled.effect = entry.effect
			scaled.stacks = entry.stacks
			scaled.chance = minf(entry.chance * power, 1.0)
			result.append(scaled)
	return result


## Share of max HP healed on each kill.
func get_kill_heal_ratio(hunter: HunterRuntime) -> float:
	var total := 0.0
	for skill in get_owned(hunter):
		if not skill.is_active() and skill.kill_heal_ratio > 0.0:
			total += skill.kill_heal_ratio * get_power(get_level(hunter, skill.id))
	return total


# --- Text --------------------------------------------------------------------------------------

## Translated numbers of a skill at `level`: damage, heals, effects, modifiers, cost.
func describe(skill: ClassSkillDefinition, level: int) -> String:
	var power := get_power(level)
	var lines := PackedStringArray()
	if skill.deals_damage():
		var parts := PackedStringArray()
		if skill.attack_ratio > 0.0:
			parts.append("%d%% %s" % [roundi(skill.attack_ratio * power * 100.0), Loc.t("stat.attack")])
		if skill.stat_ratio > 0.0:
			parts.append("%d%% %s" % [roundi(skill.stat_ratio * power * 100.0), stat_name(skill.scale_stat)])
		var text := " + ".join(parts)
		if skill.stat_multiplier:
			text = Loc.t("class_skill.fmt.times_stat", {"value": text, "stat": stat_name(skill.scale_stat)})
		if skill.hits > 1:
			text = "%d × %s" % [skill.hits, text]
		lines.append(Loc.t("class_skill.fmt.damage", {"value": text}))
		if skill.target in [ClassSkillDefinition.Target.ENEMIES_AROUND_SELF, ClassSkillDefinition.Target.ENEMIES_AROUND_TARGET]:
			lines.append(Loc.t("class_skill.fmt.area", {"radius": roundi(skill.radius)}))
		if skill.max_hits > skill.hits:
			lines.append(Loc.t("class_skill.fmt.extra_hits", {"max": skill.max_hits}))
	if skill.bonus_crit > 0.0:
		lines.append(Loc.t("class_skill.fmt.bonus_crit", {"value": roundi(skill.bonus_crit * 100.0)}))
	if skill.bonus_crit_damage > 0.0:
		lines.append(Loc.t("class_skill.fmt.bonus_crit_damage", {"value": roundi(skill.bonus_crit_damage * 100.0)}))
	if skill.ignore_dodge:
		lines.append(Loc.t("class_skill.fmt.ignore_dodge"))
	if skill.execute_threshold > 0.0:
		lines.append(Loc.t("class_skill.fmt.execute", {"threshold": roundi(skill.execute_threshold * 100.0), "value": "%.1f" % skill.execute_multiplier}))
	if skill.tag_bonus != &"":
		lines.append(Loc.t("class_skill.fmt.tag_bonus", {"value": roundi(skill.tag_bonus_ratio * 100.0), "tag": Loc.t("class_skill.tag.%s" % skill.tag_bonus)}))
	if skill.stack_effect != &"":
		lines.append(Loc.t("class_skill.fmt.per_stack", {"value": roundi(skill.ratio_per_stack * power * 100.0), "effect": _effect_name(skill.stack_effect)}))
	if skill.reset_on_kill:
		lines.append(Loc.t("class_skill.fmt.reset_on_kill"))
	if skill.heal_ratio > 0.0:
		lines.append(Loc.t("class_skill.fmt.heal", {"value": "%.1f" % (skill.heal_ratio * power * 100.0)}))
	if skill.shield_ratio > 0.0:
		lines.append(Loc.t("class_skill.fmt.shield", {"value": "%.1f" % (skill.shield_ratio * power * 100.0)}))
	if skill.taunt:
		lines.append(Loc.t("class_skill.fmt.taunt", {"radius": roundi(skill.radius)}))
	if skill.cleanse:
		lines.append(Loc.t("class_skill.fmt.cleanse"))
	_describe_effects(lines, "class_skill.fmt.target_effects", skill.target_effects, 1.0, power)
	_describe_effects(lines, "class_skill.fmt.self_effects", skill.self_effects, 1.0, power)
	_describe_effects(lines, "class_skill.fmt.ally_effects", skill.ally_effects, 1.0, power)
	_describe_effects(lines, "class_skill.fmt.on_hit", skill.on_hit_effects, power)
	var modifiers := PackedStringArray()
	for modifier in skill.modifiers:
		modifiers.append(_modifier_text(modifier, power, modifier.condition))
	for modifier in skill.level_modifiers:
		modifiers.append(Loc.t("class_skill.fmt.per_level", {"value": _modifier_text(modifier, power, modifier.condition), "step": skill.level_step}))
	if not modifiers.is_empty():
		lines.append(" · ".join(modifiers))
	if skill.kill_heal_ratio > 0.0:
		lines.append(Loc.t("class_skill.fmt.kill_heal", {"value": "%.1f" % (skill.kill_heal_ratio * power * 100.0)}))
	if skill.trigger_hp_below > 0.0:
		lines.append(Loc.t("class_skill.fmt.trigger_hp", {"value": roundi(skill.trigger_hp_below * 100.0)}))
	if skill.is_active():
		lines.append(Loc.t("class_skill.fmt.cost", {"mana": roundi(get_mana_cost(skill, level)), "cooldown": _seconds(skill.cooldown)}))
	elif skill.is_castable():
		lines.append(Loc.t("class_skill.fmt.passive_cooldown", {"cooldown": _seconds(skill.cooldown)}))
	return "\n".join(lines)


## "6" for 6.0, "2.5" for 2.5.
static func _seconds(value: float) -> String:
	return str(int(value)) if is_equal_approx(value, roundf(value)) else "%.1f" % value


static func stat_name(stat: StringName) -> String:
	return Loc.t("stat.%s" % stat)


## `chance_power` scales on-hit chances; `duration_power` > 0 shows the scaled duration.
func _describe_effects(lines: PackedStringArray, key: String, entries: Array[StatusEffectChance], chance_power: float = 1.0, duration_power: float = 0.0) -> void:
	var power := chance_power
	var parts := PackedStringArray()
	for entry in entries:
		if entry == null or entry.effect == null:
			continue
		var text := entry.effect.display_name
		if entry.stacks > 1:
			text += " ×%d" % entry.stacks
		if duration_power > 0.0 and entry.effect.duration > 0.0:
			text += " %ss" % _seconds(snappedf(entry.effect.duration * get_duration_scale(entry.effect, duration_power), 0.1))
		var chance := minf(entry.chance * power, 1.0)
		if chance < 1.0:
			text += " (%d%%)" % roundi(chance * 100.0)
		parts.append(text)
	if not parts.is_empty():
		lines.append(Loc.t(key, {"effects": ", ".join(parts)}))


func _effect_name(effect_id: StringName) -> String:
	var effect := _registry.find_def(&"status_effect", effect_id) as StatusEffectDefinition
	return effect.display_name if effect != null else String(effect_id)


func _modifier_text(modifier: StatModifier, power: float, condition: StringName) -> String:
	var value := modifier.value * power
	var text := ""
	if modifier.type == StatModifier.Type.PERCENT or absf(modifier.value) < 1.0 or modifier.stat in HunterService.ADDITIVE_STATS:
		text = "%+.1f%% %s" % [value * 100.0, stat_name(modifier.stat)]
	else:
		text = "%+.1f %s" % [value, stat_name(modifier.stat)]
	if condition != &"":
		text += " (%s)" % Loc.t("class_skill.condition.%s" % condition)
	return text


# --- Helpers -----------------------------------------------------------------------------------

func _on_leveled_up(hunter: HunterRuntime, _level: int, _healed: float) -> void:
	sync_points(hunter)


func _unowned(hunter: HunterRuntime) -> Array[ClassSkillDefinition]:
	return get_hunter_pool(hunter).filter(func(skill: ClassSkillDefinition) -> bool: return not hunter.class_skills.has(skill.id))


func _pick_unowned(hunter: HunterRuntime) -> ClassSkillDefinition:
	var free := _unowned(hunter)
	return free[_rng.randi_range(0, free.size() - 1)]


func _scaled(modifier: StatModifier, factor: float) -> StatModifier:
	var copy := StatModifier.new()
	copy.stat = modifier.stat
	copy.type = modifier.type
	copy.condition = modifier.condition
	copy.value = modifier.value * factor
	return copy


func _changed(hunter: HunterRuntime, reason: StringName) -> void:
	_hunters.notify_changed(hunter)
	skills_changed.emit(hunter)
	autosave_requested.emit(reason)
