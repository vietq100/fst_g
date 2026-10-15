class_name MonsterSkillDefinition
extends GameDefinition
## Skill of one monster type (10 per type; every monster rolls 2). Actives fire on a cooldown while
## the monster fights; passives add percent bonuses. Effects reuse the status effects (D48).

enum Kind { ACTIVE, PASSIVE }

## Monster type (EnemyDefinition id) whose pool holds the skill.
@export var enemy_id: StringName
@export var kind: Kind = Kind.ACTIVE
## Translation key; reading returns the translated text (D61).
@export_multiline var description: String:
	get:
		return tr(description) if not description.is_empty() else description

@export_group("Active")
@export var cooldown: float = 10.0
## Pixels; 0 = the monster's attack range.
@export var cast_range: float = 0.0
## Damage = attack_ratio × the monster's attack (through defense and crit, like a hit).
@export var attack_ratio: float = 0.0
@export var hits: int = 1
## Only cast while the monster's HP ratio is below this (0 = always).
@export_range(0.0, 1.0) var trigger_hp_below: float = 0.0
## Heals this share of max HP when cast.
@export var heal_ratio: float = 0.0
@export var target_effects: Array[StatusEffectChance] = []
@export var self_effects: Array[StatusEffectChance] = []

@export_group("Passive")
## Percent modifiers on attack, defense, attack_speed, move_speed and max_hp (fractions).
@export var modifiers: Array[StatModifier] = []


func is_active() -> bool:
	return kind == Kind.ACTIVE
