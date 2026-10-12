class_name QuestService
extends RefCounted
## Guided quests (Evil Hunter Tycoon style). Conditions are read from the other services; the
## player claims the reward when a quest is complete. Quests are ordered: the next one appears
## once the previous one is claimed. Quests never own gameplay rules.

signal quests_changed
signal quest_completed(quest: QuestDefinition)
signal quest_claimed(quest: QuestDefinition)
signal autosave_requested(reason: StringName)

## Quests shown at once (claimable first).
const VISIBLE := 3

var _registry: Node
var _buildings: BuildingService
var _hunters: HunterService
var _progress: ProgressService
var _wallet: WalletService
var _inventory: InventoryService
var _claimed: Dictionary[StringName, bool] = {}
## Quests already announced as complete (so the toast fires once).
var _announced: Dictionary[StringName, bool] = {}
## Counters of events that leave no other trace.
var _enhanced := 0


func _init(registry: Node, buildings: BuildingService, hunters: HunterService, progress: ProgressService,
		wallet: WalletService, inventory: InventoryService) -> void:
	_registry = registry
	_buildings = buildings
	_hunters = hunters
	_progress = progress
	_wallet = wallet
	_inventory = inventory


func note_enhanced() -> void:
	_enhanced += 1
	refresh()


## Re-checks conditions and announces newly completed quests. Call after relevant changes.
func refresh() -> void:
	for quest in get_active():
		if is_complete(quest) and not _announced.has(quest.id):
			_announced[quest.id] = true
			quest_completed.emit(quest)
	quests_changed.emit()


func get_all() -> Array[QuestDefinition]:
	var result: Array[QuestDefinition] = []
	for definition in _registry.get_all(&"quest"):
		result.append(definition as QuestDefinition)
	result.sort_custom(func(a: QuestDefinition, b: QuestDefinition) -> bool: return a.order < b.order)
	return result


## Unclaimed quests that are visible now: complete ones first, then the next in order.
func get_active() -> Array[QuestDefinition]:
	var open: Array[QuestDefinition] = []
	for quest in get_all():
		if not _claimed.has(quest.id):
			open.append(quest)
	var visible := open.slice(0, VISIBLE)
	visible.sort_custom(func(a: QuestDefinition, b: QuestDefinition) -> bool:
		return int(is_complete(a)) > int(is_complete(b)) or (is_complete(a) == is_complete(b) and a.order < b.order))
	return visible


func is_claimed(quest_id: StringName) -> bool:
	return _claimed.has(quest_id)


func get_claimed_count() -> int:
	return _claimed.size()


## How many quests wait for their reward.
func get_claimable_count() -> int:
	var count := 0
	for quest in get_active():
		if is_complete(quest):
			count += 1
	return count


## (current, needed) for the progress bar.
func get_progress(quest: QuestDefinition) -> Vector2i:
	var current := 0
	match quest.kind:
		QuestDefinition.Kind.BUILDING:
			current = _buildings.get_instances_of(quest.target_id).size()
		QuestDefinition.Kind.TOWN_LEVEL:
			current = _buildings.get_town_level()
		QuestDefinition.Kind.HUNTERS:
			current = _hunters.count()
		QuestDefinition.Kind.FLAG:
			current = 1 if _progress.has_flag(quest.target_id) else 0
		QuestDefinition.Kind.REINCARNATIONS:
			current = _progress.total_reincarnations
		QuestDefinition.Kind.DIFFICULTY:
			current = _progress.difficulty
		QuestDefinition.Kind.HUNTER_LEVEL:
			for hunter in _hunters.get_all():
				current = maxi(current, hunter.level)
		QuestDefinition.Kind.SKILLS_LEARNED:
			for hunter in _hunters.get_all():
				for level in hunter.skills.values():
					current += level
		QuestDefinition.Kind.ENHANCED:
			current = _enhanced
	return Vector2i(mini(current, quest.amount), quest.amount)


func is_complete(quest: QuestDefinition) -> bool:
	var progress := get_progress(quest)
	return progress.x >= progress.y


func can_claim(quest: QuestDefinition) -> String:
	if _claimed.has(quest.id):
		return "Already claimed"
	if not is_complete(quest):
		return "Not finished yet"
	return ""


## Pays the reward. Items that do not fit the Warehouse are skipped (gold is always paid).
func claim(quest: QuestDefinition) -> bool:
	if not can_claim(quest).is_empty():
		return false
	_claimed[quest.id] = true
	_wallet.add(quest.reward_gold)
	for entry in quest.reward_items:
		_inventory.add_item(entry.item_id, entry.quantity)
	quest_claimed.emit(quest)
	refresh()
	autosave_requested.emit(&"quest")
	return true


func describe_reward(quest: QuestDefinition) -> String:
	var parts := PackedStringArray()
	if quest.reward_gold > 0:
		parts.append("%d gold" % quest.reward_gold)
	for entry in quest.reward_items:
		var item := _registry.find_def(&"item", entry.item_id) as ItemDefinition
		parts.append("%d %s" % [entry.quantity, item.display_name if item != null else String(entry.item_id)])
	return ", ".join(parts)


func to_dict() -> Dictionary:
	return {"claimed": _claimed.keys(), "enhanced": _enhanced}


func from_dict(data: Variant) -> void:
	_claimed.clear()
	_announced.clear()
	_enhanced = 0
	if data is Dictionary:
		var claimed: Variant = data.get("claimed", [])
		for quest_id in (claimed if claimed is Array else []):
			if _registry.find_def(&"quest", StringName(str(quest_id))) != null:
				_claimed[StringName(str(quest_id))] = true
		_enhanced = maxi(int(data.get("enhanced", 0)), 0)
	for quest in get_active():
		if is_complete(quest):
			_announced[quest.id] = true
	quests_changed.emit()
