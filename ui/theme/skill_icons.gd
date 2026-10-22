class_name SkillIcons
extends RefCounted
## Square pixel icons for class and monster skills, generated from the skill's data (no asset
## files): a coloured plate (orange = active, blue = passive, tinted by group), a glyph picked from
## the skill's effects and name (blade, arrow, shield, flame, drop, bolt, heart, burst, claw, star),
## and a dark outline. The same skill always gets the same icon.

const TEXELS := 24
const OUTLINE := Color("1a120c")
const LIGHT := Color("f6efe0")

## Words in a skill id -> glyph, first match wins.
const KEYWORDS := [
	[["heal", "regen", "regrow", "second_wind", "light", "faith", "oath", "absorb", "leech", "drain", "life", "forager"], &"heart"],
	[["shield", "wall", "guard", "armor", "stone", "bark", "skin", "fur", "gel", "jelly", "bulwark", "stance", "aura", "taunt", "resilien", "protect", "unshak", "unyield", "fortif"], &"shield"],
	[["fire", "flame", "burn", "rage", "wrath", "berserk", "blood", "frenzy", "explosive", "hot"], &"flame"],
	[["poison", "acid", "venom", "toxic", "envenom", "spore", "goo", "corros", "spit", "sticky"], &"drop"],
	[["frost", "ice", "freeze", "chill", "nova"], &"snow"],
	[["bolt", "thunder", "stun", "shock", "judg", "smite", "holy"], &"bolt"],
	[["arrow", "shot", "snipe", "nock", "bow", "quiver", "aim", "hawk", "eye", "sight", "mark", "throw", "spear", "pierc", "long"], &"arrow"],
	[["slam", "storm", "rain", "whirl", "shatter", "quake", "burst", "howl", "cry", "wave", "blade_dance", "fan"], &"burst"],
	[["bite", "claw", "rend", "pounce", "lunge", "fang", "savage", "stab", "knife", "cheap", "dirty", "backstab", "eviscer", "serrat", "hamstring"], &"claw"],
	[["curse", "death", "grave", "undead", "bone", "skull", "dark", "necro", "soul", "silence"], &"skull"],
	[["step", "dodge", "evasion", "nimble", "feet", "vanish", "shadow", "lurk", "catwalk", "reflex", "escape", "smoke", "bounce", "tempo", "disengage"], &"wing"],
	[["slash", "strike", "sword", "blade", "swords", "execute", "crit", "slayer", "smash", "hammer", "bash", "crush", "triple", "twin", "opener", "riposte", "assassin"], &"blade"],
]
const EFFECT_GLYPHS := {
	&"poison": &"drop", &"burn": &"flame", &"freeze": &"snow", &"slow": &"snow", &"stun": &"bolt", &"stagger": &"bolt",
	&"bleed": &"claw", &"root": &"leaf", &"regeneration": &"heart", &"shield": &"shield", &"fortify": &"shield",
}
## Plate colours: [dark, light].
const ACTIVE_PLATE := [Color("5a2a12"), Color("c8622a")]
const PASSIVE_PLATE := [Color("1b3358"), Color("4a7fc4")]

static var _cache: Dictionary = {}


## Texture of a ClassSkillDefinition or MonsterSkillDefinition, laid out at 24 px × `scale`/2.
static func texture(skill: GameDefinition, scale: int = 2) -> Texture2D:
	var key := "%s|%d" % [skill.id, scale]
	if not _cache.has(key):
		var result := ImageTexture.create_from_image(image_of(skill))
		result.set_size_override(Vector2i(TEXELS, TEXELS) * maxi(scale, 1) / 2)
		_cache[key] = result
	return _cache[key]


static func is_active(skill: GameDefinition) -> bool:
	return skill.is_active() if skill.has_method(&"is_active") else true


static func glyph_of(skill: GameDefinition) -> StringName:
	var id := String(skill.id)
	for entry: Array in KEYWORDS:
		for word: String in entry[0]:
			if id.contains(word):
				return entry[1]
	var effects: Array = skill.get(&"target_effects") if skill.get(&"target_effects") != null else []
	for chance: StatusEffectChance in effects:
		if chance != null and chance.effect != null and EFFECT_GLYPHS.has(chance.effect.id):
			return EFFECT_GLYPHS[chance.effect.id]
	if float(skill.get(&"heal_ratio") if skill.get(&"heal_ratio") != null else 0.0) > 0.0:
		return &"heart"
	return &"blade" if is_active(skill) else &"star"


