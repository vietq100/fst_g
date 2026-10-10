# PHASE 1 — Character — ✅ DONE (2026-10-10)

## Read first
- `DOCS/00_RULES.md`
- `DOCS/DESIGN/CHARACTER_DESIGN.md`, `ART_DIRECTION.md`
- `DOCS/SYSTEMS/CHARACTER_SYSTEM.md`
- `DOCS/ARCHITECTURE/ARCHITECTURE.md`, `DATA_SPEC.md`

## Goal
A Warrior Hunter that exists as runtime data and as a placeholder actor with stats and HP.

## Tasks
- [x] `HunterDefinition` resource for Warrior (data only) — done in Phase 0
- [x] `HunterRuntime` with all fields from `CHARACTER_SYSTEM.md` (later-phase fields stubbed)
- [x] Hunter actor composition: `Visual`, `NavigationAgent2D`, `HealthController`, `CombatController` (stub), `StateController`
- [x] Placeholder visual (shapes; steel body, accent colour from runtime, 4-direction facing, selection ring, downed pose)
- [x] Movement: tap-to-move via touch events with navigation (paths around obstacles)
- [x] Stats from definition + level + recruit rolls via `HunterService` → `StatService`
- [x] `HealthController` with `health_changed` / `damaged` / `healed` / `died` signals
- [x] Debug panel: Spawn, Hit 25, Heal 25, Lv +1, selected Hunter info

## Acceptance criteria
- [x] Hunter spawns from definition and moves
- [x] Damage via debug button changes HP and emits signals
- [x] Stats come from data, not hard-coded
- [x] Placeholder can be swapped for final art without touching logic (visual is one child node)
- [x] Tests cover stats and health

## Completion report

### Implemented
- `game/runtime/hunter_runtime.gd` — persistent Hunter state (ids + plain values)
- `game/services/hunter_service.gd` — roster, `create_hunter` (unique id, name, accent, ±variance rolls, start mood), `get_stat`, `set_level`; signals `hunter_added`, `hunter_changed`
- `actors/common/` — `HealthController`, `StateController` (IDLE/MOVING/ATTACKING/DOWNED, downed is sticky), `CombatController` stub, `Facing`, `PlaceholderVisual`
- `actors/hunter/hunter.tscn` + `hunter.gd` — wires components, syncs HP to runtime, navigation movement, downed on death
- `world/test_arena/` — temporary sandbox with runtime-baked navigation and a rock obstacle; tap to select/move
- `DebugPanel.add_button_row`; `GameConfig.mood_start`
- `GameManager` now owns `rng` and `hunters`

### Validation
- Unit tests: 30 passed (13 new: HunterService, HealthController, StateController, Facing)
- Scripted end-to-end run: spawn → tap target behind rock → Hunter paths around the rock (never enters it) and stops at target facing UP → damage syncs to `runtime.current_hp` → level 3 raises max HP/ATK → 0 HP sets DOWNED, later taps ignored
- Rendered frames checked: movement around rock, back view while walking up, downed pose
- Main scene runs with no errors/warnings
- Bug found and fixed: info label did not refresh on state change (showed IDLE while downed)

### Known limitations
- Placeholder art only; no animation frames yet.
- Level-up does not restore HP yet (Progression, later phase).
- Tap-to-move is a debug interaction; in the game Hunters are moved by AI.
- Recruit cost, real names and traits come in Phases 6 and 8.
- One windowed scripted run did not move the Hunter because the test injected the tap at the wrong coordinates; the corrected run passed. Real taps use the engine's own coordinate conversion.

### Next step
Phase 2 — Enemy (Slime, target detection, enemy movement).
