class_name EquipmentService
extends RefCounted
## Equip / unequip rules and equipment stat modifiers (INVENTORY_SYSTEM.md → Equipment).
## HunterRuntime.equipment maps slot name -> instance id; the instance's item gives modifiers.

signal equipment_changed(hunter: HunterRuntime)
## A weapon reached 0 durability and stops giving its bonuses (D64).
signal weapon_broken(hunter: HunterRuntime, item: ItemDefinition)
## A Hunter had its weapon repaired at the Blacksmith (`cost` from its purse, D64).
signal weapon_repaired(hunter: HunterRuntime, item: ItemDefinition, cost: int)

const SLOT_NAMES := {
	ItemDefinition.EquipmentSlot.WEAPON: &"weapon",
	ItemDefinition.EquipmentSlot.ARMOR: &"armor",
	ItemDefinition.EquipmentSlot.ACCESSORY: &"accessory",
	ItemDefinition.EquipmentSlot.HELMET: &"helmet",
	ItemDefinition.EquipmentSlot.PANTS: &"pants",
	ItemDefinition.EquipmentSlot.BOOTS: &"boots",
	ItemDefinition.EquipmentSlot.NECKLACE: &"necklace",
	ItemDefinition.EquipmentSlot.RING: &"ring",
	ItemDefinition.EquipmentSlot.SKIN: &"skin",
	ItemDefinition.EquipmentSlot.PET: &"pet",
}
## Display order and names of the slots (paper doll, Gear tab; D59).
const SLOT_ORDER: Array[StringName] = [&"weapon", &"helmet", &"armor", &"pants", &"boots", &"necklace", &"ring",
	&"accessory", &"skin", &"pet"]
## Slot name of a slot id (D61 key "slot.<id>").
static func slot_label(slot: StringName) -> String:
	return Loc.t("slot.%s" % slot) if slot != &"" else ""

## Stat growth per Forge level (mirrors GameConfig.enhance_stat_bonus).
const ENHANCE_BONUS := 0.12
## Weapon durability (D64): base + per tier step; each kill wears one point.
const DURABILITY_BASE := 40
const DURABILITY_PER_TIER := 20
## Gold per point of durability repaired: 1 + the tier.
const REPAIR_GOLD_PER_POINT := 1
## Hunters go to the Blacksmith when their weapon is at or below this share of its durability.
const REPAIR_THRESHOLD := 0.3

## Set by GameManager (D64): the Blacksmith repairs; purses pay a Hunter's own repairs.
var buildings: BuildingService
var purses: PurseService
var wallet: WalletService

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
		if item == null or is_broken(instance_id):
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


## What the Hunter's sprite wears (D59, D73): the class outfit, the top's / skin's cloth colour and Forge
## style, pants, boots, hat, glasses (accessory) and pet from the equipped items.
func get_dress(hunter: HunterRuntime) -> ChibiDress:
	return dress_for(hunter, _hunters.get_definition(hunter), func(slot: StringName) -> ItemDefinition:
		return get_equipped_item(hunter, slot))


## Same, for any item lookup (`item_of(slot) -> ItemDefinition`, may return null).
static func dress_for(_hunter: HunterRuntime, definition: HunterDefinition, item_of: Callable) -> ChibiDress:
	var dress := ChibiDress.new()
	dress.outfit = ChibiBody.outfit_for(definition)
	var top: ItemDefinition = item_of.call(&"armor")
	if top != null:
		if top.tint != Color.WHITE:
			dress.cloth = top.tint
			dress.has_cloth = true
		dress.top = StringName(ForgeLook.top_for(top.look_id if top.look_id != &"" else top.outfit_id))
	var skin: ItemDefinition = item_of.call(&"skin")
	if skin != null:
		if ForgeLook.has_outfit(skin.outfit_id):
			dress.outfit = skin.outfit_id
		# The skin's look wins over the top: a Forge top named by its look or outfit (D73), else the
		# outfit pattern's own top.
		dress.top = StringName(ForgeLook.top_for(skin.look_id if skin.look_id != &"" else skin.outfit_id))
		dress.cloth = skin.tint
		dress.has_cloth = true
		dress.skin = true
	var pants: ItemDefinition = item_of.call(&"pants")
	if pants != null:
		dress.pants = pants.tint
		dress.has_pants = true
		dress.pants_style = StringName(ForgeLook.style_for("pants", pants.look_id))
	var boots: ItemDefinition = item_of.call(&"boots")
	if boots != null:
		dress.boots = boots.tint
		dress.has_boots = true
		dress.boots_style = StringName(ForgeLook.style_for("shoes", boots.look_id))
	var helmet: ItemDefinition = item_of.call(&"helmet")
	if helmet != null:
		dress.hat = ChibiBody.hat_style_for(helmet)
		dress.hat_tint = helmet.tint
	var charm: ItemDefinition = item_of.call(&"accessory")
	if charm != null:
		dress.glasses = StringName(ForgeLook.glasses_for(charm))
		dress.glasses_tint = charm.tint
	var pet: ItemDefinition = item_of.call(&"pet")
	if pet != null:
		dress.pet = PetSprites.kind_for(pet)
		dress.pet_tint = pet.tint
	return dress


