# SAVE SYSTEM

## Format

- Single slot, JSON at `user://save.json`
- Backup at `user://save.bak.json`

## Schema

Minimum:
- schema_version
- saved_at_unix (real-world time, for offline progress)
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
- app paused / backgrounded (`NOTIFICATION_APPLICATION_PAUSED`, focus out)
- quit

Mobile OSes can kill a backgrounded app without warning, so the pause/background save is the important one.

## Offline progress

On load and on resume, apply `min(now - saved_at_unix, offline_cap)` to town timers (`DECISIONS.md` D24). Ignore negative values.

## Versioning

Every breaking schema change increments schema_version.

Support migrations.

## Safe save

1. serialize
2. write temp
3. verify
4. replace
5. keep previous file as backup

## Implementation (Phase 9)

- `save/save_codec.gd` — `SaveCodec.capture(game)` / `restore(game, data, warnings)` / `migrate(data, warnings)`; schema 1. Sections: `schema_version`, `saved_at_unix`, `gold`, `progress` (flags, day, day_time), `buildings` (id → level), `hunters` (`next_id`, list of `HunterRuntime.to_dict()`), `bonds` ("a|b" → value), `inventory` (stacks, instances, equipped, next_instance), `tavern_candidates`, `activity_time`. Town level and inventory capacity are derived from buildings, not saved.
- Each service owns its part (`to_dict` / `from_dict`) and validates on load: missing fields → defaults, unknown class/trait/item ids, dangling equipment and bonds → dropped and listed in `SaveManager.last_warnings`.
- Restore order: progress → buildings → Hunters → inventory → trait/equipment validation → HP clamp → bonds → Tavern → activity time.
- `core/save_manager.gd` — safe write (`.tmp` → re-read and parse → copy old save to backup → rename), load with fallback save → backup → new game, coalesced `request_autosave` (one write per frame), background save on `NOTIFICATION_APPLICATION_PAUSED` (and focus-out on mobile), save on window close, offline catch-up on load and on resume (`apply_offline_progress`, capped, negative ignored) with a "while you were away" summary.
- Autosave triggers come from `GameManager.autosave_requested` (expedition end, recruitment, building upgrade, crafting).
- Migration 0 → 1 (example/pre-release draft): top-level `materials` move into inventory stacks; missing timestamp added. A save from a newer schema is refused (falls back to backup / new game).

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
