class_name ChibiBody
extends RefCounted
## The chibi Hunter body (D49, D56): a 30×58 texel figure (the owner's 15×29 reference at twice
## the density, D56) placed on a 64×96 canvas with room above for hair, hats, jumps and weapons.
## Textures are drawn at 1 / SCALE in the world, so the character keeps its 32×48 world size and
## the extra texels are detail. The body is split into six parts (head, torso, two arms, two legs)
## that animation frames move by whole world pixels (ChibiAnimations offsets × SCALE), so the art
## stays crisp.
## Facings: front (down), back (up) and side (right; left is the mirrored image).
## Layers: skin tone, dye (trousers), hair style and hair colour come from HunterAppearance; the
## outfit (torso, arms, legs rows) follows the Hunter's base class (OUTFITS, `outfit_for`).
## Hair is drawn over the head part and moves with it; back and side views are derived from the
## front hair map (`hair_map`).

## Texels per world pixel (D56). Every map below is in texels.
const SCALE := 2
const CANVAS := Vector2i(64, 96)
## Top-left of the body map on the canvas in the rest pose.
const BODY_ORIGIN := Vector2i(16, 38)
## The actor's feet (node origin) on the canvas.
const FEET := Vector2i(32, 96)
const BODY_SIZE := Vector2i(30, 58)

enum View { FRONT, BACK, SIDE }

## Traced reference, front view. Symbols:
## o outline · h s m d n skin (light → dark) · r eye lid · w eye white · i iris (hair colour) ·
## l blush
## W c g b p tank top (white → dark) · k K shorts (dye, dye dark) · . transparent
## Outfits add: y Y gold trim · e E leather · t T u metal (base, dark, shine) · f F boots
const BODY := [
	".........oooooooooooo.........",
	".......ooohhssssssssoo........",
	".......ohhhhsssssssssssso.....",
	".....oohhhhssssssssssssssoo...",
	".....ohhhssssssssssssssssso...",
	"...oohhsssssssssssssssssssoo..",
	"...ohhhsssssssssssssssssssso..",
	"..oohhssssssssssssssssssssooo.",
	"..ohhhssssssssssssssssssssmmo.",
	"..ohhhsssssssssssssssssssmmmoo",
	"..ohhhsssssssssssssssssssmmmmo",
	"..ohhsssssssssssssssssssmmmmmo",
	"..osssssssssssssssssssssmmmmmo",
	".oossssssssssssssssssssssmmmmo",
	".osssssorrrssssssssrrrosssssso",
	"oossssoorrrrssssssrrrroossssso",
	"ossssswwwwiisswwsswwiiwwssssso",
	"ossssswwwiwisswwssswiwiwssssso",
	"oossssooiiiissssmmssiiiissssoo",
	".osssssoiiisssssmmsssiissssso.",
	".ooolsssssssssssssssssssslooo.",
	"...ollssssssssssssssssssllo...",
	"....nnssssssssddsssssssmnn....",
	".....nssssssssddsssssmmnnn....",
	"......onnnmmmmmmmmmmmmmnno....",
	"......onnnnmmmmmmmmmmnnoo.....",
	"......onnnnnnnnnnnnnnnno......",
	".....ooonnnnnnnnnnnnnnno......",
	".....ommggccssssssccggmoo.....",
	"....oommgcccsssssscccgmmoo....",
	"....nnsscccWWWWWWWWcccssnn....",
	"...nnssscWWWWWWWWWWWWcsssnn...",
	"...nnssmWWWWWWWWWWWWWWmssnn...",
	"..nnssmmWWWWWWWWWWWWWWmmssnn..",
	"..nnssggWWWWWWWWWWWWWWggssnn..",
	"..nnssggWWWWWWWWWWWWWWggssnn..",
	".ommssbbWWWWWWWWWWWWWWbbssmmo.",
	"oomssbbbWWWWWWWWWWWWWWbbbssmoo",
	"oosssbbccWWWWWWWWWWWWccbbsssoo",
	".ossbbcccccWWWWWWWWcccccbbsso.",
	".oooppggggccccccccccggggppooo.",
	"...oppggggccccccccccggggppo...",
	"....ppccccccccccccccccccpp....",
	"....ppccccccccccccccccccpp....",
	"....opooppWWWWWWWWWWppoopo....",
	"....ooooppWWWWWWWWWWppoooo....",
	"....ooomKKkkkkkkkkkkKKmooo....",
	"....ommmKKkkkkkkkkkkKKmmmo....",
	"....oommssssso..osssssmmoo....",
	".....ommmsssso..ossssmmmo.....",
	".....oommmmmmo..ommmmmmoo.....",
	"......ommmmmmo..ommmmmmo......",
	"......ommmmmmo..ommmmmmo......",
	"......ommmmmmo..ommmmmmo......",
	"......osssssso..osssssso......",
	"......ooossooo..ooossooo......",
	"......ooossooo..ooossooo......",
	".......oooooo....oooooo.......",
]

