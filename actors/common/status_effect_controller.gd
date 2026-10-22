class_name StatusEffectController
extends Node
## Active buffs/debuffs of one actor (COMBAT_SYSTEM.md → Status effects, D48): durations,
## stacking, ticks, crowd control, stat modifiers, shield, thorns and lifesteal.
## Damage over time goes through CombatService so kills are credited; never touches UI.

signal effect_applied(effect: StatusEffect)
signal effect_removed(effect: StatusEffect)
## Shield points that soaked up damage.
signal shield_absorbed(amount: float)

var _effects: Array[StatusEffect] = []


## Only ticks while an effect runs (most actors have none): the physics callback is off otherwise.
func _ready() -> void:
	set_physics_process(not _effects.is_empty())


## Adds the effect or stacks/refreshes the running one. Returns the active effect, or null
## when the owner is dead.
func apply(definition: StatusEffectDefinition, source: Actor = null, stacks: int = 1) -> StatusEffect:
	var actor: Actor = _actor()
	if definition == null or (actor != null and actor.health.is_dead()):
		return null
	var effect: StatusEffect = get_effect(definition.id)
	if effect == null:
		effect = StatusEffect.new(definition, source, stacks)
		_effects.append(effect)
		set_physics_process(true)
	else:
		match definition.stacking:
			StatusEffectDefinition.Stacking.IGNORE:
				return effect
			StatusEffectDefinition.Stacking.STACK:
				effect.stacks = mini(effect.stacks + maxi(stacks, 1), maxi(definition.max_stacks, 1))
		effect.source = source
		effect.restart()
	if definition.kind == StatusEffectDefinition.Kind.DEBUFF and actor != null and _is_crowd_control(definition):
		# Tenacity (D70) shortens crowd control.
		effect.remaining *= 1.0 - clampf(actor.get_tenacity(), 0.0, 1.0)
	effect_applied.emit(effect)
	return effect


## Stun, freeze, root, disarm and slows count as crowd control.
static func _is_crowd_control(definition: StatusEffectDefinition) -> bool:
	if definition.stuns or definition.roots or definition.disarms:
		return true
	for modifier in definition.modifiers:
		if modifier != null and modifier.stat == HunterService.MOVE_SPEED and modifier.value < 0.0:
			return true
	return false


func remove(id: StringName) -> bool:
	var effect: StatusEffect = get_effect(id)
	if effect == null:
		return false
	_remove(effect)
	return true


## Removes dispellable effects of one kind (cleanse = DEBUFF, purge = BUFF). Returns the count.
func dispel(kind: StatusEffectDefinition.Kind) -> int:
	var removed := 0
	for effect in _effects.duplicate():
		if effect.definition.kind == kind and effect.definition.dispellable:
			_remove(effect)
			removed += 1
	return removed


## Everything, dispellable or not (death, revive).
func clear_all() -> void:
	for effect in _effects.duplicate():
		_remove(effect)


func has_effect(id: StringName) -> bool:
	return get_effect(id) != null


func get_effect(id: StringName) -> StatusEffect:
	for effect in _effects:
		if effect.get_id() == id:
			return effect
	return null


func get_effects() -> Array[StatusEffect]:
	return _effects.duplicate()


func can_move() -> bool:
	return not _effects.any(func(effect: StatusEffect) -> bool: return effect.definition.blocks_movement())


func can_attack() -> bool:
	return not _effects.any(func(effect: StatusEffect) -> bool: return effect.definition.blocks_attack())


func is_stunned() -> bool:
	return _effects.any(func(effect: StatusEffect) -> bool: return effect.definition.stuns)


func is_invulnerable() -> bool:
	return _effects.any(func(effect: StatusEffect) -> bool: return effect.definition.invulnerable)


## Applies every active stat modifier to `stats` (in place) and returns it.
func modify_combat_stats(stats: CombatStats) -> CombatStats:
	if _effects.is_empty():
		return stats
	stats.attack = modify_stat(HunterService.ATTACK, stats.attack)
	stats.defense = modify_stat(HunterService.DEFENSE, stats.defense)
	stats.attack_speed = modify_stat(HunterService.ATTACK_SPEED, stats.attack_speed)
	stats.critical_chance = minf(modify_stat(HunterService.CRITICAL_CHANCE, stats.critical_chance), 1.0)
	stats.critical_damage = modify_stat(HunterService.CRITICAL_DAMAGE, stats.critical_damage)
	stats.damage_dealt = modify_stat(HunterService.DAMAGE_DEALT, stats.damage_dealt)
	stats.damage_taken = modify_stat(HunterService.DAMAGE_TAKEN, stats.damage_taken)
	return stats


