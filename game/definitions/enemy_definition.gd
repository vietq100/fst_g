class_name EnemyDefinition
extends GameDefinition
## Enemy or boss stats (ENEMY_DESIGN.md, BALANCE.md).

@export var is_boss: bool = false

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

@export_group("Character")
## Active skills (D55), used when off cooldown instead of a plain attack (two per monster).
@export var skill_ids: Array[StringName] = []
## Weapon and armor items (data/items) the monster fights with: their stat modifiers apply, the
## weapon is shown in its hand, and either may drop (`gear_drop_chance`) into the killer's bag.
@export var weapon_id: StringName
@export var armor_id: StringName
@export_range(0.0, 1.0) var gear_drop_chance: float = 0.0

@export_group("Rewards")
@export var xp_reward: int = 0
## Coins the monster carries, taken by the killer (scaled by region level and difficulty).
@export var gold_min: int = 0
@export var gold_max: int = 0
@export var loot_table_id: StringName

@export_group("Visuals")
## Scene with an Enemy root (components + visual) spawned for this definition.
@export var actor_scene: PackedScene
@export var sprite_frames: SpriteFrames
