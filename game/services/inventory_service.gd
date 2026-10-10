class_name InventoryService
extends RefCounted
## Shared town inventory (INVENTORY_SYSTEM.md). Materials are stacks; equipment items are
## individual instances with their own id. Capacity is in slots: one slot per started stack
## of `max_stack`, one slot per *stored* equipment instance. Equipped instances belong to a
## Hunter, use no slot and cannot be sold. Gold lives in WalletService.

signal inventory_changed

## Set by the Warehouse level (BuildingService). Default = Warehouse Lv1 for standalone use.
var capacity: int = 40

var _registry: Node
var _wallet: WalletService
## Stackable item id -> count.
var _stacks: Dictionary[StringName, int] = {}
## Every owned equipment instance id -> item id (stored and equipped).
var _instances: Dictionary[StringName, StringName] = {}
## Equipped instance id -> Hunter id.
var _equipped: Dictionary[StringName, StringName] = {}
var _next_instance := 1


func _init(registry: Node, wallet: WalletService) -> void:
	_registry = registry
	_wallet = wallet


## Adds as many as fit. Returns how many were added (0 for unknown ids / bad quantity).
func add_item(item_id: StringName, quantity: int) -> int:
	var item := _get_item(item_id)
	if item == null or quantity <= 0:
		return 0
	var added := 0
	if item.stackable:
		added = mini(quantity, _stack_room(item))
		if added > 0:
			_stacks[item_id] = _stacks.get(item_id, 0) + added
	else:
		added = mini(quantity, free_slots())
		for i in added:
			_new_instance(item_id)
	if added > 0:
		inventory_changed.emit()
	return added


## Creates an equipment instance that is equipped right away (starting gear). Uses no slot.
func create_equipped(item_id: StringName, hunter_id: StringName) -> StringName:
	var item := _get_item(item_id)
	if item == null or item.stackable:
		return &""
	var instance_id := _new_instance(item_id)
	_equipped[instance_id] = hunter_id
	inventory_changed.emit()
	return instance_id


## Removes stackable items. Returns false (and changes nothing) if there are not enough.
func remove_item(item_id: StringName, quantity: int) -> bool:
	if quantity <= 0 or not _stacks.has(item_id) or _stacks[item_id] < quantity:
		return false
	_stacks[item_id] -= quantity
	if _stacks[item_id] == 0:
		_stacks.erase(item_id)
	inventory_changed.emit()
	return true


## Removes a stored (not equipped) instance.
func remove_instance(instance_id: StringName) -> bool:
	if not is_stored(instance_id):
		return false
	_instances.erase(instance_id)
	inventory_changed.emit()
	return true


## Stack count for materials, number of stored instances for equipment.
func count(item_id: StringName) -> int:
	if _stacks.has(item_id):
		return _stacks[item_id]
	return get_instances_of(item_id).size()


func has(item_id: StringName, quantity: int = 1) -> bool:
	return quantity > 0 and count(item_id) >= quantity


## Item id of any owned instance (stored or equipped), or &"".
func get_instance_item(instance_id: StringName) -> StringName:
	return _instances.get(instance_id, &"")


func is_stored(instance_id: StringName) -> bool:
	return _instances.has(instance_id) and not _equipped.has(instance_id)


func is_equipped(instance_id: StringName) -> bool:
	return _equipped.has(instance_id)


## Marks a stored instance as equipped by `hunter_id` (EquipmentService validates the rules).
func set_equipped(instance_id: StringName, hunter_id: StringName) -> bool:
	if not is_stored(instance_id):
		return false
	_equipped[instance_id] = hunter_id
	inventory_changed.emit()
	return true


## Moves an equipped instance back to storage. Needs a free slot unless `force`.
func set_stored(instance_id: StringName, force: bool = false) -> bool:
	if not _equipped.has(instance_id) or (not force and free_slots() <= 0):
		return false
	_equipped.erase(instance_id)
	inventory_changed.emit()
	return true


