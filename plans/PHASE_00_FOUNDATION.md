# PHASE 0 — Foundation — ✅ DONE (2026-10-10)

## Read first
- `DOCS/00_RULES.md`
- `DOCS/ARCHITECTURE/ARCHITECTURE.md`
- `DOCS/ARCHITECTURE/DATA_SPEC.md`

## Goal
Empty but well-structured Godot project that boots to a Main scene with core services available.

## Tasks
- [x] Create folders: `core, game, actors, buildings, world, ui, data, save, tests, scenes, assets`
- [x] `Main` scene: `GameRoot`, `WorldContainer`, `UI`
- [x] Autoloads: `DataRegistry`, `GameManager`, `SaveManager` (stub); EventBus not needed yet
- [x] Base Resource classes per `DATA_SPEC.md` (Hunter, Trait, Activity, Enemy, LootTable, Item, Recipe, Building, Expedition) + `GameConfig`, helpers
- [x] `StatModifier` format and `StatService` (D18, D19)
- [x] `DataRegistry`: load definitions by ID, validate missing id / duplicate / wrong type
- [x] `project.godot`: 640×360 base viewport, 1280×720 window, stretch `viewport`, integer scaling, nearest filter (D20)
- [x] Test runner `tests/run_tests.gd` (headless) (D22)
- [x] Debug panel shell in `ui/debug/` (D22)

## Acceptance criteria
- [x] Project runs with no errors/warnings
- [x] Main scene loads; autoloads reachable
- [x] `DataRegistry` loads a sample definition and rejects an unknown ID cleanly
- [x] Tests in `tests/` cover registry lookup and validation
- [x] Docs updated (`DATA_SPEC.md`, `ARCHITECTURE.md`)

## Completion report

### Implemented
- Folder structure, main scene, three autoloads
- 17 definition/helper Resource classes in `game/definitions/`
- `DataRegistry` (9 categories, validation, typed getters, `find_def` silent / `get_def` reporting)
- `GameConfig` data + `StatService` (stat pipeline, damage, crit, cooldown, XP, level cap)
- Sample data: `data/hunters/warrior.tres`, `data/config/game_config.tres`
- Test runner + `TestCase` base; 17 tests
- Debug panel (F1 toggle, removed in release builds)
- Renderer switched from Mobile to GL Compatibility (2D desktop-first)

### Validation
- `godot --headless --path . --import`: no errors
- `godot --headless --path . -s res://tests/run_tests.gd`: 17 passed, exit 0; a deliberately failing test gives exit 1
- `godot --headless --path . --quit-after 60`: no errors/warnings
- Rendered frame checked at 640×360: debug panel shows "Definitions loaded: 1"

### Known limitations
- A GDScript runtime error inside a test aborts that test but is not counted as a failure by the runner (Godot has no exceptions); check the log for script errors.
- `tests/` should be excluded from export presets when exports are set up.
- `HunterRuntime`, services beyond `StatService` come in later phases.

### Follow-up (mobile switch, 2026-10-10)
- Display switched to portrait 360×640, aspect `expand`, desktop test window 540×960, handheld orientation portrait
- Mouse emulates touch; debug panel collapsible by tap
- `GameConfig.offline_cap_hours` added

### Next step
Phase 1 — Character.
