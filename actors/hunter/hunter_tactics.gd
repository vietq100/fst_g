class_name HunterTactics
extends RefCounted
## Fighting sense of a Hunter (AI_SYSTEM.md → Hunter tactics): which enemy to pick and when to drink
## medicine. The base rules are the same for everyone (finish wounded enemies, back up allies in
## trouble, focus fire, keep away from a boss when hurt); the Hunter's personality (traits'
## behaviour numbers, TraitService.get_behavior) tilts them. Pure functions: easy to test.

## Another Hunter already fighting the enemy makes it more attractive (focus fire), up to this many.
const FOCUS_ALLIES := 2
const FOCUS_BONUS := 0.22
## An enemy attacking an ally under this HP ratio is worth stepping in for.
const ALLY_IN_TROUBLE := 0.5
const PROTECT_BONUS := 0.7
## Weight of a wounded enemy (1 - its HP ratio) in the score.
const WOUNDED_WEIGHT := 0.55
const BOSS_WEIGHT := 0.6
## Below this own HP ratio the Hunter shies away from bosses and elites, more with `boss` < 0.
const HURT := 0.6
## A new target must beat the current one by this much to be switched to.
const SWITCH_MARGIN := 0.45
## Medicine is drunk this far above the retreat ratio (plus the personality's potion bias).
const POTION_MARGIN := 0.12
const POTION_COOLDOWN := 6.0


## Lower is better. `distance` to the enemy and the Hunter's `reach` (the aggro range, px) set the
## base; the rest adjusts it. `info`: enemy_hp (ratio), is_boss, allies_on_it (Hunters targeting it),
## hits_ally_in_trouble (it attacks an ally under ALLY_IN_TROUBLE HP), my_hp (own ratio).
static func score(distance: float, reach: float, info: Dictionary, behavior: Dictionary) -> float:
	var value := distance / maxf(reach, 1.0)
	var wounded := 1.0 - float(info.get("enemy_hp", 1.0))
	value -= wounded * WOUNDED_WEIGHT * (1.0 + float(behavior.get("weak", 0.0)))
	value -= FOCUS_BONUS * mini(int(info.get("allies_on_it", 0)), FOCUS_ALLIES) * (1.0 + float(behavior.get("weak", 0.0)))
	if info.get("hits_ally_in_trouble", false):
		value -= PROTECT_BONUS
	if info.get("is_boss", false):
		var boss: float = behavior.get("boss", 0.0)
		value -= BOSS_WEIGHT * boss
		if float(info.get("my_hp", 1.0)) < HURT:
			value += BOSS_WEIGHT * (1.0 - float(info.get("my_hp", 1.0)) / HURT) * (1.0 + maxf(-boss, 0.0))
	return value


## HP ratio under which the Hunter drinks medicine from its bag during a fight.
static func potion_ratio(retreat_ratio: float, behavior: Dictionary) -> float:
	return clampf(retreat_ratio + POTION_MARGIN + float(behavior.get("potion", 0.0)), 0.0, 0.95)
