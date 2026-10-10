@tool
class_name SlimeVisual
extends ActorVisual
## Placeholder Slime: round translucent blob with a simple face (ENEMY_DESIGN.md §2).
## Origin is at the bottom of the blob.

@export var body_color := Color(0.42, 0.78, 0.45, 0.85):
	set(value):
		body_color = value
		queue_redraw()
@export var radius := 8.0:
	set(value):
		radius = value
		queue_redraw()


func _draw() -> void:
	fill_ellipse(Vector2.ZERO, Vector2(radius + 1.0, 3.0), SHADOW_COLOR)
	if selected:
		outline_ellipse(Vector2.ZERO, Vector2(radius + 3.0, 5.0), SELECTION_COLOR)
	var squash := 0.45 if downed else 0.8
	var center := Vector2(0.0, -radius * squash)
	var radii := Vector2(radius, radius * squash)
	fill_ellipse(center, radii + Vector2.ONE, OUTLINE_COLOR)
	fill_ellipse(center, radii, body_color)
	# Highlight.
	draw_circle(center + Vector2(-radius * 0.4, -radii.y * 0.45), 1.5, Color(1, 1, 1, 0.6))
	if downed or facing == Facing.Direction.UP:
		return
	var look := Facing.to_vector(facing) * 2.0
	draw_rect(Rect2(center + Vector2(-3.0 + look.x, -1.0), Vector2(2, 2)), OUTLINE_COLOR)
	draw_rect(Rect2(center + Vector2(1.0 + look.x, -1.0), Vector2(2, 2)), OUTLINE_COLOR)
