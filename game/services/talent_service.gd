class_name TalentService
extends RefCounted
## Talents (DECISIONS.md D46): Cooks and Herbalists make food / medicine in the field from the
## materials in their own loot bag, with the village recipes but no building. Every Hunter eats
## food and uses medicine from its own bag before anything else. The crafting time is spent by
## the Hunter brain; this service only applies the results.

signal crafted_in_field(hunter: HunterRuntime, recipe: RecipeDefinition)

enum Kind { FOOD, MEDICINE }

var _registry: Node
var _hunters: HunterService
var _regions: RegionService
var _config: GameConfig
var _rng: RandomNumberGenerator


func _init(registry: Node, hunters: HunterService, regions: RegionService, config: GameConfig,
		rng: RandomNumberGenerator) -> void:
	_registry = registry
	_hunters = hunters
	_regions = regions
	_config = config
	_rng = rng


func get_talent(hunter: HunterRuntime) -> TalentDefinition:
	return _registry.find_def(&"talent", hunter.talent_id) as TalentDefinition if hunter.talent_id != &"" else null


## Rolls a talent (or none) for a Tavern candidate / new Hunter (BALANCE.md → Talents).
func assign_random_talent(hunter: HunterRuntime) -> void:
	var talents: Array[TalentDefinition] = []
	var total := _config.talent_none_weight
	for definition in _registry.get_all(&"talent"):
		var talent := definition as TalentDefinition
		talents.append(talent)
		total += maxf(talent.weight, 0.0)
	hunter.talent_id = &""
	var roll := _rng.randf() * total
	for talent in talents:
		roll -= maxf(talent.weight, 0.0)
		if roll < 0.0:
			hunter.talent_id = talent.id
			return


## The first recipe of the Hunter's talent that makes `kind` and whose ingredients are in its bag.
func pick_recipe(hunter: HunterRuntime, kind: Kind) -> RecipeDefinition:
	var talent := get_talent(hunter)
	if talent == null:
		return null
	for recipe_id in talent.recipe_ids:
		var recipe := _registry.find_def(&"recipe", recipe_id) as RecipeDefinition
		if recipe != null and _makes(recipe, kind) and _has_ingredients(hunter, recipe):
			return recipe
	return null


## Uses the bag's ingredients and puts the result into the bag (what does not fit is lost).
## Returns false if the ingredients are gone.
func make_from_bag(hunter: HunterRuntime, recipe: RecipeDefinition) -> bool:
	if recipe == null or not _has_ingredients(hunter, recipe):
		return false
	for cost in recipe.material_costs:
		_regions.remove_from_bag(hunter, cost.item_id, cost.quantity)
	_regions.add_to_bag(hunter, recipe.result_item_id, maxi(recipe.result_quantity, 1))
	crafted_in_field.emit(hunter, recipe)
	return true


## Eats the most filling food in the bag (free). Returns the energy gained (0 = none).
func eat_from_bag(hunter: HunterRuntime) -> float:
	var food := _best_in_bag(hunter, Kind.FOOD)
	if food == null:
		return 0.0
	_regions.remove_from_bag(hunter, food.id, 1)
	var gained := minf(food.energy, _config.needs_max - hunter.energy)
	hunter.energy += gained
	return maxf(gained, 0.001)


## Uses the strongest medicine in the bag (free). Returns the HP healed (0 = none).
func use_medicine_from_bag(hunter: HunterRuntime) -> float:
	var medicine := _best_in_bag(hunter, Kind.MEDICINE)
	if medicine == null:
		return 0.0
	_regions.remove_from_bag(hunter, medicine.id, 1)
	var max_hp := _hunters.get_stat(hunter, HunterService.MAX_HP)
	var healed := minf(max_hp * medicine.heal_ratio, max_hp - hunter.current_hp)
	hunter.current_hp += healed
	_hunters.notify_changed(hunter)
	return maxf(healed, 0.001)


func has_in_bag(hunter: HunterRuntime, kind: Kind) -> bool:
	return _best_in_bag(hunter, kind) != null


func _best_in_bag(hunter: HunterRuntime, kind: Kind) -> ItemDefinition:
	var best: ItemDefinition = null
	for item_id in hunter.loot_bag:
		var item := _registry.find_def(&"item", item_id) as ItemDefinition
		if item == null or hunter.loot_bag[item_id] <= 0:
			continue
		var value := item.energy if kind == Kind.FOOD else item.heal_ratio
		if value > 0.0 and (best == null or value > (best.energy if kind == Kind.FOOD else best.heal_ratio)):
			best = item
	return best


func _makes(recipe: RecipeDefinition, kind: Kind) -> bool:
	var item := _registry.find_def(&"item", recipe.result_item_id) as ItemDefinition
	if item == null:
		return false
	return item.energy > 0.0 if kind == Kind.FOOD else item.heal_ratio > 0.0


func _has_ingredients(hunter: HunterRuntime, recipe: RecipeDefinition) -> bool:
	for cost in recipe.material_costs:
		if hunter.loot_bag.get(cost.item_id, 0) < cost.quantity:
			return false
	return true
