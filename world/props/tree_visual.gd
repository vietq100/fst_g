@tool
extends Node2D
## Placeholder forest tree: trunk + layered canopy. Origin at the trunk base.

const OUTLINE := Color("10140f")
const TRUNK := Color("3b2e22")

@export var canopy_color := Color("23452b"):
	set(value):
		canopy_color = value
		queue_redraw()
@export var size := 1.0:
	set(value):
		size = value
		queue_redraw()


func _draw() -> void:
	draw_ellipse(Vector2.ZERO, 9.0 * size, 3.0 * size, Color(0, 0, 0, 0.35))
	draw_rect(Rect2(Vector2(-3, -12) * size, Vector2(6, 12) * size).grow(1.0), OUTLINE)
	draw_rect(Rect2(Vector2(-3, -12) * size, Vector2(6, 12) * size), TRUNK)
	var layers := [[Vector2(0, -22), 13.0], [Vector2(-6, -30), 9.0], [Vector2(6, -29), 9.0], [Vector2(0, -36), 8.0]]
	for layer in layers:
		draw_circle(layer[0] * size, (layer[1] + 1.0) * size, OUTLINE)
	for i in layers.size():
		var shade := canopy_color.lightened(0.06 * i)
		draw_circle(layers[i][0] * size, layers[i][1] * size, shade)
