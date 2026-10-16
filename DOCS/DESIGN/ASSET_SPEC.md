# ASSET SPECIFICATION

## Purpose

This document defines what assets are required and how they should be prepared.

## Environment

MVP:
- grass tile
- dirt path
- forest floor
- tree
- rock
- bush
- water if needed
- town road
- wall/fence

## Buildings

MVP:
- Town Hall
- Tavern
- Blacksmith
- Hospital
- Warehouse

Each needs:
- world sprite
- optional upgrade variant
- UI icon

## Characters

MVP:
- Warrior Hunter
- Slime
- Goblin
- Wolf
- Forest Guardian

Required:
- idle
- movement
- combat
- hit/death as practical

## UI

- resource icons
- class icons
- item icons
- building icons
- buttons
- panels
- status icons

## Asset naming

Use snake_case.

Examples:
- hunter_warrior_idle.png
- enemy_slime_idle.png
- building_tavern_lv1.png
- item_iron_sword.png

## Source separation

Keep generated/source assets outside runtime folders when appropriate.

Runtime assets should have predictable paths.

## Character Forge export (D73)

The Hunter art comes from the HTML tool `tools/character_forge/pixel-character.html`. After changing it, re-export the data and the golden test fixtures (Node 18+, dev tool only):

```bash
node tools/character_forge/export_forge.js
```

It writes `actors/hunter/forge/forge_data.json` (parts, items, animations, effects, constants) and `tests/fixtures/forge_golden/*.json` (reference output of the original engine: `compose.json` for 49 configurations including every weapon's wind-up and swing pose without effects (`pose_*`), `ramp.json`, `weapons.json`). Weapons and glasses are shapes in the HTML; glasses are exported already rasterised at 2.5x, weapons are ported by hand (`forge_shapes.gd`) and checked against `weapons.json`.

In game, `ForgeFrame` bakes each composed frame into a few textures (one per run of same-size cells: 1× body, 1.5× clothes, 2× weapon, 2.5× glasses) drawn with a 1/res transform; `ForgeLook` caches them by look and frame state, shared by every Hunter.

To check the art without Godot, render sprite sheets with the original engine (D77):

```bash
node tools/character_forge/export_sheets.js
```

It writes PNGs to `build/forge_sheets/` (git-ignored; optional arguments: output folder, pixels per character pixel, default 4): `classes.png` (each class look as the game maps it: idle, breath, blink, rear view, attack sequence), `hair.png` (the 18 styles front and rear), `hats.png`, `tops.png`, `weapons.png` (rest pose and fire attack sequence).
