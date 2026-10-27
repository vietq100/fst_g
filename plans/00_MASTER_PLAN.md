# MASTER PLAN — Dark Hunter Tycoon MVP

Source of truth: `DOCS/`. Phase order follows `DOCS/ROADMAP/ROADMAP.md` (Phase 0–11).
Each phase has its own file in this folder, written with the `DOCS/ROADMAP/AGENT_TASK_TEMPLATE.md` structure.

## Platform

Mobile (Android + iOS), portrait, touch (`DECISIONS.md` D20, D23). Town progresses offline, expeditions do not (D24). Desktop is for development only.

## Goal

Playable vertical slice:

Town → recruit/summon Hunter (with traits, class, tier) → Hunters hunt autonomously → auto combat with class skills → loot → sell to village → craft food/medicine → upgrade buildings → save/load

No endgame. Bosses and regions are milestones, not endings.

## Phases

### Core loop (Phase 0–11c) — all ✅ done

| # | Phase | File | Result |
|---|---|---|---|
| 0 | Foundation ✅ | `PHASE_00_FOUNDATION.md` | Project skeleton, autoloads, data registry |
| 1 | Character ✅ | `PHASE_01_CHARACTER.md` | Warrior with stats/HP, placeholder visuals |
| 2 | Enemy ✅ | `PHASE_02_ENEMY.md` | Slime, targeting, movement |
| 3 | Combat ✅ | `PHASE_03_COMBAT.md` | Auto combat, damage, death, feedback |
| 4 | Expedition ✅ | `PHASE_04_EXPEDITION.md` | Dark Forest run, boss, completion, return |
| 5 | Loot ✅ | `PHASE_05_LOOT.md` | Loot tables, gold, materials, inventory |
| 6 | Town ✅ | `PHASE_06_TOWN.md` | Town scene, buildings, upgrades |
| 7 | Equipment ✅ | `PHASE_07_EQUIPMENT.md` | Weapon/armor, stat modifiers |
| 8 | Hunter Life ✅ | `PHASE_08_HUNTER_LIFE.md` | Traits, mood, activities, bonds, history |
| 9 | Save ✅ | `PHASE_09_SAVE.md` | Versioned save/load, autosave, migration |
| 10 | UI ✅ | `PHASE_10_UI.md` | HUD and panels (later extended by D62–D83) |
| 11 | World redesign ✅ | `PHASE_11_WORLD.md` | Isometric world, autonomous Hunters, needs, Houses, building placement, bodies, purses (D27–D37) |
| 11b | Village economy ✅ | `PHASE_11B_VILLAGE.md` | Chief role, materials sold to the village, food and medicine crafting, Temple revival, cleanup staff, XP rebalance (D38–D44) |
| 11c | Classes and talents ✅ | `PHASE_11C_CLASSES.md` | Ranger, Rogue, Guardian; Cook / Herbalist talents crafting in the field (D45–D46) |

### Post-core systems (D54–D83) — implemented, some unvalidated

These systems were added after the core loop by owner request. They do not have separate plan files; each is documented in `DOCS/DECISIONS.md`.

