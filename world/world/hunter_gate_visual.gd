class_name HunterGateVisual
extends Node2D
## The Summoning Circle (D58, D83): an ancient arcane ritual circle on the Gate island.
## Only the magical summoning circle on a stepped stone dais — no gate arch.
## Origin at the circle's centre; tapping opens the Gate sheet.

const OUTLINE := Color("16161c")
const STONE_SHADOW := Color("0d0d12", 0.45)
const STONE_DEEP := Color("232729")
const STONE_DARK := Color("3d4345")
const STONE_MID := Color("616b6e")
const STONE_LIGHT := Color("8f9c9e")
const STONE_HIGHLIGHT := Color("c2cfd1")

const ASTRAL_CORE := Color("d8f8ff")
const ASTRAL_CYAN := Color("38bdf8")
const ASTRAL_DEEP := Color("0e2238")
const ASTRAL_VIOLET := Color("818cf8")
const GOLD := Color("f2c94c")
const GOLD_DARK := Color("9e7821")

const FLICKER_FPS := 16.0
const HALF_SPAN := 36.0 # Radius X of the outer stone dais
const HALF_Y := 18.0    # Radius Y (2:1 isometric ellipse)

var _time := 0.0
var _flicker_time := 0.0
var _flicker := 0
var _motes: Array[Vector3] = [] # x, y, speed


func _ready() -> void:
	Loc.locale_changed.connect(_on_locale_changed)
	add_to_group(DayNight.LIGHT_GROUP)
	set_meta(&"light_radius", 52.0)
	set_meta(&"light_offset", Vector2.ZERO)
	set_meta(&"light_color", Color("38bdf8"))
	# Initialize ambient floating starlight motes drifting up from the runes.
	for i in 12:
		_motes.append(Vector3(
			randf_range(-HALF_SPAN * 0.75, HALF_SPAN * 0.75),
			randf_range(-HALF_Y * 0.8, HALF_Y * 0.8),
			randf_range(14.0, 28.0)
		))


func _on_locale_changed(_locale: String) -> void:
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	_flicker_time += delta
	for i in _motes.size():
		var mote: Vector3 = _motes[i]
		mote.y -= mote.z * delta * 0.5
		if mote.y < -32.0:
			mote.y = randf_range(-HALF_Y * 0.4, HALF_Y * 0.8)
			mote.x = randf_range(-HALF_SPAN * 0.75, HALF_SPAN * 0.75)
		_motes[i] = mote
	if _flicker_time >= 1.0 / FLICKER_FPS:
		_flicker_time -= 1.0 / FLICKER_FPS
		_flicker += 1
		queue_redraw()


func hit_test(world_point: Vector2) -> bool:
	var delta := world_point - global_position
	# Elliptical hit-test covering the circular ritual platform.
	return (delta.x * delta.x) / ((HALF_SPAN + 6.0) * (HALF_SPAN + 6.0)) + \
		(delta.y * delta.y) / ((HALF_Y + 6.0) * (HALF_Y + 6.0)) <= 1.0


func _draw() -> void:
	var pulse := (sin(_time * 2.5) + 1.0) * 0.5
	var fast_pulse := (sin(_time * 5.0) + 1.0) * 0.5

	# 1. Ground Shadow (Bóng nền đất)
	draw_ellipse(Vector2(0, 4), HALF_SPAN + 8.0, HALF_Y + 4.0, STONE_SHADOW)

	# 2. Stepped Stone Dais (Bệ đá triệu hồi 2 tầng hình tròn đẳng cự)
	_draw_dais()

	# 3. Ancient Summoning Circle (Vòng tròn ma pháp triệu hồi phát sáng)
	_draw_summoning_circle(pulse, fast_pulse)

	# 4. Four Cardinal Leyline Focus Nodes (4 trụ ngọc cổ ngữ định vị Bắc Nam Đông Tây)
	_draw_focus_nodes(pulse)

	# 5. Rising Starlight Motes (Hạt sáng ma thuật bay lên)
	_draw_motes()

	# 6. Hovering Arcane Summon Sigil (Biểu tượng ma pháp bay lơ lửng phía trên)
	_draw_hovering_sigil(pulse)


