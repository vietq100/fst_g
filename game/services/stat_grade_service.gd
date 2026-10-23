class_name StatGradeService
extends RefCounted
## Grades every stat, and an object's total, against the average of its kind (DECISIONS.md D80):
## a ten-step colour ladder where blue means "average" (BALANCE.md → Stat grades). The averages
## are built from the data when the game loads: Hunters per level from every class definition
## (tier C, no gear, no rolls), monsters per level from the regular (non-boss) enemy definitions,
## gear per equipment slot from the items that carry the same bonus. Evaluation and colour only:
## nothing here changes a number used in combat.

enum Step { POOR, PLAIN, AVERAGE, GOOD, FINE, STRONG, EXCELLENT, ELITE, LEGENDARY, SUPREME }

## Colour per step: grey · white · blue (average) · deep blue · orange · red · gold · sky · emerald · violet.
const COLORS: Array[Color] = [Color("8a8f98"), Color("f4f1ea"), Color("5fa8ff"), Color("3a6fd8"), Color("ff9a3d"),
	Color("ff5a5a"), Color("ffd23f"), Color("8fe3ff"), Color("3ddc97"), Color("c77dff")]
const NAME_KEYS: Array[String] = ["grade.poor.name", "grade.plain.name", "grade.average.name", "grade.good.name",
	"grade.fine.name", "grade.strong.name", "grade.excellent.name", "grade.elite.name", "grade.legendary.name",
	"grade.supreme.name"]
## Lower bound of each step from PLAIN up, as value / average; below the first bound is POOR.
const BOUNDS: Array[float] = [0.6, 0.85, 1.15, 1.4, 1.75, 2.2, 2.8, 3.6, 5.0]
## One stat's ratio counts at most this much in a total, so one freak bonus does not carry it.
const RATIO_CAP := 8.0

## Graded Hunter stats and their weight in the Hunter's total.
const HUNTER_STATS: Dictionary = {
	HunterService.MAX_HP: 1.0, HunterService.ATTACK: 1.0, HunterService.DEFENSE: 1.0,
	HunterService.ATTACK_SPEED: 0.5, HunterService.CRITICAL_CHANCE: 0.25, HunterService.CRITICAL_DAMAGE: 0.25,
	HunterService.MOVE_SPEED: 0.25,
}
## Graded monster stats (EnemyDefinition fields) and their weight in the monster's total.
const MONSTER_STATS: Dictionary = {
	&"hp": 1.0, &"attack": 1.0, &"defense": 1.0, &"attack_speed": 0.5, &"critical_chance": 0.25,
	&"critical_damage": 0.25, &"move_speed": 0.25,
}
## Monster stats that grow with the level scale (RegionService.get_stat_scale × Tier.stat_scale).
const MONSTER_SCALED: Array[StringName] = [&"hp", &"attack", &"defense"]

var _hunters: HunterService
var _stats: StatService
## stat → {"base": mean base, "growth": mean growth per level} over the class definitions.
var _hunter_average: Dictionary = {}
## stat → mean base value over the regular enemy definitions.
var _monster_average: Dictionary = {}
## equipment slot → ("stat|type" → mean modifier value) over the items of that slot.
var _item_average: Dictionary = {}
## ClassSkillDefinition.Kind → mean of the skills' display stars.
var _skill_average: Dictionary = {}
## Hunter unique id → {"ratios": stat → ratio, "total": float, "until": ticks ms}: a Hunter's grades
## are asked for by every card and row, so they are computed once and kept until the Hunter changes
## (HunterService.hunter_changed) or CACHE_MS pass (a modifier source that changes silently).
var _hunter_cache: Dictionary = {}
const CACHE_MS := 2000


func _init(registry: Node, stats: StatService, hunters: HunterService) -> void:
	_stats = stats
	_hunters = hunters
	if hunters != null:
		hunters.hunter_changed.connect(invalidate)
		hunters.hunter_removed.connect(invalidate)
	_build_hunter_average(registry)
	_build_monster_average(registry)
	_build_item_average(registry)
	_build_skill_average(registry)


