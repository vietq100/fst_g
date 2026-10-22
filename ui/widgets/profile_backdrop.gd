class_name ProfileBackdrop
extends Control
## Own background of the login screen: a night sky with stars and a moon, far mountains, pine
## silhouettes and a sleepy village with lit windows and chimney smoke. Drawn in code (no assets), a
## gentle twinkle and drifting smoke only.

const SKY_TOP := Color("070b18")
const SKY_MID := Color("17254a")
const SKY_LOW := Color("3a3f72")
const HORIZON := Color("c98a6a")

var _time := 0.0
var _stars: Array[Vector3] = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 90:
		_stars.append(Vector3(rng.randf(), rng.randf() * 0.62, rng.randf() * TAU))


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	_draw_sky(w, h)
	_draw_moon(w, h)
	_draw_ridge(w, h, 0.58, 0.16, 11.0, Color("1d2547"), 1.3)
	_draw_ridge(w, h, 0.66, 0.12, 29.0, Color("141b36"), 2.1)
	_draw_village(w, h)
	_draw_ridge(w, h, 0.84, 0.07, 47.0, Color("0a0f1f"), 3.0)
	_draw_pines(w, h)
	draw_rect(Rect2(0, h * 0.94, w, h * 0.06), Color("070a14"))


func _draw_sky(w: float, h: float) -> void:
	var bands := 48
	for i in bands:
		var t := float(i) / float(bands - 1)
		var color := SKY_TOP.lerp(SKY_MID, minf(t * 1.6, 1.0))
		if t > 0.55:
			color = SKY_MID.lerp(SKY_LOW, (t - 0.55) / 0.3).lerp(HORIZON, clampf((t - 0.82) / 0.18, 0.0, 1.0) * 0.55)
		draw_rect(Rect2(0, h * t * 0.9, w, h * 0.9 / bands + 1.0), color)
	for star in _stars:
		var twinkle := 0.55 + 0.45 * sin(_time * 1.6 + star.z * 3.0)
		var at := Vector2(star.x * w, star.y * h)
		draw_rect(Rect2(at, Vector2(2, 2)), Color(1, 0.97, 0.85, 0.35 + 0.5 * twinkle))
		if int(star.z * 10.0) % 7 == 0:
			draw_rect(Rect2(at + Vector2(-2, 0), Vector2(6, 2)), Color(1, 1, 1, 0.18 * twinkle))
			draw_rect(Rect2(at + Vector2(0, -2), Vector2(2, 6)), Color(1, 1, 1, 0.18 * twinkle))


func _draw_moon(w: float, h: float) -> void:
	var centre := Vector2(w * 0.78, h * 0.17)
	var radius := minf(w, h) * 0.075
	for i in 6:
		draw_circle(centre, radius * (3.4 - i * 0.45), Color(0.75, 0.82, 1.0, 0.035))
	draw_circle(centre, radius, Color("e9ecf8"))
	draw_circle(centre + Vector2(-radius * 0.3, -radius * 0.2), radius * 0.2, Color("cfd5ea"))
	draw_circle(centre + Vector2(radius * 0.35, radius * 0.3), radius * 0.28, Color("d6dbee"))


func _draw_ridge(w: float, h: float, base: float, amp: float, seed_shift: float, color: Color, rough: float) -> void:
	var points := PackedVector2Array([Vector2(0, h)])
	var step := maxf(w / 40.0, 6.0)
	var x := 0.0
	while x <= w + step:
		var n := sin(x * 0.011 * rough + seed_shift) * 0.55 + sin(x * 0.027 * rough + seed_shift * 2.0) * 0.3 + sin(x * 0.061 + seed_shift) * 0.15
		points.append(Vector2(x, h * (base - amp * (0.5 + 0.5 * n))))
		x += step
	points.append(Vector2(w + step, h))
	draw_colored_polygon(points, color)


func _draw_village(w: float, h: float) -> void:
	var ground := h * 0.8
	draw_rect(Rect2(0, ground, w, h * 0.2), Color("0f1429"))
	var house_w := clampf(w * 0.11, 34.0, 60.0)
	var count := int(w / (house_w * 1.7))
	for i in count:
		var x := (float(i) + 0.5) * w / float(count) + sin(i * 12.7) * house_w * 0.3
		var scale := 0.8 + 0.4 * fmod(absf(sin(i * 3.1)), 1.0)
		_house(Vector2(x, ground + sin(i * 5.3) * 6.0), house_w * scale, i)


func _house(base: Vector2, width: float, index: int) -> void:
	var height := width * 0.62
	var body := Rect2(base + Vector2(-width * 0.5, -height), Vector2(width, height))
	draw_rect(body, Color("1b2240"))
	draw_rect(Rect2(body.position, Vector2(width * 0.12, height)), Color("252d52"))
	var roof := PackedVector2Array([body.position + Vector2(-width * 0.1, 0), body.position + Vector2(width * 0.5, -height * 0.55), body.end + Vector2(width * 0.1, -height)])
	draw_colored_polygon(roof, Color("3a2438") if index % 2 == 0 else Color("2c3552"))
	var lit := (index * 7 + int(_time * 0.3)) % 3 != 0
	var glow := Color("ffcf6b") if lit else Color("2a3156")
	var window := Rect2(body.position + Vector2(width * 0.3, height * 0.3), Vector2(width * 0.2, height * 0.28))
	if lit:
		draw_rect(window.grow(width * 0.12), Color(1, 0.8, 0.4, 0.12))
	draw_rect(window, glow)
	draw_rect(Rect2(body.position + Vector2(width * 0.62, height * 0.3), Vector2(width * 0.16, height * 0.28)), glow if index % 3 != 1 else Color("2a3156"))
	if index % 2 == 0:
		var chimney := Rect2(body.position + Vector2(width * 0.72, -height * 0.45), Vector2(width * 0.1, height * 0.3))
		draw_rect(chimney, Color("141a33"))
		for k in 4:
			var phase := fmod(_time * 0.35 + k * 0.25 + index * 0.13, 1.0)
			draw_circle(chimney.position + Vector2(width * 0.05 + sin(phase * 6.0 + k) * 5.0, -phase * height * 1.2), 3.0 + phase * 5.0, Color(0.7, 0.75, 0.9, 0.22 * (1.0 - phase)))


func _draw_pines(w: float, h: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var ground := h * 0.95
	for side in 2:
		var count := int(w / 60.0) + 2
		for i in count:
			var x := rng.randf_range(0.0, w * 0.28) if side == 0 else w - rng.randf_range(0.0, w * 0.28)
			var tall := rng.randf_range(0.13, 0.26) * h
			_pine(Vector2(x, ground + rng.randf_range(-6.0, 8.0)), tall)


func _pine(base: Vector2, height: float) -> void:
	var color := Color("060a14")
	var width := height * 0.38
	for tier in 4:
		var t := float(tier) / 4.0
		var y := base.y - height * (0.25 + t * 0.7)
		var half := width * (1.0 - t * 0.7)
		draw_colored_polygon(PackedVector2Array([Vector2(base.x - half, y + height * 0.28), Vector2(base.x, y - height * 0.05), Vector2(base.x + half, y + height * 0.28)]), color)
	draw_rect(Rect2(base.x - width * 0.07, base.y - height * 0.25, width * 0.14, height * 0.25), color)
