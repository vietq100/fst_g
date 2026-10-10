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
- InventoryService
- BuildingService
- ActivityService
- BondService
- StatService (single place for the stat pipeline and formulas)

## Display

Base viewport 640×360, window 1280×720, stretch mode `viewport`, integer scaling, nearest filtering.

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
