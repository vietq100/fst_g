# PHASE 11 — World redesign

Owner request (2026-10-11): one isometric world map with Town, Dark Forest, Goblin Cave and Ancient Ruins; Hunters hunt on their own; bodies are carried home; stamina and energy; Houses (4 beds); build / move / remove buildings; zoomable camera that can follow a Hunter; personal purses with 10% transfer fee.

## Read first
- `DOCS/DECISIONS.md` D27–D37 (primary)
- `DOCS/DESIGN/WORLD_DESIGN.md`, `DOCS/SYSTEMS/AUTONOMY_SYSTEM.md`, `DOCS/SYSTEMS/BUILD_SYSTEM.md`
- `DOCS/BALANCE.md` → Regions, Needs, Bodies, Money, Building placement

## Sub-phases (each ends playable, tested, documented)

### W1 — Isometric world + camera
- [x] `WorldService`: tile ↔ world, regions (diamonds), gates, dungeon entrances, region at point
- [x] World scene: ground per region (iso tiles), gate arches, dungeon entrances, props (trees, rocks, columns), one navigation mesh (regions + corridors, props as obstacles)
- [x] World camera: drag, pinch / wheel zoom (0.2–2×), clamp, follow an actor (drag stops following)
- [x] Main: the World replaces the Town scene as the hub (town buildings sit in the Town region)

### W2 — Buildings as placed instances
- [x] `BuildingDefinition`: build_cost, footprint, unique, beds; data for House
- [x] `BuildingService` → instances (id, type, tile, level); placement validation; build / move / remove (refund 50%); per-instance upgrades; effects from the unique building of a type
- [x] Isometric building visuals (box + roof + marker, Lv2 variant); collision footprint; nav rebake after changes
- [x] Default layout for a new game (Town Hall, Tavern, Blacksmith, Hospital, Warehouse, 1 House)
- [x] Beds: assignment, capacity rule for recruiting

### W3 — Needs and money
- [x] `HunterRuntime`: stamina, energy, purse, duty, bed, alive/body fields
- [x] `NeedsService` (tick drain/refill, effects), `PurseService` (purse, meals → treasury, transfers with 10% fee)
- [x] Stamina effects on speed / attack speed; starving effects

### W4 — Region monsters + Hunter brains
- [x] `RegionDefinition` data (monsters, levels, cap, respawn, min Hunter level); Skeleton enemy
- [x] `RegionService`/region spawners in the world: spawn, respawn, aggro range, leash, level scaling
- [x] `HunterBrain` node: priorities (carry, sleep, eat, rest, deposit, duty), walking between regions through gates, hunting, wandering
- [x] Kill rewards: XP, purse gold, loot bag; deposit at the Warehouse

### W5 — Death and bodies
- [x] Death leaves a body (actor downed, `HunterRuntime.alive = false`, body position)
- [x] `CorpseService`: carrier selection, fetch, drag at carrier speed × 0.7, deliver to Hospital
- [x] Hospital revival (recovery time, speed-up), revived at 50% needs

### W6 — Dungeons in the living world
- [x] `ExpeditionDefinition` → dungeon with entrance (region + tile); Forest Guardian's Grove active, others locked (data + world entrances; tapping a locked one shows "coming later")
- [x] Dungeon instance placed off-map in the world; party walks to the entrance, enters, fights; camera follows; survivors exit and resume their brains; fallen come out as bodies at the entrance
- [x] Rewards: items to the Warehouse, gold to the treasury, first-clear flag

### W7 — UI + save
- [x] Nav: Town (recenter) · Hunters · Build · Inventory; top bar adds beds and treasury
- [x] Build sheet + placement mode (preview, place, cancel); building sheet: Move / Remove
- [x] Hunter sheet: stamina/energy bars, purse + give/take (fee shown), duty selector, Follow, current task
- [x] Dungeon entrance sheet (party selection, locked entrances)
- [x] Save schema 2 (buildings instances ✅ done in W2; needs, purse, duty, positions, bodies) + migration 1 → 2
- [x] Docs, plan report, balance probes

## Acceptance criteria
- [x] One world map matching the owner's sketch; drag, zoom and follow work
- [x] Hunters sleep, eat, hunt, deposit loot and come home without player input
- [x] A Hunter that dies is carried home by another and revived
- [x] Buildings can be built, moved and removed; Houses limit recruiting
- [x] Purses and transfers work with the 10% fee
- [x] Forest Guardian's Grove can be run while the rest of the world keeps living
- [x] Save/load keeps all of it; old saves migrate
- [x] All tests pass; main scene has no errors/warnings

## Report — W1 + W2 (2026-10-11)

