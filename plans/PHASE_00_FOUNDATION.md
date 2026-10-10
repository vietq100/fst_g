# PHASE 0 — Foundation

## Read first
- `DOCS/00_RULES.md`
- `DOCS/ARCHITECTURE/ARCHITECTURE.md`
- `DOCS/ARCHITECTURE/DATA_SPEC.md`

## Goal
Empty but well-structured Godot project that boots to a Main scene with core services available.

## Tasks
- [ ] Create folders: `core, game, actors, buildings, world, ui, data, save, tests, scenes, assets`
- [ ] `Main` scene: `GameRoot`, `WorldContainer`, `UI`
- [ ] Autoloads: `GameManager`, `SaveManager` (stub), `DataRegistry`; optional `EventBus`
- [ ] Base Resource classes per `DATA_SPEC.md` (Hunter, Trait, Activity, Enemy, LootTable, Item, Recipe, Building, Expedition) — fields can be filled as phases need them
- [ ] `Modifier` format and `StatService` skeleton (`DECISIONS.md` D18)
- [ ] `DataRegistry`: load definitions by ID, validate missing/duplicate IDs
- [ ] `project.godot`: 640×360 base viewport, 1280×720 window, stretch `viewport`, integer scaling, nearest filter (D20)
- [ ] Test runner `tests/run_tests.gd` (headless) (D22)
- [ ] Debug panel shell in `ui/debug/` (D22)

## Technical requirements
- Keep autoloads minimal
- Typed GDScript
- Registry returns definitions by ID, never Nodes

## Acceptance criteria
- [ ] Project runs with no errors/warnings
- [ ] Main scene loads; autoloads reachable
- [ ] `DataRegistry` loads a sample definition and rejects an unknown ID cleanly
- [ ] Test script in `tests/` covers registry lookup
- [ ] Docs updated if structure deviates

## Completion report
Implemented / Files changed / Validation / Known limitations / Next step (Phase 1)
