class_name ForgeLook
extends RefCounted
## Game data → Pixel Hero Forge look (D73, PHASE_13 §3.6), and the cache of baked frames shared by every
## Hunter that looks the same.
## Look: skin, hair colour (eyes follow it, D51), hair style, dye (the core shorts). Dress: the class outfit
## (CLASS_LOOKS), the gear's colours, and item `look_id`s naming a Forge top / pants / shoes / hat, or
## glasses on an accessory (`glasses_<id>`). Weapons: Forge weapon by item, or by class; the element of
## its effects comes from a `look_id` suffix (`_fire`, `_ice`...).

## HunterAppearance.hair_style → Forge hair (0–9 keep the D51 styles' slots, 10–17 are new).
const HAIR_IDS := ["short", "spiky", "buzz", "sweep", "hero", "bob", "long", "pony", "twin", "bun",
	"quiff", "mohawk", "afro", "pixie", "hime", "wavy", "braid", "buns"]
## Base class → [top, top colour, pants, pants colour, shoes, shoes colour]; "" = the Forge item's colour.
const CLASS_LOOKS := {
	&"warrior": ["armor", "", "armor", "", "armor", ""],
	&"berserker": ["armor", "", "armor", "", "armor", ""],
	&"ranger": ["jacket", "#5f8236", "cargo", "", "boots", ""],
	&"rogue": ["hoodie", "#52456c", "jeans", "#2b2630", "leather", ""],
	&"guardian": ["knight", "", "armor", "", "armor", ""],
	&"paladin": ["knight", "", "armor", "", "armor", ""],
	&"sorcerer": ["robe", "#3d5a9e", "jeans", "#2b2630", "boots", "", "wizard", "#5b3fa0"],
	&"mage": ["robe", "#3d5a9e", "jeans", "#2b2630", "boots", "", "wizard", "#5b3fa0"],
}
const CORE_LOOK := ["none", "", "none", "", "none", ""]
## Skin `outfit_id`s that name no class pattern → Forge top.
const TOP_ALIASES := {&"iron_plate": "armor", &"light_leather": "leather"}
## Gear worn over the core body (no class pattern) when the item names no style.
const DEFAULT_PANTS := "jeans"
const DEFAULT_SHOES := "boots"
const TANK := "#ecebe4"
const HAIR_ACCENT := "#e0507a"
const GLASSES_PREFIX := "glasses_"
## WeaponSprites kind → Forge weapon (Hunters only; monsters keep WeaponSprites).
const SPRITE_WEAPONS := {
	&"sword": "sword", &"greatsword": "great", &"curved": "katana", &"dagger": "dagger", &"fang": "dagger",
	&"bow": "bow", &"mace": "hammer", &"club": "hammer", &"bone": "hammer", &"shadow": "sword",
}
## Words in a weapon id → Forge weapon (kinds WeaponSprites does not know).
const WEAPON_WORDS := [["katana", "katana"], ["axe", "axe"], ["spear", "spear"], ["lance", "spear"],
	["staff", "staff"], ["wand", "staff"], ["rod", "staff"]]
const CLASS_WEAPONS := {
	&"warrior": "sword", &"berserker": "great", &"ranger": "bow", &"rogue": "dagger",
	&"guardian": "hammer", &"paladin": "hammer", &"sorcerer": "staff", &"mage": "staff",
}
const ELEMENTS := ["fire", "ice", "thunder", "poison", "shadow"]
## Status effect a skill applies → element of its effects (D73 / Q5), first match wins.
const EFFECT_ELEMENTS := {
	&"burn": "fire", &"freeze": "ice", &"slow": "ice", &"stun": "thunder", &"stagger": "thunder",
	&"poison": "poison", &"weaken": "shadow", &"vulnerable": "shadow", &"lifesteal": "shadow",
}
## UI portrait: hair, face and shoulders, world px from the feet (27×29 like the D67 portrait).
const PORTRAIT := Rect2(-14, -40, 27, 29)
## Baked frames kept before the cache starts over.
const CACHE_LIMIT := 4000

static var _frames: Dictionary = {}
static var _sequences: Dictionary = {}


