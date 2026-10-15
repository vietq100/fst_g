class_name WorldDecor
extends Node2D
## Small Town decoration (D57): lamp post, bench or flower planter. No collision (Hunters walk
## past), y-sorted with the actors. WorldMap hides it while a building covers its `tile`.
## Origin at the base.

enum Kind { LAMP, BENCH, PLANTER }

const IRON := Color("2a2a30")
const IRON_LIGHT := Color("4a4a54")
const LIGHT := Color("ffcf6b")
const LIGHT_CORE := Color("fff2c4")
const WOOD := Color("5a4430")
const WOOD_LIGHT := Color("8a6a44")
const WOOD_DARK := Color("3a2a1a")
const SHADOW := Color(0, 0, 0, 0.28)
const PLANTER_FLOWERS: Array[Color] = [Color("e8789a"), Color("f2c94c"), Color("f4f1ea")]

var kind := Kind.LAMP:
	set(value):
		kind = value
		queue_redraw()
## Tile the decoration stands on.
var tile := Vector2i.ZERO


func _draw() -> void:
	match kind:
		Kind.LAMP:
			_draw_lamp()
		Kind.BENCH:
			_draw_bench()
		Kind.PLANTER:
			_draw_planter()


## Iron lamp post with a lit lantern and a soft halo.
func _draw_lamp() -> void:
	draw_ellipse(Vector2(1, 0), 4.0, 1.5, SHADOW)
	draw_rect(Rect2(Vector2(-1.5, -22), Vector2(3, 22)), IRON)
	draw_rect(Rect2(Vector2(-0.5, -22), Vector2(1, 22)), IRON_LIGHT)
	draw_rect(Rect2(Vector2(-3, -2), Vector2(6, 2)), IRON)
	draw_circle(Vector2(0, -25), 8.0, Color(LIGHT, 0.16))
	draw_rect(Rect2(Vector2(-3.5, -29), Vector2(7, 7)), IRON)
	draw_rect(Rect2(Vector2(-2.5, -28), Vector2(5, 5)), LIGHT)
	draw_rect(Rect2(Vector2(-1, -27), Vector2(2, 2)), LIGHT_CORE)
	draw_colored_polygon(PackedVector2Array([Vector2(-4.5, -29), Vector2(4.5, -29), Vector2(0, -33)]), IRON)


## Wooden bench: seat, back rest, legs.
func _draw_bench() -> void:
	draw_ellipse(Vector2(0, 1), 9.0, 2.0, SHADOW)
	draw_rect(Rect2(Vector2(-8, -11), Vector2(16, 3)), WOOD.lightened(0.1))
	draw_rect(Rect2(Vector2(-8, -6), Vector2(16, 3)), WOOD)
	draw_rect(Rect2(Vector2(-8, -6), Vector2(16, 1)), WOOD_LIGHT)
	draw_rect(Rect2(Vector2(-7, -3), Vector2(2, 3)), WOOD_DARK)
	draw_rect(Rect2(Vector2(5, -3), Vector2(2, 3)), WOOD_DARK)
	draw_rect(Rect2(Vector2(-8, -11), Vector2(16, 8)), WOOD_DARK, false, 1.0)


## Wooden flower box with three blooms.
func _draw_planter() -> void:
	draw_ellipse(Vector2(0, 1), 9.0, 2.0, SHADOW)
	draw_rect(Rect2(Vector2(-8, -5), Vector2(16, 5)), WOOD.lightened(0.1))
	draw_rect(Rect2(Vector2(-8, -5), Vector2(16, 1)), WOOD_LIGHT.lightened(0.15))
	draw_rect(Rect2(Vector2(-8, -5), Vector2(16, 5)), WOOD_DARK, false, 1.0)
	for i in PLANTER_FLOWERS.size():
		var at := Vector2(-5 + i * 5, -7)
		draw_circle(at, 2.5, Color("3f6a36"))
		draw_circle(at + Vector2(0, -1), 1.4, PLANTER_FLOWERS[i])
