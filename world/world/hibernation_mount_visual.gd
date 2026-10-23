class_name HibernationMountVisual
extends Node2D
## The Hibernation Mount (D83): a snow-capped rocky hill with a cave mouth where sleeping Hunters
## wait, below and left of the Hunter Gate (a bridge joins them). Origin at the base centre; tap
## opens the hibernation sheet. Drowsy "z"s drift up from the cave.

const OUTLINE := Color("16161c")
const ROCK := Color("6f7480")
const ROCK_DARK := Color("4b505a")
const ROCK_LIGHT := Color("8d93a0")
const SNOW := Color("eef2f6")
const SNOW_SHADE := Color("c7d2de")
const CAVE := Color("1a1c24")
const GLOW := Color(0.55, 0.7, 1.0, 0.25)
const Z_COLOR := Color("c9d8ff")
const DRIFT_FPS := 4.0
const HALF_SPAN := 44.0
const HEIGHT := 70.0

var _drift_time := 0.0
var _drift := 0


func _ready() -> void:
	Loc.locale_changed.connect(_on_locale_changed)


func _on_locale_changed(_locale: String) -> void:
	queue_redraw()


func _process(delta: float) -> void:
	_drift_time += delta
	if _drift_time >= 1.0 / DRIFT_FPS:
		_drift_time -= 1.0 / DRIFT_FPS
		_drift += 1
		queue_redraw()


func hit_test(world_point: Vector2) -> bool:
	return Rect2(global_position + Vector2(-HALF_SPAN - 8.0, -HEIGHT - 28.0), Vector2(HALF_SPAN * 2.0 + 16.0, HEIGHT + 40.0)).has_point(world_point)


func _draw() -> void:
	draw_ellipse(Vector2(0, 3), HALF_SPAN + 10.0, 13.0, Color(0, 0, 0, 0.3))
	# The hill: a jagged outline, lit left face, shaded right face.
	var peak := Vector2(-6, -HEIGHT)
	var hill := PackedVector2Array([Vector2(-HALF_SPAN, 0), Vector2(-HALF_SPAN + 8, -22), Vector2(-26, -38), Vector2(-16, -54),
		peak, Vector2(8, -58), Vector2(20, -44), Vector2(30, -30), Vector2(HALF_SPAN - 4, -14), Vector2(HALF_SPAN, 0)])
	draw_colored_polygon(BuildingVisual._grow(hill, 1.5), OUTLINE)
	draw_colored_polygon(hill, ROCK)
	var shade := PackedVector2Array([peak, Vector2(8, -58), Vector2(20, -44), Vector2(30, -30), Vector2(HALF_SPAN - 4, -14),
		Vector2(HALF_SPAN, 0), Vector2(0, 0)])
	draw_colored_polygon(shade, ROCK_DARK)
	draw_line(Vector2(-26, -38), Vector2(-10, -10), ROCK_LIGHT, 1.5)
	draw_line(Vector2(-16, -54), Vector2(-4, -30), ROCK_LIGHT, 1.0)
	draw_line(Vector2(20, -44), Vector2(28, -12), OUTLINE, 1.0)
	# Snow cap.
	var cap := PackedVector2Array([Vector2(-16, -54), peak, Vector2(8, -58), Vector2(14, -50), Vector2(6, -46), Vector2(-2, -50), Vector2(-10, -46)])
	draw_colored_polygon(cap, SNOW)
	draw_colored_polygon(PackedVector2Array([peak, Vector2(8, -58), Vector2(14, -50), Vector2(6, -46)]), SNOW_SHADE)
	# Cave mouth at the foot, with a faint cold glow.
	draw_circle(Vector2(2, -8), 16.0, GLOW)
	var mouth := PackedVector2Array([Vector2(-11, 0), Vector2(-11, -12), Vector2(-6, -20), Vector2(4, -22), Vector2(12, -16), Vector2(14, -8), Vector2(14, 0)])
	draw_colored_polygon(BuildingVisual._grow(mouth, 1.5), OUTLINE)
	draw_colored_polygon(mouth, CAVE)
	draw_line(Vector2(-11, 0), Vector2(14, 0), ROCK_DARK, 2.0)
	# Drowsy z's drifting up from the cave.
	var font := ThemeDB.fallback_font
	for i in 3:
		var t := fmod((_drift + i * 5) / 15.0, 1.0)
		var at := Vector2(6.0 + t * 10.0 + i * 3.0, -24.0 - t * 26.0)
		var size := 8 + i * 2
		draw_string_outline(font, at, "z", HORIZONTAL_ALIGNMENT_LEFT, -1, size, 2, Color(OUTLINE, 1.0 - t))
		draw_string(font, at, "z", HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(Z_COLOR, 1.0 - t))
	# Name plate.
	var text := Loc.t("world.mount.plaque")
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
	var plaque := Rect2(Vector2(-text_size.x * 0.5 - 4.0, -HEIGHT - 28.0 - text_size.y), Vector2(text_size.x + 8.0, text_size.y + 2.0))
	draw_rect(plaque, Color(0.06, 0.07, 0.1, 0.75))
	draw_rect(plaque, SNOW_SHADE, false, 1.0)
	var text_at := Vector2(-text_size.x * 0.5, plaque.position.y + font.get_ascent(10) + 1.0)
	draw_string_outline(font, text_at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 2, OUTLINE)
	draw_string(font, text_at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("f4f1ea"))
