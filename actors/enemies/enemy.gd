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
## HP / attack / defense multiplier for `level` (set by the spawner).
var stat_scale := 1.0


## Call after the node is in the tree.
func setup(enemy_definition: EnemyDefinition, combat_service: CombatService, retarget_interval: float,
		monster_level: int = 1, monster_stat_scale: float = 1.0) -> void:
	definition = enemy_definition
	level = monster_level
	stat_scale = monster_stat_scale
	add_to_group(GROUP)
	health.setup((definition.hp + _gear_flat(HunterService.MAX_HP)) * stat_scale * (1.0 + _gear_percent(HunterService.MAX_HP)))
	_dress()
	combat.setup(Hunter.GROUP, definition.attack_range, retarget_interval, combat_service)
	auto_combat = true
	repositions_in_range = not definition.is_boss
	# HP bar while hurt; bosses also show their name.
	var plate := ActorNameplate.new()
	add_child(plate)
	plate.setup(self, definition.display_name if definition.is_boss else "", 56.0 if definition.is_boss else 28.0)


func get_team_group() -> StringName:
	return GROUP


func get_move_speed() -> float:
	return definition.move_speed if definition != null else 0.0


func get_hit_radius() -> float:
	return definition.hit_radius if definition != null else 0.0


## Base stats scaled by the region level, plus the monster's gear (D55): weapon and armor
## modifiers follow the D18 rule (base + Σflat) × (1 + Σpercent).
func get_combat_stats(_against: Actor = null) -> CombatStats:
	var stats := CombatStats.new()
	stats.attack = (definition.attack + _gear_flat(HunterService.ATTACK)) * stat_scale * (1.0 + _gear_percent(HunterService.ATTACK))
	stats.defense = (definition.defense + _gear_flat(HunterService.DEFENSE)) * stat_scale * (1.0 + _gear_percent(HunterService.DEFENSE))
	stats.attack_speed = (definition.attack_speed + _gear_flat(HunterService.ATTACK_SPEED)) * (1.0 + _gear_percent(HunterService.ATTACK_SPEED))
	stats.critical_chance = definition.critical_chance + _gear_flat(HunterService.CRITICAL_CHANCE)
	stats.critical_damage = definition.critical_damage + _gear_flat(HunterService.CRITICAL_DAMAGE)
	return stats


## The monster's two active skills (D55).
func get_active_skills() -> Array[ActiveSkillDefinition]:
	var result: Array[ActiveSkillDefinition] = []
	if definition == null:
		return result
	for skill_id in definition.skill_ids:
		var skill := ActiveSkills.get_skill(DataRegistry, skill_id)
		if skill != null:
			result.append(skill)
	return result


## Weapon and armor items of this monster (missing ids are skipped).
func get_gear() -> Array[ItemDefinition]:
	var gear: Array[ItemDefinition] = []
	if definition == null:
		return gear
	for item_id in [definition.weapon_id, definition.armor_id]:
		if item_id == &"":
			continue
		var item := DataRegistry.find_def(DataRegistry.ITEM, item_id) as ItemDefinition
		if item != null:
			gear.append(item)
	return gear


func _gear_flat(stat: StringName) -> float:
	var total := 0.0
	for item in get_gear():
		for modifier in item.modifiers:
			if modifier.stat == stat and modifier.type == StatModifier.Type.FLAT and modifier.condition == &"":
				total += modifier.value
	return total


func _gear_percent(stat: StringName) -> float:
	var total := 0.0
	for item in get_gear():
		for modifier in item.modifiers:
			if modifier.stat == stat and modifier.type == StatModifier.Type.PERCENT and modifier.condition == &"":
				total += modifier.value
	return total


## Shows the weapon item in the monster's hand (MonsterVisual).
func _dress() -> void:
	var look := visual as MonsterVisual
	if look == null or definition.weapon_id == &"":
		return
	var weapon := DataRegistry.find_def(DataRegistry.ITEM, definition.weapon_id) as ItemDefinition
	if weapon == null:
		return
	look.weapon_sprite = WeaponSprites.kind_for_item(weapon, look.weapon_sprite)
	if weapon.tint != Color.WHITE:
		look.weapon_color = weapon.tint


func get_on_hit_effects() -> Array[StatusEffectChance]:
	return definition.on_hit_effects if definition != null else [] as Array[StatusEffectChance]


func _on_died() -> void:
	super()
	remove_from_group(GROUP)
	visual.play_death(DEATH_DURATION)
	get_tree().create_timer(DEATH_DURATION).timeout.connect(queue_free)
