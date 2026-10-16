class_name HunterAppearance
extends RefCounted
## Look of one Hunter (CHARACTER_DESIGN.md §12, DECISIONS.md D47). Plain values only.
## The Forge body (D73) draws skin, dye (shorts), hair style and hair colour (eyes follow it); gender is
## kept in saves for a future body-type layer. The outfit is not stored here: the sprite follows the Hunter's
## base class (ChibiBody.outfit_for).

const MALE := &"male"
const FEMALE := &"female"
## Catalog sizes (skins match ChibiBody.SKINS, dyes the accent palette, hair styles ForgeLook.HAIR_IDS:
## 0–9 the D51 styles, 10–17 added by the Forge, D73).
const HAIR_STYLE_COUNT := 18
const HAIR_COLOR_COUNT := 10
const SKIN_COUNT := 4
const DYE_COUNT := 8

var gender: StringName = MALE
var hair_style: int = 0
var hair_color: int = 0
var skin: int = 0
var dye: int = 0


func to_dict() -> Dictionary:
	return {"gender": gender, "hair_style": hair_style, "hair_color": hair_color, "skin": skin, "dye": dye}


## Sanitized copy of saved data; out-of-range values are wrapped into the catalog.
static func from_dict(data: Dictionary) -> HunterAppearance:
	var look := HunterAppearance.new()
	look.gender = FEMALE if str(data.get("gender", "")) == String(FEMALE) else MALE
	look.hair_style = posmod(int(data.get("hair_style", 0)), HAIR_STYLE_COUNT)
	look.hair_color = posmod(int(data.get("hair_color", 0)), HAIR_COLOR_COUNT)
	look.skin = posmod(int(data.get("skin", 0)), SKIN_COUNT)
	look.dye = posmod(int(data.get("dye", 0)), DYE_COUNT)
	return look


## Deterministic random look from any seed text (new recruits, saves made before D47).
## Does not consume the caller's RNG, so recruitment rolls stay unchanged.
static func from_seed(seed_text: String, dye_index: int) -> HunterAppearance:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_text)
	var look := HunterAppearance.new()
	look.gender = FEMALE if rng.randi_range(0, 1) == 1 else MALE
	look.hair_style = rng.randi_range(0, HAIR_STYLE_COUNT - 1)
	look.hair_color = rng.randi_range(0, HAIR_COLOR_COUNT - 1)
	# Most recruits keep the reference skin tone.
	look.skin = 0 if rng.randf() < 0.55 else rng.randi_range(1, SKIN_COUNT - 1)
	look.dye = posmod(dye_index, DYE_COUNT)
	return look


## Cache key for composed sprites.
func key() -> String:
	return "%s:%d:%d:%d:%d" % [gender, hair_style, hair_color, skin, dye]
