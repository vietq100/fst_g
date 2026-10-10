class_name RarityColors
extends RefCounted
## Consistent rarity colour language for items (ITEM_DESIGN.md → Rarity).

const COMMON := Color("e6e2d8")
const UNCOMMON := Color("7fd36b")
const RARE := Color("5fa8ff")
const GOLD := Color("ffd23f")


static func of(rarity: ItemDefinition.Rarity) -> Color:
	match rarity:
		ItemDefinition.Rarity.UNCOMMON:
			return UNCOMMON
		ItemDefinition.Rarity.RARE:
			return RARE
	return COMMON