- World scene `world/world/` replaces `world/town/` (deleted; still in git). Hub id stays `&"town"`.
- Navigation: one NavigationPolygon from `WorldService.navigation_outlines()` (overlapping outlines union on bake — verified: paths Town → Forest / Ruins / Cave all reach their target). Props keep 34 px apart, otherwise the bake leaves slivers ("edge merge" warnings).
- Placement: Build sheet → ghost at the nearest free tile → tap to move → Confirm / Cancel bar. Building sheet: Move, Remove (tap twice, 50% refund).
- Save: schema 2 stores building instances; schema 1 saves migrate to the default layout with their levels.
- Departure is interim: the party walks to the Town gate towards the dungeon's region, then the old expedition scene loads (W6 replaces it).
- Tests: 126 passed (new `test_world.gd`, schema 1 → 2 migration test).

## Report — W3 (2026-10-11)

- `NeedsService` (stamina / energy per activity tick, meals, starving, exhaustion modifiers) and `PurseService` (purse, meals → treasury, give / take with 10% fee). Numbers in `GameConfig` (Needs, Money groups) = BALANCE.md.
- Until the brain (W4), town life decides needs: ActivityService picks **Sleeping** (stamina < 25, until 95) and **Eating** (energy < 35 and purse ≥ 10) before Rest / Train / Socialize. Training counts as active (drains stamina). Same rules run offline (D36).
- World: sleepers walk to their House door and go inside (hidden); without a bed they sleep beside the Town Hall. Eaters stand at the Tavern.
- UI: Hunter sheet shows stamina / energy bars, purse, Give 50 (+45) / Take all; top bar says Treasury; offline sheet counts meals and warns about hunger. Dev panel: "Tire all".
- Save: needs and purse are saved; schema 1 Hunters get a 20 gold purse.
- Tests: 135 passed (new `test_needs.gd`, 9 tests).

## Report — W4 (2026-10-11)

- Data: Skeleton (enemy + scene + loot table). Region numbers in `GameConfig` → Regions (aggro 90, leash 220, engage 150, bag 10, rest 35% → 90%).
- `RegionService`: duty (Auto = hardest region with min level ≤ Hunter level; fixed region; Stay), monster level / scaling, kill rewards (killer: purse gold × gold_find + loot bag; killer and helpers: XP), bag capacity, deposit (Warehouse, overflow sold to the treasury), rest hysteresis.
- World: `RegionSpawner` per region (fill to cap, respawn 15 s, wander near spawn, aggro only on Hunters in the same region, leash home + heal). `HunterBrain` on every Hunter: sleep / eat / rest / full bag → home (task "returning"), deposit at the Warehouse door, otherwise hunt the duty region (walk to the nearest monster); Hunters only fight while hunting, in the region they stand in. Damage numbers and loot popups in the world.
- `CombatController.acquire_filter` / `keep_filter` (aggro / leash / region rules); `Enemy.level` + stat scale.
- `HunterRuntime.task` ("" in town, "hunting", "returning") is saved with `world_position`; Hunters outside the Town are frozen offline (D36): `advance_town_time(seconds, offline)`.
- UI: Hunter sheet status (Hunting in …), duty buttons (Auto / Forest / Cave / Ruins / Stay), loot bag.
- Interim until W5: a Hunter who dies is moved to the Hospital as injured after 2 s.
- Probe (6× speed, 3 Hunters, 10 min game time): Lv1 → Lv4 in ~3 min in the Dark Forest, ~4 gold/min each, bags deposited, a Lv1 Hunter sent to the Goblin Cave came home at low HP. Leveling looks fast — balance pass pending (owner).
- Tests: 143 passed (new `test_regions.gd`, 8 tests).

## Report — W5 (2026-10-11)

- `CorpseService`: die (body where it fell, `alive = false`), carrier rules (alive, healthy, stamina ≥ 25, not asleep, not carrying), assign / pick up / drop / deliver, carrier speed × 0.7 as a stat modifier. A carrier that dies drops its body. Assignments are not saved (re-planned on load); bodies are (alive + position).
- Brain: carrying comes before needs — walk to the body ("fetching"), drag it ("carrying") to the Hospital door, deliver. World: every second the nearest free Hunter is assigned to each body; carried bodies follow their carrier.
- Revival: delivery makes the dead Hunter a Hospital patient (timer, gold speed-up as before); `HunterService.recover` revives with 50% HP and lifts stamina / energy to at least 50%. Bodies do not tick (needs, activities).
- Placement rule: a building's door tile (front-right face) must be free and inside the Town, and no building may cover another's door (carriers and depositors got stuck at a blocked Hospital door). Default House moved to (6, 15).
- Fix: a downed actor no longer overwrites a revived Hunter's HP.
- UI: Hunter status (Fallen / being carried / revived in …, Fetching / Carrying), toasts for deaths and deliveries.
- Probe (6×, 3 Hunters, one forced to die in the Ruins repeatedly): carrier assigned within 1 s, picked up, delivered, revived after the Hospital time at 50% HP; a natural death in the Forest was handled the same way.
- Tests: 150 passed (new `test_bodies.gd`, 7 tests; door rule in `test_world.gd`).

