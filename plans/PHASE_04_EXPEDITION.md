# PHASE 4 — Expedition — ✅ DONE (2026-10-10)

## Read first
- `DOCS/00_RULES.md`
- `DOCS/SYSTEMS/EXPEDITION_SYSTEM.md`, `CHARACTER_SYSTEM.md`
- `DOCS/DESIGN/MAP_DESIGN.md`, `DUNGEON_DESIGN.md`, `BOSS_DESIGN.md`, `ENEMY_DESIGN.md`

## Goal
Send a party into the Dark Forest, fight through groups and the boss, finish and return.

## Tasks
- [x] `ExpeditionDefinition` for Dark Forest (`data/expeditions/dark_forest.tres`)
- [x] Expedition flow: choose Hunters (1–3) → validate → start → travel → combat per section → boss → exit → rewards → return
- [x] Hunter lifecycle: AVAILABLE → ASSIGNED → TRAVELING → COMBAT → RETURNING → AVAILABLE / RECOVERING
- [x] Dark Forest portrait map (360 × 1440): entrance → clearing → enemy area → deeper forest → boss arena → exit; 134 trees as navigation obstacles; markers for spawns/rallies
- [x] Enemies: Goblin, Wolf (data + placeholder visuals)
- [x] Boss: Forest Guardian, basic melee only, `hit_radius` 14, holds position in range
- [x] Downed state at 0 HP (D4); full XP per kill to every party member (D5); level-ups with 20% heal and level cap
- [x] Expedition stash: gold per kill, granted on return (items in Phase 5)
- [x] Completion: stash + 50 bonus, first-clear flag `first_boss_clear`, `autosave_requested` signal (Phase 9 hooks in)
- [x] Failure: all downed → keep 50% stash, no bonus, everyone injured
- [x] Repeat boss clears halve boss gold
- [x] Camera follows the party, clamped to the map
- [x] Clear transitions: fade between hub and expedition, VICTORY/DEFEAT banner
- [x] App background pauses the expedition (D2)

## Acceptance criteria
- [x] Full run from start to boss kill works
- [x] Failure path works and injures Hunters
- [x] Hunters return and states reset correctly
- [x] Map transitions are visually clear (no silent teleport)
- [x] Tests cover state transitions and completion/failure

## Completion report

### Implemented
- Services: `ExpeditionService`, `WalletService`, `ProgressService`; `HunterService.add_xp / set_lifecycle_state / mark_injured / recover`; runtime `ExpeditionRun`
- `world/expedition/expedition_scene.gd` (generic pacing), `dark_forest.tscn`, ground and camera scripts; `world/props/tree.tscn`
- Enemies: `goblin`, `wolf`, `forest_guardian` data + scenes + visuals (Goblin reuses the humanoid placeholder with ears/club)
- `Actor.travel_target` (walk when no target), `Actor.repositions_in_range`, `get_hit_radius` / reach
- `LevelUpBurst` VFX; Main world switching, banner, background pause; hub (test arena) re-spawns the roster, "Dark Forest" and "Heal all" buttons; expedition debug panel (Kill wave, Party Lv 10, Wipe party, live status)

### Validation
- Unit tests: 50 passed (new: validation rules, lifecycle, stash/XP incl. downed members, level-up math 150 XP → Lv 3 with 73 left, level cap keeps XP, success rewards/flag/states, failure 50% + injuries, repeat boss gold, wallet, data vs BALANCE for 3 enemies and Dark Forest incl. scene markers)
- Full runs through Main (headless): party Lv 1 → reached boss, FAILED at 50 s, 31/63 gold kept, all 3 back in the hub injured and shown downed; party Lv 10 → SUCCESS at 36 s, 270 gold, first-clear flag set, all AVAILABLE in the hub
- Balance probe (no equipment): Lv 3 and 4 fail at the boss, Lv 5 wins with 1 downed
- Background pause: 1 s in background → boss HP and position unchanged; resume continues the run
- Rendered frames checked: forest trail, section fights, boss arena with stone circle, party surrounding the boss, VICTORY banner
- Main scene runs with no errors/warnings
- Bug found and fixed: boss fight drifted into the trees because boss and Hunters kept stepping to each other's slots → bosses hold position when in range (drift now ≈ the approach distance only)

### Known limitations
- Recommended level 4 is not enough without gear (BALANCE assumes Iron Sword); revisit after Phase 7 / in Phase 11.
- Loot items (Iron Ore, Beast Fang, Dark Essence, equipment) are Phase 5; loot table ids are already set on the data.
- Injured Hunters need the debug "Heal all" until the Hospital exists (Phase 6).
- The hub is still the test arena; Town comes in Phase 6. Expeditions in progress are not saved (D21).
- The debug panel covers the top of the screen; real UI in Phase 10.

### Next step
Phase 5 — Loot (loot tables, materials, inventory).