## Stepped isometric stone platform embedded into the ground.
func _draw_dais() -> void:
	# Outer lower stone tier rim & depth
	draw_ellipse(Vector2(0, 3), HALF_SPAN + 2.0, HALF_Y + 1.0, STONE_DEEP)
	draw_ellipse(Vector2(0, 0), HALF_SPAN, HALF_Y, STONE_DARK)
	draw_ellipse(Vector2(0, -1), HALF_SPAN - 1.0, HALF_Y - 0.5, STONE_MID)

	# Carved stone quadrant seams
	for i in 4:
		var ang := i * TAU / 4.0 + PI * 0.25
		var p1 := Vector2(cos(ang) * (HALF_SPAN - 8.0), sin(ang) * (HALF_Y - 4.0))
		var p2 := Vector2(cos(ang) * HALF_SPAN, sin(ang) * HALF_Y)
		draw_line(p1, p2, STONE_DEEP, 1.0)

	# Inner raised stone step
	draw_ellipse(Vector2(0, -2), HALF_SPAN - 4.0, HALF_Y - 2.0, STONE_DEEP)
	draw_ellipse(Vector2(0, -3), HALF_SPAN - 5.0, HALF_Y - 2.5, STONE_MID)
	draw_ellipse(Vector2(0, -3.5), HALF_SPAN - 5.5, HALF_Y - 2.8, STONE_LIGHT.darkened(0.15))


## The glowing magical array: concentric rings, rotating runes, octagram, and core vortex.
func _draw_summoning_circle(pulse: float, fast_pulse: float) -> void:
	var cy := -3.5
	var r_outer_x := HALF_SPAN - 7.0
	var r_outer_y := HALF_Y - 3.5

	# Astral energy floor background
	draw_ellipse(Vector2(0, cy), r_outer_x, r_outer_y, Color(ASTRAL_DEEP, 0.75))

	# Outer glowing ring with radial tick marks
	var ring_col := Color(ASTRAL_CYAN, 0.45 + 0.25 * pulse)
	var glow_col := Color(ASTRAL_CORE, 0.6 + 0.3 * fast_pulse)
	draw_ellipse(Vector2(0, cy), r_outer_x, r_outer_y, Color(ASTRAL_CYAN, 0.12 * pulse))
	draw_arc(Vector2(0, cy), r_outer_x, 0, TAU, 36, ring_col, 1.2)

	# 12 Cardinal and Astrological boundary tick marks
	for i in 12:
		var ang := i * TAU / 12.0
		var p_in := Vector2(cos(ang) * (r_outer_x - 2.5), sin(ang) * (r_outer_y - 1.25) + cy)
		var p_out := Vector2(cos(ang) * (r_outer_x + 1.5), sin(ang) * (r_outer_y + 0.75) + cy)
		draw_line(p_in, p_out, ring_col, 1.0)

	# Rotating Middle Rune Band (8 ancient runes slowly orbiting)
	var r_rune_x := r_outer_x - 5.0
	var r_rune_y := r_outer_y - 2.5
	draw_arc(Vector2(0, cy), r_rune_x, 0, TAU, 32, Color(GOLD, 0.3 + 0.2 * pulse), 1.0)

	var rune_rot := _time * 0.35
	for i in 8:
		var ang := rune_rot + i * TAU / 8.0
		var pt := Vector2(cos(ang) * r_rune_x, sin(ang) * r_rune_y + cy)
		var p_tick := Vector2(cos(ang) * (r_rune_x - 2.0), sin(ang) * (r_rune_y - 1.0) + cy)
		draw_circle(pt, 1.6, glow_col)
		draw_line(pt, p_tick, Color(ASTRAL_CYAN, 0.7), 1.0)

	# Inner Geometric Sacred Star (8-pointed Octagram formed by 2 rotated squares)
	var r_star_x := r_rune_x - 4.5
	var r_star_y := r_rune_y - 2.2
	draw_arc(Vector2(0, cy), r_star_x, 0, TAU, 28, Color(ASTRAL_CYAN, 0.35), 1.0)

	for sq in 2:
		var offset := sq * PI * 0.25
		var pts: PackedVector2Array = []
		for v in 5:
			var ang := offset + v * PI * 0.5
			pts.append(Vector2(cos(ang) * r_star_x, sin(ang) * r_star_y + cy))
		draw_polyline(pts, Color(GOLD, 0.4 + 0.25 * pulse), 1.0)

	# Center Astral Core Pool & Vortex
	var r_core_x := 8.5
	var r_core_y := 4.2
	draw_ellipse(Vector2(0, cy), r_core_x + 2.0 * pulse, r_core_y + 1.0 * pulse, Color(ASTRAL_CYAN, 0.35 * pulse))
	draw_ellipse(Vector2(0, cy), r_core_x, r_core_y, Color(ASTRAL_CORE, 0.6 + 0.3 * fast_pulse))
	draw_ellipse(Vector2(0, cy), r_core_x * 0.5, r_core_y * 0.5, Color.WHITE)


