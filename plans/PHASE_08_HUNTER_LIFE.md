# PHASE 8 — Hunter Life

## Read first
- `DOCS/00_RULES.md`
- `DOCS/SYSTEMS/HUNTER_LIFE_SYSTEM.md` (primary)
- `DOCS/SYSTEMS/CHARACTER_SYSTEM.md`, `PROGRESSION_SYSTEM.md`, `AI_SYSTEM.md`
- `DOCS/DESIGN/CHARACTER_DESIGN.md`

## Goal
Hunters feel like individuals: traits, mood, bonds, town activities and history that affect gameplay.

## Tasks
- [ ] `TraitDefinition` data + 6 starter traits (Brave, Cautious, Greedy, Disciplined, Reckless, Lazy)
- [ ] Assign 1–2 traits at recruitment (Tavern generation)
- [ ] Trait modifiers feed the stat pipeline and activity rates only — no AI behaviour changes in MVP (D15)
- [ ] Mood (0–100, start 60): events per `BALANCE.md`; High/Normal/Low effects; Low mood only warns + penalizes (D13)
- [ ] `ActivityDefinition` + activities at locations per D14; default activity rule
- [ ] Activity ticks on timers/events, not per frame
- [ ] Bonds: `BondService` stores pairs of Hunter IDs; one level (`none` → `bonded`); party bonus + mood bonus
- [ ] Hunter history: recruit date, expeditions, bosses, injuries, bonds
- [ ] Signals: `mood_changed`, `bond_changed`, `activity_changed`
- [ ] Hunters visible doing activities in town where practical

## Out of scope
Romance, dialogue trees, permadeath, multi-level bonds, life events (post-MVP).

## Acceptance criteria
- [ ] Each starter trait has a visible, testable effect
- [ ] Mood changes from expedition results, rest and trait likes/dislikes
- [ ] Bond forms after shared expeditions/socializing and gives the defined bonus
- [ ] Training grants XP at the trait-adjusted rate
- [ ] Balance values live in data
- [ ] Tests cover trait modifiers, mood transitions, bond growth

## Milestone
**M3 – Management loop**

## Completion report
Implemented / Files changed / Validation / Known limitations / Next step (Phase 9)
