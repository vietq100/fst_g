class_name Tier
extends RefCounted
## One tier scale for Hunters, items, monsters and bosses (DECISIONS.md D60):
## C · U · R · SR · SSR · UR are rolled; LR and Mythic are declared only (set in data, never
## rolled). Values 0–4 match the old item rarities (Common, Uncommon, Rare, Superior, Epic), so
## saved .tres numbers keep their meaning.

enum Level { C, U, R, SR, SSR, UR, LR, MYTHIC }

const CODES: Array[String] = ["C", "U", "R", "SR", "SSR", "UR", "LR", "MR"]
## Name keys (D61): "tier.c.name" … "tier.mr.name".
const NAME_KEYS: Array[String] = ["tier.c.name", "tier.u.name", "tier.r.name", "tier.sr.name", "tier.ssr.name",
	"tier.ur.name", "tier.lr.name", "tier.mr.name"]
const COLORS: Array[Color] = [Color("e6e2d8"), Color("7fd36b"), Color("5fa8ff"), Color("c58bff"), Color("ff9a3d"),
	Color("ff5a5a"), Color("ffd23f"), Color("ff6bd6")]
## Highest tier a roll can give; LR and Mythic are fixed (declared in data only).
const RANDOM_MAX := Level.UR
## HP / attack / defense multiplier of a Hunter or monster of that tier.
const STAT_SCALE: Array[float] = [1.0, 1.05, 1.12, 1.2, 1.3, 1.45, 1.65, 1.9]
## Gold / XP / recruit-cost multiplier.
const REWARD_SCALE: Array[float] = [1.0, 1.2, 1.5, 2.0, 2.8, 4.0, 6.0, 9.0]
## Roll weights C..UR for Hunter candidates and for regular monsters.
const HUNTER_WEIGHTS: Array[float] = [40.0, 28.0, 17.0, 9.0, 4.5, 1.5]
const MONSTER_WEIGHTS: Array[float] = [72.0, 17.0, 7.0, 3.0, 0.8, 0.2]


static func clamp_level(level: int) -> int:
	return clampi(level, Level.C, Level.MYTHIC)


static func code(level: int) -> String:
	return CODES[clamp_level(level)]


static func name_of(level: int) -> String:
	return Loc.t(NAME_KEYS[clamp_level(level)])


static func color(level: int) -> Color:
	return COLORS[clamp_level(level)]


static func stat_scale(level: int) -> float:
	return STAT_SCALE[clamp_level(level)]


static func reward_scale(level: int) -> float:
	return REWARD_SCALE[clamp_level(level)]


## LR and Mythic are never rolled.
static func is_fixed(level: int) -> bool:
	return clamp_level(level) > RANDOM_MAX


## A random tier C..UR from `weights` (one per rollable tier).
static func roll(rng: RandomNumberGenerator, weights: Array[float]) -> int:
	var total := 0.0
	for weight in weights:
		total += weight
	var pick := rng.randf() * total
	for i in weights.size():
		pick -= weights[i]
		if pick < 0.0:
			return mini(i, RANDOM_MAX)
	return Level.C