## Part rectangles in the body map. Draw order (back to front) is PART_ORDER.
const PARTS := {
	&"head": Rect2i(0, 0, 30, 26),
	&"torso": Rect2i(6, 26, 18, 22),
	&"arm_l": Rect2i(0, 26, 6, 20),
	&"arm_r": Rect2i(24, 26, 6, 20),
	&"leg_l": Rect2i(0, 48, 16, 10),
	&"leg_r": Rect2i(16, 48, 14, 10),
}
const PART_ORDER: Array[StringName] = [&"arm_l", &"leg_l", &"leg_r", &"torso", &"arm_r", &"head"]
## Weapon hand (bottom of the right arm) in the body map.
const HAND := Vector2i(26, 40)
## Eye blocks (front view): left eye, right eye, rows 14–19, 4 texels wide (lid, white + iris,
## iris).
const EYE_ROWS := Vector2i(14, 19)
const EYE_LEFT_COL := 8
const EYE_RIGHT_COL := 18
const EYE_WIDTH := 4
## Side view: eyes slide toward the facing side by these amounts.
const SIDE_EYE_SHIFT := Vector2i(4, 2)
## First body-map row replaced by an outfit (neck); outfits cover rows 26–57.
const TORSO_ROW := 26
## Hair maps start this many rows above the head's top row.
const HAIR_TOP := -6
## Side hair (D51 rules at D56 density): rows from this head row on are below the fringe, rows
## below LONG_HAIR_ROW are strands over the shoulders; back-of-head columns end at these.
const FRINGE_END_ROW := 13
const LONG_HAIR_ROW := 25
const SIDE_BACK_COL := 15
const SIDE_NAPE_COL := 9
const HAIR_SHADE_COL := 22
## Portrait crop relative to BODY_ORIGIN: hair, face and shoulders.
const PORTRAIT_RECT := Rect2i(-2, -8, 34, 38)

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
		".......onnnnnnnnnnnnnno.......",
		"......oonnnnnnnnnnnnnnoo......",
		"...ouuuuttccssssssccuutttto...",
		"..oouuuuttccssssssccuuttttoo..",
		"..otttTTTTWWWWWWWWWWTTTTTTTo..",
		"..otttTTTWWWWWWWWWWWWTTTTTTo..",
		"..ppccggWWWWWWWWWWWWWWggccpp..",
		"..ppccggWWWWWWWWWWWWWWggccpp..",
		"..ppccggWWWWWWWWWWWWWWggccpp..",
		"..ppccggWWWWWWWWWWWWWWggccpp..",
		".ommssbbWWWWWWWWWWWWWWbbssmmo.",
		"oomssbbbWWWWWWWWWWWWWWbbbssmoo",
		"oosssbbccWWWWWWWWWWWWccbbsssoo",
		".ossbbcccccWWWWWWWWcccccbbsso.",
		".oooppggggccccccccccggggppooo.",
		"...oppggggccccccccccggggppo...",
		"....ppccccccccccccccccccpp....",
		"....ppccccccccccccccccccpp....",
		"....oEEEeeeeeeyyeeeeeeEEEo....",
		"....oEEEeeeeeeyyeeeeeeEEEo....",
		"....oKKKkkkkkkkkkkkkkkKKKo....",
		"....oKKKkkkkkkkkkkkkkkKKKo....",
		"....ooKKkkkkko..okkkkkKKoo....",
		".....oKKkkkkko..okkkkkKKo.....",
		".....oooFFFFFo..oFFFFFooo.....",
		"......oFFFFFFo..oFFFFFFo......",
		"......offffffo..offffffo......",
		"......offffffo..offffffo......",
		"......offffffo..offffffo......",
		"......oooffooo..oooffooo......",
		"......oooffooo..oooffooo......",
		".......oooooo....oooooo.......",
	],
	&"ranger": [
		".......onnnnnnnnnnnnnno.......",
		".....ooonnnnnnnnnnnnnnooo.....",
		".....oEEggccssssssccggEEo.....",
		"...oooEEgcccsssssscccgEEooo...",
		"...oeeEEcccWWWWWWWWcccEEeeo...",
		"..ooeeEEcWWWWWWWWWWWWcEEeeoo..",
		"..ppeeEEWWWWWWeeWWWWWWEEeepp..",
		"..ppeeEEWWWWWWeeeWWWWWEEeepp..",
		"..ppccggWWWWWWWeeeWWWWggccpp..",
		"..ppccggWWWWWWWWeeeWWWggccpp..",
		".ommEEbbWWWWWWWWWeeeWWbbEEmmo.",
		"oommEEbbWWWWWWWWWWeeeWbbEEmmoo",
		"oossEEcccWWWWWWWWWWeWeccEEssoo",
		".ossEEcccccWWWWWWWWWeeccEEsso.",
		".oooppggggccccccccccggggppooo.",
		"...oppggggcccccccccccgggppo...",
		"....ppccccccccccccccccccpp....",
		"....ppccccccccccccccccccpp....",
		"....oEEEeeeeeeyyeeeeeeEEEo....",
		"....oEEEeeeeeeyyeeeeeeEEEo....",
		"....oKKKkkkkkkkkkkkkkkKKKo....",
		"....oKKKkkkkkkkkkkkkkkKKKo....",
		"....ooKKkkkkko..okkkkkKKoo....",
		".....oKKkkkkko..okkkkkKKo.....",
		".....oooeeeeeo..oeeeeeooo.....",
		"......oeeeeeeo..oeeeeeeo......",
		"......oEEEEEEo..oEEEEEEo......",
		"......oEEEEEEo..oEEEEEEo......",
		"......offfFFFo..offfFFFo......",
		"......ooofFooo..ooofFooo......",
		"......ooofFooo..ooofFooo......",
		".......oooooo....oooooo.......",
	],
	&"rogue": [
		".......okkkkkkkkkkkkkko.......",
		".....ookkkkkkkkkkkkkkkkoo.....",
		".....okkKKkkkkkkkkkkKKkko.....",
		"...oookkKKkkkkkkkkkkKKkkooo...",
		"...obbggKKccWWWWWWccKKggbbo...",
		"..oobbggKKcWWWWWWWWcKKggbboo..",
		"..ppbbggWWWWWWWWWWWWWWggbbpp..",
		"..ppbbggWWWWWWWWWWWWWWggbbpp..",
		"..ppbbggWWWWWWWWWWWWWWggbbpp..",
		"..ppbbbgWWWWWWWWWWWWWWgbbbpp..",
		".ommssbbWWWWWWWWWWWWWWbbssmmo.",
		"oomsssbbWWWWWWWWWWWWWWbbsssmoo",
		"oosssbbccWWWWWWWWWWWWccbbsssoo",
		".ossbbcccccWWWWWWWWcccccbbsso.",
		".oooppgggcccggccggcccgggppooo.",
		"...oppggggccggccggccggggppo...",
		"....ppcgggccccccccccgggcpp....",
		"....ppccggccccccccccggccpp....",
		"....oEEEeeeeeeyyeeeeeeEEoo....",
		"....oEEEeeeeeeyyeeeeeeEoo.....",
		"....obbbggggggggggggbbbo......",
		"....obbbgggggggggggggbbo......",
		"....oobbgggggo..oggggbbboo....",
		".....obbgggggo..ogggggbboo....",
		".....ooofffffo..offfffooo.....",
		"......offffffo..offffffo......",
		"......offffffo..offffffo......",
		"......offffffo..offffffo......",
		"......oFFFFFFo..oFFFFFFo......",
		"......oooFFooo..oooFFooo......",
		"......oooFFooo..oooFFooo......",
		".......oooooo....oooooo.......",
	],
	&"guardian": [
		".......onnnnnnnnnnnnnno.......",
		"......oonnnnnnnnnnnnnnoo......",
		"...ouuttttTTssssssTTttttuuo...",
		".ooouutttTTTssssssTTTtttuuooo.",
		"oottTTTTTTTWWWccWWWTTTTTTTTToo",
		"oottTTTTTTWWWWccWWWWTTTTTTTToo",
		".oooTTTTttWWWWccWWWWttTTTTToo.",
		"..oTTTTtttWWWWccWWWWtttTTTTo..",
		"..ppTTtttTWWWWccWWWWTtttTTpp..",
		"..ppTTttTTWWWWccWWWWTTttTTpp..",
		".ommssooTTWWWWccWWWWTToossmmo.",
		"oomsssooTTWWWWccWWWWTToosssmoo",
		"oosssboottWWWWccWWWWttoobsssoo",
		".ossbbootttWWWccWWWtttoobbsso.",
		".oooppTTTttWWWccWWWttTTTppooo.",
		"...oppTTTTTtWWccWWtTTTTTppo...",
		"....ppTTTTTTWWccWWTTTTTTpp....",
		"....ppTTTTTTWWccWWTTTTTTpp....",
		"....oEEEeeeeeeyyeeeeeeEEEo....",
		"....oEEEeeeeeeyyeeeeeeEEEo....",
		"....oKKKkkkkkkkkkkkkkkKKKo....",
		"....oKKKkkkkkkkkkkkkkkKKKo....",
		"....ooKKkkkkko..okkkkkKKoo....",
		".....oKKkkkkko..okkkkkKKo.....",
		".....ooouuttto..ouuuttooo.....",
		"......ouutttto..ouutttto......",
		"......ottttTTo..ottttTTo......",
		"......ottTTTTo..ottTTTTo......",
		"......oTTTTTTo..oTTTTTTo......",
		"......oooTTooo..oooTTooo......",
		"......oooTTooo..oooTTooo......",
		".......oooooo....oooooo.......",
	],
}
## Hair styles (HunterAppearance.hair_style): front rows from HAIR_TOP; "back" = last head row
## covered at the back (texel rows). Short messy, long, ponytail, bob, spiky, bun, side swept, twin tails,
## buzz cut, curly. Symbols: o outline, L H D hair (light → dark).
const HAIR_STYLES := [
	{"back": 19, "rows": [
		"..............................",
		"..............................",
		"..........oo....oo..oo........",
		".........oooo..ooo..ooo.......",
		".......oooLLooooLLooLLo.......",
		".....oooLLLLLLLLLLLLLLLoo.....",
		".....oLLLLLLLLLLLLLLLLLLo.....",
		"...ooLLLLLLLLLLLLLLLLLLLooo...",
		"...oLLLLLHHHHHHHHHHHHHHHHHo...",
		"..ooLLLHHHHHHHHHHHHHHHHHHHooo.",
		"..oLLLLHHHLLLHLLLHLLHHHHHHDDo.",
		".ooLLHHHLLHLLLHLLLHLHHHHHHDDoo",
		".oLLLHHHHHHHHHHHHHHHHHHHHHDDDo",
		"ooLHHHHHHHHHHHHHHHHHHHHHHHDDDo",
		"oHHHHHHHHHHHHHHHHHHHHHHHHHDDDo",
		"oHHHHHHHHHHHHHHHHHHHHHHHHHDDDo",
		"oHHHHHDDHHHHDDHHHHHHDDHHHHDDDo",
		"oHHHHDDDHHHDDDDHHHHHDDHHHHDDDo",
		"oHHHHDDDHHHDDoDHHHHoDDHHHoDDDo",
		"oHHDDooooHDDoooDHHoooDHHooDDDo",
		"ooDDDo..oo...ooo...ooo..ooDDoo",
		".oDDo...oo....oo....oo...oDDo.",
		".oooo....................oooo.",
		"..oo......................oo..",
	]},
	{"back": 25, "rows": [
		"..............................",
		"..............................",
		"..............................",
		"..............................",
		".........oooooooooooo.........",
		".......oooLLLLLLHHHHoo........",
		".......oLLLLLLLLHHHHHHHHo.....",
		".....ooLLLLLLLLHHHHHHHHHooo...",
		".....oLLLLLLLHHHHHHHHHHHDDo...",
		"...ooLLLLLLHHHHHHHHHHHHHHDDoo.",
		"...oLLLLLHHHHHHHHHHHHHHHHDDDo.",
		"..ooLLLHHHHHHHHHHHHHHHHHHHDDoo",
		"..oLLLLHHHLLLHLLLHLLHHHHHHDDDo",
		".ooLLHHHLLHLLLHLLLHLHHHHHHDDDo",
		".oLLLHHHHHHHHHHHHHHHHHHHHHDDDo",
		"ooLHHHHHHHHHHHHHHHHHHHHHHHDDDo",
		"oHHHHHHHHHHHHHHHHHHHHHHHHHDDDo",
		"oHHHHHHHHHHHHHHHHHHHHHHHHHDDDo",
		"oHHHHHHDDHHHHHHHHHHHHDDHHHDDDo",
		"oHHHHDDDDDHHHHHHHHHHDDDDHHDDDo",
		"oHHHHDDo..............oDDDDDDo",
		"oHHHDDo................oDDDDDo",
		"oHHHDD..................DDDHHo",
		"oHHHDD..................DDHHHo",
		"oHHHDD..................DDHHHo",
		"oHHHDD..................DDHHHo",
		"oHHHDD..................DDHHHo",
		"oHHHHDD................DDHHHHo",
		"oHHHHDD................DDHHHHo",
		"oHHHHHDD..............DDHHHHHo",
		"oHHHHHDDo............oDDHHHHHo",
		"oHHHHDDDoo..........ooDDDHHHHo",
		"oHHHHDDDoo..........ooDDDHHHHo",
		"oHHDDDDDo............oDDDDDHHo",
		"ooDDDDDoo............ooDDDDDoo",
		".oDDDDo................oDDDDo.",
		".oooooo................oooooo.",
		"...oo....................oo...",
	]},
	{"back": 21, "rows": [
		".......................oooo...",
		".....................oooHHooo.",
		".....................oLLHHDDoo",
		"...................oooLHHDDDoo",
		".........oooooooooooHHHHHDDoo.",
		".......oooLLLLLLLLLoHHHDDDDo..",
		".......oLLLLLLLLLLLLHHDDDDDo..",
		".....ooLLLLLLLLLLLLHHHDDDDDo..",
		".....oLLLLLHHHHHHHHHHHHDDDDo..",
		"...ooLLLLHHHHHHHHHHHHHHHHDDoo.",
		"...oLLLHHHHHHHHHHHHHHHHHHDDDo.",
		"..ooLLHHHHHHHHHHHHHHHHHHHHDDoo",
		"..oLLLHHHHHHHHHHHHHHHHHHHHDDDo",
		".ooLLHHHHHHHHHHHHHHHHHHHHHDDDo",
		".oLLLHHHHHHHHHHHHHHHHHHHHHDDDo",
		"ooLHHHHHHHHHHHHHHHHHHHHHHHDDDo",
		"oHHHHHHHHHHHHHHHHHHHHHHHHHDDDo",
		"oHHHHHHHHHHHHHHHHHHHHHHHHDDDDo",
		"oHHHDDHHHHDDHHHHHHDDHHHHHDDDDo",
		"oHHDDDHHHHDDHHHHHHDDHHHHDDDDDo",
		"ooDDDo..ooDDoo....oo..ooDDDDoo",
		".oDDo....oDDo.....oo...oDDDDo.",
		".oooo..................oooooo.",
		"..oo.....................oo...",
	]},
	{"back": 23, "rows": [
		"..............................",
		"..............................",
		"..............................",
		"..............................",
		".........oooooooooooo.........",
		".......oooLLLLLLLLLLooo.......",
		".......oLLLLLLLLLLLLLLo.......",
		".....ooLLLLLLLLLLLLLLLooo.....",
		".....oLLLLLHHHHHHHHHHHHHo.....",
		"...ooLLLLHHHHHHHHHHHHHHHooo...",
		"...oLLLHHHHHHHHHHHHHHHHHDDo...",
		".ooLLHHHHHHHHHHHHHHHHHHHHDDoo.",
		".oLLLHHHLLLHLLLHLLLHHHHHHDDDo.",
		"ooLHHHLLHLLLHLLLHLLLHHHHHHDDoo",
		"oHHHHHHHHHHHHHHHHHHHHHHHHHDDDo",
		"oHHHHHHHHHHHHHHHHHHHHHHHHHDDDo",
		"oHHHHHHHHHHHHHHHHHHHHHHHHHDDDo",
		"oHHHHHHHHHHHHHHHHHHHHHHHHDDDDo",
		"oHHHHDDDDDDDDDDDDDDDDDDDDDDDDo",
		"oHHHDDDDDDDDDDDDDDDDDDDDDDDDDo",
		"oHHHDDD................DDDDHHo",
		"oHHHDD..................DDHHHo",
		"oHHHDD..................DDHHHo",
		"oHHHDD..................DDHHHo",
		"oHHHDD..................DDHHHo",
		"oHHDDD..................DDDHHo",
		"ooDDDD..................DDDDoo",
		".oDDDD..................DDDDo.",
		".ooooo..................ooooo.",
		"...oo....................oo...",
	]},
	{"back": 19, "rows": [
		"....oo....oo......oo....oo....",
		"....oo...ooo......ooo...oo....",
		"....ooLLooooLLooLLLoooLLoo....",
		"...ooLLLLooLLLLLLLLLoLLLooo...",
		"..ooLLLLoooLLLLLLLLLLLLLDDoo..",
		"..ooLLLLooLLLLLLLLLLLLLLDDoo..",
		"....oLLLLLLLLLLLLLLLLHHHHo....",
		"....oLLLLLLLLLLLLLLHHHHHHo....",
		"...ooLLLLHHHHHHHHHHHHHHHHoo...",
		".ooLLLLHHHLLLHLLLHLLHHHHHHooo.",
		"ooLLLLLHHHLLHLLLHLLLHHHHHHDDoo",
		"ooLLLHHHHHHHHHHHHHHHHHHHHDDDoo",
		"..oHHHHHHHHHHHHHHHHHHHHHDDDo..",
		"..oHHHHHHHHHHHHHHHHHHHHHDDDo..",
		".ooHHHHHHHHHHHHHHHHHHHHHHHDoo.",
		"ooHHHHHHHHHHHHHHHHHHHHHHHHDDoo",
		"ooHHDDHHHHHHHHDDHHHHHHHHHDDDoo",
		".oHHDDHHHHHHHHDDDHHHHHHDDDDDo.",
		".oooDDHHHHHDoHDDDHHHHHDDDDDoo.",
		"...oDDoooHDDooooDDHooooDDDo...",
		"...ooo..ooooo..ooooo..ooooo...",
		"....oo...oo......oo....oo.....",
		"..............................",
		"..............................",
	]},
	{"back": 21, "rows": [
		"...........oooooooo...........",
		".........oooLLHHHHooo.........",
		".........oLLLLHHHHDDo.........",
		"........ooLLLHHHHHDDoo........",
		"........oHHHHHHHHHDDDo........",
		".......ooooHHHHHHHDoooo.......",
		".......oooooooooooooooo.......",
		".....oooooooooooooooooooo.....",
		".....oLLLLLLLLLLLLHHHHHHo.....",
		"...ooLLLLLLLLLLLLHHHHHHHooo...",
		"...oLLLHHHHHHHHHHHHHHHHHDDo...",
		".ooLLHHHHHHHHHHHHHHHHHHHHDDoo.",
		".oLLLHHHHHHHHHHHHHHHHHHHHDDDo.",
		"ooLHHHHHHHHHHHHHHHHHHHHHHHDDoo",
		"oHHHHHHHHHHHHHHHHHHHHHHHHHDDDo",
		"oHHHHHHHHHHHHHHHHHHHHHHHHDDDDo",
		"oHHHHHHHHHHHHHHHHHHHHHHHHDDDDo",
		"oHHHHHHHHHHHHHHHHHHHHHHDDDDDDo",
		"oHHHHDDDoo..........ooDDDDDDDo",
		"oHHDDDDDo............oDDDDDDDo",
		"ooDDDo..................oDDDoo",
		".oDDo....................oDDo.",
		".oooo....................oooo.",
		"..oo......................oo..",
	]},
	{"back": 21, "rows": [
		"..............................",
		"..............................",
		"..............................",
		"..............................",
		".........oooooooooooo.........",
		".......oooLLLLLLLLLLooo.......",
		".......oLLLLLLLLLLLLLLooo.....",
		".....ooLLLLLLLLLLLLLLLoHooo...",
		".....oLLLLLLLLLLLHHHHHHHHHo...",
		"...ooLLLLLLLLLLHHHHHHHHHHHooo.",
		"...oLLLHHHLLLHLLLHLLHHHHHHDDo.",
		".ooLLHHHLLHLLLHLLLHLHHHHHHDDoo",
		".oLLLHHHHHHHHHHHHHHHHHHHHHDDDo",
		"ooLHHHHHHHHHHHHHHHHHHHHHHHDDDo",
		"oHHHHHHHHHHHHHHHHHHHHHHHHHDDDo",
		"oHHHHHHHHHHHHHHHHHHHHHHHHDDDDo",
		"oHHHHHHHHHHHHHHHHHHHHHHHHDDDDo",
		"oHHHHHHHHHHHHHHHHHHHHHHHDDDDDo",
		"oHHHHHHHHHHHHHHDDDDDoo..oDDDDo",
		"oHHHHHHHHHHHHHDDDDDDo...oDDDDo",
		"oHHHHHHDDDDDoo..........ooDDoo",
		"oHHHHDDDDDDDo............oDDo.",
		"ooDDDDDo.................oooo.",
		".oDDDDo...................oo..",
		".oooooo.......................",
		"...oo.........................",
	]},
	{"back": 21, "rows": [
		"..............................",
		"..............................",
		"..............................",
		"..............................",
		".........oooooooooooo.........",
		".......oooLLLLLLLLLLooo.......",
		".......oLLLLLLLLLLLLLLo.......",
		".....ooLLLLLLLLLLLLLLLooo.....",
		".....oLLLLLHHHHHHHHHHHHHo.....",
		"...ooLLLLHHHHHHHHHHHHHHHooo...",
		"...oLLLHHHHHHHHHHHHHHHHHDDo...",
		".ooLLHHHHHHHHHHHHHHHHHHHHDDoo.",
		".oLLLHHHHHHHHHHHHHHHHHHHHDDDo.",
		"ooLHHHLLLHLLLHLLLHLLHHHHHHDDoo",
		"oHHHLLHLLLHLLLHLLLHLHHHHHHDDDo",
		"oHHHHHHHHHHHHHHHHHHHHHHHHHDDDo",
		"oHHHHHDDHHHHHHDDHHHHHHDDHHDDDo",
		"oHHHHDDDHHHHHDDDDHHHHHDDHHDDDo",
		"oHHHHDDDHHHHHDDDDHHHHHDDDDDDDo",
		"oooHDoooooHHDDooDDHHoooooDDooo",
		"ooooDo..................oDoooo",
		"ooooHo..................oHoooo",
		"oooLHoo................ooHDooo",
		"oLLHHHoo..............ooHHDDDo",
		"oHHHHHHo..............oHHHDDDo",
		"oHHHHHHo..............oHHHDDDo",
		"oHHHHDDo..............oHHHDDDo",
		"oHHHDDDo..............oHHDDDDo",
		"ooHHDDDo..............oDDDDDoo",
		".oHHHDDoo............ooDDDDDo.",
		".ooHHDDDoo..........ooDDDDDoo.",
		"...oHHDDoo..........ooDDDDo...",
		"...oooooo............oooooo...",
		".....oo................oo.....",
	]},
	{"back": 17, "rows": [
		"..............................",
		"..............................",
		"..............................",
		"..............................",
		".........oooooooooooo.........",
		".......oooLLLLLLHHHHooo.......",
		".......oLLLLLLLLHHHHHHo.......",
		".....ooLLLLLLLLHHHHHHHooo.....",
		".....oLLLHHHLLHLHHHHHHDDo.....",
		"...ooLLHHHHHHHHHHHHHHHHDDoo...",
		"...oLLLHHHHHHHHHHHHHHHHDDDo...",
		"..ooLHHHHHHHHHHHHHHHHHHHDDoo..",
		"..oHHHHHHHHHHHHHHHHHHHHHDDDo..",
		"..oHHHHHHHHHHHHHHHHHHHHHDDDo..",
		"..oHHHHHDDHHHHHHHHDDHHHHDDDo..",
		"..oHHHHHDDHHHHHHHHDDHHHHDDDo..",
		"..ooDDoo..oo......oo..ooDDoo..",
		"...oDDo...oo......oo...oDDo...",
		"...oooo................oooo...",
		"....oo..................oo....",
	]},
	{"back": 23, "rows": [
		".........oo....oo....oo.......",
		".......ooooo..oooo..ooooo.....",
		".....oooLLLooooLLooooHHHooo...",
		"...oooLLLLLLLLLLLLHHHHHHHHooo.",
		"...oLLLLLLLLLLLLLHHHHHHHHHDDo.",
		".ooLLLLLLLLLLLLHHHHHHHHHHHDDoo",
		".oLLLLLLLHHHLLLHLLLHHHHHHHDDDo",
		"ooLLLLLHHHLLHLLLHLLLHHHHHHDDDo",
		"oLLLLHHHHHHHHHHHHHHHHHHHHHDDDo",
		"oLLHHHHHHHHHHHHHHHHHHHHHHHDDDo",
		"oHHHHHHHHHHHHHHHHHHHHHHHHHDDDo",
		"oHHHHHHHHHHHHHHHHHHHHHHHHHDDDo",
		"oHHHHHHHHHHHHHHHHHHHHHHHHHDDDo",
		"oHHHHHHHHHHHHHHHHHHHHHHHHHDDDo",
		"oHHHHHDDHHHHHHHHHHHHDDHHHHDDDo",
		"oHHHHDDDHHHHHHHHHHHHDDDHHDDDDo",
		"oHHHHDDoHHHDoHHHHDoHHDHDDDDDDo",
		"oHHHDDooHHDoooHHDoooHHDDDDDDDo",
		"oHHHDDoo..ooo...ooo...oDDDDDDo",
		"oHHHDDo...oo....oo.....oDDDDDo",
		"oHHHDD..................DDHHHo",
		"oHHDDD..................DDHHHo",
		"ooDDDDoo..............ooDDDDoo",
		".oDDDDoo..............ooDDDDo.",
		".oooooo................oooooo.",
		"...oo....................oo...",
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


## Hair, face and shoulders for UI portraits (PORTRAIT_RECT size, 34×38 texels).
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


## One 64×96 frame: every part moved by the frame's offsets (ChibiAnimations.resolve_offsets, in
## world pixels, × SCALE). Gaps opened between parts are filled by repeating the edge row (chin,
## top of the legs).
static func compose(look: HunterAppearance, view: View, frame: Dictionary, outfit: StringName = &"") -> Image:
	var offsets := _scaled(ChibiAnimations.resolve_offsets(frame, view == View.SIDE))
	var map := body_map(view, outfit)
	var palette := palette_for(look, outfit)
	var lying: bool = frame.get("lying", false)
	var canvas := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8) if not lying \
		else Image.create(BODY_SIZE.x + 16, BODY_SIZE.y + 16, false, Image.FORMAT_RGBA8)
	var origin := BODY_ORIGIN if not lying else Vector2i(8, 8)
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
	var lift: int = int(frame.get("lift", 0)) * SCALE
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
			for y in [TORSO_ROW + 2, TORSO_ROW + 3]:
				rows[y] = _replace_cols(rows[y], 12, String(rows[TORSO_ROW + 4]).substr(12, 6))
		else:
			for y in range(EYE_ROWS.x, EYE_ROWS.y + 1):
				var front: String = BODY[y]
				var row: String = face[y]
				row = _replace_cols(row, EYE_LEFT_COL + SIDE_EYE_SHIFT.x, front.substr(EYE_LEFT_COL, EYE_WIDTH))
				row = _replace_cols(row, EYE_RIGHT_COL + SIDE_EYE_SHIFT.y, front.substr(EYE_RIGHT_COL, EYE_WIDTH))
				face[y] = row
			# Far (left) ear hidden behind the head.
			for y in range(EYE_ROWS.x, EYE_ROWS.y + 1):
				face[y] = _replace_cols(face[y], 0, "..oo")
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
		if view == View.SIDE and head_row > FRINGE_END_ROW:
			row = row.substr(0, SIDE_BACK_COL + 1) + ".".repeat(row.length() - SIDE_BACK_COL - 1)
		if first >= 0 and (head_row <= back_len or head_row > LONG_HAIR_ROW):
			var right := last
			if view == View.SIDE:
				right = mini(last, SIDE_BACK_COL if head_row <= FRINGE_END_ROW else SIDE_NAPE_COL)
			for x in range(first, right + 1):
				if row[x] == ".":
					row[x] = "D" if head_row == back_len or x >= HAIR_SHADE_COL else "H"
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
	var blush: Color = skin[0].lerp(Color("ff8c96"), 0.3)
	return {
		"o": OUTLINE, "r": EYE_LID, "w": EYE_WHITE, "i": hair[1], "l": blush,
		"h": skin[0], "s": skin[1], "m": skin[2], "d": skin[3], "n": skin[4],
		"W": cloth[0], "c": cloth[1], "g": cloth[2], "b": cloth[3], "p": cloth[4],
		"k": dye, "K": dye.darkened(0.35),
		"y": TRIM, "Y": TRIM_DARK, "e": LEATHER, "E": LEATHER_DARK,
		"t": METAL, "T": METAL_DARK, "u": METAL_SHINE, "f": BOOT, "F": BOOT_LIGHT,
		"L": hair[0], "H": hair[1], "D": hair[2],
	}


## Off hand (bottom of the left arm, shield) relative to the feet in world pixels, unmirrored.
## `arm` is the arm's frame offset in world pixels.
static func off_hand_position(view: View, arm: Vector2i) -> Vector2:
	var hand := Vector2i(BODY_SIZE.x - SCALE - HAND.x, HAND.y)
	if view == View.BACK:
		hand.x = HAND.x
	return _texel_to_world(hand, arm)


## Hand position relative to the feet in world pixels for arm offset `arm` (world pixels),
## unmirrored (side view faces right).
static func hand_position(view: View, arm: Vector2i) -> Vector2:
	var hand := HAND
	if view == View.BACK:
		# Seen from behind, the weapon hand is on the screen-left side.
		hand.x = BODY_SIZE.x - SCALE - HAND.x
	return _texel_to_world(hand, arm)


## Centre of the SCALE×SCALE texel block at body-map `texel` moved by `offset` world pixels,
## relative to the feet, in world pixels.
static func _texel_to_world(texel: Vector2i, offset: Vector2i) -> Vector2:
	return (Vector2(BODY_ORIGIN + texel + offset * SCALE - FEET) + Vector2.ONE * SCALE * 0.5) / SCALE


## Frame offsets (world pixels) as texel offsets.
static func _scaled(offsets: Dictionary) -> Dictionary:
	var result := {}
	for part in offsets:
		var offset: Vector2i = offsets[part]
		result[part] = offset * SCALE
	return result


static func _clear_face(rows: Array) -> Array:
	var result := rows.duplicate()
	for y in range(EYE_ROWS.x, EYE_ROWS.y + 1):
		var row: String = result[y]
		for x in range(6, 24):
			if row[x] in ["o", "w", "W", "r", "i", "l"]:
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
