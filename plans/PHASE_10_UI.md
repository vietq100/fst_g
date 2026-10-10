# PHASE 10 — UI

## Read first
- `DOCS/00_RULES.md`
- `DOCS/DESIGN/UI_DESIGN.md`
- `DOCS/ARCHITECTURE/UI_ARCHITECTURE.md`

## Goal
Replace debug panels with the real UI for the full vertical slice.

## Tasks
- [ ] HUD: Gold, Materials, Town level; Hunter status; Expedition status
- [ ] Hunter panel: portrait, name, class, level, HP, XP, equipment, traits, mood, activity, bonds, history
- [ ] Tavern/recruit panel
- [ ] Expedition preparation panel: destination, recommended level, enemy preview, rewards, party (mood/traits/bonds shown), start button
- [ ] Inventory panel
- [ ] Building panel: name, level, function, upgrade cost, requirements
- [ ] Activity assignment UI
- [ ] Notifications, loot popup, level-up effect, progress bars
- [ ] Button states: available / unavailable / selected / dangerous

## Technical requirements
- Button → Controller → Service → signal → UI refresh
- Event-driven refresh; no full rebuild per frame
- UI never owns game state

## Acceptance criteria
- [ ] Whole vertical slice playable without debug panels
- [ ] Failed actions show clear feedback
- [ ] No gameplay logic in UI scripts
- [ ] Text readable at target resolution

## Milestone
**M4 – Vertical slice**

## Completion report
Implemented / Files changed / Validation / Known limitations / Next step (Phase 11)
