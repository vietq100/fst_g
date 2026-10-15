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
## · j w W bone (skull light, light, shade) · r skeleton eyes · f F l wolf fur (base, dark, belly) · e wolf eye ·
## a A m slime (base, dark, shine) · c C d bark (base, dark, light) · s S q stone · M moss ·
## x X core glow (boss).

const PALETTE := {
	"o": Color("16161c"), "g": Color("7fb04a"), "G": Color("4f7a2c"), "h": Color("a3cf63"), "y": Color("ffe14a"),
	"k": Color("2a1c10"), "b": Color("8a5a30"), "B": Color("5a3a1c"), "w": Color("eee8d8"), "W": Color("b8b0a0"),
	"r": Color("ff5a3c"), "s": Color("8a8f98"), "t": Color("c9b56a"), "n": Color("3a2a1a"),
	"f": Color("6f7782"), "F": Color("4a505a"), "l": Color("aab1ba"), "e": Color("ffd23f"),
	"a": Color("5fcf6a"), "A": Color("3a9a48"), "m": Color("9fe8a0"), "M": Color("4f8a3a"),
	"c": Color("5a4a3a"), "C": Color("3a2e24"), "d": Color("7a6650"), "q": Color("9a9d94"), "S": Color("55584f"),
	"x": Color("7dffb0"), "X": Color("2f8a5a"), "j": Color("e8e2d0"),
}
## Texels per world pixel (D56): bodies are drawn at 1 / SCALE in the world.
const SCALE := 2
const VIEWS_ALL := 0
const VIEWS_SIDE := 1
const VIEWS_FRONT := 2

