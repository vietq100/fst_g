class_name WeaponSprites
extends RefCounted
## Pixel weapon sprites held by Hunters and monsters: text bitmaps drawn blade-up with a "grip"
## pixel that sits in the hand (ChibiVisual / MonsterVisual rotate them to the animation's weapon
## angle). Kinds: sword, greatsword, dagger, curved, shadow, fang, bow, mace, club, bone.
## T t L = the item's tint (base, shadow, shine); the rest are fixed colours. Bitmaps are drawn at
## SCALE texels per world pixel (D56): draw them with a 1 / SCALE transform.

const SCALE := 2

const PALETTE := {
	"o": Color("16161c"), "g": Color("5a3a26"), "G": Color("3a2416"), "y": Color("d9b356"), "Y": Color("9a7a2e"),
	"w": Color("eee8d8"), "W": Color("b8b0a0"), "s": Color("8a8f98"), "r": Color("8a5a30"), "R": Color("5a3a1c"),
	"v": Color("2a1f3d"), "V": Color("5a3f8c"), "p": Color("c79bff"), "f": Color("f4f1ea"), "F": Color("c9c0b0"),
	"n": Color("3a2a1a"),
}

const BITMAPS := {
	&"sword": {"grip": Vector2i(6, 28), "rows": [
		".......oo.....",
		".....oooooo...",
		".....oLLTTo...",
		"....ooLLTToo..",
		"....oLLLTTTo..",
		"....oLLLTTTo..",
		"....oLLLTTTo..",
		"....oLLLTTTo..",
		"....oLLLTTTo..",
		"....oLLLTTTo..",
		"....oLLLTTTo..",
		"....oLLLTTTo..",
		"....oLLLTTTo..",
		"....oLLLTTTo..",
		"....oLLLTTTo..",
		"....oLLLTTTo..",
		"....oLLLTTTo..",
		"....oLLLTTTo..",
		"....oLLLTTTo..",
		"....oLLLTTTo..",
		"....oLLLTTTo..",
		"...ooLLTTTTo..",
		"...oLLLTTTTo..",
		".oooLLTTTTooo.",
		"ooyyyyyyyyyooo",
		"ooyyyyyyyyyyoo",
		"....oggggo....",
		"....oggggo....",
		"....oggggo....",
		"....oggggo....",
		"....oggggo....",
		"....oggggo....",
		"....ooyyoo....",
		".....oyyo.....",
		".....oooo.....",
		"......oo......",
	]},
	&"greatsword": {"grip": Vector2i(8, 30), "rows": [
		".......oo.......",
		"......oooo......",
		"...oLLTTTTtto...",
		"..ooLLTTTTttoo..",
		"..oLLLTTTTttto..",
		"..oLLLTTTTttto..",
		"..oLLLTTTTttto..",
		"..oLLLTTTTttto..",
		"..oLLLTTTTttto..",
		"..oLLLTTTTttto..",
		"..oLLLTTTTttto..",
		"..oLLLTTTTttto..",
		"..oLLLTTTTttto..",
		"..oLLLTTTTttto..",
		"..oLLLTTTTttto..",
		"..oLLLTTTTttto..",
		"..oLLLTTTTttto..",
		"..oLLLTTTTttto..",
		"..oLLLTTTTttto..",
		"..oLLLTTTTttto..",
		"..oLLLTTTTttto..",
		"..oLLLTTTTttto..",
		"..oLLLTTTTttto..",
		"..oLLLTTTTttto..",
		"..oLLLTTTTttto..",
		".oooLLTTTTttooo.",
		"oooyyyyyyyyyyooo",
		"ooyyyyyyyyyyyyoo",
		"......oggggo....",
		"......oggggo....",
		"......oggggo....",
		"......oggggo....",
		"......oggggo....",
		"......oggggo....",
		"......ooyyoo....",
		".......oyyo.....",
		".......oooo.....",
		"........oo......",
	]},
	&"dagger": {"grip": Vector2i(4, 14), "rows": [
		".....oo...",
		"...oooooo.",
		"...oLLTTo.",
		"..ooLLTToo",
		"..oLLLTTTo",
		"..oLLLTTTo",
		"..oLLLTTTo",
		"..oLLLTTTo",
		"..oLLLTTTo",
		"..oLLLTTTo",
		"..oLLLTTTo",
		".oooLLTTTo",
		"ooyyyyyyoo",
		"ooyyyyyyo.",
		".oooggooo.",
		"..oggggo..",
		"..oggggo..",
		"..oggggo..",
		"..ooyyoo..",
		"...oyyo...",
		"...oooo...",
		"....oo....",
	]},
	&"curved": {"grip": Vector2i(6, 26), "rows": [
		".........oo.....",
		".......oooooo...",
		".......oLLTToo..",
		".....ooLLTTToo..",
		".....oLLLTToo...",
		"....ooLLTTTo....",
		"....oLLLTToo....",
		"...ooLLTTTo.....",
		"...oLLLTToo.....",
		"..ooLLTTTo......",
		"..oLLLTTTo......",
		"..oLLLTTTo......",
		"..oLLLTTTo......",
		"..oLLLTTTo......",
		"..oLLLTTTo......",
		"..oLLLTTooo.....",
		"..oLLLTTtto.....",
		"..oLLLTTttoo....",
		"..ooLLTTttto....",
		"...oLLTTttto....",
		"...oooTTttto....",
		"....oTTTttto....",
		"....oyyyyyoo....",
		"....oyyyyyo.....",
		"....ogggooo.....",
		"....oggggo......",
		"....oggggo......",
		"....oggggo......",
		"....oggggo......",
		"....oggggo......",
		"....ooyyoo......",
		".....oyyo.......",
		".....oooo.......",
		"......oo........",
	]},
	&"shadow": {"grip": Vector2i(6, 26), "rows": [
		".........oo.....",
		".......oooooo...",
		".......oppVVo...",
		".....ooppVVVoo..",
		".....opppVVvvo..",
		"....ooppVVvvvo..",
		"....opppVVvvoo..",
		"...ooppVVvvvo...",
		"...opppVVvvoo...",
		"..ooppVVvvvo....",
		"..opppVVvvvo....",
		"..opppVVvvvo....",
		"..opppVVvvvo....",
		"..opppVVvvvo....",
		"..opppVVvvvo....",
		"..opppVVvvvo....",
		"..opppVVvvvo....",
		"..opppVVvvvoo...",
		"..ooppVVvvvvo...",
		"...oppVVvvvvoo..",
		"...oooVVvvvvoo..",
		"....oVVVvvvvo...",
		"....oyyyyyooo...",
		"....oyyyyyo.....",
		"....ovvvooo.....",
		"....ovvvvo......",
		"....ovvvvo......",
		"....ovvvvo......",
		"....ovvvvo......",
		"....ovvvvo......",
		"....ooyyoo......",
		".....oyyo.......",
		".....oooo.......",
		"......oo........",
	]},
	&"fang": {"grip": Vector2i(6, 22), "rows": [
		".....oo.......",
		"....ooooo.....",
		"....offfo.....",
		"...oofffoo....",
		"...offfFFo....",
		"..ooffFFFo....",
		"..offfFFFo....",
		"..offfFFFoo...",
		"..offfFFFFo...",
		"..offfFFFFoo..",
		"..ooffFFFFFo..",
		"...offfFFFFo..",
		"...ooffFFFFo..",
		"....offfFFFo..",
		"....offfFFFo..",
		"....offfFFFo..",
		"....offfFFFo..",
		"....offfFFFoo.",
		"....offfFFFFoo",
		"....offfFFFFoo",
		"....orrrrrooo.",
		"....orrrrrro..",
		"....oRRrrrro..",
		"....oRRRrrro..",
		"....oRRRrrro..",
		"....oRRrrrro..",
		"....oorrrroo..",
		".....orrrro...",
		".....oooooo...",
		".......oo.....",
	]},
	&"bow": {"grip": Vector2i(6, 18), "rows": [
		"..............oo..",
		".............oooo.",
		"...........ooorroo",
		".........oooRorroo",
		".........orrRRooo.",
		".......oorrRRRo...",
		".......orrrRRoo...",
		"......oorrRRo.....",
		"......orrrooo.....",
		".....oorrro.......",
		".....orrroo.......",
		"....oorrro........",
		"....orrrro........",
		"....orrrooo.......",
		"....orrrRRo.......",
		"....orrrRRoo......",
		"....oGGGGGGo......",
		"....oGGGGGGo......",
		"....oGGGGGGo......",
		"....oGGGGGGo......",
		"....orrrRRoo......",
		"....orrrRRo.......",
		"....orrrooo.......",
		"....orrrro........",
		"....oorrro........",
		".....orrroo.......",
		".....oorrro.......",
		"......orrrooo.....",
		"......oorrRRo.....",
		".......orrrRRoo...",
		".......oorrRRRo...",
		".........orrRRooo.",
		".........oooRorroo",
		"...........ooorroo",
		".............oooo.",
		"..............oo..",
	]},
	&"mace": {"grip": Vector2i(8, 22), "rows": [
		".....oooooooo.....",
		"...oooTTTTTTooo...",
		"...ossTTTTTTsso...",
		".oossTTTTTTTTssoo.",
		".osssTLLTTTTTssso.",
		"oossTTLLTTTTTTssoo",
		"osssTTTTTTTTTTssso",
		"osssTTTTTTTTTTssso",
		"oossTTTTTTTTTTssoo",
		".osssTTTTTTTTssso.",
		".oossTTTTTTTTssoo.",
		"...ossTTTTTTsso...",
		"...oooooooooooo...",
		".....oooooooo.....",
		".....oooggooo.....",
		"......oggggo......",
		"......oggggo......",
		"......oggggo......",
		"......oggggo......",
		"......oggggo......",
		"......oggggo......",
		"......oggggo......",
		"......oggggo......",
		"......oggggo......",
		"......oggggo......",
		"......oggggo......",
		"......ooyyoo......",
		".......oyyo.......",
		".......oooo.......",
		"........oo........",
	]},
	&"club": {"grip": Vector2i(6, 20), "rows": [
		".....oooooo...",
		"....ooorRRooo.",
		"....ororRRRRo.",
		"...oorrrRRRRoo",
		"...orrrrRRRRRo",
		"..oorrrrRRRRRo",
		"..orrrrrRRRRRo",
		"..orrrrrRRRRRo",
		"..oorrrrRRRRoo",
		"...orrrrRRRRo.",
		"...oorrrRRRoo.",
		"....orrrRRRo..",
		"....orrrRRRo..",
		"....orrrRRRo..",
		"....orrrRRoo..",
		"....orrrRRo...",
		"....orrrooo...",
		"....orrrro....",
		"....orrrro....",
		"....orrrro....",
		"....orrrro....",
		"....orrrro....",
		"....orrrro....",
		"....orrrro....",
		"....oorroo....",
		".....orro.....",
		".....oooo.....",
		"......oo......",
	]},
	&"bone": {"grip": Vector2i(6, 24), "rows": [
		".......oo.....",
		".....oooooo...",
		".....owwWWo...",
		"....oowwWWoo..",
		"....owwwWWWo..",
		"....owwwWWWo..",
		"....owwwWWWo..",
		"....owwwWWWo..",
		"....owwwWWWo..",
		"....owwwWWWo..",
		"....owwwWWWo..",
		"....owwwWWWo..",
		"....owwwWWWo..",
		"....owwwWWWo..",
		"....owwwWWWo..",
		"....owwwWWWo..",
		"....owwwWWWo..",
		"...oowwwWWWo..",
		"...owwwwWWWo..",
		".oowwwwwwWWoo.",
		"oowwwwwwwwWWoo",
		"oowwwwwwwwWWoo",
		"....osssWWWoo.",
		"....osssWWo...",
		"....osssooo...",
		"....osssso....",
		"....osssso....",
		"....osssso....",
		"....oossoo....",
		".....osso.....",
		".....oooo.....",
		"......oo......",
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


## Reach from the grip to the tip, in world pixels.
static func length_of(kind: StringName) -> float:
	return (float(grip_of(kind).y) + SCALE) / SCALE


## Grip point as a texture offset: centre of the SCALE×SCALE grip block, in texels.
static func grip_center(kind: StringName) -> Vector2:
	return Vector2(grip_of(kind)) + Vector2.ONE * SCALE * 0.5


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
