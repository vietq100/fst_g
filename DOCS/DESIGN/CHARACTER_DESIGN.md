# CHARACTER DESIGN

## 1. Character philosophy

Hunters are the emotional center of the game.

The player should be able to recognize a Hunter from:
- silhouette
- class
- equipment
- color accents
- portrait

## 2. Character proportions

Initial target:
- small readable pixel character
- head slightly larger than realistic proportion
- readable weapon silhouette
- clear feet/contact point

Avoid excessive tiny details.

## 3. Required character states

Every playable Hunter should support:

- idle
- walk
- attack
- hit
- hurt/injured
- death/fall
- victory

MVP may use simplified animations.

## 4. Direction

MVP: 4-direction movement and sprites. 8-direction is post-MVP.

Order:
- front
- back
- left
- right

## 5. Warrior visual design

Silhouette:
- broad
- medium/heavy armor
- one-handed sword
- shield optional

Personality:
- dependable
- frontline
- practical

Color:
- steel
- brown leather
- muted red accent

## 6. Ranger visual design

Silhouette:
- slim
- hood/cloak
- bow

Color:
- forest green
- brown
- dark gray

## 7. Mage visual design

Silhouette:
- robe
- staff
- distinctive head/shoulder shape

Color:
- dark blue
- purple
- silver accent

## 8. Priest visual design

Silhouette:
- long robe
- staff or holy symbol

Color:
- cream
- gray
- gold accent

## 9. Portrait

Portrait should use the same character identity as the world sprite.

Portrait size can be larger, but:
- same hairstyle
- same equipment theme
- same class identity
- same palette

## 10. Equipment visibility

Where practical, equipment changes should be visually noticeable.

MVP can use equipment icons instead of dynamic sprite composition.

## 11. Personality

Traits are part of the MVP (see `SYSTEMS/HUNTER_LIFE_SYSTEM.md`).

Starter traits:
- brave
- greedy
- lazy
- disciplined
- reckless
- cautious

Traits must have gameplay meaning and should be visible in the Hunter panel.
Hunters also have mood and bonds; the UI should communicate these simply (icons/colour, not walls of text).
Personality may be hinted visually (posture, idle animation variation) where practical.

## 12. Character generation

Random Hunters should vary in:
- face/hair
- small color accents
- name
- traits
- starting stats

Do not make all Hunters visually identical.
