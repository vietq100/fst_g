class_name ForgeFrame
extends RefCounted
## One baked frame of a Forge Hunter (D73, PHASE_13 §3.3): the renderer's square ops grouped into runs of
## the same cell size (1× body, 1.5× clothes and hats, 2× weapons, 2.5× glasses), each run baked into a
## small texture. Drawn in order with a 1/res transform, so every detail level stays exact without a 30×
## image or thousands of draw_rect calls per frame.
## Positions are in world pixels relative to the feet (the actor's origin); the art faces left.

const UNIT := 30.0
## Design pixel of the feet: the renderer's (0, 0) is design (-OX, -OY).
const FEET := Vector2(10.0, 37.0)
const ORIGIN := Vector2(14.0, 4.0)

var textures: Array[ImageTexture] = []
## Top-left of each texture, world px from the feet.
var positions: Array[Vector2] = []
## Size of one texel of each texture, world px.
var texels: Array[float] = []
## Union of the layers, world px from the feet.
var rect := Rect2()


static func bake(g: ForgeRenderer) -> ForgeFrame:
	var frame := ForgeFrame.new()
	var run: Array = []
	var cell := 0
	var x0 := 0
	var y0 := 0
	var texel := 0
	for op: Array in g.ops:
		var x := roundi(op[0])
		var y := roundi(op[1])
		var s := roundi(op[2])
		if not run.is_empty() and s == cell:
			# Same cell size: stay in the run while its grid (texel) stays at least half a cell.
			var t := _gcd(_gcd(texel, absi(x - x0)), absi(y - y0))
			if t * 2 >= s:
				texel = t
				run.append(op)
				continue
		frame._add_run(run, texel)
		run = [op]
		cell = s
		x0 = x
		y0 = y
		texel = s
	frame._add_run(run, texel)
	return frame


static func _gcd(a: int, b: int) -> int:
	while b != 0:
		var r := a % b
		a = b
		b = r
	return a


func _add_run(run: Array, texel: int) -> void:
	if run.is_empty():
		return
	var left := INF
	var top := INF
	var right := -INF
	var bottom := -INF
	for op: Array in run:
		left = minf(left, roundf(op[0]))
		top = minf(top, roundf(op[1]))
		right = maxf(right, roundf(op[0]) + roundf(op[2]))
		bottom = maxf(bottom, roundf(op[1]) + roundf(op[2]))
	var image := Image.create(int(right - left) / texel, int(bottom - top) / texel, false, Image.FORMAT_RGBA8)
	for op: Array in run:
		var ix := (roundi(op[0]) - int(left)) / texel
		var iy := (roundi(op[1]) - int(top)) / texel
		var n := roundi(op[2]) / texel
		# The HTML painter truncates the channels (`c | 0`).
		var color := Color(floorf(op[3]) / 255.0, floorf(op[4]) / 255.0, floorf(op[5]) / 255.0, op[6])
		if color.a >= 1.0:
			image.fill_rect(Rect2i(ix, iy, n, n), color)
			continue
		# Translucent ops (cast shadows, ground shadow, glass) blend over what the run already holds;
		# over earlier runs they blend when drawn.
		for yy in range(iy, iy + n):
			for xx in range(ix, ix + n):
				image.set_pixel(xx, yy, image.get_pixel(xx, yy).blend(color))
	var position := Vector2(left, top) / UNIT - ORIGIN - FEET
	var size := Vector2(right - left, bottom - top) / UNIT
	textures.append(ImageTexture.create_from_image(image))
	positions.append(position)
	texels.append(texel / UNIT)
	rect = Rect2(position, size) if textures.size() == 1 else rect.merge(Rect2(position, size))


## Draws the layers on `item` with the feet at `at`. `mirrored` faces right; `zoom` scales (UI);
## `rotation` turns the figure about the feet (lying bodies).
func draw(item: CanvasItem, at: Vector2, mirrored := false, zoom := 1.0, rotation := 0.0, tint := Color.WHITE) -> void:
	var base := Transform2D(rotation, at)
	var sx := -1.0 if mirrored else 1.0
	for i in textures.size():
		var t := texels[i] * zoom
		var p := positions[i] * zoom
		item.draw_set_transform_matrix(base * Transform2D(Vector2(sx * t, 0.0), Vector2(0.0, t), Vector2(sx * p.x, p.y)))
		item.draw_texture(textures[i], Vector2.ZERO, tint)
	item.draw_set_transform_matrix(Transform2D.IDENTITY)


## The rect as drawn (mirrored or not), world px from the feet.
func get_rect(mirrored := false) -> Rect2:
	if not mirrored:
		return rect
	return Rect2(Vector2(-rect.end.x, rect.position.y), rect.size)
