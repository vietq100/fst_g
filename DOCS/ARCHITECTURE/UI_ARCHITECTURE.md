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

## UI refresh

Prefer event-driven updates.

Avoid rebuilding the entire UI every frame.
