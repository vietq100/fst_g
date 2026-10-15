class_name CombatService
extends RefCounted
## Resolves attacks: damage, critical, death (COMBAT_SYSTEM.md → Combat ownership).
## Actors decide *when* to attack; this service decides *what happens*. UI/VFX subscribe to signals.
## Status effects (D48) hook in here: invulnerability, shields, thorns, lifesteal, on-hit effects
## and damage over time.

## A monster cast one of its skills (effects, popups).
signal monster_skill_cast(monster: Actor, skill: MonsterSkillDefinition)
signal damage_dealt(attacker: Actor, target: Actor, amount: float, is_critical: bool)
## Damage from a status effect: damage over time, or thorns reflecting a hit (`effect` = the
## thorns effect). `source` may be null.
signal effect_damage_dealt(source: Actor, target: Actor, amount: float, effect: StatusEffectDefinition)
## Target reached 0 HP: enemies die, Hunters are downed (DECISIONS.md D4). `by` may be null.
signal actor_defeated(actor: Actor, by: Actor)
## The target dodged a hit (D70 dodge stat).
signal attack_dodged(attacker: Actor, target: Actor)
## A class skill was cast (D70). Presentation listens (skill name popup).
signal skill_cast(caster: Actor, skill: ClassSkillDefinition)
## HP restored by a class skill (D70).
signal actor_healed(source: Actor, target: Actor, amount: float)

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
	if _dodges(defense):
		attack_dodged.emit(attacker, target)
		return 0.0
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


## One hit of a class skill (D70). `raw_attack` replaces the attacker's attack value (e.g. 160% of
## it); the target's defense is subtracted once per hit, like a normal attack. Then critical
## (with the skill's bonuses), damage multipliers and `multiplier` (execute, tag bonus).
## No on-hit effects (the skill applies its own). Returns the damage applied to HP.
func resolve_skill_hit(attacker: Actor, target: Actor, raw_attack: float, bonus_crit: float = 0.0,
		bonus_crit_damage: float = 0.0, multiplier: float = 1.0, ignore_dodge: bool = false) -> float:
	if not is_instance_valid(attacker) or not is_instance_valid(target) or not target.is_targetable():
		return 0.0
	var attack := attacker.get_final_combat_stats(target)
	var defense := target.get_final_combat_stats(attacker)
	if not ignore_dodge and _dodges(defense):
		attack_dodged.emit(attacker, target)
		return 0.0
	var damage := _stats.calculate_damage(raw_attack, defense.defense)
	var is_critical := _stats.roll_critical(minf(attack.critical_chance + bonus_crit, 1.0), _rng)
	if is_critical:
		damage = _stats.apply_critical(damage, attack.critical_damage + bonus_crit_damage)
	damage = maxf(damage * multiplier * attack.damage_dealt * defense.damage_taken, 1.0)
	var applied := _deal_damage(target, damage)
	damage_dealt.emit(attacker, target, applied, is_critical)
	if target.health.is_dead():
		actor_defeated.emit(target, attacker)
	if applied > 0.0:
		_apply_lifesteal(attacker, applied)
		_apply_thorns(target, attacker, applied)
	return applied


## Heals `target` by `amount` (class skills, D70). Returns the HP restored.
func heal(source: Actor, target: Actor, amount: float) -> float:
	if not is_instance_valid(target) or not target.is_targetable():
		return 0.0
	var applied := target.health.heal(amount)
	if applied > 0.0:
		actor_healed.emit(source, target, applied)
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


func _dodges(defense: CombatStats) -> bool:
	return defense.dodge > 0.0 and _rng.randf() < defense.dodge


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
