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
- Follow easing, the free band above an open sheet and the lit "Town" button: D79.

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

## D50. Evil Hunter Tycoon systems (owner request, 2026-10-12; see REFERENCE_EVIL_HUNTER_TYCOON.md)
- **Town Hall gates buildings**: `BuildingDefinition.required_town_level`. Town Hall now has 5 levels (Hunter level cap = 10 × level, capacity 3/5/8/12/16).
- **New buildings** (unique, built from the Build menu): Trading Post (Lv2), Inn (Lv2, 6/10 beds), Academy (Lv3), Enhancement Forge (Lv3), Reincarnation Portal (Lv3).
- **Trading Post**: the chief posts material requests; Hunters selling that material get a bounty (50% of the price) from the treasury on top of the normal sale. Slots 2/3/5.
- **Academy**: gold-priced skills (`data/skills`, per-level modifiers, Academy level gates them) and traits bought with rebirth points; flaws can be forgotten for 300 gold.
- **Forge**: per-instance enhancement (+12% item modifiers per level, limit 3/6/9 by Forge level; gold ×(n+1)^1.5 and Iron Ore).
- **Reincarnation** (Lv20, Portal; content tops out near level 12 monsters, so 30 was unreachable): level back to 1, +6% HP/ATK/DEF and +10% XP gain permanently per rebirth, 1 rebirth point (2 every third). Repeatable, no end (keeps the "no endgame" pillar).
- **Difficulty** (Easy/Normal/Hard/Nightmare): unlocked by total reincarnations (0/1/3/6); scales region monster stats ×1/1.4/2/3 and rewards ×1/1.5/2.2/3.5.
- **Quests** (`data/quests`): ordered guided objectives with gold/item rewards, claimed in the Quests sheet.
- Save schema unchanged: all new fields are optional with defaults.
- **Subclasses**: 8 (Duelist/Slayer, Hawkeye/Sniper, Assassin/Nightblade, Crusader/Templar), `HunterDefinition.promotion_of`; not recruitable. Academy class change needs 2 reincarnations and 5000 gold.
- **Restaurant** (Town Hall Lv2): meals restore +25% / +50% energy (needs the Tavern's food).
- **Item tiers**: Rarity gains Superior and Epic; Steel and Shadow weapons/armor are Blacksmith recipes.
- **Trading Post pull**: Auto-duty Hunters pick the hardest region whose monsters drop a requested material.
- ~~The world stays isometric (D27), as in the original game.~~ Superseded by D52: the original game is top-down.
- UI icons are 12×12 pixel-art bitmaps in code (`ui/theme/pixel_icons.gd`) used by the top bar and the navigation bar.

## D51. Visual polish pass (owner request, 2026-10-13: "better UX/UI, maps and characters")
- **Hunters** (extends D49): a hair layer (10 styles × 10 colours from `HunterAppearance`, drawn over the head and moving with it; back and side views derived from the front map) and an outfit per base class (`ChibiBody.OUTFITS`: Warrior red tunic + steel pauldrons, Ranger green tunic + quiver strap, Rogue dark tunic + dyed scarf, Guardian plate + blue tabard; subclasses wear their base class's outfit; trousers keep the dye). Iris colour = hair colour. Weapons are drawn by class: sword, bow, dagger, mace; Guardians carry a shield. Portraits crop hair, face and shoulders (17×19 px). Body type and armor items still do not change the sprite.
- **Enemies**: the humanoid placeholder (goblin, skeleton) has legs, arms, a shaded tunic, belt, eyes; skeletons show ribs and red eyes.
- **World**: hip roofs with a ridge, stone plinth, three wall materials (stone / wood planks / plaster with timber frame), lit windows, arched door, signs, chimneys with smoke; leafy trees in the Town, pines in the Dark Forest, faceted rocks, fluted columns; cobbled plaza, dirt roads with pebbles, grass tufts and bushes; hanging grass and streaks on cliffs, foam and wave marks on the water; dungeon entrances with torches, glow and a name plaque. (Gate arches were replaced by bridges in D52.)
- **UI** (`GameTheme`): chunky buttons (dark bottom edge, sink when pressed), sheets with rounded top, gold rim and shadow, header separator, thin scroll bars, shaded progress bars, accent-edged toasts, resource pills in the HUD, gold bar on the selected nav tab, lit portrait backdrop.
- Presentation only: no gameplay, balance or save changes.

## D52. Top-down world like Evil Hunter Tycoon (owner request, 2026-10-13; replaces the projection of D27)
- The world is a **top-down grid of 32 × 32 px square tiles**: tile (gx, gy) → world (gx × 32, gy × 32). Buildings, props, gates and characters are drawn front-facing (3/4 view), as in the reference game. `WorldService.rect_polygon` returns top-left, top-right, bottom-right, bottom-left.
- Region layout, tile rectangles, gates and dungeon entrance tiles are unchanged (data): Town top-left, Ancient Ruins top-right, Dark Forest bottom-left, Goblin Cave bottom-right. The 2-tile gaps between regions are **bridges** over the water (plank deck drawn by the ground, railings and lanterns by `GateVisual`). Dungeon entrances sit on small rock ledges off the outer edges.
- Each region is a plateau: a cliff face below its bottom edge (the Town a stone retaining wall), foam and wave marks on the water around it. The Town also has a stone parapet along its other edges and a fence behind its back row.
- Buildings (`TownBuilding`, `BuildingVisual`, formerly `IsoBuilding*`) are anchored at the middle of their footprint's bottom edge; the **door is in the middle of the bottom face**, so `BuildingService.get_door_tile` is the tile below the footprint's middle. Door points, home spots and staff spots follow from that. Save data (anchor tiles, footprints) is unchanged.
- UI palette follows the reference: deep navy panels, gold rims, green confirm / red cancel, white outlined numbers, bigger nav icons.
- Presentation and geometry only: no balance or save schema change. The isometric drawing code was removed.

## D53. Items, monsters and nameplates (2026-10-13, continues D51/D52)
- **Item icons**: `ItemIcons` draws 12×12 pixel icons by item kind (sword, dagger, bow, mace, armor, ring, ore, herb, meat, fang, gel, dust, essence, potion, bandage, bowl), picked from the item's type and id and tinted with `ItemDefinition.tint`. `ItemIcon` is the slot widget (rarity rim, count / "+N" badge) used by the Storage, Blacksmith, Forge and paper-doll views instead of colour swatches.
- **Monsters**: goblins, skeletons, wolves and slimes are pixel bodies (`MonsterBodies`, `MonsterVisual`): goblin / skeleton with front, back and side views and a generated walk frame; wolf side-on; slime front-only with a two-frame squash that also plays while idle. Lying when dead, weapon line kept where the body has one. `PlaceholderVisual` remains for staff workers; the old wolf / slime visuals were removed.
- **Ambient motion** (cheap, low frame rates): torch and lantern flames flicker on bridges and dungeon entrances (8 fps), the entrance glow pulses, chimney smoke rises from the Tavern, Blacksmith, Houses, Restaurant and Forge (6 fps), and `WaterShimmer` twinkles glints on the water outside the regions (8 fps). The ground itself stays a one-time draw.
- **Forest Guardian**: a 30×35 px pixel body (`forest_guardian` in `MonsterBodies`) with a pulsing core glow (`"glow"` config drawn by `MonsterVisual`); the hand-drawn boss visual was removed.
- **Dark Forest expedition map**: the ground matches the world map's style (tufts, ferns, mushrooms, fallen leaves, worn trail with pebbles, mossy clearing with standing stones, torch-lit exit); expedition trees are pines like the world map's.
- **Weapon sprites** (`WeaponSprites`): pixel weapons (sword, greatsword, dagger, curved, shadow, fang, bow, mace, club, bone) with a grip pixel, tinted by the item. Hunters hold the sprite of their equipped weapon (by words in the item id; the class default — sword / bow / dagger / mace — without one), rotated to the animation's weapon angle; goblins hold a club, skeletons a bone sword. The line weapon remains as a fallback for unknown kinds.
- **Tavern**: candidates are a two-column board of cards ("Hunters waiting": portrait, name, talent star, class / level, stats, traits, Hire) instead of a list.
- **Nameplates**: every Hunter shows its name over its head and an HP bar while hurt; monsters show the HP bar only, bosses also their name (`ActorNameplate`, scaled against the camera zoom so it stays readable).

## D54. Oblique 3/4 buildings on the top-down grid (owner request, 2026-10-13: "isometric like Evil Hunter Tycoon"; refines D52)
- The reference game is not diamond-isometric: its ground is a flat grid and its buildings are boxes seen from the front and slightly above, with a visible side. The world therefore **keeps the D52 square grid** (geometry, navigation, footprints, doors, save data all unchanged) and only the drawing changes.
- `BuildingVisual` draws each building as a box in an oblique projection: the front wall (and plinth) stands on the front edge of the footprint; the **right side wall** recedes up and to the right (`SKEW` = 0.28 of the footprint depth) in shade, with courses and a small window; the **hip roof** is seen from above and in front — a front slope from the eave line to the ridge half-way back, the back slope and both hips behind it, shingle rows, ridge cap, eave shadow on the wall. Depth is 1:1 with the ground (a 45° view), so a 2-tile-deep building is about 100 px tall and a 3-tile one about 150 px. Only the upper box skews; the footprint, door, shadow and selection rectangle stay on the grid, so a Hunter beside the back-right corner may be hidden by the side wall (accepted).
- `TownBuilding.hit_test` covers everything drawn (`BuildingVisual.get_drawn_rect`, which includes the skewed part), not just the footprint column.
- Dungeon entrances get a receding right side on their arch; cliffs are deeper (38 px) and darker towards the water; the Town parapet is a low wall with a cap and a short front face.
- The camera starts closer (`START_ZOOM` 0.75, was 0.6) so buildings read at the reference's scale.
- Presentation only: no balance, gameplay or save schema change.

## D55. Isometric world like Evil Hunter Tycoon (owner request, 2026-10-13, with a reference screenshot; replaces the projection of D52 and the oblique drawing of D54)
- The reference town is a **2:1 isometric diamond grid**: buildings are boxes with two visible walls and steep hip roofs carrying big round emblems, on a cobbled ground with paths, gardens and props. D27's projection returns: tile 64 × 32 px, tile (gx, gy) → world ((gx − gy) × 32, (gx + gy) × 16), `WorldService.world_to_tile` is the inverse. The tile x axis runs down-right on screen, y down-left.
- Region layout, tile rectangles, gates, entrance tiles, footprints, door tiles and save data are **unchanged** (all tile-space). `WorldService.rect_polygon` returns the diamond (top, right, bottom, left); `rect_to_world` is now its bounding box and `rect_has_point` / `quad` were added. Gates carry their travel `axis` in tile space.
- `BuildingVisual` draws an isometric box: origin = the footprint's south corner (`TownBuilding.origin_for`), lit south-west face (+y side) with the door over the door tile, shaded south-east face (+x side), plinth, eave shadow, hip roof with the ridge along the tile x axis, shingle rows, ridge cap and a round emblem with the building's glyph on the front slope. `TownBuilding.get_door_point` is the door tile's centre; `hit_test` uses `BuildingVisual.get_hit_polygon`.
- Ground: diamond tiles with the same decorations; cliff faces hang below each region's two front edges (south-west and south-east), the Town's a stone retaining wall with the parapet and fence along its two back edges; bridge decks follow the corridor diamond; dungeon ledges are diamonds with faces.
- `GateVisual` rails follow the corridor's long edges one tile onto both banks. Props, actors and entrances are unchanged (upright sprites on the diamond grid).
- Camera starts at zoom 0.55 (the iso world is twice as wide); minimum zoom 0.15.
- The expedition (dungeon run) maps and the test arena keep their own top-down ground: they are separate scenes, not on the world grid.
- Presentation and geometry only: no balance, gameplay or save schema change.

## D56. Smaller map (owner request, 2026-10-13: "70% of the current size"; refines D55)
- The isometric tile is **44 × 22 px** (70% of D55's 64 × 32); tile (gx, gy) → world ((gx − gy) × 22, (gx + gy) × 11). Region sizes in tiles, layouts and save data are unchanged, so the whole map shrinks to 70% while Hunters, monsters and props keep their pixel size: the town is denser and walks are shorter, closer to the reference's building-to-character ratio.
- Building wall heights scale with the tile (`BuildingVisual.HEIGHT_SCALE`), the plinth and ridge rise are a little lower, cliffs are 26 px deep. Start zoom 0.6.

## D57. Rounded region corners (owner request, 2026-10-13, with a sketch and a reference screenshot: "still square, but with rounded corners")
- Each region's ground is its tile rectangle with the **four corners rounded along a quarter circle** (`WorldService._build_shape`: radius 6 tiles for the Town, 8 for the hunting regions); the edges stay straight, like the walled town of the reference. Tiles within 3 of a gate corridor, within 2 of a dungeon entrance and the shore around the pond always stay ground, so bridges, ledges and the pond line up. `tile_rect` stays the data (layout, gates, default tiles are unchanged); `region_tiles` / `region_tile_list` / `has_tile` / `region_outline` expose the shape.
- Everything that walks, spawns or builds uses the shape: navigation outlines are the merged shape polygons, `region_at` tests the shape, random points and monster spawns pick shape tiles, props and border trees skip cut tiles, and `BuildingService.can_place` requires every footprint tile and the door tile to be Town ground ("Must be inside the Town").
- The ground draws cliff faces, rims, the Town parapet and fence per boundary tile edge, so they follow the coast. The pond moved to the Town's (6, 4) so it sits clear of the rounded corner.
- The owner's sketch also shows a **recruit / dismiss gate** off the Town's north-west edge, a **weekly boss** area off the Ancient Ruins' north-east edge, and the portrait view at maximum zoom-out framing the Town–Goblin Cave column (`WorldCamera.MIN_ZOOM` 0.22 does that). The two new areas need their own systems (recruitment today lives in the Tavern, there is no weekly boss) and are **not built yet**; see ROADMAP.

## D58. Hunter Gate and weekly boss (owner request, 2026-10-13, from the map sketch)
- Two small regions of their own `RegionDefinition.kind` join the world: the **Hunter Gate** island (`hunter_gate`, kind GATE, 8 × 8 tiles off the Town's north-west edge, bridge Town–gate) and the **Boss Arena** (`boss_arena`, kind BOSS, 12 × 12 tiles off the Ancient Ruins' north-east edge, bridge Ruins–arena). Rounded corners like the other regions (radius = a quarter of the short side). Neither is a hunting ground: Auto duty, the hex region buttons and the monster spawners of D29 ignore them.
- **Hunter Gate**: hiring moves from the Tavern to the gate (`GateSheet`: the "Hunters waiting" board and paid refresh, unchanged rules); new recruits walk in through the gate. The gate also **expels** Hunters (`RecruitmentService.dismiss`, two taps in the sheet): the Hunter is removed for good (`HunterService.remove_hunter`, `hunter_removed`), no refund, purse and bag go with them, their bed is freed. Not while on a dungeon run, dead, or carrying a body. The Tavern keeps rest / food / drink and links to the gate. Tapping the gate arch (`HunterGateVisual`) or the HUD "Hunters Waiting" button opens the sheet.
- **Weekly boss** (`WeeklyBossService`): the arena's altar (`BossAltarVisual`) holds the Abyss Warden (`weekly_boss`, Lv 12, boss). The arena is a duty choice ("Boss Arena"); assigned Hunters fight it like any monster (killer's purse and bag get its gold and loot table). When it falls the treasury gets a chest (1500 gold; dark essence, iron ore, beast fangs into the Warehouse) and the boss returns **7 real days** later (`next_available_unix` in the save, section `weekly_boss`; missing = available). The arena spawner spawns it at the altar whenever it is due and absent. `BossSheet` shows status, rewards, assigned Hunters and sends everyone Lv 12+ / recalls them.
- Save: new `weekly_boss` section, no schema bump (missing = defaults). Balance: BONUS_GOLD / BONUS_ITEMS in `WeeklyBossService`, boss stats in `data/enemies/weekly_boss.tres`.

## D59. Full-body Hunters and more gear slots (owner request, 2026-10-13, with reference screenshots)
- **Slots** (`EquipmentService.SLOT_ORDER`): weapon, helmet, top (`armor`), pants, boots, necklace, ring, charm (`accessory`), skin, pet. `ItemDefinition.EquipmentSlot` and `ItemType` (SKIN, PET) gained values at the end, so existing .tres numbers keep their meaning; saves are unchanged (equipment maps slot name → instance).
- **The sprite wears the gear** (`ChibiDress`, built by `EquipmentService.get_dress`): the top's tint recolours the class outfit's cloth; a **skin** replaces the pattern (`outfit_id`: warrior / ranger / rogue / guardian) and colour and wins over the top; pants recolour the trousers, boots the boots; helmets draw a hat over the hair (`ChibiBody.HATS`: helm, cap, hood, wizard, crown; `look_id` or words in the id); hoods and helms hide long hair at the back. Necklaces, rings and charms have no sprite.
- **Pets** (`PetSprites`: pup, chick, slime, teddy, wisp; 12 × 11 px, tinted): trot at the Hunter's heels in the world (hop while walking, mirrored with the facing) and stand beside the figure in the UI.
- **Full figure in the UI** (`HunterFigure`, `ChibiBody.get_figure`): Hunter cards in the Hunters tab and the Hunter Gate show the whole body with gear and pet; the detail dialog's paper doll shows a large figure with helmet / top / pants / boots on the left, weapon / necklace / ring / charm on the right and skin / pet under it. The Gear tab lists every slot.
- **Items** (30 new): helmets, pants, boots, necklaces, rings and charms are Blacksmith recipes (iron ore, fangs, bone dust, slime gel, dark essence); skins and pets are recipes of the Trading Post's new **Boutique** section; the Golden Crown and the Wisp pet drop only from the weekly boss.

## D60. Tiers for Hunters, items, monsters and bosses (owner request, 2026-10-13)
- One scale (`Tier.Level`): **C** Common · **U** Uncommon · **R** Rare · **SR** Super Rare · **SSR** Special Super Rare · **UR** Ultra Rare · **LR** Legendary Rare · **MR** Mythic. C..UR can be rolled; **LR and Mythic are declared only** (set in data, never rolled). Colours in `Tier.COLORS` (also `RarityColors`).
- **Items**: `ItemDefinition.rarity` is a `Tier.Level`; the old values map 1:1 (Common→C, Uncommon→U, Rare→R, Superior→SR, Epic→SSR), so data files are unchanged.
- **Hunters**: `HunterRuntime.tier` is rolled when a candidate is generated (weights C 40 · U 28 · R 17 · SR 9 · SSR 4.5 · UR 1.5, from the candidate's own seed so the shared RNG is untouched) and saved (missing = C). Tier scales base and growth of HP / attack / defense (`Tier.STAT_SCALE`: ×1.0 … ×1.45 for UR, ×1.65 LR, ×1.9 Mythic) and the recruit cost (`Tier.REWARD_SCALE`). The card and dialog badge shows the tier code in its colour (replacing the reincarnation grade; reincarnations keep their stars).
- **Monsters**: regular monsters roll a tier on spawn (C 72 · U 17 · R 7 · SR 3 · SSR 0.8 · UR 0.2), never below `EnemyDefinition.tier`; it scales their stats, gold and XP (`REWARD_SCALE`) and adds one extra loot roll per step above R. Tier R and up show "[R]" etc. over the monster in the tier colour.
- **Bosses** have a fixed tier from data: Forest Guardian SR, Abyss Warden (weekly boss) UR.

## D61. Every text is a translation key; English and Vietnamese (owner request, 2026-10-13)
- Player-facing texts are keys (00_RULES.md §11b). Keys with their `en` and `vi` texts live in one file, `data/i18n/translations.json`; the autoload `Loc` (`core/localization.gd`, loaded first) feeds them to Godot's TranslationServer. Code uses `Loc.t(key, {placeholders})` with named `{placeholders}`; data `.tres` files store keys in `display_name` / `description`, and reading those properties returns the translated text (`get_name_key()` gives the key). Hunter names from the name pools, ids, numbers and stat abbreviations (HP, ATK, DEF, XP, Lv, tier codes) are not keys.
- Vietnamese may keep common game words in English ("semi English": Hunter, Boss, Dungeon, Skill, Pet, Skin…). Conventions and key naming: DOCS/ARCHITECTURE/LOCALIZATION.md.
- **Settings** (gear button in the top bar) picks the language; it is saved in `user://settings.cfg` (not the save game), the first run follows the OS language, English is the fallback. Changing it saves the game and reloads the main scene so every text is rebuilt; not available during a dungeon run.
- `tests/unit/test_localization.gd` checks that every key has both languages with the same placeholders and that every key used in code and data exists; the test runner forces English.

## D62. Hunter cards like the reference (owner request, 2026-10-13, with screenshots)
- The Hunters tab shows 3 cards per row (`HunterCard`): background washed with the Hunter's tier colour and a rim in it; talent star, name and the tier code (C, U, R, SR, SSR, UR, LR, MR) in the tier colour; "Lv.N", the class in its class colour (warrior orange, ranger green, rogue violet, guardian gold, others teal) and the reincarnation count in Roman numerals (hidden at 0); the full figure with gear and pet over a glow in the tier colour; what the Hunter is doing or where it hunts on a translucent band across its feet; a large "Info" button and a green Locate button with a reticle icon.
- Hunter levels are capped at **100** (`GameConfig.max_hunter_level`) on top of the Town Hall cap (10 per Town Hall level).

## D63. Market and the Hunter's loot bag (owner request, 2026-10-13)
- New building **Market** (`market`, Chợ): Town Hall Lv 1, 180 gold, 2 × 2, unique, not in the starting layout. It buys Hunters' loot into the Warehouse at `buy_price` × the item's price (Lv 1 90 %, Lv 2 80 %, Lv 3 70 %); the rest of D39 is unchanged (the treasury buys what it can afford and store, a passing trader the rest, the Hunter's purse gets the money). Hunters with loot walk to the Market's door when the Town has one, else to the Warehouse as before. The Market's panel lists every Hunter carrying loot with its value and buys one bag or all of them now. On the map: a red-roofed wooden hall with a coin-sack emblem and a striped produce stall.
- The Hunter detail dialog's **Gear tab is replaced by a Bag tab**: the loot bag's fill, each item with its icon, count and what the Market pays, and "Sell to the Market" (needs a Market). Equipment is managed from the paper doll (see D66).

## D64. Item details and weapon durability (owner request, 2026-10-13, with a reference screenshot)
- **Tapping any item icon** (paper doll, Bag tab, slot sheet, Warehouse, Blacksmith…) opens `ItemInfoModal` over the screen without closing the open sheet: name in the tier colour, a big rimmed icon with its enhancement, kind (slot or material / consumable), quality (tier), the main bonus, every bonus as a bullet, its value, durability for weapons, who wears it; buttons Repair (weapons with wear, treasury pays, needs a Blacksmith) and Change (opens the slot sheet of its wearer); tap outside or Close to dismiss. The reference's re-roll / extract options are not in yet.
- **Weapon durability**: max = 40 + 20 × tier (C 40 … MR 180); each kill in a region wears the killer's weapon by 1. At 0 the weapon is **broken**: its bonuses stop until it is repaired (icons show a red slash, the feed reports it). Other gear does not wear. Wear is saved per instance in the inventory (`wear`; missing = like new).
- **Repairs at the Blacksmith** (Thợ Rèn): cost = worn points × (1 + tier) gold. The Blacksmith's panel lists every worn weapon (worn or stored) with a Repair button paid by the treasury. Hunters whose weapon is at or below 30 % walk to the Blacksmith on their own when in town and pay from their purse (gold to the treasury); the feed reports it.

## D65. Item panel look (owner request, 2026-10-13, with the reference screenshot)
- `ItemInfoModal` follows the reference's item panel: dark brown frame with a dark outer rim, a thin gold inner rim and gold corner ornaments; a title banner lit from the middle with the name in cream; the icon in a gold frame with the enhancement as a Roman numeral (IV) over it and one star per tier step under it; "Kind / Quality / Enhanced" as lavender label + value lines (quality in the tier colour) and the main bonus in large type; a dark inner box with blue bonus bullets, gold state lines (durability bar, worn by), the value, and the item's flavour text (`item.<id>.desc` when present; the durability note otherwise); small Repair / Change buttons in the box; an orange Close button centred under it.

## D66. No slot sheet: modals straight from the paper doll (owner request, 2026-10-13)
- The intermediate slot sheet is gone. In the Hunter dialog, tapping a worn item opens its item panel (`ItemInfoModal`) directly over the dialog; tapping an empty slot opens `EquipPickerModal` (same frame: the worn item with Remove, every stored item that fits with Equip, icons open their details, orange Close).
- The item panel of a worn item has Change (opens the picker for that slot) and Remove next to Repair.

## D67. Larger, more detailed chibi Hunters (owner request, 2026-10-13: "redesign the model, more detail, still pixel chibi"; then "more pixels"; extends D49/D51)
- The chibi body grows from 15×29 to **23×44 px** (canvas 32×48 → **40×64**, feet at the bottom centre). Same six parts, views and animation tables; `ChibiAnimations.PIXEL_SCALE` (1.5) scales the tables' whole-pixel offsets, so animation data is unchanged.
- Everything is redrawn at the new size: head and face (3×5 px eyes with a shine, blush, mouth, female lash flicks), base body, the four class outfits (Warrior: steel pauldrons, red tunic, buckled belt, boots · Ranger: leather shoulder pads and bracers, quiver strap · Rogue: dyed scarf, pouch belt, slit tunic · Guardian: breastplate, big pauldrons, blue tabard with a gold cross, metal boots), 10 hair styles (highlight band top-left, strand parts, outlines in the hair's darkest tone) and the 5 hats.
- Portraits crop 27×29 px (hair, face, shoulders); UI widgets keep scaling by integer zoom, so cards and the paper doll show the bigger figure as is.
- Hunters are now about 1.4 tiles tall; staff workers (`PlaceholderVisual`) and monsters (`MonsterBodies`) keep their old size until they get the same treatment.
- Presentation only: no gameplay, balance or save change.

## D68. Colosseum (Đấu Trường): Hunter PvP 1vs1, 4vs4, 6vs6 (owner request, 2026-10-13)
- The owner explicitly requests PvP. This lifts the PvP ban of `00_RULES.md` §8 **for the Colosseum only**; online multiplayer and a backend stay out of scope.
- Formats 1vs1, 4vs4, 6vs6 against generated rival teams (offline), plus free friendly matches between the player's own Hunters. Automatic fights, time limits 60 / 90 / 120 s.
- Arena is safe: no death, injury, XP loss or weapon wear. Mood and bond change with results.
- PvP combat rules: damage ×0.8, crowd control ×0.6 with 2 s same-type immunity, healing and shields ×0.7, lower caps (dodge 25 %, damage reduction 50 %, tenacity 50 %, lifesteal 20 %, thorns 30 %, crit 75 %). New debuff Grievous (−30 % healing received).
- Ranked points per format, 7-day seasons on the weekly-boss clock, 5 tickets per format per day, Arena Tokens and a Token shop.
- English id `colosseum` to avoid confusion with the Boss Arena (D58).
- Full design: `SYSTEMS/ARENA_SYSTEM.md`. Status: design only.

## D69. Class skills: 30 per class, 7 random per Hunter (owner request, 2026-10-13)
- Each base class (Warrior, Ranger, Rogue, Guardian) has a pool of **30 skills**: 18 active (cooldown, cast by the Hunter's AI) and 12 passive. Each skill scales with one main stat (ATK, DEF, Max HP, ASPD, MSPD, CRIT, CRITDMG, RANGE, Level or Gold Find).
- A Hunter has **up to 7 skills, chosen at random** from the pool (no duplicates). Superseded by D70: skills are opened one by one with skill points, not rolled at recruitment.
- Every skill carries a 1–3 star rating for three contexts: monsters, people (Hunters and humanoid monsters) and bosses. Bosses turn hard crowd control into **Stagger** (+10 % damage taken), take half effect from soft crowd control, and cap % max-HP damage at 150 % of the source's ATK.
- Class skills are separate from the gold-bought Academy skills (`data/skills`, D50), which stay as they are.
- Full list, formulas and balance rules: `guide/skills_guide.html` and `guide/skills_guide.md`. Status: implemented (D70).

## D70. Mana, skill levels, skill points and reincarnation swaps (owner request, 2026-10-13)
- **Mana**: Hunters get `max_mana` (100 + 2 per level) and `mana_regen` (5/s, ×3 out of combat) through the stat pipeline. Active class skills cost mana (`8 + 1.5 × cooldown` at level 1).
- **Skill levels**: every class skill goes from level 1 to **6**. Power = `1 + 0.15 × (level − 1)` (×1.75 at level 6) on damage, heals, shields, passive bonuses and effect durations (debuffs get half the bonus); mana cost +6% per level.
- **Skill points**: 1 point every **10 Hunter levels**. A point either opens a **random** new skill of the class pool (max 7) or raises one owned skill by a level. Recruits start with no skills.
- **Reincarnation at level 100** (was 20 in D50): back to level 1, class skills and levels kept, unspent points kept, **+1 swap point** saved per Hunter. A swap replaces one skill (same slot, same level) with a random skill the Hunter does not own. Points are earned again in the new life.
- Combat additions: `dodge`, `tenacity`, `range_bonus` and `healing` stats; `EnemyDefinition.tags` (humanoid, undead, beast, slime) for `vs_<tag>` conditions; Stagger replaces hard crowd control on bosses; soft debuffs from skills last half as long on bosses and %-max-HP damage over time deals ×0.25 to them.
- Known limit: Town Hall tops out at Lv 5 (level cap 50), so level 100 is not reachable yet; Town Hall Lv 6–10 are needed.
- Code: `ClassSkillDefinition`, `ClassSkillService`, `ClassSkillCaster`; UI in the Hunter dialog's Skills tab. Rules: `SYSTEMS/CLASS_SKILL_SYSTEM.md`.
- Save: new Hunter fields `class_skills` (ordered [id, level] pairs), `skill_points`, `skill_swap_points`, `skill_point_level`, `current_mana`; missing = defaults, and older Hunters receive the points for their current level. No schema bump.

## D71. Merge of the 2026-10-15 visual branch into this line (owner decision, 2026-10-15)
- A parallel branch (commit f104f06: top-down map redesign, active skills, monster gear, building / prop / scenery redraws, double-density sprites, menu pictures) was merged into this line. The owner chose **this line as the base**: the isometric world (D55–D57), class skills (D69–D70), localization (D61), the chibi Hunters (D67) and every UI sheet stay as they are here. That branch's decisions were numbered D54–D63 there; they are not part of this log except as summarised below.
- **Kept from that branch** (they do not depend on the map projection):
  - Props (`WorldProp`) redrawn: leafy trees with apple / blossom variants, pines with saw-tooth tiers and cones, boulders with moss and a hidden crystal, broken fluted columns with ivy and rubble; the variant comes from the prop's position.
  - Monsters (`MonsterBodies`, `MonsterVisual`) and weapons (`WeaponSprites`) at **2 texels per world pixel** (EPX upscale, `tools/upscale_pixel_maps.py`) with one-texel silhouette outlines (`tools/thin_outlines.py`); goblin, skeleton, wolf and slime redrawn; monsters puff up when they use a skill; the Forest Guardian's core glows. Drawn at 1 / SCALE, so world sizes, grips and reach are unchanged; `ChibiVisual` draws weapon sprites with that scale.
  - UI icons (`PixelIcons`, `ItemIcons`) as 24×24 texel bitmaps laid out at 12 × scale px (`ImageTexture.set_size_override`), sharper on dense screens; layouts unchanged.
- **Dropped** (superseded here or tied to the top-down grid): the active-skill system and its 130 skills (class skills cover it), monster gear items, the top-down ground / buildings / bridges, the scenery around the map, the hunting-region landmarks, the Town decorations and the menu building pictures. They remain in the history of f104f06 and can be ported to the isometric world later.

## D71. Monster loadouts and ground loot (owner request, 2026-10-15)
- Every region monster (not bosses) rolls a `MonsterLoadout` at spawn: weapon / armor / accessory (only types with `can_equip`: goblins and skeletons; wolves and slimes carry none), gold, the materials of its loot table, **2 skills** out of its type's pool of **10** (`data/monster_skills`, `MonsterSkillDefinition`), and meat (`monster_meat`).
- Gear adds flat/percent stats; passive skills add percent stats; active skills are cast by `MonsterSkillCaster` (cooldowns, damage through `CombatService.resolve_skill_hit`, status effects).
- On death the loot is not credited: `RegionService.record_kill(..., loadout)` returns it with `on_ground = true` (XP is still immediate) and the world drops a `LootDrop` (gold, materials, meat, each worn item with 50% + 5% per tier). Hunting Hunters with no target walk to the nearest drop in their region and pick it up (gold into the purse, items into the bag as far as it fits); drops fade after 90 s.
- `monster_meat` is a material; the Tavern cooks `monster_steak` from it.
- The monster info sheet shows its gear, gold, skills, carried materials and meat.
- (2026-10-15) Bosses (Forest Guardian, Weekly Boss) also roll a loadout: always weapon + armor + accessory from high-tier pools and 3 of their 10 skills. The monster dialog (`MonsterDialog`, like the Hunter dialog) shows the monster's picture, gear slots (tap an icon for its details), HP, and tabs Info / Skills / Items. A cast skill floats its name over the monster. Dungeon (expedition) monsters carry a loadout too (rolled when they spawn); what they carry goes straight into the expedition stash when they die (`ExpeditionService.record_kill(enemy, loadout, tier)`; bosses keep their special loot tables and add their worn gear), and they can be tapped to inspect.

## D72. Colosseum phase 1 (owner request, 2026-10-16; implements part of D68)
- Built: the `colosseum` building, `ArenaService`, safe 1vs1 matches (generated rivals or an own Hunter), a replay view and the result; details in `SYSTEMS/ARENA_SYSTEM.md` §14.
- Deviations from the design: the fight is simulated from stats (no actors, skills or movement yet); the minimum Hunter level is 5 (design: 10, `GameConfig.colosseum_min_level`); no ranking points, tickets, rewards, Token shop or 4vs4 / 6vs6.
- Not verified by eye: the replay and result screens were only exercised by unit tests (screenshots of them were not captured).

## D73. Character Forge replaces the chibi Hunter art (owner request, 2026-10-15; replaces the art of D49/D51/D67, keeps their APIs)
- **Source of truth**: the owner's HTML tool `tools/character_forge/pixel-character.html` ("Pixel Hero Forge"). Its data is exported by `tools/character_forge/export_forge.js` to `actors/hunter/forge/forge_data.json`; golden fixtures for tests go to `tests/fixtures/forge_golden/`. Art changes are made in the HTML, then re-exported.
- **Body**: about 16×35 px (traced from the owner's reference), one 3/4 view facing left, placed on the existing 40×64 canvas with design (x, y) → canvas (x + 10, y + 27), feet at `ChibiBody.FEET`. Hunters are ~20% shorter than the D67 body; they stay 1:1 with world pixels (no fractional scaling).
- **Facings**: two-direction sprites. LEFT is the native art, RIGHT is its mirror (weapon and effects mirrored too); DOWN and UP reuse the last horizontal side. A back view is a later phase and must be added to the HTML first. `ChibiBody.View` stays for other users (MonsterBodies).
- **Fixed detail levels** (mixed resolution, exact because 1 character pixel = 30 units): body, hair, pants, shoes 1×; tops (with hoods and posed sleeves) and hats 1.5×; glasses 2.5×; Hunter weapons, arrows, quiver 2×. Frames are baked as runs of same-resolution layers and drawn with a 1/res transform.
- **Content**: 18 hair styles (indices 0–9 keep their slot, 10–17 appended; `HAIR_STYLE_COUNT` = 18), 14 tops + tank top, 5 pants + shorts, 5 shoes + barefoot, 7 hats (+ `helm` and `hood` variants to be added to the HTML; `hood` maps to `beanie` until then), 5 glasses, 9 weapons (sword, greatsword, katana, dagger, axe, hammer, spear, staff, bow) drawn geometrically at any angle, 7 attack sequences by weapon and 6 element effects (none, fire, ice, thunder, poison, shadow).
- **Mapping**: class outfits warrior→armor, ranger→jacket + cargo + boots, rogue→hoodie + jeans + leather shoes, guardian→knight + armor pants/boots; item `look_id` may name any Forge top / pants / shoes / hat; gear tints recolour as before. **Glasses** come from an `accessory` (charm) item with `look_id = glasses_<round|square|sun|goggle|patch>` (new `ChibiDress.glasses`). **Element** of attack effects comes from a weapon `look_id` suffix (`_fire`, `_ice`, `_thunder`, `_poison`, `_shadow`) or the skill being cast; no new gameplay field. Monsters keep `WeaponSprites`; pets keep `PetSprites`; the Guardian shield keeps its vector drawing.
- **Animations**: names and priorities unchanged; `ChibiAnimations.PIXEL_SCALE` = 1.0; ATTACK plays the weapon's Forge sequence (per-frame durations); SKILL with a staff plays `cast`.
- **Old chibi art removed** once tests pass (`ChibiBody.BODY`, `OUTFITS`, `HAIR_STYLES`, `HATS` maps); no parallel fallback.
- Presentation only: no gameplay, balance or save schema change (appearance indices and gear stay as saved).

## D74. Mountain range removed (owner request, 2026-10-16)
- The `MountainRange` scenery behind the north-west coast (WORLD_DESIGN.md, 2026-10-16) made the game lag, so it is removed: `world/world/mountain_range.gd` deleted and no longer added by `world.gd`. That water is plain sea again.
- Presentation only: no gameplay, collision or save change.

## D75. Forge attack effects, gear looks, landmarks, water scenery, lighter world drawing (owner request, 2026-10-16)
- **Attack effects** (PHASE_13 step 6): `ForgeFx` ports the Forge tool's effects 1:1 (slash crescent, ground rings, burst, glow, X mark, element particles, spell column with lightning / ice spikes / poison / shadow, weapon aura; mulberry32 random numbers checked against the JS). They are baked into the attack frames like the body: one bake per frame at mid-frame progress, time = the frame's start in the sequence, seed 3. Golden fixtures `attack_*` and `fx_<element>_<slash|strike|rest>` cover every element.
- **Element of the effects** (D73 / Q5): the weapon's `look_id` suffix, or, while a class skill plays, the skill's element from the first status it applies (burn → fire; freeze, slow → ice; stun, stagger → thunder; poison → poison; weaken, vulnerable, lifesteal → shadow). Support skills (no enemy target) now play the SKILL animation.
- **Gear looks**: existing items name their Forge style (`look_id`): Shadow Blade `sword_shadow`, Fang Blade `katana`, Iron Greaves armor pants, Shadow Leggings jeans, Leather Pants cargo, Iron Boots armor, Leather Boots boots, Swift Boots sneakers, Snow Robe robe, Crimson Suit vest. A skin's look wins over the top's. New Blacksmith gear (BALANCE.md → Equipment): Battle Axe, Iron Spear, Oak Staff, Ember Staff (fire), Round Glasses, Eye Patch, Hunter Goggles, Straw Hat (nón lá), Cowboy Hat, Viking Helm; item icons for axe, spear, staff and glasses.
- **Landmarks** (D62 back on the isometric map): Dark Forest shrine, stumps and logs; Goblin Cave two camps of tents around a campfire, skull totems; Ancient Ruins rune obelisk, broken arches and statues. Placed at fixed fractions of each hunting region (moved to the nearest free ground), navigation obstacles like the props; none in the boss arena.
- **Water scenery** (from D61): a lighthouse islet, a shipwreck, islets with trees or palms, sandbars, rocks, drifting logs and kelp, placed with a fixed seed in open water inside the camera bounds, away from land, cliffs, bridges and dungeon ledges. Each piece is its own small node.
- **Lighter drawing** (after D74): the world ground is split into child nodes (water, cliffs / tiles / rims of each region in strips of 8 tile diagonals back to front, bridges, pond) so parts off screen are culled instead of one huge drawing every frame; Town lamps, fountains and camp fires redraw at 8–12 fps and only on screen; Hunters redraw only when their frame, breath, blink or effects change.
- Gameplay: only the new items and recipes (data). No save schema change.

## D76. Rear view, real helm / hood, chibi art removed, gear drops, ambience, skill effects (owner request, 2026-10-16)
- **Rear view** (replaces "a back view is a later phase" of D73): the Forge tool has `composeRear` (toggle "Sau lưng"): the same 3/4 silhouette with no face or glasses, hair filled over the head down to the ear line (`rearHair`, every style; the nape stays below), the weapon behind the body, quiver, hood and long hair over the back; hats may have their own rear parts (`rear`) or keep some parts (`rear_keep`). Exported as `body.head_rear`, `hair[].rear`, hat `rear` / `rear_keep`; golden `rear_*`. Hunters facing up show it (mirrored by their last side); attacks and lying bodies keep the front view.
- **Helm and hood** are real Forge hats (D73 / Q4 closed): an iron helm with rivets, nose and neck guards (seen from the back without the nose guard), and a hood around the face that hides all hair (seen from the back as a closed hood).
- **Old chibi art removed** (D73 / Q6, PHASE_13 step 7): `ChibiBody` keeps only the skin and hair colour tables, the class outfit list, hat styles of helmets and the View enum used by monster bodies; `ChibiDress.ramp` is gone; UI and tests use `ForgeLook.figure`.
- **Gear drops** (BALANCE.md → Enemies): goblins, wolves, slimes and skeletons drop the D75 gear rarely (0.8–3%).
- **Ambience** (from D61): cloud shadows drift over the map, gulls circle the islets, a rowing boat rocks by a palm islet, the lighthouse lamp pulses with a sweeping beam. One node per piece; clouds and gulls move by position, the rest redraws at 10 fps only on screen.
- **Skill effects**: monster skills show a Forge pixel effect in their element (status effects, else words in the id): a burst with particles on the target (damage), a shock wave around the monster (slams, novas, storms, shatters, quakes), a spell column on the target (effects only) or an aura on the monster (heals, buffs); Hunters' support skills glow on the caster. Frames baked once per kind and element (`SkillEffect`).
- Presentation only, except the loot table entries.

## D77. Forge acolytes, building pictures, sprite sheets, barber, day and night, class skill effects (owner request, 2026-10-16)
- **Village staff** are Forge characters: Temple acolytes in a pale robe and a hood, empty-handed, face and hair from their id; they walk while they move (`StaffWorker`).
- **Build menu** shows each building's picture (`BuildingThumb`: the map's BuildingVisual on a plate, dimmed when it cannot be built).
- **Sprite sheets** of the Forge are rendered by `tools/character_forge/export_sheets.js` (Node, the original engine, PNG to the git-ignored `build/forge_sheets/`) to check the art without Godot.
- **Barber** (Hunter panel → Barber): browse the 18 hair styles and 10 hair colours on a preview, pay `GameConfig.restyle_cost` (100 gold) to keep them (`BarberService`); refused while away on an expedition, fallen, or for the same look. Saved with the Hunter; no stat effect.
- **Day and night** follow the in-game clock (`ProgressService.day_time`, `day_length_seconds`): white day, warm dusk and dawn, blue night (`DayNight.TINTS`). A multiply layer tints the world and an additive layer lights lamps, camp fires, the shrine, the obelisk and the lighthouse as the night falls; both are drawn once and only their modulate changes. UI, skill effects, status icons and popups stay above the shade.
- **Class skill effects**: area skills a shock wave where they land (around the caster, or the target), single-target skills a burst on the target (a spell column when they only debuff), taunts a shock wave on the caster, heals / shields / buffs an aura on up to 4 helped allies; all in the skill's element (`ClassSkillCaster._play_effects`).
- Gameplay: only the barber (gold for looks). No save schema change (appearance fields already saved).

## D78. Synthesized audio (owner request, 2026-10-16)
- **No audio files**: sound effects and music are synthesized from data (`data/audio/sfx.json`, `data/audio/music.json`) by `SoundSynth` (chiptune voices: square, triangle, saw, sine, noise; sweeps, arpeggios, vibrato, envelopes, low-pass), so nothing needs importing or licensing. `tools/audio/preview_audio.py` renders the same data with the same algorithm to WAV for listening without Godot.
- **Audio autoload**: buses Music and SFX with volumes in `user://settings.cfg` (Settings sheet sliders, 0 mutes); 12 effect voices; every sound keeps a minimum interval (`cooldown`); world sounds only near the screen, quieter towards its edge, ±5% pitch. Effects render on first use; music tracks render once on a worker thread and loop, cross-fading on change.
- **Music** follows the camera: town (day) / night (Town at night) / wild (hunting regions, dungeon runs) / boss (boss arena). **Sounds**: button click, error toast, hit / critical / dodge, monster and Hunter deaths, loot picked up, bag sold, level up, building placed / upgraded, item crafted, Hunter recruited, dungeon start / end, weekly boss defeated, class and monster skills by element, heals (AUDIO_DESIGN.md tables). Village events stay silent while a save loads.
- Presentation only; no save data.

## D79. Readability and feel pass: monsters, UI rules, buildings, camera, combat feedback (owner request, 2026-10-22 → 2026-10-23: "cải thiện UI và char, quái", then UX / HUD / movement / facings; written without Godot on hand, validation pending)
- **Monster bodies** (`MonsterBodies`): the wolf is redrawn (ears, muzzle, four legs, thin curled tail, back highlight, pale belly, tongue; new palette symbol `p`); goblin (open grin with fangs, nose, slanted eyes, belted loincloth, symmetric legs; `h` highlight cleared on the back) and skeleton (dark sockets `n`, nasal hole, ribcage over a dark cavity, separate leg bones; `n` cleared on the back) are rebuilt from shapes; the slime gets a mouth and a second shine; the Forest Guardian gets a shaded right side, scattered bark cracks, a jagged maw, slanted eyes and a bevel ring around its core (the `glow` point is unchanged). Canvas sizes are unchanged.
- **UI rules enforced** (UI_DESIGN.md): no text under 10 px (`GameTheme.SMALL_SIZE` in the gate, Hunter and monster dialogs), every button at least `GameTheme.TOUCH` (40 px: gate hire / expel, inventory and dialog tabs, sheet close, profile remove, the header icon buttons); "DPS" is the key `ui.hunter.dps`.
- **Buildings** (`BuildingVisual`): light spills from the windows onto the wall and the glass has a reflection; a wall lantern hangs left of every door (not the warehouse; replaces the inn's own); a contact shadow sits where the walls meet the plinth; the front roof slope darkens towards the eave and each shingle row has a lit edge. **Ground** (`world_ground.gd`, drawn at run time): moss creeps down from the cliff lips; dirt roads have worn darker / lighter patches (hashed per tile).
- **Facing** (`Facing.from_vector`, D20): switching between the side pair and the front / back pair needs the new axis to dominate by `HYSTERESIS` 1.25, so a path wobbling around a diagonal no longer flips the sprite every step. Ties still prefer vertical; a zero vector keeps the current facing.
- **Camera** (extends D28): following eases towards the target (`FOLLOW_SMOOTHING` 7 / s, frame-rate independent) instead of snapping each frame; entering a dungeon snaps. A followed actor is centred in the band of the screen the HUD and an open sheet leave free (`WorldCamera.cover_bottom`, fed by `UIRoot.sheet_cover_changed`; not part of the zoom-out limit). Hunter and monster dialogs are bottom sheets of `DIALOG_HEIGHT` 78% of the viewport (no longer full screen) so the tapped Hunter stays in view above them. The nav "Town" button turns gold while the camera's centre is outside the Town's bounds plus `AWAY_MARGIN` 80 px (`WorldMap.camera_away_changed`, polled 4× / s).
- **HUD**: the expedition HUD shows a section progress bar (full at the boss and on the way back); the chest chip's count turns gold while quests have rewards to claim.
- **Toasts and the event feed**: fade in; a repeat of a line still on screen bumps a "×N" counter on it (`ui.root.repeat_count`) and restarts its timer instead of adding a line; repeated errors do not replay the error sound.
- **Movement**: the walk / run cycle plays at the actor's real speed over its base speed (`ActorVisual.step_scale`, 0.5–1.6), so slowed or hasted actors (and monsters) do not slide.
- **Combat feedback** (`CombatFeedback`, `DamageNumber`): numbers scatter ±6 px sideways; critical hits scale in from 1.6× (`punch`); hits on one target within `MERGE_WINDOW_MS` 350 ms add into the same number (`absorb`; effect ticks, heals, misses and immunities stay separate). Monsters are shoved 3 px away from a hit (`ActorVisual.play_knockback`, sharing the lunge tween; Hunters are not). The screen shakes on a boss skill (5 px, 0.35 s) and when a Hunter goes down (4 px, 0.3 s) via the current camera's `offset` (`CameraShake`); Settings → Display → "Screen shake" turns it off (`SettingsStore`, section `display` of `user://settings.cfg`, next to D78's audio volumes).
- **Nameplates** (`ActorNameplate`): a pale trail behind the HP fill catches up after a hit (`GHOST_SPEED` 1.2 bars / s; none for damage taken before the plate existed); the name turns gold while the actor is selected; bosses get a 12 px name with a thicker outline and a 52 px bar. Loot popups above common are 12 px; the level-up burst has two rings.
- **Shadows** (extends D77): actor shadows follow the hour's sun (`DayNight.shadow_of`): leaning east at dawn, short at noon, leaning west at dusk, faint at night (`DAYLIGHT_END` 0.68). They and the selection ring are drawn in the actor's space (`ActorVisual.draw_shadow` / `draw_selection`), so a lunge, knockback or flourish moves the body but not its shadow (local-transform notifications trigger the redraw). Building shadows are unchanged.
- Presentation only: the settings file gains a `display` section; no save schema change. Tests cover the facing hysteresis and the sun shadows; the rest is to be checked in Godot (360 × 640) before it is relied on.

## D80. Stat grades: colours by the average, tier by total (owner request, 2026-10-23: a colour ladder grey → white → blue (average) → deep blue → orange → red → gold → sky → emerald → violet; stats coloured against the average, objects tiered by their total; averages built per kind)
- **Ladder** (`StatGradeService.Step`, BALANCE.md → Stat grades): ten steps by value / average, blue being average; the violet top step is the "luxury" colour and may be changed. Steps have names (`grade.<id>.name`, Poor … Supreme).
- **Averages** are not hand-written: built from the data when the game loads. Hunters per level from every class definition (tier C, no gear, no rolls, through `StatService.compute_stat`); monsters from the regular enemy definitions (HP / ATK / DEF at the level and tier scale); gear per equipment slot from the items that carry the same bonus (flat and percent apart). A stat with no average, or an item with no bonus, counts as average.
- **Total**: weighted mean of the stat ratios (HP, ATK, DEF 1; attack speed 0.5; crits and move speed 0.25; each ratio capped at 8) → one step for the whole Hunter / monster / item, shown as "Grade: …". It does not replace the rolled tier (D60): the tier is what the object *is*, the grade is how it *measures up* now (level, gear, buffs included for Hunters).
- **Shown** in the Hunter dialog (each stat value in its grade's colour, a grade line), the monster dialog (same; bosses read high against regular monsters) and the item details (a Grade fact, each bonus line in its colour; broken gear keeps the dim note colour).
- **Choosing gear** (`EquipPickerModal`): every stored item shows its grade and how it compares with the worn item, as the difference of their totals in percent of an average item's bonuses ("▲ +40 % vs worn" green, "▼" red, "=" grey, "slot is empty" when nothing is worn); Forge enhancement counts (every bonus scales by `ENHANCE_BONUS` per level). The Hunters tab colours each card's level by the Hunter's grade (name in the tooltip); the Gate colours each candidate's HP / ATK / DEF and shows its grade.
- **Everywhere else**: the Hunters tab sorts by grade (fourth sort mode); the Warehouse lists spare gear best first; a monster's name plate takes its grade's colour and a regular monster graded Strong or above shows its grade as its name; "{name} now grades …" toasts when a Hunter measures up to a higher grade; class skills get a grade bar under their icon (the mean of their display stars against the skills of their kind); the equip picker calls out broken gear (a broken worn piece makes any candidate an upgrade); "Wear best gear" in the Hunter dialog puts on every stored piece that grades above the worn one (`suggest_gear`).
- Evaluation and colour only: no combat number changes; no save data. `GameManager.grades` holds the service; tests in `test_stat_grade.gd`. Written without Godot on hand, validation pending.

## D81. Dungeon HUD, toast icons, Lv3 buildings, idle strolls (owner request, 2026-10-23; written without Godot on hand, validation pending)
- **Dungeon HUD** member cards add a mana bar (`ManaBar`) and a row of dots, one per status effect on the member, in the effect's colour (D48).
- **Toasts** may lead with a pixel icon (`UIRoot.toast(text, is_error, icon)`): buildings and level-ups a hammer, quests a book, requests the shop, recruits and bonds the Hunters icon, recoveries a bed, deaths and deliveries a skull, awakenings a star, grade-ups a trophy. Repeats still merge (D79).
- **Buildings** (extends D55): Lv2 opens a second window on the shaded face; Lv3 raises the plinth to 7 px, flanks the door with a pair of lanterns and caps the ridge in the trim colour with a finial.
- **Town life**: an idle Hunter at home strolls to a spot within 56 px now and then (8 % per think) and comes back; any order, need or duty still takes over at once (`HunterBrain._stroll`). Presentation only.
- Not done without Godot: the Hunter front view (Forge art needs rendering), the baked ground.

## D83. Summoning tickets, the active cap and the Hibernation Mount (owner request, 2026-10-23; written without Godot on hand, validation pending)
- **Summoning** replaces gold hiring as the main way in: the Hunter Gate spends **summoning tickets** (`WalletService.summon_tickets`, saved; `GameConfig.summon_ticket_cost` 1) to call a random base class with a rolled tier (`RecruitmentService.summon` / `summon_many` for ×10). The newcomer walks in through the Gate. The Tavern's gold board (D11) stays as a secondary way in and obeys the same active cap.
- **Tickets**: a new village starts with `GameConfig.start_summon_tickets`; **1000 for now, the owner's test value**. Saves older than schema 4 get the same allowance when migrated. No drop sources yet (to design: boss clears, quests, shop).
- **Active cap**: at most `GameConfig.active_hunter_cap` **24** Hunters awake in the village (hunting, training, living), never above the Town Hall capacity (`RecruitmentService.get_active_cap`). **Hibernation cap**: `GameConfig.hibernation_cap` **100** sleepers. A summon that finds no active slot or no free bed puts the newcomer to sleep; when both the village and the Mount are full, summoning refuses.
- **The Hibernation Mount** is a region of its own kind (`RegionDefinition.Kind.MOUNT`, `data/regions/hibernation_mount.tres`, 10 × 10 tiles at (−11, 16)): just below and left of the Hunter Gate island on the screen, two tiles away, so `WorldService._find_gates` lays a bridge between them like any other pair. Rock biome, a few rocks, a snow-capped hill with a cave mouth and drifting z's at its centre (`HibernationMountVisual`); tapping it opens the hibernation sheet. No baked ground (procedural tiles).
- **Sleeping** (`HunterRuntime.hibernating`, saved): a sleeper has no needs, mood, activity, duty, XP or bed, cannot join a party, the arena or a dungeon, and does not count as active. Its brain walks it to its own spot on the Mount (spread over the hill by id, clear of the cave) and keeps it there (`task = HIBERNATING`). `hibernate` / `activate` / `swap` on `RecruitmentService` move Hunters between the village and the Mount; **they walk** there and back over the bridge, nothing teleports. Waking needs an active slot and a bed.
- **UI**: the Gate sheet shows tickets, Summon ×1 / ×10, where each newcomer went and the roster with Expel; the Mount sheet lists sleepers (Wake), the awake (Sleep, Swap… then pick a sleeper); the Hunters tab shows sleepers in their own section with the status "Hibernating"; the HUD chip counts awake / active cap.
- **The reveal** (owner request, same day): summoning is two-phase. ×1 / ×5 / ×10 call a batch (`summon_batch`: tickets spent, village-or-Mount fixed) that joins only on **Confirm** (`confirm_arrivals`). With effects on (Settings / the Gate's toggle, `SettingsStore.summon_effects`), `SummonRevealModal` shows a stack: one cover card on top, then a face-up but dimmed card per newcomer. Drag the top card any way; let go early and it eases back over 0.6 s; drag past 80 % of the card and it flies off while the card beneath flashes in its tier colour and pops. With effects off, straight to the summary: every card, tap one for details (tier, class, graded stats, traits, talent, where it will go), Confirm. Closing the reveal any other way also confirms (the tickets are spent).
- **Arrival**: confirmed newcomers come down at the Gate **one by one in call order** (`WorldMap._next_arrival`): a light column at the summoning circle (`SummonColumn`) climbs through the tier colours up to the newcomer's tier, the Hunter drops from 56 px with a small camera shake, then its brain walks it into the village or over the bridge to the Mount.
- Save schema **4** (tickets, `hibernating`); migration keeps every older village. A batch pending in the reveal is not saved: killing the app during the reveal loses it (tickets spent) — to be covered when ticket sources are designed.
