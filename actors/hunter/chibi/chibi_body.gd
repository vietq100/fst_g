class_name ChibiBody
extends RefCounted
## The chibi Hunter body (D49): a 15×29 px base figure (bald, white tank top, shorts) traced from
## the owner's reference, placed on a 32×48 canvas with room above for hair, hats, jumps and
## weapons. The body is split into six parts (head, torso, two arms, two legs) that animation
## frames move by whole pixels (ChibiAnimations), so the art stays crisp.
## Facings: front (down), back (up) and side (right; left is the mirrored image).
## Layers: skin tone, dye (trousers), hair style and hair colour come from HunterAppearance; the
## outfit (torso, arms, legs rows) follows the Hunter's base class (OUTFITS, `outfit_for`).
## Hair is drawn over the head part and moves with it; back and side views are derived from the
## front hair map (`hair_map`).

const CANVAS := Vector2i(32, 48)
## Top-left of the body map on the canvas in the rest pose.
const BODY_ORIGIN := Vector2i(8, 19)
## The actor's feet (node origin) on the canvas.
const FEET := Vector2i(16, 48)
const BODY_SIZE := Vector2i(15, 29)

enum View { FRONT, BACK, SIDE }

## Traced reference, front view. Symbols:
## o outline · h s m d n skin (light → dark) · r eye lid · w eye white · i iris (hair colour)
## W c g b p tank top (white → dark) · k K shorts (dye, dye dark) · . transparent
## Outfits add: y Y gold trim · e E leather · t T u metal (base, dark, shine) · f F boots
const BODY := [
	"....ooooooo....",
	"...ossssssso...",
	"..ossssssssso..",
	".ossssssssssso.",
	".ossssssssssho.",
	".omsssssssssmo.",
	".ommsssssssmmo.",
	".odmsssssssmdo.",
	"ossmoosssoomsso",
	"ossswosssowmsso",
	".omsirsssrismo.",
	"..nssssssshsn..",
	"...omsssssmn...",
	"...onnnnnnno...",
	"..omgcssscgmo..",
	"..nscWWWWWcsn..",
	".nsmWWWWWWWmsn.",
	".nsgWWWWWWWgsn.",
	"omsbWWWWWWWbsmo",
	"osbccWWWWWccbso",
	".opggcccccggpo.",
	"..pcccccccccp..",
	"..oopWWWWWpoo..",
	"..omKkkkkkKmo..",
	"..omsso.ossmo..",
	"...ommo.ommo...",
	"...ommo.ommo...",
	"...osso.osso...",
	"...oooo.oooo...",
]

## Part rectangles in the body map. Draw order (back to front) is PART_ORDER.
const PARTS := {
	&"head": Rect2i(0, 0, 15, 13),
	&"torso": Rect2i(3, 13, 9, 11),
	&"arm_l": Rect2i(0, 13, 3, 10),
	&"arm_r": Rect2i(12, 13, 3, 10),
	&"leg_l": Rect2i(0, 24, 8, 5),
	&"leg_r": Rect2i(8, 24, 7, 5),
}
const PART_ORDER: Array[StringName] = [&"arm_l", &"leg_l", &"leg_r", &"torso", &"arm_r", &"head"]
## Weapon hand (bottom of the right arm) in the body map.
const HAND := Vector2i(13, 20)
## Eye blocks (front view): left eye, right eye, rows 8–10, 2 px wide.
const EYE_ROWS := Vector2i(8, 10)
const EYE_LEFT_COL := 4
const EYE_RIGHT_COL := 9
## Side view: eyes slide toward the facing side by these amounts.
const SIDE_EYE_SHIFT := Vector2i(2, 1)
## First body-map row replaced by an outfit (neck); outfits cover rows 13–28.
const TORSO_ROW := 13
## Hair maps start this many rows above the head's top row.
const HAIR_TOP := -3
## Portrait crop relative to BODY_ORIGIN: hair, face and shoulders.
const PORTRAIT_RECT := Rect2i(-1, -4, 17, 19)

