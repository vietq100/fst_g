class_name EnemyDefinition
extends GameDefinition
## Enemy or boss stats (ENEMY_DESIGN.md, BALANCE.md).

@export var is_boss: bool = false
## Kind tags for skills (D70): humanoid, beast, undead, slime. A Hunter gets the conditions
## `vs_<tag>` against it.
@export var tags: Array[StringName] = []
## Tier (D60). Bosses always have this tier; regular monsters roll one and keep at least this.
@export var tier: Tier.Level = Tier.Level.C

@export_group("Stats")
@export var hp: float = 0.0
@export var attack: float = 0.0
@export var defense: float = 0.0
@export var attack_speed: float = 1.0
@export var move_speed: float = 0.0
@export_range(0.0, 1.0) var critical_chance: float = 0.0
@export var critical_damage: float = 1.0
## Max distance (feet to feet, px) at which it can attack.
@export var attack_range: float = 0.0
## Extra body size beyond a standard actor; added to attackers' reach (big bosses).
@export var hit_radius: float = 0.0

## Status effects this enemy's hits may apply (D48), e.g. a venomous bite.
@export var on_hit_effects: Array[StatusEffectChance] = []

@export_group("Rewards")
@export var xp_reward: int = 0
@export var gold_min: int = 0
@export var gold_max: int = 0
@export var loot_table_id: StringName

@export_group("Visuals")
## Scene with an Enemy root (components + visual) spawned for this definition.
@export var actor_scene: PackedScene
@export var sprite_frames: SpriteFrames
