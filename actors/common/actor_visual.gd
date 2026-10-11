@tool
class_name ActorVisual
extends Node2D
## Base for actor visuals. Gameplay code only uses this API, so placeholder shapes
## can be swapped for sprite-based visuals without touching gameplay (00_RULES.md §7).

const SHADOW_COLOR := Color(0, 0, 0, 0.35)
const OUTLINE_COLOR := Color("16161c")
const SELECTION_COLOR := Color("f2d16b")
const HIT_FLASH_COLOR := Color(2.5, 2.5, 2.5)
const HIT_FLASH_DURATION := 0.12
const LUNGE_DISTANCE := 4.0
const LUNGE_DURATION := 0.15

var facing: Facing.Direction = Facing.Direction.DOWN:
	set(value):
		facing = value
		queue_redraw()
var selected := false:
	set(value):
		selected = value
		queue_redraw()
var downed := false:
	set(value):
		downed = value
		_on_downed_changed()
		queue_redraw()
## True while the actor walks along a path (visuals may animate steps).
var moving := false
## Moving fast (chasing a target, hasted): visuals may show a run instead of a walk.
var running := false
## Body colour from status effects (D48), e.g. green while poisoned. The hit flash returns to it.
var status_tint := Color.WHITE:
	set(value):
		status_tint = value
		if _flash_tween == null or not _flash_tween.is_running():
			self_modulate = status_tint

var _flash_tween: Tween
var _lunge_tween: Tween


func play_hit_flash() -> void:
	if _flash_tween != null:
		_flash_tween.kill()
	self_modulate = HIT_FLASH_COLOR
	_flash_tween = create_tween()
	_flash_tween.tween_property(self, ^"self_modulate", status_tint, HIT_FLASH_DURATION)


## Short step towards `direction` and back.
func play_attack_lunge(direction: Vector2) -> void:
	if _lunge_tween != null:
		_lunge_tween.kill()
	position = Vector2.ZERO
	_lunge_tween = create_tween()
	_lunge_tween.tween_property(self, ^"position", direction.normalized() * LUNGE_DISTANCE, LUNGE_DURATION * 0.4)
	_lunge_tween.tween_property(self, ^"position", Vector2.ZERO, LUNGE_DURATION * 0.6)


## One-shot action animation by name (ChibiAnimations: skill, pickup, loot, interact...).
## Visuals without such animations ignore it.
func play_action(_action: StringName) -> void:
	pass


## Light burst (VFX_DESIGN.md → Level up).
func play_level_up() -> void:
	var burst := LevelUpBurst.new()
	add_child(burst)


func play_death(duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(self, ^"modulate:a", 0.0, duration)


func _on_downed_changed() -> void:
	pass


func fill_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	draw_ellipse(center, radii.x, radii.y, color)


func outline_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	draw_ellipse(center, radii.x, radii.y, color, false, 1.0)