## Four cardinal focus crystal stones holding leyline energy.
func _draw_focus_nodes(pulse: float) -> void:
	var cy := -3.5
	var nodes := [
		Vector2(0, -HALF_Y + 1.5),      # North
		Vector2(0, HALF_Y - 5.5),       # South
		Vector2(-HALF_SPAN + 2.5, cy),  # West
		Vector2(HALF_SPAN - 2.5, cy),   # East
	]
	for pt in nodes:
		# Stone socket
		draw_ellipse(pt + Vector2(0, 1), 3.5, 2.0, STONE_DEEP)
		draw_ellipse(pt, 3.0, 1.8, STONE_LIGHT)
		# Glowing Astral Gem
		var gem_col := Color(ASTRAL_CORE, 0.8 + 0.2 * pulse)
		draw_circle(pt + Vector2(0, -1), 1.6, gem_col)
		draw_circle(pt + Vector2(0, -1), 0.8, Color.WHITE)


## Ascending mystical starlight particles.
func _draw_motes() -> void:
	for mote in _motes:
		var life := clampf((-mote.y - 2.0) / 28.0, 0.0, 1.0)
		var a := (1.0 - life) * 0.75
		var col := Color(ASTRAL_CORE, a) if randf() > 0.3 else Color(GOLD, a)
		draw_circle(Vector2(mote.x, mote.y - 4.0), 1.2 * (1.0 - life * 0.5), col)


## Hovering arcane beacon sigil signaling the summon location to the player.
func _draw_hovering_sigil(pulse: float) -> void:
	var hover_y := -20.0 + sin(_time * 2.2) * 2.5
	var sigil_pos := Vector2(0, hover_y)

	# Soft glowing halo
	draw_circle(sigil_pos, 7.0 + 2.0 * pulse, Color(ASTRAL_CYAN, 0.2 * pulse))

	# Rotating diamond rune
	var rot := _time * 1.2
	var r := 4.5
	var pts := PackedVector2Array([
		sigil_pos + Vector2(cos(rot) * r, sin(rot) * r * 0.6),
		sigil_pos + Vector2(cos(rot + PI * 0.5) * r, sin(rot + PI * 0.5) * r * 0.6),
		sigil_pos + Vector2(cos(rot + PI) * r, sin(rot + PI) * r * 0.6),
		sigil_pos + Vector2(cos(rot + PI * 1.5) * r, sin(rot + PI * 1.5) * r * 0.6),
		sigil_pos + Vector2(cos(rot) * r, sin(rot) * r * 0.6),
	])
	draw_polyline(pts, Color(GOLD, 0.85), 1.2)
	draw_circle(sigil_pos, 1.4, Color.WHITE)
