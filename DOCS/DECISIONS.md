# DECISIONS

Resolved design decisions and conflict fixes. This file ranks right after `01_PROJECT_OVERVIEW.md` in priority (see `00_RULES.md`).

Numbers referenced here live in `BALANCE.md`.

## D1. Game direction
Open-ended. No endgame, final boss or win state. Two growth axes: power and life (traits, mood, bonds).

## D2. Expedition mode
- Real-time. The player can watch the expedition scene.
- Expeditions only progress while the app is open; when the app goes to background the expedition pauses.
- Town timers (Hospital, activities) also progress offline (D24).
- Hunters leave through the South Gate; the scene changes with a fade.
- No manual recall in MVP.

## D3. Party
- 1–3 Hunters per expedition.
- One expedition active at a time in MVP.

## D4. Defeat during an expedition
- A Hunter at 0 HP is **downed**: leaves the fight, not dead, becomes injured on return.
- Expedition fails when all party members are downed.
- Failure: keep 50% of collected gold and materials; no completion bonus, no boss reward; all downed Hunters go to Hospital.
- No permanent death.

## D5. Loot and XP
- Loot is collected automatically on kill into an expedition stash and granted on return.
- Every party member (including downed ones) gets the full XP of each kill.

## D6. Currencies vs materials
- **Gold** is the only numeric currency.
- **Iron Ore, Beast Fang, Dark Essence** are stackable material items stored in the inventory.
- "Materials" in older docs means these items, not a separate currency.

## D7. Dark Essence
- Source: Forest Guardian (guaranteed on first clear, chance on repeat), rare drops later.
- Sinks: Rare-tier crafting at Blacksmith, Town Hall level 3 upgrade.

## D8. Town layout (unified)
```
        [NORTH ROAD]   (closed in MVP, future regions)

 [TAVERN]        [BLACKSMITH]

    [TRAINING YARD] [TOWN HALL]

 [HOSPITAL]      [WAREHOUSE]

        [SOUTH GATE]   (expedition exit)
```
Training Yard is an open area, not a building.

## D9. Buildings in MVP
Town Hall, Tavern, Blacksmith, Hospital, Warehouse (all five).
- **Town Hall:** town level, Hunter capacity, Hunter level cap, unlocks.
- **Tavern:** recruit (3 candidates); resting and socializing location.
- **Blacksmith:** craft equipment from recipes.
- **Hospital:** timed recovery of injured Hunters; gold can speed it up.
- **Warehouse:** inventory slot capacity. Overflow on return is auto-sold at sell price.

## D10. Town milestones
First Forest Guardian clear unlocks Town Hall level 2. This replaces "unlock next expedition" while MVP has only one region.

## D11. Recruitment
- Tavern shows 3 candidates. Refresh after each expedition return, or pay gold.
- Candidates: Warrior class, random name, colour accents, 1–2 traits, ±10% stat variance.
- `HunterDefinition` is a class template; individual identity lives in `HunterRuntime`.

## D12. Hunter level cap
Hunter max level = Town Hall level × 10. Configurable in data. Not a final cap.

## D13. Mood
- Low mood never blocks assignment in MVP. It gives a warning and stat/XP penalties.
- Refusal and separation effects are post-MVP.

## D14. Activities
| Activity | Location |
|---|---|
| Resting | Tavern (rooms) |
| Socializing | Tavern (common room) |
| Training | Training Yard |
| Recovering | Hospital (forced while injured) |

Default activity for an idle Hunter: Resting if HP < 100% or mood < 50, otherwise Training.

## D15. Traits
No retreat behaviour in MVP. Cautious is a defensive stat trait. Retreat AI is post-MVP.

## D16. Elite enemies
No separate elite enemies in MVP. The "stronger enemies" section of the Dark Forest uses larger mixed Goblin/Wolf groups. Elites (stat-multiplied variants) are post-MVP.

## D17. Consumables
Category exists in data, but no consumable items in MVP.

## D18. Stat modifiers
- Format: `{ stat, type: "flat" | "percent", value }`.
- Final stat = `(base + level_growth + Σflat) × (1 + Σpercent)`.
- Sources of percent: equipment, traits, mood, bond.

