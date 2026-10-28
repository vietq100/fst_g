class_name BountyService
extends RefCounted
## Daily Bounty Board & Urgent Contracts service.
## Generates and tracks tactical short-term objectives (kill, expedition, gather)
## with gold, summon ticket, and rune rewards.

signal bounties_updated
signal bounty_claimed(bounty_id: StringName)
signal autosave_requested(reason: StringName)

const TYPE_KILL := &"kill"
const TYPE_EXPEDITION := &"expedition"
const TYPE_GATHER := &"gather"

const MAX_BOUNTIES := 3
const REFRESH_INTERVAL := 86400.0 # 1 game day in seconds (or custom timer)

var _registry: Node
var _wallet: WalletService
var _inventory: InventoryService
var _progress: ProgressService
var _rng: RandomNumberGenerator

var _bounties: Array[Dictionary] = []
var _time_until_refresh: float = REFRESH_INTERVAL


func _init(registry: Node, wallet: WalletService, inventory: InventoryService, progress: ProgressService, rng: RandomNumberGenerator) -> void:
	_registry = registry
	_wallet = wallet
	_inventory = inventory
	_progress = progress
	_rng = rng
	if _bounties.is_empty():
		refresh_bounties()


func get_bounties() -> Array[Dictionary]:
	return _bounties


func get_time_until_refresh() -> float:
	return _time_until_refresh


func tick(delta: float) -> void:
	_time_until_refresh -= delta
	if _time_until_refresh <= 0.0:
		_time_until_refresh = REFRESH_INTERVAL
		refresh_bounties()


func refresh_bounties(force: bool = false) -> void:
	if not force and not _bounties.is_empty():
		# Only refresh if all claimed or forced
		var all_claimed := true
		for b in _bounties:
			if not b.get("claimed", false):
				all_claimed = false
				break
		if not all_claimed:
			return

	_bounties.clear()
	var town_lv: int = _progress.town_level if _progress != null else 1
	var pool: Array[Dictionary] = _get_candidate_templates(town_lv)
	pool.shuffle()

	var count := mini(MAX_BOUNTIES, pool.size())
	for i in range(count):
		var template: Dictionary = pool[i]
		var bounty: Dictionary = {
			"id": StringName("bounty_%d_%d" % [int(Time.get_unix_time_from_system()), i]),
			"type": template.type,
			"target_id": template.target_id,
			"target_name_key": template.target_name_key,
			"required": template.required,
			"progress": 0,
			"reward_gold": template.reward_gold,
			"reward_tickets": template.get("reward_tickets", 0),
			"reward_item": template.get("reward_item", &""),
			"reward_item_count": template.get("reward_item_count", 0),
			"claimed": false,
		}
		_bounties.append(bounty)

	bounties_updated.emit()
	autosave_requested.emit(&"bounties_refreshed")


func record_kill(enemy_id: StringName, is_boss: bool = false) -> void:
	var changed := false
	for b in _bounties:
		if b.get("claimed", false):
			continue
		if b.get("type", &"") == TYPE_KILL:
			var target: StringName = b.get("target_id", &"")
			if target == enemy_id or (target == &"boss" and is_boss) or target == &"any":
				var cur: int = b.get("progress", 0)
				var req: int = b.get("required", 1)
				if cur < req:
					b["progress"] = mini(cur + 1, req)
					changed = true
	if changed:
		bounties_updated.emit()


func record_expedition(expedition_id: StringName) -> void:
	var changed := false
	for b in _bounties:
		if b.get("claimed", false):
			continue
		if b.get("type", &"") == TYPE_EXPEDITION:
			var target: StringName = b.get("target_id", &"")
			if target == &"any" or target == expedition_id:
				var cur: int = b.get("progress", 0)
				var req: int = b.get("required", 1)
				if cur < req:
					b["progress"] = mini(cur + 1, req)
					changed = true
	if changed:
		bounties_updated.emit()


