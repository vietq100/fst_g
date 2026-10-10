@tool
class_name WolfVisual
extends ActorVisual
## Placeholder Wolf: four-legged, long low silhouette, aggressive stance (ENEMY_DESIGN.md §4).
## Drawn side-on; up/down movement keeps the last horizontal direction.

@export var body_color := Color("6f7782"):
	set(value):
		body_color = value
		queue_redraw()
@export var belly_color := Color("aab1ba"):
	set(value):
		belly_color = value
		queue_redraw()

var _side := 1.0


func _draw() -> void:
	if facing == Facing.Direction.LEFT:
		_side = -1.0
	elif facing == Facing.Direction.RIGHT:
		_side = 1.0
	fill_ellipse(Vector2.ZERO, Vector2(11.0, 3.0), SHADOW_COLOR)
	if selected:
		outline_ellipse(Vector2.ZERO, Vector2(13.0, 5.0), SELECTION_COLOR)
	if downed:
		fill_ellipse(Vector2(0, -3), Vector2(10.0, 3.5), OUTLINE_COLOR)
		fill_ellipse(Vector2(0, -3), Vector2(9.0, 2.5), body_color.darkened(0.3))
		return
	var s := _side
	# Legs.
	for x in [-6.0, -3.0, 4.0, 7.0]:
		draw_rect(Rect2(Vector2(x * s - 1.0, -6.0), Vector2(2, 6)), OUTLINE_COLOR)
	# Tail.
	draw_line(Vector2(-9.0 * s, -9.0), Vector2(-14.0 * s, -13.0), OUTLINE_COLOR, 3.0)
	draw_line(Vector2(-9.0 * s, -9.0), Vector2(-13.5 * s, -12.5), body_color, 1.0)
	# Body.
	fill_ellipse(Vector2(0, -9), Vector2(10.0, 5.0), OUTLINE_COLOR)
	fill_ellipse(Vector2(0, -9), Vector2(9.0, 4.0), body_color)
	fill_ellipse(Vector2(1.0 * s, -7), Vector2(6.0, 1.5), belly_color)
	# Head, snout, ear, eye.
	var head := Vector2(10.0 * s, -12.0)
	draw_circle(head, 4.5, OUTLINE_COLOR)
	draw_circle(head, 3.5, body_color)
	draw_rect(Rect2(head + Vector2(2.0 * s if s > 0 else -6.0, 0.0), Vector2(4, 3)), OUTLINE_COLOR)
	draw_colored_polygon(PackedVector2Array([head + Vector2(-2.0 * s, -3), head + Vector2(-1.0 * s, -8), head + Vector2(1.0 * s, -3)]), OUTLINE_COLOR)
	draw_rect(Rect2(head + Vector2(1.0 * s - 0.5, -1.5), Vector2(1, 1)), Color("ffd23f"))