## D19. Combat details
- `attack_cooldown = 1 / attack_speed` seconds.
- Critical: `randf() < critical_chance` → `damage *= critical_damage`. Field name is `critical_damage` everywhere.
- Retarget check on a timer (0.5 s) and on target death.

## D20. Presentation
- Portrait. Base viewport 360×640, stretch mode `viewport`, aspect `expand`, integer scaling, nearest filtering.
- `expand` grows the viewport to fill tall/wide screens (e.g. 1080×2400 phone → scale 3, viewport 360×800). Layouts must use anchors and never assume exactly 360×640.
- Desktop test window 540×960 (dev only).
- Renderer: GL Compatibility (widest mobile device support for 2D).
- 4-direction movement and sprites.

## D21. Save
- Single slot, JSON at `user://save.json`, backup `user://save.bak.json`.
- Autosave: expedition end, recruitment, building upgrade, crafting, app paused/backgrounded, quit.
- Save stores a real-world timestamp for offline progress (D24).
- An expedition in progress is not saved in MVP; if the app is killed, on next load the party is back in town without that run's rewards.
- An in-game day counter is saved and used for Hunter history (recruit date).

## D22. Development tooling
- Debug panel allowed from Phase 1 under `ui/debug/`, removed in release builds. Collapsible by tap; F1 on desktop.
- Tests: plain GDScript runner `tests/run_tests.gd`, run headless. No test plugins.
- Mouse emulates touch on desktop so touch code paths are tested there.

## D23. Platform and input
- Android and iOS. Android is the first device-test target; iOS needs Xcode.
- Portrait only.
- Input: tap to select/act, drag to pan camera, pinch zoom optional (post-MVP). No hover-only or keyboard-only interactions.
- Minimum touch target 40×40 game px (~44 dp). Minimum font size 10 game px, body text 12.
- UI respects the device safe area (notch, home indicator).
- Target 60 fps on mid-range phones; first device smoke test by the end of Phase 3.

## D25. New game (decided during Phase 6)
- Start with 200 gold, 1 free Warrior and 3 Tavern candidates, all buildings at level 1.
- The player can go on an expedition right away or recruit up to 2 more Hunters (Town Hall Lv1 capacity 3).

## D26. Trait events and town life details (decided during Phase 8)
- Trait likes/dislikes are event tags: `boss_fight` (party reached the boss), `boss_kill` (success), `success`, `failure`, `above_level` (Hunter level < recommended), `reckless_partner` (another Reckless in the party), `back_to_back` (2nd+ expedition in a row without resting), `idle_cycles` (stayed home for 2 expedition cycles), `long_rest` (every 3rd consecutive resting tick), and activity ids (`training`, `resting`, `socializing`) once per 6 ticks of that activity.
- Each matching trait gives +5 (like) or −5 (dislike). Overwork: −5 from the 3rd expedition in a row. Any resting tick resets the streak.
- Greedy `gold_find` bonuses of the party add up (two Greedy Hunters: +40% gold).
- Brave's `vs_boss` bonus, Reckless and Cautious use `damage_dealt` / `damage_taken` multiplier stats.
- In-game day = 5 real minutes (Hunter history "since day N").

---

# World redesign (owner request, 2026-10-11)

These decisions replace the ones they name. Older decisions that are not mentioned still apply.

## D27. One isometric world map (replaces D8, part of D2, D20 "4-direction top-down")
- Isometric 2:1 projection, tile 64 × 32 px. Tile (gx, gy) → world (x, y) = ((gx − gy) × 32, (gx + gy) × 16).
- Four diamond regions of 36 × 36 tiles (owner: twice as wide as the first 18 × 18 draft) with 2-tile corridors between them:
  - Town gx 0–35, gy 0–35 (top) · Ancient Ruins gx 38–73, gy 0–35 (right) · Dark Forest gx 0–35, gy 38–73 (left) · Goblin Cave gx 38–73, gy 38–73 (bottom).
- Gates (2 × 2-tile corridors): Town–Forest, Town–Ruins, Forest–Cave, Ruins–Cave. No direct Forest–Ruins link.
- Dungeon entrances: two on the outer edges of each hunting region (6 total).
- Characters keep their 4-direction sprites; buildings and ground are drawn isometric.
- The world keeps running while the player looks anywhere; there is no scene switch for hunting.