## Equipped instance id -> Hunter id.
func get_equipped() -> Dictionary[StringName, StringName]:
	return _equipped.duplicate()


## Stored instances of an item.
func get_instances_of(item_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	for instance_id in _instances:
		if _instances[instance_id] == item_id and not _equipped.has(instance_id):
			result.append(instance_id)
	return result


func get_stacks() -> Dictionary[StringName, int]:
	return _stacks.duplicate()


## Stored instances: instance id -> item id.
func get_instances() -> Dictionary[StringName, StringName]:
	var result: Dictionary[StringName, StringName] = {}
	for instance_id in _instances:
		if not _equipped.has(instance_id):
			result[instance_id] = _instances[instance_id]
	return result


func used_slots() -> int:
	var used := _instances.size() - _equipped.size()
	for item_id in _stacks:
		used += _slots_for(_get_item(item_id), _stacks[item_id])
	return used


func free_slots() -> int:
	return maxi(capacity - used_slots(), 0)


## Sells stackable items. Returns the gold received (0 if not enough items).
func sell_item(item_id: StringName, quantity: int) -> int:
	var item := _get_item(item_id)
	if item == null or not remove_item(item_id, quantity):
		return 0
	var gold := item.sell_price * quantity
	_wallet.add(gold)
	return gold


## Sells a stored instance (equipped ones cannot be sold).
func sell_instance(instance_id: StringName) -> int:
	var item := _get_item(get_instance_item(instance_id))
	if item == null or not remove_instance(instance_id):
		return 0
	_wallet.add(item.sell_price)
	return item.sell_price


## Plain data for SaveManager (Phase 9).
func to_dict() -> Dictionary:
	return {
		"stacks": _stacks.duplicate(),
		"instances": _instances.duplicate(),
		"equipped": _equipped.duplicate(),
		"next_instance": _next_instance,
	}


## Restores saved data. Unknown item ids are dropped and reported in `warnings`.
func from_dict(data: Dictionary, warnings: PackedStringArray) -> void:
	_stacks.clear()
	_instances.clear()
	_equipped.clear()
	var stacks: Dictionary = data.get("stacks", {})
	for item_id in stacks:
		var item := _get_item(StringName(item_id))
		if item == null or not item.stackable or int(stacks[item_id]) <= 0:
			warnings.append("inventory: dropped stack '%s'" % item_id)
			continue
		_stacks[item.id] = int(stacks[item_id])
	var instances: Dictionary = data.get("instances", {})
	for instance_id in instances:
		var item := _get_item(StringName(instances[instance_id]))
		if item == null or item.stackable:
			warnings.append("inventory: dropped instance '%s' (%s)" % [instance_id, instances[instance_id]])
			continue
		_instances[StringName(instance_id)] = item.id
	var equipped: Dictionary = data.get("equipped", {})
	for instance_id in equipped:
		if _instances.has(StringName(instance_id)):
			_equipped[StringName(instance_id)] = StringName(equipped[instance_id])
	_next_instance = maxi(int(data.get("next_instance", 1)), _instances.size() + 1)
	inventory_changed.emit()


func _new_instance(item_id: StringName) -> StringName:
	var instance_id := StringName("e_%d" % _next_instance)
	while _instances.has(instance_id):
		_next_instance += 1
		instance_id = StringName("e_%d" % _next_instance)
	_next_instance += 1
	_instances[instance_id] = item_id
	return instance_id


## How many more of a stackable item fit, filling the last stack first.
func _stack_room(item: ItemDefinition) -> int:
	var current: int = _stacks.get(item.id, 0)
	var max_stack := maxi(item.max_stack, 1)
	var room_in_last := (max_stack - current % max_stack) % max_stack
	return room_in_last + free_slots() * max_stack


func _slots_for(item: ItemDefinition, quantity: int) -> int:
	if item == null or quantity <= 0:
		return 0
	return ceili(float(quantity) / maxi(item.max_stack, 1))


func _get_item(item_id: StringName) -> ItemDefinition:
	return _registry.find_def(&"item", item_id) as ItemDefinition