## (value + Σflat) × (1 + Σpercent), never below 0. Modifiers scale with stacks.
func modify_stat(stat: StringName, value: float) -> float:
	var flat := 0.0
	var percent := 0.0
	for effect in _effects:
		for modifier in effect.definition.modifiers:
			if modifier == null or modifier.stat != stat:
				continue
			if modifier.type == StatModifier.Type.FLAT:
				flat += modifier.value * effect.stacks
			else:
				percent += modifier.value * effect.stacks
	return maxf((value + flat) * (1.0 + percent), 0.0)


## Soaks `amount` with shields (oldest first); returns what is left for HP.
## Shield effects that are used up end.
func absorb_damage(amount: float) -> float:
	var absorbed := 0.0
	for effect in _effects.duplicate():
		if amount <= 0.0:
			break
		if effect.shield <= 0.0:
			continue
		var used: float = minf(effect.shield, amount)
		effect.shield -= used
		amount -= used
		absorbed += used
		if effect.shield <= 0.0:
			_remove(effect)
	if absorbed > 0.0:
		shield_absorbed.emit(absorbed)
	return amount


func get_shield_total() -> float:
	var total := 0.0
	for effect in _effects:
		total += effect.shield
	return total


func get_thorns() -> float:
	return _sum(func(effect: StatusEffect) -> float: return effect.definition.thorns * effect.stacks)


func get_lifesteal() -> float:
	return _sum(func(effect: StatusEffect) -> float: return effect.definition.lifesteal * effect.stacks)


## First active effect with thorns (its colour is used for the reflected damage number).
func get_thorns_effect() -> StatusEffect:
	for effect in _effects:
		if effect.definition.thorns > 0.0:
			return effect
	return null


## Advances durations and ticks. Public so tests can step time without the SceneTree.
func advance(delta: float) -> void:
	for effect in _effects.duplicate():
		if not _effects.has(effect):
			# Removed by an earlier tick (e.g. the owner died).
			continue
		var definition: StatusEffectDefinition = effect.definition
		if definition.tick_interval > 0.0 and (definition.damage_per_tick > 0.0 or definition.heal_per_tick > 0.0):
			effect.tick_timer -= delta
			while effect.tick_timer <= 0.0 and _effects.has(effect):
				effect.tick_timer += definition.tick_interval
				_tick(effect)
		if not _effects.has(effect) or effect.is_permanent():
			continue
		effect.remaining -= delta
		if effect.remaining <= 0.0:
			_remove(effect)


func _physics_process(delta: float) -> void:
	if not _effects.is_empty():
		advance(delta)


func _tick(effect: StatusEffect) -> void:
	var actor: Actor = _actor()
	if actor == null:
		return
	var definition: StatusEffectDefinition = effect.definition
	var scale: float = float(effect.stacks) * (actor.health.max_health if definition.tick_is_ratio else 1.0)
	if definition.heal_per_tick > 0.0:
		actor.health.heal(definition.heal_per_tick * scale)
	if definition.damage_per_tick > 0.0:
		var amount: float = definition.damage_per_tick * scale
		if definition.tick_is_ratio:
			# Damage in % of max HP is scaled down on bosses (D70), e.g. Bleed on a 4200 HP boss.
			amount *= actor.get_ratio_damage_scale()
		var service: CombatService = actor.combat.get_service()
		if service != null:
			service.resolve_effect_damage(effect.get_source(), actor, amount, definition)
		elif not is_invulnerable():
			actor.health.take_damage(absorb_damage(amount))


func _remove(effect: StatusEffect) -> void:
	_effects.erase(effect)
	if _effects.is_empty():
		set_physics_process(false)
	effect_removed.emit(effect)


func _sum(value_of: Callable) -> float:
	var total := 0.0
	for effect in _effects:
		total += value_of.call(effect)
	return total


func _actor() -> Actor:
	return get_parent() as Actor
