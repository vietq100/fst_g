class_name WorldAmbience
extends Node2D
## Moving scenery over the map (D61), redrawn at a low rate: the boat moored at the dock bobbing,
## the lighthouse lamp pulsing with a slow sweeping beam, gulls circling over the water and soft
## cloud shadows drifting across everything. Drawn above the y-sorted entities (z_index) but very
## faint where it crosses them. Presentation only.

const FPS := 10.0
const CLOUD_COUNT := 5
const CLOUD_SPEED := Vector2(9, 3)
const CLOUD_SHADOW := Color(0.02, 0.05, 0.1, 0.07)
const GULL := Color("f4f1ea")
const GULL_EDGE := Color("3a3f48")
const BEAM := Color(1.0, 0.92, 0.6, 0.12)
## [centre (tile), radius px, angular speed rad/s, phase].
const GULLS := [
	[Vector2(-6, 26), 60.0, 0.5, 0.0], [Vector2(40, -6), 80.0, -0.4, 1.7], [Vector2(84, 52), 70.0, 0.45, 3.1],
	[Vector2(30, 82), 90.0, -0.35, 4.4], [Vector2(-8, 70), 50.0, 0.6, 2.2],
]

var _time := 0.0
var _frame_time := 0.0
var _area := Rect2()


func _ready() -> void:
	z_index = 20
	var world: WorldService = GameManager.world
	_area = world.get_bounds(WorldScenery.MARGIN + 200.0) if world != null else Rect2(-600, -600, 3600, 3600)


func _process(delta: float) -> void:
	_time += delta
	_frame_time += delta
	if _frame_time >= 1.0 / FPS:
		_frame_time -= 1.0 / FPS
		queue_redraw()


func _draw() -> void:
	_draw_boat(WorldScenery.boat_mooring())
	_draw_lighthouse_light(WorldScenery.lighthouse_lamp())
	for gull: Array in GULLS:
		var centre := WorldScenery.tile_point(gull[0])
		var radius: float = gull[1]
		var speed: float = gull[2]
		var phase: float = gull[3]
		var angle := phase + _time * speed
		_draw_gull(centre + Vector2(cos(angle) * radius, sin(angle) * radius * 0.5), signf(speed), _time * 6.0 + phase)
	_draw_clouds()


## Rowing boat rocking gently on its mooring line.
func _draw_boat(at: Vector2) -> void:
	var bob := sin(_time * 1.6) * 1.5
	var tilt := sin(_time * 1.6 + 0.8) * 1.0
	var base := at + Vector2(0, bob)
	draw_ellipse(base + Vector2(0, 6), 22.0, 6.0, Color(0.91, 0.96, 1.0, 0.3 + 0.1 * sin(_time * 1.6)))
	var hull := PackedVector2Array([base + Vector2(-20, -2 - tilt), base + Vector2(20, -2 + tilt), base + Vector2(14, 7), base + Vector2(-14, 7)])
	var outline := PackedVector2Array()
	for point in hull:
		outline.append(point + Vector2(signf(point.x - base.x), 1))
	draw_colored_polygon(outline, WorldScenery.OUTLINE)
	draw_colored_polygon(hull, Color("8a5a30"))
	draw_colored_polygon(PackedVector2Array([base + Vector2(-17, -1 - tilt), base + Vector2(17, -1 + tilt), base + Vector2(13, 3),
		base + Vector2(-13, 3)]), Color("5a3a22"))
	draw_line(hull[0], hull[1], Color("c9a26a"), 1.5)
	for i in range(-1, 2):
		draw_line(base + Vector2(i * 7.0, -1), base + Vector2(i * 7.0, 3), Color("8a5a30"), 1.5)
	# Mooring line to the dock post.
	draw_line(base + Vector2(20, -2 + tilt), WorldScenery.DOCK * WorldScenery.TILE + Vector2(3, 32), Color(0.91, 0.89, 0.82, 0.6), 1.0)


## Pulsing lamp halo and a slow beam sweeping across the sea.
func _draw_lighthouse_light(lamp: Vector2) -> void:
	if lamp == Vector2.ZERO:
		return
	var pulse := 0.5 + 0.5 * sin(_time * 2.0)
	draw_circle(lamp, 12.0 + pulse * 4.0, Color(1.0, 0.88, 0.54, 0.16 + 0.1 * pulse))
	var angle := _time * 0.6
	var direction := Vector2.RIGHT.rotated(angle)
	var side := direction.orthogonal() * 18.0
	var far := lamp + direction * 220.0
	draw_colored_polygon(PackedVector2Array([lamp + direction.orthogonal() * 2.0, far + side, far - side,
		lamp - direction.orthogonal() * 2.0]), BEAM)


## A gull: two wing strokes flapping, facing its direction of travel.
func _draw_gull(at: Vector2, heading: float, flap: float) -> void:
	var lift := sin(flap) * 2.5
	var left := PackedVector2Array([at + Vector2(-7, -1 - lift), at + Vector2(-3, -3 - lift * 0.5), at])
	var right := PackedVector2Array([at, at + Vector2(3, -3 - lift * 0.5), at + Vector2(7, -1 - lift)])
	draw_ellipse(at + Vector2(0, 26), 4.0, 1.2, Color(0, 0, 0, 0.12))
	for wing in [left, right]:
		draw_polyline(wing, GULL_EDGE, 2.5)
		draw_polyline(wing, GULL, 1.5)
	draw_circle(at + Vector2(heading * 1.0, 0), 1.0, GULL)


## Big soft cloud shadows drifting diagonally, wrapping around the map.
func _draw_clouds() -> void:
	for i in CLOUD_COUNT:
		var start := Vector2(_unit(i, 1) * _area.size.x, _unit(i, 2) * _area.size.y)
		var travel := start + CLOUD_SPEED * _time * (0.7 + _unit(i, 3) * 0.6)
		var at := _area.position + Vector2(fposmod(travel.x, _area.size.x), fposmod(travel.y, _area.size.y))
		var size := 90.0 + _unit(i, 4) * 80.0
		for puff: Vector3 in [Vector3(0, 0, 1.0), Vector3(0.6, -0.15, 0.7), Vector3(-0.55, 0.1, 0.65), Vector3(0.2, 0.25, 0.6)]:
			draw_ellipse(at + Vector2(puff.x, puff.y) * size, size * 0.6 * puff.z, size * 0.32 * puff.z, CLOUD_SHADOW)


static func _unit(index: int, salt: int) -> float:
	return float(WorldGround._hash(index, salt, 97) % 1000) / 1000.0
