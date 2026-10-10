# EXPEDITION SYSTEM

## Mode

Real-time. The player can watch the expedition scene. No offline progress.
One expedition active at a time in MVP. No manual recall in MVP.

## Flow

Preparation
→ choose destination
→ choose Hunters (1–3, must be AVAILABLE)
→ validate
→ start
→ travel (walk out South Gate, fade to expedition scene)
→ combat through enemy groups
→ boss
→ rewards
→ return

## Expedition data

- id
- display_name
- recommended_level
- enemy groups
- boss
- reward table (completion bonus, boss rewards)
- unlock requirement

Dark Forest values: `BALANCE.md`.

## Loot and XP during the run

- Loot is collected automatically on each kill into an expedition stash.
- Every party member (including downed ones) gets the full XP of each kill.
- Stash is granted to the town inventory on return.

## Downed Hunters

A Hunter at 0 HP is downed: removed from the fight, not dead, becomes injured on return.

## Failure

Expedition fails when all party members are downed.

- expedition ends
- keep 50% of stash gold and materials
- no completion bonus, no boss reward
- downed Hunters are injured and go to Hospital
- mood penalties per `BALANCE.md`
- return to town

No permanent death.

## Completion

On success:
- grant stash + completion bonus + boss rewards
- XP already granted per kill
- mark expedition complete (first clear tracked separately)
- first Forest Guardian clear unlocks Town Hall level 2
- downed Hunters still return injured
- mood and bond updates
- autosave

The expedition stays repeatable. Repeat boss clears give reduced rewards (`BALANCE.md`).

## Warehouse overflow

If returning items exceed Warehouse capacity, the overflow is auto-sold at sell price and reported to the player.
