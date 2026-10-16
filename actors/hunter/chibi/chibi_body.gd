class_name ChibiBody
extends RefCounted
## What is left of the D49/D67 chibi body once the Pixel Hero Forge drew the Hunters (D73, PHASE_13 step 7):
## the look's colour tables (skin tones, hair colours: ForgeLook builds the Forge ramps from them), the class
## of a Hunter's outfit, hat styles of helmets, and the View enum still used by the monster bodies. The old
## body, outfit, hair and hat pixel maps are gone (no parallel fallback, D73 / Q6).

enum View { FRONT, BACK, SIDE }

## Skin tones [light, base, shadow, deep, darkest, blush] per HunterAppearance.skin; the Forge uses the base.
const SKINS := [
	[Color("ffe6d8"), Color("fbcbb9"), Color("e8977f"), Color("c47c71"), Color("814721"), Color("f7a4a6")],
	[Color("f8d8b0"), Color("e8b48a"), Color("c98a63"), Color("a5674a"), Color("6e3f22"), Color("e8977f")],
	[Color("dcaa84"), Color("c18560"), Color("9c6243"), Color("7a4a32"), Color("4e2a18"), Color("c87462")],
	[Color("ac7a5c"), Color("8a5a3e"), Color("6b432c"), Color("52311f"), Color("33190c"), Color("9a5a4a")],
]
## Hair colours [light, base, dark] per HunterAppearance.hair_color; eyes take the dark one, darkened (D51).
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
## Words in a helmet's id → hat style (when its `look_id` names none).
const HAT_WORDS := [["crown", &"crown"], ["wizard", &"wizard"], ["cowboy", &"cowboy"], ["viking", &"viking"], ["beanie", &"beanie"],
	["nonla", &"nonla"], ["straw", &"nonla"], ["hat", &"wizard"], ["hood", &"hood"], ["cap", &"cap"]]
## Hat of a helmet that names no style.
const DEFAULT_HAT := &"helm"


## Hat style of a helmet: its `look_id` when it names a Forge hat, else a style named in its id, else a
## metal helm.
static func hat_style_for(item: ItemDefinition) -> StringName:
	if item == null:
		return &""
	if ForgeLook.style_for("hat", item.look_id) != "":
		return item.look_id
	var id := String(item.id)
	for pair: Array in HAT_WORDS:
		if id.contains(pair[0]):
			return pair[1]
	return DEFAULT_HAT


## Outfit of a Hunter class: subclasses wear their base class's outfit; unknown classes the core tank
## top and shorts.
static func outfit_for(definition: HunterDefinition) -> StringName:
	if definition == null:
		return &""
	var base: StringName = definition.class_id
	if definition.promotion_of != &"":
		base = definition.promotion_of
	return base if ForgeLook.has_outfit(base) else &""


## View of a facing for the monster bodies (Hunters: ChibiVisual mirrors one 3/4 view and has a rear view).
static func view_of(facing: Facing.Direction) -> View:
	match facing:
		Facing.Direction.UP:
			return View.BACK
		Facing.Direction.LEFT, Facing.Direction.RIGHT:
			return View.SIDE
	return View.FRONT
