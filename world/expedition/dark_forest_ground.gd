@tool
extends Node2D
## Ground for the Dark Forest: dark undergrowth, dirt trail through the sections, boss
## clearing with a stone circle, entrance and exit gate (MAP_DESIGN.md §4, DUNGEON_DESIGN.md).

const UNDERGROWTH := Color("1b2e21")
const UNDERGROWTH_ALT := Color("1e3324")
const TRAIL := Color("3a3226")
const CLEARING := Color("29402e")
const STONE := Color("6d7068")
const OUTLINE := Color("10140f")
const GATE_GLOW := Color(0.55, 0.85, 1.0, 0.35)
const TILE := 32.0

@export var map_size := Vector2(360, 1440):
	set(value):
		map_size = value
		queue_redraw()
## Trail from entrance (first) to exit (last).
@export var trail: PackedVector2Array = []:
	set(value):
		trail = value
		queue_redraw()
@export var trail_width := 64.0
@export var arena_center := Vector2(180, 330)
@export var arena_radius := 120.0
@export var exit_position := Vector2(180, 120)


func _draw() -> void:
	for x in range(int(map_size.x / TILE) + 1):
		for y in range(int(map_size.y / TILE) + 1):
			var color := UNDERGROWTH if (x * 7 + y * 3) % 5 != 0 else UNDERGROWTH_ALT
			draw_rect(Rect2(Vector2(x, y) * TILE, Vector2(TILE, TILE)), color)
	draw_circle(arena_center, arena_radius, CLEARING)
	if trail.size() >= 2:
		draw_polyline(trail, TRAIL, trail_width, true)
		for point in trail:
			draw_circle(point, trail_width * 0.5, TRAIL)
	# Stone circle around the boss clearing.
	for i in 14:
		var stone_position := arena_center + Vector2.RIGHT.rotated(TAU * i / 14.0) * (arena_radius + 4.0)
		draw_rect(Rect2(stone_position - Vector2(4, 6), Vector2(8, 10)).grow(1.0), OUTLINE)
		draw_rect(Rect2(stone_position - Vector2(4, 6), Vector2(8, 10)), STONE)
	# Exit gate: two pillars and a soft glow.
	draw_circle(exit_position + Vector2(0, -6), 22.0, GATE_GLOW)
	for side in [-1.0, 1.0]:
		var pillar := Rect2(exit_position + Vector2(side * 22.0 - 5.0, -30.0), Vector2(10, 30))
		draw_rect(pillar.grow(1.0), OUTLINE)
		draw_rect(pillar, STONE)
