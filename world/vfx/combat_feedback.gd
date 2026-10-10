class_name CombatFeedback
extends Node2D
## Spawns combat VFX in the world from CombatService signals. Presentation only.
## Add one to any scene where combat happens (test arena, expedition).

## Number appears above the target's head.
const NUMBER_OFFSET := Vector2(0, -36)
const NUMBER_JITTER := 6.0


func _ready() -> void:
	z_index = 100
	GameManager.combat.damage_dealt.connect(_on_damage_dealt)


func _on_damage_dealt(_attacker: Actor, target: Actor, amount: float, is_critical: bool) -> void:
	if not is_instance_valid(target):
		return
	var number := DamageNumber.new()
	add_child(number)
	number.global_position = target.global_position + NUMBER_OFFSET + Vector2(randf_range(-NUMBER_JITTER, NUMBER_JITTER), 0)
	number.setup(amount, is_critical, target is Hunter)
