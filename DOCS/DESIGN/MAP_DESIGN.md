# MAP DESIGN

## 1. Map goals

Maps are gameplay spaces, not only backgrounds.

Every map should communicate:
- where Hunters can go
- where enemies appear
- where objectives are
- where the exit is

## 2. Tile size

Target:
32x32 px environment tiles.

## 3. Town layout

Canonical layout is defined in `TOWN_DESIGN.md` §3 (North Road closed in MVP, South Gate = expedition exit, Training Yard beside Town Hall).

Town should have:
- central readable landmark
- short walking distances
- clear building silhouettes
- open paths

## 4. Dark Forest layout

Structure:

Entrance
→ clearing
→ enemy area
→ deeper forest (stronger group)
→ boss arena
→ return/exit

Enemy groups per section: `BALANCE.md` → Dark Forest.

Portrait: the forest runs bottom (entrance) → top (boss arena); the camera follows the party vertically.

Implemented map (`world/expedition/dark_forest.tscn`): 360 × 1440 px. Trail from the entrance (y ≈ 1400) through four section rally points (y ≈ 1290, 1070, 840, 630) to the boss clearing (centre y ≈ 330, radius 120, stone circle) and the exit gate (y ≈ 120). Trees line both edges and fill the space away from the trail; they are navigation obstacles (group `navigation_obstacles`, baked at runtime).

Avoid excessive maze complexity.

## 5. Navigation

Use Godot navigation where appropriate.

Characters must not become stuck on decorative obstacles.

## 6. Spawn design

Each expedition defines:
- Hunter spawn
- enemy spawn points
- boss spawn
- loot positions if applicable
- return point

## 7. Camera

Camera should:
- follow active gameplay
- in town, allow drag-to-pan within bounds
- stay within map boundaries
- avoid exposing unfinished areas

## 8. Map transitions

Transitions should be obvious.

Use:
- gates
- roads
- portals
- entrances

Do not move Hunters between scenes with no visual explanation. MVP: Hunters walk out of the South Gate, then the scene changes with a fade.