const OUTLINE := Color("3d1505")
const EYE_LID := Color("a64c40")
const EYE_WHITE := Color("eddad4")
const CLOTH: Array[Color] = [Color("fff6ec"), Color("e2e0d6"), Color("b5aeb4"), Color("888ca5"), Color("786d62")]
const TRIM := Color("e8c35a")
const TRIM_DARK := Color("a8822e")
const LEATHER := Color("9a6a3e")
const LEATHER_DARK := Color("6e4a2a")
const METAL := Color("b9c2cc")
const METAL_DARK := Color("7d8794")
const METAL_SHINE := Color("e9eef2")
const BOOT := Color("5a3a26")
const BOOT_LIGHT := Color("7a5236")
## Skin ramps [light, base, shadow, deep, darkest] per HunterAppearance.skin.
const SKINS := [
	[Color("ffe0d0"), Color("fbcbb9"), Color("e8977f"), Color("c47c71"), Color("814721")],
	[Color("f6d2a8"), Color("e8b48a"), Color("c98a63"), Color("a5674a"), Color("6e3f22")],
	[Color("d9a47c"), Color("c18560"), Color("9c6243"), Color("7a4a32"), Color("4e2a18")],
	[Color("a87556"), Color("8a5a3e"), Color("6b432c"), Color("52311f"), Color("33190c")],
]

