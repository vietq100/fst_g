class_name RarityColors
extends RefCounted
## Colour of a tier (D60) for items, Hunters and monsters; see Tier.COLORS.

const COMMON := Color("e6e2d8")
const GOLD := Color("ffd23f")


static func of(rarity: int) -> Color:
	return Tier.color(rarity)