## D28. Camera (replaces "drag to pan" only, D23)
- Drag to pan, pinch (two fingers) or mouse wheel to zoom (0.2×–2×), clamped to the world.
- "Follow" a Hunter from their panel; any drag stops following. Nav "Town" recenters on the Town.

## D29. Autonomous hunting (replaces the expedition loop of D2–D5 for regions)
- Every Hunter has a brain with priorities: dead → (nothing) · stamina low → sleep · energy low → eat · HP low → rest · loot bag full → deposit · duty → hunt / town life.
- Duty: **Auto** (default: the hardest region whose minimum level ≤ Hunter level), a fixed region (Dark Forest / Goblin Cave / Ancient Ruins), or **Stay in town**.
- Monsters live in regions (spawn points, population cap, respawn timer) and only aggro on Hunters within range in the same region.
- Kill rewards: XP to the Hunter, gold to the Hunter's purse, items into the Hunter's loot bag (capacity 10). Bag contents go to the Warehouse on return (overflow auto-sold, gold to the treasury).
- Region monster levels scale stats and rewards (BALANCE.md → Regions). Ancient Ruins add a new enemy, the Skeleton.

## D30. Death and bodies (replaces "downed / injured on return", D4)
- A Hunter at 0 HP dies and leaves a **body** where they fell. No permanent death.
- A free Hunter (in town or idle, alive, not on a dungeon run, stamina ≥ 25) is sent to fetch it: walks to the body, then drags it back to the Temple (D42) at the **carrier's speed × 0.7**. Village staff do this first (D43).
- At the Temple (D42) the Hunter is revived after the revival time (gold can speed it up). Revived Hunters start with 50% HP, stamina and energy.
- Monsters ignore bodies. A carrier that dies drops the body; both wait for the next carrier.

## D31. Needs (new)
- **HP** (combat), **Stamina** 0–100 (sleep/rest), **Energy** 0–100 (food/drink).
- Stamina drains while active (walking, hunting) and refills while sleeping in a House bed (slower without a bed). Energy drains over time and refills by eating at the Tavern.
- Thresholds and effects: BALANCE.md → Needs. Empty stamina: −40% move speed, −30% attack speed. Empty energy: HP slowly drops and mood falls.

## D32. Houses (new)
- A House has 4 beds. Each Hunter is assigned a bed when one is free. Recruiting needs a free bed and Town Hall capacity.
- Hunters without a bed sleep outdoors near the Town Hall (half stamina recovery, mood penalty).

## D33. Building placement (replaces fixed layout, D8/D9 "one of each")
- Build mode: choose a building, place it on free Town tiles (green/red footprint preview), confirm.
- Existing buildings can be **moved** (free) or **removed** (50% of their build cost refunded). The Town Hall cannot be removed. Removing a House frees its beds.
- Core buildings (Town Hall, Tavern, Blacksmith, Hospital, Temple, Warehouse) are unique; Houses are unlimited.
- Upgrades stay per building (levels from BALANCE.md). Navigation is rebaked after every change.

## D34. Money: treasury and purses (extends D6)
- **Treasury** = town gold (build, upgrade, craft, recruit, Temple speed-up, staff fees; D38).
- Every Hunter has a **purse**: hunting gold goes there; meals are paid from it (meal price goes to the treasury as Tavern revenue).
- The player can transfer gold treasury → Hunter or Hunter → treasury; every transfer costs a **10% fee** (the receiver gets 90%).
- A Hunter who cannot afford a meal stays hungry (mood falls) until they earn or receive gold.

## D35. Dungeons (replaces the Dark Forest expedition as a region, keeps D3/D5 for runs)
- Dungeons are separate instances with a boss, entered by a chosen party (1–3) through an entrance on a region edge. The rest of the world keeps running.
- MVP: **Forest Guardian's Grove** (Dark Forest, former Dark Forest expedition: same sections, boss, loot and first-clear flag). The other five entrances are shown locked ("coming later").
- The party walks to the entrance, then fights in the dungeon instance; the camera follows them. Afterwards survivors walk home on their own; Hunters who fell come out as bodies at the entrance (D30).
- Dungeon loot goes to the Warehouse and the gold to the treasury.
- On the way to the entrance the party fights monsters that attack it; if a member falls on the way, the run is cancelled.
- If no Hunter can carry a body for a while (BALANCE.md → Bodies), the town brings it to the Temple so the game never gets stuck.

