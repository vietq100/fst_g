class_name PurseService
extends RefCounted
## Treasury (WalletService) and Hunter purses (AUTONOMY_SYSTEM.md → Money, DECISIONS.md D34).
## Hunting gold and material sales go to the purse, food and medicine are paid from it into the
## treasury (SupplyService), and the player can move gold either way for a fee (the receiver gets
## the rest).

signal purse_changed(hunter: HunterRuntime)

var _wallet: WalletService
var _config: GameConfig


func _init(wallet: WalletService, config: GameConfig) -> void:
	_wallet = wallet
	_config = config


## What the receiver gets from a transfer of `amount` (fee rounded in the town's favour).
func get_received(amount: int) -> int:
	return floori(maxi(amount, 0) * (1.0 - _config.transfer_fee))


func get_fee(amount: int) -> int:
	return maxi(amount, 0) - get_received(amount)


## Empty string when `amount` treasury gold can go to the Hunter.
func can_give(hunter: HunterRuntime, amount: int) -> String:
	if hunter == null:
		return "Unknown Hunter"
	if amount <= 0:
		return "Nothing to give"
	if not _wallet.can_spend(amount):
		return "Needs %d gold in the treasury" % amount
	return ""


## Treasury → purse. Returns the error ("" = done).
func give(hunter: HunterRuntime, amount: int) -> String:
	var reason := can_give(hunter, amount)
	if not reason.is_empty():
		return reason
	_wallet.spend(amount)
	hunter.purse += get_received(amount)
	purse_changed.emit(hunter)
	return ""


func can_take(hunter: HunterRuntime, amount: int) -> String:
	if hunter == null:
		return "Unknown Hunter"
	if amount <= 0:
		return "Nothing to take"
	if hunter.purse < amount:
		return "%s only has %d gold" % [hunter.display_name, hunter.purse]
	return ""


## Purse → treasury. Returns the error ("" = done).
func take(hunter: HunterRuntime, amount: int) -> String:
	var reason := can_take(hunter, amount)
	if not reason.is_empty():
		return reason
	hunter.purse -= amount
	_wallet.add(get_received(amount))
	purse_changed.emit(hunter)
	return ""


## Hunting income (no fee).
func earn(hunter: HunterRuntime, amount: int) -> void:
	if amount <= 0:
		return
	hunter.purse += amount
	purse_changed.emit(hunter)


## A purchase from the village (food, medicine): purse → treasury, no fee. False if too poor.
func pay_village(hunter: HunterRuntime, amount: int) -> bool:
	if amount < 0 or hunter.purse < amount:
		return false
	hunter.purse -= amount
	_wallet.add(amount)
	purse_changed.emit(hunter)
	return true
