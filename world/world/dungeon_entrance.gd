class_name DungeonEntrance
extends Node2D
## A dungeon entrance on a region edge (D35): dark doorway in a rough stone arch with torches, a
## swirling glow and a name plate. Locked entrances are greyed out and chained.

const OUTLINE := Color("16161c")
const STONE := Color("6d7068")
const GLOW := Color(0.55, 0.85, 1.0, 0.45)
const FLAME := Color("ffb347")
const PLAQUE := Color(0.06, 0.07, 0.1, 0.75)

const FLICKER_FPS := 8.0

var expedition_id: StringName
## The expedition name key (translated when drawn, so a language change shows on redraw).
var title := ""
var locked := false

var _flicker_time := 0.0
var _flicker := 0


func _ready() -> void:
	# The name plate is translated in _draw; redraw when the language changes.
	Loc.locale_changed.connect(_on_locale_changed)


func _on_locale_changed(_locale: String) -> void:
	queue_redraw()


func _process(delta: float) -> void:
	if locked:
		return
	_flicker_time += delta
	if _flicker_time >= 1.0 / FLICKER_FPS:
		_flicker_time -= 1.0 / FLICKER_FPS
		_flicker += 1
		queue_redraw()


func setup(definition: ExpeditionDefinition) -> void:
	expedition_id = definition.id
	title = definition.get_name_key()
	locked = definition.locked
	position = WorldService.tile_center(definition.entrance_tile)
	queue_redraw()


func hit_test(world_point: Vector2) -> bool:
	return Rect2(global_position + Vector2(-28, -52), Vector2(56, 60)).has_point(world_point)


func _draw() -> void:
	draw_ellipse(Vector2(2, 0), 30, 11, Color(0, 0, 0, 0.35))
	var stone := STONE.darkened(0.3) if locked else STONE
	var frame := PackedVector2Array([Vector2(-24, 0), Vector2(-24, -28), Vector2(-17, -40), Vector2(-6, -46), Vector2(6, -46),
		Vector2(17, -40), Vector2(24, -28), Vector2(24, 0)])
	# Right side of the arch receding up and to the right (oblique view, D54).
	var flank := PackedVector2Array([Vector2(24, 0), Vector2(24, -28), Vector2(17, -40), Vector2(6, -46), Vector2(13, -53), Vector2(24, -47),
		Vector2(31, -35), Vector2(31, -7)])
	draw_colored_polygon(BuildingVisual._grow(flank, 1.5), OUTLINE)
	draw_colored_polygon(flank, stone.darkened(0.35))
	draw_colored_polygon(BuildingVisual._grow(frame, 1.5), OUTLINE)
	draw_colored_polygon(frame, stone)
	# Arch blocks: lit left half, shaded right half, joints.
	draw_colored_polygon(PackedVector2Array([Vector2(16, 0), Vector2(16, -30), Vector2(6, -46), Vector2(17, -40), Vector2(24, -28), Vector2(24, 0)]), stone.darkened(0.2))
	draw_colored_polygon(PackedVector2Array([Vector2(-24, 0), Vector2(-24, -28), Vector2(-17, -40), Vector2(-14, -36), Vector2(-20, -26), Vector2(-20, 0)]), stone.lightened(0.12))
	for joint: Array in [[Vector2(-24, -14), Vector2(-14, -14)], [Vector2(14, -14), Vector2(24, -14)], [Vector2(-21, -33), Vector2(-12, -30)],
			[Vector2(21, -33), Vector2(12, -30)], [Vector2(-6, -46), Vector2(-5, -36)], [Vector2(6, -46), Vector2(5, -36)]]:
		draw_line(joint[0], joint[1], stone.darkened(0.4), 1.0)
	var door := PackedVector2Array([Vector2(-13, 0), Vector2(-13, -26), Vector2(-7, -34), Vector2(7, -34), Vector2(13, -26), Vector2(13, 0)])
	draw_colored_polygon(door, Color("0b0b10"))
	if not locked:
		# Swirling glow in the doorway and flickering torches.
		var pulse := sin(_flicker * 0.5) * 1.5
		draw_circle(Vector2(0, -14), 11.0 + pulse, Color(GLOW, 0.18))
		draw_circle(Vector2(0, -14), 7.0, GLOW)
		draw_arc(Vector2(0, -14), 4.0, _flicker * 0.4, _flicker * 0.4 + PI * 1.5, 10, Color(1, 1, 1, 0.6), 1.0)
		for side: float in [-1.0, 1.0]:
			var torch := Vector2(side * 29.0, -22)
			var wobble := float((_flicker + int(side) + 1) % 3) - 1.0
			draw_line(torch, torch + Vector2(0, 8), OUTLINE, 2.0)
			draw_circle(torch + Vector2(0, -2), 6.0 + wobble, Color(FLAME, 0.25 + wobble * 0.04))
			draw_circle(torch + Vector2(wobble * 0.5, -1), 2.5, FLAME)
			draw_circle(torch, 1.2, Color("fff2a8"))
	else:
		for chain: Array in [[Vector2(-12, -24), Vector2(12, -4)], [Vector2(12, -24), Vector2(-12, -4)]]:
			draw_line(chain[0], chain[1], OUTLINE, 4.0)
			draw_line(chain[0], chain[1], Color("8a8f98"), 2.0)
		draw_rect(Rect2(Vector2(-4, -17), Vector2(8, 7)), OUTLINE)
		draw_rect(Rect2(Vector2(-3, -16), Vector2(6, 5)), Color("b8892a"))
	var font := ThemeDB.fallback_font
	var name_text := tr(title)
	var text := Loc.t("world.entrance.locked", {"name": name_text}) if locked else name_text
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
	var plaque := Rect2(Vector2(-size.x * 0.5 - 4.0, -50.0 - size.y - 4.0), Vector2(size.x + 8.0, size.y + 2.0))
	draw_rect(plaque, PLAQUE)
	draw_rect(plaque, Color("9aa3ad") if locked else Color("6fb3d9"), false, 1.0)
	var at := Vector2(-size.x * 0.5, plaque.position.y + font.get_ascent(10) + 1.0)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 2, OUTLINE)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("9aa3ad") if locked else Color("bfe3ff"))
