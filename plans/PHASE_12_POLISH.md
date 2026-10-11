# PHASE 12 — Polish

Do not start while the core loop is broken.

## Read first
- `DOCS/DESIGN/ART_DIRECTION.md`, `ASSET_SPEC.md`, `VFX_DESIGN.md`, `AUDIO_DESIGN.md`

## Goal
Make the vertical slice look, sound and feel like the target, and stable.

## Tasks
- [ ] Replace placeholders with final art per `ASSET_SPEC.md` (snake_case names, predictable paths)
- [ ] Animations: idle, walk, attack, hit, injured, death, victory
- [ ] VFX: hit flash, crit, death, loot sparkle, level-up, boss attack effects (no excessive screen shake)
- [ ] Audio: music (town, wilderness, boss) and required SFX list
- [ ] Balancing pass; update `DOCS/BALANCE.md`
- [ ] Performance check on mid-range Android + iPhone (60 fps target, battery, memory)
- [ ] Export presets: Android (AAB/APK), iOS (Xcode project); app icon, splash, portrait lock
- [ ] Exclude `tests/` from exports
- [ ] Bug fixing and regression tests

## Acceptance criteria
- [ ] Art swaps required no gameplay code changes
- [ ] Silhouettes readable at gameplay zoom
- [ ] No runtime errors across full slice
- [ ] Balance values documented

## Milestone
**M5 – MVP polished**

## After MVP
Open-ended expansion: new regions, classes, traits, bond levels, life events. No final phase.
