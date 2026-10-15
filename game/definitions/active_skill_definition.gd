class_name ActiveSkillDefinition
extends GameDefinition
## An active combat skill (D55) used by Hunters (30 per class, unlocked by level, two equipped)
## and monsters (two each). Fired instead of a plain attack when off cooldown: a damage multiplier
## on the target and, for area skills, on nearby enemies; status effects on them and / or on the
## user; a self heal. Presentation is picked by `animation` (ChibiAnimations one-shot) and `vfx`
## (SkillVfx kind). Numbers: BALANCE.md → Active skills.

@export_multiline var description: String
## Base class id (warrior / ranger / rogue / guardian) or &"monster".
@export var owner_class: StringName
## Hunter level that unlocks it (monsters ignore it).
@export var required_level: int = 1
## Seconds between uses; the first use is possible right away.
@export var cooldown: float = 8.0

@export_group("Damage")
## Multiplier of a normal attack on every target hit; 0 = no damage (buff / heal only).
@export var damage: float = 1.5
## Other enemies within this distance (px) of the target are hit too (0 = single target).
@export var radius: float = 0.0
@export var targets: int = 1

@export_group("Effects")
## Status effect (data/status_effects id) applied to every target hit.
@export var effect_id: StringName
@export var effect_stacks: int = 1
## Status effect applied to the user.
@export var self_effect_id: StringName
@export var self_effect_stacks: int = 1
## Share of the user's max HP healed.
@export_range(0.0, 1.0) var heal_ratio: float = 0.0

@export_group("Presentation")
## ChibiAnimations one-shot (skill_slam, skill_volley, skill_dash, skill_bash, skill_thrust,
## skill_spin, skill_cast, skill_leap). Monsters play a generic flourish.
@export var animation: StringName = &"skill_slam"
## SkillVfx kind: shockwave, arrows, shadow, bash, flame, frost, poison, holy, lightning, wind,
## blood, earth, heal.
@export var vfx: StringName = &"shockwave"
