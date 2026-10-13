@tool
class_name WorldProp
extends StaticBody2D
## Region decoration that blocks movement (navigation obstacle): leafy trees (Town edges), pines
## (Dark Forest), boulders (Goblin Cave), broken columns (Ancient Ruins). Origin at the base.
## Shading: light from the top-left, outlines one pixel darker than the darkest shade.

enum Kind { TREE, ROCK, COLUMN, PINE }

const OUTLINE := Color("10140f")
const TRUNK := Color("5a3f2a")
const MOSS := Color("5f7a3a")

@export var kind: Kind = Kind.TREE:
	set(value):
		kind = value
		queue_redraw()
@export var size := 1.0:
	set(value):
		size = value
		queue_redraw()
@export var tint := Color("23452b"):
	set(value):
		tint = value
		queue_redraw()


func _init() -> void:
	add_to_group(&"navigation_obstacles")
	collision_layer = 1
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 7.0
	shape.shape = circle
	shape.position = Vector2(0, -2)
	add_child(shape)


func _draw() -> void:
	draw_ellipse(Vector2(2.0 * size, 0.0), 12.0 * size, 4.5 * size, Color(0, 0, 0, 0.3))
	match kind:
		Kind.TREE:
			_draw_tree()
		Kind.PINE:
			_draw_pine()
		Kind.ROCK:
			_draw_rock()
		Kind.COLUMN:
			_draw_column()


func _scaled(points: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point: Vector2 in points:
		result.append(point * size)
	return result


func _draw_trunk(height: float) -> void:
	var trunk := _scaled([Vector2(-4, 0), Vector2(-2.5, -2), Vector2(-2, -height), Vector2(2, -height), Vector2(2.5, -2), Vector2(4, 0)])
	draw_colored_polygon(BuildingVisual._grow(trunk, 1.0), OUTLINE)
	draw_colored_polygon(trunk, TRUNK)
	draw_line(Vector2(1.0, -1.0) * size, Vector2(1.0, -height + 1.0) * size, TRUNK.darkened(0.35), 1.0)


## Leafy tree: clustered round blobs, dark base layer, lit layer, highlights.
func _draw_tree() -> void:
	_draw_trunk(13.0)
	var blobs := [[Vector2(0, -20), 11.0], [Vector2(-8, -24), 8.0], [Vector2(8, -23), 8.0],
		[Vector2(-4, -31), 8.5], [Vector2(5, -32), 7.5], [Vector2(0, -38), 5.5]]
	for blob: Array in blobs:
		draw_circle(blob[0] * size, (blob[1] + 1.0) * size, OUTLINE)
	for blob: Array in blobs:
		draw_circle(blob[0] * size, blob[1] * size, tint.darkened(0.25))
	for blob: Array in blobs:
		draw_circle((blob[0] + Vector2(-1.0, -1.5)) * size, blob[1] * 0.78 * size, tint)
	for i in [1, 3, 5]:
		var blob: Array = blobs[i]
		draw_circle((blob[0] + Vector2(-2.0, -3.0)) * size, blob[1] * 0.38 * size, tint.lightened(0.2))


## Pine: three drooping tiers, lit left half, dark right half.
func _draw_pine() -> void:
	_draw_trunk(9.0)
	for tier: Array in [[-7.0, 12.0, 15.0], [-16.0, 9.5, 14.0], [-25.0, 6.5, 13.0]]:
		var base: float = tier[0]
		var half: float = tier[1]
		var height: float = tier[2]
		var outline := _scaled([Vector2(-half, base), Vector2(0, base + 2.0), Vector2(half, base), Vector2(0, base - height)])
		draw_colored_polygon(BuildingVisual._grow(outline, 1.0), OUTLINE)
		draw_colored_polygon(_scaled([Vector2(0, base + 2.0), Vector2(half, base), Vector2(0, base - height)]), tint.darkened(0.3))
		draw_colored_polygon(_scaled([Vector2(-half, base), Vector2(0, base + 2.0), Vector2(0, base - height)]), tint)
		draw_line(Vector2(-half * 0.55, base - height * 0.3) * size, Vector2(-1.0, base - height * 0.75) * size, tint.lightened(0.18), 1.0)


## Faceted boulder: lit top, shaded right side, a crack and some moss.
func _draw_rock() -> void:
	var outline := _scaled([Vector2(-12, 0), Vector2(-11, -8), Vector2(-4, -14), Vector2(6, -13), Vector2(12, -5), Vector2(10, 1)])
	draw_colored_polygon(BuildingVisual._grow(outline, 1.0), OUTLINE)
	draw_colored_polygon(outline, tint)
	draw_colored_polygon(_scaled([Vector2(-11, -8), Vector2(-4, -14), Vector2(6, -13), Vector2(3, -7), Vector2(-6, -6)]), tint.lightened(0.15))
	draw_colored_polygon(_scaled([Vector2(3, -7), Vector2(6, -13), Vector2(12, -5), Vector2(10, 1), Vector2(2, 1)]), tint.darkened(0.25))
	draw_polyline(_scaled([Vector2(-3, -6), Vector2(-1, -2), Vector2(-3, 1)]), tint.darkened(0.4), 1.0)
	draw_circle(Vector2(-7, -8) * size, 2.0 * size, Color(MOSS, 0.8))
	draw_circle(Vector2(-4, -10) * size, 1.5 * size, Color(MOSS, 0.8))
	# Pebble beside it.
	draw_circle(Vector2(13, 1) * size, 2.0 * size, OUTLINE)
	draw_circle(Vector2(13, 0.5) * size, 1.3 * size, tint.lightened(0.1))


## Broken fluted column on a square base, moss at its foot.
func _draw_column() -> void:
	var height := 34.0 * size
	var base := Rect2(Vector2(-8, -6), Vector2(16, 6))
	draw_rect(base.grow(1.0), OUTLINE)
	draw_rect(base, tint.darkened(0.2))
	draw_rect(Rect2(Vector2(-8, -6), Vector2(16, 2)), tint)
	var shaft := Rect2(Vector2(-5, -height), Vector2(10, height - 6))
	draw_rect(shaft.grow(1.0), OUTLINE)
	draw_rect(shaft, tint)
	draw_rect(Rect2(Vector2(-5, -height), Vector2(2, height - 6)), tint.lightened(0.15))
	draw_rect(Rect2(Vector2(3, -height), Vector2(2, height - 6)), tint.darkened(0.22))
	for x: float in [-1.0, 1.5]:
		draw_line(Vector2(x, -height + 2), Vector2(x, -7), tint.darkened(0.15), 1.0)
	# Broken top.
	var broken := PackedVector2Array([Vector2(-5, -height), Vector2(5, -height), Vector2(5, -height - 3), Vector2(2, -height - 7), Vector2(-1, -height - 3), Vector2(-5, -height - 5)])
	draw_colored_polygon(BuildingVisual._grow(broken, 1.0), OUTLINE)
	draw_colored_polygon(broken, tint.lightened(0.1))
	draw_circle(Vector2(-6, -2), 2.5, Color(MOSS, 0.85))
	draw_circle(Vector2(6, -1), 2.0, Color(MOSS, 0.7))
	# A fallen chunk.
	draw_rect(Rect2(Vector2(9, -4), Vector2(5, 4)).grow(1.0), OUTLINE)
	draw_rect(Rect2(Vector2(9, -4), Vector2(5, 4)), tint.darkened(0.1))
