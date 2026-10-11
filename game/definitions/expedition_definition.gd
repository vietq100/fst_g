class_name ExpeditionDefinition
extends GameDefinition
## Expedition destination (EXPEDITION_SYSTEM.md, BALANCE.md).

@export var recommended_level: int = 1
## In order from entrance to the section before the boss.
@export var enemy_groups: Array[EnemyGroup] = []
@export var boss_id: StringName
@export var completion_bonus_gold: int = 0
@export var first_clear_loot_table_id: StringName
@export var repeat_clear_loot_table_id: StringName
## Progress flags set on the first clear, e.g. &"first_boss_clear".
@export var first_clear_flags: Array[StringName] = []
## Progress flag required to start. Empty means always available.
@export var unlock_flag: StringName
@export var scene: PackedScene

@export_group("Dungeon entrance (D35)")
## Region whose edge holds the entrance.
@export var region_id: StringName
## Tile just outside the region edge where the entrance stands.
@export var entrance_tile: Vector2i
## Shown in the world but not enterable yet (content comes later).
@export var locked: bool = false
