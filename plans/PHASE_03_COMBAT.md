# PHASE 3 — Combat — ✅ DONE except device smoke test (2026-10-10)

## Read first
- `DOCS/00_RULES.md`
- `DOCS/SYSTEMS/COMBAT_SYSTEM.md`, `AI_SYSTEM.md`
- `DOCS/DESIGN/VFX_DESIGN.md`

## Goal
Hunter and Slime fight automatically until one dies.

## Tasks
- [x] `CombatService` resolves attacks (damage, crit, death/downed) and emits `damage_dealt`, `actor_defeated`
- [x] Formulas in `StatService`: `max(1, attack - defense * 0.5)`, critical, cooldown `1 / attack_speed`
- [x] Attack timing in `CombatController` (random initial delay so groups do not attack in lockstep)
- [x] Flow: target → engagement slot → in range → cooldown → damage → react → death → next target
- [x] Hunter targeting + Hunter AI (shared `Actor` chase with enemies)
- [x] Actor spacing: engagement slots (6 per actor, obstacle-aware, waiting ring) + light separation. RVO avoidance was tried and dropped (deadlocks around one target).
- [x] Feedback: hit flash, attack lunge, floating damage numbers (crit yellow, Hunter hurt red), enemy death fade
- [x] Debug panel: Hunter / Hit 25 / Revive / Lv +1, Slime / x3 / x6, combat log (kills, crits)
- [ ] Android export preset + first device smoke test — blocked: export templates for Godot 4.7.2 not installed and no device connected (see report)

## Acceptance criteria
- [x] Fight resolves with correct damage and death
- [x] Critical hits work and are visible
- [x] Multiple enemies handled with retargeting
- [x] No runtime errors; existing phases still work
- [x] Tests cover formula, crit, death, slots

## Milestone
**M1 – Combat sandbox** (device test pending)

## Completion report

### Implemented
- `game/services/combat_service.gd`, `game/runtime/combat_stats.gd`; `GameManager.combat`
- `CombatController`: attack loop, engagement slots (`claim_slot`, `release_slot`, `holds_slot`), stop/resume
- `Actor`: shared chase, separation, `command_move_to` (player command pauses combat until arrival), `revive`, feedback hooks; `get_combat_stats`/`get_team_group` per subclass
- `Enemy` death: leaves group, fades, freed after 0.5 s; `Hunter` downed stays
- `ActorVisual`: `play_hit_flash`, `play_attack_lunge`, `play_death`
- `world/vfx/combat_feedback.gd`, `damage_number.gd`
- Test runner: runs tests on the first frame (nodes get `_ready`), and a custom `Logger` turns any script/runtime error during a test into a failure

### Validation
- Unit tests: 39 passed (new: damage formula on real actors, signals/defeat, refusing dead targets, critical ×2, cooldown, slot uniqueness/nearest, slots running out)
- Runner checked against a deliberate runtime error → reported as FAIL, exit 1
- Battles (headless, physics time): 2 Hunters vs 6 Slimes cleared in 10.7 s, no Hunter downed, runtime HP in sync, dead Slimes freed; 3 vs 9 cleared in 8.5–11.2 s over 4 seeds
- Crowd test: 7 Slimes on 1 Hunter at 4 positions (open field, rock corner, above rock, map edge) → every usable slot filled, extras wait, standing Slimes ≥ 13 px apart
- Rendered frames checked (spacing, damage numbers, combat log)
- Main scene runs with no errors/warnings
- Bugs found and fixed during validation: nodes added in the runner's `_initialize` never got `_ready`; RVO avoidance deadlock; slots squeezed against obstacles; Hunters stacking after retargeting; separation pushing slot holders out of range; arrival tolerance stopping attackers just outside range

### Known limitations
- In a dense brawl actors still overlap briefly while repositioning (measured < 1% of actor-frames out of range while holding a slot).
- Waiting attackers query navigation for 6 slots every physics frame; fine for MVP group sizes, may need throttling for big fights.
- No XP/loot on kill yet (Phases 4–5).
- Device smoke test not done.

### Next step
Phase 4 — Expedition. Device smoke test as soon as templates + a device are available.
