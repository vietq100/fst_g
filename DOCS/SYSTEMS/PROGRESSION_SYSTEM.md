# PROGRESSION SYSTEM

The game is open-ended. There is no final level, final region or win state.
Progression must remain meaningful and never "complete".

## Two axes

- **Power growth** (this file): XP, level, equipment, class skills, town upgrades.
- **Life growth**: traits, mood, bonds, history (see `HUNTER_LIFE_SYSTEM.md`).

## Hunter XP

XP comes from:
- combat: every party member gets full XP per kill
- training in town (slower, trait-dependent)

Level up:
- increases stats
- restores some HP
- shows feedback

## XP formula

required_xp = base_xp * pow(level, 1.5), base_xp = 20

Centralize formula. Values: `BALANCE.md`.

## Level cap

Hunter max level = Town Hall level × 10 (configurable data).
This is a gate that rises with the town, not a final cap.
XP gained at the cap is kept and applied when the cap rises.

## Long-term scaling

Because there is no endgame:
- Prefer new unlock layers (class skills, specialization, higher equipment tiers, more buildings) over raw number inflation.
- Every new tier should give a new decision, not only bigger numbers.

## Town progression

Town Hall level unlocks:
- Hunter capacity
- Hunter level cap
- building upgrades
- expeditions
- equipment tiers (via Blacksmith level)

MVP milestone: first Forest Guardian clear unlocks Town Hall level 2.

Town levels are data; more can be added over time.

## Milestones (not endings)

Bosses, first clears and building levels are milestones. They:
- unlock new content
- grant rewards
- remain repeatable where sensible

They never end the game.

## Future progression

- class skills and specialization
- technology
- reputation
- new regions as optional expansions
- Hunter mentoring (bond-based skill transfer)
