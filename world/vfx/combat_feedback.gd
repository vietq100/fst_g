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
	GameManager.combat.effect_damage_dealt.connect(_on_effect_damage_dealt)


## Attackers with a longer reach than this shoot (arrow streak).
const RANGED_REACH := 60.0
const IMMUNE_COLOR := Color("ffe9a8")
const EFFECT_FONT_SIZE := 10


func _on_damage_dealt(attacker: Actor, target: Actor, amount: float, is_critical: bool) -> void:
	if not is_instance_valid(target):
		return
	if is_instance_valid(attacker) and attacker.combat.attack_range > RANGED_REACH:
		var streak := ArrowStreak.new()
		add_child(streak)
		streak.setup(attacker.global_position + Vector2(0, -14), target.global_position + Vector2(0, -12))
	var number := _spawn_number(target)
	if amount <= 0.0 and target.effects.is_invulnerable():
		number.show_text("Immune", IMMUNE_COLOR)
	else:
		number.setup(amount, is_critical, target is Hunter)


## Damage over time and thorns: small number in the effect's colour (D48).
func _on_effect_damage_dealt(_source: Actor, target: Actor, amount: float, effect: StatusEffectDefinition) -> void:
	if not is_instance_valid(target):
		return
	var color := effect.color if effect != null else DamageNumber.COLOR
	if amount <= 0.0:
		if target.effects.is_invulnerable():
			_spawn_number(target).show_text("Immune", IMMUNE_COLOR, EFFECT_FONT_SIZE)
		return
	_spawn_number(target).show_text(str(roundi(amount)), color, EFFECT_FONT_SIZE)


func _spawn_number(target: Actor) -> DamageNumber:
	var number := DamageNumber.new()
	add_child(number)
	number.global_position = target.global_position + NUMBER_OFFSET + Vector2(randf_range(-NUMBER_JITTER, NUMBER_JITTER), 0)
	return number
