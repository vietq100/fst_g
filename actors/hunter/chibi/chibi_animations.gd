class_name ChibiAnimations
extends RefCounted
## Frame tables of the chibi Hunter (D49, CHARACTER_DESIGN.md §3).
##
##   Movement: idle, walk, run
##   Combat:   attack, skill, hit, death
##   Utility:  pickup, loot, interact
##
## A frame is a Dictionary:
## - part offsets in whole pixels of the original 15×29 body (scaled by PIXEL_SCALE): "all",
##   "body" (head + torso + arms), "arms", "legs", or one part ("head", "torso", "arm_l", "arm_r",
##   "leg_l", "leg_r"). Groups and parts add up.
## - "side": keys that replace the frame's own keys in the side view (+x = forward).
## - "weapon": weapon angle in degrees (0 = straight up, + = forward). Default WEAPON_REST.
## - "fx": effect started when the frame begins (ChibiVisual): step, slash, charge, burst,
##   sparkle, tap, dust.
## - "lying": drawn lying on the ground (death); "lift": extra px off the ground while lying.
## - "item": show a picked-up item in the weapon hand.
## - "dur": this frame's duration in seconds (default 1 / fps). ChibiVisual plays ATTACK (and SKILL with a
##   staff) from the weapon's Forge sequence instead (ForgeLook.sequence: frames {dur, pose}).

const WEAPON_REST := 30.0
## Offsets in the tables are in 15×29-body pixels (D49), about the size of the Forge body (D73).
const PIXEL_SCALE := 1.0

const IDLE := &"idle"
const WALK := &"walk"
const RUN := &"run"
const ATTACK := &"attack"
const SKILL := &"skill"
const HIT := &"hit"
const DEATH := &"death"
const PICKUP := &"pickup"
const LOOT := &"loot"
const INTERACT := &"interact"

## name -> {fps, loop, frames}. One-shot animations end on their last frame (death holds it).
const ANIMATIONS := {
	IDLE: {"fps": 4.0, "loop": true, "frames": [
		{},
		{"head": [0, 1]},
		{"head": [0, 1], "arms": [0, 1]},
		{"arms": [0, 1]},
	]},
	WALK: {"fps": 8.0, "loop": true, "frames": [
		{"fx": "step", "side": {"leg_l": [1, 0], "leg_r": [-1, 0], "arm_l": [0, 1], "arm_r": [0, -1]}},
		{"body": [0, -1], "leg_l": [0, -1], "arm_l": [0, 1], "side": {"arm_l": [0, 0], "leg_l": [0, 0], "leg_r": [0, -1]}},
		{"fx": "step", "side": {"leg_l": [-1, 0], "leg_r": [1, 0], "arm_l": [0, -1], "arm_r": [0, 1]}},
		{"body": [0, -1], "leg_r": [0, -1], "arm_r": [0, 1], "side": {"arm_r": [0, 0], "leg_r": [0, 0], "leg_l": [0, -1]}},
	]},
	RUN: {"fps": 12.0, "loop": true, "frames": [
		{"fx": "step", "leg_l": [0, -2], "arm_l": [0, 1], "arm_r": [0, -1],
			"side": {"head": [1, 0], "leg_l": [1, -1], "leg_r": [-1, 0]}},
		{"body": [0, -1], "leg_l": [0, -1], "side": {"head": [1, 0], "leg_l": [1, -1]}},
		{"all": [0, -2], "side": {"head": [1, 0]}},
		{"fx": "step", "leg_r": [0, -2], "arm_r": [0, 1], "arm_l": [0, -1],
			"side": {"head": [1, 0], "leg_r": [1, -1], "leg_l": [-1, 0]}},
		{"body": [0, -1], "leg_r": [0, -1], "side": {"head": [1, 0], "leg_r": [1, -1]}},
		{"all": [0, -2], "side": {"head": [1, 0]}},
	]},
	ATTACK: {"fps": 14.0, "loop": false, "frames": [
		{"head": [0, 1], "arm_r": [0, -1], "weapon": -30.0},
		{"head": [0, 1], "arm_r": [0, -2], "weapon": -60.0, "side": {"head": [-1, 1], "torso": [-1, 0], "arm_r": [-1, -2]}},
		{"arm_r": [1, 1], "weapon": 70.0, "fx": "slash", "side": {"head": [1, 0], "torso": [1, 0], "arm_r": [1, 0]}},
		{"arm_r": [1, 1], "weapon": 120.0, "side": {"head": [1, 0], "arm_r": [1, 1]}},
		{"weapon": 90.0},
		{"weapon": 50.0},
	]},
	SKILL: {"fps": 12.0, "loop": false, "frames": [
		{"head": [0, 2], "torso": [0, 1], "arms": [0, 1]},
		{"head": [0, 2], "torso": [0, 1], "arms": [0, 1], "fx": "charge"},
		{"all": [0, -3], "arms": [0, -3], "weapon": -10.0},
		{"all": [0, -4], "arms": [0, -5], "weapon": 0.0},
		{"head": [0, 1], "arm_l": [-1, 0], "arm_r": [1, 0], "weapon": 150.0, "fx": "burst"},
		{"head": [0, 1], "arms": [0, 1], "weapon": 150.0},
		{"head": [0, 1], "weapon": 90.0},
		{},
	]},
	HIT: {"fps": 12.0, "loop": false, "frames": [
		{"head": [0, 1], "arm_l": [-1, -1], "arm_r": [1, -1], "side": {"body": [-1, 0], "head": [0, 1]}},
		{"head": [0, 1], "side": {"body": [-1, 0], "head": [0, 1]}},
		{},
	]},
	DEATH: {"fps": 8.0, "loop": false, "frames": [
		{"head": [0, 1], "arm_l": [-1, -1], "arm_r": [1, -1]},
		{"body": [0, 1], "head": [0, 1]},
		{"body": [0, 2], "head": [0, 1], "arms": [0, 1]},
		{"lying": true, "fx": "dust"},
		{"lying": true, "lift": -1},
		{"lying": true},
	]},
	PICKUP: {"fps": 10.0, "loop": false, "frames": [
		{"head": [0, 1], "torso": [0, 1], "arms": [0, 1]},
		{"head": [0, 3], "torso": [0, 2], "arms": [0, 3], "arm_r": [0, 1]},
		{"head": [0, 3], "torso": [0, 2], "arms": [0, 3], "arm_r": [0, 2]},
		{"head": [0, 3], "torso": [0, 2], "arms": [0, 3], "arm_r": [0, 1]},
		{"head": [0, 1], "torso": [0, 1], "arms": [0, 1]},
		{},
	]},
	LOOT: {"fps": 10.0, "loop": false, "frames": [
		{"head": [0, 1], "torso": [0, 1], "arms": [0, 1]},
		{"head": [0, 3], "torso": [0, 2], "arms": [0, 3], "arm_r": [0, 1]},
		{"head": [0, 3], "torso": [0, 2], "arms": [0, 3], "arm_r": [0, 2], "item": true},
		{"head": [0, 1], "torso": [0, 1], "arms": [0, 1], "arm_r": [0, -4], "item": true, "weapon": -20.0},
		{"arm_r": [0, -5], "item": true, "fx": "sparkle", "weapon": -20.0},
		{"arm_r": [0, -5], "item": true, "weapon": -20.0},
		{"arm_r": [0, -4], "item": true, "weapon": -10.0},
		{},
	]},
	INTERACT: {"fps": 8.0, "loop": false, "frames": [
		{"arm_r": [0, -1], "side": {"arm_r": [1, -1]}},
		{"arm_r": [0, -2], "side": {"arm_r": [1, -2]}},
		{"head": [0, 1], "arm_r": [0, -1], "fx": "tap", "side": {"head": [0, 1], "arm_r": [1, -1]}},
		{"arm_r": [0, -2], "side": {"arm_r": [1, -2]}},
		{"arm_r": [0, -1], "fx": "tap", "side": {"arm_r": [1, -1]}},
		{},
	]},
}

