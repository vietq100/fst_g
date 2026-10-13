class_name WeaponSprites
extends RefCounted
## Pixel weapon sprites held by Hunters and monsters: text bitmaps drawn blade-up with a "grip"
## pixel that sits in the hand (ChibiVisual / MonsterVisual rotate them to the animation's weapon
## angle). Kinds: sword, greatsword, dagger, curved, shadow, fang, bow, mace, club, bone.
## T t L = the item's tint (base, shadow, shine); the rest are fixed colours.

const PALETTE := {
	"o": Color("16161c"), "g": Color("5a3a26"), "G": Color("3a2416"), "y": Color("d9b356"), "Y": Color("9a7a2e"),
	"w": Color("eee8d8"), "W": Color("b8b0a0"), "s": Color("8a8f98"), "r": Color("8a5a30"), "R": Color("5a3a1c"),
	"v": Color("2a1f3d"), "V": Color("5a3f8c"), "p": Color("c79bff"), "f": Color("f4f1ea"), "F": Color("c9c0b0"),
	"n": Color("3a2a1a"),
}

const BITMAPS := {
	&"sword": {"grip": Vector2i(3, 14), "rows": [
		"...oo..",
		"..oLTo.",
		"..oLTo.",
		"..oLTo.",
		"..oLTo.",
		"..oLTo.",
		"..oLTo.",
		"..oLTo.",
		"..oLTo.",
		"..oLTo.",
		"..oLTo.",
		".oLTTo.",
		"oyyyyyo",
		"..ogo..",
		"..ogo..",
		"..ogo..",
		"..oyo..",
		"...o...",
	]},
	&"greatsword": {"grip": Vector2i(4, 15), "rows": [
		"...oo...",
		".oLTTto.",
		".oLTTto.",
		".oLTTto.",
		".oLTTto.",
		".oLTTto.",
		".oLTTto.",
		".oLTTto.",
		".oLTTto.",
		".oLTTto.",
		".oLTTto.",
		".oLTTto.",
		".oLTTto.",
		"oyyyyyyo",
		"...ogo..",
		"...ogo..",
		"...ogo..",
		"...oyo..",
		"....o...",
	]},
	&"dagger": {"grip": Vector2i(2, 7), "rows": [
		"..oo.",
		".oLTo",
		".oLTo",
		".oLTo",
		".oLTo",
		".oLTo",
		"oyyyo",
		".ogo.",
		".ogo.",
		".oyo.",
		"..o..",
	]},
	&"curved": {"grip": Vector2i(3, 13), "rows": [
		"....oo..",
		"...oLTo.",
		"..oLTo..",
		"..oLTo..",
		".oLTo...",
		".oLTo...",
		".oLTo...",
		".oLTo...",
		".oLTto..",
		".oLTto..",
		"..oTto..",
		"..oyyo..",
		"..ogo...",
		"..ogo...",
		"..ogo...",
		"..oyo...",
		"...o....",
	]},
	&"shadow": {"grip": Vector2i(3, 13), "rows": [
		"....oo..",
		"...opVo.",
		"..opVvo.",
		"..opVvo.",
		".opVvo..",
		".opVvo..",
		".opVvo..",
		".opVvo..",
		".opVvo..",
		".opVvvo.",
		"..oVvvo.",
		"..oyyo..",
		"..ovo...",
		"..ovo...",
		"..ovo...",
		"..oyo...",
		"...o....",
	]},
	&"fang": {"grip": Vector2i(3, 11), "rows": [
		"..oo...",
		"..ofo..",
		".ofFo..",
		".ofFo..",
		".ofFFo.",
		".ofFFo.",
		"..ofFo.",
		"..ofFo.",
		"..ofFo.",
		"..ofFFo",
		"..orro.",
		"..oRro.",
		"..oRro.",
		"..orro.",
		"...oo..",
	]},
	&"bow": {"grip": Vector2i(3, 9), "rows": [
		".......o.",
		".....ooro",
		"....orRo.",
		"...orRo..",
		"...oro...",
		"..oro....",
		"..oro....",
		"..orRo...",
		"..oGGo...",
		"..oGGo...",
		"..orRo...",
		"..oro....",
		"..oro....",
		"...oro...",
		"...orRo..",
		"....orRo.",
		".....ooro",
		".......o.",
	]},
	&"mace": {"grip": Vector2i(4, 11), "rows": [
		"..ooooo..",
		".osTTTso.",
		"osTLTTTso",
		"osTTTTTso",
		"osTTTTTso",
		".osTTTso.",
		"..ooooo..",
		"...ogo...",
		"...ogo...",
		"...ogo...",
		"...ogo...",
		"...ogo...",
		"...ogo...",
		"...oyo...",
		"....o....",
	]},
	&"club": {"grip": Vector2i(3, 10), "rows": [
		"..oooo.",
		"..orRRo",
		".orrRRo",
		".orrRRo",
		".orrRRo",
		"..orRo.",
		"..orRo.",
		"..orRo.",
		"..oro..",
		"..oro..",
		"..oro..",
		"..oro..",
		"..oro..",
		"...o...",
	]},
	&"bone": {"grip": Vector2i(3, 12), "rows": [
		"...oo..",
		"..owWo.",
		"..owWo.",
		"..owWo.",
		"..owWo.",
		"..owWo.",
		"..owWo.",
		"..owWo.",
		"..owWo.",
		".owwWo.",
		"owwwwWo",
		"..osWo.",
		"..oso..",
		"..oso..",
		"..oso..",
		"...o...",
	]},
}

static var _cache: Dictionary = {}


static func has_kind(kind: StringName) -> bool:
	return BITMAPS.has(kind)


## Sprite kind for an equipped weapon item, by words in its id; `fallback` for unknown ones.
static func kind_for_item(item: ItemDefinition, fallback: StringName) -> StringName:
	if item == null:
		return fallback
	var id := String(item.id)
	for pair: Array in [["shadow", &"shadow"], ["fang", &"fang"], ["dagger", &"dagger"], ["bow", &"bow"],
			["mace", &"mace"], ["hammer", &"mace"], ["club", &"club"], ["great", &"greatsword"], ["bone", &"bone"],
			["scimitar", &"curved"], ["sword", &"sword"], ["blade", &"sword"]]:
		if id.contains(pair[0]):
			return StringName(pair[1])
	return fallback


## Pixel the hand holds (from the bitmap's top-left).
static func grip_of(kind: StringName) -> Vector2i:
	return BITMAPS[kind]["grip"] if BITMAPS.has(kind) else Vector2i.ZERO


## Reach from the grip to the tip, in px.
static func length_of(kind: StringName) -> float:
	return float(grip_of(kind).y) + 1.0


static func texture(kind: StringName, tint: Color) -> Texture2D:
	var key := "%s|%s" % [kind, tint.to_html(false)]
	if _cache.has(key):
		return _cache[key]
	var entry: Dictionary = BITMAPS.get(kind, BITMAPS[&"sword"])
	var rows: Array = entry["rows"]
	var palette := PALETTE.duplicate()
	palette["T"] = tint
	palette["t"] = tint.darkened(0.4)
	palette["L"] = tint.lightened(0.45)
	var width := String(rows[0]).length()
	var image := Image.create(width, rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		var row: String = rows[y]
		for x in width:
			var code := row[x]
			if code != "." and palette.has(code):
				image.set_pixel(x, y, palette[code])
	var result := ImageTexture.create_from_image(image)
	_cache[key] = result
	return result


static func clear_cache() -> void:
	_cache.clear()
