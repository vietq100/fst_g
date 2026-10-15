@tool
class_name ChibiVisual
extends ActorVisual
## Hunter drawn as the 32×48 chibi body (D49). Origin is at the feet.
## Picks a looping animation from the actor's state (idle / walk / run / death) and plays
## one-shot actions on top (attack, skill, hit, pickup, loot, interact), higher priority first
## (ChibiAnimations.PRIORITY). Frames come from ChibiBody (outfit = the base class). The weapon
## is a WeaponSprites pixel sprite (`weapon_sprite`, picked from the equipped item or the class
## default) rotated in the right hand to the frame's weapon angle and tinted by the item; without
## a sprite a line is drawn by kind (sword, bow, dagger, mace). Guardians also carry a shield on
## the left arm. Presentation only: gameplay never reads it.

## Injured but alive / dead body tints (modulate; self_modulate is the hit flash + status tint).
const DOWNED_TINT := Color(0.72, 0.7, 0.76)
const DEAD_TINT := Color(0.62, 0.66, 0.74)
## State changes during the first moments after spawn skip their animation (loading a save).
const SETTLE_TIME := 0.2
const SLASH_COLOR := Color(1, 1, 1, 0.9)
const CHARGE_COLOR := Color("8fd3ff")
const BURST_COLOR := Color("ffe36b")
const SPARKLE_COLOR := Color("fff2a8")
const ITEM_COLOR := Color("e0b04a")
const DUST_COLOR := Color(0.85, 0.8, 0.7, 0.8)
const SOUL_COLOR := Color(0.85, 0.95, 1.0, 0.8)
const SWORD := &"sword"
const BOW := &"bow"
const DAGGER := &"dagger"
const MACE := &"mace"
## Base class -> [weapon kind, shield, default weapon sprite].
const CLASS_STYLES := {
	&"warrior": [SWORD, false, &"sword"],
	&"ranger": [BOW, false, &"bow"],
	&"rogue": [DAGGER, false, &"dagger"],
	&"guardian": [MACE, true, &"mace"],
}
const GRIP_COLOR := Color("5a3a26")
const GUARD_COLOR := Color("d9b356")
const STRING_COLOR := Color(0.92, 0.9, 0.82, 0.85)
const SHIELD_FACE := Color("41629e")
const SHIELD_RIM := Color("c9d0d8")
const SHIELD_EMBLEM := Color("e8c35a")
const FX_DURATION := {"step": 0.3, "slash": 0.18, "charge": 0.25, "burst": 0.45, "sparkle": 0.5, "tap": 0.25, "dust": 0.4, "soul": 1.4}

var appearance: HunterAppearance = HunterAppearance.new():
	set(value):
		appearance = value if value != null else HunterAppearance.new()
		_frames_cache.clear()
		queue_redraw()
## ChibiBody outfit (base class id, &"" = reference tank top).
var outfit: StringName = &"":
	set(value):
		if outfit == value:
			return
		outfit = value
		_frames_cache.clear()
		queue_redraw()
## Gear worn over the outfit (D59): top / skin colours, pants, boots, hat and pet. Null = the
## plain class outfit.
var dress: ChibiDress = null:
	set(value):
		if dress != null and value != null and dress.key() == value.key() and dress.pet == value.pet \
				and dress.pet_tint == value.pet_tint:
			return
		dress = value
		_frames_cache.clear()
		queue_redraw()
## How the weapon is drawn: SWORD, BOW, DAGGER or MACE.
var weapon_kind: StringName = SWORD:
	set(value):
		weapon_kind = value
		queue_redraw()
var shield := false:
	set(value):
		shield = value
		queue_redraw()
## WeaponSprites kind drawn in the hand; &"" falls back to the line weapon.
var weapon_sprite: StringName = &"":
	set(value):
		weapon_sprite = value
		queue_redraw()
var weapon_color := Color("d8dde3"):
	set(value):
		weapon_color = value
		queue_redraw()
var weapon_length := 12.0:
	set(value):
		weapon_length = value
		queue_redraw()
var weapon_width := 1.0:
	set(value):
		weapon_width = value
		queue_redraw()
## A dead Hunter's body (HunterRuntime.alive == false): lies still, cold grey, a soul rises.
var dead := false:
	set(value):
		if dead == value:
			return
		dead = value
		_on_dead_changed()

