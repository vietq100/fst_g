# ART DIRECTION

## 1. Visual identity

Target:
- 2D pixel-art-inspired fantasy
- dark fantasy atmosphere
- readable silhouettes
- slightly charming rather than horror
- strong contrast between safe town and dangerous wilderness

The game should feel:
- cozy in town
- dangerous outside
- rewarding during loot
- mysterious during exploration

## 2. Camera

Preferred:
- top-down / 3/4 hybrid
- orthographic 2D
- no perspective distortion

Camera should be readable and stable.

## 3. Pixel grid

Initial target:
- environment tile: 32x32 px
- standard character: 32x48 world px (Hunters: 64×96 texel canvas at 2 texels per px, D56)
- larger bosses may use 64x64 or larger

These values are targets, not absolute constraints.

Display (`DECISIONS.md` D20):
- portrait, base viewport 360×640 (expands on taller/wider screens)
- stretch mode `canvas_items` (D56; was `viewport`), integer scaling, nearest filtering
- characters, monsters and weapons are drawn at 2 texels per world pixel (D56): same world size, twice the detail
- 4-direction sprites
- about 11 tiles across the screen width: keep silhouettes readable on a phone

## 4. Palette

Use a restrained palette.

Town:
- warm wood
- stone
- muted greens
- warm light

Wilderness:
- dark greens
- blue-gray
- brown
- muted purple

Dungeon:
- dark stone
- desaturated colors
- magical accent colors

## 5. Silhouette

Every Hunter and enemy must remain identifiable at small size.

Do not rely only on facial detail.

Class silhouettes:
- Warrior: broad shoulders, sword/shield
- Ranger: slim, bow
- Mage: staff/robe
- Priest: robe, holy symbol

## 6. Lighting

Town:
- warm
- safe
- lanterns

Dungeon:
- cool/dark
- localized light sources

Lighting should support gameplay readability, not obscure characters.

## 7. Consistency

All generated assets must share:
- camera angle
- pixel density
- outline treatment
- lighting direction
- palette logic

Avoid mixing realistic art with pixel art.
