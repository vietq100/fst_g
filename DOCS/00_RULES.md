# DARK HUNTER TYCOON — MASTER RULES

## 1. Agent priority

Read this file first.

Priority:
1. This file
2. Explicit user request
3. Project Overview
4. Decisions (`DECISIONS.md`) and balance values (`BALANCE.md`)
5. Design documents
6. System specifications
7. Architecture
8. Roadmap

If documents conflict, do not silently choose. Preserve the higher-priority rule and report the conflict.

## 2. Product goal

Create an original 2D fantasy Hunter-management RPG in Godot 4.x.

The game is inspired by the management/idle RPG genre, but must not reproduce another game's proprietary:
- assets
- source code
- names
- characters
- maps
- UI
- dialogue
- exact layouts

Use genre inspiration only.

## 3. Engine

- Godot 4.x
- GDScript
- 2D
- Mobile game: Android and iOS, portrait orientation, touch input
- Desktop is used only for development/testing
- Pixel-art-inspired presentation

## 4. Design before implementation

Before implementing a visual/gameplay feature:
- read its design document
- understand the intended player experience
- identify required assets
- identify system dependencies
- then implement

Do not invent major visual design decisions during coding if the design documents already define them.

## 5. Architecture

Separate:
- static definitions
- runtime state
- gameplay systems
- scene presentation
- UI

UI never owns authoritative gameplay state.

## 6. Code

- Prefer typed GDScript.
- Use small, focused classes.
- Avoid giant scripts.
- Avoid duplicated logic.
- Avoid hard-coded balance values.
- Use Resources/data definitions for content.
- Use signals/events for decoupling.
- Do not use fragile deep relative node paths.
- Do not add plugins unless requested.

## 7. Assets

Gameplay must work with placeholders.

Final art must be replaceable without rewriting gameplay code.

All visual assets must follow ART_DIRECTION.md and ASSET_SPEC.md.

## 8. Scope

MVP first.

Do not implement multiplayer, online backend, monetization, PvP, guild wars or complex procedural generation unless explicitly requested.

Exception (D68): offline Hunter PvP in the Colosseum (Đấu Trường: 1vs1, 4vs4, 6vs6 against generated rival teams) is requested. See `SYSTEMS/ARENA_SYSTEM.md`.

## 9. Validation

Never claim a feature works without running or validating it.

Every completed task reports:
- implemented
- files changed
- validation
- known limitations
- next step

## 10. Save safety

Persistent state must be versioned.

Do not serialize live Godot Nodes.

Save IDs and data, then reconstruct runtime objects.

## 11. Workflow

For each task:

1. Read relevant docs.
2. Inspect existing project.
3. Identify dependencies.
4. Implement the smallest complete slice.
5. Run/validate.
6. Fix errors.
7. Update docs if architecture/design changed.
8. Report result.

## 11b. Text and localization

- Every player-facing text is a translation key, never a literal: UI labels and buttons, toasts, error reasons returned by services, texts drawn in the world, and the names / descriptions in data files.
- Keys and their English and Vietnamese texts live in `data/i18n/translations.json`; code reads them with `Loc.t(key, {placeholders})` (DOCS/ARCHITECTURE/LOCALIZATION.md).
- A new text means a new key with both `en` and `vi` in the same change. Use named placeholders (`{gold}`), never sentence fragments glued together.
- The player chooses the language in Settings. Developer-only messages (`push_error`, tests, ids) stay in English and are not keys.

## 12. Never

- rewrite unrelated code
- delete working systems without reason
- hide gameplay rules in UI
- invent arbitrary systems just to fill gaps
- create massive files unnecessarily
- optimize without evidence
- claim success without validation
- write a player-facing text literal instead of a translation key