## Whether a base class has its own outfit (a skin's `outfit_id` may name one).
static func has_outfit(base_class: StringName) -> bool:
	return CLASS_LOOKS.has(base_class)


## Forge config (ForgeComposer cfg) of a look, dress, weapon (Forge id) and element.
## `weapon_tint` Color.WHITE = the Forge weapon's own colour.
static func config(look: HunterAppearance, dress: ChibiDress = null, weapon := "none", weapon_tint := Color.WHITE,
		element := "none") -> Dictionary:
	var skin: Array = ChibiBody.SKINS[posmod(look.skin, ChibiBody.SKINS.size())]
	var hair: Array = ChibiBody.HAIR_COLORS[posmod(look.hair_color, ChibiBody.HAIR_COLORS.size())]
	var dye: Color = PlaceholderVisual.ACCENT_PALETTE[posmod(look.dye, PlaceholderVisual.ACCENT_PALETTE.size())]
	var outfit: StringName = dress.outfit if dress != null else &""
	var style: Array = CLASS_LOOKS.get(outfit, CORE_LOOK)
	var top: String = style[0]
	var top_color: String = style[1]
	var pants: String = style[2]
	var pants_color: String = style[3]
	var shoes: String = style[4]
	var shoes_color: String = style[5]
	var tank := TANK
	var hat: String = style[6] if style.size() > 6 else "none"
	var hat_color: String = style[7] if style.size() > 7 else ""
	var glasses := "none"
	var glasses_color := ""
	if dress != null:
		if dress.top != &"":
			top = dress.top
		if dress.has_cloth:
			top_color = _hex(dress.cloth)
			tank = top_color
		if dress.has_pants:
			pants_color = _hex(dress.pants)
			if pants == "none":
				pants = DEFAULT_PANTS
		if dress.pants_style != &"":
			pants = dress.pants_style
		if dress.has_boots:
			shoes_color = _hex(dress.boots)
			if shoes == "none":
				shoes = DEFAULT_SHOES
		if dress.boots_style != &"":
			shoes = dress.boots_style
		if dress.hat != &"" and ForgeData.has_item("hat", dress.hat):
			hat = dress.hat
			hat_color = _tint(dress.hat_tint)
		if dress.glasses != &"" and ForgeData.has_item("glasses", dress.glasses):
			glasses = dress.glasses
			glasses_color = _tint(dress.glasses_tint)
	return {
		"skin": _hex(skin[1]), "eyes": _hex(hair[2].darkened(0.45)), "tank": tank, "shorts": _hex(dye), "black": true,
		"hair": {"id": HAIR_IDS[posmod(look.hair_style, HAIR_IDS.size())], "color": _hex(hair[1]), "accent": HAIR_ACCENT},
		"shirt": _select("shirt", top, top_color),
		"pants": _select("pants", pants, pants_color),
		"shoes": _select("shoes", shoes, shoes_color),
		"glasses": _select("glasses", glasses, glasses_color),
		"hat": _select("hat", hat, hat_color),
		"weapon": _select("weapon", weapon, _tint(weapon_tint)),
		"fx": element,
	}


## Item choice with its colours (HTML `sel`): `color` "" = the item's own.
static func _select(category: String, id: String, color: String) -> Dictionary:
	var item := ForgeData.find_item(category, id)
	var own: String = item.get("color", "#888888")
	return {"id": item["id"], "color": color if color != "" else own, "accent": item.get("accent", own)}


static func _hex(color: Color) -> String:
	return "#" + color.to_html(false)


static func _tint(color: Color) -> String:
	return "" if color == Color.WHITE else _hex(color)


static func key_of(cfg: Dictionary) -> String:
	return JSON.stringify(cfg)


## Forge top named by a skin's `outfit_id` or an item's `look_id`; "" = none.
static func top_for(id: StringName) -> String:
	if TOP_ALIASES.has(id):
		return TOP_ALIASES[id]
	return String(id) if id != &"none" and ForgeData.has_item("shirt", id) else ""


