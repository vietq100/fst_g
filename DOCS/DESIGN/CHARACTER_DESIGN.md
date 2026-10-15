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

Implemented for Hunters: the chibi core (D49, `actors/hunter/chibi/`; redrawn larger in D67). A 23×44 px body on a 40×64 canvas (head 20 rows, torso 17, legs 7), split into head, torso, two arms and two legs that frames move by whole pixels. Face: 3×5 px eyes (lid, shine, iris in the hair colour's base and dark tones), blush, a 1 px mouth, lash flicks for female Hunters; skin and hair use 5-step ramps lit from the top left; hair outlines are the hair's own darkest tone. Views: front, back, side (left = mirrored). Layers (D51): hair (10 styles, 10 colours), class outfit (Warrior, Ranger, Rogue, Guardian; trousers in the Hunter's dye), class weapon (sword, bow, dagger, mace + shield).

```
Hunter
├── Movement: idle (4 fps loop), walk (8 fps), run (12 fps; chasing or hasted)
├── Combat:   attack (14 fps, weapon swing + slash arc), skill (12 fps, crouch → jump → slam,
│             charge glow + burst ring), hit (white flash + flinch), death (buckle → lie down, dust;
│             holds; downed = darker, dead body = cold grey + rising soul)
└── Utility:  pickup (crouch, hand down), loot (crouch → raise the item, sparkles),
              interact (reach and tap twice)
```

One-shot actions play over the state loop by priority: death > attack / skill > hit > pickup / loot / interact.
Triggers: attack on each attack, hit on damage, pickup when lifting a body, loot when a kill drops items, interact at the Warehouse, Hospital and Temple. Skill has no gameplay trigger yet (test arena button).
- victory: not yet

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

Implemented (D47): the portrait is a 40×40 crop around the face of the 2x composed sprite, drawn at an integer scale.

## 10. Equipment visibility

Where practical, equipment changes should be visually noticeable.

MVP can use equipment icons instead of dynamic sprite composition.

Implemented (D47): Hunters are composed from two reference bodies (male, female; 3/4 view facing right). The equipped armor picks one of 30 outfits (5 armor classes × 6: cloth, leather, chain, plate, robe); the Hunter's dye colour recolours the cloth parts. The weapon is still a tinted line. Visual reference: `DESIGN/character_wardrobe_preview.html`.

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

Random Hunters should vary in (D47: body type, 10 hairstyles, 10 hair colours, 4 skin tones, 8 dyes; always random, the player does not pick a look):
- face/hair
- small color accents
- name
- traits
- starting stats

Do not make all Hunters visually identical.