## D36. Offline progress with a living world (refines D24)
- Offline time only advances Town timers: Temple revivals and needs/activities of Hunters who are in the Town. Hunters outside the Town (hunting, carrying, in a dungeon) are frozen while the app is closed. Cap stays 8 hours.

## D37. Save schema 2
- Buildings are saved as placed instances (type, tile, level); Hunters add needs, purse, duty, position, alive/body state; carriers and monsters are not saved (re-planned / respawned on load). Schema 1 saves migrate by placing the default layout with their building levels.

## D38. The player is the village chief (owner, Phase 11b)
- The player runs the village: builds, crafts in the village buildings, sets duties, moves gold between the treasury and Hunters, and pays village staff. Hunters live and hunt on their own.
- Treasury = village funds.

## D39. Materials are sold to the village (replaces "bag deposited for free", D29)
- Monsters drop materials into the Hunter's loot bag. At the Warehouse the village **buys** them at the item's price: the treasury pays, the Hunter's purse receives.
- What the village cannot pay for or store (treasury short, Warehouse full) is sold to a passing trader at the same price (gold to the purse, items leave the game), so Hunters are always paid.

## D40. Food is crafted by the village (replaces "meals cost 10 gold any time", D34)
- The chief cooks food at the **Tavern** from materials (recipes). Food is kept in the Warehouse.
- A hungry Hunter eats one portion of the best food it can afford: it pays the food's price into the treasury and gains its energy.
- No food in stock (or no money): the Hunter stays hungry and keeps working; the Hunter panel says why.

## D41. Medicine (replaces Hospital recovery, D9)
- The chief makes **Bandages** and **Healing Potions** at the **Hospital** from materials.
- A Hunter that comes home to rest at low HP visits the Hospital and buys the strongest medicine it can afford (purse → treasury), one at a time, until it is back above the rest threshold (90%); without medicine it rests as before.

## D42. Temple: revival (replaces Hospital revival, D30)
- Bodies are delivered to the **Temple**. Revival takes the Temple's time (gold can speed it up) and costs the Hunter **10% of the XP needed for its current level** (never below 0 XP, no level loss). Revived Hunters come back with 50% HP, stamina and energy.

## D43. Cleanup staff (extends D30)
- The village has **2 staff** (not Hunters, not in the roster, cannot fight, monsters ignore them). They live at the Temple.
- A free staff member fetches each body and drags it to the Temple at its speed × 0.7. Every trip costs the treasury a fee, paid when the trip starts.
- When both are busy or the treasury cannot pay, a free Hunter carries the body for free (D30). The town rescue after a long wait stays.
- A party that falls on its way to a dungeon simply leaves bodies; staff bring them home.

## D44. Progression rebalance
- Required XP grows faster with level: `30 × level^2.2`.
- Training gives 1 XP per tick; offline (D24/D36) training gives a quarter of that.

## D45. Hunter classes (owner, Phase 11c; extends D1)
- Four classes: **Warrior** (balanced melee), **Ranger** (ranged, fragile), **Rogue** (fast, critical hits), **Guardian** (tank). Numbers in BALANCE.md → Classes.
- Tavern candidates are any class. Every class can equip any weapon and armor; its starting gear and look differ.
- Ranged attacks show an arrow streak; damage is still resolved on the attack (no projectile travel).

## D46. Talents (owner, Phase 11c)
- A recruit may have one **talent**: **Cook** (cooks food) or **Herbalist** (makes medicine), or none (BALANCE.md → Talents).
- A talented Hunter crafts **in the field from the materials in its own loot bag**, using the village recipes (Meat Stew, Herb Soup / Bandage, Healing Potion), without any building. Crafting takes 5–10 s, during which it stands still; being hit cancels it (nothing is used up).
- When hungry, any Hunter first eats food from its own bag (free). A Cook without food cooks if its bag has the ingredients. When its HP is low, a Hunter first uses medicine from its bag; a Herbalist brews some if it can. Only then does it walk home.
- Extra portions stay in the bag and are sold to the village with the rest of the bag (D39).