var _time := 0.0
var _animation: StringName = ChibiAnimations.IDLE
var _frame := 0
var _frame_time := 0.0
## One-shot action playing over the looping state, or &"".
var _action: StringName = &""
## Active effects: {kind, at (local position), age 0..1, side (+1/-1)}.
var _fx: Array[Dictionary] = []
## Facing -> animation -> textures, for the current appearance.
var _frames_cache: Dictionary = {}


func _ready() -> void:
	queue_redraw()


## Outfit, weapon kind and shield for a base class (ChibiBody.outfit_for).
func set_class_style(base_class: StringName) -> void:
	outfit = base_class
	var style: Array = CLASS_STYLES.get(base_class, [SWORD, false, &"sword"])
	weapon_kind = style[0]
	shield = style[1]
	weapon_sprite = style[2]


## Default sprite kind of the current class (for the equipped item lookup).
func get_default_weapon_sprite() -> StringName:
	var style: Array = CLASS_STYLES.get(outfit, [SWORD, false, &"sword"])
	return style[2]


## Plays a one-shot animation (ChibiAnimations names). Ignored while a higher-priority one plays,
## and while downed or dead (except death itself).
func play_action(action: StringName) -> void:
	if not ChibiAnimations.has_animation(action) or ChibiAnimations.is_looping(action):
		return
	if (downed or dead) and action != ChibiAnimations.DEATH:
		return
	if _action != &"" and ChibiAnimations.PRIORITY.get(_action, 0) > ChibiAnimations.PRIORITY.get(action, 0):
		return
	_action = action
	_start(action)


func play_attack_lunge(direction: Vector2) -> void:
	super(direction)
	play_action(ChibiAnimations.ATTACK)


func play_hit_flash() -> void:
	super()
	play_action(ChibiAnimations.HIT)


## Current animation and frame (debug / tests).
func get_animation() -> StringName:
	return _animation


func get_frame() -> int:
	return _frame


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	if _action == &"":
		var wanted := _looping_animation()
		if wanted != _animation:
			_start(wanted)
	var fps := ChibiAnimations.get_fps(_animation)
	_frame_time += delta
	var count := ChibiAnimations.get_frames(_animation).size()
	while _frame_time >= 1.0 / fps:
		_frame_time -= 1.0 / fps
		if _frame + 1 < count:
			_enter_frame(_frame + 1)
		elif ChibiAnimations.is_looping(_animation):
			_enter_frame(0)
		elif _action != &"" and _action != ChibiAnimations.DEATH:
			# One-shot done: back to the state animation.
			_action = &""
			_start(_looping_animation())
			break
		else:
			break
	for effect in _fx:
		effect["age"] += delta / FX_DURATION[effect["kind"]]
	_fx = _fx.filter(func(effect: Dictionary) -> bool: return effect["age"] < 1.0)
	queue_redraw()


func _looping_animation() -> StringName:
	if downed or dead:
		return ChibiAnimations.DEATH
	if moving:
		return ChibiAnimations.RUN if running else ChibiAnimations.WALK
	return ChibiAnimations.IDLE


func _start(animation: StringName) -> void:
	_animation = animation
	_frame_time = 0.0
	_enter_frame(0)


func _enter_frame(index: int) -> void:
	_frame = index
	var frame := ChibiAnimations.get_frame(_animation, index)
	if frame.has("fx"):
		_add_fx(frame["fx"])


func _on_downed_changed() -> void:
	_action = &""
	if downed:
		if _settled():
			_start(ChibiAnimations.DEATH)
		else:
			_skip_to_end(ChibiAnimations.DEATH)
	else:
		_start(ChibiAnimations.IDLE)
	_refresh_tint()


func _on_dead_changed() -> void:
	if dead:
		_action = &""
		_skip_to_end(ChibiAnimations.DEATH)
		if _settled():
			_add_fx("soul")
	_refresh_tint()


func _skip_to_end(animation: StringName) -> void:
	_animation = animation
	_frame_time = 0.0
	_frame = ChibiAnimations.get_frames(animation).size() - 1


func _refresh_tint() -> void:
	modulate = DEAD_TINT if dead else (DOWNED_TINT if downed else Color.WHITE)


func _settled() -> bool:
	return _time >= SETTLE_TIME and is_inside_tree()


