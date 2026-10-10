class_name HealthController
extends Node
## HP for any actor. Emits signals; never touches UI (ARCHITECTURE.md → Actor composition).

signal health_changed(current: float, maximum: float)
signal damaged(amount: float)
signal healed(amount: float)
## Emitted once when HP reaches 0. Hunters treat this as "downed" (DECISIONS.md D4).
signal died

var max_health: float = 1.0
var current_health: float = 1.0


## `current` < 0 means full health.
func setup(maximum: float, current: float = -1.0) -> void:
	max_health = maxf(maximum, 1.0)
	current_health = max_health if current < 0.0 else clampf(current, 0.0, max_health)
	health_changed.emit(current_health, max_health)


## Changes max HP, clamping current HP.
func set_max_health(maximum: float) -> void:
	max_health = maxf(maximum, 1.0)
	current_health = minf(current_health, max_health)
	health_changed.emit(current_health, max_health)


## Returns the damage actually applied.
func take_damage(amount: float) -> float:
	if is_dead() or amount <= 0.0:
		return 0.0
	var applied := minf(amount, current_health)
	current_health -= applied
	damaged.emit(applied)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		died.emit()
	return applied


## Returns the HP actually restored. Dead actors cannot be healed (use revive).
func heal(amount: float) -> float:
	if is_dead() or amount <= 0.0:
		return 0.0
	var applied := minf(amount, max_health - current_health)
	if applied <= 0.0:
		return 0.0
	current_health += applied
	healed.emit(applied)
	health_changed.emit(current_health, max_health)
	return applied


func revive(amount: float) -> void:
	current_health = clampf(amount, 1.0, max_health)
	health_changed.emit(current_health, max_health)


func is_dead() -> bool:
	return current_health <= 0.0


func get_ratio() -> float:
	return current_health / max_health