const BODIES := {
	&"goblin": {
		"frames": [
			[
				"...........oooooooooooo...........",
				".........oooggggggggggooo.........",
				".........ohhgggggggggghho.........",
				"........oohgggggggggggghoo........",
				".oo.....oggggggggggggggggo.....oo.",
				"oooo...oooggggggggggggggooo...oooo",
				"ooggggooooggggggggggggggoooogggooo",
				".ogggggooggggggggggggggggooggggggo",
				".oogggggggggggggggggggggggggggggoo",
				"...oggggggggggggggggggggggggggggo.",
				"...ooggggggGooyyGGGGyyooGggggo....",
				"....ogggggGGGoyGGGGGGyoGGGgggo....",
				"....ooggggGGGGGGGGGGGGGGGGggoo....",
				".....ogggGGGGGGGGGGGGGGGGGggo.....",
				".....oooGGGGGGGwwwwGGGGGGGooo.....",
				".......oGGGGGGwwwwwwGGGGGGo.......",
				".......ooGGGGGwwGGwwGGGGGoo.......",
				".........ooGGGwwGGwwGGGoo.........",
				"..........oGooooooooooGo..........",
				"..........ogoooooooooogo..........",
				".........oggbbBBBBBBbbggo.........",
				".......oogggbBbBBBBbBbgggoo.......",
				".......ogggoBBbbBBbbBBogggo.......",
				".....oogggooBBbbBBbbBBooggooo.....",
				".....ogggGoobbbbbbbbbbooggGGo.....",
				"....ooggGGoobbbbbbbbbboogGgGoo....",
				"....ogggGGGBBbbbBBbbbBBGGggggo....",
				"....oggGGooooBbbBBbbBooooGgggo....",
				"....oGGGGo..obbbbbbbbo..oGGGGo....",
				"....oGGGo...ooobbbbooo...oGGGo....",
				"....ooooo...oooooooooo...ooooo....",
				".....oo.....ooooooooo......oo.....",
				"............ogoggoooo.............",
				"...........ooggggggo..............",
				"...........oggggggooggggo.........",
				"..........oogggggoooggggoo........",
				"..........ooGGGGGGGGGGGGoo........",
				"...........oGGGoooGGGGGGo.........",
				"...........ooooo..ooGGooo.........",
				".............oo....oooo...........",
			],
		],
		"leg_row": 32, "views": VIEWS_ALL, "back_fill": {"y": "g", "w": "G"},
	},
	&"skeleton": {
		"frames": [
			[
				".........oooooooooooo.........",
				".......ooojjjjjjjjjjooo.......",
				".......ojjjjjjjjjjjjjjo.......",
				".....oojjjjjjjjjjjjjjjjoo.....",
				".....ojjjjjjjjjjWWjjjjjjo.....",
				"....oojjjjjjjjjjWWjjjjjjjoo...",
				"....ojjjjwrjjjjjjjjjjrwjjjo...",
				"....ojjjwwrrjjjjjjjjrrwwjjoo..",
				"....oojjoorrjjjjWWjjrroojjoo..",
				".....ojjjorjjjjWWWjjjrojjjo...",
				".....oojojjjjjjWWWjjjjjjjoo...",
				"......ojjjjjjWWWWWjjjjjjjo....",
				"......ooWWooWWooWWooWWojoW....",
				".......oWWooWWooWWooWWooW.....",
				".......oooooooooooooooo.......",
				".........oooooooooooo.........",
				"..........oooWjjWooo..........",
				"..........oWWWjjWWWo..........",
				".......oooooWWjjWWooooo.......",
				".....ooojjooWWjjjWooWWooo.....",
				".....oWWjjooWWjjjjooWWjjo.....",
				"....ooWWjjooWWjjjjooWWWjoo....",
				"....oWWWooooWWjjjjooooWWWo....",
				"....oWWWooooWWjjjjooooWWWo....",
				"....oWWWjjooWWjjjjooWWjjjo....",
				"....oWWWjjooWWjjjjooWWjjjo....",
				"....oWWWooooWWjjjWooooWWWo....",
				"....oWWWooooWWjjWWooooWWWo....",
				"....oWWWjooo..WW..oooWWjjo....",
				"....oooWjjoo..WW..ooWWjooo....",
				"....oooo..ooWWjjWWoo..oooo....",
				".....oo...oWWWjjWWWo...oo.....",
				"..........oWWWWWWWWo..........",
				".........ooWWWWWWWooo.........",
				".........oWWWjoWWWjjo.........",
				"........ooWWjjooWWjjoo........",
				"........oWWWjjooWWjjjo........",
				"........oWWWWjooWWWjjo........",
				"........ooWWWWWWWWWWoo........",
				".........oWWWooooWWWo.........",
				".........ooooo..ooooo.........",
				"...........oo....oo...........",
			],
		],
		"leg_row": 34, "views": VIEWS_ALL, "back_fill": {"r": "j", "w": "j"},
	},
	&"wolf": {
		"frames": [
			[
				"....................oo............................",
				"...................oooo...........................",
				"...................offo....................oo.....",
				".................oofffooo.................oooo....",
				".................offffoooooooooooooooooofflooo....",
				"...............ooffffffooffffffffffffffffffllo....",
				"...............offfffffffffffffffffffffffffffo....",
				".............ooffffffffffffffffffffffffffffffo....",
				".............offfffffllllllllllllllffffffffffo....",
				"...........oofffffflllllllllllllllllfffffffffo....",
				"...oooooooooffffffflllllllllllllllllfffffffFoo....",
				".oooeooofffffffffllllllllllllllllllffffffFFFo.....",
				".offeooofffffffflllllllllllllllllllffffffFFoo.....",
				"ooffeeoffffffffflllllllllllllllllffffffFFFo.......",
				"ooffFFfofoFffffffffffffffffffffffffffFFFFoo.......",
				".offFFffoooFffffffffffffffffffffffffFFFFFo........",
				".oooFowwwwooffflllllllllllllllllllllFFFFoo........",
				"...ooowwwwoofflllllllllllllllllllllFFFFFo.........",
				".....ooowwooFFFFooFFFFoolFFFFFooFFFFFo............",
				".......ooooooFFFooFFFFoooooFFFooFFFFFo............",
				"...........ooFFFooFFFFFo..oFFFooFFFFFo............",
				"............oFFFoooFFFFo..oFFFoooFFFFo............",
				"............oFFFoooFFFFo..oFFFoooFFFFo............",
				"............oFFFooooFFFo..oFFFooooFFFo............",
				"............ooFFooooFFoo..ooFFooooFFoo............",
				".............oooooooooo....oooooooooo.............",
			],
		],
		"leg_row": 18, "views": VIEWS_SIDE,
	},
	&"slime": {
		"frames": [
			[
				".........oooooooo.........",
				".......oooaaaaaaooo.......",
				".....oooaaaaaaaaaaooo.....",
				"...ooomoaaaaaaaaaaaaooo...",
				"...oaammmmaaaaaaaaaaaao...",
				".ooaamammmaaaaaaaaaaaaaoo.",
				".oaammmaaaaaaaaaaaaaaaaao.",
				"ooaammaaaaaaaaaaaaaaaaaaoo",
				"oaaaaaooaaaaaaaaaaooaaaaao",
				"oaaaaaooaaaaaaaaaaooaaaaao",
				"oaaaaaaaaaaaaaaaaaaaaaaaao",
				"oaaaaaaaaaaaaaaaaaaaaaaaao",
				"oAAaaaaaaaAAaaaaaaaaaaaAAo",
				"oAAAAaaaaaAAaaaaaaaaaAAAAo",
				"ooAAAaaaaaaaaaaaaaaaaAAAoo",
				".oAAAAAaaaaaaaaaaaaAAAAAo.",
				".ooAAAAAAAAAAAAAAAAAAAAoo.",
				"...oAAAAAAAAAAAAAAAAAAo...",
				"...oooAAAAAAAAAAAAAAooo...",
				".....oooooooooooooooo.....",
			],
			[
				"..........................",
				"..........................",
				".........oooooooo.........",
				".......oooaaaaaaooo.......",
				".....oooaaaaaaaaaaooo.....",
				"...ooomoaaaaaaaaaaaaooo...",
				"...oaammaaaaaaaaaaaaaao...",
				".ooaaammaaaaaaaaaaaaaaaoo.",
				".oaaaaooaaaaaaaaaaooaaaao.",
				"ooaaaaooaaaaaaaaaaooaaaaoo",
				"oaaaaaaaaaaaaaaaaaaaaaaaao",
				"oaaaaaaaaaaaaaaaaaaaaaaaao",
				"oAAAAaaaaaaaaaaaaaaaaAAAAo",
				"oAAAAAAaaaaaaaaaaaaAAAAAAo",
				"ooAAAAAAAAAAAAAAAAAAAAAAoo",
				".oAAAAAAAAAAAAAAAAAAAAAAo.",
				".oooAAAAAAAAAAAAAAAAAAooo.",
				"...oooooooooooooooooooo...",
				"..........................",
				"..........................",
			],
		],
		"views": VIEWS_FRONT, "idle_fps": 2.0,
	},
	&"forest_guardian": {
		"frames": [
			[
				".............oo..............................oo.............",
				"...........oooooo..........................oooooo...........",
				"...........oddddo..........................oddddo...........",
				".........oodddddoo........................oodddddoo.........",
				".........odddcccoo.........oooooo.........oocccdddo.........",
				"........oodccccco........oooccccooo........occcccdoo........",
				"........oocccccoo........occcccccco........oocccccoo........",
				".........occccco.......oocccccccccco........occccco.........",
				".........oocccco.......occcccccccccccco.....occccoo.........",
				"..........occcco.....ooccccccccccccccccoo...occcco..........",
				"..........occcco.....occcccccccccccccccco...occcoo..........",
				"..........occcco....occcccccccccccccccccco..occco...........",
				"..........ooccooccccccxxccccccccccccxxcccccccocoo...........",
				"...........occooccccccxxccccccccccccxxccccccccco............",
				"...........oococccccccccooccccccccooccccccccccoo............",
				"............occcccccccccooccccccccoocccccccccco.............",
				"............oocccccccccccccccccccccccccccccccoo.............",
				".............ooccccccccccccccccccccccccccccoo...............",
				"..............oCCCCCCCCCCCCCCCCCCCCCCCCCCCCo................",
				"..............oCCCCCCCCCCCCCCCCCCCCCCCCCCCCo................",
				".........ooooooocccccccccccccccccccccccccccoooooooo.........",
				".......oooccccocccccccccccccccccccccccccccccccccccoo........",
				".......occcccccccccccccccccccccccccccccccccccccccccccco.....",
				".....ooccccccccccccccccccccccccccccccccccccccccccccccccoo...",
				".....occcccccssssssccccccccccccccccccccccccsssssscccccccoo..",
				"....oocccccsssssssssccccccccccccccccccccccssssssssscccccoo..",
				"....occccssssqqqssssccccccccccccccccccccccsssqqqssscccco....",
				"...oocccssssqqqqssssccccccccccccccccccccccssqqqqssssccco....",
				"...occccssssqqqssssScccccccccxxxxcccccccccssqqqsssssSScoo...",
				"..ooccccssssqqsssSScccccccccxxxxxxccccccccssqqsssssSSSccoo..",
				"..occcccsssssssSSSScccccccccxxXXxxccccccccsssssssSSSScccco..",
				"..occccccsssssSSScccccccccccxxXXxxcccccccccsssssSSScccccco..",
				"..occcCCccccccccccccccccccccxxxxxxcccccccccccccccccccccCCo..",
				"..occcCCcccccccccccccccccccccxxxxcccccccccccccccccccccCCCo..",
				"..occcCCccccccccccccccccccccccccccccccccccccccccccccccCCCo..",
				".oooccCCcccccccccccccccccccccccccccccccccccccccccccccccCooo.",
				".oddddcccccccMMcccccccccccccccccccccccccccccccMMMcccccccddo.",
				"ooddddccccccMMMMccccccccccccccccccccccccccccccMMMMMcccccddoo",
				"odddccccccccMMMMcccccccccccccccccccccccccccccccMMMMMccccdddo",
				"odddcccccccccMMccccccccccccccccccccccccccccccccccMMMcccddddo",
				"oodddccccccccccccccccccccccccccccccccccccccccccccccccccdddoo",
				".oddddccccccccccccccccccccccccccccccccccccccccccccccccdddoo.",
				".ooooocccccccccssssccccccccccccccccccccccccccsssscccccoodo..",
				"..oooocccccccsssssssscccccccccccccccccccccccssssssscccooso..",
				"..osossccccccsqqqqssssccccccccccccccccccccccssqqqssssssssoo.",
				".oosssssccccssqqqqssssccccccccccccccccccccccssqqqqssssssssoo",
				".ossqqssccccsssssssSccccccccccccccccccccccccssssSSsssqqsssso",
				"oossqqqssccccsssssSccccccccccccccccccccccccccsssSSssqqqqssso",
				"osssqqqssccccccccccccccccccCCCCCCCCcccccccccccccccssqqqqssso",
				"ossssqqqsscccccccccccccccCCCCCCCCCCCCcccccccccccccssqqqqssso",
				"oossssSSsscccccccccccccccCCCCCCCCCCCCcccccccccccccssSSSSssoo",
				".osssSSSsoooocccccccccccCCCCCCCCCCCCCCcccccccccoooosSSSSsso.",
				".oooSSSSoo..occcccccccccCCCCCCCCCCCCCCccccccccco..ooSSSSooo.",
				"...oSSSSo...occccccccccccCCCCCCCCCCCCcccccccccco...oSSSSo...",
				"...oooooo...oCCccccccccccccccccccccccccccccccCCo...oooooo...",
				".....oo.....oCCCCcccccccccccccccccccccccccccCCCo.....oo.....",
				"............ooCCCcccccccccccccccccccccccccccCCoo............",
				".............oCCCCCccccccccccccccccccccccccCCCo.............",
				".............ooCCCCccccccccccccccccccccccccCCoo.............",
				"..............oCCCCCCccccccccccccccccccccCCCCo..............",
				"..............oCCCCCCCCCCCCCCccccCCCCCCCCCCCCo..............",
				".............oooCCCCCCCCCCCCooooooCCCCCCCCCCooo.............",
				".............occcCCCCCCCCo..........oCCCCCCccco.............",
				"...........ooccccccCCCCCo............oCCCCccccooo...........",
				"...........occMMccccCCCoo............ooCCCccccMMo...........",
				".........oocccMMccccCCCo..............oCCCCccccMooo.........",
				".........occcccccccCCCCo..............oCCCCccccccco.........",
				"........ooccccccccCCCooo..............oooCCCccccccooo.......",
				"........ooccccccccCCCooo..............oooCCCccccccoooo......",
				".........oooooooooooooo................ooooooooooooooo......",
			],
		],
		"leg_row": 60, "views": VIEWS_FRONT, "idle_fps": 1.5, "back_fill": {"x": "c", "X": "c"},
		"glow": Vector2(31.0, 31.0), "glow_color": Color("7dffb0"),
	},
}

