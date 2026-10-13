@tool
extends Node2D
## Ground for the Dark Forest: dark undergrowth with ferns, mushrooms and fallen leaves, a worn
## dirt trail through the sections, a mossy boss clearing ringed with standing stones, and the
## exit gate (MAP_DESIGN.md §4, DUNGEON_DESIGN.md). Drawn once; same hand-drawn pixel style as
## the world map ground.

const UNDERGROWTH := Color("1b2e21")
const UNDERGROWTH_ALT := Color("1e3324")
const TRAIL := Color("4a3d2c")
const TRAIL_EDGE := Color("2e2619")
const PEBBLE := Color("6e6252")
const CLEARING := Color("29402e")
const MOSS := Color("3a5a36")
const STONE := Color("6d7068")
const OUTLINE := Color("10140f")
const GATE_GLOW := Color(0.55, 0.85, 1.0, 0.35)
const FLAME := Color("ffb347")
const FERN := Color("2f5a3a")
const LEAF := Color("6a4a2a")
const MUSHROOM: Array[Color] = [Color("c94a4a"), Color("d9b356"), Color("9aa0a6")]
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
	var columns := int(map_size.x / TILE) + 1
	var rows := int(map_size.y / TILE) + 1
	for x in columns:
		for y in rows:
			var roll := _hash(x, y, 1) % 100
			var color := UNDERGROWTH if roll > 30 else UNDERGROWTH_ALT
			draw_rect(Rect2(Vector2(x, y) * TILE, Vector2(TILE, TILE)), color)
	draw_circle(arena_center, arena_radius, CLEARING)
	for i in 24:
		var at := arena_center + Vector2.RIGHT.rotated(i * TAU / 24.0 + 0.3) * (arena_radius * (0.3 + (i % 5) * 0.14))
		draw_ellipse(at, 10.0, 5.0, Color(MOSS, 0.6))
	if trail.size() >= 2:
		draw_polyline(trail, TRAIL_EDGE, trail_width + 8.0, true)
		for point in trail:
			draw_circle(point, trail_width * 0.5 + 4.0, TRAIL_EDGE)
		draw_polyline(trail, TRAIL, trail_width, true)
		for point in trail:
			draw_circle(point, trail_width * 0.5, TRAIL)
		_trail_details()
	# Undergrowth decoration, skipping the trail and the clearing.
	for x in columns:
		for y in rows:
			var tile := Vector2i(x, y)
			var centre := (Vector2(tile) + Vector2(0.5, 0.5)) * TILE
			if _on_trail(centre) or centre.distance_to(arena_center) < arena_radius + 10.0:
				continue
			_tufts(tile, 2 + _hash(x, y, 3) % 2)
			var roll := _hash(x, y, 5) % 100
			if roll < 14:
				_fern(tile)
			elif roll < 20:
				_mushrooms(tile)
			elif roll < 32:
				_leaves(tile)
	# Standing stones around the boss clearing.
	for i in 14:
		var stone_position := arena_center + Vector2.RIGHT.rotated(TAU * i / 14.0) * (arena_radius + 4.0)
		var tall := 10.0 + (i % 3) * 3.0
		var stone := Rect2(stone_position - Vector2(4, tall), Vector2(8, tall))
		draw_ellipse(stone_position + Vector2(1, 1), 7.0, 3.0, Color(0, 0, 0, 0.3))
		draw_rect(stone.grow(1.0), OUTLINE)
		draw_rect(stone, STONE)
		draw_rect(Rect2(stone.position, Vector2(3, tall)), STONE.lightened(0.15))
		draw_rect(Rect2(stone.position + Vector2(5, 0), Vector2(3, tall)), STONE.darkened(0.25))
		draw_circle(stone_position + Vector2(-2, -3), 2.0, Color(MOSS.lightened(0.2), 0.8))
	_draw_exit()


## Pebbles and worn ruts along the trail.
func _trail_details() -> void:
	for i in range(trail.size() - 1):
		var a := trail[i]
		var b := trail[i + 1]
		var steps := int(a.distance_to(b) / 14.0)
		for j in steps:
			var roll := _hash(i, j, 7) % 100
			var at := a.lerp(b, float(j) / maxf(steps, 1.0)) + Vector2((roll % 40) - 20.0, (roll % 7) - 3.0)
			if roll < 45:
				draw_ellipse(at + Vector2(0, 0.6), 1.8, 0.9, TRAIL_EDGE)
				draw_ellipse(at, 1.5, 0.8, PEBBLE)
			elif roll < 60:
				draw_line(at, at + Vector2(6, 3), TRAIL.darkened(0.2), 1.0)