## Report — W6 (2026-10-11)

- Dungeons run inside the world map: the dungeon scene (Forest Guardian's Grove = the former Dark Forest expedition) is instanced right of the map (`DUNGEON_ORIGIN`, outside the camera bounds); its navigation bakes into the same map as a separate island. Main no longer switches scenes for it (the sandbox still does).
- Departure: the party walks to the entrance point (entrance pulled 48 px into its region, `WorldService.get_entrance_point`) with task "departing" — it fights monsters that attack on the way; a member falling or a 90 s timeout cancels the run. Carried bodies are dropped first.
- Run: party actors are moved into the dungeon, brains off, targets limited to the dungeon (`HunterBrain.override_filter`, dungeon enemies `is_inside`); the world camera follows the party inside the dungeon bounds; UI in expedition mode (HUD). The rest of the world keeps living.
- End: after the result banner, survivors come out at the entrance and their brains resume; the fallen lie there as bodies (`ExpeditionService.downed_handler` → `CorpseService.die`) and get carried home. Gold → treasury, items → Warehouse, first-clear flag as before. Result sheet says who fell.
- Fallback: a body nobody can carry for 120 s (`body_rescue_seconds`, e.g. everyone fell) is brought to the Hospital by the town.
- Fixes: brain no longer writes a body's position; party copied before release (actors were freed with the dungeon).
- Probe (4×): 2 × Lv10 + 1 Lv1 cleared the Grove (316 gold); the two fallen lay at the entrance and the survivor carried both to the Hospital.
- Tests: 151 passed (dungeon bodies at the entrance in `test_bodies.gd`).

## Report — W7 (2026-10-11)

- Navigation: Town (recenter) · Build · Hunters · Dungeon · Items. Top bar: Treasury, Beds, Slots, Town level.
- Hunter sheet: Follow on the map (camera follows; dragging stops it). Hunters list: task, stamina, energy, purse.
- Dungeon panel (entrance tap or Dungeon button): where the entrance is, "the world keeps living", fallen come out as bodies, "Walk to the entrance"; locked dungeons say they are sealed (no button); party rows show fallen / tired or hungry. Departure toast.
- Save schema 2 complete: building instances, needs, purse, duty, task, position, alive (bodies), loot bag; carriers and monsters re-planned / respawned. Schema 1 → 2 migration: default layout with old levels, 20 gold purses, beds handed out after loading (old saves had none — found while loading the owner's save).
- Tests: 153 passed (UI: build / locked dungeon / Follow / duty; save round trip with the new Hunter fields; migrated Hunters get beds).

## Phase 11 summary — owner review

Done: W1–W7. Open points for the owner:
- Balance: Dark Forest leveling is fast (Lv1 → 4 in ~3 min); energy lasts ~28 min per 10-gold meal, so Hunters who stay in town with an empty purse go hungry (offline too: 8 h offline ≈ starving town Hunters at 1 HP). Hunting Hunters earn ~4 gold/min and feed themselves.
- No Hospital: bodies go to the Town Hall and revive at once (no recovery time).
- Dungeon departure: the party walks the whole way; a member falling on the way cancels the run.
- Art is still placeholder (Phase 12).

## Change — map twice as wide (owner, 2026-10-11)

- Every region 36 × 36 tiles (was 18 × 18): Town gx/gy 0–35, Ruins 38–73 × 0–35, Forest 0–35 × 38–73, Cave 38–73 × 38–73. Gates follow automatically (middle of each shared edge).
- Default buildings at doubled tiles: Town Hall (16, 14), Tavern (6, 8), Blacksmith (26, 6), Hospital (6, 24), Warehouse (24, 24), House (12, 30). Dungeon entrances moved to the middle of their edges: Grove (−1, 56), Hollow (17, 74), Crypt (56, −1), Sanctum (74, 17), Warren (56, 74), Deep Mine (74, 56).
- Population caps doubled (16 / 18 / 18); prop density unchanged (≈ 310 props). Camera zooms out to 0.2×; the dungeon instance is placed right of the (now larger) map bounds.
- Checked: paths Town → each region, 0 frames over 40 ms in a 1 140-frame run, load ≈ 0.2 s. Tests: 153 passed.
- Older saves: building positions from schema 2 saves stay valid (still inside the larger Town); schema 1 saves get the new default layout.
- Fix found while soaking the bigger map at 8× speed: actors could overshoot a path point by more than the arrival distance and oscillate forever; `Actor` now never steps past the next path point. Soak (8×, 3 Hunters, ~12 min game time): 59 kills, Lv1 → Lv5, purses 69–181 gold, bags deposited, no errors.
