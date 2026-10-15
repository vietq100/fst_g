class_name GroundPainter
extends RefCounted
## Paints the pixel-art ground of one region into an Image (baked once by tools/bake_ground.gd, the
## game loads the PNGs). One texel = SCALE world px. Each theme looks different: Dark Forest is
## dark mud and moss with spiky leaf bushes, Goblin Cave flagstones with glowing lava veins, Ancient
## Ruins cracked pale paving with moss, the Town grass with tufts and flowers, the boss arena
## obsidian slabs with violet veins. The texture covers the region's bounding box; texels outside its
## tiles stay transparent.

## One texel is one world pixel, like the Hunters' sprites. Feature sizes below are written in
## "design texels" (2 world px each) and multiplied by K.
const SCALE := 2
const K := 2.0 / SCALE
## The texture reaches this many world px past the region's tiles: ragged, noise-shaped shores
## (grass and rock lips hanging over the water) instead of straight diamond edges.
const PAD := 6
const BAYER: Array[int] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

enum Biome { GRASS, FOREST, CAVE, RUINS, OBSIDIAN, PATH }

var _world: WorldService
var _region: RegionDefinition
var _tiles: Dictionary
var _origin := Vector2.ZERO
var _size := Vector2i.ZERO
var _image: Image
var _mask: PackedByteArray
var _seed := 1
var _big := FastNoiseLite.new()
var _mid := FastNoiseLite.new()
var _fine := FastNoiseLite.new()
var _cell := FastNoiseLite.new()
var _cell_value := FastNoiseLite.new()


## World-space top-left corner and texel size of the region's texture.
static func layout(world: WorldService, region: RegionDefinition) -> Dictionary:
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for tile: Vector2i in world.region_tile_list(region.id):
		for corner in WorldService.rect_polygon(Rect2i(tile, Vector2i.ONE)):
			low = low.min(corner)
			high = high.max(corner)
	if low.x == INF:
		return {}
	low -= Vector2(PAD, PAD)
	high += Vector2(PAD, PAD)
	var origin := Vector2(floorf(low.x / SCALE) * SCALE, floorf(low.y / SCALE) * SCALE)
	var size := Vector2i(ceili((high.x - origin.x) / SCALE) + 1, ceili((high.y - origin.y) / SCALE) + 1)
	return {"origin": origin, "size": size}


static func biome_of(region: RegionDefinition) -> Biome:
	if region.kind == RegionDefinition.Kind.BOSS:
		return Biome.OBSIDIAN
	if region.is_town:
		return Biome.GRASS
	match region.props:
		RegionDefinition.Props.TREES:
			return Biome.FOREST
		RegionDefinition.Props.ROCKS:
			return Biome.CAVE
		RegionDefinition.Props.COLUMNS:
			return Biome.RUINS
	return Biome.PATH if region.kind == RegionDefinition.Kind.GATE else Biome.GRASS


## The finished texture image, or null when the region has no tiles.
func paint(world: WorldService, region: RegionDefinition) -> Image:
	var box := layout(world, region)
	if box.is_empty():
		return null
	_world = world
	_region = region
	_tiles = world.region_tiles(region.id)
	_origin = box["origin"]
	_size = box["size"]
	_seed = hash(String(region.id)) & 0xFFFF
	_setup_noise()
	_image = Image.create(_size.x, _size.y, false, Image.FORMAT_RGBA8)
	_build_mask()
	match biome_of(region):
		Biome.FOREST:
			_paint_forest()
		Biome.CAVE:
			_paint_cave(false)
		Biome.OBSIDIAN:
			_paint_cave(true)
		Biome.RUINS:
			_paint_ruins()
		Biome.PATH:
			_paint_path()
		_:
			_paint_grass()
	_edge_fringe(_fringe_color())
	return _image


# --- Shared helpers ------------------------------------------------------------------------------

func _setup_noise() -> void:
	for entry in [[_big, 0.0045, 0], [_mid, 0.014, 1], [_fine, 0.07, 2]]:
		var noise: FastNoiseLite = entry[0]
		noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		noise.seed = _seed + entry[2] * 101
		noise.frequency = entry[1]
	_cell.noise_type = FastNoiseLite.TYPE_CELLULAR
	_cell.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	_cell.seed = _seed + 7
	_cell.frequency = 0.011
	_cell_value.noise_type = FastNoiseLite.TYPE_CELLULAR
	_cell_value.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE
	_cell_value.seed = _seed + 7
	_cell_value.frequency = 0.011


