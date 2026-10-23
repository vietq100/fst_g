@tool
class_name ChibiVisual
extends ActorVisual
## Hunter drawn with the Pixel Hero Forge body (D73, PHASE_13): one 3/4 view facing left, mirrored to face
## right; facing up shows its back (rear view, D75), facing up or down keeps the last side. Origin is at the feet.
## Picks a looping animation from the actor's state (idle / walk / run / death) and plays one-shot actions
## on top (attack, skill, hit, pickup, loot, interact), higher priority first (ChibiAnimations.PRIORITY).
## Table animations (ChibiAnimations) move whole Forge parts; idle breathes and blinks like the Forge
## tool; ATTACK plays the weapon's Forge sequence, and SKILL with a staff its `cast`, with per-frame
## durations. The weapon (`forge_weapon`: from the equipped item or the class, tinted by the item) is
## part of the baked frames, which are shared by every Hunter that looks the same (ForgeLook).
## Guardians also carry a shield on the far arm. Presentation only: gameplay never reads it.

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
## Base classes that carry a shield on the far arm.
const SHIELD_CLASSES: Array[StringName] = [&"guardian"]
const SHIELD_FACE := Color("41629e")
const SHIELD_RIM := Color("c9d0d8")
const SHIELD_EMBLEM := Color("e8c35a")
const FX_DURATION := {"step": 0.3, "slash": 0.18, "charge": 0.25, "burst": 0.45, "sparkle": 0.5, "tap": 0.25, "dust": 0.4, "soul": 1.4}
## Breathing and blinking at rest, like the Forge tool: a 1 px bob every 520 ms, a 140 ms blink every 3.4 s.
const BOB_PERIOD := 0.52
const BLINK_EVERY := 3.4
const BLINK_TIME := 0.14
## Far hand (shield arm) in design pixels.
const FAR_HAND := Vector2(3.5, 28.5)
## Chest height above the feet (charge effect, rising soul).
const CHEST := Vector2(0, -18)
const SHADOW_RADII := Vector2(9.0, 3.0)
const LYING_SHADOW_RADII := Vector2(15.0, 3.0)
const SELECTION_RADII := Vector2(11.0, 5.0)
## The pet trots this far behind the heels.
const PET_DISTANCE := 15.0
## Attack effects are baked once per frame: at this progress through the frame, with this random seed.
const EFFECT_PROGRESS := 0.5
const EFFECT_SEED := 3

var appearance: HunterAppearance = HunterAppearance.new():
	set(value):
		appearance = value if value != null else HunterAppearance.new()
		_look_changed()
## Base class outfit (ChibiBody.outfit_for, &"" = the core tank top); used when `dress` is null.
var outfit: StringName = &"":
	set(value):
		if outfit == value:
			return
		outfit = value
		_look_changed()
## Gear worn over the outfit (D59, D73). Null = the plain class outfit.
var dress: ChibiDress = null:
	set(value):
		if dress != null and value != null and dress.key() == value.key() and dress.pet == value.pet \
				and dress.pet_tint == value.pet_tint:
			return
		dress = value
		_look_changed()
## Forge weapon in the hand (ForgeLook.weapon_for): sword, great, katana, dagger, axe, hammer, spear,
## staff, bow, or none.
var forge_weapon := "sword":
	set(value):
		if forge_weapon == value:
			return
		forge_weapon = value
		_weapon_anim = ForgeLook.anim_of(value)
		_look_changed()
## Element of the attack effects (ForgeLook.element_for): none, fire, ice, thunder, poison, shadow.
var element := "none":
	set(value):
		if element == value:
			return
		element = value
		_look_changed()
## Weapon colour from the item; Color.WHITE = the Forge weapon's own colours.
var weapon_color := Color.WHITE:
	set(value):
		if weapon_color == value:
			return
		weapon_color = value
		_look_changed()
