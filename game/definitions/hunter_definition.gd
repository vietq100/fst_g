class_name HunterDefinition
extends GameDefinition
## Hunter class template (e.g. Warrior). Individual identity lives in HunterRuntime.

@export var class_id: StringName

@export_group("Base stats")
@export var base_hp: float = 0.0
@export var base_attack: float = 0.0
@export var base_defense: float = 0.0

@export_group("Growth per level")
@export var hp_per_level: float = 0.0
@export var attack_per_level: float = 0.0
@export var defense_per_level: float = 0.0

@export_group("Combat")
## Attacks per second. Cooldown = 1 / attack_speed.
@export var attack_speed: float = 1.0
## Pixels per second.
@export var move_speed: float = 0.0
@export_range(0.0, 1.0) var critical_chance: float = 0.0
@export var critical_damage: float = 1.0
## Max distance (feet to feet, px) at which it can attack.
@export var attack_range: float = 0.0

@export_group("Recruitment")
@export var recruit_cost: int = 0
## Random roll applied to HP/Attack/Defense of each recruit, e.g. 0.1 = ±10%.
@export_range(0.0, 1.0) var stat_roll_variance: float = 0.0
## Names given to recruits of this class (unused ones first).
@export var name_pool: PackedStringArray = []
## Items created and equipped on every new recruit (Phase 7).
@export var starting_items: Array[StringName] = []

@export_group("Visuals")
@export var portrait: Texture2D
@export var sprite_frames: SpriteFrames
