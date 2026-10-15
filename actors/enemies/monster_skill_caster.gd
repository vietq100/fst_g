class_name MonsterSkillCaster
extends Node
## Casts a monster's active skills (2 per monster) while it fights: cooldowns tick, and at most one
## skill is cast per `CAST_GAP` seconds. Damage goes through CombatService; effects reuse the
## status effects (D48). Passive skills are applied by Enemy.

## Seconds between two casts of one monster.
const CAST_GAP := 1.5

var _enemy: Enemy
var _combat: CombatService
var _skills: Array[MonsterSkillDefinition] = []
var _cooldowns: Dictionary[StringName, float] = {}
var _gap := 0.0


func setup(enemy: Enemy, combat: CombatService, skills: Array[MonsterSkillDefinition]) -> void:
	_enemy = enemy
	_combat = combat
	for skill in skills:
		if skill.is_active():
			_skills.append(skill)
			# Start part-way through the cooldown so a pack does not cast in sync.
			_cooldowns[skill.id] = randf_range(0.3, 0.8) * skill.cooldown


func has_skills() -> bool:
	return not _skills.is_empty()


func get_cooldown(skill_id: StringName) -> float:
	return _cooldowns.get(skill_id, 0.0)


func _physics_process(delta: float) -> void:
	advance(delta)


## One step (tests call it directly).
func advance(delta: float) -> void:
	if _enemy == null or _enemy.health.is_dead():
		return
	for skill_id: StringName in _cooldowns.keys():
		_cooldowns[skill_id] = maxf(_cooldowns[skill_id] - delta, 0.0)
	_gap = maxf(_gap - delta, 0.0)
	var target := _enemy.combat.target
	if _gap > 0.0 or not _enemy.combat.is_valid_target(target) or not _enemy.can_attack():
		return
	for skill in _skills:
		if _cooldowns[skill.id] > 0.0:
			continue
		if try_cast(skill, target):
			return


## Casts `skill` at `target` if its conditions hold; starts the cooldown. True when it fired.
func try_cast(skill: MonsterSkillDefinition, target: Actor) -> bool:
	if skill.trigger_hp_below > 0.0 and _enemy.health.get_ratio() >= skill.trigger_hp_below:
		return false
	var reach := maxf(skill.cast_range, _enemy.combat.get_reach())
	var needs_target := skill.attack_ratio > 0.0 or not skill.target_effects.is_empty()
	if needs_target and _enemy.global_position.distance_to(target.global_position) > reach:
		return false
	_cooldowns[skill.id] = skill.cooldown
	_gap = CAST_GAP
	_combat.monster_skill_cast.emit(_enemy, skill)
	if needs_target:
		_enemy.face_towards(target.global_position)
		_enemy.visual.play_attack_lunge(target.global_position - _enemy.global_position)
		if skill.attack_ratio > 0.0:
			var raw := skill.attack_ratio * _enemy.get_final_combat_stats(target).attack
			for i in maxi(skill.hits, 1):
				if not target.is_targetable():
					break
				_combat.resolve_skill_hit(_enemy, target, raw)
		if target.is_targetable():
			_apply(skill.target_effects, target)
	if skill.heal_ratio > 0.0:
		_combat.heal(_enemy, _enemy, skill.heal_ratio * _enemy.health.max_health)
	_apply(skill.self_effects, _enemy)
	return true


func _apply(entries: Array[StatusEffectChance], target: Actor) -> void:
	for entry in entries:
		if entry == null or entry.effect == null or randf() >= entry.chance:
			continue
		var effect := entry.effect
		# Shields have no value of their own: size them from the caster's max HP.
		var applied := target.effects.apply(effect, _enemy, entry.stacks)
		if applied != null and effect.id == &"shield" and applied.shield <= 0.0:
			applied.shield = _enemy.health.max_health * 0.15
