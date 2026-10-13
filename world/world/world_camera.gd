class_name WorldCamera
extends Camera2D
## The screen as a window onto the world (D28): drag to pan, pinch / wheel to zoom, follow an
## actor until the player drags. Clamped to the world bounds.

const MIN_ZOOM := 0.22
const MAX_ZOOM := 2.0
const WHEEL_STEP := 1.12

var bounds := Rect2(-1300, -100, 2600, 1400)
var follow_target: Node2D
## Follows the centre of these actors' standing members (a dungeon party).
var follow_group: Array[Actor] = []


func _ready() -> void:
	position_smoothing_enabled = false
	clamp_to_bounds()


func _process(_delta: float) -> void:
	if not follow_group.is_empty():
		var sum := Vector2.ZERO
		var count := 0
		for actor in follow_group:
			if is_instance_valid(actor) and actor.is_targetable():
				sum += actor.global_position
				count += 1
		if count > 0:
			global_position = sum / count + Vector2(0, -20)
			clamp_to_bounds()
		return
	if follow_target != null:
		if not is_instance_valid(follow_target) or not follow_target.is_inside_tree():
			follow_target = null
		else:
			global_position = follow_target.global_position + Vector2(0, -20)
			clamp_to_bounds()


func follow(target: Node2D) -> void:
	follow_group.clear()
	follow_target = target


func follow_party(actors: Array[Actor]) -> void:
	follow_target = null
	follow_group = actors.duplicate()


func stop_following() -> void:
	follow_target = null
	follow_group.clear()


## `relative` is a drag in screen pixels; the world follows the finger.
func pan(relative: Vector2) -> void:
	stop_following()
	global_position -= relative / zoom
	clamp_to_bounds()


## Zooms by `factor` keeping the world point under `screen_point` in place.
func zoom_at(factor: float, screen_point: Vector2) -> void:
	var before := _screen_to_world(screen_point)
	var value := clampf(zoom.x * factor, MIN_ZOOM, MAX_ZOOM)
	zoom = Vector2(value, value)
	if follow_target == null:
		global_position += before - _screen_to_world(screen_point)
	clamp_to_bounds()


func center_on(point: Vector2) -> void:
	stop_following()
	global_position = point
	clamp_to_bounds()


func clamp_to_bounds() -> void:
	var half := get_viewport_rect().size * 0.5 / zoom
	var lo := bounds.position + half
	var hi := bounds.end - half
	global_position.x = clampf(global_position.x, minf(lo.x, bounds.get_center().x), maxf(hi.x, bounds.get_center().x))
	global_position.y = clampf(global_position.y, minf(lo.y, bounds.get_center().y), maxf(hi.y, bounds.get_center().y))


func _screen_to_world(screen_point: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * screen_point
