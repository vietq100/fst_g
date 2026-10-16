class_name ClassSkillCaster
extends Node
## Casts a Hunter's class skills in combat (D70): regenerates mana, ticks cooldowns and, at most
## once per `class_skill_cast_gap`, casts the first ready skill whose conditions hold. Actives
## pay mana; triggered passives are free. Rules and numbers come from ClassSkillDefinition and
## ClassSkillService; damage and heals go through CombatService.

## Heal skills wait until someone is below this HP ratio.
const HEAL_BELOW := 0.7
## Effect applied to bosses instead of hard crowd control (D69).
const STAGGER := &"stagger"
## Most allies glowing from one support skill (D77).
const MAX_AURAS := 4

var _hunter: Hunter
var _service: ClassSkillService
var _combat: CombatService
var _config: GameConfig
## skill id -> seconds left.
var _cooldowns: Dictionary[StringName, float] = {}
var _gap := 0.0
## Stats and castable skills are re-read this often (seconds), not every frame.
const REFRESH_INTERVAL := 0.5

var _refresh := 0.0
var _max_mana_cached := 0.0
var _regen_cached := 0.0
var _castables: Array[Dictionary] = []
## Skill whose last hit should reset its cooldown on a kill (reset_on_kill), during one cast.
var _casting: ClassSkillDefinition


func setup(hunter: Hunter, service: ClassSkillService, combat: CombatService, config: GameConfig) -> void:
	_hunter = hunter
	_service = service
	_combat = combat
	_config = config
	if not _combat.actor_defeated.is_connected(_on_actor_defeated):
		_combat.actor_defeated.connect(_on_actor_defeated)
	refresh()
	var runtime := _hunter.runtime
	runtime.current_mana = minf(runtime.current_mana, _max_mana_cached) if runtime.current_mana > 0.0 else _max_mana_cached


## Re-reads max mana, regen and the castable skills (after level, gear or skill changes).
func refresh() -> void:
	_refresh = REFRESH_INTERVAL
	_max_mana_cached = _max_mana()
	_regen_cached = _service_stat(HunterService.MANA_REGEN)
	_castables = _service.get_castables(_hunter.runtime)


func get_max_mana() -> float:
	return _max_mana_cached


## 0–1 for the nameplate's mana bar.
func get_mana_ratio() -> float:
	return clampf(_hunter.runtime.current_mana / _max_mana_cached, 0.0, 1.0) if _max_mana_cached > 0.0 else 0.0


func get_cooldown(skill_id: StringName) -> float:
	return _cooldowns.get(skill_id, 0.0)


func _physics_process(delta: float) -> void:
	advance(delta)


## One step of mana, cooldowns and casting (tests call it directly).
func advance(delta: float) -> void:
	if _hunter == null or _hunter.runtime == null or _hunter.health.is_dead():
		return
	var runtime := _hunter.runtime
	_refresh -= delta
	if _refresh <= 0.0:
		refresh()
	var fighting := _hunter.combat.is_valid_target(_hunter.combat.target)
	var regen := _regen_cached * (1.0 if fighting else _config.mana_regen_idle_multiplier)
	runtime.current_mana = minf(runtime.current_mana + regen * delta, _max_mana_cached)
	for skill_id: StringName in _cooldowns.keys():
		_cooldowns[skill_id] = maxf(_cooldowns[skill_id] - delta, 0.0)
	_gap = maxf(_gap - delta, 0.0)
	if _gap > 0.0 or not fighting or not _hunter.can_attack():
		return
	for entry in _castables:
		var skill: ClassSkillDefinition = entry["skill"]
		var level: int = entry["level"]
		if get_cooldown(skill.id) > 0.0:
			continue
		var cost := _service.get_mana_cost(skill, level)
		if runtime.current_mana < cost:
			continue
		if try_cast(skill, level):
			runtime.current_mana -= cost
			_gap = _config.class_skill_cast_gap
			return


## Casts `skill` now if its conditions hold (cooldown and mana are the caller's business).
## Returns true when it did something; starts the cooldown.
func try_cast(skill: ClassSkillDefinition, level: int) -> bool:
	if skill.trigger_hp_below > 0.0 and _hunter.health.get_ratio() >= skill.trigger_hp_below:
		return false
	var power := _service.get_power(level)
	var enemies := _enemy_targets(skill)
	if skill.targets_enemies() and enemies.is_empty():
		return false
	var allies := _ally_targets(skill)
	if (skill.heal_ratio > 0.0 or skill.cleanse) and not skill.deals_damage() and not _anyone_needs_help(allies, skill):
		return false
	_cooldowns[skill.id] = skill.cooldown
	_combat.skill_cast.emit(_hunter, skill)
	if skill.targets_enemies():
		_hunter.face_towards(enemies[0].global_position)
		_hunter.visual.play_attack_lunge(enemies[0].global_position - _hunter.global_position)
	var element := ForgeLook.element_for_skill(skill)
	var look := _hunter.visual as ChibiVisual
	if look != null:
		# Attack effects in the skill's element (D73 / Q5).
		look.play_skill(element, skill.targets_enemies())
	_play_effects(skill, element, enemies, allies)
	_casting = skill
	for enemy in enemies:
		_hit(skill, power, enemy)
	_casting = null
	_support(skill, power, allies)
	_apply_all(skill.self_effects, _hunter, power)
	if skill.taunt:
		for enemy in _enemies_within(_hunter.global_position, skill.radius):
			enemy.combat.force_target(_hunter)
	return true


