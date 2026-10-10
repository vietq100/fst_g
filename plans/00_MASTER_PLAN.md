# MASTER PLAN — Dark Hunter Tycoon MVP

Source of truth: `DOCS/`. Phase order follows `DOCS/ROADMAP/ROADMAP.md` (Phase 0–11).
Each phase has its own file in this folder, written with the `DOCS/ROADMAP/AGENT_TASK_TEMPLATE.md` structure.

## Goal

Playable vertical slice:

Town → recruit Hunter (with traits) → expedition → auto combat → loot → return → rest/train/socialize (mood, bond) → upgrade → save/load

No endgame. Bosses and regions are milestones, not endings.

## Phases

| # | Phase | File | Result |
|---|---|---|---|
| 0 | Foundation | `PHASE_00_FOUNDATION.md` | Project skeleton, autoloads, data registry |
| 1 | Character | `PHASE_01_CHARACTER.md` | Warrior with stats/HP, placeholder visuals |
| 2 | Enemy | `PHASE_02_ENEMY.md` | Slime, targeting, movement |
| 3 | Combat | `PHASE_03_COMBAT.md` | Auto combat, damage, death, feedback |
| 4 | Expedition | `PHASE_04_EXPEDITION.md` | Dark Forest run, boss, completion, return |
| 5 | Loot | `PHASE_05_LOOT.md` | Loot tables, gold, materials, inventory |
| 6 | Town | `PHASE_06_TOWN.md` | Town scene, buildings, upgrades |
| 7 | Equipment | `PHASE_07_EQUIPMENT.md` | Weapon/armor, stat modifiers |
| 8 | Hunter Life | `PHASE_08_HUNTER_LIFE.md` | Traits, mood, activities, bonds, history |
| 9 | Save | `PHASE_09_SAVE.md` | Versioned save/load, autosave, migration |
| 10 | UI | `PHASE_10_UI.md` | HUD and panels |
| 11 | Polish | `PHASE_11_POLISH.md` | Art, VFX, audio, balance |

## Decisions and numbers

All previously open questions and doc conflicts are resolved in:
- `DOCS/DECISIONS.md` — D1–D22 (expedition mode, party, defeat, currencies, town layout, Warehouse, level cap, mood, activities, modifiers, display, save, tooling)
- `DOCS/BALANCE.md` — first-pass numbers for all MVP content

If a new conflict appears: report it, do not silently pick one (`00_RULES.md` §1).

## Per-task workflow (from `00_RULES.md`)

1. Read relevant docs
2. Inspect existing project
3. Identify dependencies
4. Implement the smallest complete slice
5. Run/validate
6. Fix errors
7. Update docs if design/architecture changed
8. Report: implemented, files changed, validation, known limitations, next step

## Global constraints

- Typed GDScript, small focused scripts
- Static definitions as Resources, runtime state separate, UI never owns state
- Signals for decoupling; no fragile deep node paths
- No plugins unless requested
- Never claim success without running/validating
- Save IDs and data, never live Nodes

## Milestones

- **M1 – Combat sandbox:** end of Phase 3
- **M2 – Expedition loop:** end of Phase 5 (expedition + loot)
- **M3 – Management loop:** end of Phase 8 (town + equipment + Hunter life)
- **M4 – Vertical slice:** end of Phase 10 (save + UI)
- **M5 – MVP polished:** end of Phase 11
