class_name TradingService
extends RefCounted
## Trading Post (Evil Hunter Tycoon style): the chief posts material requests; Hunters bring the
## material home as they hunt and are paid a bounty from the treasury on top of the normal price.
## A request is done when its quantity has been delivered.

signal requests_changed
signal request_completed(item_id: StringName, quantity: int)
signal autosave_requested(reason: StringName)

## Dictionaries: {"item_id": StringName, "quantity": int, "delivered": int}.
var requests: Array[Dictionary] = []

var _registry: Node
var _buildings: BuildingService
var _wallet: WalletService
var _purses: PurseService
var _config: GameConfig


func _init(registry: Node, buildings: BuildingService, wallet: WalletService, purses: PurseService, config: GameConfig) -> void:
	_registry = registry
	_buildings = buildings
	_wallet = wallet
	_purses = purses
	_config = config


func get_wanted_item_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for request in requests:
		ids.append(request["item_id"])
	return ids


func get_slots() -> int:
	return int(_buildings.get_effect(BuildingService.TRADING_POST, BuildingService.REQUEST_SLOTS, 0.0))


## Materials that can be requested, cheapest first.
func get_orderable_items() -> Array[ItemDefinition]:
	var result: Array[ItemDefinition] = []
	for definition in _registry.get_all(&"item"):
		var item := definition as ItemDefinition
		if item.item_type == ItemDefinition.ItemType.MATERIAL and item.sell_price > 0:
			result.append(item)
	result.sort_custom(func(a: ItemDefinition, b: ItemDefinition) -> bool: return a.sell_price < b.sell_price)
	return result


func get_bounty(item_id: StringName) -> int:
	var item := _registry.find_def(&"item", item_id) as ItemDefinition
	return roundi(item.sell_price * _config.bounty_ratio) if item != null else 0


func can_order(item_id: StringName, quantity: int) -> String:
	if not _buildings.has_building(BuildingService.TRADING_POST):
		return Loc.t("err.trading.no_post")
	var item := _registry.find_def(&"item", item_id) as ItemDefinition
	if item == null or item.item_type != ItemDefinition.ItemType.MATERIAL:
		return Loc.t("err.trading.not_requestable")
	if quantity <= 0:
		return Loc.t("err.trading.nothing")
	if requests.size() >= get_slots():
		return Loc.t("err.trading.slots_full", {"slots": get_slots()})
	for request in requests:
		if request["item_id"] == item_id:
			return Loc.t("err.trading.already_requested")
	return ""


func order(item_id: StringName, quantity: int) -> bool:
	if not can_order(item_id, quantity).is_empty():
		return false
	requests.append({"item_id": item_id, "quantity": quantity, "delivered": 0})
	requests_changed.emit()
	autosave_requested.emit(&"trading")
	return true


func cancel(index: int) -> void:
	if index < 0 or index >= requests.size():
		return
	requests.remove_at(index)
	requests_changed.emit()
	autosave_requested.emit(&"trading")


## Called when a Hunter's bag was sold: `report["items"]` = {id: quantity stored}. Pays the bounty
## for requested items (as far as the treasury can) and completes requests.
func on_bag_deposited(hunter: HunterRuntime, report: Dictionary) -> void:
	var changed := false
	for index in range(requests.size() - 1, -1, -1):
		var request: Dictionary = requests[index]
		var stored: int = report.get("items", {}).get(request["item_id"], 0)
		var useful := mini(stored, request["quantity"] - request["delivered"])
		if useful <= 0:
			continue
		var bounty := mini(useful * get_bounty(request["item_id"]), _wallet.gold)
		if bounty > 0:
			_wallet.spend(bounty)
			_purses.earn(hunter, bounty)
		request["delivered"] += useful
		changed = true
		if request["delivered"] >= request["quantity"]:
			requests.remove_at(index)
			request_completed.emit(request["item_id"], request["quantity"])
	if changed:
		requests_changed.emit()
		autosave_requested.emit(&"trading")


func to_dict() -> Array:
	var list: Array = []
	for request in requests:
		list.append({"item_id": request["item_id"], "quantity": request["quantity"], "delivered": request["delivered"]})
	return list


func from_dict(data: Variant) -> void:
	requests.clear()
	if data is Array:
		for entry in data:
			if not entry is Dictionary:
				continue
			var item_id := StringName(str(entry.get("item_id", "")))
			if _registry.find_def(&"item", item_id) == null:
				continue
			requests.append({"item_id": item_id, "quantity": maxi(int(entry.get("quantity", 1)), 1),
				"delivered": maxi(int(entry.get("delivered", 0)), 0)})
	requests_changed.emit()
