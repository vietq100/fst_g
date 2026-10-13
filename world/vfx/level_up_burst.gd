class_name LevelUpBurst
extends Node2D
## Short golden ring + "LEVEL UP" text over an actor. Frees itself.

const DURATION := 0.9
const COLOR := Color("ffd23f")
const OUTLINE := Color("16161c")

var _progress := 0.0


func _ready() -> void:
	z_index = 50
	var label := Label.new()
	label.text = Loc.t("world.popup.level_up")
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", COLOR)
	label.add_theme_color_override("font_outline_color", OUTLINE)
	label.add_theme_constant_override("outline_size", 4)
	add_child(label)
	label.position = Vector2(-label.get_minimum_size().x * 0.5, -54)
	var tween := create_tween().set_parallel()
	tween.tween_property(self, ^"_progress", 1.0, DURATION)
	tween.tween_property(label, ^"position:y", -66.0, DURATION)
	tween.tween_property(self, ^"modulate:a", 0.0, DURATION * 0.35).set_delay(DURATION * 0.65)
	tween.chain().tween_callback(queue_free)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var radius := lerpf(6.0, 22.0, _progress)
	draw_ellipse(Vector2(0, -2), radius, radius * 0.4, COLOR, false, 2.0)
