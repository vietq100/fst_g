# PHASE 3 — Combat

## Read first
- `DOCS/00_RULES.md`
- `DOCS/SYSTEMS/COMBAT_SYSTEM.md`, `AI_SYSTEM.md`
- `DOCS/DESIGN/VFX_DESIGN.md`

## Goal
Hunter and Slime fight automatically until one dies.

## Tasks
- [ ] `CombatSystem` owns target validity, attack timing, damage, death resolution
- [ ] Centralized damage formula: `max(1, attack - defense * 0.5)`; critical multiplier
- [ ] Attack cooldown from `attack_speed`
- [ ] Flow: target → move → enter range → cooldown → damage → react → death → next target
- [ ] Signals: `damage_dealt`, `enemy_died`, `hunter_died`, `combat_finished`
- [ ] Feedback: hit flash, floating damage number, death effect (simple)
- [ ] Debug panel: start fight, show combat log

## Technical requirements
- UI/VFX subscribe to signals; combat never depends on UI
- Formulas live in one place
- Balance values from data

## Acceptance criteria
- [ ] Fight resolves with correct damage and death
- [ ] Critical hits work and are visible
- [ ] Multiple enemies handled with retargeting
- [ ] No runtime errors; existing phases still work
- [ ] Tests cover formula, crit, death, retarget

## Milestone
**M1 – Combat sandbox**

## Completion report
Implemented / Files changed / Validation / Known limitations / Next step (Phase 4)
