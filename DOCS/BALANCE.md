# BALANCE (first pass)

Starting values for MVP. All of these must live in data resources, not code.
Tune during Phase 11. Update this file when values change.

## Formulas
- Damage: `max(1, attack - defense * 0.5)`
- Critical: `damage *= critical_damage` when `randf() < critical_chance`
- Attack cooldown: `1 / attack_speed` s
- Required XP for next level: `20 * pow(level, 1.5)`
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

## Enemies
| Enemy | HP | Atk | Def | Atk spd | Move | XP | Gold |
|---|---|---|---|---|---|---|---|
| Slime | 30 | 6 | 1 | 0.7 | 40 | 5 | 2–4 |
| Goblin | 50 | 10 | 3 | 1.0 | 70 | 10 | 4–8 |
| Wolf | 40 | 12 | 1 | 1.4 | 120 | 12 | 3–6 |
| Forest Guardian | 900 | 28 | 10 | 0.5 | 40 | 150 | 150 |

Attack range (feet to feet): Slime 18, Goblin 20, Wolf 20, Forest Guardian 30 px.
Hit radius (extra body size added to attackers' reach): Forest Guardian 14 px, others 0.

## Progression
- Level-up heals 20% of max HP.
- Hunter level cap = Town Hall level × 10 (Town Hall level is 1 until Phase 6).

Drops:
- Goblin: Iron Ore ×1 (40%)
- Wolf: Beast Fang ×1 (50%)
- Forest Guardian: Iron Ore ×5, Beast Fang ×3, Dark Essence ×2 (first clear) / ×1 at 50% (repeat), Rare equipment 10%; repeat clears give 50% boss gold.

## Dark Forest
- Recommended level: 4
- Completion bonus: 50 gold
- Groups:
  1. Entrance: 3 Slime
  2. Clearing: 2 Slime + 2 Goblin
  3. Enemy area: 3 Goblin + 1 Wolf
  4. Deeper forest (stronger group): 2 Goblin + 2 Wolf
  5. Boss arena: Forest Guardian

## Buildings
| Building | Lv1 effect | Lv2 cost | Lv2 effect |
|---|---|---|---|
| Town Hall | capacity 3, level cap 10 | 500 gold + 10 Iron Ore (requires first boss clear) | capacity 5, level cap 20 |
| Tavern | 3 candidates, refresh 30 gold | 300 gold | 4 candidates |
| Blacksmith | Common/Uncommon recipes | 300 gold + 5 Iron Ore | Rare recipes |
| Hospital | recovery 120 s | 300 gold | recovery 84 s (−30%) |
| Warehouse | 40 slots | 250 gold + 5 Iron Ore | 80 slots |

Town Hall Lv3 (post-MVP reference): 1500 gold + 30 Iron Ore + 3 Dark Essence → capacity 8, level cap 30.

Hospital speed-up: 20 gold per remaining started minute.

## Equipment
| Item | Rarity | Slot | Modifiers | Source / recipe | Sell |
|---|---|---|---|---|---|
| Rusty Sword | Common | weapon | +3 atk | starting gear | 5 |
| Leather Armor | Common | armor | +3 def, +10 HP | starting gear | 5 |
| Iron Sword | Uncommon | weapon | +7 atk | 50 gold + 5 Iron Ore | 20 |
| Iron Armor | Uncommon | armor | +6 def, +20 HP | 60 gold + 6 Iron Ore | 25 |
| Fang Blade | Rare | weapon | +10 atk, +5% crit | 150 gold + 8 Beast Fang + 1 Dark Essence (Blacksmith Lv2) | 60 |

Materials sell: Iron Ore 3, Beast Fang 4, Dark Essence 25. Stack size 99, one slot per stack.

## Mood (0–100, start 60)
| State | Range | Effect |
|---|---|---|
| High | ≥ 70 | +5% atk/def, +10% XP |
| Normal | 30–69 | none |
| Low | < 30 | −10% atk/def, −10% XP |

Events: success +10, failure −15, injured −10, trait like +5, trait dislike −5, third consecutive expedition without rest −5.

## Activities (tick = 10 s)

> ⚠ Tuning note (found in Phase 9): with offline progress, +3 XP per training tick is ~1,080 XP/hour, and Lv 1→10 needs ~2,200 XP, so 2 hours away takes a fresh roster to the level cap. Revisit the training XP (or cap offline training) in Phase 11.

| Activity | Per tick |
|---|---|
| Resting | +5% max HP, +2 mood |
| Socializing | +3 mood, +2 bond with each other socializing Hunter |
| Training | +3 XP |
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
