# DARK HUNTER TYCOON — GAME DOCS V2

## Purpose

This folder is the source of truth for the AI coding/game-development agent.

## Reading order

1. `00_RULES.md`
2. `01_PROJECT_OVERVIEW.md`
3. `DECISIONS.md` (resolved decisions) and `BALANCE.md` (starting numbers)
4. `DESIGN/ART_DIRECTION.md`
5. relevant `DESIGN/*.md`
6. relevant `SYSTEMS/*.md`
7. relevant `ARCHITECTURE/*.md`
8. `ROADMAP/ROADMAP.md`

## Game direction

The game is open-ended: **no endgame, no final boss, no win state.**
Its goal is to build the town and nurture Hunters along two axes: power growth and life growth (traits, mood, bonds).
See `01_PROJECT_OVERVIEW.md` and `SYSTEMS/HUNTER_LIFE_SYSTEM.md`.

Since the world redesign (D27–D37) the hub is one isometric world map where Hunters live and hunt on their own; see `SYSTEMS/AUTONOMY_SYSTEM.md` and `SYSTEMS/BUILD_SYSTEM.md`.

## Design vs implementation

DESIGN answers:

> What should the game look and feel like?

SYSTEMS answer:

> What rules make the game work?

ARCHITECTURE answers:

> How should the Godot project implement those rules?

ROADMAP answers:

> What should the Agent build next?

## Important

The Agent must not invent major art direction or map layout when a design document exists.

The Agent must not implement every system at once.

Build a playable vertical slice first:

Town
→ recruit Hunter (with traits)
→ expedition
→ auto combat
→ loot
→ return
→ rest/train/socialize (mood, bond)
→ upgrade
→ save/load

## Source of truth

If implementation differs from the design documents, the Agent should identify the discrepancy and either:
- update implementation to match, or
- report that the design needs revision.
