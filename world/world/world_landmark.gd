class_name WorldLandmark
extends StaticBody2D
## A landmark inside a hunting region (D62, placed on the isometric map in D75): a navigation obstacle
## drawn in the D57–D59 style, front-facing like the props.
## Dark Forest: mossy shrine with a glowing idol, stumps, fallen logs. Goblin Cave: hide tents,
## a campfire with a roast on a spit (animated flames and sparks), a skull totem. Ancient Ruins:
## broken knight statues, a rune obelisk, a collapsed arch. Origin at the base.

enum Kind { TENT, CAMPFIRE, TOTEM, STATUE, OBELISK, ARCH, STUMP, LOG, SHRINE }

const OUTLINE := Color("16161c")
const MOSS := Color("4f7a3a")
const STONE := Color("a8a499")
const RUNE := Color("7fd3ff")
const IDOL := Color("7dffb0")
const FLAME_FPS := 8.0
## Collision per kind: [shape size (radius, or rect size), offset]. Arches block only their
## pillars so Hunters can walk through.
const BLOCKERS := {
	Kind.TENT: [14.0], Kind.CAMPFIRE: [10.0], Kind.TOTEM: [6.0], Kind.STATUE: [10.0], Kind.OBELISK: [8.0],
	Kind.STUMP: [7.0], Kind.LOG: [Vector2(38, 9)], Kind.SHRINE: [Vector2(32, 8)],
}

var kind := Kind.STUMP
var tint := Color("8a6a44")
var _time := 0.0
var _frame_time := 0.0


## Night light of the glowing landmarks (DayNight, D77): kind -> [radius, offset, colour].
const LIGHTS := {
	Kind.CAMPFIRE: [44.0, Vector2(0, -6), Color(1.0, 0.6, 0.3)],
	Kind.SHRINE: [28.0, Vector2(0, -14), Color(0.5, 1.0, 0.7)],
	Kind.OBELISK: [26.0, Vector2(0, -26), Color(0.5, 0.82, 1.0)],
}


## Call before adding to the tree.
func setup(landmark_kind: Kind, color: Color = Color("8a6a44")) -> WorldLandmark:
	kind = landmark_kind
	tint = color
	if LIGHTS.has(kind):
		var light: Array = LIGHTS[kind]
		add_to_group(DayNight.LIGHT_GROUP)
		set_meta(&"light_radius", light[0])
		set_meta(&"light_offset", light[1])
		set_meta(&"light_color", light[2])
	add_to_group(&"navigation_obstacles")
	collision_layer = 1
	collision_mask = 0
	if kind == Kind.ARCH:
		for x: float in [-15.0, 15.0]:
			_add_circle(5.0, Vector2(x, -2))
	else:
		var size: Variant = BLOCKERS[kind][0]
		if size is Vector2:
			var shape := CollisionShape2D.new()
			var box := RectangleShape2D.new()
			box.size = size
			shape.shape = box
			shape.position = Vector2(0, -(size as Vector2).y * 0.5)
			add_child(shape)
		else:
			_add_circle(float(size), Vector2(0, -2))
	return self


func _add_circle(radius: float, at: Vector2) -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	shape.position = at
	add_child(shape)


func _process(delta: float) -> void:
	if kind != Kind.CAMPFIRE and kind != Kind.OBELISK and kind != Kind.SHRINE:
		set_process(false)
		return
	_time += delta
	_frame_time += delta
	if _frame_time >= 1.0 / FLAME_FPS:
		_frame_time -= 1.0 / FLAME_FPS
		# Off-screen flames do not need redrawing (D75).
		if is_visible_in_tree() and get_viewport_rect().grow(64.0).has_point(get_global_transform_with_canvas().origin):
			queue_redraw()


func _draw() -> void:
	match kind:
		Kind.TENT:
			_draw_tent()
		Kind.CAMPFIRE:
			_draw_campfire()
		Kind.TOTEM:
			_draw_totem()
		Kind.STATUE:
			_draw_statue()
		Kind.OBELISK:
			_draw_obelisk()
		Kind.ARCH:
			_draw_arch()
		Kind.STUMP:
			_draw_stump()
		Kind.LOG:
			_draw_log()
		Kind.SHRINE:
			_draw_shrine()


