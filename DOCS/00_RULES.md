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

## 12. Never

- rewrite unrelated code
- delete working systems without reason
- hide gameplay rules in UI
- invent arbitrary systems just to fill gaps
- create massive files unnecessarily
- optimize without evidence
- claim success without validation
