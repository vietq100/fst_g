@tool
class_name WorldProp
extends StaticBody2D
## Region decoration that blocks movement (navigation obstacle): leafy trees (Town edges), pines
## (Dark Forest), boulders (Goblin Cave), broken columns (Ancient Ruins). Origin at the base.
## Shading: light from the top-left, dark outlines, a soft ground shadow cast to the right (D59).
## Each prop picks a variant from its position: fruit or blossom trees, pine cones, a crystal in a
## boulder, column height.

enum Kind { TREE, ROCK, COLUMN, PINE }

const OUTLINE := Color("10140f")
const TRUNK := Color("5a3f2a")
const MOSS := Color("5f7a3a")
const APPLE := Color("d8423a")
const BLOSSOM := Color("f4b6c8")
const CRYSTAL := Color("6fd3ff")

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
	match kind:
		Kind.TREE:
			_draw_tree()
		Kind.PINE:
			_draw_pine()
		Kind.ROCK:
			_draw_rock()
		Kind.COLUMN:
			_draw_column()


## 0..99, stable per placed prop (from its position).
func _variant() -> int:
	return _hash(int(position.x), int(position.y), 11) % 100


func _scaled(points: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point: Vector2 in points:
		result.append(point * size)
	return result


func _circle(centre: Vector2, radius: float, color: Color) -> void:
	draw_circle(centre * size, radius * size, color)


func _ellipse(centre: Vector2, rx: float, ry: float, color: Color) -> void:
	draw_ellipse(centre * size, rx * size, ry * size, color)


func _line(a: Vector2, b: Vector2, color: Color, width: float = 1.0) -> void:
	draw_line(a * size, b * size, color, width)


func _rect(rect: Rect2, color: Color) -> void:
	draw_rect(Rect2(rect.position * size, rect.size * size), color)


## Polygon with a dark outline (grown copy behind it).
func _outlined(points: Array, color: Color) -> void:
	var shape := _scaled(points)
	draw_colored_polygon(BuildingVisual._grow(shape, 1.0), OUTLINE)
	draw_colored_polygon(shape, color)


## Tapered trunk with a lit left edge, a dark right edge and two roots.
func _draw_trunk(height: float, width: float = 4.0) -> void:
	_outlined([Vector2(-width - 2.0, 0), Vector2(-width + 0.5, -2), Vector2(-width + 1.5, -height), Vector2(width - 1.5, -height),
		Vector2(width - 0.5, -2), Vector2(width + 2.0, 0)], TRUNK)
	_line(Vector2(width - 2.2, -1), Vector2(width - 2.4, -height + 1.0), TRUNK.darkened(0.35), 1.5)
	_line(Vector2(-width + 1.8, -2), Vector2(-width + 2.2, -height + 2.0), TRUNK.lightened(0.18))
	for root: float in [-width - 3.0, width + 3.0]:
		_line(Vector2(root * 0.6, -1), Vector2(root, 0.5), TRUNK.darkened(0.2), 1.5)


## Leafy tree: six outlined canopy clumps, lit layer, highlights on the upper-left clumps, leaf
## clusters, and apples (a quarter) or blossoms (a fifth).
func _draw_tree() -> void:
	var variant := _variant()
	_ellipse(Vector2(4, 0), 15.0, 5.0, Color(0, 0, 0, 0.28))
	_draw_trunk(14.0)
	var blobs := [[Vector2(0, -21), 12.0], [Vector2(-9, -25), 9.0], [Vector2(9, -24), 9.0], [Vector2(-5, -33), 9.5],
		[Vector2(6, -33), 8.5], [Vector2(0, -40), 7.0]]
	for blob: Array in blobs:
		_circle(blob[0], blob[1] + 1.2, OUTLINE)
	for blob: Array in blobs:
		_circle(blob[0], blob[1], tint.darkened(0.3))
	for blob: Array in blobs:
		var centre: Vector2 = blob[0]
		_circle(centre + Vector2(-1, -1.5), blob[1] * 0.82, tint)
	for i in [1, 3, 5]:
		var blob: Array = blobs[i]
		var centre: Vector2 = blob[0]
		_circle(centre + Vector2(-2, -2.5), blob[1] * 0.42, tint.lightened(0.16))
	for i in 16:
		var point := _canopy_point(variant, i, 1, 3.0, 10.0)
		var lit := point.x + point.y + 29.0 < -2.0
		_circle(point, 1.5, tint.lightened(0.22) if lit else tint.darkened(0.22))
	if variant < 25:
		for i in 6:
			var point := _canopy_point(variant, i, 3, 4.0, 9.0)
			_circle(point, 1.6, APPLE.darkened(0.45))
			_circle(point - Vector2(0.4, 0.4), 1.1, APPLE)
	elif variant < 45:
		for i in 9:
			var point := _canopy_point(variant, i, 5, 3.0, 11.0)
			_circle(point, 1.3, BLOSSOM)
			_circle(point, 0.6, BLOSSOM.lightened(0.7))


## A point inside the canopy (centred at y -29), spread by the variant.
func _canopy_point(variant: int, index: int, salt: int, near: float, spread: float) -> Vector2:
	var angle := deg_to_rad(float(_hash(variant, index, salt) % 360))
	var distance := near + float(_hash(variant, index, salt + 1) % 100) / 100.0 * spread
	return Vector2(cos(angle) * distance, -29.0 + sin(angle) * distance * 0.9)


## Pine: four tiers with saw-tooth skirts, lit left half, dark right half, needle strokes; some
## have cones.
func _draw_pine() -> void:
	_ellipse(Vector2(4, 0), 14.0, 5.0, Color(0, 0, 0, 0.3))
	_draw_trunk(9.0, 3.5)
	for tier: Array in [[-7.0, 13.0, 15.0], [-15.0, 10.5, 14.0], [-23.0, 8.0, 13.0], [-30.0, 5.0, 11.0]]:
		var base: float = tier[0]
		var half: float = tier[1]
		var height: float = tier[2]
		var skirt: Array[Vector2] = [Vector2(-half, base)]
		for i in range(1, 12):
			skirt.append(Vector2(-half + half * 2.0 * i / 12.0, base + (3.0 if i % 2 == 1 else 0.0)))
		skirt.append(Vector2(half, base))
		var whole: Array = skirt.duplicate()
		whole.append(Vector2(0, base - height))
		_outlined(whole, tint.darkened(0.32))
		var lit: Array = []
		for point in skirt:
			if point.x <= 0.0:
				lit.append(point)
		lit.append(Vector2(0, base + 2.0))
		lit.append(Vector2(0, base - height))
		draw_colored_polygon(_scaled(lit), tint)
		_line(Vector2(-half * 0.6, base - height * 0.25), Vector2(-1.5, base - height * 0.8), tint.lightened(0.22))
		_line(Vector2(-half * 0.3, base - height * 0.15), Vector2(-0.5, base - height * 0.55), tint.lightened(0.12))
	if _variant() < 20:
		for i in 2:
			_ellipse(Vector2(-4 + i * 7, -10 - i * 3), 1.6, 2.4, Color("6a4a2a"))


## Boulder with a smaller rock beside it: lit top facet, shaded right face, cracks, a moss cap
## and a pebble; some hide a glowing crystal.
func _draw_rock() -> void:
	_ellipse(Vector2(3, 0), 17.0, 5.0, Color(0, 0, 0, 0.3))
	_outlined([Vector2(9, 1), Vector2(10, -5), Vector2(15, -7), Vector2(20, -3), Vector2(19, 1)], tint)
	_outlined([Vector2(-13, 0), Vector2(-12, -9), Vector2(-5, -16), Vector2(6, -15), Vector2(13, -6), Vector2(11, 1)], tint)
	draw_colored_polygon(_scaled([Vector2(-12, -9), Vector2(-5, -16), Vector2(6, -15), Vector2(3, -8), Vector2(-6, -7)]), tint.lightened(0.16))
	draw_colored_polygon(_scaled([Vector2(3, -8), Vector2(6, -15), Vector2(13, -6), Vector2(11, 1), Vector2(2, 1)]), tint.darkened(0.25))
	draw_colored_polygon(_scaled([Vector2(10, -5), Vector2(15, -7), Vector2(16, -4), Vector2(11, -3)]), tint.lightened(0.14))
	_line(Vector2(-3, -6), Vector2(-1, -2), tint.darkened(0.45))
	_line(Vector2(-1, -2), Vector2(-3, 1), tint.darkened(0.45))
	for moss: Array in [[Vector2(-6, -12), 2.6], [Vector2(-2, -14), 2.2], [Vector2(-9, -9), 1.8]]:
		var centre: Vector2 = moss[0]
		var radius: float = moss[1]
		_circle(centre, radius, Color(MOSS, 0.9))
		_circle(centre - Vector2(0.5, 0.6), radius * 0.5, MOSS.lightened(0.2))
	_ellipse(Vector2(-16, 0.5), 2.2, 1.3, OUTLINE)
	_ellipse(Vector2(-16, 0), 1.6, 1.0, tint.lightened(0.1))
	if _variant() < 30:
		_circle(Vector2(1, -3), 3.0, Color(CRYSTAL, 0.2))
		draw_colored_polygon(_scaled([Vector2(0, 0), Vector2(2, 0), Vector2(1, -6)]), CRYSTAL)


## Broken fluted column on a stepped base, ivy creeping up, rubble around it.
func _draw_column() -> void:
	var height := 30.0 + (_variant() % 3) * 4.0
	_ellipse(Vector2(3, 0), 14.0, 4.5, Color(0, 0, 0, 0.3))
	_rect(Rect2(-10, -4, 20, 4), OUTLINE)
	_rect(Rect2(-9, -3.5, 18, 3.5), tint.darkened(0.2))
	_rect(Rect2(-9, -3.5, 18, 1), tint.lightened(0.05))
	_rect(Rect2(-8, -8, 16, 4.5), OUTLINE)
	_rect(Rect2(-7, -7.5, 14, 4), tint.darkened(0.1))
	_rect(Rect2(-7, -7.5, 14, 1), tint.lightened(0.12))
	_rect(Rect2(-6, -height, 12, height - 7.0), OUTLINE)
	_rect(Rect2(-5, -height, 10, height - 7.5), tint)
	_rect(Rect2(-5, -height, 2.5, height - 7.5), tint.lightened(0.16))
	_rect(Rect2(2.5, -height, 2.5, height - 7.5), tint.darkened(0.22))
	for x: float in [-1.5, 1.0]:
		_line(Vector2(x, -height + 2.0), Vector2(x, -9), tint.darkened(0.15))
	var broken := [Vector2(-5.5, -height), Vector2(5.5, -height), Vector2(5.5, -height - 3.0), Vector2(3, -height - 7.0),
		Vector2(1, -height - 4.0), Vector2(-1.5, -height - 6.0), Vector2(-5.5, -height - 4.0)]
	_outlined(broken, tint.lightened(0.1))
	_line(Vector2(-1.5, -height - 6.0), Vector2(0, -height - 1.0), tint.darkened(0.2))
	for i in 7:
		var leaf := Vector2(-4.0 + sin(i * 1.3) * 3.0, -9.0 - i * 3.5)
		if leaf.y < -height + 2.0:
			break
		_circle(leaf, 1.7, MOSS.darkened(0.1))
		_circle(leaf - Vector2(0.4, 0.4), 1.0, MOSS.lightened(0.2))
	for piece: Rect2 in [Rect2(10, -5, 5, 4), Rect2(14, -2.5, 3, 2.5), Rect2(-14, -3.5, 4, 3)]:
		_rect(piece.grow(0.5), OUTLINE)
		_rect(piece, tint.darkened(0.08))
		_rect(Rect2(piece.position, Vector2(piece.size.x, 1)), tint.lightened(0.15))


static func _hash(x: int, y: int, salt: int) -> int:
	var h := (x * 73856093) ^ (y * 19349663) ^ (salt * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	return absi(h ^ (h >> 16))
