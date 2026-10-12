class_name EquipmentService
extends RefCounted
## Equip / unequip rules and equipment stat modifiers (INVENTORY_SYSTEM.md → Equipment).
## HunterRuntime.equipment maps slot name -> instance id; the instance's item gives modifiers.

signal equipment_changed(hunter: HunterRuntime)

const SLOT_NAMES := {
	ItemDefinition.EquipmentSlot.WEAPON: &"weapon",
	ItemDefinition.EquipmentSlot.ARMOR: &"armor",
	ItemDefinition.EquipmentSlot.ACCESSORY: &"accessory",
}

## Stat growth per Forge level (mirrors GameConfig.enhance_stat_bonus).
const ENHANCE_BONUS := 0.12

var _registry: Node
var _hunters: HunterService
var _inventory: InventoryService


func _init(registry: Node, hunters: HunterService, inventory: InventoryService) -> void:
	_registry = registry
	_hunters = hunters
	_inventory = inventory
	_hunters.add_modifier_source(get_modifiers)


func get_modifiers(hunter: HunterRuntime) -> Array[StatModifier]:
	var modifiers: Array[StatModifier] = []
	for slot in hunter.equipment:
		var instance_id: StringName = hunter.equipment[slot]
		var item := get_item(instance_id)
		if item == null:
			continue
		var enhance := _inventory.get_enhance(instance_id)
		if enhance <= 0:
			modifiers.append_array(item.modifiers)
			continue
		# Forge enhancement scales every modifier of the item.
		for modifier in item.modifiers:
			var scaled := StatModifier.new()
			scaled.stat = modifier.stat
			scaled.type = modifier.type
			scaled.value = modifier.value * (1.0 + ENHANCE_BONUS * enhance)
			scaled.condition = modifier.condition
			modifiers.append(scaled)
	return modifiers


func get_item(instance_id: StringName) -> ItemDefinition:
	return _registry.find_def(&"item", _inventory.get_instance_item(instance_id)) as ItemDefinition


func get_equipped_item(hunter: HunterRuntime, slot: StringName) -> ItemDefinition:
	return get_item(hunter.equipment.get(slot, &""))


## Empty string on success, otherwise the reason. Swaps out whatever is in that slot.
func equip(hunter: HunterRuntime, instance_id: StringName) -> String:
	if hunter.expedition_id != &"":
		return "%s is on an expedition" % hunter.display_name
	if not _inventory.is_stored(instance_id):
		return "Item is not in the Warehouse"
	var item := get_item(instance_id)
	if item == null or not SLOT_NAMES.has(item.equipment_slot):
		return "%s cannot be equipped" % (item.display_name if item != null else String(instance_id))
	var slot: StringName = SLOT_NAMES[item.equipment_slot]
	var previous: StringName = hunter.equipment.get(slot, &"")
	_inventory.set_equipped(instance_id, hunter.unique_id)
	if previous != &"":
		# The new item freed a slot, so the old one always fits.
		_inventory.set_stored(previous, true)
	hunter.equipment[slot] = instance_id
	_changed(hunter)
	return ""


func unequip(hunter: HunterRuntime, slot: StringName) -> String:
	if hunter.expedition_id != &"":
		return "%s is on an expedition" % hunter.display_name
	var instance_id: StringName = hunter.equipment.get(slot, &"")
	if instance_id == &"":
		return "Nothing equipped"
	if not _inventory.set_stored(instance_id):
		return "Warehouse is full"
	hunter.equipment.erase(slot)
	_changed(hunter)
	return ""


## Creates the class's starting items directly on the Hunter (new recruits).
func give_starting_gear(hunter: HunterRuntime) -> void:
	var definition := _hunters.get_definition(hunter)
	if definition == null:
		return
	for item_id in definition.starting_items:
		var item := _registry.find_def(&"item", item_id) as ItemDefinition
		if item == null or not SLOT_NAMES.has(item.equipment_slot):
			continue
		var slot: StringName = SLOT_NAMES[item.equipment_slot]
		if hunter.equipment.has(slot):
			continue
		hunter.equipment[slot] = _inventory.create_equipped(item_id, hunter.unique_id)
	# New recruits arrive at full health with their gear's HP.
	if not hunter.injured:
		hunter.current_hp = _hunters.get_stat(hunter, HunterService.MAX_HP)
	_changed(hunter)


## Equips the strongest stored item for each slot if it beats the current one.
## Returns the names of what was equipped.
func equip_best(hunter: HunterRuntime) -> PackedStringArray:
	var equipped := PackedStringArray()
	for slot_enum in SLOT_NAMES:
		var slot: StringName = SLOT_NAMES[slot_enum]
		var best := &""
		var best_power := item_power(get_equipped_item(hunter, slot))
		for instance_id in _inventory.get_instances():
			var item := get_item(instance_id)
			if item != null and item.equipment_slot == slot_enum and item_power(item) > best_power:
				best = instance_id
				best_power = item_power(item)
		if best != &"" and equip(hunter, best).is_empty():
			equipped.append(get_item(best).display_name)
	return equipped


## Rough comparison value for auto-equip: flat stats, crit counted per percent.
static func item_power(item: ItemDefinition) -> float:
	if item == null:
		return -1.0
	var power := 0.0
	for modifier in item.modifiers:
		match modifier.stat:
			HunterService.MAX_HP:
				power += modifier.value * 0.2
			HunterService.CRITICAL_CHANCE:
				power += modifier.value * 100.0
			_:
				power += modifier.value
	return power


## Drops equipment references to instances that no longer exist (after loading).
func validate(hunter: HunterRuntime, warnings: PackedStringArray) -> void:
	for slot in hunter.equipment.keys():
		var instance_id: StringName = hunter.equipment[slot]
		var worn_by: StringName = _inventory.get_equipped().get(instance_id, &"")
		if worn_by != hunter.unique_id or get_item(instance_id) == null:
			warnings.append("%s: dropped missing equipment %s" % [hunter.unique_id, instance_id])
			hunter.equipment.erase(slot)


## After loading: Hunters only reference instances equipped to them, and every equipped
## instance belongs to a Hunter that references it (others go back to the Warehouse).
func validate_all(warnings: PackedStringArray) -> void:
	for hunter in _hunters.get_all():
		validate(hunter, warnings)
	for instance_id in _inventory.get_equipped():
		var owner := _hunters.get_hunter(_inventory.get_equipped()[instance_id])
		if owner == null or not owner.equipment.values().has(instance_id):
			warnings.append("equipment: %s was not worn by anyone, moved to the Warehouse" % instance_id)
			_inventory.set_stored(instance_id, true)


func _changed(hunter: HunterRuntime) -> void:
	_hunters.notify_changed(hunter)
	equipment_changed.emit(hunter)
