# COMBAT SYSTEM

## Combat model

Auto combat.

Flow:
target
→ move to an engagement slot
→ enter range
→ attack cooldown
→ damage
→ target reacts
→ death (enemy) / downed (Hunter)
→ next target

## Damage

Physical formula:

damage = max(1, attack - defense * 0.5)

Critical:
if randf() < critical_chance:
    damage *= critical_damage

Attack timing:
attack_cooldown = 1 / attack_speed (seconds)

Attack, defense and other stats come from the stat pipeline (base + level + equipment + traits + mood + bond), see `DECISIONS.md` D18.

Trait damage modifiers (e.g. Brave vs boss, Reckless, Cautious) are applied as percent modifiers in the same pipeline.

Centralize formulas (`StatService`). Values: `BALANCE.md`.

## Targeting

- nearest valid target
- keep the current target until it becomes invalid
- retarget check on a 0.5 s timer and immediately when the target dies/is downed

## Engagement slots (spacing)

Every actor offers 6 fixed slots around itself (ring = 0.75 × attacker's attack range).
- An attacker claims the free slot nearest to it and walks there, so attackers never stack.
- Slots inside obstacles or outside attack range are skipped.
- When all slots are taken, the attacker waits on an outer ring and retries.
- Standing teammates closer than 12 px drift apart (actors do not body-block each other).

## Combat ownership

- `CombatService` resolves attacks: damage, critical, death/downed; emits `damage_dealt`, `actor_defeated`.
- Each actor's `CombatController` owns its target, slots and attack timing.
- UI/VFX only subscribe to signals (`CombatFeedback` spawns damage numbers).

## Feedback (MVP)

- hit flash on damage
- short attack lunge towards the target
- floating damage numbers (white, red when a Hunter is hurt, yellow + "!" on critical)
- enemy death fade (0.5 s), Hunter downed pose

## Status effects (D48)

Timed buffs/debuffs on any actor, defined in `data/status_effects/`:

| Effect | Kind | What it does (per stack) |
|---|---|---|
| Poison | debuff | 2 dmg/s, stacks ×5 |
| Burn | debuff | 4 dmg / 0.5 s, −10% defense |
| Bleed | debuff | 1% max HP/s, stacks ×3 |
| Regen | buff | heals 3% max HP/s |
| Stunned | debuff | no move, no attack; cannot be chained |
| Frozen | debuff | stunned, +15% damage taken |
| Rooted | debuff | no move, can still attack in range |
| Disarmed | debuff | no attack, can still move |
| Slowed | debuff | −40% move speed, −20% attack speed |
| Haste | buff | +40% move speed, +30% attack speed |
| Weakened | debuff | −30% attack |
| Strength | buff | +15% attack, stacks ×3 |
| Armor Break | debuff | −50% defense, +15% damage taken |
| Fortify | buff | +50% defense, −15% damage taken |
| Focus | buff | +25% crit chance, +0.5 crit damage |
| Vulnerable | debuff | +10% damage taken, stacks ×3 |
| Shield | buff | absorbs 30 damage, ends when broken |
| Invulnerable | buff | takes no damage, cannot be cleansed |
| Thorns | buff | reflects 30% of hit damage |
| Lifesteal | buff | heals 25% of hit damage dealt |

- `StatusEffectController` owns durations, stacks, ticks and flags; `CombatService` applies invulnerability, shields, thorns, lifesteal, on-hit effects and damage over time.
- Cleanse removes dispellable debuffs, purge dispellable buffs.
- Test arena: one debug button per effect (selected Hunter, or every enemy when none is selected).

## MVP

- melee attack
- HP
- enemy death / Hunter downed
- basic target selection
- simple feedback