## Outfit rows per base class, replacing body rows TORSO_ROW..28 (cloth ramps in CLOTHS):
## Warrior red tunic + steel pauldrons, Ranger green tunic + quiver strap, Rogue dark tunic +
## dyed scarf, Guardian plate + blue tabard.
const OUTFITS := {
	&"warrior": [
		"...onnnnnnno...",
		".ouutcssscutto.",
		".otTTWWWWWTTTo.",
		".pcgWWWWWWWgcp.",
		".pcgWWWWWWWgcp.",
		"omsbWWWWWWWbsmo",
		"osbccWWWWWccbso",
		".opggcccccggpo.",
		"..pcccccccccp..",
		"..oEeeeyeeeEo..",
		"..oKkkkkkkkKo..",
		"..oKkko.okkKo..",
		"...oFFo.oFFo...",
		"...offo.offo...",
		"...offo.offo...",
		"...oooo.oooo...",
	],
	&"ranger": [
		"...onnnnnnno...",
		"..oEgcssscgEo..",
		".oeEcWWWWWcEeo.",
		".peEWWWeWWWEep.",
		".pcgWWWWeWWgcp.",
		"omEbWWWWWeWbEmo",
		"osEccWWWWWecEso",
		".opggcccccggpo.",
		"..pcccccccccp..",
		"..oEeeeyeeeEo..",
		"..oKkkkkkkkKo..",
		"..oKkko.okkKo..",
		"...oeeo.oeeo...",
		"...oEEo.oEEo...",
		"...ofFo.ofFo...",
		"...oooo.oooo...",
	],
	&"rogue": [
		"...okkkkkkko...",
		"..okKkkkkkKko..",
		".obgKcWWWcKgbo.",
		".pbgWWWWWWWgbp.",
		".pbgWWWWWWWgbp.",
		"omsbWWWWWWWbsmo",
		"osbccWWWWWccbso",
		".opggcgcgcggpo.",
		"..pcgcccccgcp..",
		"..oEeeeyeeeEo..",
		"..obggggggbo...",
		"..obggo.oggbo..",
		"...offo.offo...",
		"...offo.offo...",
		"...oFFo.oFFo...",
		"...oooo.oooo...",
	],
	&"guardian": [
		"...onnnnnnno...",
		".outtTsssTttuo.",
		"otTTTWWcWWTTTTo",
		".oTTtWWcWWtTTo.",
		".pTtTWWcWWTtTp.",
		"omsoTWWcWWTosmo",
		"osbotWWcWWtobso",
		".opTTtWcWtTTpo.",
		"..pTTTWcWTTTp..",
		"..oEeeeyeeeEo..",
		"..oKkkkkkkkKo..",
		"..oKkko.okkKo..",
		"...outo.outo...",
		"...otTo.otTo...",
		"...oTTo.oTTo...",
		"...oooo.oooo...",
	],
}
## Hair styles (HunterAppearance.hair_style): front rows from HAIR_TOP; "back" = last head row
## covered at the back. Short messy, long, ponytail, bob, spiky, bun, side swept, twin tails,
## buzz cut, curly. Symbols: o outline, L H D hair (light → dark).
const HAIR_STYLES := [
	{"back": 9, "rows": [
		"...............",
		".....o..o.o....",
		"...ooLooLoLo...",
		"..oLLLLLLLLLo..",
		".oLLHHHHHHHHHo.",
		".oLHHHHHHHHHHDo",
		"oLHHHHHHHHHHHDo",
		"oHHHHHHHHHHHHDo",
		"oHHDHHDHHHDHHDo",
		"oHDoHDoDHoDHoDo",
		"oDo.o..o..o.oDo",
		".o...........o.",
	]},
	{"back": 12, "rows": [
		"...............",
		"...............",
		"....ooooooo....",
		"...oLLLLHHHHo..",
		"..oLLLHHHHHHDo.",
		".oLLHHHHHHHHHDo",
		".oLHHHHHHHHHHDo",
		"oLHHHHHHHHHHHDo",
		"oHHHHHHHHHHHHDo",
		"oHHDDHHHHHDDHDo",
		"oHDo.......oDDo",
		"oHD.........DHo",
		"oHD.........DHo",
		"oHD.........DHo",
		"oHHD.......DHHo",
		"oHHDo.....oDHHo",
		"oHDDo.....oDDHo",
		"oDDo.......oDDo",
		".oo.........oo.",
	]},
	{"back": 10, "rows": [
		"...........ooo.",
		"..........oLHDo",
		"....ooooooHHDo.",
		"...oLLLLLLHDDo.",
		"..oLLHHHHHHHDo.",
		".oLHHHHHHHHHHDo",
		".oLHHHHHHHHHHDo",
		"oLHHHHHHHHHHHDo",
		"oHHHHHHHHHHHHDo",
		"oHDHHDHHHDHHDDo",
		"oDo.oDo..o.oDDo",
		".o..........oo.",
	]},
	{"back": 11, "rows": [
		"...............",
		"...............",
		"....ooooooo....",
		"...oLLLLLLLo...",
		"..oLLHHHHHHHo..",
		".oLHHHHHHHHHDo.",
		"oLHHHHHHHHHHHDo",
		"oHHHHHHHHHHHHDo",
		"oHHHHHHHHHHHHDo",
		"oHDDDDDDDDDDDDo",
		"oHD.........DHo",
		"oHD.........DHo",
		"oHD.........DHo",
		"oDD.........DDo",
		".oo.........oo.",
	]},
	{"back": 9, "rows": [
		"..o..o...o..o..",
		"..oLooLoLLoLo..",
		".oLLoLLLLLLLDo.",
		"..oLLLLLLLHHo..",
		".oLLHHHHHHHHHo.",
		"oLLHHHHHHHHHHDo",
		".oHHHHHHHHHHDo.",
		"oHHHHHHHHHHHHDo",
		"oHDHHHHDHHHHDDo",
		".oDoHDooDHoDDo.",
		"..o.oo..oo.oo..",
		"...............",
	]},
	{"back": 10, "rows": [
		".....ooooo.....",
		"....oLLHHDo....",
		"....oHHHHDo....",
		"...ooooooooo...",
		"..oLLLLLLHHHo..",
		".oLHHHHHHHHHDo.",
		"oLHHHHHHHHHHHDo",
		"oHHHHHHHHHHHHDo",
		"oHHHHHHHHHHHDDo",
		"oHDDo.....oDDDo",
		"oDo.........oDo",
		".o...........o.",
	]},
	{"back": 10, "rows": [
		"...............",
		"...............",
		"....ooooooo....",
		"...oLLLLLLLoo..",
		"..oLLLLLHHHHHo.",
		".oLHHHHHHHHHHDo",
		"oLHHHHHHHHHHHDo",
		"oHHHHHHHHHHHHDo",
		"oHHHHHHHHHHHDDo",
		"oHHHHHHDDDo.oDo",
		"oHHDDDo.....oDo",
		"oDDo.........o.",
		".oo............",
	]},
	{"back": 10, "rows": [
		"...............",
		"...............",
		"....ooooooo....",
		"...oLLLLLLLo...",
		"..oLLHHHHHHHo..",
		".oLHHHHHHHHHDo.",
		"oLHHHHHHHHHHHDo",
		"oHHHHHHHHHHHHDo",
		"oHHDHHHDHHHDHDo",
		"oHDooHDoDHooDDo",
		"ooo.........ooo",
		"oLHo.......oHDo",
		"oHHo.......oHDo",
		"oHDo.......oHDo",
		"oHDo.......oDDo",
		".oHDo.....oDDo.",
		"..oo.......oo..",
	]},
	{"back": 8, "rows": [
		"...............",
		"...............",
		"....ooooooo....",
		"...oLLLLHHHo...",
		"..oLHHHHHHHDo..",
		".oLHHHHHHHHHDo.",
		".oHHHHHHHHHHDo.",
		".oHHDHHHHDHHDo.",
		".oDo.o...o.oDo.",
		"..o.........o..",
	]},
	{"back": 11, "rows": [
		"....oo.oo.oo...",
		"..ooLLoLLoHHoo.",
		".oLLLLLLHHHHHDo",
		"oLLLHHHHHHHHHDo",
		"oLHHHHHHHHHHHDo",
		"oHHHHHHHHHHHHDo",
		"oHHHHHHHHHHHHDo",
		"oHHDHHHHHHDHHDo",
		"oHDoHDoHDoHDDDo",
		"oHDo.o..o..oDDo",
		"oHD.........DHo",
		"oDDo.......oDDo",
		".oo.........oo.",
	]},
]
## Hair ramps [light, base, dark] (HunterAppearance.hair_color): black, dark brown, chestnut,
## ginger, blonde, platinum, silver, blue, pink, violet. The iris uses the base colour.
const HAIR_COLORS := [
	[Color("4a3f4f"), Color("2b2230"), Color("17121c")],
	[Color("7a5034"), Color("5a3622"), Color("3a2214")],
	[Color("b07a45"), Color("8a5a30"), Color("5f3c1e")],
	[Color("d9603a"), Color("b0432a"), Color("7a2a1c")],
	[Color("f2d27a"), Color("d9ac4a"), Color("a67c2e")],
	[Color("f4ecd8"), Color("d8cdb4"), Color("a99d86")],
	[Color("c9ccd6"), Color("9a9eae"), Color("6a6e80")],
	[Color("6f8fd9"), Color("4a63b0"), Color("2e3d7a")],
	[Color("f29ab8"), Color("d46a8f"), Color("9a4466")],
	[Color("9b6fd0"), Color("7448a8"), Color("4a2c70")],
]
const CLOTHS := {
	&"warrior": [Color("c9533f"), Color("a83f30"), Color("7f2c22"), Color("5c1f18"), Color("3f150f")],
	&"ranger": [Color("7fa04a"), Color("5f8236"), Color("456326"), Color("33491c"), Color("223212")],
	&"rogue": [Color("6a5a86"), Color("52456c"), Color("3c3252"), Color("2a233b"), Color("1b1626")],
	&"guardian": [Color("5b7fbf"), Color("41629e"), Color("2f4a7a"), Color("223658"), Color("16243b")],
}

