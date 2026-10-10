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

## Modifiers

Format: `{ stat, type: "flat" | "percent", value }`.
Final stat = `(base + level_growth + Σflat) × (1 + Σpercent)`.
