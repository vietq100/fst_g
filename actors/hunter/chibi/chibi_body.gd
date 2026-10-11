class_name ChibiBody
extends RefCounted
## The chibi Hunter body (D49): a 15×29 px base figure (bald, white tank top, shorts) traced from
## the owner's reference, placed on a 32×48 canvas with room above for hair, hats, jumps and
## weapons. The body is split into six parts (head, torso, two arms, two legs) that animation
## frames move by whole pixels (ChibiAnimations), so the art stays crisp.
## Facings: front (down), back (up) and side (right; left is the mirrored image).
## Skin tone and dye come from HunterAppearance; hair and outfits are future layers.

const CANVAS := Vector2i(32, 48)
## Top-left of the body map on the canvas in the rest pose.
const BODY_ORIGIN := Vector2i(8, 19)
## The actor's feet (node origin) on the canvas.
const FEET := Vector2i(16, 48)
const BODY_SIZE := Vector2i(15, 29)

enum View { FRONT, BACK, SIDE }

## Traced reference, front view. Symbols:
## o outline · h s m d n skin (light → dark) · r eye lid · w eye white
## W c g b p tank top (white → dark) · k K shorts (dye, dye dark) · . transparent
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
	".omsWrsssrWsmo.",
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

const OUTLINE := Color("3d1505")
const EYE_LID := Color("a64c40")
const EYE_WHITE := Color("eddad4")
const CLOTH: Array[Color] = [Color("fff6ec"), Color("e2e0d6"), Color("b5aeb4"), Color("888ca5"), Color("786d62")]
## Skin ramps [light, base, shadow, deep, darkest] per HunterAppearance.skin.
const SKINS := [
	[Color("ffe0d0"), Color("fbcbb9"), Color("e8977f"), Color("c47c71"), Color("814721")],
	[Color("f6d2a8"), Color("e8b48a"), Color("c98a63"), Color("a5674a"), Color("6e3f22")],
	[Color("d9a47c"), Color("c18560"), Color("9c6243"), Color("7a4a32"), Color("4e2a18")],
	[Color("a87556"), Color("8a5a3e"), Color("6b432c"), Color("52311f"), Color("33190c")],
]

static var _maps: Dictionary = {}
static var _frames: Dictionary = {}
static var _portraits: Dictionary = {}


## Frame textures of one animation for a look and facing. Left facing is pre-mirrored.
static func get_frames(look: HunterAppearance, facing: Facing.Direction, animation: StringName) -> Array[ImageTexture]:
	var key := "%s|%d|%s" % [look.key(), facing, animation]
	if not _frames.has(key):
		var textures: Array[ImageTexture] = []
		for frame: Dictionary in ChibiAnimations.get_frames(animation):
			var image := compose(look, view_of(facing), frame)
			if facing == Facing.Direction.LEFT:
				image.flip_x()
			textures.append(ImageTexture.create_from_image(image))
		_frames[key] = textures
	return _frames[key]


## Head and shoulders for UI portraits (15×14 px).
static func get_portrait(look: HunterAppearance) -> ImageTexture:
	var key := look.key()
	if not _portraits.has(key):
		var image := compose(look, View.FRONT, {})
		_portraits[key] = ImageTexture.create_from_image(image.get_region(Rect2i(BODY_ORIGIN, Vector2i(BODY_SIZE.x, 14))))
	return _portraits[key]


static func view_of(facing: Facing.Direction) -> View:
	match facing:
		Facing.Direction.UP:
			return View.BACK
		Facing.Direction.LEFT, Facing.Direction.RIGHT:
			return View.SIDE
	return View.FRONT


## One 32×48 frame: every part moved by the frame's offsets (ChibiAnimations.resolve_offsets).
## Gaps opened between parts are filled by repeating the edge row (chin, top of the legs).
static func compose(look: HunterAppearance, view: View, frame: Dictionary) -> Image:
	var offsets := ChibiAnimations.resolve_offsets(frame, view == View.SIDE)
	var map := body_map(view)
	var palette := palette_for(look)
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


## Body map for a view (cached). Back: no face, tank back. Side: eyes shifted, far ear hidden.
static func body_map(view: View) -> Array:
	if _maps.has(view):
		return _maps[view]
	var rows: Array = []
	for row: String in BODY:
		rows.append(row)
	if view != View.FRONT:
		var face := _clear_face(rows)
		if view == View.BACK:
			rows = face
			# The tank top covers the back: no skin V-neck.
			rows[14] = _replace_cols(rows[14], 6, "WWW")
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
	_maps[view] = rows
	return rows


static func palette_for(look: HunterAppearance) -> Dictionary:
	var skin: Array = SKINS[posmod(look.skin, SKINS.size())]
	var dye: Color = PlaceholderVisual.ACCENT_PALETTE[posmod(look.dye, PlaceholderVisual.ACCENT_PALETTE.size())]
	return {
		"o": OUTLINE, "r": EYE_LID, "w": EYE_WHITE,
		"h": skin[0], "s": skin[1], "m": skin[2], "d": skin[3], "n": skin[4],
		"W": CLOTH[0], "c": CLOTH[1], "g": CLOTH[2], "b": CLOTH[3], "p": CLOTH[4],
		"k": dye, "K": dye.darkened(0.35),
	}


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
			if row[x] in ["o", "w", "W", "r"]:
				row[x] = "s"
		result[y] = row
	return result


static func _replace_cols(row: String, column: int, text: String) -> String:
	return row.substr(0, column) + text + row.substr(column + text.length())


static func _blit(canvas: Image, map: Array, palette: Dictionary, rect: Rect2i, at: Vector2i) -> void:
	for y in range(rect.position.y, rect.end.y):
		_blit_row(canvas, map, palette, rect, y, at + Vector2i(0, y))


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
