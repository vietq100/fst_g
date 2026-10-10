class_name WalletService
extends RefCounted
## Gold, the only numeric currency (DECISIONS.md D6). Materials are inventory items (Phase 5).

signal gold_changed(gold: int, delta: int)

var gold: int = 0


func add(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	gold_changed.emit(gold, amount)


func can_spend(amount: int) -> bool:
	return amount >= 0 and gold >= amount


## Returns false (and changes nothing) if there is not enough gold.
func spend(amount: int) -> bool:
	if not can_spend(amount):
		return false
	gold -= amount
	gold_changed.emit(gold, -amount)
	return true