| Decision | System | Status |
|---|---|---|
| D54–D57 | Isometric diamond grid, 44×22 tile, rounded corners, smaller map | ✅ Done |
| D58 | Hunter Gate (hiring/expel) + Weekly Boss (Abyss Warden) | ✅ Done |
| D59 | Full-body gear: 10 slots (weapon, helmet, top, pants, boots, necklace, ring, charm, skin, pet) | ✅ Done |
| D60 | Tiers for Hunters, items, monsters, bosses (C–MR) | ✅ Done |
| D61 | Localization: every text is a translation key, en + vi | ✅ Done |
| D62 | Hunter cards (3/row, tier colour, figure, class, reincarnation) | ✅ Done |
| D63 | Market building (buys Hunter loot into Warehouse) | ✅ Done |
| D64–D65 | Item details modal + weapon durability | ✅ Done |
| D66 | Equip picker modal straight from paper doll | ✅ Done |
| D67 | Larger chibi Hunters 23×44 (superseded by D73 Forge) | ✅ Done → replaced |
| D68 | Colosseum design (1v1, 4v4, 6v6) | Design only |
| D69–D70 | Class skills (30/class, 7/Hunter), mana, skill levels, reincarnation | ✅ Done |
| D71 | Monster loadouts + ground loot + monster dialog | ✅ Done |
| D72 | Colosseum phase 1 (1v1 simulated, no rewards yet) | ✅ Done |
| D73–D76 | Character Forge (Pixel Hero Forge art, mixed-res rendering, attack FX, rear view) | ✅ Code done, ⚠️ Godot unvalidated |
| D77 | Forge acolytes, building thumbnails, barber, day/night, class skill effects | ✅ Code done, ⚠️ Godot unvalidated |
| D78 | Synthesized audio (chiptune SFX + music, no audio files) | ✅ Code done, ⚠️ Godot unvalidated |
| D79 | Readability pass: monsters, UI, buildings, camera, combat feedback, facing, shadows | ✅ Code done, ⚠️ Godot unvalidated |
| D80 | Stat grades: colour ladder, averages, grade totals, equip picker | ✅ Code done, ⚠️ Godot unvalidated |
| D81 | Dungeon HUD (mana, status dots), toast icons, Lv3 buildings, idle strolls | ✅ Code done, ⚠️ Godot unvalidated |
| D83 | Summoning tickets, active cap (24), Hibernation Mount (100 sleepers), reveal modal | ✅ Code done, ⚠️ Godot unvalidated |

### Art and tooling

| # | Phase | File | Result |
|---|---|---|---|
| 13 | Character Forge | `PHASE_13_CHARACTER_FORGE.md` | Pixel Hero Forge art replaces chibi; code done steps 1–7, Godot unvalidated (D73–D76) |
| 12 | Polish | `PHASE_12_POLISH.md` | Balance pass, performance, export presets, device test (art/VFX/audio already done) |

## Decisions and numbers

All previously open questions and doc conflicts are resolved in:
- `DOCS/DECISIONS.md` — D1–D83 (expedition mode, party, defeat, currencies, town, isometric world, full gear, tiers, localization, class skills, mana, monster loadouts, Colosseum, Character Forge, audio, readability, stat grades, summoning)
- `DOCS/BALANCE.md` — numbers for all MVP content (stats, economy, XP curve, regions, needs, tiers, classes, stat grades)

If a new conflict appears: report it, do not silently pick one (`00_RULES.md` §1).

## Per-task workflow (from `00_RULES.md`)

1. Read relevant docs
2. Inspect existing project
3. Identify dependencies
4. Implement the smallest complete slice
5. Run/validate
6. Fix errors
7. Update docs if design/architecture changed
8. Report: implemented, files changed, validation, known limitations, next step

## Global constraints

- Typed GDScript, small focused scripts
- Static definitions as Resources, runtime state separate, UI never owns state
- Signals for decoupling; no fragile deep node paths
- No plugins unless requested
- Never claim success without running/validating
- Save IDs and data, never live Nodes
- Every player-facing text is a translation key (en + vi)

## Milestones

- **M1 – Combat sandbox ✅:** end of Phase 3
- **M2 – Expedition loop ✅:** end of Phase 5 (expedition + loot)
- **M3 – Management loop ✅:** end of Phase 8 (town + equipment + Hunter life)
- **M4 – Vertical slice ✅:** end of Phase 10 (save + UI)
- **M5 – Living world ✅:** end of Phase 11c (isometric world, autonomous Hunters, village economy, classes)
- **M6 – Full systems ✅ (code):** D54–D83 (isometric grid, tiers, class skills, Forge art, audio, summoning)
- **M7 – Godot validated:** all D73–D83 code passes tests and visual inspection in Godot 4.7
- **M8 – First device build:** Android export preset, APK on a real device
- **M9 – MVP polished:** balance pass, performance, export presets (Phase 12)
