class_name ItemIcons
extends RefCounted
## 12×12 pixel-art item icons drawn from text bitmaps (like PixelIcons), picked by the item's type
## and id and tinted with its `tint` (T = tint, t = tint shadow). Cached per kind, tint and scale.

const SIZE := 12

const PALETTE := {
	"k": Color("2a1c10"), "L": Color("ffffff"), "b": Color("8b5e3c"), "B": Color("5a3b22"), "y": Color("f2c94c"),
	"w": Color("f4f1ea"), "g": Color("6fbf5f"), "G": Color("3f8a3a"), "r": Color("c9503f"), "p": Color("e8b98a"),
	"s": Color("9aa0a6"), "S": Color("5d5a55"), "l": Color("5fa8ff"), "o": Color("e0874a"), "v": Color("a78bfa"),
	"V": Color("6b3b8c"),
}
## Default tint for kinds whose item has none (white = untinted).
const KIND_TINT := {
	&"sword": Color("c8d0d8"), &"dagger": Color("c8d0d8"), &"bow": Color("8b5e3c"), &"mace": Color("b8bcc4"),
	&"armor": Color("b8bcc4"), &"potion": Color("ff6b7a"),
}

const BITMAPS := {
	&"sword": [
		".........kk.", "........kTLk", ".......kTLk.", "......kTLk..", ".....kTLk...", "kk..kTLk....",
		".kkkkLk.....", "..kyyk......", ".kykkyk.....", "kbk..kk.....", "kBk.........", ".k..........",
	],
	&"dagger": [
		"............", "........kk..", ".......kTLk.", "......kTLk..", ".....kTLk...", "....kTLk....",
		"..kkkLk.....", "..kyyk......", ".kbkkk......", ".kBk........", "..k.........", "............",
	],
	&"bow": [
		".....kk.....", "...kkTTk....", "..kTTkkTk...", ".kTk..kTk...", ".kTk...kk...", "kTk.....k...",
		"kTk.....k...", ".kTk...kk...", ".kTk..kTk...", "..kTTkkTk...", "...kkTTk....", ".....kk.....",
	],
	&"mace": [
		"........kkk.", ".......kTTTk", "......kTLTTk", ".......kTTTk", "......kTkkk.", ".....kbk....",
		"....kbk.....", "...kbk......", "..kbk.......", ".kbk........", "kBk.........", ".k..........",
	],
	&"armor": [
		"..kkk..kkk..", ".kTTTkkTTTk.", "kTLTTkkTTTtk", "kTTkkTTkkTtk", "kTkTTTTTTktk", ".kTTTTTTTtk.",
		".kTTtTTtTtk.", ".kTTTTTTTtk.", ".kTtTTTTtTk.", ".kTTTTTTTtk.", "..kTTTTTTk..", "...kkkkkk...",
	],
	&"ring": [
		"....kkkk....", "...kyyyyk...", "..kyk..kyk..", "..ky....yk..", ".kyk.kk.kyk.", ".ky.kTLk.yk.",
		".ky.kTTk.yk.", ".kyk.kk.kyk.", "..ky....yk..", "..kyk..kyk..", "...kyyyyk...", "....kkkk....",
	],
	&"ore": [
		"............", "....kkk.....", "...kssSk....", "..ksLsSSk...", ".kssssSSSk..", ".kssLssSSk..",
		"kssssssSSSk.", "kssssssSSSk.", "kSsssssSSSk.", ".kSSSSSSSk..", "..kkkkkkk...", "............",
	],
	&"herb": [
		"......kk....", ".....kgGk...", "....kgggk...", "...kggGk....", "..kgGgk.....", ".kggGk.kk...",
		".kgGk.kgGk..", "..kkk.kggk..", "...kk.kGk...", "....kbkk....", "....kBk.....", "....kk......",
	],
	&"meat": [
		"............", "..kkkk......", ".kooook.....", "kooLooook...", "koooooook...", "koooooooook.",
		".koooooooBk.", "..koooook.k.", "...kkkk..k..", ".....kk..k..", "......kwwk..", "......kk....",
	],
	&"fang": [
		"............", "....kk......", "...kwwk.....", "...kwwk.....", "...kwwwk....", "....kwwk....",
		"....kwwk....", "....kwwwk...", ".....kwwk...", ".....kwwk...", "......kwk...", ".......k....",
	],
	&"gel": [
		"............", "............", "...kkkkk....", "..kgggggk...", ".kgLgggggk..", "kgggggggggk.",
		"kgggggggggk.", "kGgggggggGk.", "kGGgggggGGk.", ".kGGGGGGGk..", "..kkkkkkk...", "............",
	],
	&"dust": [
		"............", "............", "............", "......k.....", "....k.kk.k..", "...kk.kkk...",
		".kkkkkkkkk..", "kssssssSSSk.", "kssSsssSSSk.", "kSSSSSSSSSk.", ".kkkkkkkkk..", "............",
	],
	&"essence": [
		"....kkkk....", "..kkvvvvkk..", ".kvvVvvvvvk.", ".kvLvvvvVvk.", "kvvvvvvvVVk.", "kvvvvvvvVVk.",
		"kvvvvvvVVVk.", "kVvvvvVVVVk.", ".kVVVVVVVk..", ".kkVVVVVkk..", "...kkkkk....", "............",
	],
	&"potion": [
		"....kkkk....", "....kbbk....", "....kkkk....", "...kwTTwk...", "..kwTTTTwk..", ".kTTTTTTTTk.",
		"kTTTLTTTTTtk", "kTTTTTTTTTtk", "kTTTTTTTTttk", ".kTTTTTTttk.", "..kkTTTTkk..", "....kkkk....",
	],
	&"bandage": [
		"............", ".kkkkkkkkk..", "kwwwwwwwwwk.", "kwkwkwkwkwk.", "kwwwwwwwwwk.", "kwkwkwkwkwk.",
		"kwwwwwwwwwk.", "kwkwkwkwkwk.", "kwwwwwwwwwk.", ".kkkkkkkkk..", "..kwk.......", "..kk........",
	],
	&"bowl": [
		"............", "...kk.......", "..kook.k....", "..koook.k...", "kkkkkkkkkkk.", "kwwwwwwwwwk.",
		".kwwwwwwwk..", ".kBBBBBBBk..", "..kBBBBBk...", "...kkkkk....", "............", "............",
	],
}


