extends Camera2D
## Drag-to-pan within the town bounds (MAP_DESIGN.md §7, DECISIONS.md D23).

@export var map_size := Vector2(360, 800)


func _ready() -> void:
	limit_left = 0
	limit_top = 0
	limit_right = int(map_size.x)
	limit_bottom = int(map_size.y)
	clamp_to_limits()


## `relative` is the drag movement in screen pixels; the view follows the finger.
func pan(relative: Vector2) -> void:
	global_position -= relative / zoom
	clamp_to_limits()


func clamp_to_limits() -> void:
	var half := get_viewport_rect().size * 0.5 / zoom
	global_position.x = clampf(global_position.x, half.x, maxf(map_size.x - half.x, half.x))
	global_position.y = clampf(global_position.y, half.y, maxf(map_size.y - half.y, half.y))
