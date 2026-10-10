# GODOT ARCHITECTURE

## Folder structure

res://
├── core/
├── game/
├── actors/
├── buildings/
├── world/
├── ui/
├── data/
├── save/
├── tests/
├── scenes/
└── assets/

## Core services

Recommended Autoloads:
- GameManager
- SaveManager
- DataRegistry

Optional:
- EventBus

Keep Autoloads minimal.

## Scene structure

Main
├── GameRoot
├── WorldContainer
└── UI

Town
├── World
├── Buildings
├── Actors
└── Navigation

Expedition
├── World
├── Actors
├── Enemies
└── Navigation

## Actor composition

Hunter
├── Visual
├── NavigationAgent2D
├── HealthController
├── CombatController
└── StateController

Avoid giant Hunter.gd.

`Hunter` and `Enemy` extend `Actor` (shared movement, targeting access, downed handling). Visuals extend `ActorVisual` (facing, selected, downed) so art can be swapped.

## Physics layers

- Layer 1 `world`: static obstacles (rocks, walls, buildings)
- Layer 2 `actors`: Hunters and enemies

Actors are on layer 2 and collide only with layer 1, so actors never body-block each other. Spacing is handled by engagement slots and a light separation push (`COMBAT_SYSTEM.md`), not by RVO avoidance (it deadlocked crowds around one target in testing).

## Data

Use Resource classes for (fields in `DATA_SPEC.md`):
- HunterDefinition
- TraitDefinition
- ActivityDefinition
- EnemyDefinition
- LootTableDefinition
- ItemDefinition
- RecipeDefinition
- BuildingDefinition
- ExpeditionDefinition

Runtime state references IDs/definitions.

## Gameplay services

Plain classes or nodes owned by `GameManager` (not autoloads):
- HunterService (roster, recruitment, lifecycle)
- ExpeditionService
- CombatService (resolves attacks; emits `damage_dealt`, `actor_defeated`)
- WalletService (gold)
- ProgressService (progress flags, town level until the Town Hall exists)
- ExpeditionService (expedition rules and run state)
- InventoryService (stacks, equipment instances, slots, selling)
- LootService (loot table rolls)
- BuildingService (levels, upgrades, effects → inventory capacity, town level)
- RecruitmentService (Tavern candidates, recruiting)
- HospitalService (real-time recovery, speed-up)
- EquipmentService (equip/unequip/starting gear, equipment modifiers)
- CraftingService (Blacksmith recipes)
- TraitService, MoodService, BondService, ActivityService (Hunter life)

`HunterService.add_modifier_source(callable)` lets other systems contribute stat modifiers (equipment, traits, mood, bonds) to one stat pipeline. `GameManager._process` advances real-time town timers (`advance_town_time`), which is also the entry point for offline catch-up.
- InventoryService
- BuildingService
- ActivityService
- BondService
- StatService (single place for the stat pipeline and formulas; constructed with `GameConfig`)

## Code layout

- `core/` — autoload scripts (`data_registry.gd`, `game_manager.gd`, `save_manager.gd`)
- `game/definitions/` — Resource classes for static data
- `game/services/` — gameplay services
- `game/runtime/` — runtime state objects (`HunterRuntime`, …): ids and plain values, serializable
- `actors/common/` — reusable actor components (`HealthController`, `StateController`, `CombatController`, `Facing`, `PlaceholderVisual`)
- `actors/hunter/` — Hunter actor scene
- `world/town/` — the hub: `town.tscn` (layout D8), `Town` (selection, building panels, departure), `TownBuilding` + `BuildingVisual`, ground, drag camera
- `world/test_arena/` — combat sandbox, reachable from the Town debug panel (debug builds only)
- `world/vfx/` — world-space feedback (`CombatFeedback`, `DamageNumber`, `LevelUpBurst`, `LootPopup`)
- `save/` — `SaveCodec` (snapshot ↔ services, migrations); `core/save_manager.gd` handles files, autosave and offline catch-up
- `ui/ui_root.gd` — the game UI (top bar, nav, sheet host, toasts, expedition HUD); `ui/sheets/` — one class per panel (base `Sheet`: title, close, scroll, rebuild on watched signals); `ui/hud/` — expedition HUD; `ui/widgets/` — portrait; `ui/kit/` — `UIKit` builders
- `ui/theme/` — shared presentation helpers (`RarityColors`, `ItemText`); helpers take the DataRegistry as a parameter instead of using the autoload name
- `world/expedition/` — `ExpeditionScene` (generic run pacing), `dark_forest.tscn` + ground, expedition camera
- `world/props/` — props such as `tree.tscn` (navigation obstacle)
- `actors/enemies/<enemy>/` — one scene (+ visual) per enemy type

`Main` owns world switching (hub ↔ expedition) with a fade (`Transition` canvas layer) and the background pause. `WorldContainer` is pausable; `Main` itself always processes.
- `data/` — `.tres` content, one folder per category; `data/config/game_config.tres`
- `scenes/main.tscn` — main scene
- `ui/debug/` — debug panel
- `tests/` — `run_tests.gd`, `test_case.gd`, `unit/test_*.gd`, `fixtures/`

Renderer: GL Compatibility (2D, widest Android/iOS device support).

## Display

Portrait. Base viewport 360×640, aspect `expand`, stretch mode `viewport`, integer scaling, nearest filtering. Desktop test window 540×960. Mouse emulates touch.

## Mobile lifecycle

- Handle `NOTIFICATION_APPLICATION_PAUSED` / `NOTIFICATION_APPLICATION_FOCUS_OUT`: pause expedition, autosave.
- Handle `NOTIFICATION_APPLICATION_RESUMED`: apply offline town progress, resume.
- Input code uses touch/pointer events (`InputEventScreenTouch`, `InputEventScreenDrag`); never depend on hover or keyboard.

## Debug and tests

- Debug panel under `ui/debug/`, allowed from Phase 1, hidden in release builds.
- Tests: plain GDScript runner `tests/run_tests.gd`, run headless (`godot --headless -s tests/run_tests.gd`). No test plugins.

## Communication

Prefer signals.

Example:
CombatSystem
→ damage_dealt
→ enemy_died
→ combat_finished

UI subscribes and displays.

## Dependency direction

Gameplay systems must not depend on UI.

UI may depend on gameplay services/controllers.
