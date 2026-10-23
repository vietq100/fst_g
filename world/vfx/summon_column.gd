class_name SummonColumn
extends Node2D
## Summoning light at the Hunter Gate (D83): a column that brightens step by step through the
## tier colours up to the newcomer's tier (`peaked`), then fades. Origin at the circle's centre.

signal peaked

const STEP := 0.24
const HOLD := 0.2
const FADE := 0.5
const HEIGHT := 96.0
const HALF_WIDTH := 14.0

var _tier := 0
var _level := -1
var _time := 0.0
var _peaked := false
var _fade := 0.0


func setup(tier: int) -> void:
	_tier = Tier.clamp_level(tier)
	z_index = 60


func _process(delta: float) -> void:
	_time += delta
	if not _peaked:
		var level := mini(int(_time / STEP), _tier)
		if level != _level:
			_level = level
			if _level >= _tier:
				_peaked = true
				_time = 0.0
				peaked.emit()
	else:
		_fade = clampf((_time - HOLD) / FADE, 0.0, 1.0)
		if _fade >= 1.0:
			queue_free()
			return
	queue_redraw()


func _draw() -> void:
	if _level < 0:
		return
	var color := Tier.color(_level)
	var strength := (1.0 - _fade) * (0.55 + 0.45 * float(_level + 1) / float(_tier + 1))
	var pulse := 0.85 + 0.15 * sin(_time * 18.0)
	# Rings on the floor, the column, a bright core and a halo at the top.
	draw_ellipse(Vector2.ZERO, 30.0 * pulse, 12.0 * pulse, Color(color, 0.22 * strength))
	draw_ellipse(Vector2.ZERO, 18.0, 7.0, Color(color, 0.4 * strength))
	draw_rect(Rect2(Vector2(-HALF_WIDTH, -HEIGHT), Vector2(HALF_WIDTH * 2.0, HEIGHT)), Color(color, 0.18 * strength))
	draw_rect(Rect2(Vector2(-HALF_WIDTH * 0.5, -HEIGHT), Vector2(HALF_WIDTH, HEIGHT)), Color(color, 0.35 * strength))
	draw_rect(Rect2(Vector2(-2.0, -HEIGHT), Vector2(4.0, HEIGHT)), Color(1, 1, 1, 0.5 * strength))
	draw_circle(Vector2(0, -HEIGHT), 16.0 * pulse, Color(color, 0.25 * strength))
	# One spark per tier reached, climbing the column.
	for i in _level + 1:
		var t := fmod(_time * 1.5 + i * 0.37, 1.0)
		var x := sin((t + i) * TAU) * HALF_WIDTH * 0.8
		draw_circle(Vector2(x, -t * HEIGHT), 2.0, Color(Tier.color(i), (1.0 - t) * strength))
