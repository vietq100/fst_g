class_name DamageNumber
extends Node2D
## Floating damage number (VFX_DESIGN.md → Combat). Rises, fades and frees itself.

const RISE := 14.0
const DURATION := 0.7
const FONT_SIZE := 12
const CRITICAL_FONT_SIZE := 15
const COLOR := Color("f4f1ea")
const CRITICAL_COLOR := Color("ffd23f")
const HUNTER_HURT_COLOR := Color("ff7a6b")
const OUTLINE := Color("16161c")


## `hurt_hunter` uses a red tint so the player can tell incoming from outgoing damage.
func setup(amount: float, is_critical: bool, hurt_hunter: bool) -> void:
	var color := CRITICAL_COLOR if is_critical else (HUNTER_HURT_COLOR if hurt_hunter else COLOR)
	show_text("%d%s" % [roundi(amount), "!" if is_critical else ""], color, CRITICAL_FONT_SIZE if is_critical else FONT_SIZE)


## Any floating text: status effect damage, heals, "Immune", effect names (D48).
func show_text(text: String, color: Color, font_size: int = FONT_SIZE) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", OUTLINE)
	label.add_theme_constant_override("outline_size", 4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	label.position = -label.get_minimum_size() * 0.5
	var tween := create_tween().set_parallel()
	tween.tween_property(self, ^"position:y", position.y - RISE, DURATION).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, ^"modulate:a", 0.0, DURATION * 0.4).set_delay(DURATION * 0.6)
	tween.chain().tween_callback(queue_free)
