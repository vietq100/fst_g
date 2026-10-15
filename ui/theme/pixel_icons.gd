class_name PixelIcons
extends RefCounted
## Tiny 12×12 pixel-art icons drawn from text bitmaps (matches the game's pixel look, no asset
## files). Each row is padded with '.' (transparent) to 12 pixels.

## Layout size of an icon at scale 1, in px. Bitmaps are TEXELS square (D71: twice the density
## of the 12×12 set); textures keep their full resolution and lay out at SIZE × scale px.
const SIZE := 12
const TEXELS := 24

const PALETTE := {
	"k": Color("2a1c10"), "y": Color("f2c94c"), "Y": Color("b8892a"), "w": Color("f4f1ea"), "r": Color("c9503f"),
	"o": Color("e0874a"), "b": Color("8b5e3c"), "B": Color("5a3b22"), "g": Color("9aa0a6"), "G": Color("5d5a55"),
	"l": Color("5fa8ff"), "n": Color("6fbf5f"), "p": Color("e8b98a"), "s": Color("cfd6dd"),
}

const BITMAPS := {
	&"coin": [
		".........kkkkkk.........", ".......kkkkkkkkkk.......", ".....kkkkyyyyyykkkk.....", "...kkkkyyyyyyyyyykkkk...",
		"...kkyyyyyYYYYyyyyykk...", "..kkyyyyyYYYYYyyyyyykk..", "..kkyyyyYYYyyyyyyyyykk..", ".kkyyyyyYYyyyyyyyyyyykk.",
		".kkyyyyyYYyyyyyyyyyyykk.", "kkyyyyyyYYyyyyyyyyyyyykk", "kkyyyyyyYYyyyyyyyyYYyykk", "kkyyyyyyYYyyyyyyyyYYyykk",
		"kkyyyyyyYYyyyyyyyyYYyykk", "kkyyyyyyYYYyyyyyyYYYyykk", "kkyyyyyyyYYYYYYYYYYyyykk", ".kkyyyyyyyYYYYYYYYyyykk.",
		".kkyyyyyyyyyyyyyyyyyykk.", "..kkyyyyyyyyyyyyyyyykk..", "..kkyyyyyyyyyyyyyyyykk..", "...kkyyyyyyyyyyyyyykk...",
		"...kkkkyyyyyyyyyykkkk...", ".....kkkkyyyyyykkkk.....", ".......kkkkkkkkkk.......", ".........kkkkkk.........",
	],
	&"town": [
		".........kkkkkk.........", ".......kkkkkkkkkk.......", ".......kkrrrrrrkk.......", ".....kkrrrrrrrrrrkk.....",
		".....kkrrrrrrrrrrkk.....", "...kkrrrrrrrrrrrrrrkk...", "...kkrrrrrrrrrrrrrrkk...", ".kkrrrrrrrrrrrrrrrrrrkk.",
		"kkrrrrrrrrrrrrrrrrrrrrkk", "kkrrrrrrrrrrrrrrrrrrrrkk", ".kkkwwwwwwwwwwwwwwwwkkk.", "..kkwwwwwwwwwwwwwwwwkk..",
		"..kkwwwyywwwwwwyywwwkk..", "..kkwwyyyywwwwyyyywwkk..", "..kkwwyyyywwwwyyyywwkk..", "..kkwwwyywwwwwwyywwwkk..",
		"..kkwwwwwwwkkwwwwwwwkk..", "..kkwwwwwwkkkkwwwwwwkk..", "..kkwwwwwwkkkkwwwwwwkk..", "..kkwwwwwwkkkkwwwwwwkk..",
		"..kkwwwwwwkkkkwwwwwwkk..", "..kkkwwwwkkkkkkwwwwkkk..", "..kkkkkkkkkkkkkkkkkkkk..", "...kkkkkkkkkkkkkkkkkk...",
	],
	&"food": [
		".............kkkk.......", "...........kkkkkkk......", "...........kkoooooook...", ".........kkoooooooookk..",
		".........kkoooooooookk..", ".......kkoooooooooookk..", ".......kkoooooooooookk..", "......kkooooooooooookk..",
		"......kkooooooooooookk..", ".....kkooooooooooookk...", ".....kkooooooooooookk...", "...kkooooooooooookk.....",
		"...kkooooooooooookk.....", ".kkkooooooooooook.......", ".kkwwwkooooook..........", "kkwwwwwkkookk...........",
		"kkwwwwwkkkkkk...........", ".kkwwwwwkkk.............", ".kkwwwwwkkk.............", "...kkwwkk...............",
		"...kkkkkk...............", ".....kk.................", "........................", "........................",
	],
	&"bed": [
		"........................", "........................", ".kk.....................", "kkkkk...................",
		"kkbbk...................", "kkbbkkk.................", "kkbbkkkkkkkkkkkkkkkkk...", "kkbbkkkkkkkkkkkkkkkkkk..",
		"kkbbwwwwwwlllllllllkkk..", "kkbbwwwwwwllllllllllkk..", "kkbbwwwwwwllllllllllkk..", "kkbbbwwwwwllllllllllkkk.",
		"kkbbbbbbbbbbbbbbbbbbbkk.", "kkbbbbbbbbbbbbbbbbbbbbkk", "kkbbbbbbbbbbbbbbbbbbbbkk", "kkbbbbbbbbbbbbbbbbbbbkkk",
		"kkBBkk..............kkkB", "kkBBkk..............kkBB", "kkBBkk..............kkBB", "kkBBk................kkB",
		"kkkkk................kkk", ".kk...................kk", "........................", "........................",
	],
	&"bag": [
		".........kkkkkk.........", ".......kkkkkkkkkk.......", "......kkbbbbbbbbkk......", "......kkbbbbbbbbkk......",
		"........kkbbbbkk........", "........kkbbbbkk........", ".....kkkkbbbbbbkkkk.....", "...kkkkbbbbbbbbbbkkkk...",
		"...kkbbbbbbbbbbbbbbkk...", ".kkbbbbbbbbbbbbbbbbbbkk.", ".kkbbbbbbyybbbbbbbbbbkk.", "kkbbbbbbyyyybbbbbbbbbbkk",
		"kkbbbbbbyyyybbbbbbbbbbkk", "kkbbbbbbbyybbbbbbbbbbbkk", "kkbbbbbbbbbbbbbbbbbbbbkk", "kkbbbbbbbbbbbbbbbbbbbbkk",
		"kkbbbbbbbbbbbbbbbbbbbbkk", ".kkbbbbbbbbbbbbbbbbbbkk.", ".kkbbbbbbbbbbbbbbbbbbkk.", "...kkbbbbbbbbbbbbbbkk...",
		"...kkkkkkkkkkkkkkkkkk...", ".....kkkkkkkkkkkkkk.....", "........................", "........................",
	],
	&"build": [
		".....kkkkkkkkkk.........", "...kkkkkkkkkkkkkk.......", "...kkggggggggggkk.......", "..kkgggggggggggggkk.....",
		"..kkggssssssssssggkk....", "..kkggssssssssssggkk....", "..kkgggggggggggggkk.....", "...kkggggggggggkk.......",
		"...kkkkkkkbbkkkkk.......", ".....kkkkkbbkkk.........", ".......kkkbbkkk.........", "........kkbbkk..........",
		"........kkbbkk..........", "........kkbbkk..........", "........kkbbkk..........", "........kkbbkk..........",
		"........kkbbkk..........", "........kkbbkk..........", "........kkbbkk..........", "........kkbbkk..........",
		"........kkBBkk..........", ".........kBBk...........", ".........kkkk...........", "..........kk............",
	],
	&"hunters": [
		".......kkkkkk...........", ".....kkkkkkkkkk.........", ".....kkppppppkk.........", "....kkppppppppkk........",
		"....kkppkkkkppkk........", "....kkppkkkkppkk........", "....kkppppppppkk........", ".....kkppppppkk.........",
		"......kkkkkkkkk.........", "......kkkkkkkk..........", ".....kklllllllllk.......", "...kkkllllllllllkkk.....",
		"...kkkllllllllllkkk.....", "..kkkkllllllllllkkkk....", "..kkppllllllllllppkk....", "...kppllllllllllppk.....",
		"...kkkllllllllllkkk.....", "....kkkllllllllkkk......", "....kkkkkk..kkkkkk......", "....kkkkkk..kkkkkk......",
		"....kkBBkk..kkBBkk......", "....kkBBkk..kkBBkk......", "....kkkkkk..kkkkkk......", ".....kkkk....kkkk.......",
	],
	&"quests": [
		"...kkkkkkkkkkkkkkkk.....", ".kkkkkkkkkkkkkkkkkkkk...", ".kwwwwwwwwwwwwwwwwwwk...", "kkwwwwwwwwwwwwwwwwwwkk..",
		"kkkkkkkkkkkkkkkkkkkkkk..", ".kkkkkkkkkkkkkkkkkkkk...", ".kkkkwwwwwwwwwwwwkkkk...", "..kkwwwwwwwwwwwwwwkk....",
		"..kkwwkkkkkkkkkkwwkk....", "..kkwwkkkkkkkkkkwwkk....", "..kkwwwwwwwwwwwwwwkk....", "..kkwwwwwwwwwwwwwwkk....",
		"..kkwwkkkkkkkkkkwwkk....", "..kkwwkkkkkkkkkkwwkk....", "..kkwwwwwwwwwwwwwwkk....", "..kkwwwwwwwwwwwwwwkk....",
		"..kkwwwkkkkwwwwwwwkk....", ".kkkwwkkkkkkkwwwwkkkk...", ".kkkkkkkkkkkkkkkkkkkk...", "kkkkkkkkkkkkkkkkkkkkkk..",
		"kkwwwwwwwwwwwwwwwwwwkk..", ".kwwwwwwwwwwwwwwwwwwk...", ".kkkkkkkkkkkkkkkkkkkk...", "...kkkkkkkkkkkkkkkk.....",
	],
	&"skull": [
		".....kkkkkkkkkkkkkk.....", "...kkkkkkkkkkkkkkkkkk...", "...kkwwwwwwwwwwwwwwkk...", ".kkwwwwwwwwwwwwwwwwwwkk.",
		".kkwwwwwwwwwwwwwwwwwwkk.", "kkwwwwwwwwwwwwwwwwwwwwkk", "kkwwwwwwwwwwwwwwwwwwwwkk", "kkwwwwwwwwwwwwwwwwwwwwkk",
		"kkwwwkkwwwwwwwwwwkkwwwkk", "kkwwkkkkwwwwwwwwkkkkwwkk", "kkwwkkkkwwwwwwwwkkkkwwkk", "kkwwwkkwwwwwwwwwwkkwwwkk",
		"kkwwwwwwwwwkkwwwwwwwwwkk", ".kkwwwwwwwkkkkwwwwwwwkk.", ".kkwwwwwwwkkkkwwwwwwwkk.", "...kkwwwwwwkkwwwwwwkk...",
		"...kkwwwwwwwwwwwwwwkk...", "....kkwwwwwwwwwwwkkk....", "....kkwwkkwwkkwwwkkk....", "....kkwwkkwwkkwwkkkk....",
		"....kkkkkkkkkkkkkkkk....", ".....kkkkkkkkkkkkkk.....", "........................", "........................",
	],
	&"book": [
		"...kkkkkkkkkkkkkkkkkk...", ".kkkkkkkkkkkkkkkkkkkkkk.", ".kkwwwwwwkkkkwwwwwwwwkk.", "kkwwwwwwwwkkwwwwwwwwwwkk",
		"kkwwkkkkwwkkwwkkkkkkwwkk", "kkwwkkkkwwkkwwkkkkkkwwkk", "kkwwwwwwwwkkwwwwwwwwwwkk", "kkwwwwwwwwkkwwwwwwwwwwkk",
		"kkwwkkkkwwkkwwkkkkkkwwkk", "kkwwkkkkwwkkwwkkkkkkwwkk", "kkwwwwwwwwkkwwwwwwwwwwkk", "kkwwwwwwwwkkwwwwwwwwwwkk",
		"kkwwkkkkwwkkwwkkkkkkwwkk", "kkwwkkkkwwkkwwkkkkkkwwkk", "kkwwwwwwwwkkwwwwwwwwwwkk", "kkwwwwwwwwkkwwwwwwwwwwkk",
		"kkbbbbbbbbkkbbbbbbbbbbkk", ".kkbbbbbbkkkkbbbbbbbbkk.", ".kkkkkkkkkkkkkkkkkkkkkk.", "...kkkkkkkkkkkkkkkkkk...",
		"........................", "........................", "........................", "........................",
	],
	&"trophy": [
		"...kkkkkkkkkkkkkkkkkk...", ".kkkkkkkkkkkkkkkkkkkkkk.", ".kkkyyyyyyyyyyyyyyyykkk.", "kkkyyyyyyyyyyyyyyyyyykkk",
		"kkyykkyyyyyyyyyyyykkyykk", "kkyykkyyyyyyyyyyyykkyykk", "kkyykkyyyyyyyyyyyykkyykk", ".kyykkkyyyyyyyyyykkkyyk.",
		".kkkkkkyyyyyyyyyykkkkkk.", "...kkkkkyyyyyyyykkkkk...", ".....kkkyyyyyyyykkk.....", ".......kkyyyyyykk.......",
		".......kkyyyyyykk.......", "........kkyyyykk........", "........kkyyyykk........", ".......kkkyyyykkk.......",
		".......kkYYYYYYkk.......", ".....kkYYYYYYYYYYkk.....", ".....kYYYYYYYYYYYYk.....", "....kkYYYYYYYYYYYYkk....",
		"....kkkkkkkkkkkkkkkk....", ".....kkkkkkkkkkkkkk.....", "........................", "........................",
	],
	&"mail": [
		"........................", "........................", ".kkkkkkkkkkkkkkkkkkkkkk.", "kkkkkkkkkkkkkkkkkkkkkkkk",
		"kkwwkkwwwwwwwwwwwwkkwwkk", "kkwwkkwwwwwwwwwwwwkkwwkk", "kkwwwkkkwwwwwwwwkkkwwwkk", "kkwwwwkkkwwwwwwkkkwwwwkk",
		"kkwwwwwkkkwwwwkkkwwwwwkk", "kkwwwwwwkkkwwkkkwwwwwwkk", "kkwwwwwwwkkkkkkwwwwwwwkk", "kkwwwwwwwwkkkkwwwwwwwwkk",
		"kkwwwwwwwwwwwwwwwwwwwwkk", "kkwwwwwwwwwwwwwwwwwwwwkk", "kkwwwwwwwwwwwwwwwwwwwwkk", "kkkwwwwwwwwwwwwwwwwwwkkk",
		"kkkkkkkkkkkkkkkkkkkkkkkk", ".kkkkkkkkkkkkkkkkkkkkkk.", "........................", "........................",
		"........................", "........................", "........................", "........................",
	],
	&"chest": [
		".....kkkkkkkkkkkkkk.....", "...kkkkkkkkkkkkkkkkkk...", "...kkbbbbbbbbbbbbbbkk...", ".kkbbbbbbbbbbbbbbbbbbkk.",
		".kbbbbbbbbbbbbbbbbbbbbk.", "kkbbbbbbbbbbbbbbbbbbbbkk", "kkkkkkkkkkyyyykkkkkkkkkk", "kkkkkkkkkkyyyykkkkkkkkkk",
		"kkkbbbbbbbyyyybbbbbbbkkk", "kkbbbbbbbbbyybbbbbbbbbkk", "kkbbbbbbbbbbbbbbbbbbbbkk", "kkbbbbbbbbbbbbbbbbbbbbkk",
		"kkbbbbbbbbbbbbbbbbbbbbkk", "kkbbbbbbbbbbbbbbbbbbbbkk", "kkbbbbbbbbbbbbbbbbbbbbkk", "kkkbbbbbbbbbbbbbbbbbbkkk",
		"kkkkkkkkkkkkkkkkkkkkkkkk", ".kkkkkkkkkkkkkkkkkkkkkk.", "........................", "........................",
		"........................", "........................", "........................", "........................",
	],
	&"shop": [
		".rwwrrwwrrwwrrwwrrwwrrw.", "rrwwrrwwrrwwrrwwrrwwrrww", "rrwwrrwwrrwwrrwwrrwwrrww", "rrwwrrwwrrwwrrwwrrwwrrww",
		"kkkkkkkkkkkkkkkkkkkkkkkk", ".kkkkkkkkkkkkkkkkkkkkkk.", ".kkkkb............bkkkk.", "..kkbb............bbkk..",
		"..kkbb...wwwwww...bbkk..", "..kkbb..wwwwwwww..bbkk..", "..kkbb..wwyyyyww..bbkk..", "..kkbb..wwyyyyww..bbkk..",
		"..kkbb..wwwwwwww..bbkk..", "..kkbbb.wwwwwwww.bbbkk..", "..kkbbbbbbbbbbbbbbbbkk..", "..kkbbbbbbbbbbbbbbbbkk..",
		"..kkbbbbbbbbbbbbbbbbkk..", "..kkkbbbbbbbbbbbbbbkkk..", "..kkkkkkkkkkkkkkkkkkkk..", "...kkkkkkkkkkkkkkkkkk...",
		"........................", "........................", "........................", "........................",
	],
	&"arch": [
		".....kkkkkkkkkkkkkk.....", "...kkkkkkkkkkkkkkkkkk...", "...kkggggggggggggggkk...", ".kkggggggggggggggggggkk.",
		".kkggssskkkkkkkksssggkk.", "kkggssskkkkkkkkkksssggkk", "kkggssskkkkkkkkkksssggkk", "kkggsskkkkkkkkkkkkssggkk",
		"kkggsskkkkkkkkkkkkssggkk", "kkggsskkkkkkkkkkkkssggkk", "kkggsskkkkkkkkkkkkssggkk", "kkggsskkkkkkkkkkkkssggkk",
		"kkggsskkkkkkkkkkkkssggkk", "kkggsskkkkkkkkkkkkssggkk", "kkggsskkkkkkkkkkkkssggkk", "kkggsskkkkkkkkkkkkssggkk",
		"kkggsskkkkkkkkkkkkssggkk", "kkkgskkkkkkkkkkkkkksgkkk", "kkkkkkkkkkkkkkkkkkkkkkkk", ".kkkkkkkkkkkkkkkkkkkkkk.",
		"........................", "........................", "........................", "........................",
	],
	&"close": [
		".kk..................kk.", "kkkkk..............kkkkk", "kkwwk..............kwwkk", ".kwwwkk..........kkwwwk.",
		".kkwwwk..........kwwwkk.", "...kwwwkk......kkwwwk...", "...kkwwwk......kwwwkk...", ".....kwwwkk..kkwwwk.....",
		".....kkwwwkkkkwwwkk.....", ".......kwwwkkwwwk.......", ".......kkwkwwkwkk.......", "........kkwwwwkk........",
		"........kkwwwwkk........", ".......kkwkwwkwkk.......", ".......kwwwkkwwwk.......", ".....kkwwwkkkkwwwkk.....",
		".....kwwwkk..kkwwwk.....", "...kkwwwk......kwwwkk...", "...kwwwkk......kkwwwk...", ".kkwwwk..........kwwwkk.",
		".kwwwkk..........kkwwwk.", "kkwwk..............kwwkk", "kkkkk..............kkkkk", ".kk..................kk.",
	],
	&"star": [
		"...........kk...........", ".........kkkkkk.........", ".........kkyykk.........", "........kkyyyykk........",
		"........kkyyyykk........", ".......kkkyyyykkk.......", ".kkkkkkkkkyyyykkkkkkkkk.", "kkkkkkkkkyyyyyykkkkkkkkk",
		"kkyyyyyyyyyyyyyyyyyyyykk", ".kyyyyyyyyyyyyyyyyyyyyk.", ".kkyyyyyyyyyyyyyyyyyykk.", "...kkyyyyyyyyyyyyyykk...",
		"...kkyyyyyyyyyyyyyykk...", "....kkyyyyyyyyyyyykk....", "....kkyyyyyyyyyyyykk....", "...kkyyyyyyyyyyyyyykk...",
		"...kkyyyyyykkyyyyyykk...", "..kkyyyyykkkkkkyyyyykk..", "..kkyyyyykkk..kyyyyykk..", ".kkykyyykkk....kyyykykk.",
		".kyyyk............kyyyk.", "kkyyk..............kyykk", "kkkkk..............kkkkk", ".kk..................kk.",
	],
	&"locate": [
		"...........ww...........", "..........wwww..........", ".........kwwwwk.........", ".......kkwwwwwwkk.......",
		".....kkkwwwwwwwwkkk.....", "...kkkkwwwwwwwwwwkkkk...", "...kkwwwwk....kwwwwkk...", "..kkwwwwk......kwwwwkk..",
		"..kkwwwkk......kkwwwkk..", "..kwwwkk........kkwwwk..", ".wwwwwkk...ww...kkwwwww.", "wwwwwwkk..wwww..kkwwwwww",
		"wwwwwwkk..wwww..kkwwwwww", ".wwwwwkk...ww...kkwwwww.", "..kwwwkk........kkwwwk..", "..kkwwwkk......kkwwwkk..",
		"..kkwwwwk......kwwwwkk..", "...kkwwwwk....kwwwwkk...", "...kkkkwwwwwwwwwwkkkk...", ".....kkkwwwwwwwwkkk.....",
		".......kkwwwwwwkk.......", ".........kwwwwk.........", "..........wwww..........", "...........ww...........",
	],
	&"target": [
		".........kkkkkk.........", ".......kkkkkkkkkk.......", ".....kkkkwwwwwwkkkk.....", "...kkkkwwwwwwwwwwkkkk...",
		"...kkwwwwwwkkwwwwwwkk...", "..kkwwwwwwkkkkwwwwwwkk..", "..kkwwwwwwkkkkwwwwwwkk..", ".kkwwwwwwwkkkkwwwwwwwkk.",
		".kwwwwwwwwkkkkwwwwwwwwk.", "kkwwwwwwwkwkkwkwwwwwwwkk", "kkkkkkkkkwkwwkwkkkkkkkkk", "kkkkkkkkkkwwwwkkkkkkkkkk",
		"kkkkkkkkkkwwwwkkkkkkkkkk", "kkkkkkkkkwkwwkwkkkkkkkkk", "kkwwwwwwwkwkkwkwwwwwwwkk", ".kwwwwwwwwkkkkwwwwwwwwk.",
		".kkwwwwwwwkkkkwwwwwwwkk.", "..kkwwwwwwkkkkwwwwwwkk..", "..kkwwwwwwkkkkwwwwwwkk..", "...kkwwwwwwkkwwwwwwkk...",
		"...kkkkwwwwwwwwwwkkkk...", ".....kkkkwwwwwwkkkk.....", ".......kkkkkkkkkk.......", ".........kkkkkk.........",
	],
	&"dungeon": [
		"...................kk...", ".................kkkkk..", ".................ksskk..", "...............kksssk...",
		"...............kssskk...", ".............kksssk.....", ".............kssskk.....", "...........kksssk.......",
		"..kk.......kssskk.......", "..kkk....kksssk.........", "..kkk....kssskk.........", "...kkk..ksssk...........",
		"...kkkkkssskk...........", ".....kkksskk............", "......kkyykk............", "......kyyyykk...........",
		".....kyykkyyk...........", "...kkkyykkyyykk.........", "...kbbkk..kyyykk........", ".kkbbbk....kyykk........",
		".kbbbkk.................", "kkbbk...................", "kkkkk...................", ".kk.....................",
	],
	&"gear": [
		".........kkkkkk.........", "........kkkkkkkk........", "...kk...kkksskkk...kk...", "..kkkk..kksssskk..kkkk..",
		"..kksskkkggggggkkksskk..", "...ksskggggggggggkssk...", "....kkkggggggggggkkk....", "....kggggggggggggggk....",
		".kkkkggggkkkkkkggggkkkk.", "kkkkggggkkkkkkkkgggggkkk", "kkksggggkkk..kkkgggggkkk", "kkssggggkk....kkggggggkk",
		"kkssggggkk....kkggggggkk", "kkksggggkkk..kkkgggggkkk", "kkkkggggkkkkkkkkgggggkkk", ".kkkkggggkkkkkkggggkkkk.",
		"....kkggggggggggggkk....", "....kkkggggggggggkkk....", "...kggkkggggggggkkggk...", "..kkggkkkggggggkkkggkk..",
		"..kkkk..kggggggk..kkkk..", "...kk...kkkggkkk...kk...", "........kkkkkkkk........", ".........kkkkkk.........",
	],
}

static var _cache: Dictionary = {}


## The icon as a texture, enlarged `scale` times with hard pixels.
static func texture(icon: StringName, scale: int = 2) -> Texture2D:
	var key := "%s@%d" % [icon, scale]
	if _cache.has(key):
		return _cache[key]
	var result := build(BITMAPS.get(icon, BITMAPS[&"coin"]), PALETTE, scale)
	_cache[key] = result
	return result


## A TEXELS×TEXELS bitmap as a texture that lays out at SIZE × scale px (full-resolution image,
## size override). Shared with ItemIcons.
static func build(rows: Array, palette: Dictionary, scale: int) -> ImageTexture:
	var image := Image.create(TEXELS, TEXELS, false, Image.FORMAT_RGBA8)
	for y in mini(rows.size(), TEXELS):
		var row: String = rows[y]
		for x in mini(row.length(), TEXELS):
			var code := row[x]
			if code != "." and palette.has(code):
				image.set_pixel(x, y, palette[code])
	var result := ImageTexture.create_from_image(image)
	result.set_size_override(Vector2i(SIZE, SIZE) * maxi(scale, 1))
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
