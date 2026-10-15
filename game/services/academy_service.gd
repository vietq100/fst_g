class_name AcademyService
extends RefCounted
## Academy (Evil Hunter Tycoon style): Hunters train skills for gold and learn traits with
## reincarnation points. Skills add their modifiers once per level.

signal skill_learned(hunter: HunterRuntime, skill: SkillDefinition, level: int)
signal trait_learned(hunter: HunterRuntime, trait_id: StringName)
signal class_changed(hunter: HunterRuntime, class_id: StringName)
signal trait_forgotten(hunter: HunterRuntime, trait_id: StringName)
signal autosave_requested(reason: StringName)

## Reincarnations a Hunter needs before it may change class, and the gold price.
const PROMOTION_REINCARNATIONS := 2
const PROMOTION_COST := 5000
## Gold to make a Hunter forget a trait.
const FORGET_COST := 300

var _registry: Node
var _hunters: HunterService
var _buildings: BuildingService
var _wallet: WalletService


func _init(registry: Node, hunters: HunterService, buildings: BuildingService, wallet: WalletService) -> void:
	_registry = registry
	_hunters = hunters
	_buildings = buildings
	_wallet = wallet
	_hunters.add_modifier_source(get_modifiers)


func get_modifiers(hunter: HunterRuntime) -> Array[StatModifier]:
	var modifiers: Array[StatModifier] = []
	for skill_id in hunter.skills:
		var skill := get_skill(skill_id)
		if skill == null:
			continue
		for modifier in skill.modifiers:
			var scaled := StatModifier.new()
			scaled.stat = modifier.stat
			scaled.type = modifier.type
			scaled.value = modifier.value * hunter.skills[skill_id]
			scaled.condition = modifier.condition
			modifiers.append(scaled)
	return modifiers


func get_skill(skill_id: StringName) -> SkillDefinition:
	return _registry.find_def(&"skill", skill_id) as SkillDefinition


func get_skills() -> Array[SkillDefinition]:
	var result: Array[SkillDefinition] = []
	for definition in _registry.get_all(&"skill"):
		result.append(definition as SkillDefinition)
	result.sort_custom(func(a: SkillDefinition, b: SkillDefinition) -> bool:
		return a.required_academy_level < b.required_academy_level or (a.required_academy_level == b.required_academy_level and a.gold_per_level < b.gold_per_level))
	return result


func get_skill_level(hunter: HunterRuntime, skill_id: StringName) -> int:
	return hunter.skills.get(skill_id, 0)


func get_next_skill_cost(hunter: HunterRuntime, skill: SkillDefinition) -> int:
	return skill.gold_per_level * (get_skill_level(hunter, skill.id) + 1)


func can_learn_skill(hunter: HunterRuntime, skill_id: StringName) -> String:
	var skill := get_skill(skill_id)
	if hunter == null or skill == null:
		return Loc.t("err.academy.unknown_skill")
	var academy := _buildings.get_level(BuildingService.ACADEMY)
	if academy <= 0:
		return Loc.t("err.academy.no_academy")
	if academy < skill.required_academy_level:
		return Loc.t("err.academy.needs_level", {"level": skill.required_academy_level})
	if get_skill_level(hunter, skill_id) >= skill.max_level:
		return Loc.t("err.academy.max_level")
	if not hunter.alive or hunter.injured:
		return Loc.t("err.academy.hurt", {"name": hunter.display_name})
	var cost := get_next_skill_cost(hunter, skill)
	if not _wallet.can_spend(cost):
		return Loc.t("ui.common.needs_gold", {"gold": cost})
	return ""


func learn_skill(hunter: HunterRuntime, skill_id: StringName) -> bool:
	if not can_learn_skill(hunter, skill_id).is_empty():
		return false
	var skill := get_skill(skill_id)
	_wallet.spend(get_next_skill_cost(hunter, skill))
	hunter.skills[skill_id] = get_skill_level(hunter, skill_id) + 1
	_hunters.notify_changed(hunter)
	skill_learned.emit(hunter, skill, hunter.skills[skill_id])
	autosave_requested.emit(&"academy")
	return true


# --- Traits -------------------------------------------------------------------------------------

func get_max_traits() -> int:
	return int(_buildings.get_effect(BuildingService.ACADEMY, BuildingService.MAX_TRAITS, 2.0))