func _add_fx(kind: String) -> void:
	var frame := ChibiAnimations.get_frame(_animation, _frame)
	var at := Vector2.ZERO
	match kind:
		"slash", "sparkle", "tap", "charge":
			at = _hand_position(frame)
		"soul":
			at = Vector2(0, -22)
	_fx.append({"kind": kind, "at": at, "age": 0.0, "side": _side_sign()})


func _side_sign() -> float:
	return -1.0 if facing == Facing.Direction.LEFT else 1.0


# --- Drawing ---------------------------------------------------------------------------------


func _draw() -> void:
	fill_ellipse(Vector2.ZERO, Vector2(11.0, 4.0), SHADOW_COLOR)
	if selected:
		outline_ellipse(Vector2.ZERO, Vector2(13.0, 6.0), SELECTION_COLOR)
	var frame := ChibiAnimations.get_frame(_animation, _frame)
	var textures := _textures(_animation)
	var show_weapon: bool = not frame.get("lying", false) and not frame.get("item", false)
	var behind := facing == Facing.Direction.UP
	# The shield arm is the far arm in the side view.
	var shield_behind := ChibiBody.view_of(facing) == ChibiBody.View.SIDE
	_draw_pet(frame)
	if shield and show_weapon and shield_behind:
		_draw_shield(frame)
	if show_weapon and behind:
		_draw_weapon(frame)
	if not textures.is_empty():
		draw_texture(textures[clampi(_frame, 0, textures.size() - 1)], -Vector2(ChibiBody.FEET))
	if show_weapon and not behind:
		_draw_weapon(frame)
	if shield and show_weapon and not shield_behind:
		_draw_shield(frame)
	if frame.get("item", false):
		var hand := _hand_position(frame)
		draw_rect(Rect2(hand + Vector2(-3, -7), Vector2(6, 6)), OUTLINE_COLOR)
		draw_rect(Rect2(hand + Vector2(-2, -6), Vector2(4, 4)), ITEM_COLOR)
	for effect in _fx:
		_draw_fx(effect)


## The pet trots a step behind the Hunter's heels and hops while it walks (D59).
func _draw_pet(frame: Dictionary) -> void:
	if dress == null or dress.pet == &"" or frame.get("lying", false):
		return
	var moving := _animation == ChibiAnimations.WALK or _animation == ChibiAnimations.RUN
	var texture := PetSprites.texture(dress.pet, dress.pet_tint, _frame % 2 if moving else 0)
	if texture == null:
		return
	var side := _side_sign()
	var x := -18.0 * side if facing == Facing.Direction.LEFT or facing == Facing.Direction.RIGHT else -16.0
	var size := Vector2(PetSprites.SIZE)
	fill_ellipse(Vector2(x, 0.5), Vector2(5.0, 1.8), SHADOW_COLOR)
	var at := Vector2(x - size.x * 0.5, -size.y + 1.0)
	if side < 0.0:
		draw_set_transform(Vector2(x * 2.0, 0.0), 0.0, Vector2(-1, 1))
		draw_texture(texture, at)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_texture(texture, at)


func _textures(animation: StringName) -> Array[ImageTexture]:
	var key := "%d|%s" % [facing, animation]
	if not _frames_cache.has(key):
		_frames_cache[key] = ChibiBody.get_frames(appearance, facing, animation, outfit, dress)
	return _frames_cache[key]


## Weapon hand relative to the feet for a frame, mirrored when facing left.
func _hand_position(frame: Dictionary) -> Vector2:
	var view := ChibiBody.view_of(facing)
	var offsets := ChibiAnimations.resolve_offsets(frame, view == ChibiBody.View.SIDE)
	var hand := ChibiBody.hand_position(view, offsets[&"arm_r"])
	if facing == Facing.Direction.LEFT:
		hand.x = -hand.x
	return hand


## Shield hand (left arm) relative to the feet, mirrored when facing left.
func _off_hand_position(frame: Dictionary) -> Vector2:
	var view := ChibiBody.view_of(facing)
	var offsets := ChibiAnimations.resolve_offsets(frame, view == ChibiBody.View.SIDE)
	var hand := ChibiBody.off_hand_position(view, offsets[&"arm_l"])
	if facing == Facing.Direction.LEFT:
		hand.x = -hand.x
	return hand


