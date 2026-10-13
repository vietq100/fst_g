class_name RegionDefinition
extends GameDefinition
## A square region of the top-down world (WORLD_DESIGN.md, DECISIONS.md D52, D29).
## The Town is a region too (`is_town`, no monsters).

enum Props { NONE, TREES, ROCKS, COLUMNS }

## Tiles covered (gx, gy, width, height).
@export var tile_rect: Rect2i
@export var is_town: bool = false

@export_group("Hunting")
## Auto duty sends Hunters of at least this level here (the hardest such region wins).
@export var min_hunter_level: int = 1
@export var monster_ids: Array[StringName] = []
@export var monster_level_min: int = 1
@export var monster_level_max: int = 1
@export var population_cap: int = 0
@export var respawn_seconds: float = 15.0

@export_group("Look")
@export var ground_color: Color = Color("4f7a46")
@export var ground_alt_color: Color = Color("547f4a")
@export var props: Props = Props.NONE
## Share of free tiles that get a prop.
@export_range(0.0, 1.0) var prop_density: float = 0.0
