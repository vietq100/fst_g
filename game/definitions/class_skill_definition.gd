class_name ClassSkillDefinition
extends GameDefinition
## Class skill (D69, D70): one of the 30 skills of a base class. A Hunter owns up to 7, each at
## level 1–6; power grows with the skill level (ClassSkillService.get_power). Actives cost mana
## and have a cooldown; passives add stat modifiers, on-hit effects, or trigger on their own.
## Full list and balance notes: guide/skills_guide.md.

enum Kind { ACTIVE, PASSIVE }
## Who a skill hits or helps.
enum Target {
	ENEMY, ## The caster's current target.
	ENEMIES_AROUND_SELF, ## Every enemy within `radius` of the caster.
	ENEMIES_AROUND_TARGET, ## Every enemy within `radius` of the current target.
	SELF, ## The caster only.
	ALLIES_AROUND, ## The caster and every Hunter within `radius`.
	LOWEST_ALLY, ## The Hunter (caster included) with the lowest HP ratio within `radius`.
}

## Base class whose pool holds this skill (warrior, ranger, rogue, guardian).
@export var class_id: StringName
## Position in the class list (1–30).
@export var order: int = 0
@export var kind: Kind = Kind.ACTIVE
## A translation key (D61); reading it returns the translated text.
@export_multiline var description: String:
	get:
		return tr(description) if not description.is_empty() else description
## Main stat the skill scales with (HunterService stat id, or &"attack_range", &"level").
@export var scale_stat: StringName = &"attack"
## Stars 1–3 against monsters, people (Hunters, humanoids) and bosses. Display only.
@export var ratings: Vector3i = Vector3i(2, 2, 2)

@export_group("Trigger")
## Seconds. Actives always have one; a passive with a cooldown triggers on its own (no mana).
@export var cooldown: float = 0.0
## Mana at skill level 1 (actives only).
@export var mana_cost: float = 0.0
## > 0: only cast while the caster's HP ratio is below this.
@export_range(0.0, 1.0) var trigger_hp_below: float = 0.0
## Pixels. 0 = the caster's attack range.
@export var cast_range: float = 0.0

@export_group("Damage")
@export var target: Target = Target.ENEMY
## Area radius in pixels (area targets and ally searches).
@export var radius: float = 0.0
@export var hits: int = 1
## Attack-speed skills: one extra hit per 0.25 attack speed above 1.0, up to this many hits.
@export var max_hits: int = 0
## Damage per hit = (attack_ratio × attack + stat_ratio × scale stat) × power.
@export var attack_ratio: float = 0.0
@export var stat_ratio: float = 0.0
## True: damage × (scale stat / the class's base value of it), e.g. move speed 96 / 80.
@export var stat_multiplier: bool = false
@export var bonus_crit: float = 0.0
@export var bonus_crit_damage: float = 0.0
@export var ignore_dodge: bool = false
## Target HP ratio below this: damage × execute_multiplier (bosses: GameConfig threshold).
@export_range(0.0, 1.0) var execute_threshold: float = 0.0
@export var execute_multiplier: float = 1.0
## Extra damage against enemies with this tag (e.g. undead).
@export var tag_bonus: StringName
@export var tag_bonus_ratio: float = 0.0
## Extra attack ratio per stack of this effect on the target; optionally removes the stacks.
@export var stack_effect: StringName
@export var ratio_per_stack: float = 0.0
@export var consume_stacks: bool = false
## Killing a non-boss target with it resets the cooldown.
@export var reset_on_kill: bool = false

@export_group("Support")
## HP healed = heal_ratio × caster max HP × power (to the target group, or to the caster for
## damage skills).
@export var heal_ratio: float = 0.0
## Shield = shield_ratio × caster max HP × power.
@export var shield_ratio: float = 0.0
## Removes dispellable debuffs from the helped Hunters.
@export var cleanse: bool = false
## Enemies within `radius` attack the caster.
@export var taunt: bool = false
## Applied to every enemy hit. Hard crowd control turns into Stagger on bosses.
@export var target_effects: Array[StatusEffectChance] = []
@export var self_effects: Array[StatusEffectChance] = []
## Applied to the helped Hunters (ALLIES_AROUND / LOWEST_ALLY).
@export var ally_effects: Array[StatusEffectChance] = []

@export_group("Passive")
## Values × power.
@export var modifiers: Array[StatModifier] = []
## Values × power × (Hunter level / level_step, at most level_step_cap steps).
@export var level_modifiers: Array[StatModifier] = []
@export var level_step: int = 1
@export var level_step_cap: int = 100
## Chance to apply on every normal attack (chance × power, at most 100%).
@export var on_hit_effects: Array[StatusEffectChance] = []
## Heals this share of max HP × power on every kill.
@export var kill_heal_ratio: float = 0.0


func is_active() -> bool:
	return kind == Kind.ACTIVE


## True when the skill does something on its own in combat (actives, triggered passives).
func is_castable() -> bool:
	return cooldown > 0.0


func deals_damage() -> bool:
	return attack_ratio > 0.0 or stat_ratio > 0.0


func targets_enemies() -> bool:
	return target in [Target.ENEMY, Target.ENEMIES_AROUND_SELF, Target.ENEMIES_AROUND_TARGET]
