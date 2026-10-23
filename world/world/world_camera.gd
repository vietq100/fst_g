class_name WorldCamera
extends Camera2D
## The screen as a window onto the world (D28): drag to pan, pinch / wheel to zoom, follow an
## actor until the player drags. Clamped to the world bounds.

const MIN_ZOOM := 0.14
const MAX_ZOOM := 2.0
const WHEEL_STEP := 1.12

var bounds := Rect2(-1300, -100, 2600, 1400)
## Zoom-out limit; the world sets it from the Town's size (the whole Town and a little more).
var min_zoom := MIN_ZOOM
## Screen pixels covered by the HUD at the top and the navigation bar at the bottom: the map may
## scroll until its edges sit just clear of them, so every part of it can be reached.
var inset_top := 0.0
var inset_bottom := 0.0
## Screen pixels an open sheet covers at the bottom: a followed actor is kept in the free band above
## it (not part of the zoom-out limit, which only the fixed HUD sets).
var cover_bottom := 0.0
var follow_target: Node2D
## Follows the centre of these actors' standing members (a dungeon party).
var follow_group: Array[Actor] = []
## Rate of the follow easing (per second); higher is tighter.
const FOLLOW_SMOOTHING := 7.0
## The followed actor sits a little below the screen centre (its sprite rises from the feet).
const FOLLOW_OFFSET := Vector2(0, -20)
var _snap := false


func _ready() -> void:
	position_smoothing_enabled = false
	clamp_to_bounds()


func _process(delta: float) -> void:
	if not follow_group.is_empty():
		var sum := Vector2.ZERO
		var count := 0
		for actor in follow_group:
			if is_instance_valid(actor) and actor.is_targetable():
				sum += actor.global_position
				count += 1
		if count > 0:
			_glide_to(sum / count + FOLLOW_OFFSET, delta)
		return
	if follow_target != null:
		if not is_instance_valid(follow_target) or not follow_target.is_inside_tree():
			follow_target = null
		else:
			_glide_to(follow_target.global_position + FOLLOW_OFFSET, delta)


## Eases towards `goal` (frame-rate independent) so a followed walker does not jerk the screen
## with every step; snaps when `_snap` is set (a fresh follow starting far away).
func _glide_to(goal: Vector2, delta: float) -> void:
	# Centre the target in the part of the screen the HUD and an open sheet leave free.
	goal.y += (inset_bottom + cover_bottom - inset_top) * 0.5 / zoom.y
	if _snap:
		global_position = goal
		_snap = false
	else:
		global_position = global_position.lerp(goal, 1.0 - exp(-delta * FOLLOW_SMOOTHING))
	clamp_to_bounds()


## `snap` jumps to the target at once instead of gliding there.
func follow(target: Node2D, snap: bool = false) -> void:
	follow_group.clear()
	follow_target = target
	_snap = snap


func follow_party(actors: Array[Actor], snap: bool = false) -> void:
	follow_target = null
	follow_group = actors.duplicate()
	_snap = snap


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
	var value := clampf(zoom.x * factor, min_zoom, MAX_ZOOM)
	zoom = Vector2(value, value)
	if follow_target == null:
		global_position += before - _screen_to_world(screen_point)
	clamp_to_bounds()


## Sets the zoom-out limit so `area` (world px) plus `margin` (1.2 = a fifth more) just fits the screen
## between the HUD insets, and pulls the current zoom inside it.
func limit_zoom_out_to(area: Rect2, margin: float) -> void:
	var view := get_viewport_rect().size - Vector2(0.0, inset_top + inset_bottom)
	if view.x <= 0.0 or view.y <= 0.0 or area.size.x <= 0.0 or area.size.y <= 0.0:
		return
	min_zoom = clampf(minf(view.x / (area.size.x * margin), view.y / (area.size.y * margin)), MIN_ZOOM, MAX_ZOOM)
	if zoom.x < min_zoom:
		zoom = Vector2(min_zoom, min_zoom)
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
	# Vertically the map may slide under the HUD's insets by their size (in world px).
	var lo_y := bounds.position.y + half.y - inset_top / zoom.y
	var hi_y := bounds.end.y - half.y + (inset_bottom + cover_bottom) / zoom.y
	global_position.y = clampf(global_position.y, minf(lo_y, bounds.get_center().y), maxf(hi_y, bounds.get_center().y))


func _screen_to_world(screen_point: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * screen_point
