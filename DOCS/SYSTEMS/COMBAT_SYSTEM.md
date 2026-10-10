# COMBAT SYSTEM

## Combat model

Auto combat.

Flow:
target
→ move
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

Centralize formulas. Values: `BALANCE.md`.

## Targeting

- nearest valid target
- retarget check on a 0.5 s timer and immediately when the target dies/is downed

## Combat ownership

Combat system owns:
- target validity
- damage
- attack timing
- death resolution (enemies die, Hunters are downed)

UI only displays results.

## MVP

- melee attack
- HP
- enemy death / Hunter downed
- basic target selection
- simple feedback
