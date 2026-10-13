class_name ForgeService
extends RefCounted
## Enhancement Forge (Evil Hunter Tycoon style): equipment instances gain enhancement levels that
## raise the stats of their modifiers. The cap comes from the Forge level.

signal enhanced(instance_id: StringName, level: int)
signal autosave_requested(reason: StringName)

const ORE := &"iron_ore"

var _registry: Node
var _buildings: BuildingService
var _wallet: WalletService
var _inventory: InventoryService
var _config: GameConfig
var _hunters: HunterService


func _init(registry: Node, buildings: BuildingService, wallet: WalletService, inventory: InventoryService,
		hunters: HunterService, config: GameConfig) -> void:
	_registry = registry
	_buildings = buildings
	_wallet = wallet
	_inventory = inventory
	_hunters = hunters
	_config = config


func get_max_level() -> int:
	return int(_buildings.get_effect(BuildingService.FORGE, BuildingService.MAX_ENHANCE, 0.0))


func get_level(instance_id: StringName) -> int:
	return _inventory.get_enhance(instance_id)


func get_gold_cost(instance_id: StringName) -> int:
	return roundi(_config.enhance_gold_base * pow(get_level(instance_id) + 1.0, 1.5))


func get_ore_cost(instance_id: StringName) -> int:
	return _config.enhance_ore_per_level * (get_level(instance_id) + 1)


## Empty string when the item can be enhanced now.
func can_enhance(instance_id: StringName) -> String:
	var item_id := _inventory.get_instance_item(instance_id)
	var item := _registry.find_def(&"item", item_id) as ItemDefinition
	if item == null or item.equipment_slot == ItemDefinition.EquipmentSlot.NONE:
		return Loc.t("err.forge.not_equipment")
	if not _buildings.has_building(BuildingService.FORGE):
		return Loc.t("err.forge.no_forge")
	if get_level(instance_id) >= get_max_level():
		return Loc.t("err.forge.limit", {"max": get_max_level()})
	if not _wallet.can_spend(get_gold_cost(instance_id)):
		return Loc.t("ui.common.needs_gold", {"gold": get_gold_cost(instance_id)})
	if not _inventory.has(ORE, get_ore_cost(instance_id)):
		var ore := _registry.find_def(&"item", ORE) as ItemDefinition
		return Loc.t("err.forge.needs_items", {"count": get_ore_cost(instance_id), "item": ore.display_name if ore != null else String(ORE)})
	return ""


func enhance(instance_id: StringName) -> bool:
	if not can_enhance(instance_id).is_empty():
		return false
	_wallet.spend(get_gold_cost(instance_id))
	_inventory.remove_item(ORE, get_ore_cost(instance_id))
	_inventory.set_enhance(instance_id, get_level(instance_id) + 1)
	var wearer: StringName = _inventory.get_equipped().get(instance_id, &"")
	if wearer != &"":
		var hunter := _hunters.get_hunter(wearer)
		if hunter != null:
			_hunters.notify_changed(hunter)
	enhanced.emit(instance_id, get_level(instance_id))
	autosave_requested.emit(&"forge")
	return true
