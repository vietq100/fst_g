class_name SkillVfx
extends Node2D
## World-space effect of an active skill (D55, VFX_DESIGN.md), spawned by CombatFeedback on
## CombatService.skill_used and drawn by kind (ActiveSkillDefinition.vfx):
##   shockwave / earth  expanding ground ring with dust or rock chunks
##   arrows             nothing here (ArrowStreak nodes are spawned by CombatFeedback)
##   shadow             dark burst and crossed slash marks
##   bash               blue impact ring and stun stars
##   flame / frost / poison / holy / lightning / wind / blood / heal  elemental bursts
## Presentation only: damage was already resolved. Frees itself when done.

const COLORS := {
	&"shockwave": Color("ffd27a"), &"earth": Color("b08d57"), &"shadow": Color("8a5cff"), &"bash": Color("9fd6ff"),
	&"flame": Color("ff8a3d"), &"frost": Color("9fe3ff"), &"poison": Color("7fe07a"), &"holy": Color("fff2a8"),
	&"lightning": Color("c9e8ff"), &"wind": Color("d8f0e8"), &"blood": Color("e04a4a"), &"heal": Color("8fe39a"),
}
const DUST := Color(0.85, 0.8, 0.7, 0.8)
const DURATION := 0.45

var kind: StringName = &"shockwave"
var radius := 30.0
var _time := 0.0


## `at` = world position of the effect's centre; `reach` = the skill's radius in px (0 = single).
func setup(vfx_kind: StringName, at: Vector2, reach: float) -> void:
	kind = vfx_kind
	radius = maxf(reach, 16.0)
	global_position = at
	z_index = 90


