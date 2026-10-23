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
const KNOCKBACK_DISTANCE := 3.0
const KNOCKBACK_DURATION := 0.16

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
## Playback rate of the walk / run cycle: actual speed over the base walk speed, so a slowed or
## hasted actor's feet keep pace with the ground instead of sliding.
var step_scale := 1.0
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
	_nudge(direction, LUNGE_DISTANCE, LUNGE_DURATION, 0.4)


## Short shove away from a hit, then back (monsters; CombatFeedback).
func play_knockback(direction: Vector2) -> void:
	if not downed:
		_nudge(direction, KNOCKBACK_DISTANCE, KNOCKBACK_DURATION, 0.3)


## Moves this node `distance` px along `direction` and back over `duration` s (`out` = the share
## of the time spent going out). One tween for both: a new nudge replaces a running one.
func _nudge(direction: Vector2, distance: float, duration: float, out: float) -> void:
	if direction.is_zero_approx():
		return
	if _lunge_tween != null:
		_lunge_tween.kill()
	position = Vector2.ZERO
	_lunge_tween = create_tween()
	_lunge_tween.tween_property(self, ^"position", direction.normalized() * distance, duration * out).set_ease(Tween.EASE_OUT)
	_lunge_tween.tween_property(self, ^"position", Vector2.ZERO, duration * (1.0 - out)).set_ease(Tween.EASE_IN_OUT)


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


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			set_notify_local_transform(true)
		NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
			# A lunge / knockback moved this node (or a flourish scaled it): redraw so the shadow
			# and the selection ring stay on the ground.
			queue_redraw()


## Ground shadow at the feet, cast by the hour's sun (DayNight.shadow_of): leaning and long at
## dawn and dusk, short at noon, faint at night. Drawn in the actor's space, so it stays put while
## `position` / `scale` animate the body.
func draw_shadow(radii: Vector2) -> void:
	# Plain noon shadow in the editor and before the game data is loaded (tests, sandbox).
	var sun := {"shift": 0.0, "stretch": 1.0, "strength": 1.0} if Engine.is_editor_hint() or DataRegistry.config == null \
			else DayNight.shadow_of(DayNight.current_phase())
	_begin_ground_space()
	var centre := Vector2(float(sun["shift"]) * radii.x * 0.5, 0.0)
	var size := Vector2(radii.x * float(sun["stretch"]), radii.y)
	fill_ellipse(centre, size, Color(SHADOW_COLOR, SHADOW_COLOR.a * float(sun["strength"])))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Selection ring on the ground (see draw_shadow).
func draw_selection(radii: Vector2) -> void:
	_begin_ground_space()
	outline_ellipse(Vector2.ZERO, radii, SELECTION_COLOR)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Draw transform cancelling this node's own offset and scale: (0, 0) is the actor's feet.
func _begin_ground_space() -> void:
	var inverse := Vector2.ONE
	if not is_zero_approx(scale.x) and not is_zero_approx(scale.y):
		inverse = Vector2.ONE / scale
	draw_set_transform(-position * inverse, 0.0, inverse)


func fill_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	draw_ellipse(center, radii.x, radii.y, color)


func outline_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	draw_ellipse(center, radii.x, radii.y, color, false, 1.0)