static var _maps: Dictionary = {}
static var _hair_maps: Dictionary = {}
static var _frames: Dictionary = {}
static var _portraits: Dictionary = {}


## Frame textures of one animation for a look and facing. Left facing is pre-mirrored.
static func get_frames(look: HunterAppearance, facing: Facing.Direction, animation: StringName,
		outfit: StringName = &"") -> Array[ImageTexture]:
	var key := "%s|%s|%d|%s" % [look.key(), outfit, facing, animation]
	if not _frames.has(key):
		var textures: Array[ImageTexture] = []
		for frame: Dictionary in ChibiAnimations.get_frames(animation):
			var image := compose(look, view_of(facing), frame, outfit)
			if facing == Facing.Direction.LEFT:
				image.flip_x()
			textures.append(ImageTexture.create_from_image(image))
		_frames[key] = textures
	return _frames[key]


## Hair, face and shoulders for UI portraits (PORTRAIT_RECT size, 17×19 px).
static func get_portrait(look: HunterAppearance, outfit: StringName = &"") -> ImageTexture:
	var key := "%s|%s" % [look.key(), outfit]
	if not _portraits.has(key):
		var image := compose(look, View.FRONT, {}, outfit)
		var crop := Rect2i(BODY_ORIGIN + PORTRAIT_RECT.position, PORTRAIT_RECT.size)
		_portraits[key] = ImageTexture.create_from_image(image.get_region(crop))
	return _portraits[key]


## Outfit of a Hunter class: subclasses wear their base class's outfit; unknown classes the
## reference tank top.
static func outfit_for(definition: HunterDefinition) -> StringName:
	if definition == null:
		return &""
	var base: StringName = definition.class_id
	if definition.promotion_of != &"":
		base = definition.promotion_of
	return base if OUTFITS.has(base) else &""


static func view_of(facing: Facing.Direction) -> View:
	match facing:
		Facing.Direction.UP:
			return View.BACK
		Facing.Direction.LEFT, Facing.Direction.RIGHT:
			return View.SIDE
	return View.FRONT


