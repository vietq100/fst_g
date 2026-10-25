class_name SummonColumn
extends Node2D
## Summoning light at the Summoning Circle (D83): a magnificent column of astral light that climbs
## step by step through the tier colours (Normal -> Superior -> Rare -> Heroic -> Legendary -> Mythic)
## up to the newcomer's tier, holds at peak glory, then lets the Hunter drop down through the beam.
## Origin at the circle's centre.

signal peaked

const STEP := 0.35       # Time spent climbing each tier
const PEAK_HOLD := 0.35  # Time to hold at the hunter's tier before hunter drops
const HEIGHT := 200.0    # Tall pillar shooting into the sky
const HALF_WIDTH := 24.0 # Pillar core half-width

var _target_tier := 0
var _current_tier := 0
var _time := 0.0
var _step_timer := 0.0
var _peaked := false
var _peaked_emitted := false
var _peak_hold_timer := 0.0
var _impacted := false
var _fade := 0.0

var _rings: Array[Dictionary] = []       # {y, spd, col}
var _sparks: Array[Dictionary] = []      # {pos, vel, col, life, max_l, size}
var _shockwaves: Array[Dictionary] = []  # {r, max_r, col, w}
var _title_alpha: float = 0.0
var _title_scale: float = 0.7


func setup(tier: int) -> void:
	_target_tier = Tier.clamp_level(tier)
	_current_tier = 0
	_time = 0.0
	_step_timer = 0.0
	_peaked = false
	_peaked_emitted = false
	_peak_hold_timer = 0.0
	_impacted = false
	_fade = 0.0
	z_index = 80
	# Initial charging flash
	var col := Tier.color(0)
	_rings.append({"y": 0.0, "spd": 360.0, "col": col})
	_shockwaves.append({"r": 6.0, "max_r": 34.0, "col": col, "w": 2.5})


func impact() -> void:
	_impacted = true
	var col := Tier.color(_target_tier)
	# Trigger ground impact shockwave and radial burst
	_shockwaves.append({"r": 6.0, "max_r": 60.0, "col": col, "w": 4.5})
	_shockwaves.append({"r": 4.0, "max_r": 75.0, "col": Color.WHITE, "w": 3.0})
	for i in 28:
		var ang := randf() * TAU
		var spd := randf_range(60.0, 180.0)
		_sparks.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(ang) * spd, sin(ang) * spd * 0.45 - 25.0),
			"col": col if randf() > 0.3 else Color.WHITE,
			"life": 0.0, "max_l": randf_range(0.35, 0.65), "size": randf_range(2.0, 4.5)
		})


func _process(delta: float) -> void:
	_time += delta

	if not _peaked:
		if _current_tier < _target_tier:
			_step_timer += delta
			if _step_timer >= STEP:
				_step_timer = 0.0
				_current_tier += 1
				var col := Tier.color(_current_tier)
				# Ring traveling up the column
				_rings.append({"y": 0.0, "spd": 380.0, "col": col})
				# Ground flash ring
				_shockwaves.append({"r": 8.0, "max_r": 42.0, "col": col, "w": 3.0})
				# Sparks burst
				for i in 8:
					var ang := randf() * TAU
					var spd := randf_range(40.0, 90.0)
					_sparks.append({
						"pos": Vector2(randf_range(-12, 12), randf_range(-6, 6)),
						"vel": Vector2(cos(ang) * spd, sin(ang) * spd * 0.45 - 40.0),
						"col": col, "life": 0.0, "max_l": randf_range(0.35, 0.7), "size": randf_range(2.0, 3.8)
					})
				if _current_tier >= _target_tier:
					_peaked = true
					_title_alpha = 1.0
					_title_scale = 1.35
		else:
			# Target tier is 0 (Normal)
			_step_timer += delta
			if _step_timer >= 0.25:
				_peaked = true
				_title_alpha = 1.0
				_title_scale = 1.25
	else:
		if not _peaked_emitted:
			_peak_hold_timer += delta
			_title_scale = lerpf(_title_scale, 1.0, delta * 7.0)
			if _peak_hold_timer >= PEAK_HOLD:
				_peaked_emitted = true
				peaked.emit()
		else:
			if _impacted:
				_fade = clampf(_fade + delta * 2.2, 0.0, 1.0)
				_title_alpha = clampf(_title_alpha - delta * 3.0, 0.0, 1.0)
				if _fade >= 1.0:
					queue_free()
					return

	# Update upward traveling rings
	var active_rings: Array[Dictionary] = []
	for ring in _rings:
		var ring_y: float = float(ring["y"]) + float(ring["spd"]) * delta
		ring["y"] = ring_y
		if ring_y < HEIGHT:
			active_rings.append(ring)
	_rings = active_rings

	# Update sparks
	var active_sparks: Array[Dictionary] = []
	for spk in _sparks:
		var p_life: float = float(spk["life"]) + delta
		var p_max_l: float = float(spk["max_l"])
		spk["life"] = p_life
		if p_life < p_max_l:
			var pos: Vector2 = spk["pos"]
			var vel: Vector2 = spk["vel"]
			vel.y += 110.0 * delta # Gravity
			pos += vel * delta
			spk["pos"] = pos
			spk["vel"] = vel
			active_sparks.append(spk)
	_sparks = active_sparks

	# Update shockwaves
	var active_shockwaves: Array[Dictionary] = []
	for sw in _shockwaves:
		var sw_r: float = float(sw["r"])
		var sw_max_r: float = float(sw["max_r"])
		sw_r += (sw_max_r - sw_r) * delta * 11.0
		sw["r"] = sw_r
		if sw_r < sw_max_r - 1.5:
			active_shockwaves.append(sw)
	_shockwaves = active_shockwaves

	# Ambient rising runes/particles inside beam
	if randf() < 0.5 and _current_tier >= 0:
		var col := Tier.color(_current_tier)
		_sparks.append({
			"pos": Vector2(randf_range(-HALF_WIDTH * 0.7, HALF_WIDTH * 0.7), randf_range(-6, 2)),
			"vel": Vector2(randf_range(-12, 12), randf_range(-180, -90)),
			"col": col if randf() > 0.25 else Color.WHITE,
			"life": 0.0, "max_l": randf_range(0.4, 0.8), "size": randf_range(1.5, 3.5)
		})

	queue_redraw()


