# ROADMAP

Each phase uses the debug panel for validation until the real UI lands in Phase 10.
Detailed task plans live in `/plans`.

## Phase 0 — Foundation
- Godot project
- folder structure
- Main scene
- GameManager
- data registry
- display settings (640×360 base, integer scaling)
- test runner (`tests/run_tests.gd`)
- debug panel shell (`ui/debug/`)

## Phase 1 — Character
- Warrior Hunter
- movement
- animation placeholder
- stats
- health

## Phase 2 — Enemy
- Slime
- target detection
- enemy movement

## Phase 3 — Combat
- attack
- damage
- death
- feedback

## Phase 4 — Expedition
- Dark Forest
- enemy groups
- boss
- completion
- return

## Phase 5 — Loot
- loot table
- gold
- materials
- inventory

## Phase 6 — Town
- Town Hall
- Tavern
- Blacksmith
- Hospital
- Warehouse (capacity)
- Training Yard area
- building upgrade
- Town Hall Lv2 unlock by first boss clear

## Phase 7 — Equipment
- weapon
- armor
- stat modifiers (flat/percent)
- Blacksmith recipes

## Phase 8 — Hunter Life
See `SYSTEMS/HUNTER_LIFE_SYSTEM.md`.
- TraitDefinition + starter traits (data)
- trait modifiers applied to stats/AI
- mood (simple)
- town activities: rest, train, socialize
- bonds (one level)
- Hunter history record

## Phase 9 — Save
- schema (including traits, mood, activity, history, bonds)
- load
- autosave
- migration

## Phase 10 — UI
- HUD
- Hunter panel (traits, mood, bonds, history)
- Tavern
- expedition preparation
- inventory
- building panel
- activity assignment

## Phase 11 — World redesign (owner request, D27–D37) ✅ (W1–W7 done; review pending)
Plan: `plans/PHASE_11_WORLD.md`. Sub-phases, each playable and tested:
- W1 Isometric world map (4 regions, gates, dungeon entrances, navigation) + camera (drag, zoom, follow)
- W2 Buildings as placed instances + build / move / remove + Houses (beds)
- W3 Needs (stamina, energy), purses, Tavern meals, treasury transfers (10% fee), sleep in Houses
- W4 Region monsters + Hunter brains (autonomous hunting, loot bag, deposit)
- W5 Death, bodies, carriers, revival at the Hospital
- W6 Dungeons in the living world (Forest Guardian's Grove; others locked)
- W7 UI (build mode, Hunter needs/purse/duty/follow, dungeon panel) + save schema 2 + migration

## Phase 11b — Village economy (owner request, D38–D44)
Plan: `plans/PHASE_11B_VILLAGE.md`. The player is the village chief: Hunters sell materials to the village, the chief crafts food (Tavern) and medicine (Hospital) sold back to Hunters, the Temple revives at an XP cost, two staff carry bodies, steeper XP curve and weaker offline training.

## Phase 12 — Polish
- art
- animation
- VFX
- audio
- balancing
- performance
- bug fixing

Do not jump to polish while core loop is broken.

There is no "final" phase for content: after MVP, new regions, classes, traits and life events are added as expansions (see `01_PROJECT_OVERVIEW.md`).
