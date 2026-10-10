# AI SYSTEM

## Hunter AI

Priority:
1. follow expedition objective
2. find nearest valid enemy
3. approach
4. attack
5. continue to next group (loot is auto-collected on kill in MVP)
6. return after boss or when the expedition ends

## Enemy AI

Priority:
1. find nearest Hunter
2. approach
3. attack
4. retarget when target invalid

## Update frequency

Do not perform expensive searches every frame.

Use timers, state changes, or event-driven retargeting. MVP: retarget check every 0.5 s and on target death/downed.

## Town AI

In town, Hunters walk to the location of their activity (`DECISIONS.md` D14) and idle there.

## Trait influence

In MVP, traits and mood only change stats (via the stat pipeline), not AI behaviour.
Behaviour-changing traits (e.g. retreat when Cautious) are post-MVP and must be data-driven modifiers, not hard-coded branches per trait.

## Future

Potential:
- tank positioning
- healer priority
- ranged distance keeping
- threat
- retreat behavior