# --- Ladder --------------------------------------------------------------------------------------

## Step (a `Step` value) of a value / average ratio.
static func step_of(ratio: float) -> int:
	var step := 0
	for bound in BOUNDS:
		if ratio < bound:
			break
		step += 1
	return step


static func color(step: int) -> Color:
	return COLORS[clampi(step, 0, COLORS.size() - 1)]


static func name_of(step: int) -> String:
	return Loc.t(NAME_KEYS[clampi(step, 0, NAME_KEYS.size() - 1)])


## value / average, or 1 (average) when there is no average to compare with.
static func ratio_of(value: float, average: float) -> float:
	if average <= 0.0:
		return 1.0
	return maxf(value, 0.0) / average


## Weighted mean of ratios (each capped at RATIO_CAP): the total of an object.
static func total_of(ratios: Array[float], weights: Array[float]) -> float:
	var sum := 0.0
	var weight_sum := 0.0
	for i in ratios.size():
		var weight: float = weights[i] if i < weights.size() else 1.0
		sum += minf(ratios[i], RATIO_CAP) * weight
		weight_sum += weight
	return sum / weight_sum if weight_sum > 0.0 else 1.0


# --- Hunters ---------------------------------------------------------------------------------------

## What the average Hunter of `level` has for `stat` (tier C, no gear, no rolls).
func hunter_average(stat: StringName, level: int) -> float:
	var entry: Dictionary = _hunter_average.get(stat, {})
	if entry.is_empty():
		return 0.0
	return _stats.compute_stat(stat, entry["base"], entry["growth"], level)


func hunter_ratio(hunter: HunterRuntime, stat: StringName) -> float:
	var ratios: Dictionary = _hunter_entry(hunter)["ratios"]
	if ratios.has(stat):
		return ratios[stat]
	return ratio_of(_hunters.get_stat(hunter, stat), hunter_average(stat, hunter.level))


func hunter_step(hunter: HunterRuntime, stat: StringName) -> int:
	return step_of(hunter_ratio(hunter, stat))


## The Hunter's total over HUNTER_STATS, as a ratio to the average Hunter of its level.
func hunter_total(hunter: HunterRuntime) -> float:
	return _hunter_entry(hunter)["total"]


## Forgets a Hunter's cached grades (its stats changed).
func invalidate(hunter: HunterRuntime) -> void:
	if hunter != null:
		_hunter_cache.erase(hunter.unique_id)


## The Hunter's cached ratios and total, computed now when missing or stale.
func _hunter_entry(hunter: HunterRuntime) -> Dictionary:
	var now := Time.get_ticks_msec()
	var cached := hunter.unique_id != &""
	var entry: Dictionary = _hunter_cache.get(hunter.unique_id, {}) if cached else {}
	if not entry.is_empty() and now <= int(entry["until"]):
		return entry
	var ratios: Dictionary = {}
	var values: Array[float] = []
	var weights: Array[float] = []
	for stat: StringName in HUNTER_STATS:
		var ratio := ratio_of(_hunters.get_stat(hunter, stat), hunter_average(stat, hunter.level))
		ratios[stat] = ratio
		values.append(ratio)
		weights.append(HUNTER_STATS[stat])
	entry = {"ratios": ratios, "total": total_of(values, weights), "until": now + CACHE_MS}
	if cached:
		_hunter_cache[hunter.unique_id] = entry
	return entry


func hunter_grade(hunter: HunterRuntime) -> int:
	return step_of(hunter_total(hunter))


# --- Monsters --------------------------------------------------------------------------------------

## What the average regular monster has for `stat` at a level scale (RegionService.get_stat_scale
## × Tier.stat_scale for the tier being compared against; 1 for the base).
func monster_average(stat: StringName, scale: float = 1.0) -> float:
	var base: float = _monster_average.get(stat, 0.0)
	return base * scale if MONSTER_SCALED.has(stat) else base


func monster_ratio(stat: StringName, value: float, scale: float) -> float:
	return ratio_of(value, monster_average(stat, scale))


func monster_step(stat: StringName, value: float, scale: float) -> int:
	return step_of(monster_ratio(stat, value, scale))


