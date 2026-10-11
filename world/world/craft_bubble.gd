class_name CraftBubble
extends Node2D
## Bubble above a Hunter crafting in the field (D46): a pot (cooking) or a green cross (brewing)
## with a progress ring. Presentation only.

const OUTLINE := Color("16161c")

var brewing := false
var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()


func _ready() -> void:
	position = Vector2(0, -40)
	z_index = 50


func _draw() -> void:
	draw_circle(Vector2.ZERO, 9.0, OUTLINE)
	draw_circle(Vector2.ZERO, 8.0, Color("f4f1ea"))
	draw_arc(Vector2.ZERO, 10.5, -PI / 2.0, -PI / 2.0 + TAU * progress, 24, Color("f2d16b"), 2.0)
	if brewing:
		draw_rect(Rect2(-4.5, -1.5, 9, 3), Color("3f9a52"))
		draw_rect(Rect2(-1.5, -4.5, 3, 9), Color("3f9a52"))
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(-5, -1), Vector2(5, -1), Vector2(4, 4), Vector2(-4, 4)]), Color("5a4636"))
		draw_line(Vector2(-2, -3), Vector2(-1, -6), Color("b8b8b8"), 1.0)
		draw_line(Vector2(2, -3), Vector2(3, -6), Color("b8b8b8"), 1.0)
