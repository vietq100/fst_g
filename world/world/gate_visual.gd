class_name GateVisual
extends Node2D
## Bridge over the water between two regions (WORLD_DESIGN.md, D52): the deck is drawn by the
## ground; this adds the railings, posts and lanterns at both ends. Origin = corridor centre.
## No collision: the corridor must stay walkable.

const WOOD := Color("8a6a44")
const WOOD_DARK := Color("5a4430")
const OUTLINE := Color("16161c")
const FLAME := Color("ffb347")
const FLAME_CORE := Color("fff2a8")
## Half the corridor length along its axis (the gap plus the overlap onto both banks).
const HALF_LENGTH := 44.0
## Railings sit this far from the corridor centre line.
const HALF_WIDTH := 29.0
const POST_SPACING := 16.0

## Lantern flames flicker at this rate.
const FLICKER_FPS := 8.0

## Direction along the corridor in world space (from one region to the other).
var axis := Vector2(1, 0)

var _flicker_time := 0.0
var _flicker := 0


func _process(delta: float) -> void:
	_flicker_time += delta
	if _flicker_time >= 1.0 / FLICKER_FPS:
		_flicker_time -= 1.0 / FLICKER_FPS
		_flicker += 1
		queue_redraw()


func _draw() -> void:
	var along := axis.normalized()
	var across := Vector2(-along.y, along.x)
	for side: float in [-1.0, 1.0]:
		var offset := across * HALF_WIDTH * side
		var a := offset - along * HALF_LENGTH
		var b := offset + along * HALF_LENGTH
		# Rail: outline, wood, highlight.
		draw_line(a + Vector2(0, -10), b + Vector2(0, -10), OUTLINE, 4.0)
		draw_line(a + Vector2(0, -10), b + Vector2(0, -10), WOOD, 2.0)
		draw_line(a + Vector2(0, -11), b + Vector2(0, -11), WOOD.lightened(0.2), 1.0)
		var posts := int(HALF_LENGTH * 2.0 / POST_SPACING)
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
