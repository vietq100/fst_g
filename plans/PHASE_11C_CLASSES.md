# PHASE 11c — Classes and talents (owner request, D45–D46)

## Read first
`DOCS/DECISIONS.md` D45–D46, `DOCS/BALANCE.md` → Classes / Talents.

## Tasks
- [x] Class data: Ranger, Rogue, Guardian (+ Short Bow, Rusty Dagger); class look (body, weapon) on the placeholder
- [x] Ranged attack streak VFX
- [x] `TalentDefinition` + data (Cook, Herbalist); `HunterRuntime.talent_id` (saved); rolled for every candidate
- [x] `RecipeDefinition.field_seconds`; `TalentService`: field recipes, craft from the bag, eat / use from the bag
- [x] Brain: eat from bag, cook / brew in the field (5–10 s, cancelled when hit), before walking home
- [x] UI: class and talent on the Hunter panel, Hunters list and Tavern candidates
- [x] Tests, docs, report

## Acceptance
- [x] Tavern offers all four classes; each fights with its own range and look
- [x] A Cook eats from its own cooking in the field; a Herbalist heals itself with bandages it makes
- [x] All tests pass; main scene has no errors

## Report (2026-10-11)

- Classes: Ranger (range 110, arrow streak), Rogue (crit 20% ×1.8, fast), Guardian (160 HP, 9 DEF, slow) next to the Warrior; Short Bow and Rusty Dagger as starting weapons; class look (body size, weapon length / width) on the placeholder. Tavern candidates are any class (cost per class).
- Talents: `TalentDefinition` (Cook, Herbalist), `HunterRuntime.talent_id` (saved), rolled for every candidate (35 / 35 / 30% none). `TalentService`: field recipes from the bag (village recipes, `RecipeDefinition.field_seconds` 5–10 s, no building), eat / use from the bag. `NeedsService.eat` uses bag food first.
- Brain: self-care before going home — eat from bag, else a Cook cooks (task "cooking"); HP below 35%: medicine from bag, else a Herbalist brews (task "brewing"). The Hunter stands still with a progress bubble; being hit cancels it (nothing used up). Party runs cancel crafting.
- UI: class and talent in the Hunters list, Hunter panel and Tavern candidates.
- Probe: a hungry Cook in the field cooked Meat Stew from 2 Raw Meat and ate (energy 30 → 89); a hurt Herbalist brewed 3 Bandages from Slime Gel and healed itself twice without going home.
- Tests: 166 passed (new `test_classes_talents.gd`, 7 tests).
