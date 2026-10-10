# EXPEDITION SYSTEM

## Mode

Real-time. The player can watch the expedition scene.
Expeditions only progress while the app is open and pause when it goes to background. No offline expedition progress (town timers do progress offline, `DECISIONS.md` D24).
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

## Implementation (Phase 4)

- `ExpeditionService` owns the rules: validation, Hunter lifecycle, XP/gold per kill, success/failure rewards. Emits `expedition_started`, `section_started`, `expedition_finished`, `autosave_requested`.
- `ExpeditionScene` (one per map) owns pacing and presentation: party walks to a section's rally marker → that section's enemies spawn at its markers → when cleared, walk to the next → boss at the boss arena → walk to the exit → `complete()`. Party wipe → `fail()`.
- Gold drops go to the stash during the run (items in Phase 5). Repeat boss clears halve the boss's gold.
- Main switches hub ↔ expedition with a fade, shows a VICTORY/DEFEAT banner for 2 s, and pauses the scene tree while the app is in background.

## Warehouse overflow

If returning items exceed Warehouse capacity, the overflow is auto-sold at sell price and reported to the player.
