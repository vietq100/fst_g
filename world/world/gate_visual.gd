class_name GateVisual
extends Node2D
## Stone arch over a gate corridor between two regions (WORLD_DESIGN.md). Origin = corridor centre.
## No collision: the corridor must stay walkable.

const STONE := Color("8a8a84")
const OUTLINE := Color("16161c")

## Direction along the corridor in world space (from one region to the other).
var axis := Vector2(1, 0.5)


func _draw() -> void:
	var across := Vector2(-axis.y, axis.x).normalized() * 34.0
	for side: float in [-1.0, 1.0]:
		var base := across * side
		draw_rect(Rect2(base + Vector2(-5, -30), Vector2(10, 30)).grow(1.0), OUTLINE)
		draw_rect(Rect2(base + Vector2(-5, -30), Vector2(10, 30)), STONE)
	draw_line(-across + Vector2(0, -32), across + Vector2(0, -32), OUTLINE, 7.0)
	draw_line(-across + Vector2(0, -32), across + Vector2(0, -32), STONE.lightened(0.1), 5.0)