## One 32×48 frame: every part moved by the frame's offsets (ChibiAnimations.resolve_offsets).
## Gaps opened between parts are filled by repeating the edge row (chin, top of the legs).
static func compose(look: HunterAppearance, view: View, frame: Dictionary, outfit: StringName = &"") -> Image:
	var offsets := ChibiAnimations.resolve_offsets(frame, view == View.SIDE)
	var map := body_map(view, outfit)
	var palette := palette_for(look, outfit)
	var lying: bool = frame.get("lying", false)
	var canvas := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8) if not lying \
		else Image.create(BODY_SIZE.x + 8, BODY_SIZE.y + 8, false, Image.FORMAT_RGBA8)
	var origin := BODY_ORIGIN if not lying else Vector2i(4, 4)
	for part in PART_ORDER:
		var rect: Rect2i = PARTS[part]
		var offset: Vector2i = offsets[part]
		var torso_y: int = offsets[&"torso"].y
		if part == &"leg_l" or part == &"leg_r":
			# Torso raised above the legs: stretch the top of the legs up to it.
			for gap in range(1, offset.y - torso_y + 1):
				_blit_row(canvas, map, palette, rect, rect.position.y, origin + offset + Vector2i(0, rect.position.y - gap))
		_blit(canvas, map, palette, rect, origin + offset)
		if part == &"head":
			# Head raised above the torso: stretch the chin down to it.
			for gap in range(1, torso_y - offset.y + 1):
				_blit_row(canvas, map, palette, rect, rect.end.y - 1, origin + offset + Vector2i(0, rect.end.y - 1 + gap))
	# Hair over the head, following it.
	var head_offset: Vector2i = offsets[&"head"]
	_blit_map(canvas, hair_map(look.hair_style, view), palette, origin + head_offset + Vector2i(0, HAIR_TOP))
	if not lying:
		return canvas
	# Lying on the ground: rotate the standing pose, head towards the facing side.
	canvas.rotate_90(CLOCKWISE)
	var used := canvas.get_used_rect()
	var result := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	var lift: int = frame.get("lift", 0)
	var at := Vector2i((CANVAS.x - used.size.x) / 2, CANVAS.y - used.size.y - 1 + lift)
	result.blit_rect(canvas, used, at)
	return result


## Body map for a view and outfit (cached). Back: no face, shirt back. Side: eyes shifted, far
## ear hidden.
static func body_map(view: View, outfit: StringName = &"") -> Array:
	var key := "%d|%s" % [view, outfit]
	if _maps.has(key):
		return _maps[key]
	var rows: Array = []
	for row: String in BODY:
		rows.append(row)
	if OUTFITS.has(outfit):
		var torso: Array = OUTFITS[outfit]
		for i in torso.size():
			rows[TORSO_ROW + i] = torso[i]
	if view != View.FRONT:
		var face := _clear_face(rows)
		if view == View.BACK:
			rows = face
			# The shirt covers the back: no skin V-neck.
			rows[14] = _replace_cols(rows[14], 6, String(rows[15]).substr(6, 3))
		else:
			for y in range(EYE_ROWS.x, EYE_ROWS.y + 1):
				var front: String = BODY[y]
				var row: String = face[y]
				row = _replace_cols(row, EYE_LEFT_COL + SIDE_EYE_SHIFT.x, front.substr(EYE_LEFT_COL, 2))
				row = _replace_cols(row, EYE_RIGHT_COL + SIDE_EYE_SHIFT.y, front.substr(EYE_RIGHT_COL, 2))
				face[y] = row
			# Far (left) ear hidden behind the head.
			face[8] = _replace_cols(face[8], 0, ".o")
			face[9] = _replace_cols(face[9], 0, ".o")
			rows = face
	_maps[key] = rows
	return rows


## Hair rows for a style and view (cached), starting HAIR_TOP rows above the head.
## Back: every row down to the style's "back" row is filled across the head; long strands
## (below the head) are joined. Side (facing right): the back of the head (left) is filled, the
## fringe stays on the face side, strands in front of the face are dropped.
static func hair_map(style: int, view: View) -> Array:
	var key := "%d|%d" % [posmod(style, HAIR_STYLES.size()), view]
	if _hair_maps.has(key):
		return _hair_maps[key]
	var entry: Dictionary = HAIR_STYLES[posmod(style, HAIR_STYLES.size())]
	var front: Array = entry["rows"]
	var back_len: int = entry["back"]
	var rows: Array = []
	for i in front.size():
		var row: String = front[i]
		if view == View.FRONT:
			rows.append(row)
			continue
		var head_row := i + HAIR_TOP
		var first := -1
		var last := -1
		for x in row.length():
			if row[x] != ".":
				if first < 0:
					first = x
				last = x
		if view == View.SIDE and head_row > 6:
			row = row.substr(0, 8) + ".".repeat(row.length() - 8)
		if first >= 0 and (head_row <= back_len or head_row > 12):
			var right := last
			if view == View.SIDE:
				right = mini(last, 7 if head_row <= 6 else 4)
			for x in range(first, right + 1):
				if row[x] == ".":
					row[x] = "D" if head_row == back_len or x >= 11 else "H"
				elif row[x] == "o" and x > first and x < right and head_row >= 0:
					row[x] = "D" if head_row == back_len else "H"
		rows.append(row)
	_hair_maps[key] = rows
	return rows


