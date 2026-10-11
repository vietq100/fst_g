# PHASE 11b — Village economy (owner request, D38–D44)

The player is the village chief. Hunters farm materials and sell them to the village; the chief turns them into food (Tavern) and medicine (Hospital) that Hunters buy back. A Temple revives the dead at an XP cost; two village staff carry bodies home. XP curve and offline training rebalanced.

## Read first
`DOCS/DECISIONS.md` D38–D44, `DOCS/BALANCE.md` → Village economy / Bodies / Formulas, `DOCS/SYSTEMS/AUTONOMY_SYSTEM.md`.

## Sub-phases
### V1 — Rebalance
- [x] XP curve `30 × L^2.2`; training +1 XP/tick; offline training ×0.25

### V2 — Materials sold to the village
- [x] Items Slime Gel, Raw Meat, Wild Herb, Bone Dust; loot tables (slime new, goblin, wolf, skeleton)
- [x] Deposit = village buys (treasury → purse); overflow to the trader (purse)

### V3 — Food and medicine
- [x] Consumable fields (energy, heal ratio); recipes per building with output quantity
- [x] Tavern: Meat Stew, Herb Soup; Hospital: Bandage, Healing Potion
- [x] Eating takes food from stock (best affordable); medicine bought at the Hospital when resting at low HP
- [x] New village starts with 6 Meat Stew

### V4 — Temple
- [x] Temple building (data, visual, default spot); revival service (time, speed-up, XP loss 10%); Hospital loses revival
- [x] Save schema 3: add the Temple to older layouts

### V5 — Cleanup staff
- [x] 2 staff actors at the Temple, fee per trip, staff first then Hunters, drag × 0.7

### V6 — UI, docs, tests
- [x] Building sheets: kitchen (Tavern), pharmacy (Hospital), Temple (revivals, staff); top bar food stock; Hunter panel reasons (no food / no money)
- [x] Tests, docs, report

## Acceptance
- [x] Hunters earn by selling materials; the village earns by selling food and medicine
- [x] No food → hungry Hunters keep working; with food they eat and pay
- [x] Dead Hunters are carried by staff to the Temple and revived with an XP loss
- [x] All tests pass; main scene has no errors

## Report (2026-10-11)

- V1: required XP `30 × L^2.2` (Lv1 30 … Lv9 3 771); Training +1 XP/tick, offline ×0.25 with fractional carry-over.
- V2: Slime Gel, Raw Meat, Wild Herb, Bone Dust; new Slime loot table, Goblin / Wolf / Skeleton tables extended. `RegionService.deposit` = the village buys (treasury → purse), the trader buys the rest.
- V3: `ItemDefinition` energy / heal_ratio; `RecipeDefinition` building_id, required_level, result_quantity; `CraftingService.get_recipes(building)`. Tavern: Meat Stew ×3, Herb Soup ×2; Hospital: Bandage ×3, Healing Potion (Lv2). `SupplyService` sells food (best affordable) and medicine; the brain visits the Hospital when resting. New village: 6 Meat Stew. Top bar: Food.
- V4: Temple (250 g, 2 × 2, default (6, 16); Lv1 180 s, Lv2 300 g + 2 Dark Essence → 120 s). `TempleService` replaces the Hospital timers (XP loss 10% of the level's XP, no level loss). Save schema 3 adds a Temple to older layouts (default spot or nearest free).
- V5: 2 `StaffWorker`s at the Temple (70 px/s, × 0.7 dragging), 15 g per trip; staff first, then free Hunters; town rescue kept.
- V6: building sheets (kitchen / pharmacy / forge / Temple), Hunter panel (why it cannot eat, purse text), docs.
- Probe (6×, fresh village, 3 Hunters, chief crafting whenever possible): Hunters sold materials (treasury paid ~3–5 g per item), the chief cooked stews / soups and bandages, Hunters bought bandages after fights, staff carried three bodies to the Temple (15 g each), revivals took XP (e.g. 124 → 111).
- Tests: 159 passed.

## Open points for the owner
- Economy numbers are first-pass: Hunters still earn more (kill gold + sales) than they spend; the treasury slowly pays out for materials and only earns from food and medicine sales.
- Hunters at the level cap keep collecting XP; a revival takes 10% of the level's XP from that pool.
