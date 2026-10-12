class_name PixelIcons
extends RefCounted
## Tiny 12×12 pixel-art icons drawn from text bitmaps (matches the game's pixel look, no asset
## files). Each row is padded with '.' (transparent) to 12 pixels.

const SIZE := 12

const PALETTE := {
	"k": Color("2a1c10"), "y": Color("f2c94c"), "Y": Color("b8892a"), "w": Color("f4f1ea"), "r": Color("c9503f"),
	"o": Color("e0874a"), "b": Color("8b5e3c"), "B": Color("5a3b22"), "g": Color("9aa0a6"), "G": Color("5d5a55"),
	"l": Color("5fa8ff"), "n": Color("6fbf5f"), "p": Color("e8b98a"), "s": Color("cfd6dd"),
}

const BITMAPS := {
	&"coin": [
		"....kkkk....", "..kkyyyykk..", ".kyyyYYyyyk.", ".kyyYyyyyyk.", "kyyyYyyyyyyk", "kyyyYyyyyYyk",
		"kyyyYyyyyYyk", "kyyyyYYYYyyk", ".kyyyyyyyyk.", ".kyyyyyyyyk.", "..kkyyyykk..", "....kkkk....",
	],
	&"town": [
		"....kkkk....", "...krrrrk...", "..krrrrrrk..", ".krrrrrrrrk.", "krrrrrrrrrrk", ".kwwwwwwwwk.",
		".kwyywwyywk.", ".kwyywwyywk.", ".kwwwkkwwwk.", ".kwwwkkwwwk.", ".kwwwkkwwwk.", ".kkkkkkkkkk.",
	],
	&"food": [
		"......kkk...", ".....kooook.", "....koooook.", "...kooooook.", "...kooooook.", "..kooooook..",
		".kooooook...", "kwwkook.....", "kwwwkk......", ".kwwk.......", "..kk........", "............",
	],
	&"bed": [
		"............", "kk..........", "kbk.........", "kbkkkkkkkkk.", "kbwwwlllllk.", "kbwwwlllllk.",
		"kbbbbbbbbbbk", "kbbbbbbbbbbk", "kBk.......kB", "kBk.......kB", "kk.........k", "............",
	],
	&"bag": [
		"....kkkk....", "...kbbbbk...", "....kbbk....", "..kkbbbbkk..", ".kbbbbbbbbk.", "kbbbyybbbbbk",
		"kbbbyybbbbbk", "kbbbbbbbbbbk", "kbbbbbbbbbbk", ".kbbbbbbbbk.", "..kkkkkkkk..", "............",
	],
	&"build": [
		"..kkkkkk....", ".kggggggk...", ".kgsssssgk..", ".kggggggk...", "..kkkbkk....", "....kbk.....",
		"....kbk.....", "....kbk.....", "....kbk.....", "....kbk.....", "....kBk.....", ".....k......",
	],
	&"hunters": [
		"...kkkk.....", "..kppppk....", "..kpkkpk....", "..kppppk....", "...kkkk.....", "..klllllk...",
		".kklllllkk..", ".kplllllpk..", "..klllllk...", "..kkk.kkk...", "..kBk.kBk...", "..kkk.kkk...",
	],
	&"quests": [
		".kkkkkkkkk..", "kwwwwwwwwwk.", "kkkkkkkkkkk.", ".kwwwwwwwk..", ".kwkkkkkwk..", ".kwwwwwwwk..",
		".kwkkkkkwk..", ".kwwwwwwwk..", ".kwkkkwwwk..", "kkkkkkkkkkk.", "kwwwwwwwwwk.", ".kkkkkkkkk..",
	],
	&"skull": [
		"..kkkkkkkk..", ".kwwwwwwwwk.", "kwwwwwwwwwwk", "kwwwwwwwwwwk", "kwkkwwwwkkwk", "kwkkwwwwkkwk",
		"kwwwwkkwwwwk", ".kwwwkkwwwk.", "..kwwwwwwk..", "..kwkwkwkk..", "..kkkkkkkk..", "............",
	],
	&"book": [
		".kkkkkkkkkk.", "kwwwwkwwwwwk", "kwkkwkwkkkwk", "kwwwwkwwwwwk", "kwkkwkwkkkwk", "kwwwwkwwwwwk",
		"kwkkwkwkkkwk", "kwwwwkwwwwwk", "kbbbbkbbbbbk", ".kkkkkkkkkk.", "............", "............",
	],
	&"trophy": [
		".kkkkkkkkkk.", "kkyyyyyyyykk", "kykyyyyyykyk", "kykyyyyyykyk", ".kkkyyyykkk.", "...kyyyyk...",
		"....kyyk....", "....kyyk....", "...kYYYYk...", "..kYYYYYYk..", "..kkkkkkkk..", "............",
	],
	&"mail": [
		"............", "kkkkkkkkkkkk", "kwkwwwwwwkwk", "kwwkwwwwkwwk", "kwwwkwwkwwwk", "kwwwwkkwwwwk",
		"kwwwwwwwwwwk", "kwwwwwwwwwwk", "kkkkkkkkkkkk", "............", "............", "............",
	],
	&"chest": [
		"..kkkkkkkk..", ".kbbbbbbbbk.", "kbbbbbbbbbbk", "kkkkkyykkkkk", "kbbbbyybbbbk", "kbbbbbbbbbbk",
		"kbbbbbbbbbbk", "kbbbbbbbbbbk", "kkkkkkkkkkkk", "............", "............", "............",
	],
	&"shop": [
		"rwrwrwrwrwrw", "rwrwrwrwrwrw", "kkkkkkkkkkkk", ".kb......bk.", ".kb.wwww.bk.", ".kb.wyyw.bk.",
		".kb.wwww.bk.", ".kbbbbbbbbk.", ".kbbbbbbbbk.", ".kkkkkkkkkk.", "............", "............",
	],
	&"arch": [
		"..kkkkkkkk..", ".kggggggggk.", "kgsskkkkssgk", "kgskkkkkksgk", "kgskkkkkksgk", "kgskkkkkksgk",
		"kgskkkkkksgk", "kgskkkkkksgk", "kgskkkkkksgk", "kkkkkkkkkkkk", "............", "............",
	],
	&"close": [
		"kk........kk", "kwk......kwk", ".kwk....kwk.", "..kwk..kwk..", "...kwkkwk...", "....kwwk....",
		"....kwwk....", "...kwkkwk...", "..kwk..kwk..", ".kwk....kwk.", "kwk......kwk", "kk........kk",
	],
	&"star": [
		".....kk.....", "....kyyk....", "....kyyk....", "kkkkkyykkkkk", "kyyyyyyyyyyk", ".kyyyyyyyyk.",
		"..kyyyyyyk..", "..kyyyyyyk..", ".kyyykkyyyk.", ".kyykk.kyyk.", "kyk......kyk", "kk........kk",
	],
	&"target": [
		"....kkkk....", "..kkwwwwkk..", ".kwwwkkwwwk.", ".kwwwkkwwwk.", "kwwwwkkwwwwk", "kkkkkwwkkkkk",
		"kkkkkwwkkkkk", "kwwwwkkwwwwk", ".kwwwkkwwwk.", ".kwwwkkwwwk.", "..kkwwwwkk..", "....kkkk....",
	],
	&"dungeon": [
		".........kk.", "........ksk.", ".......ksk..", "......ksk...", ".k...ksk....", ".kk.ksk.....",
		"..kksk......", "...kyk......", "..kykyk.....", ".kbk.kyk....", "kbk.........", "kk..........",
	],
}

static var _cache: Dictionary = {}


## The icon as a texture, enlarged `scale` times with hard pixels.
static func texture(icon: StringName, scale: int = 2) -> Texture2D:
	var key := "%s@%d" % [icon, scale]
	if _cache.has(key):
		return _cache[key]
	var rows: Array = BITMAPS.get(icon, BITMAPS[&"coin"])
	var image := Image.create(SIZE * scale, SIZE * scale, false, Image.FORMAT_RGBA8)
	for y in SIZE:
		var row: String = rows[y] if y < rows.size() else ""
		for x in SIZE:
			var code := row[x] if x < row.length() else "."
			if code == "." or not PALETTE.has(code):
				continue
			for dy in scale:
				for dx in scale:
					image.set_pixel(x * scale + dx, y * scale + dy, PALETTE[code])
	var result := ImageTexture.create_from_image(image)
	_cache[key] = result
	return result


## A small TextureRect showing the icon.
static func rect(icon: StringName, scale: int = 1) -> TextureRect:
	var node := TextureRect.new()
	node.texture = texture(icon, scale)
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node.stretch_mode = TextureRect.STRETCH_KEEP
	node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func clear_cache() -> void:
	_cache.clear()
