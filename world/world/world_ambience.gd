class_name WorldAmbience
extends Node2D
## Moving life over the map (D75, from the D61 ambience), one small node per piece: soft cloud shadows
## drifting across everything, gulls circling over the water, a rowing boat rocking by an islet, the
## lighthouse lamp pulsing with a slow sweeping beam. Clouds and gulls move by node position (no redraw);
## flapping, rocking and the beam redraw at FPS and only on screen. Presentation only.

enum Kind { CLOUD, GULL, BOAT, BEACON }

const FPS := 10.0
const CLOUD_SPEED := Vector2(9, 3)
const CLOUD_SHADOW := Color(0.02, 0.05, 0.1, 0.07)
const GULL := Color("f4f1ea")
const GULL_EDGE := Color("3a3f48")
const BEAM := Color(1.0, 0.92, 0.6, 0.12)
const OUTLINE := Color("10140f")
## Margin around the viewport inside which a piece counts as on screen (world px).
const SCREEN_MARGIN := 240.0
## Seconds between the on-screen checks of a cloud.
const CLOUD_CHECK := 0.4

var kind := Kind.CLOUD
## Clouds: the area they wrap around in. Gulls: circle centre, radius, angular speed (rad/s), phase.
var area := Rect2()
var centre := Vector2.ZERO
var radius := 60.0
var speed := 0.5
var phase := 0.0
## Cloud size (world px).
var size := 120.0
var _time := 0.0
var _frame_time := 0.0


func _process(delta: float) -> void:
	_time += delta
	match kind:
		Kind.CLOUD:
			var moved := position + CLOUD_SPEED * speed * delta
			position = area.position + Vector2(fposmod(moved.x - area.position.x, area.size.x), fposmod(moved.y - area.position.y, area.size.y))
			# Clouds off screen are hidden (a few checks a second): no blended ellipses to draw or cull.
			_frame_time += delta
			if _frame_time >= CLOUD_CHECK:
				_frame_time = 0.0
				visible = get_viewport_rect().grow(size * 1.2 + SCREEN_MARGIN).has_point(get_global_transform_with_canvas().origin)
			return
		Kind.GULL:
			var angle := phase + _time * speed
			position = centre + Vector2(cos(angle) * radius, sin(angle) * radius * 0.5)
	_frame_time += delta
	if _frame_time >= 1.0 / FPS:
		_frame_time = fmod(_frame_time, 1.0 / FPS)
		if is_visible_in_tree() and get_viewport_rect().grow(SCREEN_MARGIN).has_point(get_global_transform_with_canvas().origin):
			queue_redraw()


func _draw() -> void:
	match kind:
		Kind.CLOUD:
			_draw_cloud()
		Kind.GULL:
			_draw_gull()
		Kind.BOAT:
			_draw_boat()
		Kind.BEACON:
			_draw_beacon()


## A big soft cloud shadow of four puffs.
func _draw_cloud() -> void:
	for puff: Vector3 in [Vector3(0, 0, 1.0), Vector3(0.6, -0.15, 0.7), Vector3(-0.55, 0.1, 0.65), Vector3(0.2, 0.25, 0.6)]:
		draw_ellipse(Vector2(puff.x, puff.y) * size, size * 0.6 * puff.z, size * 0.32 * puff.z, CLOUD_SHADOW)


## A gull: two wing strokes flapping, facing its direction of travel, its shadow on the water below.
func _draw_gull() -> void:
	var heading := signf(speed)
	var lift := sin(_time * 6.0 + phase) * 2.5
	var left := PackedVector2Array([Vector2(-7, -1 - lift), Vector2(-3, -3 - lift * 0.5), Vector2.ZERO])
	var right := PackedVector2Array([Vector2.ZERO, Vector2(3, -3 - lift * 0.5), Vector2(7, -1 - lift)])
	draw_ellipse(Vector2(0, 26), 4.0, 1.2, Color(0, 0, 0, 0.12))
	for wing in [left, right]:
		draw_polyline(wing, GULL_EDGE, 2.5)
		draw_polyline(wing, GULL, 1.5)
	draw_circle(Vector2(heading, 0), 1.0, GULL)


## Rowing boat rocking gently.
func _draw_boat() -> void:
	var bob := sin(_time * 1.6 + phase) * 1.5
	var tilt := sin(_time * 1.6 + phase + 0.8) * 1.0
	var base := Vector2(0, bob)
	draw_ellipse(base + Vector2(0, 6), 22.0, 6.0, Color(0.91, 0.96, 1.0, 0.3 + 0.1 * sin(_time * 1.6)))
	var hull := PackedVector2Array([base + Vector2(-20, -2 - tilt), base + Vector2(20, -2 + tilt), base + Vector2(14, 7), base + Vector2(-14, 7)])
	var outline := PackedVector2Array()
	for point in hull:
		outline.append(point + Vector2(signf(point.x - base.x), 1))
	draw_colored_polygon(outline, OUTLINE)
	draw_colored_polygon(hull, Color("8a5a30"))
	draw_colored_polygon(PackedVector2Array([base + Vector2(-17, -1 - tilt), base + Vector2(17, -1 + tilt), base + Vector2(13, 3),
		base + Vector2(-13, 3)]), Color("5a3a22"))
	draw_line(hull[0], hull[1], Color("c9a26a"), 1.5)
	for i in range(-1, 2):
		draw_line(base + Vector2(i * 7.0, -1), base + Vector2(i * 7.0, 3), Color("8a5a30"), 1.5)
	# Oars resting across the gunwales.
	draw_line(base + Vector2(-6, -2), base + Vector2(-16, -9), Color("c9a26a"), 1.5)
	draw_line(base + Vector2(6, -2), base + Vector2(16, -9), Color("c9a26a"), 1.5)


## Pulsing lamp halo and a slow beam sweeping across the sea (origin = the lamp).
func _draw_beacon() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 2.0)
	draw_circle(Vector2.ZERO, 12.0 + pulse * 4.0, Color(1.0, 0.88, 0.54, 0.16 + 0.1 * pulse))
	var direction := Vector2.RIGHT.rotated(_time * 0.6)
	var side := direction.orthogonal() * 18.0
	var far := direction * 220.0
	draw_colored_polygon(PackedVector2Array([direction.orthogonal() * 2.0, far + side, far - side,
		-direction.orthogonal() * 2.0]), BEAM)
