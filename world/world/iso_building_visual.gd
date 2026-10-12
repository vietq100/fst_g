@tool
class_name IsoBuildingVisual
extends Node2D
## Isometric placeholder building (BUILDING_DESIGN.md, D27): footprint diamond, two lit wall faces,
## pyramid roof, one marker per building type; Lv2 adds a stone base and a banner.
## Origin = the footprint's bottom (front) corner, so y-sorting with actors works.
## `ghost` draws a translucent placement preview tinted green (valid) or red.

const OUTLINE := Color("16161c")
const SHADOW := Color(0, 0, 0, 0.28)
const SELECTION := Color("f2d16b")
const WINDOW := Color("f5b453")
const STONE := Color("8a8a84")
const BANNER := Color("a83a3a")
const LABEL := Color("f4f1ea")
const VALID := Color(0.4, 1.0, 0.45, 0.45)
const INVALID := Color(1.0, 0.35, 0.3, 0.45)

const STYLES := {
	&"town_hall": {"wall": Color("cdbf9f"), "roof": Color("3c5a8c"), "trim": Color("e2c46b"), "height": 58.0},
	&"tavern": {"wall": Color("8b5e3c"), "roof": Color("7a3b2e"), "trim": Color("e2a64b"), "height": 40.0},
	&"blacksmith": {"wall": Color("5d5a55"), "roof": Color("3f4247"), "trim": Color("ff8a3d"), "height": 38.0},
	&"hospital": {"wall": Color("e6e1d6"), "roof": Color("3f8a83"), "trim": Color("c94a4a"), "height": 40.0},
	&"warehouse": {"wall": Color("7d6448"), "roof": Color("5b4430"), "trim": Color("b08d57"), "height": 36.0},
	&"house": {"wall": Color("b48a62"), "roof": Color("8a4b3a"), "trim": Color("e8d3a8"), "height": 32.0},
	&"temple": {"wall": Color("d8d2c2"), "roof": Color("b8913a"), "trim": Color("f2d16b"), "height": 46.0},
	&"trading_post": {"wall": Color("a67c52"), "roof": Color("2f6f5e"), "trim": Color("f2d16b"), "height": 34.0},
	&"restaurant": {"wall": Color("c27a4a"), "roof": Color("a83a3a"), "trim": Color("f4f1ea"), "height": 36.0},
	&"inn": {"wall": Color("c9a37a"), "roof": Color("5b6c8f"), "trim": Color("f4f1ea"), "height": 42.0},
	&"academy": {"wall": Color("b9b4c9"), "roof": Color("5a3f8c"), "trim": Color("9fd6ff"), "height": 48.0},
	&"forge": {"wall": Color("4a4a50"), "roof": Color("8a3b24"), "trim": Color("ff7a2e"), "height": 36.0},
	&"portal": {"wall": Color("2e2a45"), "roof": Color("6a3fb8"), "trim": Color("c79bff"), "height": 30.0},
}

@export var building_id: StringName = &"house":
	set(value):
		building_id = value
		queue_redraw()
@export var footprint := Vector2i(2, 2):
	set(value):
		footprint = value
		queue_redraw()
@export var level := 1:
	set(value):
		level = value
		queue_redraw()
@export var title := "":
	set(value):
		title = value
		queue_redraw()

var selected := false:
	set(value):
		selected = value
		queue_redraw()
var ghost := false:
	set(value):
		ghost = value
		queue_redraw()
var ghost_valid := true:
	set(value):
		ghost_valid = value
		queue_redraw()


## Corners of the footprint relative to the origin (bottom corner): top, right, bottom, left.
func get_corners() -> PackedVector2Array:
	var w := float(footprint.x)
	var d := float(footprint.y)
	return PackedVector2Array([
		WorldService.tile_to_world(Vector2(-w, -d)),
		WorldService.tile_to_world(Vector2(0, -d)),
		Vector2.ZERO,
		WorldService.tile_to_world(Vector2(-w, 0)),
	])


func get_height() -> float:
	return _style()["height"] * (1.15 if level >= 2 else 1.0) + _roof_height()


func _roof_height() -> float:
	return 14.0 + footprint.x * 4.0


func _style() -> Dictionary:
	return STYLES.get(building_id, STYLES[&"house"])