## Which one-shot animation wins when another is asked for while it plays.
const PRIORITY := {DEATH: 4, SKILL: 3, ATTACK: 3, HIT: 2, PICKUP: 1, LOOT: 1, INTERACT: 1}

const GROUPS := {
	"all": [&"head", &"torso", &"arm_l", &"arm_r", &"leg_l", &"leg_r"],
	"body": [&"head", &"torso", &"arm_l", &"arm_r"],
	"arms": [&"arm_l", &"arm_r"],
	"legs": [&"leg_l", &"leg_r"],
}


static func has_animation(animation: StringName) -> bool:
	return ANIMATIONS.has(animation)


static func get_frames(animation: StringName) -> Array:
	return ANIMATIONS[animation]["frames"] if ANIMATIONS.has(animation) else ANIMATIONS[IDLE]["frames"]


static func get_fps(animation: StringName) -> float:
	return ANIMATIONS[animation]["fps"]


static func is_looping(animation: StringName) -> bool:
	return ANIMATIONS[animation]["loop"]


static func get_frame(animation: StringName, index: int) -> Dictionary:
	var frames := get_frames(animation)
	return frames[clampi(index, 0, frames.size() - 1)]


## Part -> pixel offset for a frame (side view applies the frame's "side" keys).
static func resolve_offsets(frame: Dictionary, side: bool) -> Dictionary:
	var keys := frame.duplicate()
	if side and frame.has("side"):
		keys.merge(frame["side"], true)
	var result := {}
	for part in GROUPS["all"]:
		result[part] = Vector2i.ZERO
	for key: String in ["all", "body", "arms", "legs"]:
		if keys.has(key):
			for part: StringName in GROUPS[key]:
				result[part] += _vector(keys[key])
	for part: StringName in GROUPS["all"]:
		if keys.has(String(part)):
			result[part] += _vector(keys[String(part)])
	return result


static func _vector(value: Array) -> Vector2i:
	return Vector2i(roundi(float(value[0]) * PIXEL_SCALE), roundi(float(value[1]) * PIXEL_SCALE))
