class_name StatusEffect
extends RefCounted
## One active status effect on an actor (runtime state of a StatusEffectDefinition).
## Lives only in the scene: effects are not saved (combat is never saved, D48).

var definition: StatusEffectDefinition
## Who applied it (kill credit for damage over time). May be null or freed.
var source: Actor
var stacks := 1
## Seconds left; ignored when the effect is permanent.
var remaining := 0.0
## Shield points left.
var shield := 0.0
## Seconds until the next tick.
var tick_timer := 0.0


func _init(effect_definition: StatusEffectDefinition, effect_source: Actor, effect_stacks: int) -> void:
	definition = effect_definition
	source = effect_source
	stacks = clampi(effect_stacks, 1, maxi(definition.max_stacks, 1))
	restart()


## Full duration, full shield for the current stacks, tick timer from zero.
func restart() -> void:
	remaining = definition.duration
	shield = definition.shield * stacks
	tick_timer = definition.tick_interval


func get_id() -> StringName:
	return definition.id


func is_permanent() -> bool:
	return definition.duration <= 0.0


## 1 → just applied, 0 → about to expire. Permanent effects stay at 1.
func get_remaining_ratio() -> float:
	if is_permanent():
		return 1.0
	return clampf(remaining / definition.duration, 0.0, 1.0)


func get_source() -> Actor:
	return source if is_instance_valid(source) else null