static func palette_for(look: HunterAppearance, outfit: StringName = &"") -> Dictionary:
	var skin: Array = SKINS[posmod(look.skin, SKINS.size())]
	var dye: Color = PlaceholderVisual.ACCENT_PALETTE[posmod(look.dye, PlaceholderVisual.ACCENT_PALETTE.size())]
	var hair: Array = HAIR_COLORS[posmod(look.hair_color, HAIR_COLORS.size())]
	var cloth: Array = CLOTH
	if CLOTHS.has(outfit):
		cloth = CLOTHS[outfit]
	return {
		"o": OUTLINE, "r": EYE_LID, "w": EYE_WHITE, "i": hair[1],
		"h": skin[0], "s": skin[1], "m": skin[2], "d": skin[3], "n": skin[4],
		"W": cloth[0], "c": cloth[1], "g": cloth[2], "b": cloth[3], "p": cloth[4],
		"k": dye, "K": dye.darkened(0.35),
		"y": TRIM, "Y": TRIM_DARK, "e": LEATHER, "E": LEATHER_DARK,
		"t": METAL, "T": METAL_DARK, "u": METAL_SHINE, "f": BOOT, "F": BOOT_LIGHT,
		"L": hair[0], "H": hair[1], "D": hair[2],
	}


## Off hand (bottom of the left arm, shield) relative to the feet, unmirrored.
static func off_hand_position(view: View, arm: Vector2i) -> Vector2:
	var hand := Vector2i(BODY_SIZE.x - 1 - HAND.x, HAND.y)
	if view == View.BACK:
		hand.x = HAND.x
	return Vector2(BODY_ORIGIN + hand + arm - FEET) + Vector2(0.5, 0.5)


## Hand position relative to the feet for arm offset `arm`, unmirrored (side view faces right).
static func hand_position(view: View, arm: Vector2i) -> Vector2:
	var hand := HAND
	if view == View.BACK:
		# Seen from behind, the weapon hand is on the screen-left side.
		hand.x = BODY_SIZE.x - 1 - HAND.x
	return Vector2(BODY_ORIGIN + hand + arm - FEET) + Vector2(0.5, 0.5)


static func _clear_face(rows: Array) -> Array:
	var result := rows.duplicate()
	for y in range(EYE_ROWS.x, EYE_ROWS.y + 1):
		var row: String = result[y]
		for x in range(3, 12):
			if row[x] in ["o", "w", "W", "r", "i"]:
				row[x] = "s"
		result[y] = row
	return result


static func _replace_cols(row: String, column: int, text: String) -> String:
	return row.substr(0, column) + text + row.substr(column + text.length())


static func _blit(canvas: Image, map: Array, palette: Dictionary, rect: Rect2i, at: Vector2i) -> void:
	for y in range(rect.position.y, rect.end.y):
		_blit_row(canvas, map, palette, rect, y, at + Vector2i(0, y))


static func _blit_map(canvas: Image, rows: Array, palette: Dictionary, at: Vector2i) -> void:
	if rows.is_empty():
		return
	var rect := Rect2i(0, 0, String(rows[0]).length(), rows.size())
	for y in rows.size():
		_blit_row(canvas, rows, palette, rect, y, at + Vector2i(0, y))


## Map row `map_y` (columns of `rect`) drawn at canvas row `at.y`; map column 0 is at `at.x`.
static func _blit_row(canvas: Image, map: Array, palette: Dictionary, rect: Rect2i, map_y: int, at: Vector2i) -> void:
	var row: String = map[map_y]
	var y := at.y
	if y < 0 or y >= canvas.get_height():
		return
	for x in range(rect.position.x, rect.end.x):
		var symbol := row[x]
		if symbol == ".":
			continue
		var cx := at.x + x
		if cx >= 0 and cx < canvas.get_width():
			canvas.set_pixel(cx, y, palette[symbol])