## Pixel effects of a cast skill in its element (D77): a shock wave where an area skill lands (around the
## caster or its target, and around a taunting caster), a burst on a single target (a spell column when the
## skill only debuffs it), and an aura on everyone a heal, shield or buff helps (at most MAX_AURAS).
func _play_effects(skill: ClassSkillDefinition, element: String, enemies: Array[Actor], allies: Array[Actor]) -> void:
	var world := _hunter.get_parent()
	if world == null:
		return
	match skill.target:
		ClassSkillDefinition.Target.ENEMIES_AROUND_SELF:
			SkillEffect.play(world, _hunter.global_position, SkillEffect.Kind.SLAM, element)
		ClassSkillDefinition.Target.ENEMIES_AROUND_TARGET:
			if not enemies.is_empty():
				SkillEffect.play(world, _hunter.combat.target.global_position, SkillEffect.Kind.SLAM, element)
		ClassSkillDefinition.Target.ENEMY:
			var kind := SkillEffect.Kind.STRIKE if skill.deals_damage() else SkillEffect.Kind.SPELL
			for enemy in enemies:
				SkillEffect.play(world, enemy.global_position, kind, element)
	if skill.taunt and skill.target != ClassSkillDefinition.Target.ENEMIES_AROUND_SELF:
		SkillEffect.play(world, _hunter.global_position, SkillEffect.Kind.SLAM, element)
	for ally in allies.slice(0, MAX_AURAS):
		# On the ally, so the glow follows it.
		SkillEffect.play(ally, ally.global_position, SkillEffect.Kind.AURA, element)


func _hit(skill: ClassSkillDefinition, power: float, enemy: Actor) -> void:
	if not is_instance_valid(enemy) or not enemy.is_targetable():
		return
	var boss := _is_boss(enemy)
	if skill.deals_damage():
		var runtime := _hunter.runtime
		var stats := _hunter.get_final_combat_stats(enemy)
		var ratio := skill.attack_ratio
		if skill.stack_effect != &"":
			var stacked := enemy.effects.get_effect(skill.stack_effect)
			if stacked != null:
				ratio += skill.ratio_per_stack * stacked.stacks
				if skill.consume_stacks:
					enemy.effects.remove(skill.stack_effect)
		var raw := ratio * stats.attack + skill.stat_ratio * _service.get_scale_value(runtime, skill.scale_stat)
		if skill.stat_multiplier:
			raw *= _service.get_scale_value(runtime, skill.scale_stat) / _service.get_base_value(runtime, skill.scale_stat)
		raw *= power
		var multiplier := 1.0
		var threshold := minf(skill.execute_threshold, _config.boss_execute_threshold) if boss else skill.execute_threshold
		if threshold > 0.0 and enemy.health.get_ratio() < threshold:
			multiplier *= skill.execute_multiplier
		if skill.tag_bonus != &"" and enemy is Enemy and (enemy as Enemy).definition != null \
				and (enemy as Enemy).definition.tags.has(skill.tag_bonus):
			multiplier *= 1.0 + skill.tag_bonus_ratio
		for i in _hit_count(skill):
			if not enemy.is_targetable():
				break
			_combat.resolve_skill_hit(_hunter, enemy, raw, skill.bonus_crit, skill.bonus_crit_damage, multiplier, skill.ignore_dodge)
	if enemy.is_targetable():
		_apply_all(skill.target_effects, enemy, power, boss)
	if skill.heal_ratio > 0.0 and skill.targets_enemies():
		_heal(_hunter, skill.heal_ratio * power)


func _support(skill: ClassSkillDefinition, power: float, allies: Array[Actor]) -> void:
	for ally in allies:
		if skill.cleanse:
			ally.effects.dispel(StatusEffectDefinition.Kind.DEBUFF)
		if skill.heal_ratio > 0.0 and not skill.targets_enemies():
			_heal(ally, skill.heal_ratio * power)
		if skill.shield_ratio > 0.0:
			_shield(ally, skill.shield_ratio * power)
		_apply_all(skill.ally_effects, ally, power)


func _heal(target: Actor, ratio: float) -> void:
	var amount := ratio * _service_stat(HunterService.MAX_HP) * _service_stat(HunterService.HEALING)
	_combat.heal(_hunter, target, amount)


func _shield(target: Actor, ratio: float) -> void:
	var definition := _service.get_effect(&"shield")
	if definition == null:
		return
	var effect := target.effects.apply(definition, _hunter)
	if effect != null:
		effect.shield = maxf(effect.shield, ratio * _service_stat(HunterService.MAX_HP))