func _process(delta: float) -> void:
	_time += delta
	if _time >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := clampf(_time / DURATION, 0.0, 1.0)
	var fade := 1.0 - t
	var color: Color = COLORS.get(kind, Color.WHITE)
	match kind:
		&"shockwave", &"earth":
			var r := 8.0 + t * radius
			draw_ellipse(Vector2.ZERO, r, r * 0.45, Color(color, 0.85 * fade), false, 3.0)
			draw_ellipse(Vector2.ZERO, r * 0.7, r * 0.32, Color(color, 0.35 * fade), false, 1.5)
			draw_ellipse(Vector2.ZERO, r * 0.4, r * 0.18, Color(1, 1, 1, 0.5 * fade))
			for i in 8:
				var direction := Vector2.RIGHT.rotated(i * TAU / 8.0 + 0.3) * Vector2(1.0, 0.45)
				var chunk := direction * r * 0.9 + Vector2(0, -t * 10.0 + t * t * 14.0)
				draw_circle(chunk, (2.0 if kind == &"shockwave" else 3.0) * fade, Color(DUST if kind == &"shockwave" else color, 0.8 * fade))
		&"shadow":
			var r := 6.0 + t * 14.0
			draw_circle(Vector2(0, -14), r, Color(color, 0.35 * fade))
			for flip: float in [-1.0, 1.0]:
				var a := Vector2(-12, -14 + flip * -10.0)
				var b := Vector2(12, -14 + flip * 10.0)
				draw_line(a.lerp(b, t * 0.3), a.lerp(b, 0.3 + t * 0.7), Color(color.lightened(0.5), 0.95 * fade), 2.0)
			for i in 6:
				var direction := Vector2.RIGHT.rotated(i * TAU / 6.0 + t * 2.0)
				draw_circle(Vector2(0, -14) + direction * (10.0 + t * 12.0), 1.5 * fade, Color(color, 0.8 * fade))
		&"bash":
			var r := 6.0 + t * radius
			draw_ellipse(Vector2(0, -4), r, r * 0.5, Color(color, 0.8 * fade), false, 2.5)
			for i in 3:
				var angle := t * 6.0 + i * TAU / 3.0
				var star := Vector2(cos(angle) * 10.0, -30.0 + sin(angle) * 3.0)
				draw_line(star + Vector2(-2, 0), star + Vector2(2, 0), Color("fff2a8", 0.95 * fade), 1.5)
				draw_line(star + Vector2(0, -2), star + Vector2(0, 2), Color("fff2a8", 0.95 * fade), 1.5)
		&"flame":
			for i in 7:
				var x := (i - 3) * 4.0 + sin(t * 8.0 + i) * 2.0
				var height := (10.0 + (i % 3) * 5.0) * (1.0 - t * 0.5)
				draw_colored_polygon(PackedVector2Array([Vector2(x - 3, -6), Vector2(x + 3, -6), Vector2(x, -6 - height - t * 10.0)]), Color(color, 0.8 * fade))
				draw_colored_polygon(PackedVector2Array([Vector2(x - 1.5, -6), Vector2(x + 1.5, -6), Vector2(x, -6 - height * 0.6)]), Color("fff2a8", 0.8 * fade))
			draw_ellipse(Vector2(0, -4), 14.0 + t * radius * 0.5, 5.0, Color(color, 0.3 * fade), false, 2.0)
		&"frost":
			for i in 6:
				var direction := Vector2.RIGHT.rotated(i * TAU / 6.0 + 0.2)
				var tip := Vector2(0, -14) + direction * (6.0 + t * 16.0)
				draw_line(Vector2(0, -14) + direction * 3.0, tip, Color(color, 0.9 * fade), 2.0)
				draw_line(tip - direction.rotated(0.6) * 4.0, tip, Color(1, 1, 1, 0.8 * fade), 1.0)
				draw_line(tip - direction.rotated(-0.6) * 4.0, tip, Color(1, 1, 1, 0.8 * fade), 1.0)
			draw_ellipse(Vector2.ZERO, 10.0 + t * radius * 0.6, 4.0 + t * radius * 0.25, Color(color, 0.4 * fade), false, 1.5)
		&"poison":
			for i in 7:
				var angle := i * TAU / 7.0 + t * 1.5
				var bubble := Vector2(cos(angle) * (8.0 + t * radius * 0.5), -10.0 + sin(angle) * 4.0 - t * 14.0)
				draw_circle(bubble, 3.0 + (i % 2) * 1.5, Color(color, 0.55 * fade))
				draw_circle(bubble + Vector2(-1, -1), 1.0, Color(1, 1, 1, 0.5 * fade))
			draw_ellipse(Vector2.ZERO, 12.0 + t * radius * 0.6, 5.0, Color(color, 0.25 * fade))
		&"holy":
			for i in 6:
				var x := (i - 2.5) * 6.0
				draw_line(Vector2(x, -4), Vector2(x, -4 - 30.0 * minf(t * 2.0, 1.0)), Color(color, 0.7 * fade), 2.0)
			draw_circle(Vector2(0, -16), 6.0 + t * 10.0, Color(color, 0.5 * fade))
			draw_circle(Vector2(0, -16), 3.0 + t * 4.0, Color(1, 1, 1, 0.7 * fade))
			draw_ellipse(Vector2.ZERO, 10.0 + t * radius * 0.6, 4.0 + t * radius * 0.2, Color(color, 0.5 * fade), false, 2.0)
		&"lightning":
			var seed_value := int(_time * 60.0)
			for i in 3:
				var points := PackedVector2Array([Vector2((i - 1) * 8.0, -48)])
				for k in range(1, 6):
					var jitter := float(((seed_value + i * 7 + k * 13) * 2654435761) % 11) - 5.0
					points.append(Vector2((i - 1) * 8.0 + jitter, -48 + k * 8.0))
				draw_polyline(points, Color(color, 0.95 * fade), 2.0)
				draw_polyline(points, Color(1, 1, 1, 0.8 * fade), 1.0)
			draw_ellipse(Vector2.ZERO, 8.0 + t * radius * 0.5, 3.5 + t * radius * 0.2, Color(color, 0.5 * fade), false, 1.5)
		&"wind":
			for i in 3:
				var r := 8.0 + i * 6.0 + t * radius * 0.6
				draw_arc(Vector2(0, -10), r, t * 5.0 + i * 2.0, t * 5.0 + i * 2.0 + PI * 1.2, 12, Color(color, 0.7 * fade), 1.5)
			for i in 5:
				var leaf := Vector2.RIGHT.rotated(t * 7.0 + i * TAU / 5.0) * (10.0 + t * 20.0) + Vector2(0, -12)
				draw_ellipse(leaf, 2.0, 1.0, Color("6fbf5f", 0.8 * fade))
		&"blood":
			for i in 8:
				var direction := Vector2.RIGHT.rotated(i * TAU / 8.0 + 0.5)
				var drop := Vector2(0, -14) + direction * (4.0 + t * 18.0) + Vector2(0, t * t * 16.0)
				draw_circle(drop, 2.0 * fade + 0.5, Color(color, 0.9 * fade))
			for flip: float in [-1.0, 1.0]:
				draw_line(Vector2(-10, -14 - flip * 8.0), Vector2(10, -14 + flip * 8.0), Color(color.lightened(0.3), 0.9 * fade), 2.0)
		&"heal":
			for i in 5:
				var x := (i - 2) * 7.0
				var y := -6.0 - fmod(t * 30.0 + i * 7.0, 28.0)
				draw_line(Vector2(x - 2, y), Vector2(x + 2, y), Color(color, 0.9 * fade), 2.0)
				draw_line(Vector2(x, y - 2), Vector2(x, y + 2), Color(color, 0.9 * fade), 2.0)
			draw_ellipse(Vector2.ZERO, 12.0 + t * 8.0, 5.0 + t * 3.0, Color(color, 0.4 * fade), false, 1.5)
		_:
			draw_circle(Vector2(0, -12), 6.0 + t * 10.0, Color(1, 1, 1, 0.5 * fade))
