# PHASE 1 — Character

## Read first
- `DOCS/00_RULES.md`
- `DOCS/DESIGN/CHARACTER_DESIGN.md`, `ART_DIRECTION.md`
- `DOCS/SYSTEMS/CHARACTER_SYSTEM.md`
- `DOCS/ARCHITECTURE/ARCHITECTURE.md`, `DATA_SPEC.md`

## Goal
A Warrior Hunter that exists as runtime data and as a placeholder actor with stats and HP.

## Tasks
- [ ] `HunterDefinition` resource for Warrior (data only)
- [ ] `HunterRuntime` (unique_id, definition_id, level, xp, current_hp, equipment, trait_ids, mood, activity, history, state, expedition_id) — fields for later phases may be stubbed
- [ ] Hunter actor composition: `Visual`, `NavigationAgent2D`, `HealthController`, `CombatController` (stub), `StateController`
- [ ] Placeholder visual (coloured shape per class; steel/brown/red accent for Warrior)
- [ ] Movement (click/move-to or scripted) with 4-direction facing
- [ ] Stats calculation from definition + level (centralized)
- [ ] `HealthController` with `health_changed` / `died` signals
- [ ] Minimal debug panel: spawn Hunter, show HP/stats

## Technical requirements
- No giant `Hunter.gd`
- Runtime state references definition by ID
- UI (debug) reads state via signals

## Acceptance criteria
- [ ] Hunter spawns from definition and moves
- [ ] Damage via debug button changes HP and emits signals
- [ ] Stats come from data, not hard-coded
- [ ] Placeholder can be swapped for final art without touching logic
- [ ] Tests cover stats and health

## Completion report
Implemented / Files changed / Validation / Known limitations / Next step (Phase 2)