## Total over the `values` given (stat → value, MONSTER_STATS keys) against the average at `scale`.
func monster_total(values: Dictionary, scale: float) -> float:
	var ratios: Array[float] = []
	var weights: Array[float] = []
	for stat: StringName in MONSTER_STATS:
		if not values.has(stat):
			continue
		ratios.append(monster_ratio(stat, values[stat], scale))
		weights.append(MONSTER_STATS[stat])
	return total_of(ratios, weights)


func monster_grade(values: Dictionary, scale: float) -> int:
	return step_of(monster_total(values, scale))


# --- Items -----------------------------------------------------------------------------------------

## Mean value of the same bonus (stat and flat / percent) over the gear of the item's slot.
func item_average(item: ItemDefinition, modifier: StatModifier) -> float:
	var slot_average: Dictionary = _item_average.get(item.equipment_slot, {})
	return slot_average.get(_modifier_key(modifier), 0.0)


## Ratio of one bonus to the slot's average; a penalty (negative value) compares by size.
func item_ratio(item: ItemDefinition, modifier: StatModifier) -> float:
	return ratio_of(absf(modifier.value), absf(item_average(item, modifier)))


func item_step(item: ItemDefinition, modifier: StatModifier) -> int:
	return step_of(item_ratio(item, modifier))


## Mean ratio over the item's bonuses; 1 (average) for an item without bonuses.
func item_total(item: ItemDefinition) -> float:
	var ratios: Array[float] = []
	for modifier in item.modifiers:
		if modifier != null:
			ratios.append(item_ratio(item, modifier))
	return total_of(ratios, [])


func item_grade(item: ItemDefinition) -> int:
	return step_of(item_total(item))


## The item's total with a Forge enhancement of `enhance` levels: every bonus scales alike
## (EquipmentService.ENHANCE_BONUS), so the total does too.
func item_total_enhanced(item: ItemDefinition, enhance: int) -> float:
	return item_total(item) * (1.0 + EquipmentService.ENHANCE_BONUS * maxi(enhance, 0))


## How much better `candidate` (+`candidate_enhance`) is than `worn` (+`worn_enhance`): its total
## minus the worn total (0.4 = better by 40 % of an average item's bonuses). `worn` null compares
## with an empty slot (from zero).
func item_delta(candidate: ItemDefinition, worn: ItemDefinition, candidate_enhance: int = 0, worn_enhance: int = 0) -> float:
	var worn_total := item_total_enhanced(worn, worn_enhance) if worn != null else 0.0
	return item_total_enhanced(candidate, candidate_enhance) - worn_total


# --- Class skills ----------------------------------------------------------------------------------

## A class skill's power for grading: the mean of its three display stars (monsters, people, bosses).
static func skill_power(skill: ClassSkillDefinition) -> float:
	return (skill.ratings.x + skill.ratings.y + skill.ratings.z) / 3.0


## Against the mean of the skills of the same kind (active / passive).
func skill_ratio(skill: ClassSkillDefinition) -> float:
	return ratio_of(skill_power(skill), _skill_average.get(skill.kind, 0.0))


func skill_grade(skill: ClassSkillDefinition) -> int:
	return step_of(skill_ratio(skill))


# --- Gear suggestions ------------------------------------------------------------------------------

## Stored gear worth putting on: slot → the instance whose total (enhancement included) beats the
## worn piece's by the most. A broken worn piece counts as nothing; broken stored gear is skipped.
func suggest_gear(hunter: HunterRuntime, inventory: InventoryService, equipment: EquipmentService) -> Dictionary:
	var best: Dictionary = {}
	var best_delta: Dictionary = {}
	var instances := inventory.get_instances()
	for instance_id: StringName in instances:
		var item := equipment.get_item(instance_id)
		if item == null or not EquipmentService.SLOT_NAMES.has(item.equipment_slot) or equipment.is_broken(instance_id):
			continue
		var slot: StringName = EquipmentService.SLOT_NAMES[item.equipment_slot]
		var worn_id: StringName = hunter.equipment.get(slot, &"")
		var worn := equipment.get_item(worn_id) if worn_id != &"" and not equipment.is_broken(worn_id) else null
		var delta := item_delta(item, worn, inventory.get_enhance(instance_id), inventory.get_enhance(worn_id) if worn != null else 0)
		if delta > 0.0001 and delta > float(best_delta.get(slot, 0.0)):
			best[slot] = instance_id
			best_delta[slot] = delta
	return best


