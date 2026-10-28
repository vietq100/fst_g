# BALANCE (first pass)

Starting values for MVP. All of these must live in data resources, not code.
Tune during Phase 11. Update this file when values change.

## Formulas
- Damage: `max(1, attack - defense * 0.5)`
- Critical: `damage *= critical_damage` when `randf() < critical_chance`
- Attack cooldown: `1 / attack_speed` s
- Required XP for next level: `30 * pow(level, 2.2)` (D44: Lv1 30, Lv2 138, Lv3 337, Lv4 634, Lv5 1035, Lv9 3771)
- Stat: `(base + level_growth * (level - 1) + Σflat) * (1 + Σpercent)`

## Offline
- Offline progress cap: 8 hours (town timers only)

## Warrior (class template)
| Stat | Base | Per level |
|---|---|---|
| HP | 120 | +12 |
| Attack | 14 | +2 |
| Defense | 6 | +1 |
| Attack speed | 1.0 /s | — |
| Move speed | 80 px/s | — |
| Crit chance | 5% | — |
| Crit damage | ×1.5 | — |
| Attack range | 20 px | — |
| Recruit cost | 100 gold | — |

Recruits roll ±10% on HP/Attack/Defense.

## Classes (D45)
| Class | HP (+/lv) | Atk (+/lv) | Def (+/lv) | Atk spd | Move | Crit | Crit dmg | Range | Recruit | Starting gear |
|---|---|---|---|---|---|---|---|---|---|---|
| Warrior | 120 (+12) | 14 (+2) | 6 (+1) | 1.0 | 80 | 5% | ×1.5 | 20 | 100 | Rusty Sword, Leather Armor |
| Ranger | 90 (+9) | 12 (+2) | 3 (+0.5) | 1.1 | 85 | 10% | ×1.6 | 110 | 120 | Short Bow, Leather Armor |
| Rogue | 100 (+10) | 13 (+2) | 4 (+0.7) | 1.4 | 95 | 20% | ×1.8 | 18 | 110 | Rusty Dagger, Leather Armor |
| Guardian | 160 (+16) | 10 (+1.5) | 9 (+1.5) | 0.8 | 70 | 0% | ×1.5 | 22 | 130 | Rusty Sword, Leather Armor |

Short Bow: +3 Atk (sell 5). Rusty Dagger: +2 Atk, +5% crit (sell 5).

## Talents (D46)
| Talent | Chance at recruitment | Field recipes (time) |
|---|---|---|
| Cook | 35% | Meat Stew 8 s, Herb Soup 6 s |
| Herbalist | 35% | Bandage 5 s, Healing Potion 10 s |
| none | 30% | — |

Field crafting uses the same ingredients and output as the village recipe; no gold, no building level.

## Enemies
| Enemy | HP | Atk | Def | Atk spd | Move | XP | Gold |
|---|---|---|---|---|---|---|---|
| Slime | 30 | 6 | 1 | 0.7 | 40 | 5 | 2–4 |
| Goblin | 50 | 10 | 3 | 1.0 | 70 | 10 | 4–8 |
| Wolf | 40 | 12 | 1 | 1.4 | 120 | 12 | 3–6 |
| Forest Guardian | 900 | 28 | 10 | 0.5 | 40 | 150 | 150 |

