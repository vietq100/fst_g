# TOWN DESIGN

## 1. Town purpose

Town is the player's home and management hub, and where Hunters live between expeditions.

It should feel:
- safe
- alive
- productive
- progressively larger

## 2. Visual hierarchy

Town Hall is the strongest landmark.

Secondary:
- Tavern
- Blacksmith
- Hospital
- Warehouse

## 3. Initial layout

Canonical layout (also used by `MAP_DESIGN.md`, see `DECISIONS.md` D8):

        [NORTH ROAD]   (closed in MVP, future regions)

 [TAVERN]        [BLACKSMITH]

    [TRAINING YARD] [TOWN HALL]

 [HOSPITAL]      [WAREHOUSE]

        [SOUTH GATE]   (expedition exit)

Training Yard is an open area next to Town Hall, not a building.

Implemented (`world/town/town.tscn`, 360 × 800 px, front-wall base positions): Tavern (90, 250), Blacksmith (272, 250), Training Yard (22–126, 330–430), Town Hall (248, 440), plaza (180, 530), Hospital (90, 650), Warehouse (272, 650), South Gate (180, 772). Drag to pan; tap a building, the gate or a Hunter to select it.

## 4. Building visual language

All buildings should share:
- same roof style (hip roof, ridge along the tile x axis, round emblem on the front slope)
- same perspective (2:1 isometric box: lit south-west face with the door, shaded south-east face, D55)
- same outline
- same material language (stone courses / wooden planks / plaster with timber frame)

Each building gets a unique visual marker.

## 5. Town life

Hunters not on an expedition are visible in town doing their activity:
- Tavern: resting, socializing
- Training Yard: training
- Hospital: recovering

## 6. Town evolution

Level 1:
- small settlement
- simple wooden structures

Level 2:
- larger buildings
- more decorations
- more NPC activity

Level 3:
- stone foundations
- stronger defenses
- busier streets

MVP only requires Level 1 and one upgrade visual change (Level 2).
Town levels have no final level; more can be added over time.

## 7. Decoration

Potential:
- barrels
- crates
- fences
- lamps
- trees
- signs
- carts

Decoration must never block navigation unexpectedly.
