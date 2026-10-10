@tool
extends Node2D
## Town ground (TOWN_DESIGN.md §3, DECISIONS.md D8): grass, roads, plaza, Training Yard with
## dummies, closed North Road and the South Gate. Warm, safe, organized.

const GRASS := Color("4f7a46")
const GRASS_ALT := Color("547f4a")
const ROAD := Color("a88a63")
const ROAD_EDGE := Color("8f7553")
const PLAZA := Color("b59a72")
const YARD := Color("9c8661")
const FENCE := Color("6b4a2f")
const STONE := Color("8a8a84")
const OUTLINE := Color("16161c")
const LAMP := Color("ffd27a")
const TILE := 32.0

@export var map_size := Vector2(360, 800)
@export var plaza_center := Vector2(180, 530)
@export var plaza_radius := 42.0
@export var yard_rect := Rect2(22, 330, 104, 100)
@export var gate_position := Vector2(180, 772)
@export var north_barricade_y := 78.0


func _draw() -> void:
	for x in range(int(map_size.x / TILE) + 1):
		for y in range(int(map_size.y / TILE) + 1):
			draw_rect(Rect2(Vector2(x, y) * TILE, Vector2(TILE, TILE)), GRASS if (x + y) % 2 == 0 else GRASS_ALT)
	# Roads: main street north → south, three cross streets in front of the building rows.
	_road(Rect2(162, 0, 36, map_size.y))
	for y in [262.0, 452.0, 662.0]:
		_road(Rect2(30, y, 300, 22))
	draw_circle(plaza_center, plaza_radius + 2, ROAD_EDGE)
	draw_circle(plaza_center, plaza_radius, PLAZA)
	draw_circle(plaza_center, 7, STONE)
	# Training Yard: fenced sand area with dummies.
	draw_rect(yard_rect, YARD)
	draw_rect(yard_rect, FENCE, false, 2.0)
	for dummy in [Vector2(50, 365), Vector2(98, 365), Vector2(50, 410), Vector2(98, 410)]:
		draw_line(dummy, dummy + Vector2(0, -16), OUTLINE, 3.0)
		draw_line(dummy + Vector2(-6, -11), dummy + Vector2(6, -11), FENCE, 3.0)
		draw_circle(dummy + Vector2(0, -18), 4.0, Color("c9a86b"))
	# North Road closed in MVP (future regions).
	for x in range(150, 214, 14):
		draw_rect(Rect2(x, north_barricade_y - 10, 10, 12).grow(1.0), OUTLINE)
		draw_rect(Rect2(x, north_barricade_y - 10, 10, 12), FENCE)
	# South Gate: two towers and an arch, the expedition exit.
	for side in [-1.0, 1.0]:
		var tower := Rect2(gate_position + Vector2(side * 34.0 - 9.0, -34.0), Vector2(18, 34))
		draw_rect(tower.grow(1.0), OUTLINE)
		draw_rect(tower, STONE)
	draw_rect(Rect2(gate_position + Vector2(-26, -34), Vector2(52, 6)), STONE.darkened(0.2))
	# Lamps along the main street.
	for y in [180.0, 380.0, 600.0]:
		for x in [150.0, 210.0]:
			draw_line(Vector2(x, y), Vector2(x, y - 14), OUTLINE, 2.0)
			draw_circle(Vector2(x, y - 15), 3.0, LAMP)


func _road(rect: Rect2) -> void:
	draw_rect(rect.grow(2.0), ROAD_EDGE)
	draw_rect(rect, ROAD)
