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
