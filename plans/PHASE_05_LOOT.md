# PHASE 5 — Loot — ✅ DONE (2026-10-11)

## Read first
- `DOCS/00_RULES.md`
- `DOCS/SYSTEMS/ECONOMY_SYSTEM.md`, `INVENTORY_SYSTEM.md`
- `DOCS/DESIGN/ITEM_DESIGN.md`, `VFX_DESIGN.md`
- `DOCS/ARCHITECTURE/DATA_SPEC.md`

## Goal
Enemies drop gold and materials; items land in an inventory.

## Tasks
- [x] `ItemDefinition` data: Iron Ore, Beast Fang, Dark Essence; Rusty Sword, Leather Armor, Iron Sword, Iron Armor, Fang Blade (modifiers per BALANCE)
- [x] Loot tables: goblin, wolf, forest_guardian_first, forest_guardian_repeat
- [x] Gold as the only currency; materials as stackable items (D6)
- [x] `InventoryService`: add, remove, count, has, sell; validates ids, quantities, capacity (slots)
- [x] Stackable materials (max 99); individual equipment instances
- [x] Expedition stash holds items; success grants all, failure 50%; overflow auto-sold and reported
- [x] Loot feedback: sparkle + stacked "+N Item" popups in rarity colours, gold popup
- [x] Debug: stash in expedition status, inventory + "Sell mats" in hub, items in the run summary

## Acceptance criteria
- [x] Kills produce loot per table
- [x] Inventory operations reject invalid IDs/quantities
- [x] Gold/materials update via signals (`gold_changed`, `inventory_changed`)
- [x] Tests cover loot rolls (seeded) and inventory ops

## Milestone
**M2 – Expedition loop**

## Completion report

### Implemented
- `game/services/loot_service.gd`, `game/services/inventory_service.gd`, `game/runtime/kill_reward.gd`
- `ExpeditionService.record_kill` returns a `KillReward`; boss uses the expedition's first-clear/repeat table; `_grant_items` with overflow auto-sell
- `ExpeditionRun.stash_items / items_granted / items_overflowed / overflow_gold`
- `world/vfx/loot_popup.gd`, `ui/theme/rarity_colors.gd`, `ui/theme/item_text.gd`
- 8 items + 4 loot tables in `data/`

### Validation
- Unit tests: 63 passed (new: drop rates over 2000 rolls ≈ 40% / 50%, stacks and slots, equipment instances, capacity limits, validation, selling, change signal, boss first-clear loot to stash then inventory, failure halves items, overflow auto-sold, items/loot tables vs BALANCE and cross-references)
- Three expeditions in a row through Main: first clear → Iron Ore 7, Beast Fang 3, Dark Essence 2 in inventory; repeat → Dark Essence ×1 and halved boss gold, items stack into existing slots (3/40 used)
- Rendered frames: boss loot popups stacked without overlap (Dark Essence blue, materials white, gold yellow)
- Main scene runs with no errors/warnings
- Bugs found and fixed: overlapping loot popups; `ItemText` used the autoload name and broke when compiled before autoloads (now takes the registry as a parameter); untyped `Dictionary.get` inference error

### Known limitations
- Inventory capacity is a fixed 40 until the Warehouse sets it (Phase 6).
- Equipment drops (Fang Blade 10%) go to the inventory but cannot be equipped yet (Phase 7).
- No dedicated inventory UI yet (Phase 10).
- One windowed recording showed the debug panel missing for part of the boss fight; not reproduced in a second recording or in headless probes.

### Next step
Phase 6 — Town.
