class_name LootPopup
extends Node2D
## Small sparkle + floating "+N Item" text where loot dropped (VFX_DESIGN.md → Loot).
## Frees itself.

const DURATION := 1.2
const RISE := 18.0
const FONT_SIZE := 10
const OUTLINE := Color("16161c")
const SPARKLE_RAYS := 6

var _color := RarityColors.COMMON
var _sparkle := 0.0


## `delay` staggers several popups from the same kill.
func setup(text: String, color: Color, delay: float) -> void:
	_color = color
	z_index = 90
	modulate.a = 0.0
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", OUTLINE)
	label.add_theme_constant_override("outline_size", 4)
	add_child(label)
	label.position = Vector2(-label.get_minimum_size().x * 0.5, -label.get_minimum_size().y - 6.0)
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(self, ^"modulate:a", 1.0, 0.08)
	tween.set_parallel()
	tween.tween_property(self, ^"_sparkle", 1.0, DURATION * 0.5)
	tween.tween_property(label, ^"position:y", label.position.y - RISE, DURATION).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, ^"modulate:a", 0.0, DURATION * 0.3).set_delay(DURATION * 0.7)
	tween.chain().tween_callback(queue_free)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _sparkle <= 0.0 or _sparkle >= 1.0:
		return
	var inner := lerpf(2.0, 8.0, _sparkle)
	var outer := lerpf(4.0, 12.0, _sparkle)
	var color := Color(_color, 1.0 - _sparkle)
	for i in SPARKLE_RAYS:
		var direction := Vector2.RIGHT.rotated(TAU * i / SPARKLE_RAYS)
		draw_line(direction * inner, direction * outer, color, 1.0)