func record_gather(item_id: StringName, count: int) -> void:
	var changed := false
	for b in _bounties:
		if b.get("claimed", false):
			continue
		if b.get("type", &"") == TYPE_GATHER:
			var target: StringName = b.get("target_id", &"")
			if target == &"any" or target == item_id:
				var cur: int = b.get("progress", 0)
				var req: int = b.get("required", 1)
				if cur < req:
					b["progress"] = mini(cur + count, req)
					changed = true
	if changed:
		bounties_updated.emit()


func can_claim(bounty_id: StringName) -> bool:
	for b in _bounties:
		if b.get("id", &"") == bounty_id:
			return not b.get("claimed", false) and b.get("progress", 0) >= b.get("required", 1)
	return false


func claim_bounty(bounty_id: StringName) -> bool:
	for b in _bounties:
		if b.get("id", &"") == bounty_id:
			if b.get("claimed", false) or b.get("progress", 0) < b.get("required", 1):
				return false
			b["claimed"] = true
			var gold: int = b.get("reward_gold", 0)
			if gold > 0:
				_wallet.earn(gold)
			var tickets: int = b.get("reward_tickets", 0)
			if tickets > 0:
				_wallet.summon_tickets += tickets
			var item: StringName = b.get("reward_item", &"")
			var item_cnt: int = b.get("reward_item_count", 0)
			if item != &"" and item_cnt > 0:
				_inventory.add_item(item, item_cnt)
			bounty_claimed.emit(bounty_id)
			bounties_updated.emit()
			autosave_requested.emit(&"bounty_claimed")
			return true
	return false


func _get_candidate_templates(town_lv: int) -> Array[Dictionary]:
	var list: Array[Dictionary] = [
		{
			"type": TYPE_KILL,
			"target_id": &"goblin",
			"target_name_key": "bounty.target.goblin",
			"required": 8,
			"reward_gold": 120 + town_lv * 20,
			"reward_tickets": 1,
			"reward_item": &"rune_ruby",
			"reward_item_count": 1,
		},
		{
			"type": TYPE_KILL,
			"target_id": &"slime",
			"target_name_key": "bounty.target.slime",
			"required": 10,
			"reward_gold": 90 + town_lv * 15,
			"reward_tickets": 0,
			"reward_item": &"beast_feast",
			"reward_item_count": 1,
		},
		{
			"type": TYPE_KILL,
			"target_id": &"skeleton",
			"target_name_key": "bounty.target.skeleton",
			"required": 6,
			"reward_gold": 150 + town_lv * 25,
			"reward_tickets": 1,
			"reward_item": &"rune_sapphire",
			"reward_item_count": 1,
		},
		{
			"type": TYPE_KILL,
			"target_id": &"boss",
			"target_name_key": "bounty.target.boss",
			"required": 1,
			"reward_gold": 250 + town_lv * 40,
			"reward_tickets": 2,
			"reward_item": &"rune_emerald",
			"reward_item_count": 1,
		},
		{
			"type": TYPE_EXPEDITION,
			"target_id": &"any",
			"target_name_key": "bounty.target.expedition",
			"required": 2,
			"reward_gold": 140 + town_lv * 20,
			"reward_tickets": 1,
			"reward_item": &"potion_clarity",
			"reward_item_count": 1,
		},
		{
			"type": TYPE_GATHER,
			"target_id": &"any",
			"target_name_key": "bounty.target.gather",
			"required": 15,
			"reward_gold": 100 + town_lv * 15,
			"reward_tickets": 1,
			"reward_item": &"mist_elixir",
			"reward_item_count": 1,
		},
	]
	return list


func to_dict() -> Dictionary:
	var list: Array = []
	for b in _bounties:
		list.append(b.duplicate())
	return {
		"time_until_refresh": _time_until_refresh,
		"bounties": list,
	}


func from_dict(data: Dictionary) -> void:
	_time_until_refresh = float(data.get("time_until_refresh", REFRESH_INTERVAL))
	_bounties.clear()
	var list: Variant = data.get("bounties", [])
	if list is Array:
		for item in list:
			if item is Dictionary:
				_bounties.append(item.duplicate())
	if _bounties.is_empty():
		refresh_bounties()
