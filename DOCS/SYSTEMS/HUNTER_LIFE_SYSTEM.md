# HUNTER LIFE SYSTEM

The "nurture" half of the game. Works together with `CHARACTER_SYSTEM.md` and `PROGRESSION_SYSTEM.md`.

All numbers live in `BALANCE.md` and in data definitions, never in code.

## Goals

- Make every Hunter feel like a distinct individual.
- Give the player reasons to care about *which* Hunters go together and *how* they are treated.
- Give Hunters something to do between expeditions, so town feels alive.
- Keep it readable: few stats, clear cause and effect.

## 1. Traits

Each Hunter has 1–2 traits at recruitment.

A trait has:
- id
- display_name
- description
- stat modifiers (percent modifiers in the stat pipeline)
- activity rate modifiers (training/resting speed)
- mood likes / dislikes (event tags)

MVP starter set (numbers in `BALANCE.md` → Traits):

| Trait | Gameplay effect | Likes | Dislikes |
|---|---|---|---|
| Brave | more damage vs bosses | boss fight | idle for 2 expedition cycles |
| Cautious | less damage taken, slightly less damage dealt | success | expedition above own level |
| Greedy | more gold from loot | boss kill | failure |
| Disciplined | faster training | training | party with a Reckless Hunter |
| Reckless | more damage dealt, more damage taken | boss fight | resting 3+ ticks |
| Lazy | slower training, faster resting | resting | 2 consecutive expeditions |

Rules:
- Traits are data (`TraitDefinition`).
- In MVP traits change stats and activity rates only, not AI behaviour.
- Traits never hide gameplay rules in UI.
- Gaining/changing traits through life events is post-MVP.

## 2. Mood (morale)

One value per Hunter, 0–100, starting at 60. Shown as High / Normal / Low.

Raised by: successful expedition, resting, socializing, trait likes, being bonded with a socializing partner.
Lowered by: failure, injury, overwork (third consecutive expedition without rest), trait dislikes.

Effects:
- High: small bonus to attack/defense and XP gain
- Low: penalty to attack/defense and XP gain, warning in UI

Low mood never blocks assignment in MVP and never ends the game. Refusal and separation effects are post-MVP.

## 3. Bonds (relationships)

Bonds exist between pairs of Hunters, value 0–100.

MVP:
- reaching 100 makes the pair `bonded` (single level)
- grows from shared expeditions and socializing together
- bonded pair: attack bonus when in the same party, extra mood when socializing together

Later:
- more levels (friends, rivals, partners/mentor)
- rivalry that boosts or harms performance
- mentor/student skill transfer

Bond data is stored as pairs of Hunter unique_ids plus a value. Never store node references.

## 4. Town life (between expeditions)

Activities (tick = 10 s, effects in `BALANCE.md`):

| Activity | Location | Effect |
|---|---|---|
| Resting | Tavern rooms | recovers HP and mood |
| Socializing | Tavern common room | mood + bond with other socializing Hunters |
| Training | Training Yard | slow XP gain (trait-adjusted) |
| Recovering | Hospital | forced while injured; recovery timer |

- The player can assign Resting, Socializing or Training.
- Default for an idle Hunter: Resting if HP < 100% or mood < 50, otherwise Training.
- Timers run only while the game runs (no offline progress).
- Hunters walk to their activity location in the town scene.

Activity effects are defined in `ActivityDefinition` data.

## 5. Personal history

Each Hunter keeps a small record:
- recruit date (in-game day counter)
- expeditions completed / failed
- bosses defeated
- times injured
- bonded partners

Used for the Hunter panel and future life events. Keep it small and serializable.

## 6. Life events (post-MVP)

Occasional small events driven by history, traits and bonds:
- a Hunter requests a specific weapon
- two Hunters become rivals
- a Hunter gains a new trait after a hard fight

Do not implement a large narrative/dialogue system. Events are short, data-driven, and optional.

## 7. Interaction with power growth

| Life axis | Affects power axis |
|---|---|
| Mood | attack/defense modifier, XP gain |
| Traits | stat modifiers, training speed |
| Bonds | party attack bonus |

| Power axis | Affects life axis |
|---|---|
| Hard expeditions | injury, mood loss, bond gain |
| Victories/bosses | mood gain, history |
| Level/equipment | makes trait strengths matter more |

## 8. Architecture notes

- `HunterRuntime` stores: `trait_ids`, `mood`, `activity`, `history`.
- Bonds are stored in a separate collection owned by `BondService`.
- Services emit signals (`mood_changed`, `bond_changed`, `activity_changed`); UI subscribes.
- Updates happen on events (expedition end, activity tick), not every frame.

## 9. Out of scope for MVP

- romance systems
- dialogue trees
- permadeath
- life events
- more than one bond level
- trait-driven AI behaviour
- mood-based refusal