static var _cache: Dictionary = {}


static func has_body(body: StringName) -> bool:
	return BODIES.has(body)


static func get_config(body: StringName) -> Dictionary:
	return BODIES.get(body, BODIES[&"goblin"])


## Texture size in texels (map plus padding).
static func get_width(body: StringName) -> int:
	return String(get_config(body)["frames"][0][0]).length() + 2 * SCALE


static func get_height(body: StringName) -> int:
	return (get_config(body)["frames"][0] as Array).size() + 2 * SCALE


## Size in world pixels.
static func get_world_size(body: StringName) -> Vector2:
	return Vector2(get_width(body), get_height(body)) / SCALE


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
	var canvas := Image.create(width + 2 * SCALE, height + 2 * SCALE, false, Image.FORMAT_RGBA8)
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
			var at := Vector2i(x + SCALE, y + 2 * SCALE)
			if generated:
				# Step: body bobs up, the near leg lifts (one world pixel).
				if y < leg_row or x < width / 2:
					at.y -= SCALE
			if at.x >= 0 and at.x < canvas.get_width() and at.y >= 0 and at.y < canvas.get_height():
				canvas.set_pixel(at.x, at.y, PALETTE[symbol])
	if not lying:
		return canvas
	# Lying on the ground: the standing pose on its side, in a wide canvas.
	canvas.rotate_90(CLOCKWISE)
	var used := canvas.get_used_rect()
	var result := Image.create(height + 4 * SCALE, width + 4 * SCALE, false, Image.FORMAT_RGBA8)
	result.blit_rect(canvas, used, Vector2i((result.get_width() - used.size.x) / 2, result.get_height() - used.size.y - 1))
	return result
