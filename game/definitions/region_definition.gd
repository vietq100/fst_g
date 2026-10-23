class_name RegionDefinition
extends GameDefinition
## A region of the isometric world (WORLD_DESIGN.md, DECISIONS.md D55, D29, D58).
## The Town is a region too (`is_town`, no monsters); the Hunter Gate island and the Boss Arena
## are small regions of their own `kind`.

enum Props { NONE, TREES, ROCKS, COLUMNS }
## HUNTING: monsters, a duty choice, Auto duty may pick it. TOWN: see `is_town`. GATE: the
## Hunter Gate island (no monsters, no duty). BOSS: the weekly boss arena (a duty choice, never
## picked by Auto). MOUNT: the Hibernation Mount (D83), where sleeping Hunters wait; no monsters,
## no duty.
enum Kind { HUNTING, TOWN, GATE, BOSS, MOUNT }
## Outline of the region inside `tile_rect`. ROUNDED: the rectangle with rounded corners (Town,
## gate island, arena). WINDING: a meandering woodland of overlapping glades. LOBED: an irregular
## blob with peninsulas and bays. CROSS: a plus-shaped plaza with a court at each corner.
enum Shape { ROUNDED, WINDING, LOBED, CROSS }

## Tiles covered (gx, gy, width, height).
@export var tile_rect: Rect2i
@export var is_town: bool = false
@export var kind: Kind = Kind.HUNTING
@export var shape: Shape = Shape.ROUNDED

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


## A regular hunting ground (not the Town, the gate island or the arena).
func is_hunting() -> bool:
	return not is_town and kind == Kind.HUNTING
