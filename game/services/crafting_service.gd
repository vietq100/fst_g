class_name CraftingService
extends RefCounted
## Blacksmith crafting (BALANCE.md → Equipment, DECISIONS.md D7, D9).

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


func get_recipes() -> Array[RecipeDefinition]:
	var recipes: Array[RecipeDefinition] = []
	for definition in _registry.get_all(&"recipe"):
		recipes.append(definition as RecipeDefinition)
	recipes.sort_custom(func(a: RecipeDefinition, b: RecipeDefinition) -> bool:
		return a.gold_cost < b.gold_cost)
	return recipes


## Empty string when the recipe can be crafted now, otherwise the reason.
func can_craft(recipe_id: StringName) -> String:
	var recipe := _registry.find_def(&"recipe", recipe_id) as RecipeDefinition
	if recipe == null:
		return "Unknown recipe '%s'" % recipe_id
	var level := int(_buildings.get_effect(BuildingService.BLACKSMITH, BuildingService.RECIPE_LEVEL))
	if level < recipe.required_blacksmith_level:
		return "Needs Blacksmith Lv %d" % recipe.required_blacksmith_level
	if not _wallet.can_spend(recipe.gold_cost):
		return "Needs %d gold" % recipe.gold_cost
	for cost in recipe.material_costs:
		if not _inventory.has(cost.item_id, cost.quantity):
			var item := _registry.find_def(&"item", cost.item_id) as ItemDefinition
			return "Needs %d %s" % [cost.quantity, item.display_name if item != null else String(cost.item_id)]
	if _inventory.free_slots() <= 0:
		return "Warehouse is full"
	return ""


## Returns the new instance id, or &"" if it cannot be crafted.
func craft(recipe_id: StringName) -> StringName:
	if not can_craft(recipe_id).is_empty():
		return &""
	var recipe := _registry.find_def(&"recipe", recipe_id) as RecipeDefinition
	_wallet.spend(recipe.gold_cost)
	for cost in recipe.material_costs:
		_inventory.remove_item(cost.item_id, cost.quantity)
	var before := _inventory.get_instances_of(recipe.result_item_id)
	_inventory.add_item(recipe.result_item_id, 1)
	var instance_id := &""
	for candidate in _inventory.get_instances_of(recipe.result_item_id):
		if not before.has(candidate):
			instance_id = candidate
	item_crafted.emit(recipe, instance_id)
	autosave_requested.emit(&"crafting")
	return instance_id
