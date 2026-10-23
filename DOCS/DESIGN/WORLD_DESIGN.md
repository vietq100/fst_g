# WORLD DESIGN

## World structure (D55, formerly D27 / D52)

One continuous 2:1 isometric world (44 × 22 px diamond tiles, D56) in the style of Evil Hunter
Tycoon. Buildings are isometric boxes with two visible walls (lit south-west face with the door,
shaded south-east face) and hip roofs with round emblems. The screen (portrait) is a window onto
it: drag, zoom, follow.

```
   ┌────────────┐ bridge ┌───────────────┐
   │    TOWN    │━━━━━━━━│ ANCIENT RUINS │ dungeon ×2
   └────────────┘        └───────────────┘
        ┃ bridge               ┃ bridge
   ┌────────────┐ bridge ┌───────────────┐
   │ DARK FOREST│━━━━━━━━│  GOBLIN CAVE  │ dungeon ×2
   └────────────┘        └───────────────┘
     dungeon ×2
```

- **Town** (top-left): safe, buildings placed by the player, Hunters live here. A stone retaining wall over the water, a parapet and a fence around it.
- **Dark Forest** (bottom-left): first hunting ground (Slimes, Wolves). Dungeon: Forest Guardian's Grove (MVP) + one locked.
- **Ancient Ruins** (top-right): late hunting ground (Skeletons, Goblins). Two locked dungeons.
- **Goblin Cave** (bottom-right): mid hunting ground (Goblins, Wolves). Two locked dungeons. Reached through the Forest or the Ruins.
- Bridges (plank decks with railings and lanterns) connect Town–Forest, Town–Ruins, Forest–Cave, Ruins–Cave, plus Town–Hunter Gate (north-west island where Hunters are hired and expelled) and Ruins–Boss Arena (north-east, the weekly boss; D58). Every region is a plateau with rounded corners (straight edges, D57) over dark water with cliff faces below its front edges; dungeon entrances stand on rock ledges off the outer edges.

The world is open-ended: new regions and dungeons can be added later. There is no final region.

## Environmental storytelling

The environment should visually explain:
- safety (warm Town) vs danger (darker regions)
- progression (Forest → Cave → Ruins)
- where gates and dungeon entrances are

## Biome identity

### Town
Warm grass, roads, the player's buildings.

### Dark Forest
Dense dark green, many trees.

### Goblin Cave
Rocky brown-grey ground, boulders.

### Ancient Ruins
Pale stone, broken columns, magical remnants.

## Traversal

- One navigation mesh for the whole world: region diamonds + gate corridors; buildings, trees, rocks and columns are obstacles.
- Clear gates and entrances; no mazes.

## Map redesign (2026-10-12, Evil Hunter Tycoon look)

- Every region and gate is a raised plateau with cliff faces and a grass lip; the void around them is a dark teal.
- Town: cobbled plaza around the Town Hall, dirt roads with kerbs (one to each gate plus a "main street" west and north), flowers and grass tufts, a pond in the north corner (blocks building and walking: `WorldService.get_town_pond`), a wooden fence and a tree line along the two back edges.
- Dark Forest: mossy patches and leaf litter; Goblin Cave: cracked rock; Ancient Ruins: pale paving with moss. Layout, gates and navigation are unchanged.

## Pixel-art ground (2026-10-15)

Each region's ground is a baked texture (`assets/ground/<region id>.png`, 1 texel = 1 world px (matches the Hunters' sprites)) painted by `GroundPainter` and drawn by `WorldGround` under the objects; regions without a matching texture fall back to flat tiles. One look per theme: Dark Forest — dark mud patches with dithered rims, moss, pebbles, branches and spiky leaf bushes; Goblin Cave — flagstones split by dark cracks with glowing lava veins; Ancient Ruins — pale paving with joints, cracks, broken slabs and moss; Town — grass patches with tufts, flowers and dirt; boss arena — obsidian slabs with violet veins; gate — pebbled path. Re-bake after changing a region's shape or the painter: `godot --headless --path . --script tools/bake_ground.gd`, then `--import`.

## Map polish (2026-10-15)

