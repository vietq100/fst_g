# WORLD DESIGN

## World structure (D52, formerly D27)

One continuous top-down world (32 px square tiles, buildings drawn front-facing) in the style of
Evil Hunter Tycoon. The screen (portrait) is a window onto it: drag, zoom, follow.

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
- Bridges (plank decks with railings and lanterns) connect Town–Forest, Town–Ruins, Forest–Cave, Ruins–Cave. Every region is a plateau over dark water with a cliff face below its bottom edge; dungeon entrances stand on rock ledges off the outer edges.
- Look (D57): noise-patched ground per biome, shallows and foam around the plateaus, dirt roads with ruts and footpaths to every door in the Town, a cobbled plaza with a mosaic, lamp posts, benches and planters; trails through the hunting regions, each with its own ground detail (forest litter and ferns, cave gravel and crystals, broken ruin paving).

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
