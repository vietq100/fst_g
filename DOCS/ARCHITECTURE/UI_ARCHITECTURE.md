# UI ARCHITECTURE

## Principle

UI displays and requests actions.

UI does not own game truth.

## Example

GOOD:
Button
→ RecruitmentController
→ Game/HunterService
→ Hunter added
→ signal
→ UI refresh

BAD:
Button
→ directly modifies UI arrays and assumes recruitment succeeded

## UI layers

- HUD
- World interaction UI
- Panels
- Notifications
- Modal dialogs

## Implemented flow

Button (in a `Sheet`)
→ service action (e.g. `RecruitmentService.recruit`)
→ service signal (`candidates_changed`, `gold_changed`…)
→ every open sheet that watches that signal rebuilds once at the end of the frame (`Sheet._watch`, coalesced)
→ errors returned by the service are shown as toasts (`Sheet.run_action`).

World → UI: `Town.building_tapped` / `hunter_tapped` → `UIRoot.open_building` / `open_hunter`.
UI → World: `UIRoot.depart_requested(expedition_id, party)` → `Town.depart` (walk to gate) → `ExpeditionService.start`.

## UI refresh

Prefer event-driven updates.

Avoid rebuilding the entire UI every frame.
