class_name CombatService
extends RefCounted
## Resolves attacks: damage, critical, death (COMBAT_SYSTEM.md → Combat ownership).
## Actors decide *when* to attack; this service decides *what happens*. UI/VFX subscribe to signals.

signal damage_dealt(attacker: Actor, target: Actor, amount: float, is_critical: bool)
## Target reached 0 HP: enemies die, Hunters are downed (DECISIONS.md D4).
signal actor_defeated(actor: Actor, by: Actor)

var _stats: StatService
var _rng: RandomNumberGenerator


func _init(stats: StatService, rng: RandomNumberGenerator) -> void:
	_stats = stats
	_rng = rng


## Returns the damage applied (0 if the target is not a valid target).
func resolve_attack(attacker: Actor, target: Actor) -> float:
	if not is_instance_valid(attacker) or not is_instance_valid(target) or not target.is_targetable():
		return 0.0
	var attack := attacker.get_combat_stats(target)
	var defense := target.get_combat_stats(attacker)
	var damage := _stats.calculate_damage(attack.attack, defense.defense)
	var is_critical := _stats.roll_critical(attack.critical_chance, _rng)
	if is_critical:
		damage = _stats.apply_critical(damage, attack.critical_damage)
	damage = maxf(damage * attack.damage_dealt * defense.damage_taken, 1.0)
	var applied := target.health.take_damage(damage)
	damage_dealt.emit(attacker, target, applied, is_critical)
	if target.health.is_dead():
		actor_defeated.emit(target, attacker)
	return applied


func attack_cooldown(actor: Actor) -> float:
	return _stats.attack_cooldown(actor.get_combat_stats().attack_speed)
