# PHASE 10 — UI — ✅ DONE (2026-10-11)

## Read first
- `DOCS/00_RULES.md`
- `DOCS/DESIGN/UI_DESIGN.md`
- `DOCS/ARCHITECTURE/UI_ARCHITECTURE.md`

## Goal
Replace debug panels with the real UI for the full vertical slice.

## Tasks
- [x] Mobile portrait layout: bottom navigation bar, bottom sheets, safe area, ≥ 40 px touch targets, fonts ≥ 10/12 (D23)
- [x] HUD: Gold, Dark Essence, Warehouse usage, Town level; expedition status
- [x] Hunter panel: portrait, name, class, level, HP, XP, equipment, traits, mood, activity, bonds, history
- [x] Tavern/recruit panel (inside the Tavern building sheet)
- [x] Expedition preparation panel: destination, recommended level, enemy preview, rewards, party (mood/traits/bonds shown), start button
- [x] Inventory panel
- [x] Building panel: name, level, function, upgrade cost, requirements
- [x] Activity assignment UI (Hunter panel: Auto / Rest / Train / Social)
- [x] Notifications (toasts), loot popup, level-up effect, progress bars
- [x] Button states: available / unavailable / selected / dangerous
- [x] "While you were away" summary sheet; expedition result sheet

## Acceptance criteria
- [x] Whole vertical slice playable without debug panels (new game → hire → equip/craft → choose party → expedition with HUD → result → hospital → upgrade)
- [x] Failed actions show clear feedback (disabled button + reason label, error toasts)
- [x] No gameplay logic in UI scripts (sheets read services, call their actions, rebuild on signals)
- [x] Text readable at target resolution (fonts 10/12/15 at 360 px wide)

## Milestone
**M4 – Vertical slice**

## Completion report

### Implemented
- `ui/ui_root.gd`, `ui/theme/game_theme.gd`, `ui/kit/ui_kit.gd`, `ui/widgets/hunter_portrait.gd`, `ui/hud/expedition_hud.gd`
- Sheets: `Sheet` base, `BuildingSheet`, `HuntersSheet`, `HunterSheet`, `ExpeditionSheet`, `InventorySheet`, `MessageSheet`
- Main: UIRoot wiring, modes (town / expedition / sandbox), result sheet after returning, offline sheet (≥ 60 s away)
- Town: `building_tapped` / `hunter_tapped` / `depart_failed` signals, `input_blocker`, `depart(expedition_id, party)`; building panels removed from the debug panel (it now holds developer tools only and starts collapsed)

### Validation
- Unit tests: 114 passed (new: every sheet builds against live services without errors, action errors become toasts, empty party cannot depart, duration/modifier formatting, touch target and font-size rules)
- Real input routing (simulated mouse clicks, mouse → touch emulation): nav button opens the Hunters sheet without selecting a building; tapping the Tavern in the world opens its sheet; tapping inside an open sheet does not reach the building underneath
- Full run driven through the UI: expedition sheet → Depart → walk to gate → expedition HUD (area progress, found loot, party HP) → VICTORY → result sheet in town
- Offline: 3 h away → "While you were away" sheet with recoveries and training XP
- Rendered frames checked for Tavern, Hunters, Hunter, Blacksmith, Expedition, Inventory, Hospital, expedition HUD, result sheet
- Main scene runs with no errors/warnings
- Bugs found and fixed: text columns collapsing to one character per line in card rows (vbox did not expand); stretched portraits; effect values shown as "4.0"; the offline XP line read as per-Hunter

### Known limitations
- Safe-area margins are only applied on mobile and are untested on a real device with a notch.
- No icons yet (coloured swatches and text); art comes in Phase 11.
- The test runner prints GDScript class-reference "leaks" at exit when the UI tests run (engine shutdown noise; the game itself exits cleanly).
- Balance issue from Phase 9 (offline training XP) is still open.

### Next step
Phase 11 — Polish.
