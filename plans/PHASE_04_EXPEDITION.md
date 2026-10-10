# PHASE 4 — Expedition

## Read first
- `DOCS/00_RULES.md`
- `DOCS/SYSTEMS/EXPEDITION_SYSTEM.md`, `CHARACTER_SYSTEM.md`
- `DOCS/DESIGN/MAP_DESIGN.md`, `DUNGEON_DESIGN.md`, `BOSS_DESIGN.md`, `ENEMY_DESIGN.md`

## Goal
Send a party into the Dark Forest, fight through groups and the boss, finish and return.

## Tasks
- [ ] `ExpeditionDefinition` for Dark Forest (recommended level, enemy groups, boss, reward table, unlock requirement)
- [ ] Expedition flow: preparation → choose Hunters (1–3) → validate → start → travel → combat → rewards → return
- [ ] Hunter lifecycle states: AVAILABLE → ASSIGNED → TRAVELING → COMBAT → RETURNING → RECOVERING/AVAILABLE
- [ ] Dark Forest map: entrance → clearing → enemy area → deeper forest → boss arena → exit; spawn points, navigation
- [ ] Enemies: Slime, Goblin, Wolf (data + placeholder visuals)
- [ ] Boss: Forest Guardian with basic melee only (repeatable milestone)
- [ ] Downed state at 0 HP (D4); full XP per kill to every party member (D5)
- [ ] Expedition stash: loot auto-collected on kill, granted on return
- [ ] Completion: grant stash + bonus + boss rewards, track first clear, autosave hook (stub until Phase 9)
- [ ] Failure: all party downed → keep 50% stash, no bonus/boss reward, downed Hunters injured
- [ ] Section groups and stats from `BALANCE.md` (stronger group instead of elites, D16)
- [ ] Camera follows gameplay, clamped to map

## Technical requirements
- Expedition scene: World, Actors, Enemies, Navigation
- Services own state; UI only requests actions
- No permanent death

## Acceptance criteria
- [ ] Full run from start to boss kill works
- [ ] Failure path works and injures Hunters
- [ ] Hunters return and states reset correctly
- [ ] Map transitions are visually clear (no silent teleport)
- [ ] Tests cover state transitions and completion/failure

## Completion report
Implemented / Files changed / Validation / Known limitations / Next step (Phase 5)
