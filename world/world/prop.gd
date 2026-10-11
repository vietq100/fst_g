@tool
class_name WorldProp
extends StaticBody2D
## Region decoration that blocks movement (navigation obstacle): trees (Dark Forest, Town edges),
## boulders (Goblin Cave), broken columns (Ancient Ruins). Origin at the base.

enum Kind { TREE, ROCK, COLUMN }

const OUTLINE := Color("10140f")

@export var kind: Kind = Kind.TREE:
	set(value):
		kind = value
		queue_redraw()
@export var size := 1.0:
	set(value):
		size = value
		queue_redraw()
@export var tint := Color("23452b"):
	set(value):
		tint = value
		queue_redraw()


func _init() -> void:
	add_to_group(&"navigation_obstacles")
	collision_layer = 1
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 7.0
	shape.shape = circle
	shape.position = Vector2(0, -2)
	add_child(shape)


func _draw() -> void:
	draw_ellipse(Vector2.ZERO, 10.0 * size, 4.0 * size, Color(0, 0, 0, 0.3))
	match kind:
		Kind.TREE:
			draw_rect(Rect2(Vector2(-3, -12) * size, Vector2(6, 12) * size).grow(1.0), OUTLINE)
			draw_rect(Rect2(Vector2(-3, -12) * size, Vector2(6, 12) * size), Color("3b2e22"))
			var layers := [[Vector2(0, -22), 13.0], [Vector2(-6, -30), 9.0], [Vector2(6, -29), 9.0], [Vector2(0, -36), 8.0]]
			for layer in layers:
				draw_circle(layer[0] * size, (layer[1] + 1.0) * size, OUTLINE)
			for i in layers.size():
				draw_circle(layers[i][0] * size, layers[i][1] * size, tint.lightened(0.06 * i))
		Kind.ROCK:
			var points := PackedVector2Array([Vector2(-12, 0), Vector2(-10, -9), Vector2(-3, -15), Vector2(7, -13), Vector2(12, -5), Vector2(10, 1)])
			for i in points.size():
				points[i] *= size
			draw_colored_polygon(IsoBuildingVisual._grow(points, 1.0), OUTLINE)
			draw_colored_polygon(points, tint)
			draw_line(Vector2(-3, -15) * size, Vector2(0, -4) * size, tint.darkened(0.3), 1.0)
		Kind.COLUMN:
			var height := 34.0 * size
			draw_rect(Rect2(Vector2(-8, -6), Vector2(16, 6)).grow(1.0), OUTLINE)
			draw_rect(Rect2(Vector2(-8, -6), Vector2(16, 6)), tint.darkened(0.2))
			draw_rect(Rect2(Vector2(-5, -height), Vector2(10, height - 6)).grow(1.0), OUTLINE)
			draw_rect(Rect2(Vector2(-5, -height), Vector2(10, height - 6)), tint)
			# Broken top.
			draw_colored_polygon(PackedVector2Array([Vector2(-5, -height), Vector2(5, -height), Vector2(2, -height - 6), Vector2(-3, -height - 3)]), tint.lightened(0.1))
