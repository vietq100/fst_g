# PHASE 12 — Polish

Do not start while M7 (Godot validation of D73–D83) is incomplete.

## Read first
- `DOCS/DESIGN/ART_DIRECTION.md`, `ASSET_SPEC.md`, `VFX_DESIGN.md`, `AUDIO_DESIGN.md`
- `DOCS/DECISIONS.md` D73–D83

## Goal
Make the vertical slice stable on a real device, balance tuned, exports ready.

## Already done (by earlier phases)

| Area | Done by | What |
|---|---|---|
| Hunter art | D73–D76 (Phase 13) | Pixel Hero Forge: 18 hair, 14 tops, 9 weapons, 7 attack sequences, 6 element effects, rear view, mixed-res rendering |
| Monster art | D71 | MonsterBodies 2× (EPX upscale), silhouette outlines; wolf/goblin/skeleton/slime/Forest Guardian redrawn |
| Prop art | D71 | Trees (leafy, pine, apple, blossom), boulders (moss, crystal), columns (ivy, rubble) |
| Building art | D55, D79 | Isometric boxes with roofs, emblems, windows, lanterns, Lv2/Lv3 variants |
| VFX | D75, D76 | Forge attack effects (slash, ring, burst, glow, strike, particles, column, aura), class/monster skill effects, combat feedback (knockback, merge, camera shake) |
| Audio | D78 | Synthesized chiptune SFX + music (no audio files), 3 music tracks, ~20 SFX |
| Animations | D73, D79 | Forge per-weapon attack sequences, walk speed scaling, idle breathing/blink, death lying |
| UI polish | D62–D66, D79–D81 | Hunter cards, item modals, stat grade colours, toast icons, dungeon HUD, facing hysteresis |

## Remaining tasks

### Balance
- [x] Economy numbers review: Hunters earn more than they spend; treasury slowly drains (added trader tax and tavern drinks revenue streams)
- [x] XP curve verification at all level ranges (Lv1→50→100); reincarnation pacing (supported up to TH Lv10)
- [ ] Region difficulty progression (Forest → Cave → Ruins) with gear expectations
- [ ] Dungeon recommended levels with gear
- [ ] Tier drop rates and stat scales — do higher tiers feel meaningful?
- [x] Weapon durability wear rate vs repair cost (`equipment_service.gd`)
- [x] Summoning ticket sources (boss clears, quests, shop — designed and implemented)
- [x] Update `DOCS/BALANCE.md` with final numbers

### Performance
- [ ] Performance check on mid-range Android + iPhone (60 fps target, battery, memory)
- [ ] 30 Hunters on screen: first bake < 5 ms, cached frames (Phase 13 §6.5)
- [ ] World ground drawing with culled strips (D75 lighter drawing) — verify no frame drops
- [ ] Day/night tint layer cost
- [ ] Audio synth render cost (first use; music thread)

### Export and device
- [x] Export presets: Android (AAB/APK), iOS (Xcode project) (`export_presets.cfg`)
- [x] App icon, splash, portrait lock (`icon.png`, `splash_screen.png`, `project.godot`)
- [x] Exclude `tests/` and `tools/` from exports
- [ ] Safe-area margins tested on a device with a notch (noted in Phase 10)
- [ ] Touch input verification on real device (no hover/keyboard dependency)
- [ ] First Android device smoke test (blocked since Phase 3)

### Bug fixing
- [ ] Run full test suite on Godot 4.7: all D73–D83 code (many written without Godot on hand)
- [ ] Visual inspection in test arena: 4 classes × 4 facings × all gear × all animations
- [ ] Regression tests for any fixes
- [x] Save migration chain: schema 1 → 2 → 3 → 4 (all verified in `test_save.gd` & `test_summoning.gd`)

## Acceptance criteria
- [ ] Art swaps required no gameplay code changes
- [ ] Silhouettes readable at gameplay zoom
- [ ] No runtime errors across full slice
- [ ] Balance values documented in `BALANCE.md`
- [ ] 60 fps on mid-range device
- [ ] APK/AAB runs on a real Android device

## Milestone
**M9 – MVP polished**

## After MVP
Open-ended expansion: new regions, classes, traits, bond levels, life events, Colosseum 4v4/6v6, ranked rewards. No final phase.
