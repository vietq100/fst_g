class_name Enemy
extends Actor
## Enemy actor driven by an EnemyDefinition. AI: find nearest Hunter → approach →
## attack in range → retarget when the target is invalid (AI_SYSTEM.md).

const GROUP := &"enemies"
## Seconds the death effect plays before the node is removed.
const DEATH_DURATION := 0.5

var definition: EnemyDefinition
## Region monster level (BALANCE.md → Regions); 1 = base stats.
var level := 1
## HP / attack / defense multiplier for `level` and tier (set by the spawner).
var stat_scale := 1.0
## Tier of this monster (D60): the boss's fixed tier or a roll.
var tier: int = Tier.Level.C
## Gear, gold, materials, skills and meat this monster carries (region monsters only).
var loadout: MonsterLoadout
## Passive skill bonuses (fractions) and gear modifiers, read by the combat stats.
var _percent: Dictionary[StringName, float] = {}
var _flat: Dictionary[StringName, float] = {}
var _caster: MonsterSkillCaster


## Call after the node is in the tree.
func setup(enemy_definition: EnemyDefinition, combat_service: CombatService, retarget_interval: float,
		monster_level: int = 1, monster_stat_scale: float = 1.0, monster_tier: int = -1) -> void:
	definition = enemy_definition
	level = monster_level
	tier = enemy_definition.tier if monster_tier < 0 else monster_tier
	stat_scale = monster_stat_scale * Tier.stat_scale(tier)
	add_to_group(GROUP)
	health.setup(definition.hp * stat_scale)
	combat.setup(Hunter.GROUP, definition.attack_range, retarget_interval, combat_service)
	auto_combat = true
	repositions_in_range = not definition.is_boss
	# HP bar while hurt; bosses also show their name.
	var plate := ActorNameplate.new()
	add_child(plate)
	# Bosses and monsters of tier R and up show their tier code (and bosses their name) in its colour.
	var label := definition.display_name if definition.is_boss else ""
	if definition.is_boss or tier >= Tier.Level.R:
		label = ("[%s] %s" % [Tier.code(tier), label]).strip_edges()
	plate.boss = definition.is_boss
	plate.setup(self, label, 56.0 if definition.is_boss else 28.0)
	plate.name_color = Tier.color(tier) if tier > Tier.Level.C else ActorNameplate.NAME_COLOR


## Gives the monster its gear and skills: gear adds flat / percent stats, passive skills add
## percent stats, active skills are cast by a MonsterSkillCaster. Call after `setup`.
func apply_loadout(monster_loadout: MonsterLoadout) -> void:
	loadout = monster_loadout
	_percent.clear()
	_flat.clear()
	var skills: Array[MonsterSkillDefinition] = []
	for item_id in loadout.get_gear():
		var item := DataRegistry.find_def(&"item", item_id) as ItemDefinition
		if item == null:
			continue
		for modifier in item.modifiers:
			var bucket := _percent if modifier.type == StatModifier.Type.PERCENT else _flat
			bucket[modifier.stat] = bucket.get(modifier.stat, 0.0) + modifier.value
	for skill_id in loadout.skills:
		var skill := DataRegistry.find_def(&"monster_skill", skill_id) as MonsterSkillDefinition
		if skill == null:
			continue
		skills.append(skill)
		for modifier in skill.modifiers:
			_percent[modifier.stat] = _percent.get(modifier.stat, 0.0) + modifier.value
	health.setup((definition.hp * stat_scale + _flat.get(&"max_hp", 0.0)) * (1.0 + _percent.get(&"max_hp", 0.0)))
	if _caster != null:
		_caster.queue_free()
		_caster = null
	_caster = MonsterSkillCaster.new()
	_caster.name = "MonsterSkillCaster"
	add_child(_caster)
	_caster.setup(self, combat.get_service(), skills)


func get_team_group() -> StringName:
	return GROUP


func get_move_speed() -> float:
	return definition.move_speed * (1.0 + _percent.get(&"move_speed", 0.0)) if definition != null else 0.0


func get_hit_radius() -> float:
	return definition.hit_radius if definition != null else 0.0


func get_combat_stats(_against: Actor = null) -> CombatStats:
	var stats := CombatStats.new()
	stats.attack = (definition.attack * stat_scale + _flat.get(&"attack", 0.0)) * (1.0 + _percent.get(&"attack", 0.0))
	stats.defense = maxf((definition.defense * stat_scale + _flat.get(&"defense", 0.0)) * (1.0 + _percent.get(&"defense", 0.0)), 0.0)
	stats.attack_speed = definition.attack_speed * (1.0 + _percent.get(&"attack_speed", 0.0))
	stats.critical_chance = clampf(definition.critical_chance + _flat.get(&"critical_chance", 0.0), 0.0, 1.0)
	stats.critical_damage = definition.critical_damage
	return stats


## Bosses take a fraction of %-max-HP damage over time (D70, GameConfig.boss_ratio_dot_scale).
func get_ratio_damage_scale() -> float:
	if definition == null or not definition.is_boss:
		return 1.0
	return DataRegistry.config.boss_ratio_dot_scale if is_instance_valid(DataRegistry) and DataRegistry.config != null else 0.25


func get_on_hit_effects() -> Array[StatusEffectChance]:
	return definition.on_hit_effects if definition != null else [] as Array[StatusEffectChance]


func _on_died() -> void:
	super()
	remove_from_group(GROUP)
	visual.play_death(DEATH_DURATION)
	get_tree().create_timer(DEATH_DURATION).timeout.connect(queue_free)
