class_name ArrowStreak
extends Node2D
## A short arrow flying from a ranged attacker to its target (D45). Presentation only: damage was
## already resolved.

const DURATION := 0.14
const LENGTH := 10.0
const COLOR := Color("e9dcc0")

var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _time := 0.0


func setup(from: Vector2, to: Vector2) -> void:
	_from = from
	_to = to
	z_index = 90


func _process(delta: float) -> void:
	_time += delta
	if _time >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := clampf(_time / DURATION, 0.0, 1.0)
	var head := _from.lerp(_to, t)
	var direction := (_to - _from).normalized()
	draw_line(head - direction * LENGTH, head, Color(0, 0, 0, 0.5), 3.0)
	draw_line(head - direction * LENGTH, head, COLOR, 1.5)
