# PHASE 7 — Equipment

## Read first
- `DOCS/00_RULES.md`
- `DOCS/SYSTEMS/INVENTORY_SYSTEM.md`
- `DOCS/DESIGN/ITEM_DESIGN.md`
- `DOCS/ARCHITECTURE/DATA_SPEC.md`

## Goal
Hunters can equip weapon and armor that change their stats.

## Tasks
- [ ] Slots: weapon, armor (accessory slot supported in data, optional in MVP)
- [ ] Apply modifier format `{stat, flat|percent, value}` (D18)
- [ ] Equip/unequip via inventory service, validate slot and ownership
- [ ] Stat pipeline in `StatService`: base + level + equipment (traits/mood/bond plug in during Phase 8)
- [ ] Items from `BALANCE.md`: Rusty Sword, Leather Armor (starting), Iron Sword, Iron Armor, Fang Blade
- [ ] Blacksmith `RecipeDefinition`s; Fang Blade needs Blacksmith Lv2 + Dark Essence (D7)
- [ ] Icons/rarity display placeholders

## Acceptance criteria
- [ ] Equipping changes combat stats correctly
- [ ] Unequip returns item to inventory
- [ ] Invalid equips rejected
- [ ] Tests cover stat aggregation and equip rules

## Completion report
Implemented / Files changed / Validation / Known limitations / Next step (Phase 8)
