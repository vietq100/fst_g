class_name CameraShake
extends Node
## Shakes the current Camera2D (its `offset`) for a moment, fading out; off in Settings → Display
## (SettingsStore.get_screen_shake). Presentation only; CombatFeedback owns one.

var _left := 0.0
var _time := 0.0
var _strength := 0.0


func _ready() -> void:
	set_process(false)


## Starts (or strengthens) a shake of `strength` px for `duration` s.
func shake(strength: float, duration: float) -> void:
	if not SettingsStore.get_screen_shake():
		return
	_strength = maxf(strength, _strength)
	_time = duration
	_left = duration
	set_process(true)


func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		set_process(false)
		return
	_left -= delta
	if _left <= 0.0:
		camera.offset = Vector2.ZERO
		_strength = 0.0
		set_process(false)
		return
	var amount := _strength * (_left / _time)
	camera.offset = Vector2(randf_range(-amount, amount), randf_range(-amount, amount) * 0.6)
