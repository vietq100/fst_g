class_name WalletService
extends RefCounted
## Gold, the only numeric currency (DECISIONS.md D6). Materials are inventory items (Phase 5).

signal gold_changed(gold: int, delta: int)
signal tickets_changed(tickets: int, delta: int)
signal tokens_changed(tokens: int, delta: int)

var gold: int = 0
## Summoning tickets (D83): spent at the Hunter Gate to call a Hunter.
var summon_tickets: int = 0
## Arena tokens: won in Colosseum matches, spent in the Token Shop.
var arena_tokens: int = 0


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


func add_tickets(amount: int) -> void:
	if amount <= 0:
		return
	summon_tickets += amount
	tickets_changed.emit(summon_tickets, amount)


func can_spend_tickets(amount: int) -> bool:
	return amount >= 0 and summon_tickets >= amount


## Returns false (and changes nothing) if there are not enough tickets.
func spend_tickets(amount: int) -> bool:
	if not can_spend_tickets(amount):
		return false
	summon_tickets -= amount
	tickets_changed.emit(summon_tickets, -amount)
	return true


func add_tokens(amount: int) -> void:
	if amount <= 0:
		return
	arena_tokens += amount
	tokens_changed.emit(arena_tokens, amount)


func can_spend_tokens(amount: int) -> bool:
	return amount >= 0 and arena_tokens >= amount


## Returns false (and changes nothing) if there are not enough tokens.
func spend_tokens(amount: int) -> bool:
	if not can_spend_tokens(amount):
		return false
	arena_tokens -= amount
	tokens_changed.emit(arena_tokens, -amount)
	return true

