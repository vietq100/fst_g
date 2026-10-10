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