## Reach of the slash effect (table ATTACK without a Forge weapon).
var weapon_length := 12.0
var shield := false:
	set(value):
		shield = value
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
## Facing right (mirrored); kept while facing up or down.
var _mirrored := false
## Breathing / blinking phase, so Hunters do not breathe in step.
var _phase := 0.0
## Forge config of the look, dress and weapon, and its cache key ("" = rebuild).
var _cfg: Dictionary = {}
var _cfg_key := ""
## Element of the action playing (a cast skill's, D73 / Q5); "" = the weapon's `element`.
var _action_element := ""
## State key of the last requested redraw (_state_key).
var _drawn_key := ""
## Forge attack sequence of `forge_weapon` (ForgeLook.anim_of), "" without one.
var _weapon_anim := ForgeLook.anim_of("sword")


func _init() -> void:
	_phase = float(get_instance_id() % 997) / 997.0 * BLINK_EVERY


func _ready() -> void:
	queue_redraw()


## Outfit, class weapon and shield for a base class (ChibiBody.outfit_for).
func set_class_style(base_class: StringName) -> void:
	outfit = base_class
	shield = SHIELD_CLASSES.has(base_class)
	forge_weapon = ForgeLook.weapon_for(null, base_class)


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
	_set_action_element("")
	_start(action)


## A class skill was cast: its effects take the skill's element for this action. Skills that hit
## enemies already play the attack (lunge); the others play SKILL.
func play_skill(skill_element: String, attacking: bool) -> void:
	if not attacking:
		play_action(ChibiAnimations.SKILL)
	if _action == ChibiAnimations.ATTACK or _action == ChibiAnimations.SKILL:
		_set_action_element("" if skill_element == "none" else skill_element)


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
	var frames := _frames_of(_animation)
	var walking := _animation == ChibiAnimations.WALK or _animation == ChibiAnimations.RUN
	_frame_time += delta * (step_scale if walking else 1.0)
	while _frame_time >= _duration(frames, _frame):
		_frame_time -= _duration(frames, _frame)
		if _frame + 1 < frames.size():
			_enter_frame(_frame + 1)
		elif ChibiAnimations.is_looping(_animation):
			_enter_frame(0)
		elif _action != &"" and _action != ChibiAnimations.DEATH:
			# One-shot done: back to the state animation.
			_action = &""
			_set_action_element("")
			_start(_looping_animation())
			break
		else:
			break
	var animating := not _fx.is_empty()
	for effect in _fx:
		effect["age"] += delta / FX_DURATION[effect["kind"]]
	_fx = _fx.filter(func(effect: Dictionary) -> bool: return effect["age"] < 1.0)
	# Redraw only when the picture changes (frame, breath, blink, effects); setters redraw themselves.
	var key := _state_key()
	if animating or key != _drawn_key:
		_drawn_key = key
		queue_redraw()


func _looping_animation() -> StringName:
	if downed or dead:
		return ChibiAnimations.DEATH
	if moving:
		return ChibiAnimations.RUN if running else ChibiAnimations.WALK
	return ChibiAnimations.IDLE


## Forge sequence played for an animation ("" = the ChibiAnimations table).
func _forge_anim(animation: StringName) -> String:
	if animation == ChibiAnimations.ATTACK or (animation == ChibiAnimations.SKILL and _weapon_anim == "cast"):
		return _weapon_anim
	return ""


## Frames of an animation: Forge sequence frames {dur, pose} or table frames.
func _frames_of(animation: StringName) -> Array:
	var anim := _forge_anim(animation)
	if anim != "":
		var sequence := ForgeLook.sequence(anim)
		if not sequence.is_empty():
			return sequence
	return ChibiAnimations.get_frames(animation)


func _duration(frames: Array, index: int) -> float:
	var frame: Dictionary = frames[clampi(index, 0, frames.size() - 1)]
	return maxf(0.01, frame.get("dur", 1.0 / ChibiAnimations.get_fps(_animation)))


func _current_frame() -> Dictionary:
	var frames := _frames_of(_animation)
	return frames[clampi(_frame, 0, frames.size() - 1)]


func _start(animation: StringName) -> void:
	_animation = animation
	_frame_time = 0.0
	_enter_frame(0)


func _enter_frame(index: int) -> void:
	_frame = index
	var frame := _current_frame()
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
	_frame = _frames_of(animation).size() - 1


func _refresh_tint() -> void:
	modulate = DEAD_TINT if dead else (DOWNED_TINT if downed else Color.WHITE)


