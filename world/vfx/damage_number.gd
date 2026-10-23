class_name DamageNumber
extends Node2D
## Floating damage number (VFX_DESIGN.md → Combat). Rises, fades and frees itself. Hits that land
## close together on one target are added into the same number (`absorb`, CombatFeedback).

const RISE := 14.0
const DURATION := 0.7
## Random sideways offset (px) of each number.
const DRIFT := 6.0
const FONT_SIZE := 12
const CRITICAL_FONT_SIZE := 15
const COLOR := Color("f4f1ea")
const CRITICAL_COLOR := Color("ffd23f")
const HUNTER_HURT_COLOR := Color("ff7a6b")
const OUTLINE := Color("16161c")

var _label: Label
var _amount := 0.0
var _critical := false
var _hurt_hunter := false
var _tween: Tween


## `hurt_hunter` uses a red tint so the player can tell incoming from outgoing damage.
func setup(amount: float, is_critical: bool, hurt_hunter: bool) -> void:
	_amount = amount
	_critical = is_critical
	_hurt_hunter = hurt_hunter
	show_text(_format(), _color(), _size(), is_critical)


## Another hit on the same target within the merge window: one bigger number, restarted.
func absorb(amount: float, is_critical: bool) -> void:
	_amount += amount
	_critical = _critical or is_critical
	if _label == null:
		return
	_label.text = _format()
	_label.add_theme_font_size_override("font_size", _size())
	_label.add_theme_color_override("font_color", _color())
	_label.position = -_label.get_minimum_size() * 0.5
	_start_tween(true)


## Any floating text: status effect damage, heals, "Immune", effect names (D48). `punch` scales
## the text in from large (critical hits).
func show_text(text: String, color: Color, font_size: int = FONT_SIZE, punch: bool = false) -> void:
	_label = Label.new()
	_label.text = text
	_label.add_theme_font_size_override("font_size", font_size)
	_label.add_theme_color_override("font_color", color)
	_label.add_theme_color_override("font_outline_color", OUTLINE)
	_label.add_theme_constant_override("outline_size", 4)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)
	_label.position = -_label.get_minimum_size() * 0.5
	# Numbers on one target scatter sideways so rapid hits do not stack into one blob.
	position.x += randf_range(-DRIFT, DRIFT)
	_start_tween(punch)


## Rise, fade and free; `punch` scales in from large. Restarts from the current spot on a merge.
func _start_tween(punch: bool) -> void:
	if _tween != null:
		_tween.kill()
	modulate.a = 1.0
	scale = Vector2.ONE
	_tween = create_tween().set_parallel()
	if punch:
		_tween.tween_property(self, ^"scale", Vector2.ONE, 0.18).from(Vector2(1.6, 1.6)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_tween.tween_property(self, ^"position:y", position.y - RISE, DURATION).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, ^"modulate:a", 0.0, DURATION * 0.4).set_delay(DURATION * 0.6)
	_tween.chain().tween_callback(queue_free)


func _format() -> String:
	return "%d%s" % [roundi(_amount), "!" if _critical else ""]


func _color() -> Color:
	return CRITICAL_COLOR if _critical else (HUNTER_HURT_COLOR if _hurt_hunter else COLOR)


func _size() -> int:
	return CRITICAL_FONT_SIZE if _critical else FONT_SIZE
