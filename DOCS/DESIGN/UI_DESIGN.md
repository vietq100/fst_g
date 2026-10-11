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