func _draw() -> void:
	if _current_tier < 0:
		return

	var color := Tier.color(_current_tier)
	var strength: float = (1.0 - _fade) * (0.65 + 0.35 * float(_current_tier + 1) / float(_target_tier + 1))
	var pulse: float = 0.88 + 0.12 * sin(_time * 16.0)
	var cur_w: float = (HALF_WIDTH + _current_tier * 3.0) * (1.15 if _peaked else 0.95)

	# 1. Ground Magic Energy Pool & Radial Rings (Isometric 2:1)
	draw_ellipse(Vector2.ZERO, (cur_w * 1.8) * pulse, (cur_w * 0.9) * pulse, Color(color, 0.30 * strength))
	draw_ellipse(Vector2.ZERO, cur_w * 1.25, cur_w * 0.62, Color(color, 0.48 * strength))
	draw_ellipse(Vector2.ZERO, cur_w * 0.5, cur_w * 0.25, Color.WHITE * (0.80 * strength))

	# 2. Outer Coronal Light Column (Aura chùm sáng rộng)
	var aura_col := Color(color, 0.22 * strength)
	draw_rect(Rect2(-cur_w * 1.6, -HEIGHT, cur_w * 3.2, HEIGHT), aura_col)

	# 3. Mid Light Pillar (Thân cột sáng chính)
	var mid_col := Color(color, 0.48 * strength)
	draw_rect(Rect2(-cur_w, -HEIGHT, cur_w * 2.0, HEIGHT), mid_col)

	# 4. Core Laser Beam (Lõi sáng trắng tinh khiết)
	var core_w: float = cur_w * 0.36
	draw_rect(Rect2(-core_w, -HEIGHT, core_w * 2.0, HEIGHT), Color(1, 1, 1, 0.88 * strength))

	# 5. Dual Energy Helix Spirals (Dải năng lượng xoắn ốc bọc quanh cột)
	var spiral_pts_1: PackedVector2Array = []
	var spiral_pts_2: PackedVector2Array = []
	var steps := 28
	for i in steps:
		var frac: float = float(i) / float(steps)
		var y: float = -frac * HEIGHT
		var ang: float = _time * 6.0 + frac * TAU * 3.0
		var x1: float = sin(ang) * cur_w * 0.9
		var x2: float = sin(ang + PI) * cur_w * 0.9
		spiral_pts_1.append(Vector2(x1, y))
		spiral_pts_2.append(Vector2(x2, y))
	draw_polyline(spiral_pts_1, Color(Color.WHITE, 0.50 * strength), 1.3)
	draw_polyline(spiral_pts_2, Color(color.lightened(0.35), 0.45 * strength), 1.3)

	# 6. Ascending Light Rings traveling up the beam
	for ring in _rings:
		var y: float = float(ring["y"])
		var r_frac: float = clampf(y / HEIGHT, 0.0, 1.0)
		var r_alpha: float = (1.0 - r_frac) * 0.75 * strength
		var r_col: Color = ring["col"]
		draw_ellipse(Vector2(0, -y), cur_w * 1.15, cur_w * 0.38, Color(r_col, r_alpha))

	# 7. Ground Shockwaves
	for sw in _shockwaves:
		var sw_r: float = float(sw["r"])
		var sw_max_r: float = float(sw["max_r"])
		var frac: float = sw_r / sw_max_r
		var alpha: float = (1.0 - frac) * 0.88 * strength
		var c: Color = sw["col"]
		draw_ellipse(Vector2.ZERO, sw_r, sw_r * 0.48, Color(c, alpha))

	# 8. Magic Sparks & Motes
	for p in _sparks:
		var p_life: float = float(p["life"])
		var p_max_l: float = float(p["max_l"])
		var p_pos: Vector2 = p["pos"]
		var p_size: float = float(p["size"])
		var frac: float = p_life / p_max_l
		var alpha: float = (1.0 - frac) * strength
		var c: Color = p["col"]
		draw_circle(p_pos, p_size * (1.0 - frac * 0.4), Color(c, alpha))

	# 9. Top Halo Flare
	draw_circle(Vector2(0, -HEIGHT), cur_w * 1.25 * pulse, Color(color, 0.38 * strength))
	draw_circle(Vector2(0, -HEIGHT), cur_w * 0.5, Color(1, 1, 1, 0.70 * strength))

	# 10. Floating Tier Title Banner at Peak
	if _title_alpha > 0.01:
		_draw_tier_title(color)


func _draw_tier_title(col: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	var font_size: int = int(14.0 * _title_scale)
	var text: String = "%s (%s)" % [Tier.name_of(_target_tier), Tier.code(_target_tier)]
	var at := Vector2(0, -HEIGHT * 0.55)
	var str_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos := at - str_size * 0.5 + Vector2(0, font.get_ascent(font_size))
	var alpha_col := Color(col, _title_alpha)
	var outline_col := Color(0, 0, 0, 0.85 * _title_alpha)
	draw_string_outline(font, text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, 4, outline_col)
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, alpha_col)
