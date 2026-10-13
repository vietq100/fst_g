# LOCALIZATION

Rule: **every player-facing text is a translation key** (00_RULES.md §11, DECISIONS.md D61).
Languages: English (`en`, fallback) and Vietnamese (`vi`). The player picks one in Settings
(gear button in the top bar); the choice is saved in `user://settings.cfg`, and the first run
follows the OS language.

## Where the texts live

- One file: `data/i18n/translations.json`, a JSON object sorted by key (edit it directly; keep
  it sorted, UTF-8, 1-space indent):

  ```json
  { "ui.gate.hire": { "en": "Hire  {gold} g", "vi": "Thuê  {gold} g" } }
  ```

- `core/localization.gd` (autoload `Loc`) loads it into Godot's `TranslationServer` at start.
- Every key has both `en` and `vi`. A missing key shows as the key itself and logs a warning.

## How code uses keys

| Case | Write |
|---|---|
| Fixed text | `Loc.t("ui.common.close")` |
| Text with values | `Loc.t("ui.common.needs_gold", {"gold": cost})` with `"Needs {gold} gold"` in the JSON |
| A Control whose whole text is a key | `label.text = "ui.gate.title"` also works (Controls auto-translate), but prefer `Loc.t` |
| Data names and descriptions | `.tres` files store keys (`display_name = "item.iron_sword.name"`); reading `definition.display_name` / `.description` returns the translated text; `get_name_key()` returns the key |
| Errors returned by services ("" = success) | `return Loc.t("err.building.pond")` |

- Placeholders are named `{gold}`, `{name}`, `{level}`… never `%d` / `%s` inside a translated
  string, so each language can put them where its grammar needs. Format numbers before passing
  them: `{"dps": "%.1f" % dps}`.
- Do not build sentences from pieces (`"Hunting" + " in " + region`): make one key with
  placeholders (`"Hunting in {region}"`).
- Plurals: one key per form when the language needs it (`...one`, `...other`); Vietnamese has
  no plural form, so its two values may be equal.
- Never compare, `replace()` or `capitalize()` displayed text in logic. Use ids.

## What is not a key

- Ids, file paths, signal / group names, save fields, `push_error` / `push_warning` / test
  messages (developer-facing, English). Save-repair warnings (`warnings.append` in `from_dict`)
  are logged; the player only sees the translated `toast.save.warnings` notice with their count.
- Proper names generated for Hunters (`name_pool`), numbers, and symbols (tier codes C … MR,
  "Lv", "HP", "ATK", "DEF", "XP", "DPS" stay as they are and may appear inside keys' texts).

## Key names

`<area>.<screen or system>.<name>`, lowercase, dots and underscores only:

- `ui.common.*` shared words (Close, Info, Confirm, gold…); `ui.<sheet>.*` per sheet
  (`ui.gate.*`, `ui.hunter.*`, `ui.building.*`, `ui.hud.*`, `ui.debug.*`…).
- `err.<system>.*` reasons returned by services; `toast.<system>.*` short notices.
- `world.<thing>.*` texts drawn in the world (plaques, labels).
- `stat.<stat_id>`, `slot.<slot_id>`, `tier.<code>.name`.
- Data: `<category>.<id>.name` / `.desc` with category `activity, building, class, enemy,
  expedition, item, loot, quest, recipe, region, skill, status, talent, trait`.

## Vietnamese style

Natural, short Vietnamese for a mobile game; common game words may stay English ("semi
English"): Hunter, Boss, Dungeon, Skill, Buff, Pet, Skin, Lv, HP, ATK, DEF, DPS, XP, Info. Gold is
"vàng". Use the same word for the same thing everywhere (Hunter = Hunter, building names follow
their `building.*.name` keys).