func _shadow(width: float, height: float = 4.0) -> void:
	draw_ellipse(Vector2(3, 0), width, height, Color(0, 0, 0, 0.28))


func _box(rect: Rect2, color: Color) -> void:
	draw_rect(rect.grow(1.0), OUTLINE)
	draw_rect(rect, color)


## Hide tent on crossed poles: lit left half, dark right half, seams, dark doorway, patch, ropes.
func _draw_tent() -> void:
	_shadow(20.0, 5.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-17, 1), Vector2(17, 1), Vector2(0, -24)]), OUTLINE)
	draw_colored_polygon(PackedVector2Array([Vector2(-16, 0), Vector2(0, 0), Vector2(0, -22)]), tint.lightened(0.08))
	draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(16, 0), Vector2(0, -22)]), tint.darkened(0.3))
	for i in range(1, 4):
		var t := i / 4.0
		draw_line(Vector2(-16.0 * (1.0 - t), -22.0 * t), Vector2(16.0 * (1.0 - t), -22.0 * t), tint.darkened(0.25), 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-5, 0), Vector2(5, 0), Vector2(0, -12)]), Color("2a1c14"))
	draw_line(Vector2(0, -12), Vector2(0, 0), Color("4a3424"), 1.0)
	for x: float in [-3.0, 3.0]:
		draw_line(Vector2(x, -26), Vector2(x * 0.2, -20), Color("5a3a22"), 2.0)
	draw_line(Vector2(-17, 1), Vector2(-21, 4), Color("5a3a22"), 1.0)
	draw_line(Vector2(17, 1), Vector2(21, 4), Color("5a3a22"), 1.0)
	draw_rect(Rect2(Vector2(6, -10), Vector2(5, 5)), tint.darkened(0.15))
	draw_rect(Rect2(Vector2(6, -10), Vector2(5, 5)), tint.darkened(0.5), false, 1.0)


## Stone ring, crossed logs, flickering flames, rising sparks and a roast on a spit.
func _draw_campfire() -> void:
	draw_ellipse(Vector2.ZERO, 14.0, 5.0, Color(0, 0, 0, 0.25))
	draw_ellipse(Vector2(0, -1), 24.0 + sin(_time * 7.0), 10.0, Color("ff8a3d", 0.12))
	for i in 7:
		var at := Vector2(cos(i * TAU / 7.0) * 9.0, sin(i * TAU / 7.0) * 3.5)
		draw_ellipse(at + Vector2(0, 0.5), 3.2, 2.0, OUTLINE)
		draw_ellipse(at, 2.8, 1.7, Color("7d7870"))
		draw_ellipse(at + Vector2(-0.6, -0.5), 1.2, 0.7, Color("a8a39a"))
	for stick: Array in [[Vector2(-7, 0), Vector2(6, -3), Color("6a4a2a")], [Vector2(-6, -3), Vector2(7, 1), Color("5a3a22")]]:
		draw_line(stick[0], stick[1], OUTLINE, 4.0)
		draw_line(stick[0], stick[1], stick[2], 2.5)
	var flames := [[-3.0, 10.0, Color("ff6a2e")], [2.0, 13.0, Color("ff9a3d")], [0.0, 8.0, Color("ffd27a")], [4.0, 7.0, Color("ff6a2e")]]
	for i in flames.size():
		var flame: Array = flames[i]
		var x: float = flame[0]
		var height: float = flame[1] + sin(_time * 11.0 + i * 1.7) * 1.5
		var sway := sin(_time * 9.0 + i) * 1.2
		draw_colored_polygon(PackedVector2Array([Vector2(x - 3.0, -2), Vector2(x + 3.0, -2), Vector2(x + sway, -2.0 - height)]), flame[2])
	draw_colored_polygon(PackedVector2Array([Vector2(-1.5, -2), Vector2(1.5, -2), Vector2(0, -7)]), Color("fff2a8"))
	for i in 3:
		var y := -14.0 - fmod(_time * 20.0 + i * 6.0, 18.0)
		draw_circle(Vector2(sin(_time * 3.0 + i) * 2.0, y), 0.8, Color("ffd27a", 0.8))
	for x: float in [-11.0, 11.0]:
		draw_line(Vector2(x, -12), Vector2(x, 0), Color("3a2414"), 1.5)
	draw_line(Vector2(-12, -11), Vector2(12, -11), Color("3a2414"), 1.5)
	draw_ellipse(Vector2(0, -11), 5.0, 3.0, OUTLINE)
	draw_ellipse(Vector2(0, -11.5), 4.2, 2.4, Color("a0522d"))
	draw_ellipse(Vector2(-1, -12.3), 2.0, 1.0, Color("c87a4a"))