## Traits that can be taught (academy_cost > 0) and the Hunter does not have.
func get_learnable_traits(hunter: HunterRuntime) -> Array[TraitDefinition]:
	var result: Array[TraitDefinition] = []
	for definition in _registry.get_all(&"trait"):
		var trait_def := definition as TraitDefinition
		if trait_def.academy_cost > 0 and not hunter.trait_ids.has(trait_def.id):
			result.append(trait_def)
	result.sort_custom(func(a: TraitDefinition, b: TraitDefinition) -> bool:
		return a.academy_cost < b.academy_cost or (a.academy_cost == b.academy_cost and a.display_name < b.display_name))
	return result


func can_learn_trait(hunter: HunterRuntime, trait_id: StringName) -> String:
	var trait_def := _registry.find_def(&"trait", trait_id) as TraitDefinition
	if hunter == null or trait_def == null or trait_def.academy_cost <= 0:
		return Loc.t("err.academy.not_learnable")
	if not _buildings.has_building(BuildingService.ACADEMY):
		return Loc.t("err.academy.no_academy")
	if hunter.trait_ids.has(trait_id):
		return Loc.t("err.academy.already_known")
	if hunter.trait_ids.size() >= get_max_traits():
		return Loc.t("err.academy.traits_full", {"max": get_max_traits()})
	if hunter.rebirth_points < trait_def.academy_cost:
		return Loc.t("err.academy.needs_rebirth_points", {"points": trait_def.academy_cost})
	return ""


func learn_trait(hunter: HunterRuntime, trait_id: StringName) -> bool:
	if not can_learn_trait(hunter, trait_id).is_empty():
		return false
	var trait_def := _registry.find_def(&"trait", trait_id) as TraitDefinition
	hunter.rebirth_points -= trait_def.academy_cost
	hunter.trait_ids.append(trait_id)
	_hunters.notify_changed(hunter)
	trait_learned.emit(hunter, trait_id)
	autosave_requested.emit(&"academy")
	return true


func can_forget_trait(hunter: HunterRuntime, trait_id: StringName) -> String:
	if not _buildings.has_building(BuildingService.ACADEMY):
		return Loc.t("err.academy.no_academy")
	if hunter == null or not hunter.trait_ids.has(trait_id):
		return Loc.t("err.academy.unknown_trait")
	if not _wallet.can_spend(FORGET_COST):
		return Loc.t("ui.common.needs_gold", {"gold": FORGET_COST})
	return ""


func forget_trait(hunter: HunterRuntime, trait_id: StringName) -> bool:
	if not can_forget_trait(hunter, trait_id).is_empty():
		return false
	_wallet.spend(FORGET_COST)
	hunter.trait_ids.erase(trait_id)
	_hunters.notify_changed(hunter)
	trait_forgotten.emit(hunter, trait_id)
	autosave_requested.emit(&"academy")
	return true


# --- Class change ---------------------------------------------------------------------------------

## Subclasses a Hunter of a base class can become.
func get_promotions(hunter: HunterRuntime) -> Array[HunterDefinition]:
	var result: Array[HunterDefinition] = []
	for definition in _registry.get_all(&"hunter"):
		var hunter_def := definition as HunterDefinition
		if hunter_def.promotion_of == hunter.definition_id:
			result.append(hunter_def)
	return result


func can_change_class(hunter: HunterRuntime, class_id: StringName) -> String:
	if not _buildings.has_building(BuildingService.ACADEMY):
		return Loc.t("err.academy.no_academy")
	var target := _registry.find_def(&"hunter", class_id) as HunterDefinition
	if hunter == null or target == null or target.promotion_of != hunter.definition_id:
		return Loc.t("err.academy.not_promotion", {"class": hunter.definition_id if hunter != null else "?"})
	if hunter.reincarnations < PROMOTION_REINCARNATIONS:
		return Loc.t("err.academy.needs_reincarnations", {"count": PROMOTION_REINCARNATIONS})
	if not hunter.alive or hunter.injured:
		return Loc.t("err.academy.hurt", {"name": hunter.display_name})
	if not _wallet.can_spend(PROMOTION_COST):
		return Loc.t("ui.common.needs_gold", {"gold": PROMOTION_COST})
	return ""


func change_class(hunter: HunterRuntime, class_id: StringName) -> bool:
	if not can_change_class(hunter, class_id).is_empty():
		return false
	_wallet.spend(PROMOTION_COST)
	hunter.definition_id = class_id
	_hunters.notify_changed(hunter)
	class_changed.emit(hunter, class_id)
	autosave_requested.emit(&"academy")
	return true
