class_name MonsterBodies
extends RefCounted
## Pixel bodies of the monsters (ENEMY_DESIGN.md): text bitmaps composed into textures like
## ChibiBody. Each body lists its frames and how it faces: VIEWS_ALL (front / back with the face
## cleared / side = front mirrored for left), VIEWS_SIDE (drawn side-on, mirrored for left) or
## VIEWS_FRONT (one view). Bodies with one frame get a second walk frame generated (body bob,
## near leg lifted from "leg_row"); bodies with "idle_fps" animate while standing too. Dead
## bodies lie on their side. Origin = feet, bottom centre.
## Bodies may name a "glow" point (map pixel) that MonsterVisual lights up (the Forest Guardian's
## core). Symbols: o outline · g G h goblin skin (base, dark, light) · y goblin eyes · b B loincloth
## · w W bone (light, shade) · r skeleton eyes · f F l wolf fur (base, dark, belly) · e wolf eye ·
## a A m slime (base, dark, shine) · c C d bark (base, dark, light) · s S q stone · M moss ·
## x X core glow (boss).

const PALETTE := {
	"o": Color("16161c"), "g": Color("7fb04a"), "G": Color("4f7a2c"), "h": Color("a3cf63"), "y": Color("ffe14a"),
	"k": Color("2a1c10"), "b": Color("8a5a30"), "B": Color("5a3a1c"), "w": Color("eee8d8"), "W": Color("b8b0a0"),
	"r": Color("ff5a3c"), "s": Color("8a8f98"), "t": Color("c9b56a"), "n": Color("3a2a1a"),
	"f": Color("6f7782"), "F": Color("4a505a"), "l": Color("aab1ba"), "e": Color("ffd23f"),
	"a": Color("5fcf6a"), "A": Color("3a9a48"), "m": Color("9fe8a0"), "M": Color("4f8a3a"),
	"c": Color("5a4a3a"), "C": Color("3a2e24"), "d": Color("7a6650"), "q": Color("9a9d94"), "S": Color("55584f"),
	"x": Color("7dffb0"), "X": Color("2f8a5a"),
}
const VIEWS_ALL := 0
const VIEWS_SIDE := 1
const VIEWS_FRONT := 2

const BODIES := {
	&"goblin": {
		"frames": [
			[
				".....ooooo.....",
				"....oggggggo...",
				"ooo.ogggggggo..",
				"oggoogggggggoo.",
				".ogggggggggggo.",
				"..oggoyggyogo..",
				"..ogggggggggo..",
				"...ogGGwwGGo...",
				"....oGGGGGo....",
				".....ooooo.....",
				"....oggggggo...",
				"...ogbBbBbggo..",
				"..ogobbbbbogo..",
				"..ogoBbBbBogo..",
				"..oo.obbbo.oo..",
				".....ooooo.....",
				".....oggo......",
				"....ogggoggo...",
				"....oGGoGGGo...",
				".....oo.ooo....",
			],
		],
		"leg_row": 15, "views": VIEWS_ALL, "back_fill": {"y": "g", "w": "G"},
	},
	&"skeleton": {
		"frames": [
			[
				"....ooooooo....",
				"...owwwwwwwo...",
				"..owwwwwwwwwo..",
				"..owworwworwo..",
				"..owwooWooowo..",
				"...owwwWwwwo...",
				"...oWowowoWo...",
				"....ooooooo....",
				".....oWWWo.....",
				"...oooWWWooo...",
				"..oWwoWwWoWwo..",
				"..oWooWwWooWo..",
				"..oWwoWwWoWwo..",
				"..oWooWWWooWo..",
				"..oWwo.W.oWwo..",
				"..oo.oWWWo.oo..",
				".....oWWWo.....",
				"....oWwoWwo....",
				"....oWwoWwo....",
				"....oWWoWWo....",
				".....oo.oo.....",
			],
		],
		"leg_row": 16, "views": VIEWS_ALL, "back_fill": {"r": "W"},
	},
	&"wolf": {
		"frames": [
			[
				"..........o..............",
				".........ofo.........oo..",
				"........offoooooooooffo..",
				".......offffffffffffffo..",
				"......offfffffffffffffo..",
				".oooooffffffffffffffFo...",
				"ofeoffffffffffffffffFo...",
				"offfoFfffffffffffffFo....",
				".oowwofllllllllllFFo.....",
				"...oooFFoFFooFFoFFo......",
				"......oFoFFo.oFoFFo......",
				"......oFooFo.oFooFo......",
				"......oooooo.oooooo......",
			],
		],
		"leg_row": 9, "views": VIEWS_SIDE,
	},
	&"slime": {
		"frames": [
			[
				"....ooooo....",
				"..ooaaaaaoo..",
				".oamaaaaaaao.",
				"oaaaaaaaaaaao",
				"oaaoaaaaaoaao",
				"oaaaaaaaaaaao",
				"oAaaaaaaaaaAo",
				"oAAaaaaaaaAAo",
				".oAAAAAAAAAo.",
				"..ooooooooo..",
			],
			[
				".............",
				"....ooooo....",
				"..ooaaaaaoo..",
				".oamaaaaaaao.",
				"oaaoaaaaaoaao",
				"oaaaaaaaaaaao",
				"oAAaaaaaaaAAo",
				"oAAAAAAAAAAAo",
				".ooooooooooo.",
				".............",
			],
		],
		"views": VIEWS_FRONT, "idle_fps": 2.0,
	},
	&"forest_guardian": {
		"frames": [
			[
				"......oo..............oo......",
				".....oddo............oddo.....",
				"....odcco....oooo....occdo....",
				"....occo....occcco....occo....",
				".....oco...occccccco..oco.....",
				".....oco..occccccccco.oco.....",
				".....ococccxccccccxcccco......",
				"......occcccoccccoccccco......",
				"......occccccccccccccco.......",
				".......oCCCCCCCCCCCCCo........",
				"....ooooccccccccccccccoooo....",
				"...occccccccccccccccccccccco..",
				"..occcsssscccccccccccssssccco.",
				"..ocssqqsscccccccccccsqqssco..",
				".occssqssSccccxxxccccsqsssSco.",
				".occsssSScccccxXxccccsssSScco.",
				".ocCccccccccccxxxccccccccccCo.",
				".ocCcccccccccccccccccccccccCo.",
				"oddcccMMcccccccccccccccMMcccdo",
				"odccccMMccccccccccccccccMMccdo",
				"oddccccccccccccccccccccccccddo",
				".ooccccsssccccccccccccsssccoo.",
				".ossccsqqsscccccccccccsqqsssso",
				"osqsccsssSccccccccccccssSsqqso",
				"osqqsccccccccCCCCCcccccccsqqso",
				"ossSsoccccccCCCCCCCcccccosSSso",
				".oSSo.occcccCCCCCCCcccco.oSSo.",
				"..oo..oCccccccccccccccCo..oo..",
				"......oCCcccccccccccccCo......",
				".......oCCcccccccccccCo.......",
				".......oCCCCCCoooCCCCCo.......",
				"......occCCCo.....oCCcco......",
				".....ocMccCo.......oCccMo.....",
				"....occccCCo.......oCCccco....",
				"....oooooooo.......oooooooo...",
			],
		],
		"leg_row": 30, "views": VIEWS_FRONT, "idle_fps": 1.5, "back_fill": {"x": "c", "X": "c"},
		"glow": Vector2(15.0, 15.0), "glow_color": Color("7dffb0"),
	},
}

