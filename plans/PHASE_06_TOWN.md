# PHASE 6 — Town — ✅ DONE (2026-10-11)

## Read first
- `DOCS/00_RULES.md`
- `DOCS/DESIGN/TOWN_DESIGN.md`, `BUILDING_DESIGN.md`, `MAP_DESIGN.md`
- `DOCS/SYSTEMS/PROGRESSION_SYSTEM.md`, `ECONOMY_SYSTEM.md`

## Goal
A visible town with working buildings and an upgrade path.

## Tasks
- [x] Town scene: World, Buildings, Actors, Navigation (canonical layout D8), 360 × 800 portrait
- [x] `BuildingDefinition` data + `BuildingService`: Town Hall, Tavern, Blacksmith, Hospital, Warehouse; Training Yard area
- [x] Town Hall: town level → Hunter level cap (×10), Hunter capacity; Lv2 requires first boss clear (D10, D12)
- [x] Tavern: 3 candidates (not in roster until recruited), refresh after each expedition return or for 30 gold; names from the class name pool; ±10% stats (D11)
- [x] Hospital: real-time recovery (120 s), speed-up 20 gold per started minute (works offline via `advance_town_time`, D24)
- [x] Warehouse: slot capacity (40 → 80)
- [x] Blacksmith: building + upgrade (recipes in Phase 7)
- [x] Building upgrade with visible change (stone foundation, taller walls, banner, "Lv2" label)
- [x] South Gate: party walks to the gate, then the expedition starts (no silent teleport)
- [x] Portrait map, drag-to-pan camera within bounds; tap a building/gate/Hunter to open its panel
- [x] New game (D25): 200 gold, 1 free Warrior, 3 candidates

## Acceptance criteria
- [x] Recruit costs gold and adds a Hunter
- [x] Upgrade consumes resources and changes visuals/effects
- [x] Injured Hunter recovers in Hospital
- [x] Hunter capacity enforced by Town Hall level
- [x] Tests cover recruit/upgrade/recovery rules

## Completion report

### Implemented
- Services: `BuildingService`, `RecruitmentService`, `HospitalService`; `HunterService` split into `generate_candidate` / `add_hunter`, name pool, modifier sources, multiplier stats (`damage_dealt`, `damage_taken`, `gold_find`, `xp_gain`) for Phase 7–8
- `GameManager`: new-game setup, `advance_town_time`, `request_world`
- Town scene (`world/town/`): `Town`, `TownBuilding`, `BuildingVisual` (5 building looks, Lv2 variant), ground (roads, plaza, Training Yard with dummies, closed North Road, South Gate, lamps), drag camera
- Building panels in the debug panel: upgrade (cost + reason), Tavern candidates/recruit/refresh, Hospital timers/speed-up, Warehouse contents/sell, Town Hall capacity/level cap, Gate party/depart; Hunter info
- Main: Town is the hub; the combat sandbox stays reachable for development; persistent status line on the debug panel
- Data: 5 buildings; Warrior name pool + starting items; `GameConfig` new-game values

### Validation
- Unit tests: 74 passed (new: building effects/levels, upgrade costs + flag requirement + failure leaves state unchanged, set_levels clamping, candidates vs roster, capacity, paid refresh, name pool without repeats, hospital timing and speed-up cost; buildings vs BALANCE)
- End-to-end through Main: new game (200 gold, 1 Hunter, 3 candidates) → recruit 2 (gold 0) → 4th refused "Roster full (3/3)" → depart: party walks to the gate, expedition starts → party wiped → back in town, 3 injured lying at the Hospital, candidates refreshed → +60 s: 57 s left, speed-up 20 gold → +121 s: all recovered and standing → Warehouse Lv2: capacity 80, visual level 2; Town Hall refused without first boss clear
- Rendered frames: town layout, Tavern panel, Hunters walking to the South Gate
- Main scene runs with no errors/warnings
- Bugs found and fixed: debug panel collapsing to one word per line (fixed width); untyped inference errors

### Known limitations
- Hunters idle around the plaza; walking to activity locations comes in Phase 8.
- Building panels are debug-panel stand-ins; real UI in Phase 10.
- Hunters spawned in the sandbox join the real roster (debug tool).
- Only one expedition (Dark Forest) is offered at the gate.

### Next step
Phase 7 — Equipment.
