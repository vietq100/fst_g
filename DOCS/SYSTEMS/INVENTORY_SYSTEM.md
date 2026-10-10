# INVENTORY SYSTEM

## Inventory

One shared town inventory.

Stores:
- materials (Iron Ore, Beast Fang, Dark Essence)
- equipment not currently equipped
- consumables (category only, no items in MVP)

Gold is not an item; it is a separate numeric value.

## Capacity

Capacity is measured in slots and set by Warehouse level (`BALANCE.md`).
- one stack of a material = one slot (max stack 99)
- one equipment item = one slot
- equipped items do not use slots

Overflow on expedition return is auto-sold at sell price.

## Stackable

Materials are stackable.

Equipment is individual (each has a unique instance id).

## Operations

- add
- remove
- count
- has
- equip
- unequip
- sell
- craft (via Blacksmith recipes)

All operations should validate item IDs, quantities and capacity.

## Equipment

Slots:
- weapon
- armor
- accessory (supported in data, no items in MVP)

## Implementation (Phase 5)

- `InventoryService`: `add_item` (returns how many fit), `remove_item`, `remove_instance`, `count`, `has`, `sell_item`, `sell_instance`, `used_slots`, `free_slots`; signal `inventory_changed`.
- Stacks fill the last started stack first; a new stack needs a free slot.
- Equipment instances get ids `e_<n>`. Every owned instance is tracked; equipped ones are mapped to their Hunter, use no slot, are not listed as stored and cannot be sold.

## Equipment and crafting (Phase 7)

- `EquipmentService.equip(hunter, instance)` swaps with whatever is in that slot (the swap never needs a free slot); `unequip` needs a free slot; nothing can be changed while the Hunter is on an expedition.
- Equipment modifiers enter the stat pipeline through `HunterService.add_modifier_source`.
- New recruits (and the new-game Hunter) get the class `starting_items` equipped directly (Rusty Sword, Leather Armor).
- `equip_best` (Hunter panel button) equips the strongest stored item per slot.
- `CraftingService` (Blacksmith): needs the recipe's Blacksmith level, gold, materials and one free slot.
- Equipped items are visible on the placeholder: blade colour = weapon `tint`, body colour = armor `tint` (CHARACTER_DESIGN.md §10).
- `capacity` defaults to 40 (Warehouse Lv1) until the Warehouse sets it in Phase 6.
- `LootService.roll(table_id)` rolls each entry independently; enemies use their `loot_table_id`, the boss uses the expedition's first-clear / repeat table.
- Expedition loot goes to the run stash and is granted on return: 100% on success, 50% (rounded down per item) on failure; what does not fit is auto-sold and reported.

## Modifiers

Format: `{ stat, type: "flat" | "percent", value }`.
Final stat = `(base + level_growth + Σflat) × (1 + Σpercent)`.
