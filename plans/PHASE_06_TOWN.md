# PHASE 6 — Town

## Read first
- `DOCS/00_RULES.md`
- `DOCS/DESIGN/TOWN_DESIGN.md`, `BUILDING_DESIGN.md`, `MAP_DESIGN.md`
- `DOCS/SYSTEMS/PROGRESSION_SYSTEM.md`, `ECONOMY_SYSTEM.md`

## Goal
A visible town with working buildings and an upgrade path.

## Tasks
- [ ] Town scene: World, Buildings, Actors, Navigation (canonical layout `TOWN_DESIGN.md` §3 / D8)
- [ ] `BuildingDefinition` + runtime state: Town Hall, Tavern, Blacksmith, Hospital, Warehouse; Training Yard area
- [ ] Town Hall: town level, Hunter capacity, Hunter level cap (×10), Lv2 unlocked by first boss clear (D10, D12)
- [ ] Tavern: 3 candidates, refresh on return or for gold; random name, accents, ±10% stats (traits wired in Phase 8) (D11)
- [ ] Hospital: timed recovery for injured Hunters; gold speed-up
- [ ] Warehouse: slot capacity, overflow auto-sell (D9)
- [ ] Blacksmith: entry point for equipment/upgrades (full use in Phase 7)
- [ ] Building upgrade with visible change (Level 1 + one upgrade visual)
- [ ] Gate/exit to expedition with clear transition

## Technical requirements
- Building effects come from data
- Services handle recruit/upgrade; UI requests only
- Decorations must not block navigation

## Acceptance criteria
- [ ] Recruit costs gold and adds a Hunter
- [ ] Upgrade consumes resources and changes visuals/effects
- [ ] Injured Hunter recovers in Hospital
- [ ] Hunter capacity enforced by Town Hall level
- [ ] Tests cover recruit/upgrade/recovery rules

## Completion report
Implemented / Files changed / Validation / Known limitations / Next step (Phase 7)
