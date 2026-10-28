@tool
extends Node2D
## Ground for the Goblin Warren (Cave Dungeon): dark rocky cavern floor, worn earthen trail,
## mining rubble, mineral crystal clusters, torches, and a fortified warlord battle arena.

const CAVE_FLOOR := Color("231c18")
const CAVE_FLOOR_ALT := Color("2c231e")
const TRAIL := Color("3d3126")
const TRAIL_EDGE := Color("1a140f")
const PEBBLE := Color("544638")
const ARENA_FLOOR := Color("362a22")
const ROCK := Color("4f443b")
const OUTLINE := Color("110d0a")
const GATE_GLOW := Color(1.0, 0.6, 0.2, 0.35)
const FLAME := Color("ff9800")
const CRYSTAL := Color("00e5ff")
const BONE := Color("d7d0c0")
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
			var roll := _hash(x, y, 1) % 100
			var color := CAVE_FLOOR if roll > 35 else CAVE_FLOOR_ALT
			draw_rect(Rect2(Vector2(x, y) * TILE, Vector2(TILE, TILE)), color)
	draw_circle(arena_center, arena_radius, ARENA_FLOOR)
	for i in 20:
		var at := arena_center + Vector2.RIGHT.rotated(i * TAU / 20.0 + 0.2) * (arena_radius * (0.3 + (i % 4) * 0.16))
		draw_ellipse(at, 12.0, 6.0, Color(CAVE_FLOOR, 0.6))
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
			var roll := _hash(x, y, 4) % 100
			if roll < 16:
				_rock_cluster(tile)
			elif roll < 24:
				_crystals(tile)
			elif roll < 32:
				_bones(tile)

	# Cave pillars ring around boss arena
	for i in 12:
		var pillar_pos := arena_center + Vector2.RIGHT.rotated(TAU * i / 12.0) * (arena_radius + 4.0)
		var tall := 14.0 + (i % 3) * 4.0
		var r := Rect2(pillar_pos - Vector2(5, tall), Vector2(10, tall))
		draw_ellipse(pillar_pos + Vector2(1, 1), 8.0, 4.0, Color(0, 0, 0, 0.4))
		draw_rect(r.grow(1.0), OUTLINE)
		draw_rect(r, ROCK)
		draw_rect(Rect2(r.position, Vector2(3, tall)), ROCK.lightened(0.2))
		draw_rect(Rect2(r.position + Vector2(7, 0), Vector2(3, tall)), ROCK.darkened(0.3))
	_draw_exit()


func _trail_details() -> void:
	for i in range(trail.size() - 1):
		var a := trail[i]
		var b := trail[i + 1]
		var steps := int(a.distance_to(b) / 14.0)
		for j in steps:
			var roll := _hash(i, j, 7) % 100
			var at := a.lerp(b, float(j) / maxf(steps, 1.0)) + Vector2((roll % 40) - 20.0, (roll % 7) - 3.0)
			if roll < 45:
				draw_ellipse(at + Vector2(0, 0.6), 2.0, 1.0, TRAIL_EDGE)
				draw_ellipse(at, 1.6, 0.8, PEBBLE)
			elif roll < 65:
				draw_line(at, at + Vector2(5, 2), TRAIL.darkened(0.25), 1.0)


func _on_trail(point: Vector2) -> bool:
	for i in range(trail.size() - 1):
		var closest := Geometry2D.get_closest_point_to_segment(point, trail[i], trail[i + 1])
		if closest.distance_to(point) < trail_width * 0.5 + 6.0:
			return true
	return false


func _rock_cluster(tile: Vector2i) -> void:
	var base := _at(tile, 0.5, 0.5)
	draw_ellipse(base, 5.0, 3.0, OUTLINE)
	draw_ellipse(base + Vector2(0, -1), 4.5, 2.5, ROCK)
	draw_ellipse(base + Vector2(-2, 1), 3.0, 2.0, ROCK.darkened(0.2))


func _crystals(tile: Vector2i) -> void:
	var base := _at(tile, 0.5, 0.6)
	draw_line(base, base + Vector2(-2, -6), CRYSTAL, 1.5)
	draw_line(base, base + Vector2(2, -8), CRYSTAL.lightened(0.3), 1.5)
	draw_line(base, base + Vector2(4, -4), CRYSTAL, 1.2)


func _bones(tile: Vector2i) -> void:
	var at := _at(tile, 0.4, 0.5)
	draw_line(at, at + Vector2(6, 2), BONE, 1.5)
	draw_ellipse(at, 1.5, 1.5, BONE)
	draw_ellipse(at + Vector2(6, 2), 1.5, 1.5, BONE)


func _draw_exit() -> void:
	draw_circle(exit_position + Vector2(0, -6), 22.0, GATE_GLOW)
	draw_circle(exit_position + Vector2(0, -6), 12.0, Color(GATE_GLOW, 0.4))
	for side: float in [-1.0, 1.0]:
		var pillar := Rect2(exit_position + Vector2(side * 22.0 - 5.0, -30.0), Vector2(10, 30))
		draw_rect(pillar.grow(1.0), OUTLINE)
		draw_rect(pillar, ROCK)
		draw_rect(Rect2(pillar.position, Vector2(3, 30)), ROCK.lightened(0.2))
		var torch := pillar.position + Vector2(5.0, -4.0)
		draw_circle(torch, 5.0, Color(FLAME, 0.3))
		draw_circle(torch, 2.5, FLAME)
	draw_line(exit_position + Vector2(-27, -32), exit_position + Vector2(27, -32), OUTLINE, 7.0)
	draw_line(exit_position + Vector2(-27, -32), exit_position + Vector2(27, -32), ROCK.lightened(0.15), 5.0)


func _at(tile: Vector2i, u: float, v: float) -> Vector2:
	return (Vector2(tile) + Vector2(u, v)) * TILE


static func _hash(x: int, y: int, salt: int) -> int:
	var h := (x * 73856093) ^ (y * 19349663) ^ (salt * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	return absi(h ^ (h >> 16))
