# BUILD SYSTEM (placement, move, remove)

The Town is built and arranged by the player (D32, D33). Costs and footprints: `BALANCE.md` → Building placement.

## Grid

- Town tiles: gx 0–35, gy 0–35 (top-down, 32 × 32 px squares, D52). A building occupies a rectangle of tiles (its footprint) anchored at its top-left tile; its door is the tile below the middle of its bottom edge.
- A placement is valid when every footprint tile is inside the Town, not occupied by another building and not on a reserved tile (gate approaches).

## Build mode (UI)

1. Bottom nav **Build** → list of buildings with cost; unique buildings that already exist are shown as built.
2. Choose one → placement mode: a footprint preview follows the finger, green when valid, red when not; drag the camera with a second gesture or move the preview by tapping a tile.
3. **Place** confirms (cost paid from the treasury); **Cancel** leaves.

Moving: building panel → **Move** → same placement mode, free.
Removing: building panel → **Remove** → confirm; 50% of the build cost refunded; not allowed for the Town Hall. Removing a House unassigns its beds.

## Rules

- Core buildings are unique: Town Hall, Tavern, Blacksmith, Hospital, Warehouse. Houses: unlimited.
- Building levels and upgrades are per instance (BuildingService). Effects that need one building (Tavern candidates, Hospital time, Warehouse slots, Blacksmith recipes, Town Hall capacity) read that building; if it is missing, the effect is missing (e.g. no Tavern → no meals, no recruits).
- Houses: 4 beds each; beds are assigned to Hunters automatically.
- After any change: navigation is rebaked; Hunters re-plan their paths.

## Data

`BuildingDefinition` gains: `build_cost`, `footprint` (tiles), `unique`, `beds`. Placed buildings are runtime instances `{instance_id, building_id, tile, level}` saved in schema 2 (D37).

- Doors: the tile in front of a building's door (front-right face) must be free and inside the Town; no building may cover another building's door (Hunters deliver loot and bodies there).
