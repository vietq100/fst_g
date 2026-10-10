# PHASE 9 — Save — ✅ DONE (2026-10-11)

## Read first
- `DOCS/00_RULES.md` §10
- `DOCS/ARCHITECTURE/SAVE_SYSTEM.md`

## Goal
Reliable, versioned save/load of the full game state.

## Tasks
- [x] Schema per `SAVE_SYSTEM.md` (gold, progress/day, buildings, hunters, bonds, inventory incl. equipped, tavern candidates, expedition flags, activity time)
- [x] Single slot `user://save.json` + backup; in-progress expeditions not saved (party written back in town, downed → injured) (D21)
- [x] Serialize IDs/primitives only; never Nodes
- [x] Reconstruct runtime objects from IDs via `DataRegistry`
- [x] Safe write: serialize → temp → verify → backup → replace
- [x] Autosave on expedition end, recruitment, building upgrade, crafting, app background, window close (coalesced to one write per frame)
- [x] `saved_at_unix`; on load/resume apply offline town progress (capped 8 h, negative ignored) + "while you were away" summary (D24)
- [x] Pause expedition when the app goes to background (Main, since Phase 4)
- [x] Migration framework (`schema_version`, step-wise `migrate`)
- [x] Load validation: missing fields, extra fields, invalid item IDs, invalid Hunter IDs, corrupt JSON → backup → new game

## Acceptance criteria
- [x] New game, save, reload gives identical state
- [x] Corrupt/partial files do not crash; backup used when possible
- [x] Migration test from an older schema passes
- [x] Tests cover all validation cases above

## Completion report

### Implemented
- `save/save_codec.gd` (capture / restore / migrate), `core/save_manager.gd` (files, autosave, offline catch-up, summary)
- `to_dict` / `from_dict` with validation on `HunterRuntime`, `HunterService`, `InventoryService`, `BondService`, `ProgressService`, `RecruitmentService`; `EquipmentService.validate_all`, `TraitService.validate`, `ActivityService` accumulator
- `GameManager.build(registry)` (fresh game instances for tests), `reset_to_new_game`, unified `autosave_requested`
- Main shows "While you were away …" and load warnings in the status line; Town debug panel has Save / New game

### Validation
- Unit tests: 109 passed (new: full round-trip of a rich game compared as canonical JSON, file save/load + temp file gone + backup created, corrupt save → backup, both corrupt → new game, missing/extra/malformed fields, invalid item/instance/trait/class/bond ids dropped and reported, migration 0 → 1 and newer schema refused, expedition in progress → party back in town with the downed Hunter injured, offline cap 20 h → 8 h and negative elapsed ignored)
- Two real launches: session 1 (new game → recruit → upgrade → lost expedition) autosaved on new game / recruitment / expedition end; session 2 restored gold, roster, injuries, mood, Warehouse Lv2 and materials with no warnings, and the Hospital timers advanced by the 3.5 s the app was closed
- Background/resume: background save written; 2.5 s in background applied on resume
- Rendered frame: "While you were away: Away 2h 00m, recovered: …, +XP training, level-ups" in the status line
- Main scene runs with no errors/warnings
- Bug found and fixed: HP was clamped before equipment was restored (lost armor HP on load)

### Known limitations
- **Balance:** offline training is very strong — 2 h away took a fresh roster to the level cap (noted in `BALANCE.md`, Phase 11).
- The "while you were away" summary is a status line until the real sheet (Phase 10).
- Saves are not encrypted or signed (not required for MVP).
- Only one migration exists (0 → 1, illustrative); real migrations start with the first breaking change.

### Next step
Phase 10 — UI (stopped here as requested).