func _build_mask() -> void:
	_mask = PackedByteArray()
	_mask.resize(_size.x * _size.y)
	for y in _size.y:
		for x in _size.x:
			var inside := _tiles.has(WorldService.tile_at(_world_of(x, y)))
			_mask[y * _size.x + x] = 1 if inside else 0
	_grow_mask()


## Grows the mask a few texels past the tiles with a noisy reach, so the shore is ragged.
func _grow_mask() -> void:
	var layers := int(PAD / SCALE)
	var frontier: Array[int] = []
	for y in _size.y:
		for x in _size.x:
			if _mask[y * _size.x + x] != 1:
				continue
			for step in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
				var nx: int = x + step.x
				var ny: int = y + step.y
				if nx >= 0 and ny >= 0 and nx < _size.x and ny < _size.y and _mask[ny * _size.x + nx] == 0:
					frontier.append(y * _size.x + x)
					break
	for layer in range(1, layers + 1):
		var next: Array[int] = []
		for index in frontier:
			var x := index % _size.x
			var y := index / _size.x
			for step in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
				var nx: int = x + step.x
				var ny: int = y + step.y
				if nx < 0 or ny < 0 or nx >= _size.x or ny >= _size.y or _mask[ny * _size.x + nx] != 0:
					continue
				var p := _world_of(nx, ny)
				# Never grow over a neighbouring region's ground (the border stays straight).
				if _world.is_land(WorldService.tile_at(p)):
					continue
				var reach := layers * (0.25 + 0.75 * (_mid.get_noise_2d(p.x * 1.7, p.y * 1.7) * 0.5 + 0.5)) \
					+ _fine.get_noise_2d(p.x, p.y) * 1.5
				if layer <= reach:
					_mask[ny * _size.x + nx] = 1
					next.append(ny * _size.x + nx)
		frontier = next


func _world_of(x: int, y: int) -> Vector2:
	return _origin + Vector2(x + 0.5, y + 0.5) * SCALE