## Applies skill effects. Durations grow with the skill level (D70): buffs by the full power
## bonus, debuffs by `class_skill_debuff_duration_share` of it. Bosses turn hard crowd control
## into Stagger and keep soft debuffs for half as long (D69). Tenacity was already applied.
func _apply_all(entries: Array[StatusEffectChance], target: Actor, power: float, boss: bool = false) -> void:
	for entry in entries:
		if entry == null or entry.effect == null or randf() >= entry.chance:
			continue
		var effect := entry.effect
		if boss and (effect.stuns or effect.roots or effect.disarms):
			var stagger := _service.get_effect(STAGGER)
			if stagger != null:
				target.effects.apply(stagger, _hunter)
			continue
		var applied := target.effects.apply(effect, _hunter, entry.stacks)
		if applied == null or applied.is_permanent():
			continue
		applied.remaining *= _service.get_duration_scale(effect, power)
		if boss and effect.kind == StatusEffectDefinition.Kind.DEBUFF and not effect.modifiers.is_empty():
			applied.remaining *= _config.boss_soft_debuff_scale


func _hit_count(skill: ClassSkillDefinition) -> int:
	var count := maxi(skill.hits, 1)
	if skill.max_hits > count:
		var speed := _service_stat(HunterService.ATTACK_SPEED)
		count = clampi(count + floori(maxf(speed - 1.0, 0.0) / 0.25), count, skill.max_hits)
	return count


func _enemy_targets(skill: ClassSkillDefinition) -> Array[Actor]:
	var result: Array[Actor] = []
	var target := _hunter.combat.target
	if not _hunter.combat.is_valid_target(target):
		return result
	var reach := maxf(skill.cast_range, _hunter.combat.get_reach())
	match skill.target:
		ClassSkillDefinition.Target.ENEMY:
			if _hunter.global_position.distance_to(target.global_position) <= reach:
				result.append(target)
		ClassSkillDefinition.Target.ENEMIES_AROUND_SELF:
			result = _enemies_within(_hunter.global_position, maxf(skill.radius, _hunter.combat.get_reach()))
		ClassSkillDefinition.Target.ENEMIES_AROUND_TARGET:
			if _hunter.global_position.distance_to(target.global_position) <= reach:
				result = _enemies_within(target.global_position, skill.radius)
				if not result.has(target):
					result.push_front(target)
	return result


func _ally_targets(skill: ClassSkillDefinition) -> Array[Actor]:
	var result: Array[Actor] = []
	match skill.target:
		ClassSkillDefinition.Target.ALLIES_AROUND:
			result = _allies_within(skill.radius)
		ClassSkillDefinition.Target.LOWEST_ALLY:
			var lowest: Actor = null
			for ally in _allies_within(skill.radius):
				if lowest == null or ally.health.get_ratio() < lowest.health.get_ratio():
					lowest = ally
			if lowest != null:
				result.append(lowest)
		ClassSkillDefinition.Target.SELF:
			result.append(_hunter)
	return result


func _anyone_needs_help(allies: Array[Actor], skill: ClassSkillDefinition) -> bool:
	for ally in allies:
		if skill.heal_ratio > 0.0 and ally.health.get_ratio() < HEAL_BELOW:
			return true
		if skill.cleanse and ally.effects.get_effects().any(func(effect: StatusEffect) -> bool:
				return effect.definition.kind == StatusEffectDefinition.Kind.DEBUFF and effect.definition.dispellable):
			return true
	return false


func _enemies_within(center: Vector2, radius: float) -> Array[Actor]:
	var result: Array[Actor] = []
	for node in get_tree().get_nodes_in_group(_hunter.combat.target_group):
		var actor := node as Actor
		if actor != null and actor.is_targetable() and actor.global_position.distance_to(center) <= radius:
			result.append(actor)
	return result


## The caster and living Hunters within `radius`.
func _allies_within(radius: float) -> Array[Actor]:
	var result: Array[Actor] = [_hunter]
	for node in get_tree().get_nodes_in_group(Hunter.GROUP):
		var actor := node as Actor
		if actor != null and actor != _hunter and actor.is_targetable() \
				and actor.global_position.distance_to(_hunter.global_position) <= radius:
			result.append(actor)
	return result


func _is_boss(actor: Actor) -> bool:
	return actor is Enemy and (actor as Enemy).definition != null and (actor as Enemy).definition.is_boss


func _max_mana() -> float:
	return _service_stat(HunterService.MAX_MANA)


func _service_stat(stat: StringName) -> float:
	return _hunter.get_hunter_stat(stat)


func _on_actor_defeated(actor: Actor, by: Actor) -> void:
	if by != _hunter or actor == _hunter or _hunter.runtime == null:
		return
	var heal := _service.get_kill_heal_ratio(_hunter.runtime)
	if heal > 0.0:
		_heal(_hunter, heal)
	if _casting != null and _casting.reset_on_kill and not _is_boss(actor):
		_cooldowns[_casting.id] = 0.0