static func image_of(skill: GameDefinition) -> Image:
	var image := Image.create(TEXELS, TEXELS, false, Image.FORMAT_RGBA8)
	var plate: Array = ACTIVE_PLATE if is_active(skill) else PASSIVE_PLATE
	# Plate: diagonal gradient, hue nudged per group (class or monster) so neighbours differ.
	var group := String(skill.get(&"class_id")) if skill.get(&"class_id") != null else String(skill.get(&"enemy_id"))
	var shift := float(hash(group) % 100) / 100.0 * 0.08 - 0.04
	for y in TEXELS:
		for x in TEXELS:
			var t := float(x + y) / float(TEXELS * 2 - 2)
			var color: Color = (plate[1] as Color).lerp(plate[0], t)
			color.h = fposmod(color.h + shift, 1.0)
			image.set_pixel(x, y, color)
	var glyph := Image.create(TEXELS, TEXELS, false, Image.FORMAT_RGBA8)
	_draw_glyph(glyph, glyph_of(skill), hash(String(skill.id)))
	_outline(glyph)
	image.blend_rect(glyph, Rect2i(0, 0, TEXELS, TEXELS), Vector2i.ZERO)
	# Plate frame.
	for i in TEXELS:
		for edge: Vector2i in [Vector2i(i, 0), Vector2i(i, TEXELS - 1), Vector2i(0, i), Vector2i(TEXELS - 1, i)]:
			image.set_pixelv(edge, OUTLINE)
	for corner: Vector2i in [Vector2i(0, 0), Vector2i(TEXELS - 1, 0), Vector2i(0, TEXELS - 1), Vector2i(TEXELS - 1, TEXELS - 1)]:
		image.set_pixelv(corner, Color(0, 0, 0, 0))
	return image


# --- Glyphs (all inside a 24×24 grid, light colour; an outline is added afterwards) -------------

static func _px(image: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < TEXELS and y < TEXELS:
		image.set_pixel(x, y, color)


static func _line(image: Image, a: Vector2i, b: Vector2i, color: Color, width: int = 1) -> void:
	var steps := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in steps + 1:
		var p := Vector2(a).lerp(Vector2(b), float(i) / maxf(steps, 1))
		for dx in width:
			for dy in width:
				_px(image, roundi(p.x) + dx - width / 2, roundi(p.y) + dy - width / 2, color)


static func _disc(image: Image, center: Vector2, radius: float, color: Color) -> void:
	for y in range(floori(center.y - radius), ceili(center.y + radius) + 1):
		for x in range(floori(center.x - radius), ceili(center.x + radius) + 1):
			if Vector2(x, y).distance_to(center) <= radius:
				_px(image, x, y, color)


static func _poly(image: Image, points: Array, color: Color) -> void:
	var polygon := PackedVector2Array(points)
	for y in TEXELS:
		for x in TEXELS:
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), polygon):
				_px(image, x, y, color)


