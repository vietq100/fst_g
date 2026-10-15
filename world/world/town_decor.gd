class_name TownDecor
extends Node2D
## One small decoration of the Town (lamp post, barrels, bench, flower bed, fountain, well, statue,
## signpost, haystack). Pixel-style, drawn at Hunter scale, no collision (Hunters walk through).
## The world hides it while a building stands on or next to its tile. Origin = the base.

enum Kind { LAMP, BARRELS, BENCH, FLOWERBED, FOUNTAIN, WELL, STATUE, SIGN, HAY }

const OUTLINE := Color("16161c")
const WOOD := Color("8b5e3c")
const WOOD_DARK := Color("5a3b22")
const STONE := Color("9a968a")
const STONE_DARK := Color("6e6a60")
const STONE_LIGHT := Color("c4c0b2")
const IRON := Color("3a3d46")
const FLOWERS: Array[Color] = [Color("f4f1ea"), Color("f2c94c"), Color("e8789a"), Color("a78bfa"), Color("ff7a5a")]

var kind: Kind = Kind.LAMP
var tile := Vector2i.ZERO
## Distinguishes copies of the same kind (flower colours, barrel layout).
var variant := 0
var _time := 0.0


func _process(delta: float) -> void:
	if kind == Kind.LAMP or kind == Kind.FOUNTAIN:
		_time += delta
		queue_redraw()


func _draw() -> void:
	match kind:
		Kind.LAMP:
			_lamp()
		Kind.BARRELS:
			_barrels()
		Kind.BENCH:
			_bench()
		Kind.FLOWERBED:
			_flowerbed()
		Kind.FOUNTAIN:
			_fountain()
		Kind.WELL:
			_well()
		Kind.STATUE:
			_statue()
		Kind.SIGN:
			_sign()
		Kind.HAY:
			_hay()


func _shadow(rx: float, ry: float) -> void:
	draw_ellipse(Vector2(1, 1), rx, ry, Color(0, 0, 0, 0.3))


func _lamp() -> void:
	_shadow(6, 2.5)
	draw_rect(Rect2(-2, -4, 4, 4), OUTLINE)
	draw_rect(Rect2(-1.5, -4, 3, 3.5), IRON)
	draw_rect(Rect2(-1.5, -30, 3, 26.5), OUTLINE)
	draw_rect(Rect2(-1, -30, 2, 26), IRON)
	var flicker := 0.85 + 0.15 * sin(_time * 5.0 + variant)
	draw_circle(Vector2(0, -35), 16.0, Color(1.0, 0.8, 0.35, 0.10 * flicker))
	draw_circle(Vector2(0, -35), 9.0, Color(1.0, 0.8, 0.35, 0.16 * flicker))
	draw_rect(Rect2(-5, -42, 10, 11), OUTLINE)
	draw_rect(Rect2(-4, -41, 8, 9), Color("ffd66b"))
	draw_rect(Rect2(-4, -41, 8, 3), Color("fff1b0"))
	draw_rect(Rect2(-6, -44, 12, 3), OUTLINE)
	draw_rect(Rect2(-5, -44, 10, 2), IRON)


func _barrels() -> void:
	_shadow(13, 4)
	var spots := [Vector2(-6, 0), Vector2(6, 1), Vector2(0, -7)] if variant % 2 == 0 else [Vector2(-5, 0), Vector2(7, 0)]
	for spot: Vector2 in spots:
		_barrel(spot)


func _barrel(at: Vector2) -> void:
	draw_rect(Rect2(at + Vector2(-5.5, -12), Vector2(11, 12)), OUTLINE)
	draw_rect(Rect2(at + Vector2(-4.5, -11), Vector2(9, 10)), WOOD)
	for band: float in [-9.0, -3.0]:
		draw_rect(Rect2(at + Vector2(-4.5, band), Vector2(9, 1.5)), IRON)
	draw_rect(Rect2(at + Vector2(-4.5, -11), Vector2(2.5, 10)), WOOD.lightened(0.12))
	draw_ellipse(at + Vector2(0, -11), 4.5, 1.8, WOOD_DARK)
	draw_ellipse(at + Vector2(0, -11.4), 3.4, 1.2, WOOD.lightened(0.2))


func _bench() -> void:
	_shadow(13, 3)
	for x: float in [-9.0, 7.0]:
		draw_rect(Rect2(x, -8, 3, 8), OUTLINE)
		draw_rect(Rect2(x + 0.5, -7.5, 2, 7.5), WOOD_DARK)
	draw_rect(Rect2(-12, -10, 24, 5), OUTLINE)
	draw_rect(Rect2(-11, -9, 22, 3), WOOD)
	draw_rect(Rect2(-11, -9, 22, 1), WOOD.lightened(0.2))
	draw_rect(Rect2(-12, -17, 24, 5), OUTLINE)
	draw_rect(Rect2(-11, -16, 22, 3), WOOD.darkened(0.1))


func _flowerbed() -> void:
	var points := PackedVector2Array([Vector2(0, -8), Vector2(18, 0), Vector2(0, 8), Vector2(-18, 0)])
	draw_colored_polygon(Geometry2D.offset_polygon(points, 2.0)[0], STONE_DARK)
	draw_colored_polygon(points, Color("5a3f2a"))
	for i in 11:
		var h := hash(Vector2i(variant, i))
		var fx := float(h % 28) - 14.0
		var fy := float((h / 31) % 10) - 5.0
		if absf(fx) / 15.0 + absf(fy) / 6.5 > 1.0:
			continue
		var color := FLOWERS[(h / 7 + variant) % FLOWERS.size()]
		draw_line(Vector2(fx, fy), Vector2(fx, fy - 4), Color("3f6a36"), 1.0)
		draw_circle(Vector2(fx, fy - 5), 2.0, color)
		draw_circle(Vector2(fx, fy - 5), 0.7, Color("f2c94c") if color != FLOWERS[1] else Color("fff3b0"))


