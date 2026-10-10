# PHASE 8 — Hunter Life — ✅ DONE (2026-10-11)

## Read first
- `DOCS/00_RULES.md`
- `DOCS/SYSTEMS/HUNTER_LIFE_SYSTEM.md` (primary)
- `DOCS/SYSTEMS/CHARACTER_SYSTEM.md`, `PROGRESSION_SYSTEM.md`, `AI_SYSTEM.md`
- `DOCS/DESIGN/CHARACTER_DESIGN.md`

## Goal
Hunters feel like individuals: traits, mood, bonds, town activities and history that affect gameplay.

## Tasks
- [x] `TraitDefinition` data + 6 starter traits
- [x] 1–2 distinct traits for every candidate (and the new-game Hunter)
- [x] Trait modifiers feed the stat pipeline and activity rates only (D15); `damage_dealt` / `damage_taken` / `gold_find` multiplier stats; Brave `vs_boss`
- [x] Mood 0–100 (start 60): expedition events, trait likes/dislikes, overwork; High/Normal/Low modifiers; Low only warns (D13)
- [x] `ActivityDefinition` data + Resting / Training / Socializing / Recovering; default rule (D14); player assignment
- [x] Activity ticks every 10 s of real time (same entry point as offline catch-up)
- [x] Bonds (`BondService`): shared expedition +20, socializing +2/tick, bonded = 100; +5% attack with a bonded partner in the party; +2 mood when bonded partners socialize
- [x] History: recruit day, expeditions won/lost, bosses, injuries (+ internal counters)
- [x] Signals: `mood_changed`, `bond_changed`, `activity_changed`
- [x] Hunters walk to their activity location in town

## Acceptance criteria
- [x] Each starter trait has a visible, testable effect
- [x] Mood changes from expedition results, rest and trait likes/dislikes
- [x] Bond forms after shared expeditions/socializing and gives the defined bonus
- [x] Training grants XP at the trait-adjusted rate
- [x] Balance values live in data (`GameConfig`, traits, activities)
- [x] Tests cover trait modifiers, mood transitions, bond growth

## Completion report

### Implemented
- Services: `TraitService`, `MoodService`, `BondService`, `ActivityService`; `ProgressService` day counter; `ExpeditionService` history, boss-reached flag, party gold multiplier; `CombatService` damage multipliers; `CombatStats.damage_dealt/taken`
- Data: 6 traits, 4 activities, ~25 `GameConfig` values
- Town: activity spots, Hunter panel (traits, mood, activity buttons, bonds, history), candidate traits, low-mood warning at the gate
- Decision D26 (event tags, numbers, day length)

### Validation
- Unit tests: 100 passed (new: trait ranges and modifiers incl. vs_boss, mood states → stats/XP and clamping, expedition mood events per trait, overwork + rest reset, Brave idle cycles, default activity rule, assignments, resting HP/mood with Lazy, training XP with Disciplined, no town effects during expeditions, socializing → bonded + extra mood, shared expeditions + party bonus, bond save round-trip dropping unknown Hunters, day counter)
- In game (Main): recruits get traits and history day; first tick sends injured/hurt Hunters to rest at the Tavern, others train in the Training Yard (actors measured 14–30 px from their spot); socializing for 100 s → bond 20; after a won Dark Forest run: mood up, boss/expedition history, injured Hunter recovering, bonds 40/20
- Rendered frames: Hunters at the Training Yard and Tavern, Hunter panel with life info
- Bugs found in the in-game check and fixed: resting did not heal (actor `set_max_health` wrote the old HP back into runtime); recruits started below max HP (starting armor HP); test reference cycles leaking at exit
- Main scene runs with no errors/warnings

### Known limitations
- Mood rises quickly while resting (+2/tick, Lazy +3 and likes resting) — tune in Phase 11.
- Activity spots overlap the debug panel at the top of the screen; real UI in Phase 10.
- Life events, trait-driven AI behaviour and multi-level bonds are post-MVP.

### Next step
Phase 9 — Save.
