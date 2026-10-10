# PHASE 9 — Save

## Read first
- `DOCS/00_RULES.md` §10
- `DOCS/ARCHITECTURE/SAVE_SYSTEM.md`

## Goal
Reliable, versioned save/load of the full game state.

## Tasks
- [ ] Schema per `SAVE_SYSTEM.md` (gold, day counter, town, buildings, hunters, bonds, inventory, tavern candidates, expedition flags)
- [ ] Single slot `user://save.json` + backup; in-progress expeditions not saved (D21)
- [ ] Serialize IDs/primitives only; never Nodes
- [ ] Reconstruct runtime objects from IDs via `DataRegistry`
- [ ] Safe write: serialize → temp → verify → replace → backup
- [ ] Autosave on expedition completion and key events
- [ ] Migration framework (`schema_version` bumps)
- [ ] Load validation: missing fields, extra fields, invalid item IDs, invalid Hunter IDs, corrupt JSON → safe fallback

## Acceptance criteria
- [ ] New game, save, reload gives identical state
- [ ] Corrupt/partial files do not crash; backup used when possible
- [ ] Migration test from an older schema passes
- [ ] Tests cover all validation cases above

## Completion report
Implemented / Files changed / Validation / Known limitations / Next step (Phase 10)
