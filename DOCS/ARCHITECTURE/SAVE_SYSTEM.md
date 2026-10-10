# SAVE SYSTEM

## Format

- Single slot, JSON at `user://save.json`
- Backup at `user://save.bak.json`

## Schema

Minimum:
- schema_version
- gold
- day_counter
- town (level, unlocked flags such as first_boss_clear)
- buildings (id → level)
- hunters (identity, level, xp, hp, injured/recovery, equipment, trait_ids, mood, activity, history)
- bonds (pairs of Hunter IDs + value)
- inventory (material stacks + equipment instances; materials are items, not a separate field)
- tavern_candidates
- expeditions (completion / first-clear flags)

## Rules

Never save Node instances.

Save:
- IDs
- primitive values
- arrays
- dictionaries
- resource identifiers

Expeditions in progress are not saved in MVP. Quitting during an expedition returns the party to town without rewards on next load.

## Autosave

- expedition end
- recruitment
- building upgrade
- crafting
- quit

## Versioning

Every breaking schema change increments schema_version.

Support migrations.

## Safe save

1. serialize
2. write temp
3. verify
4. replace
5. keep previous file as backup

## Validation

Test:
- new game
- normal save
- reload
- missing fields
- extra fields
- invalid item IDs
- invalid Hunter IDs
- corrupt JSON (fall back to backup)