- **Water** is one baked image (`WaterPainter` → `assets/ground/water.png`): turquoise lagoon at the shore, shallow and deep bands towards the open sea, caustic streaks, foam at the cliff foot, lily pads, reeds, rocks and wave crests; the clear colour matches the deep water. Re-bake with the ground (`tools/bake_ground.gd`).
- **Region rims**: every ground texture gets a dark outline and a dithered shade on its outermost texels so each plateau reads as a solid piece. The cave is warmer with fewer lava veins.
- **Town decor** (`TownDecor`): lamp posts at the plaza corners, a fountain, well, statue, benches, flower beds, barrels, hay, signpost. No collision; hidden while a building stands on or next to them.
- **Vignette** (`Vignette`): soft dark corners over the map, under the HUD.
- **Shores**: ground textures reach `GroundPainter.PAD` px past the tiles with a noise-shaped, ragged outline (lips of grass / rock over the water) instead of straight diamond edges; the cliff faces are 40 px deep (`CLIFF_DEPTH`).

## Three larger, free-form hunting maps (2026-10-16)

Only the Town stays a 36×36 square. Dark Forest, Goblin Cave and Ancient Ruins are 64×64-tile areas (about 3× the old ground each) with their own outline (`RegionDefinition.Shape`, `WorldService._build_free_shape`):
- **Dark Forest** (WINDING): four overlapping glades along an S-shaped path, west/south-west of the Town.
- **Goblin Cave** (LOBED): a radial blob whose reach changes with the angle: peninsulas and bays.
- **Ancient Ruins** (CROSS): a plus-shaped plaza with a court at each corner, east of the Town; the boss arena sits north of it.
Every gate and dungeon entrance gets a 5-tile corridor to the region's centre (and the centre a disc) so bridges and ledges always connect; tiles not connected to the centre are dropped. Outline merging keeps pieces that only join in later rows. Dungeon entrances moved to the new outer edges; population caps raised to 30–32; the camera can zoom out to 0.14. Re-bake after changing a region (`tools/bake_ground.gd`, then `--import`).

## Bigger maps, close together (2026-10-16)

- The three hunting regions are 80×80 tiles. Neighbours stay **2 tiles apart (a narrow water channel)** and face each other with **straight, square coasts**: the side that looks at a neighbour is a band of ground `BORDER_BAND` (16) tiles deep along the whole shared border; only the outer coast is free-form (ragged) and the Town stays square.
- A long shared border gets **several bridges** across the channel: one per `BRIDGE_SPACING` (24) tiles of overlap, 1 to 3 (`WorldService._gates_between`). Town borders have one each, the 80-tile borders three.
- Ground textures are 1 texel = 2 world px and the water 4 (about 26 MB of textures in total). Dungeon entrances sit on the new outer edges.
- **Tidier map (2026-10-16)**: free shapes get gentler edge noise, a majority filter that removes single-tile spurs and nicks, and filled inner pockets (no lakes inside a region); the ragged lip over the water is 6 px (was 12); the water has far fewer rocks, wave marks, lily pads, reeds and blotches, and a cleaner foam line; the forest has fewer props.

- **Landmarks and water scenery (2026-10-16, D75)**: each hunting region has landmarks (Dark Forest shrine, stumps, logs; Goblin Cave camps of tents around a campfire, totems; Ancient Ruins obelisk, arches, statues) as navigation obstacles. The open water inside the camera bounds holds a lighthouse islet, a shipwreck, islets with trees or palms, sandbars, rocks, logs and kelp (`WorldScenery`, one small node per piece, nothing blocks). The ground is drawn by child nodes in strips so off-screen parts are culled.
- **Ambience (2026-10-16, D76)**: cloud shadows drift over everything, gulls circle the islets, a rowing boat rocks by a palm islet, the lighthouse beacon pulses and sweeps (`WorldAmbience`, a sky layer above the entities). Monster skills show pixel effects in their element (`SkillEffect`).
- **Day and night (2026-10-16, D77)**: the world is tinted by the hour of the in-game day (white day, warm dusk and dawn, blue night); at night lamps, camp fires, the shrine, the obelisk and the lighthouse glow (`DayNight`). The Temple staff are robed, hooded Forge acolytes.

## Hibernation Mount (D83)

A small rocky island of its own kind below and left of the Hunter Gate island, joined to it by a bridge: a snow-capped hill with a cave mouth at its centre. Hunters sent to sleep walk over the bridge and settle on the hill; woken ones walk back. No monsters, no duty, no buildings.
