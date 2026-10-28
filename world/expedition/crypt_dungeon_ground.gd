@tool
extends Node2D
## Ground for the Ruined Sanctum (Crypt Dungeon): ancient cracked flagstones, spectral mist,
## ritual runestones, tombstones, and an eerie sanctum arena for the Crypt Lord.

const CRYPT_FLOOR := Color("14161d")
const CRYPT_FLOOR_ALT := Color("1b1e28")
const TRAIL := Color("292e3d")
const TRAIL_EDGE := Color("0d0f15")
const PEBBLE := Color("3d4354")
const ARENA_FLOOR := Color("1e2330")
const STONE := Color("4b5266")
const OUTLINE := Color("090b10")
const GATE_GLOW := Color(0.3, 0.7, 1.0, 0.4)
const SPECTRAL_FLAME := Color("00e5ff")
const RUNE := Color("7c4dff")
const TILE := 32.0

@export var map_size := Vector2(360, 1440):
	set(value):
		map_size = value
		queue_redraw()
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
			var roll := _hash(x, y, 2) % 100
			var color := CRYPT_FLOOR if roll > 40 else CRYPT_FLOOR_ALT
			draw_rect(Rect2(Vector2(x, y) * TILE, Vector2(TILE, TILE)), color)
	draw_circle(arena_center, arena_radius, ARENA_FLOOR)
	# Ritual circle in the arena
	draw_arc(arena_center, arena_radius * 0.7, 0, TAU, 32, Color(RUNE, 0.4), 2.0)
	draw_arc(arena_center, arena_radius * 0.35, 0, TAU, 24, Color(RUNE, 0.3), 1.5)

	if trail.size() >= 2:
		draw_polyline(trail, TRAIL_EDGE, trail_width + 8.0, true)
		for point in trail:
			draw_circle(point, trail_width * 0.5 + 4.0, TRAIL_EDGE)
		draw_polyline(trail, TRAIL, trail_width, true)
		for point in trail:
			draw_circle(point, trail_width * 0.5, TRAIL)
		_trail_details()

	for x in columns:
		for y in rows:
			var tile := Vector2i(x, y)
			var centre := (Vector2(tile) + Vector2(0.5, 0.5)) * TILE
			if _on_trail(centre) or centre.distance_to(arena_center) < arena_radius + 10.0:
				continue
			var roll := _hash(x, y, 6) % 100
			if roll < 15:
				_tombstone(tile)
			elif roll < 25:
				_cracked_slab(tile)
			elif roll < 33:
				_rune_tile(tile)

	# Crypt monoliths ring
	for i in 12:
		var monolith_pos := arena_center + Vector2.RIGHT.rotated(TAU * i / 12.0) * (arena_radius + 4.0)
		var tall := 16.0 + (i % 3) * 5.0
		var r := Rect2(monolith_pos - Vector2(5, tall), Vector2(10, tall))
		draw_ellipse(monolith_pos + Vector2(1, 1), 8.0, 4.0, Color(0, 0, 0, 0.5))
		draw_rect(r.grow(1.0), OUTLINE)
		draw_rect(r, STONE)
		draw_rect(Rect2(r.position, Vector2(3, tall)), STONE.lightened(0.2))
		draw_circle(monolith_pos + Vector2(0, -tall * 0.5), 1.5, Color(RUNE, 0.8))
	_draw_exit()


func _trail_details() -> void:
	for i in range(trail.size() - 1):
		var a := trail[i]
		var b := trail[i + 1]
		var steps := int(a.distance_to(b) / 14.0)
		for j in steps:
			var roll := _hash(i, j, 8) % 100
			var at := a.lerp(b, float(j) / maxf(steps, 1.0)) + Vector2((roll % 40) - 20.0, (roll % 7) - 3.0)
			if roll < 45:
				draw_ellipse(at + Vector2(0, 0.6), 2.0, 1.0, TRAIL_EDGE)
				draw_ellipse(at, 1.6, 0.8, PEBBLE)
			elif roll < 65:
				draw_line(at, at + Vector2(6, 0), TRAIL.darkened(0.3), 1.0)


func _on_trail(point: Vector2) -> bool:
	for i in range(trail.size() - 1):
		var closest := Geometry2D.get_closest_point_to_segment(point, trail[i], trail[i + 1])
		if closest.distance_to(point) < trail_width * 0.5 + 6.0:
			return true
	return false


func _tombstone(tile: Vector2i) -> void:
	var base := _at(tile, 0.5, 0.6)
	var r := Rect2(base - Vector2(4, 10), Vector2(8, 10))
	draw_rect(r.grow(1.0), OUTLINE)
	draw_rect(r, STONE)
	draw_rect(Rect2(r.position, Vector2(2, 10)), STONE.lightened(0.15))


func _cracked_slab(tile: Vector2i) -> void:
	var base := _at(tile, 0.4, 0.5)
	draw_line(base, base + Vector2(8, 4), TRAIL_EDGE, 1.2)
	draw_line(base + Vector2(4, 2), base + Vector2(3, 7), TRAIL_EDGE, 1.0)


func _rune_tile(tile: Vector2i) -> void:
	var base := _at(tile, 0.5, 0.5)
	draw_arc(base, 4.0, 0, TAU, 8, Color(RUNE, 0.4), 1.0)
	draw_circle(base, 1.0, Color(RUNE, 0.6))


func _draw_exit() -> void:
	draw_circle(exit_position + Vector2(0, -6), 22.0, GATE_GLOW)
	draw_circle(exit_position + Vector2(0, -6), 12.0, Color(GATE_GLOW, 0.5))
	for side: float in [-1.0, 1.0]:
		var pillar := Rect2(exit_position + Vector2(side * 22.0 - 5.0, -30.0), Vector2(10, 30))
		draw_rect(pillar.grow(1.0), OUTLINE)
		draw_rect(pillar, STONE)
		draw_rect(Rect2(pillar.position, Vector2(3, 30)), STONE.lightened(0.2))
		var torch := pillar.position + Vector2(5.0, -4.0)
		draw_circle(torch, 5.0, Color(SPECTRAL_FLAME, 0.35))
		draw_circle(torch, 2.5, SPECTRAL_FLAME)
	draw_line(exit_position + Vector2(-27, -32), exit_position + Vector2(27, -32), OUTLINE, 7.0)
	draw_line(exit_position + Vector2(-27, -32), exit_position + Vector2(27, -32), STONE.lightened(0.15), 5.0)


func _at(tile: Vector2i, u: float, v: float) -> Vector2:
	return (Vector2(tile) + Vector2(u, v)) * TILE


static func _hash(x: int, y: int, salt: int) -> int:
	var h := (x * 73856093) ^ (y * 19349663) ^ (salt * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	return absi(h ^ (h >> 16))
