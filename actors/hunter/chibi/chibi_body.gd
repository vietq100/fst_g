class_name ChibiBody
extends RefCounted
## The chibi Hunter body (D49, redrawn larger in D67): a 23×44 px base figure (bald, white tank
## top, shorts) on a 40×64 canvas with room above for hair, hats, jumps and weapons. The body is split into six parts (head, torso, two arms, two legs) that animation
## frames move by whole pixels (ChibiAnimations), so the art stays crisp.
## Facings: front (down), back (up) and side (right; left is the mirrored image).
## Layers: skin tone, dye (trousers), hair style and hair colour come from HunterAppearance; the
## outfit (torso, arms, legs rows) follows the Hunter's base class (OUTFITS, `outfit_for`).
## Hair is drawn over the head part and moves with it; back and side views are derived from the
## front hair map (`hair_map`).

const CANVAS := Vector2i(40, 64)
## Top-left of the body map on the canvas in the rest pose.
const BODY_ORIGIN := Vector2i(8, 20)
## The actor's feet (node origin) on the canvas.
const FEET := Vector2i(20, 64)
const BODY_SIZE := Vector2i(23, 44)

enum View { FRONT, BACK, SIDE }

## Base figure, front view (redrawn from the traced reference, D67). Symbols:
## o outline · h s m d n skin (light → darkest) · q blush · r eye lid · w eye shine ·
## j i v iris (light, base, dark; the hair colour's base and dark tones) · W c g b p tank top (white → dark) ·
## k K shorts (dye, dye dark) · . transparent
## Outfits add: y Y gold trim · e E leather · t T u metal (base, dark, shine) · f F boots (dark, light)
## Light comes from the top left: highlights on the left, shade on the right and under the fringe.
const BODY := [
	"........ooooooo........",
	"......oohhhhhhhoo......",
	".....ohhhhhhhhhhso.....",
	"....ohhhhhhhhhhhsso....",
	"...ohhhhhhhhhhhhssso...",
	"..ohhhhhhhhhhhhssssmo..",
	".ohhhhhhhhhhhhssssssmo.",
	".ohhhhhhhhhhhsssssssmo.",
	"ohhhhhhhhhhsssssssssmmo",
	"ohhhhhhhhhssssssssssmmo",
	"ohsssssssssssssssssmmdo",
	"ohmsssrrrsssssrrrsssmdo",
	"ohsssmwjjssssswjjmssmdo",
	"omsssmjiisssssjiimssmdo",
	".ossssiiisssssiiisssmo.",
	"..oqqsvvvsssssvvvsqqo..",
	"...osssssssssssssssmo..",
	"....ommssssdssssmmo....",
	"......ommsssssmmo......",
	"........odmmmdo........",
	"........onnnnno........",
	"....oomssWWWWWssmoo....",
	"...ohhssgWWWWWcssmmo...",
	"..ohhsssgWWWWWWcsssmo..",
	".ohhsssbgWWWWWWcbsssmo.",
	"ohsssbgWWWWWWWWWcbsssmo",
	"ohsssbgWWWWWWWWWcbsssmo",
	"osssmbgWWWWWWWWWcbdssmo",
	"osssmbgWWWWWWWWWcbdssmo",
	"omssmbgWWWWWWWWWcbdssmo",
	"ommsobgWWWWWWWWWcbosmmo",
	".ooo.ogcccccccccgo.ooo.",
	"......oKkkkkkkkkKo.....",
	"......oKkkkkkkkkKo.....",
	".......oKkkkkkkKo......",
	".......oKkkkkkkKo......",
	".......oKkkkkkkKo......",
	".....oKkkKo.oKkkKo.....",
	".....omssmo.omssmo.....",
	".....omssmo.omssmo.....",
	".....omssmo.omssmo.....",
	".....ohssmo.ohssmo.....",
	".....ohssmo.ohssmo.....",
	".....oooooo.oooooo.....",
]

