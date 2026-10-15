class_name BossAltarVisual
extends Node2D
## The Boss Arena's altar (D58): a dark obelisk on a stone plinth, chained, with a purple glow
## that pulses while the weekly boss is up and dies down while it is away. Origin at the base
## centre; tap opens the boss sheet.

const OUTLINE := Color("16161c")
const STONE := Color("4a4356")
const STONE_DARK := Color("2c2734")
const GLOW := Color("b07cff")
const CHAIN := Color("8a8f98")
const PULSE_FPS := 8.0

var _pulse_time := 0.0
var _pulse := 0


func _ready() -> void:
	# The name plate is translated in _draw; redraw when the language changes.
	Loc.locale_changed.connect(_on_locale_changed)


func _on_locale_changed(_locale: String) -> void:
	queue_redraw()


func _process(delta: float) -> void:
	_pulse_time += delta
	if _pulse_time >= 1.0 / PULSE_FPS:
		_pulse_time -= 1.0 / PULSE_FPS
		_pulse += 1
		queue_redraw()


func hit_test(world_point: Vector2) -> bool:
	return Rect2(global_position + Vector2(-30, -92), Vector2(60, 102)).has_point(world_point)


func _draw() -> void:
	var up := GameManager.weekly_boss != null and GameManager.weekly_boss.is_available()
	var pulse := (sin(_pulse * 0.6) + 1.0) * 0.5
	draw_ellipse(Vector2(2, 2), 30.0, 11.0, Color(0, 0, 0, 0.35))
	if up:
		draw_ellipse(Vector2.ZERO, 26.0 + pulse * 4.0, 9.0 + pulse * 1.5, Color(GLOW, 0.18 + pulse * 0.12))
	# Plinth: two stone steps.
	for step: Array in [[24.0, 8.0, 0.0], [17.0, 7.0, -8.0]]:
		var half: float = step[0]
		var h: float = step[1]
		var y: float = step[2]
		var slab := PackedVector2Array([Vector2(-half, y), Vector2(0, y + half * 0.4), Vector2(half, y), Vector2(0, y - half * 0.4)])
		var face := PackedVector2Array([Vector2(-half, y), Vector2(0, y + half * 0.4), Vector2(0, y + half * 0.4 + h), Vector2(-half, y + h)])
		var face_r := PackedVector2Array([Vector2(0, y + half * 0.4), Vector2(half, y), Vector2(half, y + h), Vector2(0, y + half * 0.4 + h)])
		draw_colored_polygon(BuildingVisual._grow(face, 1.0), OUTLINE)
		draw_colored_polygon(BuildingVisual._grow(face_r, 1.0), OUTLINE)
		draw_colored_polygon(face, STONE)
		draw_colored_polygon(face_r, STONE_DARK)
		draw_colored_polygon(BuildingVisual._grow(slab, 1.0), OUTLINE)
		draw_colored_polygon(slab, STONE.lightened(0.12))
	# Obelisk.
	var top := -78.0
	var body := PackedVector2Array([Vector2(-8, -14), Vector2(-5, top), Vector2(5, top), Vector2(8, -14)])
	draw_colored_polygon(BuildingVisual._grow(body, 1.5), OUTLINE)
	draw_colored_polygon(body, STONE)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -14), Vector2(0, top), Vector2(5, top), Vector2(8, -14)]), STONE_DARK)
	draw_colored_polygon(PackedVector2Array([Vector2(-6, top + 2), Vector2(0, top - 12), Vector2(6, top + 2)]), OUTLINE)
	draw_colored_polygon(PackedVector2Array([Vector2(-5, top + 2), Vector2(0, top - 10), Vector2(5, top + 2)]), GLOW if up else STONE_DARK)
	# Runes down the front, lit when the boss is up.
	var rune := Color(GLOW, 0.5 + pulse * 0.5) if up else Color(GLOW, 0.15)
	for k in 4:
		var y := -24.0 - k * 12.0
		draw_rect(Rect2(Vector2(-3.5, y - 3), Vector2(3, 3)), rune)
		draw_line(Vector2(-3.5, y + 1), Vector2(-0.5, y + 1), rune, 1.0)
	# Chains from the obelisk to the plinth corners.
	for side: float in [-1.0, 1.0]:
		var from := Vector2(side * 6.0, -40.0)
		var to := Vector2(side * 22.0, 2.0)
		draw_line(from, to, OUTLINE, 3.0)
		draw_line(from, to, CHAIN, 1.5)
		for t: float in [0.25, 0.5, 0.75]:
			draw_circle(from.lerp(to, t), 1.8, CHAIN.darkened(0.3))
	# Skull at the foot.
	draw_circle(Vector2(-14, -2), 3.5, OUTLINE)
	draw_circle(Vector2(-14, -2), 2.6, Color("e8e3d6"))
	draw_rect(Rect2(Vector2(-15.5, -3), Vector2(1, 1)), OUTLINE)
	draw_rect(Rect2(Vector2(-13.5, -3), Vector2(1, 1)), OUTLINE)
	# Name plate.
	var font := ThemeDB.fallback_font
	var text := Loc.t("world.boss.plaque") if up else Loc.t("world.boss.plaque_away")
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
	var plaque := Rect2(Vector2(-size.x * 0.5 - 4.0, top - 20.0 - size.y), Vector2(size.x + 8.0, size.y + 2.0))
	draw_rect(plaque, Color(0.06, 0.05, 0.1, 0.75))
	draw_rect(plaque, GLOW if up else Color("9aa3ad"), false, 1.0)
	var at := Vector2(-size.x * 0.5, plaque.position.y + font.get_ascent(10) + 1.0)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 2, OUTLINE)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("e4d6ff") if up else Color("9aa3ad"))