func _draw() -> void:
	var style := _style()
	var corners := get_corners()
	var top := corners[0]
	var right := corners[1]
	var bottom := corners[2]
	var left := corners[3]
	var h: float = style["height"] * (1.15 if level >= 2 else 1.0)
	var up := Vector2(0, -h)
	var tint := Color(1, 1, 1, 0.55) if ghost else Color.WHITE
	if ghost:
		draw_colored_polygon(corners, VALID if ghost_valid else INVALID)
	else:
		draw_colored_polygon(_grow(corners, 4.0), SHADOW)
	if level >= 2 and not ghost:
		draw_colored_polygon(PackedVector2Array([left, bottom, bottom + Vector2(0, -6), left + Vector2(0, -6)]), STONE.darkened(0.2))
		draw_colored_polygon(PackedVector2Array([bottom, right, right + Vector2(0, -6), bottom + Vector2(0, -6)]), STONE)
	var wall: Color = style["wall"]
	var left_face := PackedVector2Array([left, bottom, bottom + up, left + up])
	var right_face := PackedVector2Array([bottom, right, right + up, bottom + up])
	draw_colored_polygon(left_face, wall.darkened(0.12) * tint)
	draw_colored_polygon(right_face, wall.lightened(0.05) * tint)
	# Masonry courses: thin lines parallel to the base on both wall faces.
	if not ghost:
		var rows := int(h / 7.0)
		for k in range(1, rows):
			var lift := up * (float(k) / rows)
			draw_line(left + lift, bottom + lift, wall.darkened(0.3) * tint, 1.0)
			draw_line(bottom + lift, right + lift, wall.darkened(0.22) * tint, 1.0)
	draw_polyline(PackedVector2Array([left, left + up, bottom + up, right + up, right, bottom, left]), OUTLINE, 1.0)
	draw_line(bottom, bottom + up, OUTLINE, 1.0)
	# Pyramid roof over the raised footprint.
	var apex := (top + bottom) * 0.5 + up + Vector2(0, -_roof_height())
	var roof: Color = style["roof"]
	var eave := 4.0
	var l := left + up + Vector2(-eave, 0)
	var b := bottom + up + Vector2(0, eave * 0.5)
	var r := right + up + Vector2(eave, 0)
	draw_colored_polygon(PackedVector2Array([l, b, apex]), roof.darkened(0.15) * tint)
	draw_colored_polygon(PackedVector2Array([b, r, apex]), roof * tint)
	# Shingle rows, then the outline.
	if not ghost:
		for t: float in [0.22, 0.44, 0.66, 0.85]:
			draw_line(l.lerp(apex, t), b.lerp(apex, t), roof.darkened(0.35), 1.0)
			draw_line(b.lerp(apex, t), r.lerp(apex, t), roof.darkened(0.25), 1.0)
		draw_line(l, b, roof.lightened(0.18), 2.0)
		draw_line(b, r, roof.lightened(0.25), 2.0)
	draw_polyline(PackedVector2Array([l, b, r, apex, l]), OUTLINE, 1.0)
	draw_line(b, apex, OUTLINE, 1.0)
	if not ghost:
		_draw_details(style, left, bottom, right, h, apex)
	if selected:
		draw_polyline(_grow(corners, 6.0) + PackedVector2Array([_grow(corners, 6.0)[0]]), SELECTION, 2.0)
	if not title.is_empty() and not ghost:
		var font := ThemeDB.fallback_font
		var text := "%s%s" % [title, "  Lv%d" % level if level > 1 else ""]
		var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
		var at := Vector2(apex.x - size.x * 0.5, apex.y - 6)
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, OUTLINE)
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, LABEL)