func _draw_weapon(frame: Dictionary) -> void:
	var hand := _hand_position(frame)
	var angle: float = frame.get("weapon", ChibiAnimations.WEAPON_REST)
	if weapon_kind == BOW:
		# A bow is held upright, not swung.
		angle = clampf(angle, -20.0, 30.0)
	var direction := Vector2.UP.rotated(deg_to_rad(angle))
	var mirrored := facing == Facing.Direction.LEFT or facing == Facing.Direction.UP
	if mirrored:
		direction.x = -direction.x
	if WeaponSprites.has_kind(weapon_sprite):
		_draw_weapon_sprite(hand, angle, mirrored)
		return
	# Perpendicular to the weapon, pointing to the side the Hunter faces.
	var across := Vector2(-direction.y, direction.x) * (-1.0 if mirrored else 1.0)
	match weapon_kind:
		BOW:
			_draw_bow(hand, direction, across)
		MACE:
			_draw_mace(hand, direction)
		_:
			_draw_blade(hand, direction, across)


## Pixel weapon rotated about the hand; mirrored facings flip the sprite and the swing.
func _draw_weapon_sprite(hand: Vector2, angle: float, mirrored: bool) -> void:
	var texture := WeaponSprites.texture(weapon_sprite, weapon_color)
	# Weapon bitmaps are at WeaponSprites.SCALE texels per world pixel (D71): draw them scaled down.
	var grip := WeaponSprites.grip_center(weapon_sprite)
	var rotation := deg_to_rad(angle) * (-1.0 if mirrored else 1.0)
	var texel := 1.0 / WeaponSprites.SCALE
	draw_set_transform(hand, rotation, Vector2((-1.0 if mirrored else 1.0) * texel, texel))
	draw_texture(texture, -grip)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Sword or dagger: grip, crossguard, blade with a bright edge.
func _draw_blade(hand: Vector2, direction: Vector2, across: Vector2) -> void:
	var dagger := weapon_kind == DAGGER
	var guard := 2.0 if dagger else 3.0
	var blade_width := weapon_width if dagger else weapon_width + 1.0
	var base := hand + direction * 2.0
	var tip := hand + direction * weapon_length
	var pommel := hand - direction * 2.0
	draw_line(pommel, base, OUTLINE_COLOR, 3.0)
	draw_line(pommel, base, GRIP_COLOR, 1.0)
	draw_line(base, tip + direction, OUTLINE_COLOR, blade_width + 2.0)
	draw_line(base, tip, weapon_color, blade_width)
	if blade_width >= 2.0:
		draw_line(base + direction, tip - direction, weapon_color.lightened(0.45), 1.0)
	draw_line(base + across * guard, base - across * guard, OUTLINE_COLOR, 3.0)
	draw_line(base + across * (guard - 1.0), base - across * (guard - 1.0), GUARD_COLOR, 1.0)


## Short bow: curved limb gripped at its middle, string behind the hand.
func _draw_bow(hand: Vector2, direction: Vector2, across: Vector2) -> void:
	var half := weapon_length * 0.5
	var limb := PackedVector2Array()
	for i in 9:
		var t := lerpf(-1.0, 1.0, i / 8.0)
		limb.append(hand + direction * t * half + across * (1.0 - t * t) * 3.5 - across * 1.5)
	draw_line(limb[0], limb[8], STRING_COLOR, 1.0)
	draw_polyline(limb, OUTLINE_COLOR, 3.0)
	draw_polyline(limb, weapon_color, 1.0)
	draw_line(hand - direction * 1.5, hand + direction * 1.5, GRIP_COLOR, 2.0)


## Mace: handle and a spiked round head.
func _draw_mace(hand: Vector2, direction: Vector2) -> void:
	var head := hand + direction * (weapon_length - 2.0)
	var pommel := hand - direction * 2.0
	draw_line(pommel, head, OUTLINE_COLOR, 3.0)
	draw_line(pommel, head, GRIP_COLOR, 1.0)
	for i in 4:
		var spike := direction.rotated(PI * 0.25 + i * PI * 0.5)
		draw_line(head + spike * 2.0, head + spike * 4.5, OUTLINE_COLOR, 1.5)
	draw_circle(head, 3.5, OUTLINE_COLOR)
	draw_circle(head, 2.5, weapon_color)
	draw_circle(head + Vector2(-0.8, -0.8), 1.0, weapon_color.lightened(0.45))