static var _cache: Dictionary = {}


## Icon kind for an item: by equipment type, then by words in its id, then by consumable effect.
static func kind_of(item: ItemDefinition) -> StringName:
	if item == null:
		return &"ore"
	var id := String(item.id)
	match item.item_type:
		ItemDefinition.ItemType.WEAPON:
			if id.contains("bow"):
				return &"bow"
			if id.contains("dagger"):
				return &"dagger"
			if id.contains("mace") or id.contains("hammer") or id.contains("club"):
				return &"mace"
			return &"sword"
		ItemDefinition.ItemType.ARMOR:
			return &"armor"
		ItemDefinition.ItemType.ACCESSORY:
			return &"ring"
		ItemDefinition.ItemType.CONSUMABLE:
			if id.contains("bandage"):
				return &"bandage"
			if item.heal_ratio > 0.0:
				return &"potion"
			return &"bowl"
	for pair: Array in [["herb", &"herb"], ["meat", &"meat"], ["fang", &"fang"], ["gel", &"gel"], ["dust", &"dust"],
			["essence", &"essence"], ["ore", &"ore"]]:
		if id.contains(pair[0]):
			return StringName(pair[1])
	return &"ore"


## Tint used for an item (its own, or the kind's default).
static func tint_of(item: ItemDefinition) -> Color:
	if item != null and item.tint != Color.WHITE:
		return item.tint
	return KIND_TINT.get(kind_of(item), Color.WHITE)


static func texture(item: ItemDefinition, scale: int = 2) -> Texture2D:
	return texture_of(kind_of(item), tint_of(item), scale)


static func texture_of(kind: StringName, tint: Color, scale: int = 2) -> Texture2D:
	var key := "%s|%s|%d" % [kind, tint.to_html(false), scale]
	if _cache.has(key):
		return _cache[key]
	var rows: Array = BITMAPS.get(kind, BITMAPS[&"ore"])
	var palette := PALETTE.duplicate()
	palette["T"] = tint
	palette["t"] = tint.darkened(0.35)
	var image := Image.create(SIZE * scale, SIZE * scale, false, Image.FORMAT_RGBA8)
	for y in SIZE:
		var row: String = rows[y] if y < rows.size() else ""
		for x in SIZE:
			var code := row[x] if x < row.length() else "."
			if code == "." or not palette.has(code):
				continue
			var color: Color = palette[code]
			for dy in scale:
				for dx in scale:
					image.set_pixel(x * scale + dx, y * scale + dy, color)
	var result := ImageTexture.create_from_image(image)
	_cache[key] = result
	return result


static func clear_cache() -> void:
	_cache.clear()