static func _draw_glyph(image: Image, glyph: StringName, _seed: int) -> void:
	var gold := Color("f2c94c")
	match glyph:
		&"blade":
			_line(image, Vector2i(5, 19), Vector2i(18, 5), LIGHT, 3)
			_line(image, Vector2i(6, 18), Vector2i(17, 7), Color("c9d4e0"), 1)
			_line(image, Vector2i(4, 13), Vector2i(10, 19), gold, 2)
			_line(image, Vector2i(3, 21), Vector2i(7, 17), Color("8b5e3c"), 2)
		&"arrow":
			_line(image, Vector2i(4, 20), Vector2i(18, 6), Color("d8c9a0"), 2)
			_poly(image, [Vector2(21, 3), Vector2(13, 6), Vector2(18, 11)], LIGHT)
			_line(image, Vector2i(4, 20), Vector2i(4, 15), Color("c9503f"), 2)
			_line(image, Vector2i(4, 20), Vector2i(9, 20), Color("c9503f"), 2)
		&"shield":
			_poly(image, [Vector2(4, 4), Vector2(20, 4), Vector2(20, 13), Vector2(12, 21), Vector2(4, 13)], LIGHT)
			_poly(image, [Vector2(7, 7), Vector2(17, 7), Vector2(17, 12), Vector2(12, 17), Vector2(7, 12)], Color("7f93b8"))
			_line(image, Vector2i(12, 7), Vector2i(12, 16), gold, 2)
		&"flame":
			_poly(image, [Vector2(12, 2), Vector2(18, 10), Vector2(19, 16), Vector2(16, 21), Vector2(8, 21), Vector2(5, 16), Vector2(7, 10), Vector2(10, 12)], Color("ffb03a"))
			_poly(image, [Vector2(12, 9), Vector2(16, 15), Vector2(15, 19), Vector2(9, 19), Vector2(8, 15)], Color("fff0a0"))
		&"drop":
			_poly(image, [Vector2(12, 2), Vector2(18, 12), Vector2(17, 18), Vector2(12, 21), Vector2(7, 18), Vector2(6, 12)], Color("7fe07a"))
			_disc(image, Vector2(10, 15), 2.0, Color("d8ffd0"))
		&"snow":
			for angle in [0.0, 60.0, 120.0]:
				var d := Vector2.from_angle(deg_to_rad(angle)) * 9.0
				_line(image, Vector2i(roundi(12 - d.x), roundi(12 - d.y)), Vector2i(roundi(12 + d.x), roundi(12 + d.y)), Color("b8ecff"), 2)
			_disc(image, Vector2(12, 12), 2.0, LIGHT)
		&"bolt":
			_poly(image, [Vector2(14, 2), Vector2(6, 13), Vector2(11, 13), Vector2(9, 22), Vector2(18, 10), Vector2(13, 10)], Color("ffe36b"))
		&"heart":
			_disc(image, Vector2(8.5, 9), 4.5, Color("ff6b7a"))
			_disc(image, Vector2(15.5, 9), 4.5, Color("ff6b7a"))
			_poly(image, [Vector2(4, 11), Vector2(20, 11), Vector2(12, 21)], Color("ff6b7a"))
			_disc(image, Vector2(7, 7.5), 1.5, Color("ffd0d6"))
		&"burst":
			for i in 8:
				var d := Vector2.from_angle(i * TAU / 8.0)
				_line(image, Vector2i(roundi(12 + d.x * 4), roundi(12 + d.y * 4)), Vector2i(roundi(12 + d.x * 10), roundi(12 + d.y * 10)), Color("ffd27a"), 2)
			_disc(image, Vector2(12, 12), 4.0, LIGHT)
		&"claw":
			for i in 3:
				_line(image, Vector2i(6 + i * 5, 3), Vector2i(11 + i * 4, 21), LIGHT, 2)
		&"skull":
			_disc(image, Vector2(12, 10), 7.0, LIGHT)
			_poly(image, [Vector2(7, 14), Vector2(17, 14), Vector2(16, 21), Vector2(8, 21)], LIGHT)
			_disc(image, Vector2(9, 10), 2.0, OUTLINE)
			_disc(image, Vector2(15, 10), 2.0, OUTLINE)
		&"wing":
			_poly(image, [Vector2(3, 18), Vector2(8, 6), Vector2(21, 3), Vector2(15, 10), Vector2(19, 13), Vector2(12, 14), Vector2(14, 18)], LIGHT)
		&"leaf":
			_poly(image, [Vector2(4, 20), Vector2(5, 8), Vector2(15, 3), Vector2(20, 5), Vector2(19, 15), Vector2(10, 20)], Color("7fd06a"))
			_line(image, Vector2i(5, 20), Vector2i(17, 7), Color("2f6a2a"), 1)
		_:
			_poly(image, [Vector2(12, 2), Vector2(15, 9), Vector2(22, 9), Vector2(16, 14), Vector2(19, 21), Vector2(12, 17), Vector2(5, 21), Vector2(8, 14), Vector2(2, 9), Vector2(9, 9)], gold)


## One-pixel dark outline around everything drawn (4-neighbour dilation).
static func _outline(image: Image) -> void:
	var source := image.duplicate() as Image
	for y in TEXELS:
		for x in TEXELS:
			if source.get_pixel(x, y).a > 0.0:
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx := x + d.x
				var ny := y + d.y
				if nx >= 0 and ny >= 0 and nx < TEXELS and ny < TEXELS and source.get_pixel(nx, ny).a > 0.0:
					image.set_pixel(x, y, OUTLINE)
					break


static func clear_cache() -> void:
	_cache.clear()