## Part rectangles in the body map. Draw order (back to front) is PART_ORDER.
const PARTS := {
	&"head": Rect2i(0, 0, 23, 20),
	&"torso": Rect2i(5, 20, 13, 17),
	&"arm_l": Rect2i(0, 20, 5, 15),
	&"arm_r": Rect2i(18, 20, 5, 15),
	&"leg_l": Rect2i(0, 37, 12, 7),
	&"leg_r": Rect2i(12, 37, 11, 7),
}
const PART_ORDER: Array[StringName] = [&"arm_l", &"leg_l", &"leg_r", &"torso", &"arm_r", &"head"]
## Weapon hand (bottom of the right arm) in the body map.
const HAND := Vector2i(20, 30)
## Eye blocks (front view): left eye, right eye, rows 11–15 (lid, shine, iris, iris, dark), 3 px wide.
const EYE_ROWS := Vector2i(11, 15)
const EYE_WIDTH := 3
## Face symbols cleared in the back and side views (columns FACE_COLS).
const FACE_SYMBOLS := ["r", "w", "i", "j", "v", "q"]
const FACE_COLS := Vector2i(2, 20)
## Female lash flick: one lid pixel outside each eye's outer corner (row, left col, right col).
const LASH_ROW := 11
const LASH_COLS := Vector2i(5, 17)
const EYE_LEFT_COL := 6
const EYE_RIGHT_COL := 14
## Side view: eyes slide toward the facing side by these amounts.
const SIDE_EYE_SHIFT := Vector2i(3, 1)
## Ear rows (the far ear is hidden in the side view).
const EAR_ROWS := Vector2i(11, 13)
## First body-map row replaced by an outfit (neck); outfits cover rows 20–43.
const TORSO_ROW := 20
## Hair maps start this many rows above the head's top row.
const HAIR_TOP := -4
## Head rows used when deriving side / back hair: last fringe row, last head row, column where
## the right side falls into shade; side view keeps this many columns of the fringe and fills
## the back of the head up to these columns (fringe rows, lower rows).
const HAIR_FRINGE_ROW := 9
const HEAD_BOTTOM_ROW := 19
const HAIR_SHADE_COL := 17
const SIDE_FRINGE_COLS := 12
const SIDE_FILL_RIGHT := Vector2i(11, 6)
## Portrait crop relative to BODY_ORIGIN: hair, face and shoulders.
const PORTRAIT_RECT := Rect2i(-2, -5, 27, 29)

const OUTLINE := Color("3d1505")
const EYE_LID := Color("3a1f2a")
const EYE_WHITE := Color("f7f1f3")
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
## Skin ramps [light, base, shadow, deep, darkest, blush] per HunterAppearance.skin.
const SKINS := [
	[Color("ffe6d8"), Color("fbcbb9"), Color("e8977f"), Color("c47c71"), Color("814721"), Color("f7a4a6")],
	[Color("f8d8b0"), Color("e8b48a"), Color("c98a63"), Color("a5674a"), Color("6e3f22"), Color("e8977f")],
	[Color("dcaa84"), Color("c18560"), Color("9c6243"), Color("7a4a32"), Color("4e2a18"), Color("c87462")],
	[Color("ac7a5c"), Color("8a5a3e"), Color("6b432c"), Color("52311f"), Color("33190c"), Color("9a5a4a")],
]

