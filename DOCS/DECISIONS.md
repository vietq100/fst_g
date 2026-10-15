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

## D54. Chibi face and class skills (owner request, 2026-10-15; extends D49, COMBAT_SYSTEM.md) — skills superseded by D55 the same day; the head redesign stands
- **Head redesign**: the chibi head keeps its 15×13 box and parts, with bigger eyes (lid, white + iris, iris; iris = hair colour), blush, a nose and a mouth. Eye rows are 7–9 (`ChibiBody.EYE_ROWS`); the back view clears the face, the side view keeps the near eye. Hair maps are unchanged.
- **Class skills**: every base class has one signature skill (`HunterDefinition` → Class skill; subclasses use their base class's). It replaces every `skill_every_attacks`-th attack of the Hunter (`CombatController.attack_override`, `CombatService.resolve_skill`): a damage multiplier on the target and, for area skills, on the nearest enemies within `skill_radius` of it (up to `skill_targets`), plus an optional status effect on everyone hit. Numbers in BALANCE.md → Class skills.
  - Warrior **Power Slam** (`skill_slam`): overhead slam, 1.8×, hits up to 4 enemies within 36 px, ground shockwave.
  - Ranger **Arrow Volley** (`skill_volley`): draws and releases three arrows, 1.1× on up to 3 enemies within 90 px of the target.
  - Rogue **Shadow Strike** (`skill_dash`): crouch, dash with afterimages, crossed double cut, 2.2× on one target + Bleed.
  - Guardian **Shield Bash** (`skill_bash`): shield raised and thrust, 1.4× on up to 3 enemies within 30 px + Stun.
- Visuals: one ChibiAnimations one-shot per skill (same priority as attack) with in-sprite effects (charge, shockwave, draw / release, afterimage, xslash, bashring) and a world `SkillVfx` (shockwave ring, arrow streaks, shadow burst, stun stars) spawned by `CombatFeedback` on `CombatService.skill_used`.
- Monsters have no skills. Save schema unchanged (attack counters are scene-only).

## D55. Active skills, monster gear and models (owner request, 2026-10-15; replaces the skill part of D54)
- **Active skills are data** (`ActiveSkillDefinition`, `data/active_skills/<owner>/`, registry category `active_skill`): owner class, unlock level, cooldown, damage multiplier, radius / targets, effect on targets, effect on self, self heal, animation, VFX kind. **30 per class** (Warrior, Ranger, Rogue, Guardian; subclasses use their base class's), unlocked by Hunter level 1–30, and **2 per monster** (`EnemyDefinition.skill_ids`). Generated from one table (`tools/gen_active_skills.py`, run with `python3 tools/gen_active_skills.py data/active_skills`) so numbers stay consistent; descriptions are derived from the numbers.
- **Loadout**: a Hunter fights with 2 skills (`ActiveSkills.SLOTS`): the player's picks (`HunterRuntime.active_skills`, saved, optional field) when still valid and unlocked, otherwise the two highest unlocked. The Hunter dialog's Skill tab shows the slots and the whole class list; tapping an unlocked skill equips it.
- **Use**: `CombatController.attack_override` → `Actor._strike`: the first ready skill (per-skill cooldowns ticked in `_physics_process`, first use immediate) replaces the plain attack, else `resolve_attack`. `CombatService.resolve_skill(attacker, target, skill)` applies damage × multiplier to the target and the nearest enemies within the radius, target effects, self effect and heal, and emits `skill_used`. Buff-only skills (damage 0) hit nobody. Hunters and monsters share this code.
- **Presentation**: 8 chibi one-shots (slam, volley, dash, bash, thrust, spin, cast, leap) with in-sprite effects; monsters puff up (`MonsterVisual.play_action`). World VFX by kind (`SkillVfx`: shockwave, earth, arrows, shadow, bash, flame, frost, poison, holy, lightning, wind, blood, heal).
- **Monster character layer**: `EnemyDefinition` gains `weapon_id`, `armor_id` (real `ItemDefinition`s: Goblin Club, Bone Blade, Wolf Pelt, Bark Plate), whose stat modifiers apply to the monster (D18 rule) and whose weapon shows in its hand; `gear_drop_chance` lets one piece drop into the killer's bag (sold with the bag). The coins a monster carries are its existing `gold_min` / `gold_max`.
- **Models**: goblin, skeleton, wolf and slime pixel bodies redrawn with more shading and detail (D53 bodies replaced).
- Balance: BALANCE.md → Active skills. Save schema unchanged (new field optional).

## D56. Double texel density for characters, monsters and weapons (owner request, 2026-10-15; extends D20, D49, D53, D55)
- Every pixel map of Hunters (`ChibiBody` body, outfits, hair), monsters (`MonsterBodies`) and weapons (`WeaponSprites`) is at **2 texels per world pixel** (`SCALE := 2`): the Hunter canvas is 64×96 texels (body 30×58), monsters and weapons are twice as wide and tall. The maps were converted once with the EPX / Scale2x rule (`tools/upscale_pixel_maps.py`), which rounds diagonals; new detail is drawn directly at this density.
- **World size is unchanged**: textures are drawn with a 1 / SCALE transform, so a Hunter still covers 32×48 world pixels and all gameplay distances, hit boxes, hands (`ChibiBody.hand_position`), weapon reach (`WeaponSprites.length_of`) and nameplate heights stay the same. Animation offsets stay in world pixels and are multiplied by SCALE when composing.
- **Display** (replaces D20's stretch mode): `window/stretch/mode = canvas_items` (integer scale kept), so 2D is rendered at the device resolution and the half-size texels are visible (a 1080 px wide phone shows 3 screen pixels per world pixel). The desktop test window is 720×1280 (2×).
- UI icons (`PixelIcons`, `ItemIcons`) follow the same rule: 24×24 texel bitmaps (EPX from the 12×12 set) whose textures lay out at 12 × scale px through `ImageTexture.set_size_override`, so no layout changes and the detail shows on dense screens. Save data unchanged.

## D57. Map redesign (owner request, 2026-10-15; extends D52)
- **Ground colour from noise**: each region's tiles take their colour from two octaves of smooth value noise blended through a per-biome palette (dark / mid / light / detail, `world_ground.gd` BIOMES keyed by `RegionDefinition.props`), so the ground reads as soft patches instead of a tile grid.
- **Water**: deep water (clear colour `163846`) with three lighter shallow bands around every plateau, sparse wave marks, foam lines at every cliff foot.
- **Plateaus**: cliff faces 40 px deep in earth bands with rock blocks, roots and hanging grass; the Town's retaining wall has staggered blocks, buttresses every four tiles, moss and a capstone. Every region has an inner edge shadow and a lit top rim.
- **Town**: dirt roads with a dark border, worn patches, wheel ruts along the road, pebbles and grass overhang; **footpaths from every building door to the nearest road or plaza** (4-way shortest path around the other buildings and the pond, recomputed when the layout changes); a cobbled plaza with a curb and a compass mosaic in front of the Town Hall; grass tufts, flowers, clover and pebbles; rounded pond.
- **Hunting regions**: dirt trails (paler in the Ruins) from every bridge and dungeon entrance to the region centre — props keep off them; Dark Forest leaf litter, ferns, mushrooms, roots and moss; Goblin Cave gravel, cracks, stones, bones and glowing crystals; Ancient Ruins two-tile paving slabs, a third missing (grass), cracked or mossy.
- **Decorations** (`WorldDecor`, no collision, y-sorted): lamp posts at the plaza corners and along the roads, benches and flower planters beside the plaza; hidden while a building stands on or next to them.
- Designed against a Python preview of the same drawing code; presentation only (navigation, placement and saves unchanged).

## D58. Building models redrawn (owner request, 2026-10-15; replaces the D51/D52 building look)
- Buildings stay front-facing 3/4 drawings on the footprint (same origin, footprint, collision, door tile and API), now built in layers: ground shadow cast back-right, plinth, front wall (stone blocks in varied shades / alternating planks / plaster with a timber frame and braces), corner quoins or posts, base trim, windows with shutters, lintels and sills (flower boxes on homes, inns, the Tavern and the Restaurant), a framed plank door with two steps, then the roof.
- **Roofs**: hip roofs (tiled slope with rows shaded towards the eave, staggered tile joints, hip edges, a capped ridge) or gable roofs (tiled side slopes behind a gable with a round window and barge boards; plank lines on wooden gables). An eave shadow falls on the wall.
- **Silhouettes per building**: Town Hall clock tower with a pyramid roof and flag, columns; Tavern hanging mug sign, barrels, chimney; Blacksmith open forge bay with a hearth glow, anvil, awning, tall chimney; Hospital red cross on the roof and over the door; Warehouse barn door with braces and crates; House chimney and flower boxes; Temple spire with a golden sun and columns; Trading Post striped awning, coin sign, crates; Restaurant striped awning, plate sign, chimney; Inn two dormers, bed sign, lantern; Academy dormers, flag, columns, crest; Forge chimney and glow; the **Reincarnation Portal** is a stone ring arch on a rune dais around a swirling gate (no house).
- Two-storey fronts (Town Hall, Tavern, Inn, Academy) get two window rows. Lv2: taller wall and plinth, a flag. Chimney smoke and the portal's sparks animate at 6 fps.
- Designed against a Python preview of the same draw calls.

## D59. Props redrawn (2026-10-15; extends D51, D57)
- `WorldProp` keeps its kinds, collision and spawn rules; only the drawing changed, in the D57/D58 style (light from the top-left, dark outlines, ground shadow cast to the right).
- **Leafy tree** (Town edges): tapered trunk with roots, six outlined canopy clumps with a lit layer, highlights on the upper-left clumps and light / dark leaf clusters; a quarter carry apples, a fifth blossoms.
- **Pine** (Dark Forest): four tiers with saw-tooth skirts, lit left half, needle strokes; some carry cones.
- **Boulder** (Goblin Cave): a big and a small rock, lit top facet, shaded side, cracks, moss cap, a pebble; three in ten hide a glowing crystal.
- **Broken column** (Ancient Ruins): stepped base, fluted shaft, jagged break, ivy, rubble; three heights.
- The variant comes from the prop's position (`WorldProp._variant`), so it is stable across sessions without saving anything.

## D60. One-texel outlines and double-density details (2026-10-15; extends D56)
- After the D56 upscale every silhouette outline was two texels thick. `tools/thin_outlines.py` removed the inner layer of every silhouette outline in the Hunter body, outfits and hair, the monster bodies and the weapon sprites (≈1,400 texels): an outline texel touching no transparency next to an outline texel that does is painted with the fill it touches. Inner lines (eyes, mouth, seams, straps) keep their weight. Outfits were thinned together with the head rows above them.
- New detail that only fits at the double density: a white sparkle in each iris (front view; cleared with the face in the back view) and a broken highlight band ("shine") across every hair style.
- Sizes, anchors, hands and grips are unchanged.

## D61. Scenery around the map (owner request, 2026-10-15; extends D57)
- The camera may now pan `WorldScenery.MARGIN` (420 px) beyond the regions (was 96 px) and the water is drawn 520 px out, with soft deeper / lighter patches from noise under the shallows and waves.
- `WorldScenery` (static, drawn once, no collision) fills the water ring: ten islets (beach, foam ring, grass, shore rocks; leafy trees, leaning palms, or a striped lighthouse on the north-west islet), four sandbars, eight rock clusters, kelp beds, drifting logs, a shipwreck off the Goblin Cave, lily pads and reeds off the Town's west shore, and a fishing dock on the Town's west edge. Positions are tile constants tested to stay off the land, bridges and dungeon entrances and inside the camera's reach.
- `WorldAmbience` (10 fps redraw, above the entities, faint): the boat moored at the dock bobbing on its line, the lighthouse lamp pulsing with a slow sweeping beam, five gulls circling with flapping wings, and five cloud shadows drifting across the map.
- `WaterShimmer` glints now cover the same ring. Presentation only.

## D62. Landmarks in the hunting regions (2026-10-15; extends D57, D59)
- `WorldLandmark` (StaticBody2D, navigation obstacle, D57–D59 drawing style) gives each hunting region a few recognisable spots, placed at fixed tiles relative to the region (`WorldMap.LANDMARKS`, keyed by `RegionDefinition.props`) and skipped on trails or near bridges and dungeon entrances. Ordinary props keep their spacing from them.
  - Dark Forest: a mossy stone shrine with a softly glowing idol, three stumps (one with a mushroom), two fallen logs with moss and mushrooms.
  - Goblin Cave: a camp of three hide tents around a campfire with a roast on a spit and a skull totem; a second small camp (tent + fire).
  - Ancient Ruins: two broken knight statues, a rune obelisk, a collapsed arch (only its pillars block, Hunters can walk under it).
- Campfire flames and sparks, the obelisk's runes and the shrine's idol animate at 8 fps; the rest is static.
- Collision: circles (tents 14 px, fire 10, totem 6, statue 10, obelisk 8, stump 7) or boxes (log 38×9, shrine 32×8).

## D63. Pictures in the menus and a Storage grid (2026-10-15; extends UI_DESIGN.md)
- `BuildingThumb`: the map's own `BuildingVisual` scaled into a rounded plate with a strip of grass (chimney smoke still moves), greyed out when the building is locked.
  - Construct menu: a two-column grid of picture cards (picture, name, coin cost, why it cannot be built, Place); the description is the card's tooltip.
  - Shop & Services: a picture on every row.
  - Building panel: a picture of the building at its level next to the description.
- Storage (`InventorySheet`, titled "Storage" like the nav tab): six-column grids of `ItemIcon` slots — materials with counts, spare equipment with "+N" — and a detail card for the tapped slot (icon, name in its rarity colour, rarity, effect, price) with Sell 1 / Sell all, or Sell for equipment. `ItemIcon.tappable()` and `selected` support it.
