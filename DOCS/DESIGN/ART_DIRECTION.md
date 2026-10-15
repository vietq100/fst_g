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
- standard character: approximately 32x48 px (Hunters, D67: 23×44 px body on a 40×64 canvas) (Hunters, D47: 34×50 canvas, body ≈ 23×44; portraits use a 2x version)
- larger bosses may use 64x64 or larger

These values are targets, not absolute constraints.

Display (`DECISIONS.md` D20):
- portrait, base viewport 360×640 (expands on taller/wider screens)
- stretch mode `viewport`, integer scaling, nearest filtering
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
