class_name SupplyService
extends RefCounted
## The village shop (DECISIONS.md D40, D41): Hunters buy food (Tavern) and medicine (Hospital)
## made by the chief, from the Warehouse stock, paying the item's price into the treasury.

signal item_sold(hunter: HunterRuntime, item: ItemDefinition)

const NO_FOOD := "No food in the Tavern"
const NO_MONEY_FOR_FOOD := "Cannot afford food"

var _registry: Node
var _inventory: InventoryService
var _purses: PurseService
var _hunters: HunterService
var _buildings: BuildingService


func _init(registry: Node, inventory: InventoryService, purses: PurseService, hunters: HunterService,
		buildings: BuildingService) -> void:
	_registry = registry
	_inventory = inventory
	_purses = purses
	_hunters = hunters
	_buildings = buildings


## Food items (energy > 0), most energy first.
func get_foods() -> Array[ItemDefinition]:
	return _consumables(func(item: ItemDefinition) -> bool: return item.energy > 0.0, func(item: ItemDefinition) -> float: return item.energy)


## Medicine items (heal_ratio > 0), strongest first.
func get_medicines() -> Array[ItemDefinition]:
	return _consumables(func(item: ItemDefinition) -> bool: return item.heal_ratio > 0.0, func(item: ItemDefinition) -> float: return item.heal_ratio)


## Portions of food in stock.
func get_food_stock() -> int:
	var total := 0
	for item in get_foods():
		total += _inventory.count(item.id)
	return total


## The most filling food in stock the Hunter can pay for, or null. Needs a Tavern.
func best_food(hunter: HunterRuntime) -> ItemDefinition:
	if not _buildings.has_building(BuildingService.TAVERN):
		return null
	return _best(get_foods(), hunter)


## Why a hungry Hunter cannot eat ("" = it can).
func food_reason(hunter: HunterRuntime) -> String:
	if best_food(hunter) != null:
		return ""
	return NO_FOOD if get_food_stock() <= 0 or not _buildings.has_building(BuildingService.TAVERN) else NO_MONEY_FOR_FOOD


## Sells the best food; returns it (the caller applies the energy) or null.
func buy_food(hunter: HunterRuntime) -> ItemDefinition:
	var food := best_food(hunter)
	return food if food != null and _sell(hunter, food) else null


## The strongest medicine in stock the Hunter can pay for, or null. Needs a Hospital.
func best_medicine(hunter: HunterRuntime) -> ItemDefinition:
	if not _buildings.has_building(BuildingService.HOSPITAL):
		return null
	return _best(get_medicines(), hunter)


## Buys and uses the best medicine at once (D41). Returns the HP healed (0 = none bought).
func treat(hunter: HunterRuntime) -> float:
	var medicine := best_medicine(hunter)
	if medicine == null or not _sell(hunter, medicine):
		return 0.0
	var max_hp := _hunters.get_stat(hunter, HunterService.MAX_HP)
	var healed := minf(max_hp * medicine.heal_ratio, max_hp - hunter.current_hp)
	hunter.current_hp += healed
	_hunters.notify_changed(hunter)
	return healed


func _best(items: Array[ItemDefinition], hunter: HunterRuntime) -> ItemDefinition:
	for item in items:
		if _inventory.count(item.id) > 0 and hunter.purse >= item.sell_price:
			return item
	return null


func _sell(hunter: HunterRuntime, item: ItemDefinition) -> bool:
	if _inventory.count(item.id) <= 0 or not _purses.pay_village(hunter, item.sell_price):
		return false
	_inventory.remove_item(item.id, 1)
	item_sold.emit(hunter, item)
	return true


func _consumables(keep: Callable, strength: Callable) -> Array[ItemDefinition]:
	var result: Array[ItemDefinition] = []
	for definition in _registry.get_all(&"item"):
		var item := definition as ItemDefinition
		if item.item_type == ItemDefinition.ItemType.CONSUMABLE and keep.call(item):
			result.append(item)
	result.sort_custom(func(a: ItemDefinition, b: ItemDefinition) -> bool: return strength.call(a) > strength.call(b))
	return result
