class_name WaterPainter
extends RefCounted
## Paints the water around the plateaus into one baked image (tools/bake_ground.gd): depth bands
## from shallow turquoise at the shore to deep blue, caustic streaks, foam along the shore, lily
## pads and reeds in the shallows, rocks and small waves out in the open water.
## One texel = SCALE world px. The image covers the world bounds plus a margin.

const SCALE := 4
## Feature sizes are written in 2-world-px texels; U converts them.
const U := 2.0 / SCALE
const MARGIN := 760.0
## Distance field cell (world px).
const CELL := 8
## Land counts this far below its front edges (the cliff faces).
const CLIFF := 42.0

var _world: WorldService
var _origin := Vector2.ZERO
var _size := Vector2i.ZERO
var _grid_size := Vector2i.ZERO
var _dist: PackedFloat32Array
var _image: Image
var _big := FastNoiseLite.new()
var _mid := FastNoiseLite.new()
var _fine := FastNoiseLite.new()
var _ridge := FastNoiseLite.new()


static func layout(world: WorldService) -> Dictionary:
	var area := world.get_bounds(MARGIN)
	var origin := Vector2(floorf(area.position.x / SCALE) * SCALE, floorf(area.position.y / SCALE) * SCALE)
	var size := Vector2i(ceili((area.end.x - origin.x) / SCALE), ceili((area.end.y - origin.y) / SCALE))
	return {"origin": origin, "size": size}


func paint(world: WorldService) -> Image:
	_world = world
	var box := layout(world)
	_origin = box["origin"]
	_size = box["size"]
	for entry in [[_big, 0.004, 1], [_mid, 0.015, 2], [_fine, 0.06, 3]]:
		var noise: FastNoiseLite = entry[0]
		noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		noise.seed = 4242 + entry[2] * 31
		noise.frequency = entry[1]
	_ridge.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_ridge.seed = 9001
	_ridge.frequency = 0.022
	_build_distance()
	_image = Image.create(_size.x, _size.y, false, Image.FORMAT_RGBA8)
	_fill()
	_scatter_rocks()
	_scatter_shore(Color("4f9a4a"), true)
	_scatter_shore(Color("6a8a3a"), false)
	return _image


# --- Distance to land ----------------------------------------------------------------------------

func _is_land(p: Vector2) -> bool:
	if _world.region_at(p) != null or _world.region_at(p - Vector2(0, CLIFF)) != null:
		return true
	for gate in _world.get_gates():
		if WorldService.rect_has_point(gate.tiles.grow(1), p):
			return true
	return false


func _build_distance() -> void:
	_grid_size = Vector2i(ceili(_size.x * SCALE / float(CELL)) + 1, ceili(_size.y * SCALE / float(CELL)) + 1)
	_dist = PackedFloat32Array()
	_dist.resize(_grid_size.x * _grid_size.y)
	for gy in _grid_size.y:
		for gx in _grid_size.x:
			var p := _origin + Vector2(gx + 0.5, gy + 0.5) * CELL
			_dist[gy * _grid_size.x + gx] = 0.0 if _is_land(p) else 1.0e6
	# Chamfer distance transform (two passes).
	var d1 := float(CELL)
	var d2 := CELL * 1.4142
	for gy in range(0, _grid_size.y):
		for gx in range(0, _grid_size.x):
			var i := gy * _grid_size.x + gx
			var best := _dist[i]
			if gx > 0:
				best = minf(best, _dist[i - 1] + d1)
			if gy > 0:
				best = minf(best, _dist[i - _grid_size.x] + d1)
				if gx > 0:
					best = minf(best, _dist[i - _grid_size.x - 1] + d2)
				if gx < _grid_size.x - 1:
					best = minf(best, _dist[i - _grid_size.x + 1] + d2)
			_dist[i] = best
	for gy in range(_grid_size.y - 1, -1, -1):
		for gx in range(_grid_size.x - 1, -1, -1):
			var i := gy * _grid_size.x + gx
			var best := _dist[i]
			if gx < _grid_size.x - 1:
				best = minf(best, _dist[i + 1] + d1)
			if gy < _grid_size.y - 1:
				best = minf(best, _dist[i + _grid_size.x] + d1)
				if gx < _grid_size.x - 1:
					best = minf(best, _dist[i + _grid_size.x + 1] + d2)
				if gx > 0:
					best = minf(best, _dist[i + _grid_size.x - 1] + d2)
			_dist[i] = best


## Bilinear distance (world px) at a world point.
func _distance_at(p: Vector2) -> float:
	var f := (p - _origin) / CELL - Vector2(0.5, 0.5)
	var x0 := clampi(floori(f.x), 0, _grid_size.x - 2)
	var y0 := clampi(floori(f.y), 0, _grid_size.y - 2)
	var tx := clampf(f.x - x0, 0.0, 1.0)
	var ty := clampf(f.y - y0, 0.0, 1.0)
	var a := _dist[y0 * _grid_size.x + x0]
	var b := _dist[y0 * _grid_size.x + x0 + 1]
	var c := _dist[(y0 + 1) * _grid_size.x + x0]
	var d := _dist[(y0 + 1) * _grid_size.x + x0 + 1]
	return lerpf(lerpf(a, b, tx), lerpf(c, d, tx), ty)


static func _bayer(x: int, y: int) -> float:
	return GroundPainter.BAYER[(x & 3) + (y & 3) * 4] / 16.0


# --- Water body ------------------------------------------------------------------------------------

