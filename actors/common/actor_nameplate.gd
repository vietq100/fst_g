class_name ActorNameplate
extends Node2D
## Name and HP bar floating over an actor (UI_DESIGN.md → Feedback), like the labels over
## hunters and monsters in management RPGs. Keeps a readable size on screen by scaling against
## the camera zoom. The HP bar appears only while the actor is hurt. Presentation only.

const FONT_SIZE := 10
const BAR_SIZE := Vector2(26, 4)
const INK := Color("0b0d12")
const NAME_COLOR := Color("f4f1ea")
const HP_GOOD := Color("6fbf5f")
const HP_WARN := Color("e8c547")
const HP_BAD := Color("c9503f")
## Hunters' mana (D70), shown under the HP bar while not full.
const MANA_COLOR := Color("6a7dff")
const MANA_SIZE := Vector2(26, 2)

var actor: Actor
var text := ""
## Name colour (tier colour for monsters, D60).
var name_color := NAME_COLOR
var _shown_hp := -1.0
var _shown_max := -1.0
var _shown_mana := -1.0


## `lift` = height above the feet.
func setup(target: Actor, label: String, lift: float) -> void:
	actor = target
	text = label
	position = Vector2(0, -lift)
	z_index = 5
	queue_redraw()


func _process(_delta: float) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	var camera := get_viewport().get_camera_2d()
	var zoom := camera.zoom.x if camera != null else 1.0
	var factor := clampf(1.0 / zoom, 1.0, 2.5)
	scale = Vector2(factor, factor)
	if actor.health.current_health != _shown_hp or actor.health.max_health != _shown_max:
		_shown_hp = actor.health.current_health
		_shown_max = actor.health.max_health
		queue_redraw()
	var mana := _mana_ratio()
	if not is_equal_approx(mana, _shown_mana):
		_shown_mana = mana
		queue_redraw()


func _mana_ratio() -> float:
	var hunter := actor as Hunter
	if hunter == null or hunter.skill_caster == null:
		return -1.0
	return snappedf(hunter.skill_caster.get_mana_ratio(), 0.02)


func _draw() -> void:
	var y := 0.0
	if not text.is_empty():
		var font := ThemeDB.fallback_font
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		var at := Vector2(-width * 0.5, 0)
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 3, INK)
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, name_color)
		y = 3.0
	if _shown_max > 0.0 and _shown_hp < _shown_max:
		var ratio := clampf(_shown_hp / _shown_max, 0.0, 1.0)
		var bar := Rect2(Vector2(-BAR_SIZE.x * 0.5, y), BAR_SIZE)
		draw_rect(bar.grow(1.0), INK)
		draw_rect(bar, Color(0.2, 0.2, 0.24))
		var color := HP_GOOD if ratio > 0.5 else (HP_WARN if ratio > 0.25 else HP_BAD)
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), color)
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, 1.0)), color.lightened(0.3))
		y += BAR_SIZE.y + 2.0
	if _shown_mana >= 0.0 and _shown_mana < 1.0:
		var mana_bar := Rect2(Vector2(-MANA_SIZE.x * 0.5, y), MANA_SIZE)
		draw_rect(mana_bar.grow(1.0), INK)
		draw_rect(mana_bar, Color(0.2, 0.2, 0.24))
		draw_rect(Rect2(mana_bar.position, Vector2(mana_bar.size.x * _shown_mana, mana_bar.size.y)), MANA_COLOR)
