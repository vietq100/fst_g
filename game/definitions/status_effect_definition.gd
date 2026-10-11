class_name StatusEffectDefinition
extends GameDefinition
## A timed buff or debuff on an actor (COMBAT_SYSTEM.md → Status effects, DECISIONS.md D48).
## One definition can combine several behaviours: damage/heal over time, crowd control,
## stat modifiers, a damage shield, thorns and lifesteal. All values are per stack.

enum Kind { BUFF, DEBUFF }
## What applying an effect the actor already has does.
enum Stacking {
	REFRESH, ## Reset the duration (and shield); stacks stay 1.
	STACK, ## Add stacks up to `max_stacks` and reset the duration.
	IGNORE, ## Keep the running effect untouched.
}
## Procedural aura drawn by StatusEffectView.
enum Aura { NONE, BUBBLES, FLAMES, DROPS, SPARKLES, STARS, ICE, ROOTS, ARROWS_UP, ARROWS_DOWN, SHIELD, GLOW, SPIKES, DRAIN, CROSS }

@export var kind: Kind = Kind.DEBUFF
## Seconds. 0 or less = lasts until removed (or until its shield breaks).
@export var duration: float = 5.0
@export var stacking: Stacking = Stacking.REFRESH
@export var max_stacks: int = 1
## Cleanse / dispel may remove it.
@export var dispellable: bool = true

@export_group("Over time")
## Seconds between ticks. The first tick happens one interval after applying.
@export var tick_interval: float = 1.0
@export var damage_per_tick: float = 0.0
@export var heal_per_tick: float = 0.0
## True: damage/heal per tick are fractions of the target's max HP (0.02 = 2%).
@export var tick_is_ratio: bool = false

@export_group("Control")
## No moving and no attacking.
@export var stuns: bool = false
## No moving; attacking in range still works.
@export var roots: bool = false
## No attacking; moving still works.
@export var disarms: bool = false
## Takes no damage at all.
@export var invulnerable: bool = false

@export_group("Stats")
## Applied on top of the final combat stats: (value + Σflat) × (1 + Σpercent).
## Stats: attack, defense, attack_speed, move_speed, critical_chance, critical_damage,
## damage_dealt, damage_taken (HunterService stat ids). The condition field is ignored.
@export var modifiers: Array[StatModifier] = []

@export_group("Combat")
## Damage absorbed before HP. The effect ends when the shield is used up.
@export var shield: float = 0.0
## Fraction of melee/ranged damage taken that is reflected to the attacker.
@export var thorns: float = 0.0
## Fraction of attack damage dealt that heals the owner.
@export var lifesteal: float = 0.0

@export_group("Visuals")
@export var color: Color = Color.WHITE
## One or two characters shown in the icon above the actor.
@export var icon: String = "?"
@export var aura: Aura = Aura.NONE
## Tints the actor's body with `color` (pulsing) while active.
@export var tints_actor: bool = false


func blocks_movement() -> bool:
	return stuns or roots


func blocks_attack() -> bool:
	return stuns or disarms
