# PHASE 7 — Equipment — ✅ DONE (2026-10-11)

## Read first
- `DOCS/00_RULES.md`
- `DOCS/SYSTEMS/INVENTORY_SYSTEM.md`
- `DOCS/DESIGN/ITEM_DESIGN.md`
- `DOCS/ARCHITECTURE/DATA_SPEC.md`

## Goal
Hunters can equip weapon and armor that change their stats.

## Tasks
- [x] Slots: weapon, armor (accessory supported in data, no items)
- [x] Modifier format `{stat, flat|percent, value}` applied through the stat pipeline (D18)
- [x] Equip/unequip via `EquipmentService`; validates slot, storage, expedition; swap never needs a free slot, unequip does
- [x] Stat pipeline: base + level + equipment via `HunterService.add_modifier_source`
- [x] Items: Rusty Sword + Leather Armor (starting gear, equipped on every recruit and the new-game Hunter), Iron Sword, Iron Armor, Fang Blade
- [x] Blacksmith `RecipeDefinition`s + `CraftingService`; Fang Blade needs Blacksmith Lv2 + Dark Essence (D7)
- [x] Equipped items visible on the placeholder (weapon/armor `tint`), rarity in panels

## Acceptance criteria
- [x] Equipping changes combat stats correctly
- [x] Unequip returns item to inventory
- [x] Invalid equips rejected
- [x] Tests cover stat aggregation and equip rules

## Completion report

### Implemented
- `InventoryService`: tracks equipped instances (no slot, not sellable, not listed as stored), `create_equipped`, `set_equipped/set_stored`, `to_dict/from_dict` (ready for Phase 9)
- `EquipmentService` (equip, unequip, starting gear, equip best, modifier source, validation for loads), `CraftingService`
- Data: 3 recipes, item `tint`, Warrior `starting_items`
- Town: Blacksmith panel (recipes, costs, lock reason, craft), Hunter panel (gear, Equip best, Unequip weapon)
- Hunter placeholder shows weapon/armor colours

### Validation
- Unit tests: 85 passed (new: starting gear stats 17 ATK / 9 DEF / 130 HP with no slots used, swap returns old item and changes stats, Fang Blade crit 10%, rule rejections, unequip needs a free slot, equipped items cannot be sold, equip best, crafting gold/material/level/slot checks, inventory save round-trip with equipped items; recipes vs BALANCE)
- Balance probe, 3 Warriors × 3 Dark Forest runs each: Lv 4 starting gear → 2/3 wins; Lv 4 iron gear → 3/3; Lv 3 iron gear → 3/3. The recommended level 4 now matches; Lv 3 with iron gear is slightly easy (Phase 11).
- Rendered frames: Blacksmith panel, Hunter panel, different armor colours on Hunters
- Main scene runs with no errors/warnings

### Known limitations
- No dedicated inventory/equipment screen (Phase 10). Selling equipment is only possible in code (`sell_instance`); the Warehouse button sells materials.
- Max HP gained from armor is not refilled immediately (resting heals in Phase 8).

### Next step
Phase 8 — Hunter Life.
