class_name CombatService
extends RefCounted
## Resolves attacks: damage, critical, death (COMBAT_SYSTEM.md → Combat ownership).
## Actors decide *when* to attack; this service decides *what happens*. UI/VFX subscribe to signals.
## Status effects (D48) hook in here: invulnerability, shields, thorns, lifesteal, on-hit effects
## and damage over time.

signal damage_dealt(attacker: Actor, target: Actor, amount: float, is_critical: bool)
## Damage from a status effect: damage over time, or thorns reflecting a hit (`effect` = the
## thorns effect). `source` may be null.
signal effect_damage_dealt(source: Actor, target: Actor, amount: float, effect: StatusEffectDefinition)
## Target reached 0 HP: enemies die, Hunters are downed (DECISIONS.md D4). `by` may be null.
signal actor_defeated(actor: Actor, by: Actor)

var _stats: StatService
var _rng: RandomNumberGenerator


func _init(stats: StatService, rng: RandomNumberGenerator) -> void:
	_stats = stats
	_rng = rng


## Returns the damage applied to HP (0 if the target is not a valid target or immune).
func resolve_attack(attacker: Actor, target: Actor) -> float:
	if not is_instance_valid(attacker) or not is_instance_valid(target) or not target.is_targetable():
		return 0.0
	var attack := attacker.get_final_combat_stats(target)
	var defense := target.get_final_combat_stats(attacker)
	var damage := _stats.calculate_damage(attack.attack, defense.defense)
	var is_critical := _stats.roll_critical(attack.critical_chance, _rng)
	if is_critical:
		damage = _stats.apply_critical(damage, attack.critical_damage)
	damage = maxf(damage * attack.damage_dealt * defense.damage_taken, 1.0)
	var applied := _deal_damage(target, damage)
	damage_dealt.emit(attacker, target, applied, is_critical)
	if target.health.is_dead():
		actor_defeated.emit(target, attacker)
	elif applied > 0.0:
		_apply_on_hit_effects(attacker, target)
	if applied > 0.0:
		_apply_lifesteal(attacker, applied)
		_apply_thorns(target, attacker, applied)
	return applied


## Damage over time from `effect`. Returns the damage applied to HP.
func resolve_effect_damage(source: Actor, target: Actor, amount: float, effect: StatusEffectDefinition) -> float:
	if not is_instance_valid(target) or not target.is_targetable():
		return 0.0
	var applied := _deal_damage(target, amount)
	effect_damage_dealt.emit(source, target, applied, effect)
	if target.health.is_dead():
		actor_defeated.emit(target, source if is_instance_valid(source) else null)
	return applied


func attack_cooldown(actor: Actor) -> float:
	return _stats.attack_cooldown(actor.get_final_combat_stats().attack_speed)


## Invulnerability, then shields, then HP.
func _deal_damage(target: Actor, damage: float) -> float:
	if target.effects.is_invulnerable():
		return 0.0
	return target.health.take_damage(target.effects.absorb_damage(damage))


func _apply_on_hit_effects(attacker: Actor, target: Actor) -> void:
	for entry in attacker.get_on_hit_effects():
		if entry != null and entry.effect != null and _rng.randf() < entry.chance:
			target.effects.apply(entry.effect, attacker, entry.stacks)


func _apply_lifesteal(attacker: Actor, damage: float) -> void:
	var lifesteal: float = attacker.effects.get_lifesteal()
	if lifesteal > 0.0 and attacker.is_targetable():
		attacker.health.heal(damage * lifesteal)


## The reflected part is not reflected again (no thorns ping-pong) and does not trigger lifesteal.
func _apply_thorns(target: Actor, attacker: Actor, damage: float) -> void:
	var thorns: StatusEffect = target.effects.get_thorns_effect()
	if thorns == null or not attacker.is_targetable():
		return
	var applied: float = _deal_damage(attacker, damage * target.effects.get_thorns())
	effect_damage_dealt.emit(target, attacker, applied, thorns.definition)
	if attacker.health.is_dead():
		actor_defeated.emit(attacker, target)
