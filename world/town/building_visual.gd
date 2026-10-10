@tool
class_name BuildingVisual
extends Node2D
## Placeholder building art (BUILDING_DESIGN.md, TOWN_DESIGN.md §4): shared roof style,
## outline and perspective, one marker per building. Level 2 adds a stone foundation, more
## height and a banner (one visible upgrade change, TOWN_DESIGN.md §6). Origin = front wall base.

enum Kind { TOWN_HALL, TAVERN, BLACKSMITH, HOSPITAL, WAREHOUSE }

const OUTLINE := Color("16161c")
const SHADOW := Color(0, 0, 0, 0.3)
const SELECTION := Color("f2d16b")
const WINDOW_WARM := Color("f5b453")
const STONE := Color("8a8a84")
const BANNER := Color("a83a3a")
const LABEL := Color("f4f1ea")

@export var kind: Kind = Kind.TAVERN:
	set(value):
		kind = value
		queue_redraw()
@export var width := 96.0:
	set(value):
		width = value
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


func get_height() -> float:
	return _wall_height() + _roof_height()


func _wall_height() -> float:
	var base := 64.0 if kind == Kind.TOWN_HALL else 46.0
	return base * (1.15 if level >= 2 else 1.0)


func _roof_height() -> float:
	return 30.0 if kind == Kind.TOWN_HALL else 24.0


func _palette() -> Dictionary:
	match kind:
		Kind.TOWN_HALL:
			return {"wall": Color("cdbf9f"), "roof": Color("3c5a8c"), "trim": Color("e2c46b")}
		Kind.TAVERN:
			return {"wall": Color("8b5e3c"), "roof": Color("7a3b2e"), "trim": Color("e2a64b")}
		Kind.BLACKSMITH:
			return {"wall": Color("5d5a55"), "roof": Color("3f4247"), "trim": Color("ff8a3d")}
		Kind.HOSPITAL:
			return {"wall": Color("e6e1d6"), "roof": Color("3f8a83"), "trim": Color("c94a4a")}
	return {"wall": Color("7d6448"), "roof": Color("5b4430"), "trim": Color("b08d57")}


func _draw() -> void:
	var colors := _palette()
	var half := width * 0.5
	var wall_h := _wall_height()
	var roof_h := _roof_height()
	draw_rect(Rect2(-half - 4, -6, width + 8, 10), SHADOW)
	if level >= 2:
		draw_rect(Rect2(-half - 2, -8, width + 4, 8).grow(1.0), OUTLINE)
		draw_rect(Rect2(-half - 2, -8, width + 4, 8), STONE)
	# Walls.
	var walls := Rect2(-half, -wall_h, width, wall_h - (8.0 if level >= 2 else 0.0))
	draw_rect(walls.grow(1.0), OUTLINE)
	draw_rect(walls, colors["wall"])
	# Roof: trapezoid with overhang.
	var roof := PackedVector2Array([
		Vector2(-half - 6, -wall_h), Vector2(half + 6, -wall_h),
		Vector2(half - 10, -wall_h - roof_h), Vector2(-half + 10, -wall_h - roof_h),
	])
	draw_colored_polygon(_grow_polygon(roof), OUTLINE)
	draw_colored_polygon(roof, colors["roof"])
	draw_line(Vector2(-half - 6, -wall_h), Vector2(half + 6, -wall_h), colors["roof"].darkened(0.3), 2.0)
	# Door.
	var door_w := 22.0 if kind == Kind.WAREHOUSE else 14.0
	var door := Rect2(-door_w * 0.5, -22 - (8.0 if level >= 2 else 0.0), door_w, 22)
	draw_rect(door.grow(1.0), OUTLINE)
	draw_rect(door, Color("3a2a1e"))
	# Windows.
	for x in [-half + 12.0, half - 24.0]:
		var window := Rect2(x, -wall_h + 12, 12, 10)
		draw_rect(window.grow(1.0), OUTLINE)
		draw_rect(window, WINDOW_WARM if kind != Kind.HOSPITAL else Color("bfe3ff"))
	_draw_marker(colors, half, wall_h, roof_h)
	if level >= 2:
		_draw_banner(Vector2(half - 4, -wall_h - roof_h + 6))
	if selected:
		draw_rect(Rect2(-half - 8, -wall_h - roof_h - 4, width + 16, wall_h + roof_h + 10), SELECTION, false, 1.0)
	if not title.is_empty():
		var font := ThemeDB.fallback_font
		var text := "%s%s" % [title, "  Lv%d" % level if level > 1 else ""]
		var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
		var at := Vector2(-size.x * 0.5, -wall_h - roof_h - 6)
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, OUTLINE)
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, LABEL)


func _draw_marker(colors: Dictionary, half: float, wall_h: float, roof_h: float) -> void:
	var trim: Color = colors["trim"]
	match kind:
		Kind.TOWN_HALL:
			# Pediment and a flag on the roof: the town's landmark.
			_draw_banner(Vector2(0, -wall_h - roof_h))
			draw_rect(Rect2(-half + 6, -wall_h + 2, width - 12, 4), trim)
		Kind.TAVERN:
			# Hanging sign with a mug.
			draw_line(Vector2(-half + 4, -30), Vector2(-half - 8, -30), OUTLINE, 2.0)
			var sign_board := Rect2(-half - 18, -30, 16, 14)
			draw_rect(sign_board.grow(1.0), OUTLINE)
			draw_rect(sign_board, trim)
			draw_rect(Rect2(sign_board.position + Vector2(5, 3), Vector2(6, 8)), Color("f4f1ea"))
		Kind.BLACKSMITH:
			# Chimney and forge glow.
			var chimney := Rect2(half - 22, -wall_h - roof_h - 8, 10, roof_h + 4)
			draw_rect(chimney.grow(1.0), OUTLINE)
			draw_rect(chimney, Color("4a4542"))
			draw_circle(Vector2(half + 10, -10), 9.0, Color(trim, 0.35))
			draw_rect(Rect2(half + 4, -16, 12, 10).grow(1.0), OUTLINE)
			draw_rect(Rect2(half + 4, -16, 12, 10), trim)
		Kind.HOSPITAL:
			# Healing cross on the wall.
			var center := Vector2(0, -wall_h + 14)
			draw_rect(Rect2(center - Vector2(7, 2.5), Vector2(14, 5)), trim)
			draw_rect(Rect2(center - Vector2(2.5, 7), Vector2(5, 14)), trim)
		Kind.WAREHOUSE:
			# Crates beside the reinforced door.
			for crate in [Rect2(half + 2, -12, 12, 12), Rect2(half + 4, -22, 10, 10), Rect2(-half - 14, -12, 12, 12)]:
				draw_rect(crate.grow(1.0), OUTLINE)
				draw_rect(crate, trim)
			draw_line(Vector2(-11, -11), Vector2(11, -11), Color("8a8a84"), 2.0)


func _draw_banner(at: Vector2) -> void:
	draw_line(at, at + Vector2(0, -16), OUTLINE, 2.0)
	var flag := PackedVector2Array([at + Vector2(1, -16), at + Vector2(12, -13), at + Vector2(1, -9)])
	draw_colored_polygon(flag, BANNER)


func _grow_polygon(points: PackedVector2Array) -> PackedVector2Array:
	var grown := Geometry2D.offset_polygon(points, 1.0)
	return grown[0] if not grown.is_empty() else points