static var _cache: Dictionary = {}


static func has_body(body: StringName) -> bool:
	return BODIES.has(body)


static func get_config(body: StringName) -> Dictionary:
	return BODIES.get(body, BODIES[&"goblin"])


static func get_width(body: StringName) -> int:
	return String(get_config(body)["frames"][0][0]).length() + 2


static func get_height(body: StringName) -> int:
	return (get_config(body)["frames"][0] as Array).size() + 2


## Frames per second while standing still (0 = static).
static func get_idle_fps(body: StringName) -> float:
	return float(get_config(body).get("idle_fps", 0.0))


## Texture for a body, view (ChibiBody.View), frame (0 / 1), mirrored (facing left), lying.
static func get_texture(body: StringName, view: ChibiBody.View, frame: int, mirrored: bool, lying: bool) -> ImageTexture:
	var config := get_config(body)
	var views: int = config["views"]
	if views != VIEWS_ALL:
		view = ChibiBody.View.FRONT
	if views == VIEWS_FRONT:
		mirrored = false
	var key := "%s|%d|%d|%s|%s" % [body, view, frame, mirrored, lying]
	if _cache.has(key):
		return _cache[key]
	var image := compose(body, view, frame, lying)
	if mirrored:
		image.flip_x()
	var texture := ImageTexture.create_from_image(image)
	_cache[key] = texture
	return texture


static func compose(body: StringName, view: ChibiBody.View, frame: int, lying: bool) -> Image:
	var config := get_config(body)
	var frames: Array = config["frames"]
	var generated := frames.size() == 1 and frame == 1
	var rows: Array = frames[mini(frame, frames.size() - 1)]
	var width := String(rows[0]).length()
	var height := rows.size()
	var canvas := Image.create(width + 2, height + 2, false, Image.FORMAT_RGBA8)
	var fill: Dictionary = config.get("back_fill", {}) if view == ChibiBody.View.BACK else {}
	var leg_row: int = config.get("leg_row", height - 4)
	for y in height:
		var row: String = rows[y]
		for x in width:
			var symbol := row[x]
			if symbol == ".":
				continue
			if fill.has(symbol):
				symbol = fill[symbol]
			var at := Vector2i(x + 1, y + 2)
			if generated:
				# Step: body bobs up, the near leg lifts.
				if y < leg_row or x < width / 2:
					at.y -= 1
			if at.x >= 0 and at.x < canvas.get_width() and at.y >= 0 and at.y < canvas.get_height():
				canvas.set_pixel(at.x, at.y, PALETTE[symbol])
	if not lying:
		return canvas
	# Lying on the ground: the standing pose on its side, in a wide canvas.
	canvas.rotate_90(CLOCKWISE)
	var used := canvas.get_used_rect()
	var result := Image.create(height + 4, width + 4, false, Image.FORMAT_RGBA8)
	result.blit_rect(canvas, used, Vector2i((result.get_width() - used.size.x) / 2, result.get_height() - used.size.y - 1))
	return result