func _on_trail(point: Vector2) -> bool:
	for i in range(trail.size() - 1):
		var closest := Geometry2D.get_closest_point_to_segment(point, trail[i], trail[i + 1])
		if closest.distance_to(point) < trail_width * 0.5 + 6.0:
			return true
	return false


func _tufts(tile: Vector2i, count: int) -> void:
	for i in count:
		var base := _at(tile, 0.15 + _unit(tile, 60 + i) * 0.7, 0.15 + _unit(tile, 70 + i) * 0.7)
		draw_line(base, base + Vector2(-1.5, -3), UNDERGROWTH.lightened(0.25), 1.0)
		draw_line(base, base + Vector2(0, -4), UNDERGROWTH.lightened(0.35), 1.0)
		draw_line(base, base + Vector2(1.5, -3), UNDERGROWTH.lightened(0.25), 1.0)


## Fern: a dark fan of fronds.
func _fern(tile: Vector2i) -> void:
	var base := _at(tile, 0.5, 0.7)
	for i in 5:
		var angle := -PI * 0.5 + (i - 2) * 0.45
		var tip := base + Vector2.RIGHT.rotated(angle) * (9.0 + (i % 2) * 3.0)
		draw_line(base, tip, FERN.darkened(0.3), 2.0)
		draw_line(base, tip, FERN, 1.0)
		draw_line(base.lerp(tip, 0.5), base.lerp(tip, 0.5) + Vector2.RIGHT.rotated(angle + 0.9) * 3.0, FERN, 1.0)
		draw_line(base.lerp(tip, 0.5), base.lerp(tip, 0.5) + Vector2.RIGHT.rotated(angle - 0.9) * 3.0, FERN, 1.0)


func _mushrooms(tile: Vector2i) -> void:
	var color := MUSHROOM[_hash(tile.x, tile.y, 9) % MUSHROOM.size()]
	for i in 3:
		var base := _at(tile, 0.3 + _unit(tile, 20 + i) * 0.4, 0.4 + _unit(tile, 30 + i) * 0.4)
		var height := 3.0 + (i % 2) * 2.0
		draw_line(base, base + Vector2(0, -height), Color("e6e2d8"), 1.5)
		draw_ellipse(base + Vector2(0, -height), 3.0, 2.0, OUTLINE)
		draw_ellipse(base + Vector2(0, -height - 0.5), 2.5, 1.5, color)


func _leaves(tile: Vector2i) -> void:
	for i in 3:
		var at := _at(tile, _unit(tile, 40 + i), _unit(tile, 50 + i))
		draw_ellipse(at, 2.5, 1.5, Color(LEAF, 0.8))


## Exit gate: two pillars with torches and a soft glow.
func _draw_exit() -> void:
	draw_circle(exit_position + Vector2(0, -6), 22.0, GATE_GLOW)
	draw_circle(exit_position + Vector2(0, -6), 12.0, Color(GATE_GLOW, 0.3))
	for side: float in [-1.0, 1.0]:
		var pillar := Rect2(exit_position + Vector2(side * 22.0 - 5.0, -30.0), Vector2(10, 30))
		draw_rect(pillar.grow(1.0), OUTLINE)
		draw_rect(pillar, STONE)
		draw_rect(Rect2(pillar.position, Vector2(3, 30)), STONE.lightened(0.15))
		for row in range(1, 4):
			draw_line(pillar.position + Vector2(0, row * 8.0), pillar.position + Vector2(10, row * 8.0), STONE.darkened(0.35), 1.0)
		var torch := pillar.position + Vector2(5.0, -4.0)
		draw_circle(torch, 5.0, Color(FLAME, 0.25))
		draw_circle(torch, 2.2, FLAME)
		draw_circle(torch + Vector2(0, 0.5), 1.0, Color("fff2a8"))
	draw_line(exit_position + Vector2(-27, -32), exit_position + Vector2(27, -32), OUTLINE, 7.0)
	draw_line(exit_position + Vector2(-27, -32), exit_position + Vector2(27, -32), STONE.lightened(0.1), 5.0)


func _at(tile: Vector2i, u: float, v: float) -> Vector2:
	return (Vector2(tile) + Vector2(u, v)) * TILE


static func _hash(x: int, y: int, salt: int) -> int:
	var h := (x * 73856093) ^ (y * 19349663) ^ (salt * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	return absi(h ^ (h >> 16))


static func _unit(tile: Vector2i, salt: int) -> float:
	return float(_hash(tile.x, tile.y, salt) % 1000) / 1000.0