func _settled() -> bool:
	return _time >= SETTLE_TIME and is_inside_tree()


func _add_fx(kind: String) -> void:
	var at := Vector2.ZERO
	match kind:
		"slash", "sparkle", "tap":
			at = _hand_position()
		"charge", "soul":
			at = CHEST
	_fx.append({"kind": kind, "at": at, "side": _side_sign(), "age": 0.0})


func _set_action_element(value: String) -> void:
	if _action_element != value:
		_action_element = value
		_look_changed()


func _look_changed() -> void:
	_cfg_key = ""
	queue_redraw()


## Facing right draws the mirrored art; up and down keep the last side.
func _is_mirrored() -> bool:
	if facing == Facing.Direction.RIGHT:
		_mirrored = true
	elif facing == Facing.Direction.LEFT:
		_mirrored = false
	return _mirrored


func _side_sign() -> float:
	return 1.0 if _is_mirrored() else -1.0


# --- Forge frames ------------------------------------------------------------------------------


func _config() -> Dictionary:
	if _cfg_key == "":
		_cfg = ForgeLook.config(appearance, dress if dress != null else ChibiDress.plain(outfit), forge_weapon,
			weapon_color, _action_element if _action_element != "" else element)
		_cfg_key = ForgeLook.key_of(_cfg)
	return _cfg


## Cache key of the current frame state (the key of _state, without building the state).
func _state_key() -> String:
	var frame := _current_frame()
	if frame.get("lying", false):
		return "lying"
	if frame.has("pose"):
		return "%s|%d" % [_forge_anim(_animation), _frame]
	var rear := _is_rear()
	var view := "rear|" if rear else ""
	if _animation == ChibiAnimations.IDLE:
		return view + "idle|%d|%s" % [_bob(), _blink(rear)]
	return view + "%s|%d" % [_animation, _frame]


## Breathing bob (0 / 1 px) of the rest pose.
func _bob() -> int:
	return posmod(floori((_time + _phase) / BOB_PERIOD), 2)


## Eyes shut this instant (never seen from the back).
func _blink(rear: bool) -> bool:
	return not rear and fmod(_time + _phase, BLINK_EVERY) < BLINK_TIME


## Facing up shows the back (D75); attacks and lying bodies keep the front view.
func _is_rear() -> bool:
	return facing == Facing.Direction.UP


## ForgeComposer state of the current frame and its cache key: [st, key].
func _state() -> Array:
	var frame := _current_frame()
	if frame.get("lying", false):
		return [{"no_weapon": true, "no_shadow": true}, "lying"]
	if frame.has("pose"):
		# Effects: this frame's index in the sequence, its start time (particles drift), mid-frame progress.
		var st := {"pose": frame["pose"], "fi": _frame, "t": _sequence_time(_frame) * 1000.0, "p": EFFECT_PROGRESS,
			"seed": EFFECT_SEED, "no_shadow": true}
		return [st, "%s|%d" % [_forge_anim(_animation), _frame]]
	var rear := _is_rear()
	var view := "rear|" if rear else ""
	if _animation == ChibiAnimations.IDLE:
		var bob := _bob()
		var blink := _blink(rear)
		return [{"bob": float(bob), "blink": blink, "back": rear, "no_shadow": true}, view + "idle|%d|%s" % [bob, blink]]
	var offsets := ChibiAnimations.resolve_offsets(frame, true)
	var arm: Vector2i = offsets[&"arm_r"]
	var leg_l: Vector2i = offsets[&"leg_l"]
	var leg_r: Vector2i = offsets[&"leg_r"]
	# The resting weapon follows the hand, but never below the feet (grounded weapons).
	var st := {"offsets": offsets, "hand": Vector2i(arm.x, mini(arm.y, maxi(leg_l.y, leg_r.y))), "back": rear,
		"no_shadow": true}
	if frame.get("item", false):
		st["no_weapon"] = true
	return [st, view + "%s|%d" % [_animation, _frame]]


## Start time (s) of a frame in the current animation.
func _sequence_time(index: int) -> float:
	var frames := _frames_of(_animation)
	var time := 0.0
	for i in mini(index, frames.size()):
		time += _duration(frames, i)
	return time


