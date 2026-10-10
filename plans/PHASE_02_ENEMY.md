# PHASE 2 — Enemy — ✅ DONE (2026-10-10)

## Read first
- `DOCS/00_RULES.md`
- `DOCS/DESIGN/ENEMY_DESIGN.md`
- `DOCS/SYSTEMS/AI_SYSTEM.md`
- `DOCS/ARCHITECTURE/DATA_SPEC.md`

## Goal
Slime exists, finds the nearest Hunter and moves toward it.

## Tasks
- [x] `EnemyDefinition` for Slime (`data/enemies/slime.tres`, values from `BALANCE.md`)
- [x] Enemy actor with the same composition as Hunter (shared `Actor` base)
- [x] Target detection: nearest valid Hunter, 0.5 s timer + immediate retarget on target death
- [x] Enemy movement with navigation; re-path only when the target moved > 8 px
- [x] Placeholder visual (round translucent blob with eyes, distinct from Hunter)
- [x] Debug panel: Slime, Slime x3, Down Hunter; red/yellow lines show each enemy's target

## Acceptance criteria
- [x] Slime chases nearest Hunter and stops in range
- [x] Retargets when target dies/leaves
- [x] No per-frame expensive searches
- [x] Hunter and enemy silhouettes distinguishable at gameplay zoom
- [x] Tests cover target selection

## Completion report

### Implemented
- `actors/common/actor.gd` — `Actor` base (components, navigation movement, `is_targetable`, downed handling); `Hunter` refactored onto it
- `actors/common/actor_visual.gd` — `ActorVisual` base (facing, selected, downed); `PlaceholderVisual` and `SlimeVisual` extend it
- `actors/common/combat_controller.gd` — targeting: keeps a valid target, retarget timer, `pick_nearest`, `is_target_in_range`, `target_changed`
- `actors/enemies/enemy.gd` + `actors/enemies/slime/` — Enemy AI (chase → stop in range → face target)
- `EnemyDefinition.attack_range`, `EnemyDefinition.actor_scene`, `HunterDefinition.attack_range`; groups `hunters` / `enemies`
- Physics layers: `world` (1), `actors` (2); actors collide only with the world
- Test runner now fails test files that do not compile

### Validation
- Unit tests: 33 passed (new: `pick_nearest`, Slime data vs BALANCE incl. actor scene)
- Scripted run (physics time): 3 Slimes pick the nearest of 2 Hunters → after 12 s all stop in range (17.5–18 px), none inside the rock → Hunter walks away, its Slime follows and stops in range again → Hunter downed, all Slimes switch to the remaining Hunter → last Hunter downed, all Slimes go IDLE with no target
- Rendered frames checked (chase lines, in-range stop)
- Main scene runs with no errors/warnings
- Bugs found and fixed: custom `draw_ellipse` clashed with Godot 4.7's built-in; Hunter could not walk through a Slime standing in its path (actors body-blocked each other); a compile-failing test file was counted as passing; leaked test instance

### Known limitations
- Several enemies can stack on the same spot; an enemy approaching from above overlaps the Hunter sprite. Spacing/avoidance is planned in Phase 3.
- Enemies do not attack yet (Phase 3). Hunters do not target enemies yet (Phase 3).
- Goblin, Wolf and boss come in Phase 4.

### Next step
Phase 3 — Combat.
