# PROJECT OVERVIEW

## Working title

Dark Hunter Tycoon

## Platform

Mobile (Android and iOS), portrait, touch. Short play sessions; the town keeps progressing while the app is closed (`DECISIONS.md` D24).

## Genre

2D:
- Hunter management
- Town building
- Character nurturing
- Idle/automation RPG
- Auto combat
- Open-ended progression (no final goal)

## Player fantasy

The player owns and develops a dangerous frontier settlement.

Hunters arrive, live in the town, train, bond with each other, equip themselves, travel into monster territory, fight automatically, collect resources and return.

The player acts as the settlement manager and as the one who raises these Hunters.

## Core fantasy

> Build a settlement and raise its Hunters — grow their strength and their stories, with no end except the one the player chooses.

## No endgame

The game has **no final boss, no final region and no victory screen**.

- Bosses and regions are milestones that open new content, never an ending.
- Progression must stay meaningful for as long as the player keeps playing.
- Long-term goals come from the player's own targets: a stronger town, a stronger roster, a specific Hunter build, a close-knit team.

Do not add "endgame", "final boss" or "win condition" features.

## Two growth axes

Both are first-class. Neither is "future work".

### A. Power growth (strength)
Level, equipment, stats, class skills, town upgrades.

### B. Life growth (character)
Traits, mood, relationships/bonds, personal history, life in town.

Power growth makes Hunters capable.
Life growth makes them individuals the player cares about.
Each axis must influence the other (see `SYSTEMS/HUNTER_LIFE_SYSTEM.md`).

## Core loop

Recruit
→ care for (rest, train, socialize)
→ prepare
→ assign
→ expedition
→ auto combat
→ loot
→ return
→ recover
→ upgrade
→ unlock
→ repeat

## Design pillars

### Living Hunters
Hunters are persistent individuals with personality, mood and relationships, not disposable units.

### Nurture over Conquest
The player's reward is watching Hunters and the town grow, not reaching an end state.

### Visible Town Growth
The town should visibly communicate progression.

### Meaningful Risk
Harder expeditions give better rewards but increase danger and affect Hunter mood and condition.

### Automation
Routine combat is automated.

### Management
The player makes decisions rather than manually attacking every enemy.

## MVP

- one town
- Town Hall, Tavern, Blacksmith, Hospital, Warehouse
- one expedition region (Dark Forest), party of 1–3 Hunters
- one Hunter class
- three normal enemies
- one boss (a milestone, repeatable)
- basic auto combat
- basic loot
- inventory
- equipment
- XP/level
- gold (only currency) and material items (Iron Ore, Beast Fang, Dark Essence)
- **traits (small starter set with real gameplay effect)**
- **mood/morale (simple)**
- **bonds between Hunters (simple, one level)**
- **basic town life: Hunters rest, train or socialize when not on expedition**
- save/load

Detailed MVP decisions: `DECISIONS.md`. Starting numbers: `BALANCE.md`.