## Forge item of a category named by a `look_id`; "" = none.
static func style_for(category: String, id: StringName) -> String:
	return String(id) if id != &"none" and ForgeData.has_item(category, id) else ""


## Glasses of an accessory (`look_id` = glasses_<round|square|sun|goggle|patch>); "" = none.
static func glasses_for(item: ItemDefinition) -> String:
	if item == null or not String(item.look_id).begins_with(GLASSES_PREFIX):
		return ""
	return style_for("glasses", StringName(String(item.look_id).trim_prefix(GLASSES_PREFIX)))


## Forge weapon of an equipped item: its `look_id` (before an element suffix), a word in its id, its
## WeaponSprites kind, else the class weapon.
static func weapon_for(item: ItemDefinition, base_class: StringName) -> String:
	var fallback: String = CLASS_WEAPONS.get(base_class, "sword")
	if item == null:
		return fallback
	var named := style_for("weapon", StringName(String(item.look_id).get_slice("_", 0)))
	if named != "":
		return named
	var id := String(item.id)
	for pair: Array in WEAPON_WORDS:
		if id.contains(pair[0]):
			return pair[1]
	var kind := WeaponSprites.kind_for_item(item, &"")
	return SPRITE_WEAPONS.get(kind, fallback)


## Element of a weapon's attack effects (D73 / Q5): the `look_id` suffix, else none.
static func element_for(item: ItemDefinition) -> String:
	if item == null:
		return "none"
	var look := String(item.look_id)
	var suffix := look.get_slice("_", look.get_slice_count("_") - 1)
	return suffix if suffix in ELEMENTS else "none"


## Element of a class skill's effects: the first status it applies (to targets, then on hit, then to
## itself and allies) that has an element; "none" otherwise.
static func element_for_skill(skill: ClassSkillDefinition) -> String:
	if skill == null:
		return "none"
	return element_for_effects([skill.target_effects, skill.on_hit_effects, skill.self_effects, skill.ally_effects])


## First element among lists of StatusEffectChance (EFFECT_ELEMENTS); "none" when none has one.
static func element_for_effects(lists: Array) -> String:
	for list: Array in lists:
		for chance: StatusEffectChance in list:
			if chance != null and chance.effect != null and EFFECT_ELEMENTS.has(chance.effect.id):
				return EFFECT_ELEMENTS[chance.effect.id]
	return "none"


## Attack sequence of a Forge animation (ANIMS[name]): frames {dur (s), pose}.
static func sequence(anim: String) -> Array:
	if not _sequences.has(anim):
		var frames: Array = []
		var anims: Dictionary = ForgeData.data()["anims"]
		for pose: Dictionary in anims.get(anim, []):
			frames.append({"dur": float(pose.get("d", 100.0)) / 1000.0, "pose": pose})
		_sequences[anim] = frames
	return _sequences[anim]


## Length of a Forge weapon from the grip to its tip (character px); 0 without a weapon.
static func tip_of(weapon: String) -> float:
	return ForgeData.find_item("weapon", weapon).get("tip", 0.0)


## Forge animation of a weapon ("" = none).
static func anim_of(weapon: String) -> String:
	return ForgeData.find_item("weapon", weapon).get("anim", "")


## Baked frame of a config (key: key_of(cfg)) in a frame state (ForgeComposer st, key: anything that
## tells states apart). Shared by every Hunter.
static func frame(cfg: Dictionary, cfg_key: String, st: Dictionary, st_key: String) -> ForgeFrame:
	var key := cfg_key + "#" + st_key
	var cached: ForgeFrame = _frames.get(key)
	if cached != null:
		return cached
	if _frames.size() >= CACHE_LIMIT:
		_frames.clear()
	var baked := ForgeFrame.bake(ForgeComposer.compose(cfg, st))
	_frames[key] = baked
	return baked


## Standing figure without weapon or ground shadow (UI cards, paper doll, portraits).
static func figure(look: HunterAppearance, dress: ChibiDress = null) -> ForgeFrame:
	var cfg := config(look, dress)
	return frame(cfg, key_of(cfg), {"no_weapon": true, "no_shadow": true}, "figure")
