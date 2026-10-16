# UI DESIGN

## Visual identity

UI should feel like:
- fantasy management interface
- clean
- readable
- slightly dark
- warm accents

## Mobile layout (`DECISIONS.md` D20, D23)

- Portrait, one-handed: primary actions in the bottom third of the screen.
- Panels open as bottom sheets or full-screen pages, not floating desktop windows.
- Touch targets at least 40×40 game px; no hover-only information (use tap / long-press for details).
- Fonts: min 10 game px, body 12.
- Respect safe area (notch, home indicator).
- Anchor-based layout; never assume exactly 360×640.

## Main HUD

Top:
- Treasury (village funds, D34, D38)
- Food portions in stock (D40)
- Beds used / total (D32)
- Warehouse usage (slots used / capacity)
- Town level

Bottom:
- navigation bar: Town (recenter the camera on the Town), Build, Hunters, Dungeon, Items
- placement bar while placing a building (title, reason it cannot be placed, Confirm / Cancel)
- expedition HUD while a party is in a dungeon

World (D28): drag to pan, pinch / wheel to zoom, tap a Hunter to select and follow it, tap a building for its panel, tap a dungeon entrance for its panel.

## Offline summary

On resume after time away: short "while you were away" sheet (recovered Hunters, XP from training, meals eaten, hunger warning).

## Panels

### Hunter panel
Show:
- portrait
- name
- class
- level
- HP
- XP
- equipment
- barber: hair style and colour pickers on a preview figure, "New look" for gold (D77)
- traits
- mood (icon/colour state)
- current activity / task (resting / training / socializing / sleeping / eating / hunting / returning / fetching / carrying / fallen)
- stamina and energy bars (D31)
- purse with Give 50 / Take all (10% fee shown, D34)
- duty: Auto / Dark Forest / Goblin Cave / Ancient Ruins / Stay (D29) and the loot bag
- Follow on the map (D28)
- bonds (who they are close to)
- short history (expeditions, bosses, injuries)

### Building panel
Show:
- building name
- level
- function
- upgrade cost
- requirements
- Move / Remove (refund shown, tap twice to remove; D33)
- House: residents and beds
- Tavern: kitchen (food recipes, stock) and candidates; Hospital: pharmacy (medicine recipes); Blacksmith: forge; Temple: revivals (time, XP loss, speed-up) and staff status
- Upgrade preview lists the recipes the next level unlocks

### Build panel
- every building that can be bought: cost, description, why it cannot be built now
- Place → placement mode on the map (ghost at the nearest free spot, tap to move, Confirm / Cancel)

### Dungeon panel (expedition panel, D35)
Opened from a dungeon entrance or the Dungeon button. Locked dungeons only say they are sealed.
Show:
- destination and where its entrance is
- recommended level
- enemy preview
- rewards
- selected Hunters (show mood, traits and bonds that affect the party)
- start button

## Buttons

Buttons must clearly communicate:
- available
- unavailable
- selected
- dangerous

Avoid tiny text.

## Feedback

Use:
- floating damage numbers
- loot popup
- level-up effect
- notification
- progress bars

Do not overwhelm the screen.

## Implementation (Phase 10)

- `UIRoot` (in Main's UI layer): top resource bar, bottom navigation (Town / Hunters / Expedition / Inventory), one bottom sheet at a time (≤ 62% of the screen, scrollable), toasts (max 3, 2.6 s), expedition HUD. Safe-area margins applied on mobile.
- Sheets (`ui/sheets/`): `BuildingSheet` (all five buildings: upgrade card + Tavern candidates / Hospital timers / Blacksmith recipes / Warehouse slots / Town Hall capacity), `HuntersSheet`, `HunterSheet` (stats, HP/XP bars, equip/remove, traits with descriptions, mood bar, activity buttons, bonds, history), `ExpeditionSheet` (destination, enemies, rewards, party toggles with mood/trait/level/bond notes, depart), `InventorySheet` (slots, sell), `MessageSheet` (expedition result, "while you were away").
- Tapping a building, the South Gate or a Hunter in town opens its sheet; taps on UI never reach the world (`Town.input_blocker`).
- Expedition HUD: destination + area progress, found gold/items/kills, party cards with HP bars and downed marker.
- Theme (`GameTheme`): dark warm panels, gold accents. Button variations: Primary (main action), Danger (selling), Selected (chosen state), disabled (greyed, reason shown as a red label). Progress bars: HP green, XP blue, mood/bond yellow, timers gold.
- Placeholder portraits (`HunterPortrait`) use the same accent and armor colours as the world sprite.
- The developer debug panel stays (collapsed "Dev +" button, top right; removed in release builds).

## Evil Hunter Tycoon HUD (2026-10-12, from the owner's reference screenshots)

- Header over the map: difficulty badge (skull + name, opens the Portal), big outlined numbers for gold, food, Warehouse slots and ready quests; Hunters count / capacity at the right with Quests (book), Portal (trophy) and Recruit (mail) shortcuts.
- Quest bubble under the header: the active quest, progress bar; tap opens the Quests sheet.
- Bottom bar: Construct, Dungeon, Hunters, Storage, Shop (Shop = every service building and Quests).
- Floating: "Hunters Waiting" (Tavern candidates) bottom-left; round Town / I / II / III buttons bottom-right jump the camera to the Town and the hunting regions; a 3-line event feed top-left (bag sales).
- Map: dark moody palette, cobbled roads, stone retaining wall around the Town over a teal moat.

## Drawer and Hunter tab (2026-10-12)

- Drawers (sheets) are 45% of the screen height with a round ✕ button; the nav tab of the open drawer is highlighted (light tab).
- Hunter tab: 4-column grid of cards — star (talent), name, grade (N / R / S / L by reincarnations), Lv + class, portrait, current place or activity, Info and Locate. Header buttons: "Hunting grounds" (cycles everyone's duty) and "Sort" (level / name / class).

## Hunter dialog (2026-10-12)

Tapping Info on a Hunter card opens `HunterDialog` (full-screen dialog, HUD hidden): name, reincarnation stars and purse, paper doll (weapon / accessory left, armor right, enhancement "+N" on worn items), rebirth points, tabs Info (grade, Lv + class, DPS, HP / satiety / mood / stamina / XP bars, ATK / DEF / CRIT / ATK SPD / MOVE), Skill&Trait, Gear (equip / remove) and Life (needs, purse transfers, duty, activity, bonds, history), and a red Close button.

## Palette and map (2026-10-13, D52)

- Theme colours follow the reference game: deep navy panels (`GameTheme.PANEL`), gold rims, green Primary (confirm) and red Danger (cancel / close) buttons, white numbers with a dark outline over the map, resource pills in the header, 36 px nav icons with a gold bar over the selected tab, round gold-rimmed Town / I / II / III buttons.
- The map is 2:1 isometric (diamond tiles, bridges over water, buildings as isometric boxes with roof emblems, D55) so the HUD reads like the reference screenshots.

## Monster info (2026-10-15)

Tapping a monster in a hunting region opens `MonsterDialog`: name in its tier colour, level and tier, live HP bar, ATK / DEF / attack speed / move speed / crit, rewards (same scaling as `RegionService.record_kill`), difficulty multipliers, region, drop list with chances and on-hit effects. All texts are `ui.monster.*` keys (EN / VI).

## Map scroll limits (2026-10-15)

The camera may scroll past the map's top and bottom by the height of the HUD header and of the navigation bar (`WorldCamera.inset_top / inset_bottom`, set from `UIRoot.view_insets_changed`), so the top and bottom of the map can always be brought clear of them, also when zoomed in. The insets are 0 while a dialog hides the HUD.