func _draw_details(style: Dictionary, left: Vector2, bottom: Vector2, right: Vector2, h: float, apex: Vector2) -> void:
	var trim: Color = style["trim"]
	# Door in the middle of the right (front-right) face, windows on the left face.
	var door_base := bottom.lerp(right, 0.5)
	var door := PackedVector2Array([door_base + Vector2(-6, 3), door_base + Vector2(6, -3), door_base + Vector2(6, -21), door_base + Vector2(-6, -15)])
	draw_colored_polygon(door, Color("3a2a1e"))
	draw_polyline(PackedVector2Array([door[0], door[3], door[2], door[1]]), style["trim"], 1.0)
	draw_circle(door_base + Vector2(3, -8), 1.0, Color("e8c547"))
	for t: float in [0.3, 0.7]:
		var spot := left.lerp(bottom, t) + Vector2(0, -h * 0.6)
		var pane := PackedVector2Array([spot + Vector2(-5, -2), spot + Vector2(5, 3), spot + Vector2(5, -6), spot + Vector2(-5, -11)])
		draw_colored_polygon(pane, WINDOW if building_id != &"hospital" else Color("bfe3ff"))
		draw_polyline(pane + PackedVector2Array([pane[0]]), OUTLINE, 1.0)
		draw_line((pane[0] + pane[3]) * 0.5, (pane[1] + pane[2]) * 0.5, OUTLINE, 1.0)
	var face_mid := left.lerp(bottom, 0.5) + Vector2(0, -h * 0.25)
	match building_id:
		&"town_hall":
			_draw_banner(apex)
			draw_line(left + Vector2(0, -h + 4), bottom + Vector2(0, -h + 4), trim, 3.0)
		&"tavern":
			draw_rect(Rect2(face_mid + Vector2(-8, -24), Vector2(16, 12)), OUTLINE)
			draw_rect(Rect2(face_mid + Vector2(-7, -23), Vector2(14, 10)), trim)
			draw_rect(Rect2(face_mid + Vector2(-3, -21), Vector2(5, 7)), Color("f4f1ea"))
		&"blacksmith":
			var chimney := apex + Vector2(10, 6)
			draw_rect(Rect2(chimney + Vector2(-4, -16), Vector2(8, 18)), OUTLINE)
			draw_rect(Rect2(chimney + Vector2(-3, -15), Vector2(6, 16)), Color("4a4542"))
			draw_circle(right + Vector2(-6, -8), 8.0, Color(trim, 0.35))
			draw_rect(Rect2(right + Vector2(-12, -14), Vector2(10, 9)), trim)
		&"hospital":
			var cross := face_mid + Vector2(0, -18)
			draw_rect(Rect2(cross - Vector2(7, 2.5), Vector2(14, 5)), trim)
			draw_rect(Rect2(cross - Vector2(2.5, 7), Vector2(5, 14)), trim)
		&"warehouse":
			for offset: Vector2 in [Vector2(-12, -4), Vector2(-4, -10)]:
				draw_rect(Rect2(left + Vector2(4, 0) + offset, Vector2(10, 10)), OUTLINE)
				draw_rect(Rect2(left + Vector2(5, 1) + offset, Vector2(8, 8)), trim)
		&"house":
			draw_line(apex, apex + Vector2(0, -6), OUTLINE, 2.0)
		&"trading_post":
			draw_rect(Rect2(face_mid + Vector2(-9, -22), Vector2(18, 10)), OUTLINE)
			draw_rect(Rect2(face_mid + Vector2(-8, -21), Vector2(16, 8)), trim)
			draw_circle(face_mid + Vector2(0, -17), 2.5, OUTLINE)
		&"restaurant":
			draw_circle(face_mid + Vector2(0, -16), 7.0, OUTLINE)
			draw_circle(face_mid + Vector2(0, -16), 6.0, trim)
			draw_line(apex, apex + Vector2(0, -6), OUTLINE, 2.0)
		&"inn":
			draw_rect(Rect2(face_mid + Vector2(-6, -22), Vector2(12, 8)), OUTLINE)
			draw_rect(Rect2(face_mid + Vector2(-5, -21), Vector2(10, 6)), trim)
			draw_line(apex, apex + Vector2(0, -6), OUTLINE, 2.0)
		&"academy":
			_draw_banner(apex)
			for t: float in [0.3, 0.5, 0.7]:
				var column := left.lerp(bottom, t)
				draw_line(column, column + Vector2(0, -h + 4), Color(1, 1, 1, 0.45), 2.0)
		&"forge":
			var chimney_pos := apex + Vector2(8, 6)
			draw_rect(Rect2(chimney_pos + Vector2(-4, -16), Vector2(8, 18)), OUTLINE)
			draw_rect(Rect2(chimney_pos + Vector2(-3, -15), Vector2(6, 16)), Color("4a4542"))
			draw_circle(right + Vector2(-6, -8), 7.0, Color(trim, 0.5))
		&"portal":
			var ring := right.lerp(bottom, 0.5) + Vector2(0, -h - 6)
			draw_circle(ring, 11.0, OUTLINE)
			draw_circle(ring, 9.0, trim)
			draw_circle(ring, 5.0, Color("120d24"))
		&"temple":
			# Spire with a golden sun.
			draw_line(apex, apex + Vector2(0, -14), OUTLINE, 3.0)
			draw_circle(apex + Vector2(0, -18), 5.0, OUTLINE)
			draw_circle(apex + Vector2(0, -18), 4.0, trim)
			for t: float in [0.25, 0.5, 0.75]:
				var column := left.lerp(bottom, t)
				draw_line(column, column + Vector2(0, -h + 4), Color(1, 1, 1, 0.5), 2.0)
	if level >= 2 and building_id != &"town_hall":
		_draw_banner(right + Vector2(0, -h))


func _draw_banner(at: Vector2) -> void:
	draw_line(at, at + Vector2(0, -16), OUTLINE, 2.0)
	draw_colored_polygon(PackedVector2Array([at + Vector2(1, -16), at + Vector2(12, -13), at + Vector2(1, -9)]), BANNER)


static func _grow(points: PackedVector2Array, amount: float) -> PackedVector2Array:
	var grown := Geometry2D.offset_polygon(points, amount)
	return grown[0] if not grown.is_empty() else points
