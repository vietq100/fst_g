@tool
class_name MonsterVisual
extends ActorVisual
## Monster drawn from a MonsterBodies pixel body (goblin, skeleton, wolf, slime): idle (some bodies
## bob), two-frame walk, hit flash (ActorVisual), lying when downed, an optional weapon held on
## the facing side: a WeaponSprites pixel sprite (`weapon_sprite`) or a line (weapon_length 0 =
## none). Side-on bodies keep their last horizontal facing.
## Bodies are drawn at 1 / MonsterBodies.SCALE (D56). Origin is at the feet. Presentation only.

const WALK_FPS := 8.0
const DOWNED_TINT := Color(0.45, 0.45, 0.5)

@export var body_id: StringName = &"goblin":
	set(value):
		body_id = value
		queue_redraw()
## WeaponSprites kind (club, bone, …); &"" draws the line weapon instead.
@export var weapon_sprite: StringName = &"":
	set(value):
		weapon_sprite = value
		queue_redraw()
@export var weapon_color := Color("d8dde3"):
	set(value):
		weapon_color = value
		queue_redraw()
@export var weapon_length := 9.0:
	set(value):
		weapon_length = value
		queue_redraw()
## Inner width of the weapon line (sword 1, club 2).
@export var weapon_width := 2.0:
	set(value):
		weapon_width = value
		queue_redraw()

var _frame := 0
var _frame_time := 0.0
var _action_tween: Tween
## Last horizontal facing (side-on bodies).
var _mirrored := false


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var fps := WALK_FPS * step_scale if moving else MonsterBodies.get_idle_fps(body_id)
	if fps > 0.0 and not downed:
		_frame_time += delta
		if _frame_time >= 1.0 / fps:
			_frame_time -= 1.0 / fps
			_frame = (_frame + 1) % 2
			queue_redraw()
	elif _frame != 0:
		_frame = 0
		_frame_time = 0.0
		queue_redraw()


func _on_downed_changed() -> void:
	modulate = DOWNED_TINT if downed else Color.WHITE


## Skill flourish (D55): monsters have no skill frames, so the body puffs up and flashes.
func play_action(_action: StringName) -> void:
	if downed:
		return
	if _action_tween != null:
		_action_tween.kill()
	scale = Vector2(1.25, 0.85)
	_action_tween = create_tween()
	_action_tween.tween_property(self, ^"scale", Vector2(0.9, 1.15), 0.08)
	_action_tween.tween_property(self, ^"scale", Vector2.ONE, 0.12)


func _draw() -> void:
	var half_width := MonsterBodies.get_world_size(body_id).x * 0.5
	draw_shadow(Vector2(half_width + 1.0, 3.0))
	if selected:
		draw_selection(Vector2(half_width + 3.0, 5.0))
	if facing == Facing.Direction.LEFT:
		_mirrored = true
	elif facing == Facing.Direction.RIGHT:
		_mirrored = false
	var view := ChibiBody.view_of(facing)
	var texture := MonsterBodies.get_texture(body_id, view, _frame, _mirrored, downed)
	var size := texture.get_size()
	var behind := facing == Facing.Direction.UP
	if not downed and behind:
		_draw_weapon()
	# Texture in texels, drawn at 1 / SCALE (D56); origin in texels relative to the feet.
	var origin := Vector2(-floorf(size.x * 0.5), -size.y)
	var texel := 1.0 / MonsterBodies.SCALE
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(texel, texel))
	draw_texture(texture, origin)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if not downed and not behind:
		_draw_weapon()
	var config := MonsterBodies.get_config(body_id)
	if config.has("glow") and not downed:
		# Pulsing core (the Forest Guardian): brighter on the raised frame.
		var glow: Vector2 = config["glow"]
		var color: Color = config["glow_color"]
		var strength := 0.8 if _frame == 1 else 0.5
		var centre := (origin + glow + Vector2.ONE * MonsterBodies.SCALE) * texel
		draw_circle(centre, 9.0, Color(color, 0.18 * strength))
		draw_circle(centre, 5.0, Color(color, 0.35 * strength))


## Weapon on the facing side (right hand when facing down / up): grip, then blade or club.
func _draw_weapon() -> void:
	if weapon_length <= 0.0:
		return
	var side := -1.0 if facing == Facing.Direction.LEFT else 1.0
	var world_size := MonsterBodies.get_world_size(body_id)
	var half_width := world_size.x * 0.5
	var height := world_size.y
	var hand := Vector2(side * (half_width - 1.0), -height * 0.42)
	if WeaponSprites.has_kind(weapon_sprite):
		# Pixel weapon tilted outward, mirrored when facing left.
		var texture := WeaponSprites.texture(weapon_sprite, weapon_color)
		var grip := WeaponSprites.grip_center(weapon_sprite)
		var weapon_texel := 1.0 / WeaponSprites.SCALE
		draw_set_transform(hand, deg_to_rad(25.0) * side, Vector2(side * weapon_texel, weapon_texel))
		draw_texture(texture, -grip)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var direction := Vector2(side * 2.0, -weapon_length).normalized()
	var base := hand + direction * 2.0
	var tip := hand + direction * weapon_length
	draw_line(hand - direction * 2.0, base, OUTLINE_COLOR, 3.0)
	draw_line(hand - direction * 2.0, base, Color("5a3a26"), 1.0)
	draw_line(base, tip, OUTLINE_COLOR, weapon_width + 2.0)
	draw_line(base, tip, weapon_color, weapon_width)
	if weapon_width >= 2.0:
		draw_circle(tip, weapon_width * 0.5 + 1.5, OUTLINE_COLOR)
		draw_circle(tip, weapon_width * 0.5 + 0.5, weapon_color)