func _fill() -> void:
	var deep := Color("12394a")
	var mid := Color("1b5a73")
	var shallow := Color("277a8d")
	var lagoon := Color("3a9a9f")
	var foam := Color("e6f6f4")
	for y in _size.y:
		for x in _size.x:
			var p := _origin + Vector2(x + 0.5, y + 0.5) * SCALE
			var d := _distance_at(p)
			# Wobble the depth so the bands are organic.
			var wob := _mid.get_noise_2d(p.x, p.y) * 26.0 + _fine.get_noise_2d(p.x, p.y) * 5.0
			var depth := d + wob
			var dither := _bayer(x, y) * 14.0 - 7.0
			var color := deep
			if depth + dither < 150.0:
				color = mid
			if depth + dither < 70.0:
				color = shallow
			if depth + dither < 28.0:
				color = lagoon
			# Large soft colour drift in the open water.
			var drift := _big.get_noise_2d(p.x, p.y)
			if color == deep and drift > 0.5:
				color = deep.lightened(0.04)
			# Caustic / wave streaks.
			var ridge := 1.0 - absf(_ridge.get_noise_2d(p.x, p.y * 1.7))
			if ridge > 0.975 and d < 200.0:
				color = color.lightened(0.1)
			# Foam where the water meets the cliff foot.
			var foam_edge := 8.0 + _mid.get_noise_2d(p.x * 1.3, p.y * 1.3) * 3.0
			if d > 0.5 and d < foam_edge - 3.0:
				# Churned water right at the foot: light, rippled.
				color = lagoon.lightened(0.18) if int(d + x * 0.5) % 5 else foam
			elif d >= foam_edge - 3.0 and d < foam_edge:
				color = foam
			elif d >= foam_edge and d < foam_edge + 3.0 and _bayer(x, y) < 0.25:
				color = foam.darkened(0.12)
			_image.set_pixel(x, y, color)
	_scatter_waves()


## Small crest marks (~) on the open water.
func _scatter_waves() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 123
	for i in 500:
		var p := _origin + Vector2(rng.randf() * _size.x, rng.randf() * _size.y) * SCALE
		var d := _distance_at(p)
		if d < 40.0:
			continue
		var tx := int((p.x - _origin.x) / SCALE)
		var ty := int((p.y - _origin.y) / SCALE)
		var width := maxi(int((4 + rng.randi_range(0, 6)) * U), 3)
		var tone := Color("3f8fa8") if d < 200.0 else Color("2a6a85")
		for k in width:
			var yy := ty + (1 if k < width / 3 or k > width * 2 / 3 else 0)
			if tx + k < _size.x and yy < _size.y:
				_image.set_pixel(tx + k, yy, tone)


## Small rocks standing in the water away from the shore.
func _scatter_rocks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var placed := 0
	for i in 900:
		var p := _origin + Vector2(rng.randf() * _size.x, rng.randf() * _size.y) * SCALE
		var d := _distance_at(p)
		if d < 110.0 or d > 420.0 or placed > 14:
			continue
		placed += 1
		var tx := int((p.x - _origin.x) / SCALE)
		var ty := int((p.y - _origin.y) / SCALE)
		var r := 5 + rng.randi_range(0, 7)
		_ellipse(tx, ty + 2, r + 2, int(r * 0.55) + 2, Color("e6f6f4", 0.35))
		_ellipse(tx, ty, r, int(r * 0.6), Color("4a5560"))
		_ellipse(tx - 1, ty - 2, int(r * 0.7), int(r * 0.35), Color("77848f"))
		_ellipse(tx - 2, ty - 3, int(r * 0.35), int(r * 0.18), Color("a9b8c4"))


func _ellipse(cx: int, cy: int, rx: int, ry: int, color: Color) -> void:
	rx = maxi(int(rx * U), 1)
	ry = maxi(int(ry * U), 1)
	for y in range(cy - ry, cy + ry + 1):
		for x in range(cx - rx, cx + rx + 1):
			if x < 0 or y < 0 or x >= _size.x or y >= _size.y:
				continue
			if Vector2(float(x - cx) / rx, float(y - cy) / ry).length() <= 1.0:
				_image.set_pixel(x, y, _image.get_pixel(x, y).lerp(Color(color, 1.0), color.a))


## Lily pads (`pads`) or reed tufts along the shore, in the shallows.
func _scatter_shore(color: Color, pads: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5 if pads else 6
	var placed := 0
	for i in 8000:
		var p := _origin + Vector2(rng.randf() * _size.x, rng.randf() * _size.y) * SCALE
		var d := _distance_at(p)
		var wanted_min := 22.0 if pads else 12.0
		var wanted_max := 70.0 if pads else 26.0
		if d < wanted_min or d > wanted_max or placed > (50 if pads else 70):
			continue
		placed += 1
		var tx := int((p.x - _origin.x) / SCALE)
		var ty := int((p.y - _origin.y) / SCALE)
		if pads:
			for k in 1 + rng.randi_range(0, 2):
				var ox := tx + int(rng.randi_range(-7, 7) * U)
				var oy := ty + int(rng.randi_range(-3, 3) * U)
				_ellipse(ox, oy, 4, 2, color.darkened(0.25))
				_ellipse(ox, oy - 1, 3, 1, color)
				if rng.randf() < 0.3:
					_ellipse(ox + 1, oy - 1, 1, 1, Color("f4a6c8"))
		else:
			for k in 3 + rng.randi_range(0, 3):
				var bx := tx + int(rng.randi_range(-5, 5) * U)
				var height := maxi(int((5 + rng.randi_range(0, 6)) * U), 3)
				for h in height:
					var px := bx + int(sin(h * 0.5 + k) * 1.2)
					var py := ty - h
					if px >= 0 and py >= 0 and px < _size.x and py < _size.y:
						_image.set_pixel(px, py, color.lightened(0.15 * float(h) / height))
