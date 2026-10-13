class_name HunterGateVisual
extends Node2D
## The Hunter Gate (D58): a tall stone arch with banners and torches on the gate island where
## Hunters are hired and expelled. Origin at the base centre; tap opens the gate sheet.

const OUTLINE := Color("16161c")
const STONE := Color("8d8f8a")
const STONE_DARK := Color("5f625e")
const BANNER := Color("3c7a6a")
const BANNER_TRIM := Color("e2c46b")
const FLAME := Color("ffb347")
const GLOW := Color(0.5, 0.95, 0.85, 0.35)
const FLICKER_FPS := 8.0
const HALF_SPAN := 34.0
const HEIGHT := 64.0

var _flicker_time := 0.0
var _flicker := 0


func _ready() -> void:
	# The name plate is translated in _draw; redraw when the language changes.
	Loc.locale_changed.connect(_on_locale_changed)


func _on_locale_changed(_locale: String) -> void:
	queue_redraw()


func _process(delta: float) -> void:
	_flicker_time += delta
	if _flicker_time >= 1.0 / FLICKER_FPS:
		_flicker_time -= 1.0 / FLICKER_FPS
		_flicker += 1
		queue_redraw()


func hit_test(world_point: Vector2) -> bool:
	return Rect2(global_position + Vector2(-HALF_SPAN - 10.0, -HEIGHT - 30.0), Vector2(HALF_SPAN * 2.0 + 20.0, HEIGHT + 40.0)).has_point(world_point)


func _draw() -> void:
	# Lit floor circle and shadow.
	draw_ellipse(Vector2(0, 2), HALF_SPAN + 14.0, 12.0, Color(0, 0, 0, 0.3))
	draw_ellipse(Vector2(0, 0), HALF_SPAN + 6.0, 9.0, Color(GLOW, 0.18 + 0.03 * (_flicker % 3)))
	for side: float in [-1.0, 1.0]:
		_pillar(Vector2(side * HALF_SPAN, 0))
	# Lintel with a keystone and a crest.
	var beam := Rect2(Vector2(-HALF_SPAN - 8.0, -HEIGHT - 10.0), Vector2(HALF_SPAN * 2.0 + 16.0, 12.0))
	draw_rect(beam.grow(1.5), OUTLINE)
	draw_rect(beam, STONE)
	draw_rect(Rect2(beam.position, Vector2(beam.size.x, 3.0)), STONE.lightened(0.2))
	var blocks := int(beam.size.x / 12.0)
	for i in range(1, blocks):
		var x := beam.position.x + beam.size.x * i / blocks
		draw_line(Vector2(x, beam.position.y + 3.0), Vector2(x, beam.end.y), STONE_DARK, 1.0)
	var crest := Vector2(0, beam.position.y - 6.0)
	draw_colored_polygon(PackedVector2Array([crest + Vector2(-9, 6), crest + Vector2(0, -8), crest + Vector2(9, 6)]), OUTLINE)
	draw_colored_polygon(PackedVector2Array([crest + Vector2(-7, 5), crest + Vector2(0, -5), crest + Vector2(7, 5)]), BANNER_TRIM)
	draw_circle(crest + Vector2(0, 1), 2.2, OUTLINE)
	# Banners hanging from the lintel.
	for side: float in [-1.0, 1.0]:
		var top := Vector2(side * (HALF_SPAN - 12.0), beam.end.y)
		var flag := PackedVector2Array([top + Vector2(-6, 0), top + Vector2(6, 0), top + Vector2(6, 22), top + Vector2(0, 28), top + Vector2(-6, 22)])
		draw_colored_polygon(BuildingVisual._grow(flag, 1.0), OUTLINE)
		draw_colored_polygon(flag, BANNER)
		draw_line(top + Vector2(-5, 4), top + Vector2(5, 4), BANNER_TRIM, 1.5)
		draw_circle(top + Vector2(0, 14), 3.0, BANNER_TRIM)
	# Torches on both pillars.
	for side: float in [-1.0, 1.0]:
		var torch := Vector2(side * (HALF_SPAN + 9.0), -HEIGHT * 0.55)
		var wobble := float(posmod(_flicker + int(side) + 1, 3)) - 1.0
		draw_line(torch, torch + Vector2(0, 8), OUTLINE, 2.0)
		draw_circle(torch + Vector2(0, -2), 6.0 + wobble, Color(FLAME, 0.25 + wobble * 0.04))
		draw_circle(torch + Vector2(wobble * 0.5, -1), 2.5, FLAME)
		draw_circle(torch, 1.2, Color("fff2a8"))
	# Name plate.
	var font := ThemeDB.fallback_font
	var text := Loc.t("world.gate.plaque")
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
	var plaque := Rect2(Vector2(-size.x * 0.5 - 4.0, -HEIGHT - 30.0 - size.y), Vector2(size.x + 8.0, size.y + 2.0))
	draw_rect(plaque, Color(0.06, 0.07, 0.1, 0.75))
	draw_rect(plaque, BANNER_TRIM, false, 1.0)
	var at := Vector2(-size.x * 0.5, plaque.position.y + font.get_ascent(10) + 1.0)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 2, OUTLINE)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("f4f1ea"))


func _pillar(base: Vector2) -> void:
	var shaft := Rect2(base + Vector2(-7, -HEIGHT), Vector2(14, HEIGHT))
	draw_rect(shaft.grow(1.5), OUTLINE)
	draw_rect(shaft, STONE)
	draw_rect(Rect2(shaft.position, Vector2(4, shaft.size.y)), STONE.lightened(0.15))
	draw_rect(Rect2(Vector2(shaft.end.x - 4.0, shaft.position.y), Vector2(4, shaft.size.y)), STONE_DARK)
	for k in range(1, 7):
		var y := shaft.position.y + shaft.size.y * k / 7.0
		draw_line(Vector2(shaft.position.x, y), Vector2(shaft.end.x, y), STONE_DARK, 1.0)
	var foot := Rect2(base + Vector2(-10, -6), Vector2(20, 6))
	draw_rect(foot.grow(1.0), OUTLINE)
	draw_rect(foot, STONE_DARK)