## Outfit rows per base class, replacing body rows TORSO_ROW..28 (cloth ramps in CLOTHS):
## Warrior red tunic + steel pauldrons, Ranger green tunic + quiver strap, Rogue dark tunic +
## dyed scarf, Guardian plate + blue tabard.
const OUTFITS := {
	&"warrior": [
		"........onnnnno........",
		"...ouuutogWcWgotTTTo...",
		"..ouuttTocWWWcottTTTo..",
		".outttTTocWWWcottTTTTo.",
		"ottTTTobgWWWWWcboTTTTTo",
		"occgbbgWcccccccgbbgbbpo",
		"occgbbgWcccccccgbbgbbpo",
		"occgbbgWcccccccgbbgbbpo",
		"occgbbgWcccccccgbbgbbpo",
		"omssmbgWcccccccgbbdssmo",
		"ommsoEeeeeeyeeeeeEosmmo",
		".ooo.EeeeeeYeeeeeE.ooo.",
		"....ogWcccccccccgbo....",
		"....ogWcccccccccgbo....",
		"....ogcccccccccccbo....",
		".....oKkkkkkkkkkKo.....",
		".....oKkkkkkkkkkKo.....",
		".....oKkkKo.oKkkKo.....",
		".....oKkkKo.oKkkKo.....",
		".....oFfffo.oFfffo.....",
		".....oFfffo.oFfffo.....",
		".....offffo.offffo.....",
		"....offfffo.offfffo....",
		"....ooooooo.ooooooo....",
	],
	&"ranger": [
		"........onnnnno........",
		"...oEEegccWWWccgeEEo...",
		"..oeEEgccWWWWccegEEeo..",
		".oeeEbgcWWWWWcecgbEeeo.",
		"occgbbgWcccccecgbbgbbpo",
		"occgbbgWcccceccgbbgbbpo",
		"oEeeEbgWcccecccgbbEeeEo",
		"oEeeEbgWcceccccgbbEeeEo",
		"oEeeEbgWcecccccgbbEeeEo",
		"omssmbgWeccccccgbbdssmo",
		"ommsoEeeeeeyeeeeeEosmmo",
		".ooo.EeeeeeYeeeeeE.ooo.",
		"....ogWcccccccccgbo....",
		"....ogWcccccccccgbo....",
		"....ogcccccccccccbo....",
		".....oKkkkkkkkkkKo.....",
		".....oKkkkkkkkkkKo.....",
		".....oKkkKo.oKkkKo.....",
		".....oeeeEo.oeeeEo.....",
		".....oeeeEo.oeeeEo.....",
		".....oeeeEo.oeeeEo.....",
		".....oEEEEo.oEEEEo.....",
		"....oEEEEEo.oEEEEEo....",
		"....ooooooo.ooooooo....",
	],
	&"rogue": [
		".......okkkkkkko.......",
		"...okKkkkkkkkkkkkKko...",
		"..obgKkkkkkkkkkkkKgbo..",
		".obbgbgccKkkkKcgbbgbbo.",
		"obbgbbgWcKkkkKcgbbgbbpo",
		"obbgbbgWccKkKccgbbgbbpo",
		"obbgbbgWcccKcccgbbgbbpo",
		"obbgbbgWcccccccgbbgbbpo",
		"obbgbbgWcccccccgbbgbbpo",
		"omssmbgWcccccccgbbdssmo",
		"ommsoEeeeeeyeeeeeEosmmo",
		".ooo.EeeEeEeEeEeeE.ooo.",
		"....ogWcccccccccgbo....",
		"....ogWccccbccccgbo....",
		"....ogcccccbcccccbo....",
		".....oKkkkkkkkkkKo.....",
		".....oKkkkkkkkkkKo.....",
		".....oKkkKo.oKkkKo.....",
		".....oFfffo.oFfffo.....",
		".....oFfffo.oFfffo.....",
		".....offffo.offffo.....",
		".....offffo.offffo.....",
		"....offfffo.offfffo....",
		"....ooooooo.ooooooo....",
	],
	&"guardian": [
		"........onnnnno........",
		"..ouuuttTotttttotTTTTo.",
		".ouuttttToutttTottTTTTo",
		"ouuttttTToWcctTottTTTTo",
		"ottTTTToutWcctTToTTTTTo",
		"ottTTTutttWccttTTTtTTTo",
		"ottTTTutttWycttTTTtTTTo",
		"ottTTTutttyyyttTTTtTTTo",
		"ottTTTutttWycttTTTtTTTo",
		"omssmTutttWycttTTTdssmo",
		"ommsoEeeeeeyeeeeeEosmmo",
		".ooo.EeeeeeYeeeeeE.ooo.",
		"....oTutttWcctttTTo....",
		"....oTutttWcctttTTo....",
		"....oTTtttWcctttTTo....",
		".....oKkkkWcckkkKo.....",
		".....oKkkkccckkkKo.....",
		".....oKkkKo.oKkkKo.....",
		".....outtTo.outtTo.....",
		".....outtTo.outtTo.....",
		".....otttTo.otttTo.....",
		".....oTTTTo.oTTTTo.....",
		"....oTTTTTo.oTTTTTo....",
		"....ooooooo.ooooooo....",
	],
}
## Hair styles (HunterAppearance.hair_style): front rows from HAIR_TOP; "back" = last head row
## covered at the back. Short messy, long, ponytail, bob, spiky, bun, side swept, twin tails,
## buzz cut, curly. Symbols: O outline in the hair's darkest tone, L H D hair (light → dark);
## a highlight band sits top-left, strands part in D at the fringe.
const HAIR_STYLES := [
	{"back": 9, "rows": [
		".......................",
		".......OO..OO..OO......",
		".....OOLLOLLOLLHOO.....",
		"....OLLLLLLLHHHHHHDO...",
		"...OLLLLLLLHHHHHHHHDO..",
		"..OLLLLLLHHHHHHHHHHHDO.",
		".OLLLLLHHHHHHHHHHHHHDO.",
		".OLLLLHHHHHHHHHHHHHHDO.",
		"OLLLHHHHHHHHHHHHHHHHDDO",
		"OLLHHHHHHHHHHHHHHHHHDDO",
		"OLHHHHHHHHHHHHHHHHHHDDO",
		"OHHHHHHHHHHHHHHHHHHHDDO",
		"OHHHDHHHHHDHHHHHDHHHDDO",
		"OHHDDO...OHHDO...ODDDDO",
		"OHDO......ODO.....ODDO.",
		"OHDO...............ODO.",
		".ODO...............ODO.",
		"..O.................O..",
	]},
	{"back": 19, "rows": [
		".......................",
		".......................",
		".......................",
		".......OLLLLHHDO.......",
		".....OLLLLLLHHHHDO.....",
		"....OLLLLLLHHHHHHDO....",
		"...OLLLLLLHHHHHHHHDO...",
		"..OLLLLLHHHHHHHHHHHDO..",
		".OLLLLHHHHHHHHHHHHHHDO.",
		"OLLLHHHHHHHHHHHHHHHHDDO",
		"OLLHHHHHHHHHHHHHHHHHDDO",
		"OLHHHHHHHHHHHHHHHHHHDDO",
		"OHHHHHHHHHHDHHHHHHHHHDO",
		"OHHHHHHHHHDDHHHHHHHHHDO",
		"OHHD...............DDDO",
		"OHHD...............DDDO",
		"OHHD...............DDDO",
		"OHHD...............DDDO",
		"OHHD...............DDDO",
		"OHHD...............DDDO",
		"OHHD...............DDDO",
		"OHHD...............DDDO",
		"OHHHD.............DDDDO",
		"OHHHD.............DDDDO",
		"OHHHDO...........ODDDDO",
		"OHHHDDO.........ODDDDDO",
		".OHHDDO.........ODDDDO.",
		"..ODDDO.........ODDDO..",
		"...OOO...........OOO...",
	]},
	{"back": 10, "rows": [
		"................OOO....",
		"...............OLHDO...",
		"..............OLLHDO...",
		".......OLLLLHHDOLHDO...",
		".....OLLLLLLHHHHDOHDO..",
		"....OLLLLLLHHHHHHDODO..",
		"...OLLLLLLHHHHHHHHDDO..",
		"..OLLLLLHHHHHHHHHHHDDO.",
		".OLLLLHHHHHHHHHHHHHHDO.",
		"OLLLHHHHHHHHHHHHHHHHDDO",
		"OLLHHHHHHHHHHHHHHHHHDDO",
		"OLHHHHHHHHHHHHHHHHHHDDO",
		"OHHHHHHHHHHHHHHHHHHHDDO",
		"OHHDDO...OHHDO...ODDDDO",
		"OHDO......ODO.....ODDDO",
		"OHDO...............ODDO",
		".ODO...............ODDO",
		"..O................ODDO",
		"...................ODDO",
		"...................ODDO",
		"...................ODDO",
		"...................ODDO",
		"...................ODDO",
		"...................ODO.",
		"....................O..",
	]},
	{"back": 16, "rows": [
		".......................",
		".......................",
		".......................",
		".......OLLLLHHDO.......",
		".....OLLLLLLHHHHDO.....",
		"....OLLLLLLHHHHHHDO....",
		"...OLLLLLLHHHHHHHHDO...",
		"..OLLLLLHHHHHHHHHHHDO..",
		".OLLLLHHHHHHHHHHHHHHDO.",
		"OLLLHHHHHHHHHHHHHHHHDDO",
		"OLLHHHHHHHHHHHHHHHHHDDO",
		"OLHHHHHHHHHHHHHHHHHHDDO",
		"OHHHHHHHHHHHHHHHHHHHDDO",
		"OHDDDDDDDDDDDDDDDDDDDDO",
		"OHHD...............DDDO",
		"OHHD...............DDDO",
		"OHHD...............DDDO",
		"OHHD...............DDDO",
		"OHHDO.............ODDDO",
		"OHHHDO...........ODDDDO",
		".OHHDDO.........ODDDDO.",
		"..ODDDO.........ODDDO..",
		"...OOO...........OOO...",
	]},
	{"back": 9, "rows": [
		"....O...OO...OO...O....",
		"...OLO.OLLO.OLLO.OLO...",
		"..OLLOLLLHOLLLHOHHDO...",
		"..OLLLLLLLHHHHHHHDDO...",
		".OLLLLLLLHHHHHHHHHHDDO.",
		".OLLLLLLHHHHHHHHHHHDDO.",
		"OLLLLLLHHHHHHHHHHHHHDDO",
		"OLLLLLHHHHHHHHHHHHHHDDO",
		"OLLLLHHHHHHHHHHHHHHHDDO",
		"OLLLHHHHHHHHHHHHHHHHDDO",
		"OLLHHHHHHHHHHHHHHHHHDDO",
		"OLHHHHHHHHHHHHHHHHHHDDO",
		"OHHHHHHHHHHHHHHHHHHHDDO",
		"OHHHDHHHHHDHHHHHDHHHDDO",
		"OHHDDO...OHHDO...ODDDDO",
		"OHDO......ODO.....ODDO.",
		"OHDO...............ODO.",
		".ODO...............ODO.",
		"..O.................O..",
	]},
	{"back": 9, "rows": [
		"........OOOOOOO........",
		".......OLLLHHHDO.......",
		".......OLLHHHHDO.......",
		"......OOLLHHHDDOO......",
		".....OLLLLLLHHHHDO.....",
		"....OLLLLLLHHHHHHDO....",
		"...OLLLLLLHHHHHHHHDO...",
		"..OLLLLLHHHHHHHHHHHDO..",
		".OLLLLHHHHHHHHHHHHHHDO.",
		"OLLLHHHHHHHHHHHHHHHHDDO",
		"OLLHHHHHHHHHHHHHHHHHDDO",
		"OLHHHHHHHHHHHHHHHHHHDDO",
		"OHHHHHHHHHHHHHHHHHHHDDO",
		"OHHDDO...OHHDO...ODDDDO",
		"OHDO......ODO.....ODDO.",
		".ODO...............ODO.",
		"..O.................O..",
	]},
	{"back": 10, "rows": [
		".......................",
		".......................",
		".......................",
		".......OLLLLHHDO.......",
		".....OLLLLLLHHHHDO.....",
		"....OLLLLLLHHHHHHDO....",
		"...OLLLLLLHHHHHHHHDO...",
		"..OLLLLLHHHHHHHHHHHDO..",
		".OLLLLHHHHHHHHHHHHHHDO.",
		"OLLLHHHHHHHHHHHHHHHHDDO",
		"OLLHHHHHHHHHHHHHHHHHDDO",
		"OLHHHHHHHHHHHHHHHHHHDDO",
		"OHHHHHHHHHHHHHHHHHHHDDO",
		"OHHHHDHHHHHHHHHHHHHHDDO",
		"OHDO.....OHHHHHHHHHHDDO",
		"OHDO.......OHHHHHHHHDDO",
		".ODO.........OHHHHHDDO.",
		"..O............OHHHDDDO",
		".................ODDDO.",
		"..................ODDO.",
		"...................OOO.",
	]},
	{"back": 10, "rows": [
		".......................",
		".......................",
		".......................",
		".......OLLLLHHDO.......",
		".....OLLLLLLHHHHDO.....",
		"....OLLLLLLHHHHHHDO....",
		"...OLLLLLLHHHHHHHHDO...",
		"..OLLLLLHHHHHHHHHHHDO..",
		".OLLLLHHHHHHHHHHHHHHDO.",
		"OLLLHHHHHHHHHHHHHHHHDDO",
		"OLLHHHHHHHHHHHHHHHHHDDO",
		"OLHHHHHHHHHHHHHHHHHHDDO",
		"OHHHHHHHHHHHHHHHHHHHDDO",
		"OHHDDO...OHHDO...ODDDDO",
		"OHDO...............ODDO",
		"OHDO...............ODDO",
		"OHDO...............ODDO",
		"OHHDO.............ODDDO",
		"OHHDO.............ODDDO",
		"OHHDO.............ODDDO",
		"OHHHDO...........ODDDDO",
		"OHHHDO...........ODDDDO",
		"OHHHDDO.........ODDDDDO",
		".OHHDDO.........ODDDDO.",
		"..ODDDO.........ODDDO..",
		"...OOO...........OOO...",
	]},
	{"back": 6, "rows": [
		".......................",
		".......................",
		".......................",
		".......OLLLLHHDO.......",
		".....OLLLLLLHHHHDO.....",
		"....OLLLLLLHHHHHHDO....",
		"...OLLLLLLHHHHHHHHDO...",
		"..OLLLLLHHHHHHHHHHHDO..",
		".OLLLLHHHHHHHHHHHHHHDO.",
		"OLLLHHHHHHHHHHHHHHHHDDO",
		"OHHDDDDDDDDDDDDDDDDDDDO",
		"ODO.................ODO",
		".O...................O.",
	]},
	{"back": 11, "rows": [
		".......................",
		".....OO..OO..OO..OO....",
		"....OLLOLLOHHOHHOHHDO..",
		"...OLLLLLLLHHHHHHHDDO..",
		"..OLLLLLLLHHHHHHHHHDDO.",
		".OLLLLLLLHHHHHHHHHHDDO.",
		"OLLLLLLHHHHHHHHHHHHHDDO",
		"OLLLLLHHHHHHHHHHHHHHDDO",
		"OLLLLHHHHHHHHHHHHHHHDDO",
		"OLLLHHHHHHHHHHHHHHHHDDO",
		"OLLHHHHHHHHHHHHHHHHHDDO",
		"OLHHHHHHHHHHHHHHHHHHDDO",
		"OHHHHHHHHHHHHHHHHHHHDDO",
		"OHHHDHHHHHDHHHHHDHHHDDO",
		"OHHDDO...OHHDO...ODDDDO",
		"OHHDO.............ODDDO",
		"OHHDO.............ODDDO",
		".ODDO.............ODDO.",
		"..OOO.............OOO..",
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

## Hats drawn over the hair (D59): `top` = first row relative to the head's top row; symbols
## A base, B shade, C light (the helmet's tint), y Y gold, r gem, o outline, . transparent.
const HATS := {
	&"helm": {"top": -6, "rows": [
		"........ooooooo........",
		"......ooCCCAAAAoo......",
		".....oCCCAAAAAAABo.....",
		"....oCCCAAAAAAAABBo....",
		"...oCCCAAAAAAAAAABBo...",
		"..oCCAAAAAAAAAAAABBBo..",
		".oCCAAAAAAAAAAAAAABBBo.",
		"oCCAAAAAAAAAAAAAAABBBBo",
		"oCAAAAAAAAAAAAAAAABBBBo",
		"oAAAAAAAAAAAAAAAAABBBBo",
		"oAAAAAAAAAAAAAAAAABBBBo",
		"oAAAAAAAAAAAAAAAAABBBBo",
		"oyyyyyyyyyyyyyyyyyyyyyo",
		"oYYYYYYYYYYYYYYYYYYYYYo",
		"oBo.................oBo",
		"oBo.................oBo",
		"oBo.................oBo",
		".o...................o.",
	]},
	&"cap": {"top": -5, "rows": [
		"......ooooooooooo......",
		"....ooCCCAAAAAABBoo....",
		"...oCCCAAAAAAAAABBBo...",
		"..oCCCAAAAAAAAAABBBBo..",
		".oCCAAAAAAAAAAAAABBBBo.",
		".oCCAAAAAyyyyyAAABBBBo.",
		"oBBBBBBBBBBBBBBBBBBBBBo",
		".ooooooooooooooooooooo.",
	]},
	&"hood": {"top": -6, "rows": [
		"........ooooooo........",
		"......ooCCCAAAAoo......",
		".....oCCCAAAAAAABo.....",
		"....oCCCAAAAAAAABBo....",
		"...oCCCAAAAAAAAAABBo...",
		"..oCCAAAAAAAAAAAABBBo..",
		".oCCAAAAAAAAAAAAAABBBo.",
		"oCCAAAAAAAAAAAAAAABBBBo",
		"oCAoooooooooooooooooABo",
		"oCAo...............oABo",
		"oAo.................oBo",
		"oAo.................oBo",
		"oAo.................oBo",
		"oAo.................oBo",
		"oAo.................oBo",
		"oAo.................oBo",
		"oAo.................oBo",
		"oAo.................oBo",
		"oAo.................oBo",
		"oAo.................oBo",
		"oAAo...............oBBo",
		".oAAo.............oBBo.",
		"..ooo.............ooo..",
	]},
	&"wizard": {"top": -16, "rows": [
		"..............ooo......",
		".............oAo.......",
		"............oAAo.......",
		"...........oCAAo.......",
		"..........oCAAABo......",
		".........oCAAAABo......",
		"........oCCAAAABo......",
		".......oCCAAAAABBo.....",
		"......oCCAAAAAABBo.....",
		".....oCCAAAAAAABBBo....",
		"....oCCAAAAAAAAABBBo...",
		"....oCCAAAAAAAAABBBo...",
		"...oCCAAAAAAAAAAABBBo..",
		"...oyyyyyyyyyyyyyyyo...",
		"..oCCAAAAAAAAAAAABBBo..",
		"oCCAAAAAAAAAAAAAAAAABBo",
		"oBBBBBBBBBBBBBBBBBBBBBo",
		".ooooooooooooooooooooo.",
	]},
	&"crown": {"top": -7, "rows": [
		"...o...o...o...o...o...",
		"..oyo.oyo.oyo.oyo.oyo..",
		"..oyyyyyyyyyyyyyyyyyo..",
		"..oyyryyyryyyryyyryyo..",
		"..oyyyyyyyyyyyyyyyyyo..",
		"..oYYYYYYYYYYYYYYYYYo..",
		"...ooooooooooooooooo...",
	]},
}
## Words in a helmet's id → hat style (when it has no `look_id`).
const HAT_WORDS := [["crown", &"crown"], ["wizard", &"wizard"], ["hat", &"wizard"], ["hood", &"hood"], ["cap", &"cap"]]

static var _maps: Dictionary = {}
static var _hair_maps: Dictionary = {}
static var _frames: Dictionary = {}
static var _portraits: Dictionary = {}
static var _figures: Dictionary = {}


## Frame textures of one animation for a look and facing. Left facing is pre-mirrored.
## `dress` (D59) overrides `outfit` and adds the gear's colours and hat.
static func get_frames(look: HunterAppearance, facing: Facing.Direction, animation: StringName,
		outfit: StringName = &"", dress: ChibiDress = null) -> Array[ImageTexture]:
	var key := "%s|%s|%d|%s" % [look.key(), dress.key() if dress != null else outfit, facing, animation]
	if not _frames.has(key):
		var textures: Array[ImageTexture] = []
		for frame: Dictionary in ChibiAnimations.get_frames(animation):
			var image := compose(look, view_of(facing), frame, outfit, dress)
			if facing == Facing.Direction.LEFT:
				image.flip_x()
			textures.append(ImageTexture.create_from_image(image))
		_frames[key] = textures
	return _frames[key]


## Hair, face and shoulders for UI portraits (PORTRAIT_RECT size, 27×29 px).
static func get_portrait(look: HunterAppearance, outfit: StringName = &"", dress: ChibiDress = null) -> ImageTexture:
	var key := "%s|%s" % [look.key(), dress.key() if dress != null else outfit]
	if not _portraits.has(key):
		var image := compose(look, View.FRONT, {}, outfit, dress)
		var crop := Rect2i(BODY_ORIGIN + PORTRAIT_RECT.position, PORTRAIT_RECT.size)
		_portraits[key] = ImageTexture.create_from_image(image.get_region(crop))
	return _portraits[key]


## The whole figure, front view at rest, cropped to what is drawn (UI cards and the paper doll,
## D59). The feet are on the bottom row.
static func get_figure(look: HunterAppearance, dress: ChibiDress) -> ImageTexture:
	var key := "%s|%s" % [look.key(), dress.key()]
	if not _figures.has(key):
		var image := compose(look, View.FRONT, {}, dress.outfit, dress)
		var used := image.get_used_rect()
		used = Rect2i(used.position, Vector2i(used.size.x, CANVAS.y - used.position.y))
		_figures[key] = ImageTexture.create_from_image(image.get_region(used))
	return _figures[key]


## Hat style of a helmet: its `look_id`, else a style named in its id, else a metal helm.
static func hat_style_for(item: ItemDefinition) -> StringName:
	if item == null:
		return &""
	if HATS.has(item.look_id):
		return item.look_id
	var id := String(item.id)
	for pair: Array in HAT_WORDS:
		if id.contains(pair[0]):
			return pair[1]
	return &"helm"


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
static func compose(look: HunterAppearance, view: View, frame: Dictionary, outfit: StringName = &"",
		dress: ChibiDress = null) -> Image:
	if dress != null:
		outfit = dress.outfit
	var offsets := ChibiAnimations.resolve_offsets(frame, view == View.SIDE)
	var map := body_map(view, outfit, look.gender == HunterAppearance.FEMALE)
	var palette := palette_for(look, outfit, dress)
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
	var hat: Dictionary = HATS.get(dress.hat, {}) if dress != null else {}
	# Hoods and full helms hide long hair at the back.
	if hat.is_empty() or view == View.FRONT or dress.hat == &"cap" or dress.hat == &"crown":
		_blit_map(canvas, hair_map(look.hair_style, view), palette, origin + head_offset + Vector2i(0, HAIR_TOP))
	if not hat.is_empty():
		_blit_map(canvas, hat["rows"], palette, origin + head_offset + Vector2i(0, hat["top"]))
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
## ear hidden. `female` adds a lash flick at each eye's outer corner (front and side).
static func body_map(view: View, outfit: StringName = &"", female := false) -> Array:
	var key := "%d|%s|%s" % [view, outfit, female]
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
		else:
			for y in range(EYE_ROWS.x, EYE_ROWS.y + 1):
				var front: String = BODY[y]
				var row: String = face[y]
				row = _replace_cols(row, EYE_LEFT_COL + SIDE_EYE_SHIFT.x, front.substr(EYE_LEFT_COL, EYE_WIDTH))
				row = _replace_cols(row, EYE_RIGHT_COL + SIDE_EYE_SHIFT.y, front.substr(EYE_RIGHT_COL, EYE_WIDTH))
				face[y] = row
			# Far (left) ear hidden behind the head.
			for y in range(EAR_ROWS.x, EAR_ROWS.y + 1):
				face[y] = _replace_cols(face[y], 0, ".o")
			rows = face
	if female and view != View.BACK:
		var shift := SIDE_EYE_SHIFT if view == View.SIDE else Vector2i.ZERO
		rows[LASH_ROW] = _replace_cols(rows[LASH_ROW], LASH_COLS.x + shift.x, "r")
		rows[LASH_ROW] = _replace_cols(rows[LASH_ROW], LASH_COLS.y + shift.y, "r")
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
		if view == View.SIDE and head_row > HAIR_FRINGE_ROW:
			row = row.substr(0, SIDE_FRINGE_COLS) + ".".repeat(row.length() - SIDE_FRINGE_COLS)
		if first >= 0 and (head_row <= back_len or head_row > HEAD_BOTTOM_ROW):
			var right := last
			if view == View.SIDE:
				right = mini(last, SIDE_FILL_RIGHT.x if head_row <= HAIR_FRINGE_ROW else SIDE_FILL_RIGHT.y)
			for x in range(first, right + 1):
				if row[x] == ".":
					row[x] = "D" if head_row == back_len or x >= HAIR_SHADE_COL else "H"
				elif row[x] == "O" and x > first and x < right and head_row >= 0:
					row[x] = "D" if head_row == back_len else "H"
		rows.append(row)
	_hair_maps[key] = rows
	return rows


static func palette_for(look: HunterAppearance, outfit: StringName = &"", dress: ChibiDress = null) -> Dictionary:
	var skin: Array = SKINS[posmod(look.skin, SKINS.size())]
	var dye: Color = PlaceholderVisual.ACCENT_PALETTE[posmod(look.dye, PlaceholderVisual.ACCENT_PALETTE.size())]
	var hair: Array = HAIR_COLORS[posmod(look.hair_color, HAIR_COLORS.size())]
	var cloth: Array = CLOTH
	if CLOTHS.has(outfit):
		cloth = CLOTHS[outfit]
	var boot := BOOT
	var boot_light := BOOT_LIGHT
	var hat: Array = ChibiDress.ramp(METAL)
	if dress != null:
		if dress.has_cloth:
			cloth = ChibiDress.ramp(dress.cloth)
		if dress.has_pants:
			dye = dress.pants
		if dress.has_boots:
			boot = dress.boots.darkened(0.15)
			boot_light = dress.boots.lightened(0.1)
		if dress.hat != &"":
			hat = ChibiDress.ramp(dress.hat_tint)
	return {
		"A": hat[1], "B": hat[3], "C": hat[0],
		"o": OUTLINE, "r": EYE_LID, "w": EYE_WHITE, "j": hair[1], "i": hair[2], "v": hair[2].darkened(0.45),
		"h": skin[0], "s": skin[1], "m": skin[2], "d": skin[3], "n": skin[4], "q": skin[5],
		"W": cloth[0], "c": cloth[1], "g": cloth[2], "b": cloth[3], "p": cloth[4],
		"k": dye, "K": dye.darkened(0.35),
		"y": TRIM, "Y": TRIM_DARK, "e": LEATHER, "E": LEATHER_DARK,
		"t": METAL, "T": METAL_DARK, "u": METAL_SHINE, "f": boot, "F": boot_light,
		"L": hair[0], "H": hair[1], "D": hair[2], "O": hair[2].darkened(0.45),
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
		for x in range(FACE_COLS.x, FACE_COLS.y + 1):
			if row[x] in FACE_SYMBOLS:
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