func _inside(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < _size.x and y < _size.y and _mask[y * _size.x + x] == 1


func _put(x: int, y: int, color: Color) -> void:
	if _inside(x, y):
		_image.set_pixel(x, y, color)


## Blends `color` over what is there (alpha 0..1).
func _blend(x: int, y: int, color: Color) -> void:
	if _inside(x, y):
		_image.set_pixel(x, y, _image.get_pixel(x, y).lerp(Color(color, 1.0), color.a))


static func _bayer(x: int, y: int) -> float:
	return BAYER[(x & 3) + (y & 3) * 4] / 16.0


func _rand(a: int, b: int, salt: int) -> float:
	var h := (a * 73856093) ^ (b * 19349663) ^ ((salt + _seed) * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	return float(absi(h ^ (h >> 16)) % 10000) / 10000.0


func _disc(cx: float, cy: float, radius: float, color: Color) -> void:
	radius *= K
	for y in range(floori(cy - radius), ceili(cy + radius) + 1):
		for x in range(floori(cx - radius), ceili(cx + radius) + 1):
			if Vector2(x - cx, y - cy).length() <= radius:
				_put(x, y, color)


func _ellipse(cx: float, cy: float, rx: float, ry: float, color: Color) -> void:
	rx *= K
	ry *= K
	for y in range(floori(cy - ry), ceili(cy + ry) + 1):
		for x in range(floori(cx - rx), ceili(cx + rx) + 1):
			var d := Vector2((x - cx) / rx, (y - cy) / ry).length()
			if d <= 1.0:
				_blend(x, y, color)


## A tapered leaf / blade from `base` along `angle` (radians, 0 = right), `length` texels.
func _leaf(base: Vector2, angle: float, length: float, width: float, fill: Color, edge: Color, tip: Color) -> void:
	var dir := Vector2(cos(angle), sin(angle))
	length *= K
	var steps := int(length * 2.0)
	for pass_index in 2:
		for i in steps + 1:
			var t := float(i) / steps
			var point := base + dir * length * t
			var radius := width * (1.0 - t) * 0.5 + 0.5
			var color := edge if pass_index == 0 else fill.lerp(tip, t * t)
			var r := radius + (0.9 if pass_index == 0 else 0.0)
			_disc(point.x, point.y, r, color)


# --- Dark Forest: mud, moss, spiky leaf bushes, pebbles ------------------------------------------

func _paint_forest() -> void:
	var base := Color("37593f")
	var mud := Color("2b4a38")
	var mud_edge := Color("1b3428")
	var moss := Color("4d7a52")
	var classes := PackedByteArray()
	classes.resize(_size.x * _size.y)
	for y in _size.y:
		for x in _size.x:
			if not _inside(x, y):
				continue
			var p := _world_of(x, y)
			var v := _big.get_noise_2d(p.x, p.y) + 0.35 * _mid.get_noise_2d(p.x, p.y)
			var d := _bayer(x, y) * 0.07 - 0.035
			var kind := 0
			if v + d < -0.14:
				kind = 1
			elif v + d > 0.40:
				kind = 2
			classes[y * _size.x + x] = kind
			var color := [base, mud, moss][kind] as Color
			var grain := _fine.get_noise_2d(p.x, p.y)
			if grain > 0.55:
				color = color.lightened(0.07)
			elif grain < -0.6:
				color = color.darkened(0.12)
			_image.set_pixel(x, y, color)
	# Dark rims where mud meets the ground.
	for y in _size.y:
		for x in _size.x:
			if not _inside(x, y) or classes[y * _size.x + x] != 1:
				continue
			for step in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
				var nx: int = x + step.x
				var ny: int = y + step.y
				if _inside(nx, ny) and classes[ny * _size.x + nx] != 1:
					_image.set_pixel(x, y, mud_edge)
					break
	_scatter_pebbles(Color("7a8a84"), Color("a9b8b0"), Color("27382f"), 56, 0.32, 1.9)
	_scatter_branches(Color("7a5a38"), 70, 0.3)
	_scatter_litter()
	_scatter_bushes(Color("3f7a4c"), Color("5aa563"), Color("93d880"), Color("1a3a28"), 46, 0.6, 1.0)
	_scatter_bushes(Color("3a7348"), Color("55a05f"), Color("86cf78"), Color("1a3a28"), 20, 0.45, 0.45)
	_scatter_mushrooms(Color("8fe0ff"), Color("5a8fd0"), 80, 0.3)


## Spiky leaf bushes: 5-8 tapered leaves fanning up, dark outline, lighter tips, soft shadow.
func _scatter_bushes(fill: Color, light: Color, tip: Color, edge: Color, cell: int, chance: float, size: float) -> void:
	cell = int(cell * K)
	for cy in range(0, _size.y / cell + 1):
		for cx in range(0, _size.x / cell + 1):
			if _rand(cx, cy, 11) > chance:
				continue
			var at := Vector2(cx * cell + 5 * K + _rand(cx, cy, 12) * (cell - 10 * K), cy * cell + 8 * K + _rand(cx, cy, 13) * (cell - 12 * K))
			if not _inside(int(at.x), int(at.y)):
				continue
			_ellipse(at.x, at.y + 1.5 * K, 16.0 * size, 5.0 * size, Color(0, 0, 0, 0.32))
			var leaves := 6 + int(_rand(cx, cy, 14) * 5.0)
			for i in leaves:
				var spread := (float(i) / maxf(leaves - 1, 1) - 0.5) * 2.6 + (_rand(cx, cy, 20 + i) - 0.5) * 0.4
				var angle := -PI * 0.5 + spread
				var length := (11.0 + _rand(cx, cy, 30 + i) * 12.0) * size
				_leaf(at, angle, length, 6.5 * size + 1.0, fill.lerp(light, _rand(cx, cy, 40 + i)), edge, tip)


func _scatter_pebbles(fill: Color, light: Color, edge: Color, cell: int, chance: float, size: float = 1.0) -> void:
	cell = int(cell * K)
	for cy in range(0, _size.y / cell + 1):
		for cx in range(0, _size.x / cell + 1):
			if _rand(cx, cy, 51) > chance:
				continue
			var at := Vector2(cx * cell + _rand(cx, cy, 52) * cell, cy * cell + _rand(cx, cy, 53) * cell)
			var r := (1.6 + _rand(cx, cy, 54) * 2.2) * size
			_ellipse(at.x, at.y + 0.6, r + 1.0, r * 0.55 + 1.0, Color(edge, 0.9))
			_ellipse(at.x, at.y, r, r * 0.6, fill)
			_ellipse(at.x - r * 0.25, at.y - r * 0.2, r * 0.5, r * 0.3, light)


func _scatter_branches(color: Color, cell: int, chance: float) -> void:
	cell = int(cell * K)
	for cy in range(0, _size.y / cell + 1):
		for cx in range(0, _size.x / cell + 1):
			if _rand(cx, cy, 61) > chance:
				continue
			var at := Vector2(cx * cell + _rand(cx, cy, 62) * cell, cy * cell + _rand(cx, cy, 63) * cell)
			var dir := Vector2.from_angle(_rand(cx, cy, 64) * TAU)
			for i in int(7 * K):
				var p := at + dir * i
				_put(int(p.x), int(p.y), color if i % 5 else color.darkened(0.3))
			var fork := at + dir * 4.0 * K
			for i in int(3 * K):
				var p2 := fork + dir.rotated(0.8) * i
				_put(int(p2.x), int(p2.y), color)


# --- Goblin Cave / boss arena: flagstones, cracks, glowing veins -----------------------------------

func _paint_cave(obsidian: bool) -> void:
	var tones: Array[Color] = [Color("78634d"), Color("6d5a46"), Color("82705a"), Color("645140")]
	if obsidian:
		tones = [Color("2a2236"), Color("251e30"), Color("2f263c"), Color("1f192a")]
	var crack := Color("3a2a20") if not obsidian else Color("0f0b16")
	var glow := Color("ff7a22") if not obsidian else Color("a66bff")
	var core := Color("ffd27a") if not obsidian else Color("e6ccff")
	for y in _size.y:
		for x in _size.x:
			if not _inside(x, y):
				continue
			var p := _world_of(x, y)
			var edge := _cell.get_noise_2d(p.x, p.y)
			# Cell index from the position of the nearest cell centre (stable tone per flagstone).
			var tone := tones[int((_cell_value.get_noise_2d(p.x, p.y) * 0.5 + 0.5) * tones.size() * 3.0) % tones.size()]
			var grain := _fine.get_noise_2d(p.x, p.y)
			var color := tone
			if grain > 0.5:
				color = color.lightened(0.06)
			elif grain < -0.55:
				color = color.darkened(0.1)
			var vein := _big.get_noise_2d(p.x * 0.9, p.y * 0.9) + 0.4 * _mid.get_noise_2d(p.x, p.y)
			if edge < -0.9:
				color = crack
				# Lava / violet light runs through some cracks.
				if vein > 0.42:
					color = glow
					if edge < -0.95 and vein > 0.54:
						color = core
			elif edge < -0.82:
				color = crack.lightened(0.04) if vein < 0.42 else glow.darkened(0.55)
			elif edge > 0.55 and _bayer(x, y) < 0.35:
				color = color.lightened(0.05)
			_image.set_pixel(x, y, color)
	_scatter_pebbles(Color("8a7a66") if not obsidian else Color("4a3f60"), Color("b3a48c") if not obsidian else Color("6a5c88"), Color("2a1d15"), 54, 0.36, 1.9)


# --- Ancient Ruins: pale paving, joints, moss, broken slabs ----------------------------------------

func _paint_ruins() -> void:
	var tones: Array[Color] = [Color("c2b896"), Color("cfc5a0"), Color("b5ab8a"), Color("d3caa8")]
	var joint := Color("6b6450")
	var moss := Color("6f9a55")
	var soil := Color("5a4a34")
	for y in _size.y:
		for x in _size.x:
			if not _inside(x, y):
				continue
			var p := _world_of(x, y)
			var tf := WorldService.world_to_tile(p)
			var su := tf.x / 1.5
			var sv := tf.y / 1.5
			var iu := floori(su)
			var iv := floori(sv)
			var fu := su - iu
			var fv := sv - iv
			var slab := _rand(iu, iv, 80)
			var color := tones[int(slab * tones.size()) % tones.size()]
			var grain := _fine.get_noise_2d(p.x, p.y)
			if grain > 0.5:
				color = color.lightened(0.05)
			elif grain < -0.5:
				color = color.darkened(0.08)
			if slab < 0.03:
				color = soil.lerp(color, 0.25 if _bayer(x, y) > 0.5 else 0.0)
			var near_joint := fu < 0.035 or fv < 0.035
			if near_joint:
				color = joint
			elif fu > 0.95 or fv > 0.95:
				color = color.darkened(0.12)
			elif fu < 0.07 or fv < 0.07:
				color = color.lightened(0.07)
			# A diagonal crack through some slabs.
			if not near_joint and slab > 0.8 and absf((fu - fv) - (slab - 0.9) * 2.0) < 0.025:
				color = joint.darkened(0.2)
			var moss_noise := _mid.get_noise_2d(p.x + 400.0, p.y) + 0.3 * _fine.get_noise_2d(p.x, p.y)
			if moss_noise > 0.42 + _bayer(x, y) * 0.1 - 0.05:
				color = moss.darkened(0.15) if moss_noise > 0.55 else moss
			_image.set_pixel(x, y, color)
	_scatter_pebbles(Color("d8d0b4"), Color("f0e8cc"), Color("6b6450"), 60, 0.3, 1.9)


# --- Town grass and the gate path ------------------------------------------------------------------

func _paint_grass() -> void:
	var base := _region.ground_color
	var dirt := Color("6b5a3c")
	for y in _size.y:
		for x in _size.x:
			if not _inside(x, y):
				continue
			var p := _world_of(x, y)
			var v := _big.get_noise_2d(p.x, p.y) + 0.4 * _mid.get_noise_2d(p.x, p.y)
			var color := base
			if v > 0.28 + _bayer(x, y) * 0.06 - 0.03:
				color = base.lightened(0.08)
			elif v < -0.3 + _bayer(x, y) * 0.06 - 0.03:
				color = base.darkened(0.1)
			var grain := _fine.get_noise_2d(p.x, p.y)
			if grain > 0.58:
				color = color.lightened(0.05)
			elif grain < -0.6:
				color = color.darkened(0.07)
			var patch := _mid.get_noise_2d(p.x + 900.0, p.y - 300.0)
			if patch > 0.7 + _bayer(x, y) * 0.05:
				color = dirt.lerp(color, 0.35)
			_image.set_pixel(x, y, color)
	_scatter_blades(base.lightened(0.32), base.darkened(0.4), 14, 0.9)
	_scatter_flowers(34, 0.55)


func _paint_path() -> void:
	var base := _region.ground_color
	for y in _size.y:
		for x in _size.x:
			if not _inside(x, y):
				continue
			var p := _world_of(x, y)
			var color := base
			var grain := _fine.get_noise_2d(p.x, p.y)
			if grain > 0.5:
				color = color.lightened(0.07)
			elif grain < -0.5:
				color = color.darkened(0.1)
			_image.set_pixel(x, y, color)
	_scatter_pebbles(base.lightened(0.15), base.lightened(0.3), base.darkened(0.5), 26, 0.4)


func _scatter_blades(light: Color, dark: Color, cell: int, chance: float) -> void:
	cell = int(cell * K)
	for cy in range(0, _size.y / cell + 1):
		for cx in range(0, _size.x / cell + 1):
			if _rand(cx, cy, 91) > chance:
				continue
			var at := Vector2(cx * cell + _rand(cx, cy, 92) * cell, cy * cell + _rand(cx, cy, 93) * cell)
			for i in 3:
				var angle := -PI * 0.5 + (i - 1) * 0.5 + (_rand(cx, cy, 94 + i) - 0.5) * 0.3
				var length := 5.0 + _rand(cx, cy, 98 + i) * 5.0
				for s in int(length * K) + 1:
					var point := at + Vector2.from_angle(angle) * s
					_put(int(point.x), int(point.y), light if s > 0 else dark)


func _scatter_flowers(cell: int, chance: float) -> void:
	cell = int(cell * K)
	var palette: Array[Color] = [Color("f4f1ea"), Color("f2c94c"), Color("e8789a"), Color("a78bfa")]
	for cy in range(0, _size.y / cell + 1):
		for cx in range(0, _size.x / cell + 1):
			if _rand(cx, cy, 101) > chance:
				continue
			var at := Vector2(cx * cell + _rand(cx, cy, 102) * cell, cy * cell + _rand(cx, cy, 103) * cell)
			var color := palette[int(_rand(cx, cy, 104) * palette.size()) % palette.size()]
			for i in 5:
				var spot := at + Vector2(_rand(cx, cy, 110 + i) * 12.0 - 6.0, _rand(cx, cy, 120 + i) * 6.0 - 3.0) * K
				for k in int(3 * K):
					_put(int(spot.x), int(spot.y) + k, Color("2f5a26"))
				_disc(spot.x, spot.y - K, 1.7, color)
				_put(int(spot.x), int(spot.y - K), Color("f2c94c") if color != Color("f2c94c") else Color("fff3b0"))


## Fallen leaves: tiny warm specks and small leaf shapes on the forest floor.
func _scatter_litter() -> void:
	var palette: Array[Color] = [Color("c98a3a"), Color("b0642e"), Color("d9b04a"), Color("8a5a2a")]
	for cy in range(0, _size.y / int(16 * K) + 1):
		for cx in range(0, _size.x / int(16 * K) + 1):
			if _rand(cx, cy, 131) > 0.22:
				continue
			var at := Vector2(cx * int(16 * K) + _rand(cx, cy, 132) * 16 * K, cy * int(16 * K) + _rand(cx, cy, 133) * 16 * K)
			var color := palette[int(_rand(cx, cy, 134) * palette.size()) % palette.size()]
			_ellipse(at.x, at.y, 2.6, 1.4, color)
			_put(int(at.x), int(at.y), color.lightened(0.25))


## Glowing mushrooms in small groups.
func _scatter_mushrooms(cap: Color, glow: Color, cell: int, chance: float) -> void:
	cell = int(cell * K)
	for cy in range(0, _size.y / cell + 1):
		for cx in range(0, _size.x / cell + 1):
			if _rand(cx, cy, 141) > chance:
				continue
			var at := Vector2(cx * cell + _rand(cx, cy, 142) * cell, cy * cell + _rand(cx, cy, 143) * cell)
			if not _inside(int(at.x), int(at.y)):
				continue
			_ellipse(at.x, at.y + 2.0, 12.0, 4.0, Color(glow, 0.22))
			for i in 3:
				var spot := at + Vector2((i - 1) * 5.0 + _rand(cx, cy, 150 + i) * 2.0, _rand(cx, cy, 160 + i) * 3.0) * K
				var h := (3.0 + _rand(cx, cy, 170 + i) * 3.0) * K
				for k in int(h):
					_put(int(spot.x), int(spot.y) - k, Color("d9e6dd"))
				_ellipse(spot.x, spot.y - h, 3.4, 2.2, cap.darkened(0.15))
				_ellipse(spot.x, spot.y - h - 0.6 * K, 2.4, 1.3, cap)


# --- Region edge: a shaded rim so each plateau reads as a solid piece --------------------------------

func _fringe_color() -> Color:
	match biome_of(_region):
		Biome.FOREST:
			return Color("102a1e")
		Biome.CAVE:
			return Color("1c130d")
		Biome.OBSIDIAN:
			return Color("120c1c")
		Biome.RUINS:
			return Color("55503c")
		Biome.PATH:
			return Color("2a2018")
	return Color("1f3d1a")


## True for texels of this region or of a neighbouring region's ground.
func _solid(x: int, y: int) -> bool:
	if _inside(x, y):
		return true
	if x < 0 or y < 0 or x >= _size.x or y >= _size.y:
		return false
	return _world.is_land(WorldService.tile_at(_world_of(x, y)))


## Darkens the outermost texels (outline) and fades a softer shade over the next few, dithered.
func _edge_fringe(dark: Color) -> void:
	var band := int(7 * K * 0.5) + 2
	var depth := PackedInt32Array()
	depth.resize(_size.x * _size.y)
	depth.fill(-1)
	var frontier: Array[int] = []
	for y in _size.y:
		for x in _size.x:
			if not _inside(x, y):
				continue
			var edge := false
			for step in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
				if not _solid(x + step.x, y + step.y):
					edge = true
					break
			if edge:
				depth[y * _size.x + x] = 0
				frontier.append(y * _size.x + x)
	var level := 0
	while not frontier.is_empty() and level < band:
		var next: Array[int] = []
		for index in frontier:
			var x := index % _size.x
			var y := index / _size.x
			var d := depth[index]
			var amount := 0.85 if d < 2 else 0.45 * (1.0 - float(d) / band) * (1.0 if _bayer(x, y) < 0.65 else 0.35)
			var base := _image.get_pixel(x, y)
			_image.set_pixel(x, y, base.lerp(dark, amount))
			for step in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
				var nx: int = x + step.x
				var ny: int = y + step.y
				if _inside(nx, ny) and depth[ny * _size.x + nx] == -1:
					depth[ny * _size.x + nx] = d + 1
					next.append(ny * _size.x + nx)
		frontier = next
		level += 1
