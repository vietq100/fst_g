class_name PetSprites
extends RefCounted
## Pixel pets that follow a Hunter (D59): pup, chick, slime, teddy and wisp, 12 × 11 px text
## bitmaps tinted by the pet item (A base, B shade, C light), with a second "hop" frame one pixel
## higher and squashed. Facing right; callers mirror for left. Cached per kind, tint and frame.

const SIZE := Vector2i(12, 11)
const OUTLINE := Color("2a1a12")

const BITMAPS := {
	&"pup": [
		"............",
		"..oo....oo..",
		".oBAo..oABo.",
		".oAAAooAAAo.",
		".oAAAAAAAAo.",
		"oCAwkAAwkAAo",
		"oCAAAnnAAAAo",
		".oAAAAAAAAo.",
		"..oAAAAAABo.",
		"..oBo..oBo..",
		"..oo....oo..",
	],
	&"chick": [
		"............",
		"....ooo.....",
		"...oCAAo....",
		"..oCAwkAo...",
		"..oAAAAAnno.",
		".oCAAAAAoo..",
		"oCAAAAAAAo..",
		"oAAABBAAAo..",
		".oAAAAAABo..",
		"..ooYooYo...",
		"....Y..Y....",
	],
	&"slime": [
		"............",
		"............",
		"....oooo....",
		"...oCCAAo...",
		"..oCwAAAAo..",
		".oCAAAAAAAo.",
		".oAwkAAwkAo.",
		"oAAAAAAAAAAo",
		"oAAAAnnAAABo",
		".oBBBBBBBBo.",
		"..oooooooo..",
	],
	&"teddy": [
		"..oo....oo..",
		".oAno..onAo.",
		".oAAooooAAo.",
		".oCAAAAAAAo.",
		".oAwkAAwkAo.",
		".oAAAnnAAAo.",
		"..oAAYYAAo..",
		".oAAYyyYAAo.",
		".oAAAAAAAAo.",
		"..oAAooAAo..",
		"..ooo..ooo..",
	],
	&"wisp": [
		".....oo.....",
		"....oCCo....",
		"...oCwwCo...",
		"..oCwwwwAo..",
		".oCwwkwkwAo.",
		".oAwwwwwwAo.",
		".oAAwwwwAAo.",
		"..oAAAAAAo..",
		"...oAAAo....",
		"....oAo.....",
		".....o......",
	],
}
## Fixed colours (w eye white, k pupil, n nose / cheek, Y y gold).
const FIXED := {"w": Color("fbf6ee"), "k": Color("1d140e"), "n": Color("e8789a"), "Y": Color("d9a640"), "y": Color("f2d16b")}
const DEFAULT_TINT := {&"pup": Color("c8925a"), &"chick": Color("f2d16b"), &"slime": Color("6fd36f"),
	&"teddy": Color("b07a4a"), &"wisp": Color("9fd6ff")}

static var _cache: Dictionary = {}


## Pet kind of an item: its `look_id`, else a kind named in its id, else a pup.
static func kind_for(item: ItemDefinition) -> StringName:
	if item == null:
		return &""
	if BITMAPS.has(item.look_id):
		return item.look_id
	var id := String(item.id)
	for kind: StringName in BITMAPS:
		if id.contains(String(kind)):
			return kind
	return &"pup"


## Frame 0 = standing, 1 = hop (squashed, one pixel up). Bottom row is the feet.
static func texture(kind: StringName, tint: Color, frame: int = 0) -> ImageTexture:
	if not BITMAPS.has(kind):
		return null
	var base: Color = tint if tint != Color.WHITE else DEFAULT_TINT.get(kind, Color.WHITE)
	var key := "%s|%s|%d" % [kind, base.to_html(false), frame]
	if _cache.has(key):
		return _cache[key]
	var palette := FIXED.duplicate()
	palette["o"] = OUTLINE
	palette["A"] = base
	palette["B"] = base.darkened(0.3)
	palette["C"] = base.lightened(0.3)
	var rows: Array = BITMAPS[kind]
	var image := Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
	for y in SIZE.y:
		# Hop: drop the second row and repeat the last one (body stretches up, feet stay).
		var source_y := y
		if frame == 1:
			source_y = mini(y + 1, SIZE.y - 1) if y < SIZE.y - 2 else y
		var row: String = rows[source_y]
		for x in SIZE.x:
			var code := row[x]
			if palette.has(code):
				image.set_pixel(x, y, palette[code])
	var result := ImageTexture.create_from_image(image)
	_cache[key] = result
	return result