# --- Averages from the data ------------------------------------------------------------------------

func _build_skill_average(registry: Node) -> void:
	var sums: Dictionary = {}
	var counts: Dictionary = {}
	for definition: ClassSkillDefinition in registry.get_all(&"class_skill"):
		if definition == null:
			continue
		sums[definition.kind] = float(sums.get(definition.kind, 0.0)) + skill_power(definition)
		counts[definition.kind] = int(counts.get(definition.kind, 0)) + 1
	for kind in sums:
		_skill_average[kind] = sums[kind] / counts[kind]


func _build_hunter_average(registry: Node) -> void:
	var definitions: Array[GameDefinition] = registry.get_all(&"hunter")
	var count := 0
	var sums: Dictionary = {}
	for stat: StringName in HUNTER_STATS:
		sums[stat] = {"base": 0.0, "growth": 0.0}
	for definition: HunterDefinition in definitions:
		if definition == null:
			continue
		count += 1
		sums[HunterService.MAX_HP]["base"] += definition.base_hp
		sums[HunterService.MAX_HP]["growth"] += definition.hp_per_level
		sums[HunterService.ATTACK]["base"] += definition.base_attack
		sums[HunterService.ATTACK]["growth"] += definition.attack_per_level
		sums[HunterService.DEFENSE]["base"] += definition.base_defense
		sums[HunterService.DEFENSE]["growth"] += definition.defense_per_level
		sums[HunterService.ATTACK_SPEED]["base"] += definition.attack_speed
		sums[HunterService.CRITICAL_CHANCE]["base"] += definition.critical_chance
		sums[HunterService.CRITICAL_DAMAGE]["base"] += definition.critical_damage
		sums[HunterService.MOVE_SPEED]["base"] += definition.move_speed
	if count == 0:
		return
	for stat: StringName in sums:
		_hunter_average[stat] = {"base": sums[stat]["base"] / count, "growth": sums[stat]["growth"] / count}


func _build_monster_average(registry: Node) -> void:
	var definitions: Array[GameDefinition] = registry.get_all(&"enemy")
	var count := 0
	var sums: Dictionary = {}
	for stat: StringName in MONSTER_STATS:
		sums[stat] = 0.0
	for definition: EnemyDefinition in definitions:
		if definition == null or definition.is_boss:
			continue
		count += 1
		for stat: StringName in MONSTER_STATS:
			sums[stat] += float(definition.get(stat))
	if count == 0:
		return
	for stat: StringName in sums:
		_monster_average[stat] = sums[stat] / count


func _build_item_average(registry: Node) -> void:
	var definitions: Array[GameDefinition] = registry.get_all(&"item")
	var sums: Dictionary = {}
	var counts: Dictionary = {}
	for definition: ItemDefinition in definitions:
		if definition == null or definition.equipment_slot == ItemDefinition.EquipmentSlot.NONE:
			continue
		var slot_sums: Dictionary = sums.get_or_add(definition.equipment_slot, {})
		var slot_counts: Dictionary = counts.get_or_add(definition.equipment_slot, {})
		for modifier in definition.modifiers:
			if modifier == null:
				continue
			var key := _modifier_key(modifier)
			slot_sums[key] = slot_sums.get(key, 0.0) + absf(modifier.value)
			slot_counts[key] = slot_counts.get(key, 0) + 1
	for slot in sums:
		var average: Dictionary = {}
		for key in sums[slot]:
			average[key] = sums[slot][key] / counts[slot][key]
		_item_average[slot] = average


static func _modifier_key(modifier: StatModifier) -> String:
	return "%s|%d" % [modifier.stat, modifier.type]