Attack range (feet to feet): Slime 18, Goblin 20, Wolf 20, Forest Guardian 30 px.
Hit radius (extra body size added to attackers' reach): Forest Guardian 14 px, others 0.

| Skeleton (Ruins, new) | 70 | 16 | 6 | 0.9 | 60 | 18 | 8–14 |

Skeleton attack range 20 px; drops Iron Ore ×1 (30%), Dark Essence ×1 (4%).

Rare gear drops (D75): Goblin Straw Hat 3%, Eye Patch 2%, Cowboy Hat 1.5%, Battle Axe 1.5%; Wolf Iron Spear 1.5%; Slime Oak Staff 2%, Round Glasses 1.5%; Skeleton Hunter Goggles 1.5%, Viking Helm 1%, Ember Staff 0.8%.

## Stat grades (D80)

Every stat of a Hunter, monster or piece of gear is graded against the **average of its kind**, as the ratio value / average; the total of an object is the weighted mean of its stats' ratios (each capped at 8).

| Step | Ratio ≥ | Colour |
|---|---|---|
| Poor | — (below 0.6) | grey `8a8f98` |
| Plain | 0.6 | white `f4f1ea` |
| Average | 0.85 | blue `5fa8ff` |
| Good | 1.15 | deep blue `3a6fd8` |
| Fine | 1.4 | orange `ff9a3d` |
| Strong | 1.75 | red `ff5a5a` |
| Excellent | 2.2 | gold `ffd23f` |
| Elite | 2.8 | sky `8fe3ff` |
| Legendary | 3.6 | emerald `3ddc97` |
| Supreme | 5.0 | violet `c77dff` |

Averages (built from the data at load, `StatGradeService`):
- **Hunters**: per level, the mean of every class definition's base and growth (tier C, no gear, no rolls) through the stat formula. Weights in the total: HP 1, ATK 1, DEF 1, attack speed 0.5, crit chance 0.25, crit damage 0.25, move speed 0.25.
- **Monsters**: the mean of the regular (non-boss) enemy definitions; HP, ATK and DEF are compared at the monster's level and tier scale. Same weights as Hunters (bosses are graded against regular monsters, so they read high).
- **Gear**: per equipment slot, the mean size of the same bonus (stat, flat or percent) over the items of that slot; an item's total is the mean over its bonuses. Items without bonuses are Average.

## Summoning and hibernation (D83)

| Number | Value | Where |
|---|---|---|
| Tickets per summon | 1 | `GameConfig.summon_ticket_cost` |
| Tickets of a new village | 20 (release balance) | `GameConfig.start_summon_tickets` |
| Ticket gold purchase price | 300 gold | `GameConfig.ticket_gold_price` |
| Hunters awake at once | 24, never above the Town Hall capacity | `GameConfig.active_hunter_cap` |
| Sleepers on the Hibernation Mount | 100 | `GameConfig.hibernation_cap` |
| Summoned tier | rolled with `Tier.HUNTER_WEIGHTS` (D60) | `HunterService.generate_candidate` |

Ticket sources:
- **Dungeons / Expeditions**: 5 tickets on first clear, 1 ticket on repeat clear (`completion_bonus_summon_tickets`, `first_clear_bonus_summon_tickets`).
- **Weekly Boss**: 5 tickets per defeat (`WeeklyBossService.BONUS_TICKETS`).
- **Quests**: 1–5 tickets on milestone achievements (hire Hunters, clear forest, upgrade Town Hall, reach level 20/50, reincarnate).
- **Gate purchase**: 300 gold per ticket from the town treasury (`RecruitmentService.buy_ticket`).

A sleeper costs nothing (no food, no bed) and gains nothing (no XP, no mood). Waking needs an active slot and a free bed.

## Regions (world redesign, D27, D29)
| Region | Monsters | Monster level | Min Hunter level (Auto) | Population cap | Respawn |
|---|---|---|---|---|---|
| Dark Forest | Slime, Wolf | 1–3 | 1 | 16 | 15 s |
| Goblin Cave | Goblin, Wolf | 4–7 | 5 | 18 | 15 s |
| Ancient Ruins | Skeleton, Goblin | 8–12 | 9 | 18 | 15 s |

Regions are 36 × 36 tiles; population caps were doubled with the map (4× the area, so monsters are half as dense as in the 18 × 18 draft).

Monster level L scales HP/ATK/DEF by `1 + 0.12 × (L − 1)` and XP/gold by `1 + 0.10 × (L − 1)`.
Aggro range 90 px; monsters leash back to their spawn after 220 px.

### Region Progression & Gear Expectations
| Region | Target Hunter Lv | Expected Gear | Hunter Benchmark Stats | Primary Risk |
|---|---|---|---|---|
| Dark Forest | Lv 1–4 | Starter (Rusty Weapon + Leather Armor) | HP 120–156, ATK 14–20, DEF 6–9 | Wolves swarm low-HP Hunters |
| Goblin Cave | Lv 5–8 | Uncommon (Iron Weapon + Iron Armor / Cowboy Hat) | HP 180–220, ATK 22–30, DEF 11–16 | Goblin criticals + Wolf speed |
| Ancient Ruins | Lv 9–15 | Rare (Fang Blade/Ember Staff, Viking Helm, Goggles) | HP 240–320, ATK 32–45, DEF 18–26 | Skeleton high defense (DEF 6+) & ATK |

## Needs (D31) — per 10 s tick
| Need | Change |
|---|---|
| Stamina while active (walking, hunting, carrying) | −1.5 |
| Stamina sleeping in a House bed | +6 |
| Stamina sleeping outdoors | +3 (and −1 mood) |
| Energy (always, except sleeping: −0.3) | −0.6 |
| Eating one portion of food (D40) | the food's energy (see Village economy), its price from the purse to the treasury |
| Energy at 0 | −2% max HP and −1 mood per tick |

Brain thresholds: sleep below 25 stamina (until 95), eat below 35 energy, go home to rest below 35% HP (until 90%), go home when the loot bag (10 items) is full.
Stamina 0: −40% move speed, −30% attack speed.

## Bodies (D30)
- Carrier speed when dragging a body: carrier move speed × 0.7.
- Revival at the Temple (D42): Temple revival time; revived with 50% HP, stamina and energy; loses 10% of the XP needed for its current level.
- Staff (D43): 2, move speed 70 px/s, fee 15 gold per trip.
- A Hunter carrier needs ≥ 25 stamina and must not be asleep.
- Nobody able to carry a body for 120 s: the town brings it to the Temple.

## Money (D34)
- New Hunter purse: 20 gold. Treasury ↔ purse transfer fee: 10% (receiver gets 90%).

## Building placement (D33)
| Building | Build cost | Footprint (tiles) | Unique |
|---|---|---|---|
| Town Hall | — (cannot be removed) | 3 × 3 | yes |
| Tavern | 200 gold | 2 × 2 | yes |
| Blacksmith | 200 gold | 2 × 2 | yes |
| Hospital | 200 gold | 2 × 2 | yes |
| Temple | 250 gold | 2 × 2 | yes |
| Warehouse | 150 gold | 2 × 2 | yes |
| House (4 beds) | 120 gold | 2 × 2 | no |

Removing refunds 50% of the build cost. Moving is free.

## Progression
- Level-up heals 20% of max HP.
- Hunter level cap = Town Hall level × 10 (Town Hall level is 1 until Phase 6).

Drops:
- Goblin: Iron Ore ×1 (40%)
- Wolf: Beast Fang ×1 (50%)
- Forest Guardian: Iron Ore ×5, Beast Fang ×3, Dark Essence ×2 (first clear) / ×1 at 50% (repeat), Rare equipment 10%; repeat clears give 50% boss gold.

## Forest Guardian's Grove (dungeon, former Dark Forest expedition)
- Recommended level: 4
- Completion bonus: 50 gold
- Groups:
  1. Entrance: 3 Slime
  2. Clearing: 2 Slime + 2 Goblin
  3. Enemy area: 3 Goblin + 1 Wolf
  4. Deeper forest (stronger group): 2 Goblin + 2 Wolf
  5. Boss arena: Forest Guardian

### Dungeon Progression & Gear Expectations
| Dungeon | Recommended Lv | Party Size | Expected Gear | Boss Benchmark |
|---|---|---|---|---|
| Forest Guardian's Grove | Lv 4+ | 3–4 Hunters | Mixed Starter / Iron Gear + Bandages | Forest Guardian (HP 900, ATK 28, DEF 10) |
| Goblin Warren (upcoming) | Lv 10+ | 4 Hunters | Full Iron / Rare Gear + Potions | Goblin Warlord |
| Ruined Sanctum (upcoming) | Lv 16+ | 4 Hunters | Rare / Tier SR+ Gear | Crypt Lord |

## Buildings
| Building | Lv1 effect | Lv2 cost | Lv2 effect |
|---|---|---|---|
| Town Hall | capacity 3, level cap 10 | 500 gold + 10 Iron Ore (requires first boss clear) | capacity 5, level cap 20 |
| Tavern | 3 candidates, refresh 30 gold | 300 gold | 4 candidates |
| Blacksmith | Common/Uncommon recipes | 300 gold + 5 Iron Ore | Rare recipes |
| Hospital | Bandages | 300 gold | + Healing Potions |
| Temple | revival 180 s | 300 gold + 2 Dark Essence | revival 120 s |
| Warehouse | 40 slots | 250 gold + 5 Iron Ore | 80 slots |

Town Hall progression (Lv 1–10, D70):
| Level | Upgrade Cost | Capacity | Hunter Level Cap |
|---|---|---|---|
| Lv 1 | — (starting building) | 3 | 10 |
| Lv 2 | 500 gold + 10 Iron Ore (requires first boss clear) | 5 | 20 |
| Lv 3 | 1,500 gold + 20 Iron Ore + 10 Beast Fang | 8 | 30 |
| Lv 4 | 4,000 gold + 40 Iron Ore + 8 Dark Essence | 12 | 40 |
| Lv 5 | 10,000 gold + 20 Dark Essence + 20 Bone Dust | 16 | 50 |
| Lv 6 | 20,000 gold + 40 Dark Essence + 30 Bone Dust + 30 Beast Fang | 20 | 60 |
| Lv 7 | 35,000 gold + 60 Dark Essence + 40 Iron Ore | 22 | 70 |
| Lv 8 | 55,000 gold + 80 Dark Essence + 50 Bone Dust + 40 Beast Fang | 24 | 80 |
| Lv 9 | 80,000 gold + 100 Dark Essence + 60 Iron Ore + 50 Bone Dust | 24 | 90 |
| Lv 10 | 120,000 gold + 150 Dark Essence + 80 Bone Dust + 60 Beast Fang | 24 | 100 |

Temple speed-up: 20 gold per remaining started minute.

## Village economy (D38–D41)
Materials (village buy price = Hunter's income at the Warehouse):

| Material | Price | Drops |
|---|---|---|
| Slime Gel | 2 | Slime 60% |
| Raw Meat | 3 | Wolf 50% |
| Wild Herb | 4 | Goblin 35%, Slime 20% |
| Bone Dust | 5 | Skeleton 45% |
| Iron Ore | 3 | Goblin 40%, Skeleton 30% |
| Beast Fang | 4 | Wolf 50% |
| Dark Essence | 25 | Skeleton 4%, boss |

Recipes (crafted by the chief; output goes to the Warehouse):

| Building | Recipe | Cost | Makes | Effect | Price to Hunters |
|---|---|---|---|---|---|
| Tavern Lv1 | Meat Stew | 2 Raw Meat | 3 | +60 energy | 12 |
| Tavern Lv1 | Herb Soup | 1 Wild Herb + 1 Slime Gel | 2 | +40 energy | 8 |
| Hospital Lv1 | Bandage | 2 Slime Gel | 3 | heals 30% max HP | 8 |
| Hospital Lv2 | Healing Potion | 1 Wild Herb + 1 Bone Dust | 1 | heals 70% max HP | 25 |

New village: 6 Meat Stew in stock.

Town revenue balancing (Phase 12):
- **Trader tax**: 15% tax taken by the town treasury on surplus materials sold to passing traders (`GameConfig.trader_tax_rate`).
- **Tavern drinks**: 2 gold paid to the treasury by Hunters during social activities (`GameConfig.social_drink_cost`).
- **Weapon repairs**: Blacksmith collects `worn points × (1 + tier)` gold when Hunters repair their gear (D64).
- **Dungeon & Weekly boss bonus**: 50–1500 gold awarded directly to the treasury on clear/defeat.

## Equipment
| Item | Rarity | Slot | Modifiers | Source / recipe | Sell |
|---|---|---|---|---|---|
| Rusty Sword | Common | weapon | +3 atk | starting gear | 5 |
| Leather Armor | Common | armor | +3 def, +10 HP | starting gear | 5 |
| Iron Sword | Uncommon | weapon | +7 atk | 50 gold + 5 Iron Ore | 20 |
| Iron Armor | Uncommon | armor | +6 def, +20 HP | 60 gold + 6 Iron Ore | 25 |
| Fang Blade | Rare | weapon | +10 atk, +5% crit | 150 gold + 8 Beast Fang + 1 Dark Essence (Blacksmith Lv2) | 60 |
| Battle Axe (D75) | Uncommon | weapon | +8 atk | 55 gold + 6 Iron Ore | 22 |
| Iron Spear (D75) | Uncommon | weapon | +6 atk, +5% atk speed | 50 gold + 4 Iron Ore + 2 Beast Fang | 20 |
| Oak Staff (D75) | Uncommon | weapon | +5 atk, +5% XP | 45 gold + 3 Wild Herb + 2 Iron Ore | 20 |
| Ember Staff (D75) | Rare | weapon | +10 atk, +10% crit dmg (fire effects) | 150 gold + 6 Slime Gel + 1 Dark Essence (Blacksmith Lv2) | 60 |
| Round Glasses (D75) | Uncommon | accessory | +5% XP | 40 gold + 2 Iron Ore | 25 |
| Eye Patch (D75) | Common | accessory | +2% crit | 20 gold + 2 Beast Fang | 8 |
| Hunter Goggles (D75) | Rare | accessory | +2 atk, +3% crit | 90 gold + 4 Iron Ore + 2 Slime Gel (Blacksmith Lv2) | 55 |
| Straw Hat (D75) | Common | helmet | +1 def, +2 move speed | 15 gold + 3 Wild Herb | 5 |
| Cowboy Hat (D75) | Uncommon | helmet | +3 def, +2% crit | 45 gold + 3 Beast Fang + 1 Iron Ore | 22 |
| Viking Helm (D75) | Rare | helmet | +6 def, +15 HP, +2 atk | 110 gold + 6 Iron Ore + 3 Bone Dust (Blacksmith Lv2) | 60 |

Materials sell: Iron Ore 3, Beast Fang 4, Dark Essence 25. Stack size 99, one slot per stack.

## Barber (D77)
Changing a Hunter's hair style and colour costs 100 gold (`GameConfig.restyle_cost`).

## Mood (0–100, start 60)
| State | Range | Effect |
|---|---|---|
| High | ≥ 70 | +5% atk/def, +10% XP |
| Normal | 30–69 | none |
| Low | < 30 | −10% atk/def, −10% XP |

Events: success +10, failure −15, injured −10, trait like +5, trait dislike −5, third consecutive expedition without rest −5.

## Activities (tick = 10 s)

> Tuning (D44): training was +3 XP per tick (~1,080 XP/hour offline) against a flat curve; now +1 XP per tick online, a quarter of that offline (~90 XP/hour), against `30 × level^2.2`.

| Activity | Per tick |
|---|---|
| Resting | +5% max HP, +2 mood |
| Socializing | +3 mood, +2 bond with each other socializing Hunter |
| Training | +1 XP (offline: ×0.25, D44) |
| Recovering | Hospital timer runs |

## Bonds (0–100, bonded at 100)
- Shared expedition: +20
- Socializing together: +2 per tick
- Bonded: +5% attack when in same party; +2 extra mood per socializing tick together

## Traits
| Trait | Effect | Likes | Dislikes |
|---|---|---|---|
| Brave | +15% damage vs boss | boss fight | idle 2 expedition cycles |
| Cautious | −10% damage taken, −5% damage dealt | success | expedition above own level |
| Greedy | +20% gold from loot | boss kill | failure |
| Disciplined | Training ×1.5 | training | party with Reckless |
| Reckless | +15% damage dealt, +10% damage taken | boss fight | resting 3+ ticks |
| Lazy | Training ×0.5, Resting ×1.5 | resting | 2 consecutive expeditions |

## Colosseum (D68, design only)
| Value | Number |
|---|---|
| PvP damage | × 0.8 |
| PvP crowd control duration | × 0.6, then 2 s same-type immunity |
| PvP healing and shields | × 0.7 |
| Caps PvP / PvE | dodge 25 / 40 %, damage reduction 50 / 60 %, tenacity 50 / 70 %, lifesteal 20 / 30 %, thorns 30 / 60 %, crit 75 / 100 % |
| Time limit | 1vs1 60 s, 4vs4 90 s, 6vs6 120 s |
| Stamina per match | 10 (needs ≥ 25) |
| Rank points | start 1000, K = 32 (win ≈ +20, loss ≈ −15) |
| Tickets | 5 ranked matches per format per day |
| Rival refresh | 20 gold |
| Ranked win gold | 15 × (1 / 3 / 4 for 1vs1 / 4vs4 / 6vs6) + 1 Arena Token |
| Mood | win +5, draw +1, loss −3 |

## Boss rules for class skills (D69, design only)
- Stunned, Frozen, Rooted, Disarmed on a boss become Stagger (+10 % damage taken) for half the duration.
- Slowed, Weakened, Armor Break at 50 % effect; Taunt duration × 0.5.
- % max-HP damage (Bleed, Judgment) capped at 150 % of the source's ATK per hit or per second.
- Execute thresholds drop to 15 % HP; no cooldown reset on a boss kill.

## Class skills and mana (D70)
| Value | Number |
|---|---|
| Skills per class | 30 (18 active, 12 passive) |
| Skills per Hunter | max 7, opened at random |
| Skill level | 1–6, power `1 + 0.15 × (L − 1)` (Lv 6 ×1.75) |
| Effect duration from skills | buffs × power, debuffs × (1 + 0.5 × (power − 1)) |
| Skill points | 1 per 10 Hunter levels |
| Max mana | 100 + 2 per level |
| Mana regen | 5 / s (×3 with no target) |
| Mana cost (Lv 1) | `8 + 1.5 × cooldown`, +6% per skill level |
| Cast gap | 0.8 s |
| Dodge cap / tenacity cap | 40% / 70% |
| Boss execute threshold | 15% |
| Stagger | +10% damage taken, 2 s |
| Boss: soft debuffs from skills | half duration |
| Boss: %-max-HP damage over time (Bleed) | ×0.25 |
| Reincarnation | level 100, +1 swap point |