func _fountain() -> void:
	_shadow(24, 9)
	draw_ellipse(Vector2(0, 0), 22, 10, OUTLINE)
	draw_ellipse(Vector2(0, -2), 21, 9, STONE_DARK)
	draw_ellipse(Vector2(0, -6), 21, 9, STONE)
	draw_ellipse(Vector2(0, -7), 17, 7, Color("3f86b8"))
	var ripple := fmod(_time * 0.8, 1.0)
	draw_arc(Vector2(0, -7), 6.0 + ripple * 9.0, 0, TAU, 24, Color(0.85, 0.96, 1.0, 0.5 * (1.0 - ripple)), 1.0)
	draw_rect(Rect2(-3, -26, 6, 20), OUTLINE)
	draw_rect(Rect2(-2, -25, 4, 18), STONE_LIGHT)
	draw_ellipse(Vector2(0, -27), 7, 3, OUTLINE)
	draw_ellipse(Vector2(0, -28), 6, 2.5, STONE)
	for i in 5:
		var t := fmod(_time * 1.3 + i * 0.2, 1.0)
		var angle := (i - 2) * 0.5
		var at := Vector2(sin(angle) * 9.0 * t, -30.0 + 20.0 * t * t - 6.0 * (1.0 - t))
		draw_circle(at, 1.2, Color(0.9, 0.98, 1.0, 0.85 * (1.0 - t * 0.6)))


func _well() -> void:
	_shadow(12, 4)
	draw_ellipse(Vector2(0, -2), 11, 5, OUTLINE)
	draw_rect(Rect2(-10, -14, 20, 12), OUTLINE)
	draw_rect(Rect2(-9, -13, 18, 10), STONE)
	draw_rect(Rect2(-9, -13, 18, 3), STONE_LIGHT)
	for x: float in [-5.0, 1.0]:
		draw_line(Vector2(x, -13), Vector2(x, -3), STONE_DARK, 1.0)
	draw_ellipse(Vector2(0, -14), 10, 4, OUTLINE)
	draw_ellipse(Vector2(0, -14), 8.5, 3, Color("1c3a4a"))
	for x: float in [-9.0, 8.0]:
		draw_rect(Rect2(x, -34, 2, 22), OUTLINE)
		draw_rect(Rect2(x + 0.3, -33.5, 1.4, 21.5), WOOD_DARK)
	draw_colored_polygon(PackedVector2Array([Vector2(-13, -33), Vector2(0, -42), Vector2(13, -33)]), OUTLINE)
	draw_colored_polygon(PackedVector2Array([Vector2(-11, -34), Vector2(0, -40.5), Vector2(11, -34)]), Color("a83a3a"))
	draw_line(Vector2(0, -34), Vector2(0, -22), WOOD, 1.0)
	draw_rect(Rect2(-2, -23, 4, 4), WOOD_DARK)


func _statue() -> void:
	_shadow(11, 4)
	draw_rect(Rect2(-9, -9, 18, 9), OUTLINE)
	draw_rect(Rect2(-8, -8, 16, 7), STONE_DARK)
	draw_rect(Rect2(-8, -8, 16, 2), STONE)
	draw_rect(Rect2(-6, -13, 12, 5), OUTLINE)
	draw_rect(Rect2(-5, -12, 10, 3), STONE)
	# A knight: body, helmet, sword.
	draw_rect(Rect2(-4, -28, 8, 15), OUTLINE)
	draw_rect(Rect2(-3, -27, 6, 13), Color("8c8a86"))
	draw_circle(Vector2(0, -31), 4.5, OUTLINE)
	draw_circle(Vector2(0, -31), 3.5, Color("a5a39d"))
	draw_rect(Rect2(-1, -33, 2, 3), Color("6e6a60"))
	draw_line(Vector2(6, -30), Vector2(6, -12), OUTLINE, 3.0)
	draw_line(Vector2(6, -30), Vector2(6, -12), Color("c4c0b2"), 1.0)


func _sign() -> void:
	_shadow(7, 2.5)
	draw_rect(Rect2(-2, -26, 4, 26), OUTLINE)
	draw_rect(Rect2(-1, -25, 2, 25), WOOD_DARK)
	draw_rect(Rect2(-12, -28, 24, 12), OUTLINE)
	draw_rect(Rect2(-11, -27, 22, 10), WOOD)
	draw_rect(Rect2(-11, -27, 22, 2), WOOD.lightened(0.2))
	for x: float in [-8.0, -3.0, 2.0]:
		draw_line(Vector2(x, -22), Vector2(x + 3, -22), WOOD_DARK, 1.0)
	draw_line(Vector2(-8, -19), Vector2(8, -19), WOOD_DARK, 1.0)


func _hay() -> void:
	_shadow(13, 4)
	var gold := Color("d9b04a")
	draw_colored_polygon(PackedVector2Array([Vector2(-12, 0), Vector2(-10, -9), Vector2(-3, -15), Vector2(5, -14), Vector2(11, -7), Vector2(13, 0)]), OUTLINE)
	draw_colored_polygon(PackedVector2Array([Vector2(-11, -1), Vector2(-9, -8), Vector2(-3, -14), Vector2(5, -13), Vector2(10, -7), Vector2(12, -1)]), gold)
	for i in 6:
		draw_line(Vector2(-9 + i * 4, -2), Vector2(-7 + i * 4, -10 - (i % 3) * 1.5), gold.darkened(0.25), 1.0)
	draw_line(Vector2(-11, -4), Vector2(12, -4), Color("8b5e3c"), 1.5)