## Painted pole with a horned skull and feathers.
func _draw_totem() -> void:
	_shadow(9.0, 3.0)
	_box(Rect2(-4, -33, 8, 33), Color("6a4a2a"))
	draw_rect(Rect2(-4, -33, 3, 33), Color("8a6a44"))
	for band: Array in [[-28.0, Color("c94a4a")], [-18.0, Color("e2c46b")], [-9.0, Color("3f8a83")]]:
		var y: float = band[0]
		var color: Color = band[1]
		draw_rect(Rect2(Vector2(-4, y), Vector2(8, 3)), color)
	draw_circle(Vector2(0, -38), 6.0, OUTLINE)
	draw_circle(Vector2(0, -38), 5.0, Color("eee8d8"))
	draw_rect(Rect2(-3, -38, 2, 2), OUTLINE)
	draw_rect(Rect2(1, -38, 2, 2), OUTLINE)
	draw_rect(Rect2(-2, -35, 4, 1.5), OUTLINE)
	for side: float in [-1.0, 1.0]:
		var horn := PackedVector2Array([Vector2(side * 4.0, -41), Vector2(side * 9.0, -44), Vector2(side * 10.0, -49)])
		draw_polyline(horn, OUTLINE, 3.0)
		draw_polyline(horn, Color("d8cfb4"), 1.5)
	draw_line(Vector2(4, -24), Vector2(9, -20), Color("c94a4a"), 2.0)
	draw_line(Vector2(-4, -14), Vector2(-9, -11), Color("3a3f48"), 2.0)


## Armoured knight on a plinth, sword raised, cracked and mossy, a fallen fragment beside it.
func _draw_statue() -> void:
	var stone := STONE
	_shadow(16.0, 5.0)
	_box(Rect2(-11, -7.5, 22, 7.5), stone.darkened(0.12))
	draw_rect(Rect2(-11, -7.5, 22, 1.5), stone.lightened(0.1))
	_box(Rect2(-8, -11.5, 16, 4), stone.darkened(0.05))
	draw_colored_polygon(PackedVector2Array([Vector2(-7, -12), Vector2(7, -12), Vector2(6, -30), Vector2(-6, -30)]), OUTLINE)
	draw_colored_polygon(PackedVector2Array([Vector2(-6, -12), Vector2(6, -12), Vector2(5, -29), Vector2(-5, -29)]), stone)
	draw_colored_polygon(PackedVector2Array([Vector2(1, -12), Vector2(6, -12), Vector2(5, -29), Vector2(1, -29)]), stone.darkened(0.18))
	draw_circle(Vector2(0, -34), 5.5, OUTLINE)
	draw_circle(Vector2(0, -34), 4.5, stone)
	draw_rect(Rect2(-3, -35, 6, 1.5), stone.darkened(0.4))
	_box(Rect2(-8, -28, 2.5, 9), stone.lightened(0.08))
	draw_line(Vector2(7, -26), Vector2(13, -40), OUTLINE, 4.0)
	draw_line(Vector2(7, -26), Vector2(13, -40), stone.lightened(0.15), 2.0)
	draw_line(Vector2(10, -30), Vector2(15, -28), OUTLINE, 2.0)
	draw_polyline(PackedVector2Array([Vector2(-2, -24), Vector2(1, -18), Vector2(-1, -13)]), stone.darkened(0.45), 1.0)
	draw_circle(Vector2(-6, -9), 2.4, MOSS)
	draw_circle(Vector2(8, -3), 2.0, MOSS)
	_box(Rect2(13.5, -2.5, 3, 2), stone)


