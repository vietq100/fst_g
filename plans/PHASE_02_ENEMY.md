# PHASE 2 — Enemy

## Read first
- `DOCS/00_RULES.md`
- `DOCS/DESIGN/ENEMY_DESIGN.md`
- `DOCS/SYSTEMS/AI_SYSTEM.md`
- `DOCS/ARCHITECTURE/DATA_SPEC.md`

## Goal
Slime exists, finds the nearest Hunter and moves toward it.

## Tasks
- [ ] `EnemyDefinition` for Slime (slow, weak, common)
- [ ] Enemy actor with same composition style as Hunter (health, state, combat stub)
- [ ] Target detection: nearest valid Hunter, timer/event-driven retargeting (not every frame)
- [ ] Enemy movement with navigation
- [ ] Placeholder visual (round blob, distinct silhouette from Hunter)
- [ ] Debug panel: spawn Slime

## Technical requirements
- Shared health/target components reused with Hunter where possible
- Enemy AI per `AI_SYSTEM.md`: find nearest Hunter → approach → (attack in Phase 3) → retarget when invalid

## Acceptance criteria
- [ ] Slime chases nearest Hunter and stops in range
- [ ] Retargets when target dies/leaves
- [ ] No per-frame expensive searches
- [ ] Hunter and enemy silhouettes distinguishable at gameplay zoom
- [ ] Tests cover target selection

## Completion report
Implemented / Files changed / Validation / Known limitations / Next step (Phase 3)
