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

The player is the **village chief** (D38): the settlement manager and the one who raises these Hunters.

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

## World structure (redesign, `DECISIONS.md` D27–D36)

One continuous **isometric world map**: the Town on top, Dark Forest (left), Ancient Ruins (right) and Goblin Cave (bottom), joined by gates. Each hunting region has dungeon entrances on its outer edges. The screen is a window onto this world: drag, zoom, or follow a Hunter.

Hunters **live on their own**: they sleep in houses, walk out to hunt in a region by themselves and sell the materials they farm to the village. The chief turns materials into food (Tavern) and medicine (Hospital) that Hunters buy with their own money. A Hunter who dies leaves a body; village staff (or another Hunter) carry it to the Temple, where it is revived at a small XP cost. The chief builds and arranges the town, crafts, equips and guides Hunters, manages money, and sends parties into dungeons.

## Core loop

Build / arrange the town (houses, buildings)
→ recruit
→ Hunters live: sleep, eat, train, socialize
→ Hunters hunt in regions on their own (or where assigned)
→ loot to the Warehouse, gold to their own purse
→ deaths: bodies carried home, revived at the Hospital
→ craft, equip, transfer money, upgrade
→ send parties into dungeons for bosses and rare loot
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

- one isometric world: Town + Dark Forest + Goblin Cave + Ancient Ruins, connected by gates
- free building placement in the Town (build, move, remove); Houses (4 beds each)
- Town Hall, Tavern, Blacksmith, Hospital, Warehouse, Houses
- autonomous hunting in the three regions; Hunter needs (HP, stamina, energy); personal purses
- bodies and corpse retrieval; revival at the Hospital
- one active dungeon (Forest Guardian's Grove, the former Dark Forest expedition), party of 1–3 Hunters; other dungeon entrances shown as locked
- camera: drag, pinch/wheel zoom, follow a Hunter
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
- **basic town life: Hunters sleep, eat, rest, train or socialize when not hunting**
- save/load

Detailed MVP decisions: `DECISIONS.md`. Starting numbers: `BALANCE.md`.