## Tapering obelisk with glowing runes that pulse.
func _draw_obelisk() -> void:
	var stone := Color("8a8780")
	var pulse := 0.6 + 0.4 * sin(_time * 2.0)
	_shadow(10.0, 4.0)
	_box(Rect2(-9, -5.5, 18, 5.5), stone.darkened(0.1))
	draw_colored_polygon(PackedVector2Array([Vector2(-7, -6), Vector2(7, -6), Vector2(5, -44), Vector2(-5, -44)]), OUTLINE)
	draw_colored_polygon(PackedVector2Array([Vector2(-6, -6), Vector2(6, -6), Vector2(4, -43), Vector2(-4, -43)]), stone)
	draw_colored_polygon(PackedVector2Array([Vector2(1, -6), Vector2(6, -6), Vector2(4, -43), Vector2(1, -43)]), stone.darkened(0.2))
	draw_colored_polygon(PackedVector2Array([Vector2(-5, -44), Vector2(5, -44), Vector2(0, -52)]), OUTLINE)
	draw_colored_polygon(PackedVector2Array([Vector2(-4, -44), Vector2(4, -44), Vector2(0, -51)]), stone.lightened(0.1))
	draw_circle(Vector2(0, -26), 10.0, Color(RUNE, 0.08 * pulse))
	for y: float in [-14.0, -22.0, -30.0, -38.0]:
		draw_rect(Rect2(-2, y, 3, 4), Color(RUNE, 0.35 * pulse))
		draw_rect(Rect2(-1.5, y + 0.5, 2, 3), Color(RUNE, 0.6 + 0.4 * pulse))


## Two pillars, half an arch still standing, fallen blocks and moss.
func _draw_arch() -> void:
	var stone := Color("b9b4a3")
	_shadow(24.0, 5.0)
	for x: float in [-18.0, 12.0]:
		_box(Rect2(x, -29, 6, 29), stone)
		draw_rect(Rect2(x, -29, 2, 29), stone.lightened(0.15))
		for k in range(1, 4):
			draw_line(Vector2(x, -29.0 + k * 7.0), Vector2(x + 6.0, -29.0 + k * 7.0), stone.darkened(0.3), 1.0)
	var curve := PackedVector2Array()
	for i in 7:
		var angle := PI + i * PI * 0.55 / 6.0
		curve.append(Vector2(-3.0 + cos(angle) * 15.0, -30.0 + sin(angle) * 12.0))
	draw_polyline(curve, OUTLINE, 7.0)
	draw_polyline(curve, stone, 5.0)
	for i in range(1, curve.size() - 1):
		draw_circle(curve[i], 0.6, stone.darkened(0.3))
	for block: Rect2 in [Rect2(14, -5, 8, 5), Rect2(22, -5, 5, 4), Rect2(-26, -4, 6, 4)]:
		_box(block, stone.darkened(0.06))
		draw_rect(Rect2(block.position, Vector2(block.size.x, 1)), stone.lightened(0.15))
	draw_circle(Vector2(-14, -2), 2.5, MOSS)
	draw_circle(Vector2(15, -31), 2.0, MOSS)