func _body_frame() -> ForgeFrame:
	var state := _state()
	return ForgeLook.frame(_config(), _cfg_key, state[0], state[1])


## Weapon hand relative to the feet, mirrored when facing right.
func _hand_position() -> Vector2:
	var hand := ForgeComposer.hand_of(_config(), _state()[0]) - ForgeFrame.FEET
	if _is_mirrored():
		hand.x = -hand.x
	return hand


## Shield hand (far arm) relative to the feet, mirrored when facing right.
func _off_hand_position(frame: Dictionary) -> Vector2:
	var hand := FAR_HAND - ForgeFrame.FEET
	if frame.has("pose"):
		var pose: Dictionary = frame["pose"]
		hand += Vector2(pose.get("dx", 0.0), pose.get("dy", 0.0))
	elif not frame.get("lying", false):
		var arm: Vector2i = ChibiAnimations.resolve_offsets(frame, true)[&"arm_l"]
		hand += Vector2(arm)
	if _is_mirrored():
		hand.x = -hand.x
	return hand


# --- Drawing ---------------------------------------------------------------------------------


func _draw() -> void:
	var frame := _current_frame()
	var lying: bool = frame.get("lying", false)
	var mirrored := _is_mirrored()
	draw_shadow(LYING_SHADOW_RADII if lying else SHADOW_RADII)
	if selected:
		draw_selection(SELECTION_RADII)
	_draw_pet(frame)
	if shield and not lying and not frame.get("item", false):
		_draw_shield(frame)
	var body := _body_frame()
	if lying:
		# Lying on the ground: the standing figure turned about the feet, head towards the facing side.
		var rect := body.get_rect()
		var middle := (rect.position.y + rect.end.y) * 0.5
		var lift: float = frame.get("lift", 0.0)
		var at := Vector2(middle if mirrored else -middle, -1.0 + lift + rect.position.x)
		body.draw(self, at, mirrored, 1.0, PI * 0.5 if mirrored else -PI * 0.5)
	else:
		body.draw(self, Vector2.ZERO, mirrored)
	if frame.get("item", false):
		var hand := _hand_position()
		draw_rect(Rect2(hand + Vector2(-3, -7), Vector2(6, 6)), OUTLINE_COLOR)
		draw_rect(Rect2(hand + Vector2(-2, -6), Vector2(4, 4)), ITEM_COLOR)
	for effect in _fx:
		_draw_fx(effect)


## The pet trots a step behind the Hunter's heels and hops while it walks (D59).
func _draw_pet(frame: Dictionary) -> void:
	if dress == null or dress.pet == &"" or frame.get("lying", false):
		return
	var moving_now := _animation == ChibiAnimations.WALK or _animation == ChibiAnimations.RUN
	var texture := PetSprites.texture(dress.pet, dress.pet_tint, _frame % 2 if moving_now else 0)
	if texture == null:
		return
	var side := _side_sign()
	var x := -PET_DISTANCE * side
	var size := Vector2(PetSprites.SIZE)
	fill_ellipse(Vector2(x, 0.5), Vector2(5.0, 1.8), SHADOW_COLOR)
	var at := Vector2(x - size.x * 0.5, -size.y + 1.0)
	if side < 0.0:
		draw_set_transform(Vector2(x * 2.0, 0.0), 0.0, Vector2(-1, 1))
		draw_texture(texture, at)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_texture(texture, at)


## Kite shield on the far arm, half behind the body.
func _draw_shield(frame: Dictionary) -> void:
	var at := _off_hand_position(frame) + Vector2(0, -3)
	var points := PackedVector2Array([at + Vector2(-4, -6), at + Vector2(4, -6), at + Vector2(4, 2),
		at + Vector2(0, 6), at + Vector2(-4, 2)])
	draw_colored_polygon(BuildingVisual._grow(points, 1.0), OUTLINE_COLOR)
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
			draw_circle(at, 5.0 + t * 14.0, Color(CHARGE_COLOR, 0.35 * (1.0 - t)))
			draw_arc(at, 20.0 - t * 14.0, 0.0, TAU, 20, Color(CHARGE_COLOR, 0.9 * t), 1.0)
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
