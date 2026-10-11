# AUTONOMY SYSTEM (Hunter brains, needs, bodies)

Hunters live on their own in the world (D29–D32). The player guides them through duty, money, equipment and buildings; routine life and hunting are automatic. Numbers: `BALANCE.md` → Regions / Needs / Bodies / Money.

## Needs (D31)

| Need | Range | Goes down | Goes up |
|---|---|---|---|
| HP | 0–max | combat, starving | resting at home, level-up, revival |
| Stamina | 0–100 | walking, hunting, carrying | sleeping (House bed, or outdoors at half rate) |
| Energy | 0–100 | time | eating at the Tavern (paid from the purse) |

Needs tick every 10 s (with the town activity tick). Empty stamina slows the Hunter; empty energy drains HP and mood.

## Brain (D29)

Re-evaluated on every tick and whenever a task ends. First match wins:

1. **Dead** → lie as a body (wait for a carrier).
2. **Carrying a body** → keep dragging it to the Hospital.
3. **Stamina < 25** (or sleeping and < 95) → go to its House bed (or outdoors spot) and sleep.
4. **Energy < 35** and purse ≥ meal price → go to the Tavern and eat.
5. **HP < 35%** (or resting and < 90%) → go home and rest.
6. **Loot bag full** → go to the Warehouse and deposit.
7. **A body needs a carrier** and this Hunter is the chosen carrier → fetch it.
8. **Duty**: Auto / fixed region → walk to the region and hunt; Stay in town → town activity (rest / train / socialize).

Hunters in a dungeon party are controlled by the dungeon run, not by the brain.

## Hunting

- Monsters spawn at region spawn points up to a population cap, respawning over time; they aggro on Hunters within range in their region and leash back if pulled too far.
- A hunting Hunter targets the nearest monster in its region; with none nearby it wanders between spawn areas.
- Kill: XP to the Hunter, gold to the purse (×gold_find), items into the loot bag.
- Returning to town deposits the bag into the Warehouse (overflow auto-sold to the treasury).

## Bodies (D30)

- 0 HP → the Hunter dies; the body stays where it fell (persisted in saves).
- `CorpseService` assigns the nearest free Hunter as carrier. The carrier walks to the body, then drags it to the Hospital at 70% of its own speed.
- At the Hospital the Hunter becomes a patient; after the recovery time it is revived (50% HP, stamina, energy). Gold can speed it up.

## Money (D34)

- Purse: hunting gold, meals, transfers. Treasury: the town's gold.
- Transfers in either direction cost 10% (the receiver gets 90%).
- Meals pay the Tavern: the meal price goes into the treasury.

## Implementation notes

- `NeedsService` (ticks, effects), `HunterBrain` (decision per Hunter, a node on the Hunter actor), `CorpseService` (bodies, carrier assignment), `PurseService` (purses, transfers), `RegionService` (monster spawns per region), `WorldService` (tile ↔ world, regions, gates, region lookup).
- All rules live in services; the brain only chooses tasks and asks the actor to walk/fight.
- Until `HunterBrain` exists (W4), Hunters in town use ActivityService: Sleeping / Eating are chosen before the normal town activities, with the same thresholds; Training counts as active for stamina.
- Code: `RegionService` (rules), `world/world/region_spawner.gd` (monsters per region), `world/world/hunter_brain.gd` (one per Hunter actor). `HunterRuntime.task`: "" (town life, ActivityService decides), "hunting", "returning".

## Village economy (D38–D44)

- **Selling**: back in town the Hunter walks to the Warehouse and sells its bag to the village (treasury → purse, item price); what the village cannot pay for or store goes to a passing trader at the same price.
- **Food**: eating takes one portion of the most filling food in stock the Hunter can afford (Tavern kitchen, crafted by the chief) and pays its price into the treasury. No food or no money → the Hunter stays hungry and keeps working.
- **Medicine**: resting at low HP, the Hunter first buys and uses the strongest affordable medicine at the Hospital (one at a time, until above 90% HP).
- **Bodies**: village staff (2, `StaffWorker`, fee per trip) fetch bodies first; a free Hunter carries when no staff member is free or the treasury is short. Bodies go to the **Temple**, which revives after its time and takes 10% of the XP of the Hunter's level.
- Code: `SupplyService` (food / medicine sales), `CorpseService` (staff and Hunter carriers), `TempleService` (revival), `RegionService.deposit` (selling).

## Talents (D46)
- Before walking home for food or rest, a Hunter eats food / uses medicine from its own bag. A Cook without food cooks from bag materials; a Herbalist with low HP brews medicine. Crafting takes the recipe's `field_seconds` (5–10 s); being hit cancels it. Code: `TalentService`, `HunterBrain._self_care`.