# --- Durability (D64) -----------------------------------------------------------------------

## Full durability of an item; 0 = it does not wear (everything but weapons).
static func max_durability(item: ItemDefinition) -> int:
	if item == null or item.equipment_slot != ItemDefinition.EquipmentSlot.WEAPON:
		return 0
	return DURABILITY_BASE + DURABILITY_PER_TIER * int(item.rarity)


func get_durability(instance_id: StringName) -> int:
	return maxi(max_durability(get_item(instance_id)) - _inventory.get_wear(instance_id), 0)


func is_broken(instance_id: StringName) -> bool:
	return max_durability(get_item(instance_id)) > 0 and get_durability(instance_id) <= 0


## One kill's worth of wear on the Hunter's weapon. Breaking it removes its bonuses.
func wear_weapon(hunter: HunterRuntime, amount: int = 1) -> void:
	var instance_id: StringName = hunter.equipment.get(&"weapon", &"")
	var item := get_item(instance_id)
	var full := max_durability(item)
	if full <= 0 or is_broken(instance_id):
		return
	_inventory.set_wear(instance_id, mini(_inventory.get_wear(instance_id) + amount, full))
	if is_broken(instance_id):
		_changed(hunter)
		weapon_broken.emit(hunter, item)


func get_repair_cost(instance_id: StringName) -> int:
	var item := get_item(instance_id)
	return _inventory.get_wear(instance_id) * (REPAIR_GOLD_PER_POINT + (int(item.rarity) if item != null else 0))


## Empty string when the treasury can repair the instance now, otherwise the reason.
func can_repair(instance_id: StringName) -> String:
	if _inventory.get_wear(instance_id) <= 0:
		return Loc.t("err.repair.not_needed")
	if buildings == null or not buildings.has_building(BuildingService.BLACKSMITH):
		return Loc.t("err.repair.needs_blacksmith")
	if wallet != null and not wallet.can_spend(get_repair_cost(instance_id)):
		return Loc.t("ui.common.needs_gold", {"gold": get_repair_cost(instance_id)})
	return ""


## Repairs paid by the treasury (the player, from an item panel or the Blacksmith).
func repair(instance_id: StringName) -> String:
	var reason := can_repair(instance_id)
	if not reason.is_empty():
		return reason
	var was_broken := is_broken(instance_id)
	wallet.spend(get_repair_cost(instance_id))
	_inventory.set_wear(instance_id, 0)
	var owner := _hunters.get_hunter(_inventory.get_owner_id(instance_id))
	if owner != null and was_broken:
		_changed(owner)
	return ""


## The Hunter's weapon is worn enough to visit the Blacksmith, which exists, and it can pay.
func wants_repair(hunter: HunterRuntime) -> bool:
	var instance_id: StringName = hunter.equipment.get(&"weapon", &"")
	var full := max_durability(get_item(instance_id))
	if full <= 0 or get_durability(instance_id) > full * REPAIR_THRESHOLD:
		return false
	if buildings == null or not buildings.has_building(BuildingService.BLACKSMITH):
		return false
	return hunter.purse >= get_repair_cost(instance_id)


## The Hunter pays the Blacksmith from its purse (gold goes to the treasury).
func repair_by_hunter(hunter: HunterRuntime) -> bool:
	if not wants_repair(hunter) or purses == null:
		return false
	var instance_id: StringName = hunter.equipment[&"weapon"]
	var cost := get_repair_cost(instance_id)
	var was_broken := is_broken(instance_id)
	if not purses.pay_village(hunter, cost):
		return false
	_inventory.set_wear(instance_id, 0)
	if was_broken:
		_changed(hunter)
	weapon_repaired.emit(hunter, get_item(instance_id), cost)
	return true


func get_item(instance_id: StringName) -> ItemDefinition:
	return _registry.find_def(&"item", _inventory.get_instance_item(instance_id)) as ItemDefinition


func get_equipped_item(hunter: HunterRuntime, slot: StringName) -> ItemDefinition:
	return get_item(hunter.equipment.get(slot, &""))


## Empty string on success, otherwise the reason. Swaps out whatever is in that slot.
func equip(hunter: HunterRuntime, instance_id: StringName) -> String:
	if hunter.expedition_id != &"":
		return Loc.t("err.equip.on_expedition", {"name": hunter.display_name})
	if not _inventory.is_stored(instance_id):
		return Loc.t("err.equip.not_in_warehouse")
	var item := get_item(instance_id)
	if item == null or not SLOT_NAMES.has(item.equipment_slot):
		return Loc.t("err.equip.not_equippable", {"item": item.display_name if item != null else String(instance_id)})
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
		return Loc.t("err.equip.on_expedition", {"name": hunter.display_name})
	var instance_id: StringName = hunter.equipment.get(slot, &"")
	if instance_id == &"":
		return Loc.t("err.equip.nothing_equipped")
	if not _inventory.set_stored(instance_id):
		return Loc.t("err.equip.warehouse_full")
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
