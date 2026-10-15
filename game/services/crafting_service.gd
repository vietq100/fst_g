class_name CraftingService
extends RefCounted
## Crafting in village buildings (BALANCE.md → Equipment / Village economy, DECISIONS.md D7, D9,
## D40, D41): Blacksmith equipment, Tavern food, Hospital medicine. Results go to the Warehouse.

signal item_crafted(recipe: RecipeDefinition, instance_id: StringName)
signal autosave_requested(reason: StringName)

var _registry: Node
var _buildings: BuildingService
var _wallet: WalletService
var _inventory: InventoryService


func _init(registry: Node, buildings: BuildingService, wallet: WalletService, inventory: InventoryService) -> void:
	_registry = registry
	_buildings = buildings
	_wallet = wallet
	_inventory = inventory


## Recipes of one building (empty id: all).
func get_recipes(building_id: StringName = &"") -> Array[RecipeDefinition]:
	var recipes: Array[RecipeDefinition] = []
	for definition in _registry.get_all(&"recipe"):
		var recipe := definition as RecipeDefinition
		if building_id == &"" or recipe.building_id == building_id:
			recipes.append(recipe)
	recipes.sort_custom(func(a: RecipeDefinition, b: RecipeDefinition) -> bool:
		return a.gold_cost < b.gold_cost)
	return recipes


## Empty string when the recipe can be crafted now, otherwise the reason.
func can_craft(recipe_id: StringName) -> String:
	var recipe := _registry.find_def(&"recipe", recipe_id) as RecipeDefinition
	if recipe == null:
		return Loc.t("err.craft.unknown_recipe", {"recipe": recipe_id})
	var building := _buildings.get_definition(recipe.building_id)
	var building_name := building.display_name if building != null else String(recipe.building_id)
	var level := _buildings.get_level(recipe.building_id)
	if level <= 0:
		return Loc.t("err.craft.needs_building", {"building": building_name})
	if level < recipe.required_level:
		return Loc.t("err.craft.needs_building_level", {"building": building_name, "level": recipe.required_level})
	if not _wallet.can_spend(recipe.gold_cost):
		return Loc.t("ui.common.needs_gold", {"gold": recipe.gold_cost})
	for cost in recipe.material_costs:
		if not _inventory.has(cost.item_id, cost.quantity):
			var item := _registry.find_def(&"item", cost.item_id) as ItemDefinition
			return Loc.t("err.craft.needs_items", {"count": cost.quantity, "item": item.display_name if item != null else String(cost.item_id)})
	var result := _registry.find_def(&"item", recipe.result_item_id) as ItemDefinition
	var stacks_onto_existing := result != null and result.stackable and _inventory.count(recipe.result_item_id) > 0
	if _inventory.free_slots() <= 0 and not stacks_onto_existing:
		return Loc.t("err.craft.warehouse_full")
	return ""


## Returns the new instance id (equipment) or the result item id (stackables), or &"" if it
## cannot be crafted.
func craft(recipe_id: StringName) -> StringName:
	if not can_craft(recipe_id).is_empty():
		return &""
	var recipe := _registry.find_def(&"recipe", recipe_id) as RecipeDefinition
	_wallet.spend(recipe.gold_cost)
	for cost in recipe.material_costs:
		_inventory.remove_item(cost.item_id, cost.quantity)
	var result := _registry.find_def(&"item", recipe.result_item_id) as ItemDefinition
	var before := _inventory.get_instances_of(recipe.result_item_id)
	_inventory.add_item(recipe.result_item_id, maxi(recipe.result_quantity, 1))
	var instance_id := recipe.result_item_id if result != null and result.stackable else &""
	for candidate in _inventory.get_instances_of(recipe.result_item_id):
		if not before.has(candidate):
			instance_id = candidate
	item_crafted.emit(recipe, instance_id)
	autosave_requested.emit(&"crafting")
	return instance_id
