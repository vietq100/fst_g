# CHARACTER SYSTEM

See also: `HUNTER_LIFE_SYSTEM.md` (traits, mood, bonds, town life).

## Definition vs individual

`HunterDefinition` is a **class template** (e.g. Warrior): base stats, growth, sprite set, recruit cost.

Each recruited Hunter is a `HunterRuntime` with its own identity (name, appearance, stat rolls, traits).

## Runtime model

HunterRuntime:
- unique_id
- definition_id (class)
- display_name
- accent_index (colour accent from the art palette; more appearance variants later)
- stat_rolls (±10% on HP/Attack/Defense)
- level
- xp
- current_hp
- injured (bool) and recovery_remaining
- equipment (item instance ids per slot)
- trait_ids
- mood
- activity
- history
- state
- expedition_id

Bonds between Hunters are stored separately (pairs of unique_ids), not inside HunterRuntime.

## Definition

HunterDefinition:
- id
- class display name
- base stats and per-level growth
- portrait / sprite references
- recruit cost

## Lifecycle

Expedition cycle:

AVAILABLE
→ ASSIGNED
→ TRAVELING
→ COMBAT (may become DOWNED at 0 HP)
→ RETURNING
→ RECOVERING (if injured) or AVAILABLE

## Town states

When not on an expedition, a Hunter is in town with an activity:

- RESTING (Tavern)
- TRAINING (Training Yard)
- SOCIALIZING (Tavern)
- RECOVERING (Hospital, forced while injured)

`AVAILABLE` = in town, not injured, eligible to be assigned. Low mood does not block assignment in MVP.

## Level cap

Max level = Town Hall level × 10 (configurable). XP above the cap is not lost; it is stored until the cap rises.

## MVP

Only Warrior is required as a class.

Traits, mood and one bond level are required in MVP (see `HUNTER_LIFE_SYSTEM.md`).

Architecture must allow additional classes without rewriting the Hunter core.