## D24. Offline progress (town only)
- On load/resume, elapsed real time since the last save is applied to town timers: Hospital recovery and activity ticks (rest, train, socialize).
- Capped at 8 hours (`GameConfig.offline_cap_hours`).
- Negative elapsed time (clock changed) is ignored.
- Expeditions never progress offline.
- On return the player sees a short "while you were away" summary.

## D47. Hunter appearance (owner, 2026-10-11; implements CHARACTER_DESIGN.md §9, §10, §12)
- Hunters are drawn from two reference sprites (male, female; 3/4 view facing right) supplied by the owner. Facing left mirrors the sprite; there is no back view yet.
- Each Hunter has a saved look: body type, 1 of 10 hairstyles, 10 hair colours, 4 skin tones, 8 dye colours (dye = accent colour).
- The look is rolled at random when the candidate is generated and never chosen or edited by the player (owner, 2026-10-11).
- Outfits are part of equipment: each armor item names one of 30 outfits (`ItemDefinition.outfit_id`). No armor = the body type's default outfit (male: Hunter Vest, female: Warrior Dress). Dye recolours only cloth; leather, metal, fur and bone keep their colours. Some outfits include headgear (hood, helmet, hat, circlet, headband).
- World sprite: 34×50 px canvas (fits the 32×48 character target). Portraits use a 2x version (EPX upscale + extra detail), cropped around the face.
- Saves made before D47 get a stable look derived from the Hunter's id and name (no schema change; the field is optional).
- Sprites are composed in code from `data/appearance/wardrobe.json` and cached. Final art can replace the reference bodies and masks without changing gameplay code.

## D48. Status effects (2026-10-11; extends COMBAT_SYSTEM.md)
- Every actor has a `StatusEffectController` (buffs/debuffs) and a `StatusEffectView` (their visuals), both created by `Actor._ready()` so no actor scene needs editing.
- Effects are data: `StatusEffectDefinition` resources in `data/status_effects/` (registry category `status_effect`). One definition may combine damage/heal over time, stun/root/disarm, invulnerability, stat modifiers, a damage shield, thorns and lifesteal. Values are per stack.
- Stacking: REFRESH (reset duration), STACK (add stacks up to `max_stacks`, reset duration) or IGNORE (no chaining, e.g. stun).
- Stat modifiers apply on top of the final combat stats: `(value + Σflat) × (1 + Σpercent)`; move speed uses the same rule. They do not enter the D18 pipeline or the Hunter sheet.
- Damage order: invulnerable → shields (oldest first) → HP. Damage over time goes through `CombatService.resolve_effect_damage` so kills are credited to whoever applied the effect. Thorns reflect a fraction of hit damage (never reflected again); lifesteal heals from hit damage.
- Enemies may apply effects on hit (`EnemyDefinition.on_hit_effects`, chance + stacks). No current enemy uses it yet (no balance change).
- Death and revive clear all effects. Effects are scene-only and never saved.

## D49. Chibi Hunter core (owner, 2026-10-11; replaces the D47 sprite pipeline)
- Hunters use one chibi base body traced from the owner's reference: 15×29 px figure (bald, white tank top, shorts) on a 32×48 canvas, feet at the bottom centre.
- The body is split into six parts moved by whole pixels per frame; animations are data tables (`ChibiAnimations`): idle, walk, run, attack, skill, hit, death, pickup, loot, interact. Gaps between parts are filled by repeating the edge row, so the body never tears.
- Facing: front, back, side; left mirrors right.
- Skin tone (4) and dye (shorts, 8 = accent palette) come from `HunterAppearance`. Hair, body type and outfits are not drawn; their saved values are kept for future layers. The D47 wardrobe, composer, reference sprites and `HunterSpriteVisual` were removed.
- `ActorVisual` gained `running` and `play_action(name)` so gameplay can trigger actions without knowing the art.