## Kite shield on the left arm; seen from behind it shows its plain back.
func _draw_shield(frame: Dictionary) -> void:
	var at := _off_hand_position(frame) + Vector2(0, -3)
	var points := PackedVector2Array([at + Vector2(-4, -6), at + Vector2(4, -6), at + Vector2(4, 2),
		at + Vector2(0, 6), at + Vector2(-4, 2)])
	draw_colored_polygon(BuildingVisual._grow(points, 1.0), OUTLINE_COLOR)
	if facing == Facing.Direction.UP:
		draw_colored_polygon(points, SHIELD_RIM.darkened(0.35))
		return
	draw_colored_polygon(points, SHIELD_FACE)
	draw_line(at + Vector2(-4, -5.5), at + Vector2(4, -5.5), SHIELD_RIM, 1.0)
	draw_rect(Rect2(at + Vector2(-1, -3), Vector2(2, 5)), SHIELD_EMBLEM)


func _draw_fx(effect: Dictionary) -> void:
	var t: float = effect["age"]
	var at: Vector2 = effect["at"]
	var side: float = effect["side"]
	match effect["kind"]:
		"step":
			for sign_x in [-1.0, 1.0]:
				draw_circle(Vector2(sign_x * (4.0 + t * 4.0), -1.0 - t * 2.0), 1.5 * (1.0 - t), Color(DUST_COLOR, DUST_COLOR.a * (1.0 - t)))
		"dust":
			for i in 5:
				var x := (i - 2) * 5.0 + (i - 2) * t * 4.0
				draw_circle(Vector2(x, -2.0 - t * 4.0), 2.0 * (1.0 - t), Color(DUST_COLOR, DUST_COLOR.a * (1.0 - t)))
		"slash":
			var arc := PackedVector2Array()
			var radius := weapon_length + 2.0
			for i in 7:
				var angle := deg_to_rad(lerpf(-40.0, 110.0, float(i) / 6.0)) - PI * 0.5
				arc.append(at + Vector2(cos(angle) * side, sin(angle)) * radius)
			draw_polyline(arc, Color(SLASH_COLOR, SLASH_COLOR.a * (1.0 - t)), 2.0)
		"charge":
			draw_circle(Vector2(0, -22), 5.0 + t * 14.0, Color(CHARGE_COLOR, 0.35 * (1.0 - t)))
			draw_arc(Vector2(0, -22), 20.0 - t * 14.0, 0.0, TAU, 20, Color(CHARGE_COLOR, 0.9 * t), 1.0)
		"burst":
			var radius := 6.0 + t * 18.0
			draw_ellipse(Vector2(0, -1), radius, radius * 0.4, Color(BURST_COLOR, 1.0 - t), false, 2.0)
			for i in 8:
				var direction := Vector2.RIGHT.rotated(i * TAU / 8.0) * Vector2(1.0, 0.5)
				draw_line(direction * radius * 0.6, direction * radius, Color(BURST_COLOR, 0.8 * (1.0 - t)), 1.0)
		"sparkle":
			for i in 4:
				var angle := i * TAU / 4.0 + t * 2.0
				var point := at + Vector2(0, -3) + Vector2(cos(angle), sin(angle)) * (3.0 + t * 6.0)
				var arm := 1.5 * (1.0 - t) + 0.5
				draw_line(point + Vector2(-arm, 0), point + Vector2(arm, 0), Color(SPARKLE_COLOR, 1.0 - t), 1.0)
				draw_line(point + Vector2(0, -arm), point + Vector2(0, arm), Color(SPARKLE_COLOR, 1.0 - t), 1.0)
		"tap":
			draw_arc(at + Vector2(side * 2.0, 0), 2.0 + t * 5.0, 0.0, TAU, 12, Color(1, 1, 1, 0.8 * (1.0 - t)), 1.0)
		"soul":
			var center := at + Vector2(sin(t * 9.0) * 2.0, -t * 26.0)
			draw_circle(center, 3.0, Color(SOUL_COLOR, SOUL_COLOR.a * (1.0 - t)))
			draw_circle(center + Vector2(0, 3), 2.0, Color(SOUL_COLOR, 0.5 * (1.0 - t)))
