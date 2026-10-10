# PHASE 5 — Loot

## Read first
- `DOCS/00_RULES.md`
- `DOCS/SYSTEMS/ECONOMY_SYSTEM.md`, `INVENTORY_SYSTEM.md`
- `DOCS/DESIGN/ITEM_DESIGN.md`, `VFX_DESIGN.md`
- `DOCS/ARCHITECTURE/DATA_SPEC.md`

## Goal
Enemies drop gold and materials; items land in an inventory.

## Tasks
- [ ] `ItemDefinition` data (materials, consumables, equipment; rarity Common/Uncommon/Rare)
- [ ] Loot tables referenced by `EnemyDefinition.loot_table_id` and expedition reward table
- [ ] Gold as the only currency; Iron Ore, Beast Fang, Dark Essence as stackable items (D6)
- [ ] Inventory service: add, remove, count, has, equip hooks, sell; validate IDs, quantities, capacity (slots)
- [ ] Stackable materials (max 99); individual equipment instances
- [ ] Overflow auto-sell hook (capacity comes from Warehouse in Phase 6)
- [ ] Loot feedback: sparkle + popup

## Acceptance criteria
- [ ] Kills produce loot per table
- [ ] Inventory operations reject invalid IDs/quantities
- [ ] Gold/materials update via signals
- [ ] Tests cover loot rolls (seeded) and inventory ops

## Milestone
**M2 – Expedition loop**

## Completion report
Implemented / Files changed / Validation / Known limitations / Next step (Phase 6)
