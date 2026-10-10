# DECISIONS

Resolved design decisions and conflict fixes. This file ranks right after `01_PROJECT_OVERVIEW.md` in priority (see `00_RULES.md`).

Numbers referenced here live in `BALANCE.md`.

## D1. Game direction
Open-ended. No endgame, final boss or win state. Two growth axes: power and life (traits, mood, bonds).

## D2. Expedition mode
- Real-time. The player can watch the expedition scene.
- No offline progress. Timers (Hospital, activities) run only while the game runs.
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
- Base viewport 640×360, window 1280×720, stretch mode `viewport`, integer scaling, nearest filtering.
- 4-direction movement and sprites.

## D21. Save
- Single slot, JSON at `user://save.json`, backup `user://save.bak.json`.
- Autosave: expedition end, recruitment, building upgrade, crafting, quit.
- An expedition in progress is not saved in MVP; on next load the party is back in town without that run's rewards.
- An in-game day counter is saved and used for Hunter history (recruit date).

## D22. Development tooling
- Debug panel allowed from Phase 1 under `ui/debug/`, hidden in release builds.
- Tests: plain GDScript runner `tests/run_tests.gd`, run headless. No test plugins.
