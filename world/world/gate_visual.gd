class_name GateVisual
extends Node2D
## Bridge over the water between two regions (WORLD_DESIGN.md, D55): the deck is drawn by the
## ground; this adds the railings, posts and lanterns along the corridor's two long edges
## (following the tile grid), reaching one tile onto both banks. Origin = corridor centre.
## No collision: the corridor must stay walkable.

const WOOD := Color("8a6a44")
const WOOD_DARK := Color("5a4430")
const OUTLINE := Color("16161c")
const FLAME := Color("ffb347")
const FLAME_CORE := Color("fff2a8")
const POST_SPACING := 16.0
## How far (tiles) the rails reach onto each bank.
const REACH := 1.0

## Lantern flames flicker at this rate.
const FLICKER_FPS := 8.0

## Rail segments [start, end] relative to the origin.
var _rails: Array[PackedVector2Array] = []

var _flicker_time := 0.0
var _flicker := 0


func setup(gate: WorldService.Gate) -> void:
	position = gate.center
	_rails.clear()
	var rect := gate.tiles
	if gate.axis.x != 0:
		for y: float in [float(rect.position.y), float(rect.end.y)]:
			_rails.append(PackedVector2Array([
				WorldService.tile_to_world(Vector2(rect.position.x - REACH, y)) - position,
				WorldService.tile_to_world(Vector2(rect.end.x + REACH, y)) - position,
			]))
	else:
		for x: float in [float(rect.position.x), float(rect.end.x)]:
			_rails.append(PackedVector2Array([
				WorldService.tile_to_world(Vector2(x, rect.position.y - REACH)) - position,
				WorldService.tile_to_world(Vector2(x, rect.end.y + REACH)) - position,
			]))
	queue_redraw()


func _process(delta: float) -> void:
	_flicker_time += delta
	if _flicker_time >= 1.0 / FLICKER_FPS:
		_flicker_time -= 1.0 / FLICKER_FPS
		_flicker += 1
		queue_redraw()


func _draw() -> void:
	for rail in _rails:
		var a := rail[0]
		var b := rail[1]
		# Rail: outline, wood, highlight.
		draw_line(a + Vector2(0, -10), b + Vector2(0, -10), OUTLINE, 4.0)
		draw_line(a + Vector2(0, -10), b + Vector2(0, -10), WOOD, 2.0)
		draw_line(a + Vector2(0, -11), b + Vector2(0, -11), WOOD.lightened(0.2), 1.0)
		var posts := maxi(int(a.distance_to(b) / POST_SPACING), 1)
		for i in posts + 1:
			var at := a.lerp(b, float(i) / posts)
			draw_line(at, at + Vector2(0, -12), OUTLINE, 4.0)
			draw_line(at, at + Vector2(0, -12), WOOD_DARK, 2.0)
			draw_line(at + Vector2(-1, -12), at + Vector2(-1, -1), WOOD, 1.0)
		# Lantern posts at both ends.
		for end: Vector2 in [a, b]:
			var lantern := end + Vector2(0, -16)
			var wobble := float(posmod(_flicker + int(end.x), 3)) - 1.0
			draw_line(end, lantern, OUTLINE, 3.0)
			draw_line(end, lantern, WOOD_DARK, 1.0)
			draw_circle(lantern + Vector2(0, -2), 6.0 + wobble, Color(FLAME, 0.22 + wobble * 0.04))
			draw_rect(Rect2(lantern + Vector2(-2.5, -5), Vector2(5, 6)), OUTLINE)
			draw_rect(Rect2(lantern + Vector2(-1.5, -4), Vector2(3, 4)), FLAME)
			draw_rect(Rect2(lantern + Vector2(-0.5 + wobble * 0.5, -3), Vector2(1, 2)), FLAME_CORE)