func _draw_stump() -> void:
	var wood := Color("6a4a2a")
	_shadow(10.0, 3.5)
	_box(Rect2(-6, -9, 12, 9), wood)
	draw_rect(Rect2(-6, -9, 3, 9), wood.lightened(0.12))
	draw_ellipse(Vector2(0, -9), 7.0, 3.0, OUTLINE)
	draw_ellipse(Vector2(0, -9.5), 6.0, 2.4, Color("c9a26a"))
	draw_ellipse(Vector2(0, -9.5), 3.5, 1.4, Color("c9a26a").darkened(0.15))
	draw_ellipse(Vector2(0, -9.5), 1.2, 0.5, Color("8a6a44"))
	for side: float in [-1.0, 1.0]:
		draw_line(Vector2(side * 6.0, -1), Vector2(side * 10.0, 1), wood, 2.0)
	draw_line(Vector2(4, -3), Vector2(4, 0), Color("e6e2d8"), 1.0)
	draw_circle(Vector2(4, -3), 1.8, Color("c94a4a"))


func _draw_log() -> void:
	var wood := Color("5a3f2a")
	_shadow(22.0, 4.0)
	_box(Rect2(-19, -8, 36, 7), wood)
	draw_rect(Rect2(-19, -8, 36, 2), wood.lightened(0.15))
	for x: float in [-12.0, -2.0, 8.0]:
		draw_line(Vector2(x, -8), Vector2(x + 3.0, -1), wood.darkened(0.3), 1.0)
	draw_ellipse(Vector2(18, -4.5), 4.0, 5.0, OUTLINE)
	draw_ellipse(Vector2(18, -4.5), 3.0, 4.0, Color("c9a26a"))
	draw_ellipse(Vector2(18, -4.5), 1.2, 1.6, Color("c9a26a").darkened(0.25))
	draw_circle(Vector2(-8, -9), 2.2, MOSS)
	draw_circle(Vector2(-4, -9.5), 1.6, MOSS.lightened(0.2))
	for mushroom: Array in [[-14.0, Color("c94a4a")], [6.0, Color("d9b356")]]:
		var x: float = mushroom[0]
		draw_line(Vector2(x, -8), Vector2(x, -11), Color("e6e2d8"), 1.0)
		draw_ellipse(Vector2(x, -11.5), 2.2, 1.3, mushroom[1])


## Mossy stone shrine: steps, two pillars, a roof, ivy and a softly glowing idol.
func _draw_shrine() -> void:
	var stone := Color("7d7a72")
	var pulse := 0.6 + 0.4 * sin(_time * 1.5)
	_shadow(18.0, 5.0)
	_box(Rect2(-15, -4.5, 30, 4.5), stone.darkened(0.1))
	for x: float in [-12.0, 8.0]:
		_box(Rect2(x, -27, 4, 23), stone)
	draw_colored_polygon(PackedVector2Array([Vector2(-17, -27), Vector2(17, -27), Vector2(13, -34), Vector2(-13, -34)]), OUTLINE)
	draw_colored_polygon(PackedVector2Array([Vector2(-16, -28), Vector2(16, -28), Vector2(12, -33), Vector2(-12, -33)]), stone.lightened(0.08))
	draw_colored_polygon(PackedVector2Array([Vector2(-12, -34), Vector2(12, -34), Vector2(0, -40)]), OUTLINE)
	draw_colored_polygon(PackedVector2Array([Vector2(-11, -34.5), Vector2(11, -34.5), Vector2(0, -39)]), stone.darkened(0.05))
	draw_circle(Vector2(0, -14), 9.0, Color(IDOL, 0.12 * pulse))
	_box(Rect2(-2, -17, 4, 11), Color("4f8a3a"))
	draw_circle(Vector2(0, -19), 3.0, OUTLINE)
	draw_circle(Vector2(0, -19), 2.2, Color(IDOL, 0.7 + 0.3 * pulse))
	for leaf: Vector2 in [Vector2(-14, -30), Vector2(12, -32), Vector2(-10, -6), Vector2(14, -4)]:
		draw_circle(leaf, 2.2, Color("3f6a36"))
	draw_polyline(PackedVector2Array([Vector2(-11, -27), Vector2(-13, -18), Vector2(-11, -10)]), Color("3f6a36"), 1.5)
