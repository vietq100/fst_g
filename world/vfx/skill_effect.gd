class_name SkillEffect
extends Node2D
## One-shot pixel effect of a skill (D75), drawn with the Pixel Hero Forge effects (ForgeFx) in an element's
## colours: STRIKE a burst with particles on the body, SLAM a shock wave on the ground, SPELL a column
## striking down, AURA a glow with rising particles (heals and buffs). Frames are baked once per kind and
## element (ForgeFrame) and shared; the node frees itself when done. Origin = the actor's feet.

enum Kind { STRIKE, SLAM, SPELL, AURA }

const FRAMES := 6
const FPS := 14.0
## Effects draw above the actors.
const Z := 30
## Design pixel of the feet and the body's middle above it.
const FEET := Vector2(9.5, 35.6)
const BODY := 12.0
## Skill id words → an area skill around the caster (SLAM); other damaging skills hit the target (STRIKE).
const SLAM_WORDS := ["slam", "shatter", "nova", "storm", "quake"]
## Skill id words → element when its status effects name none.
const ELEMENT_WORDS := [["frost", "ice"], ["chill", "ice"], ["poison", "poison"], ["acid", "poison"], ["spore", "poison"],
	["curse", "shadow"], ["drain", "shadow"], ["soul", "shadow"], ["necrotic", "shadow"], ["death", "shadow"],
	["grave", "shadow"], ["dark", "shadow"], ["thunder", "thunder"], ["fire", "fire"], ["burn", "fire"]]

static var _frames: Dictionary = {}

var kind := Kind.STRIKE
var element := "none"
var _time := 0.0


## Kind of a monster skill: damage (a shock wave for area skills), effects only (a spell), or self (an aura).
static func kind_for(skill: MonsterSkillDefinition) -> Kind:
	if skill.attack_ratio > 0.0:
		for word: String in SLAM_WORDS:
			if String(skill.id).contains(word):
				return Kind.SLAM
		return Kind.STRIKE
	return Kind.SPELL if not skill.target_effects.is_empty() else Kind.AURA


## Element of a monster skill: its status effects (ForgeLook), else words in its id.
static func element_for(skill: MonsterSkillDefinition) -> String:
	var from_effects := ForgeLook.element_for_effects([skill.target_effects, skill.self_effects])
	if from_effects != "none":
		return from_effects
	for pair: Array in ELEMENT_WORDS:
		if String(skill.id).contains(pair[0]):
			return pair[1]
	return "none"


## The baked frames of a kind in an element (shared).
static func frames_of(effect: Kind, el: String) -> Array:
	var key := "%d|%s" % [effect, el]
	if _frames.has(key):
		return _frames[key]
	var c := ForgeFx.colors(el)
	var frames: Array = []
	for i in FRAMES:
		var g := ForgeRenderer.new()
		var p := float(i) / (FRAMES - 1)
		var fade := 1.0 - p * 0.75
		var t := i * 1000.0 / FPS
		match effect:
			Kind.STRIKE:
				ForgeFx.burst(g, FEET.x, FEET.y - BODY, 2.5 + p * 4.0, c, fade)
				ForgeFx.particles(g, el, FEET.x, FEET.y - BODY, 4.0, 12, t, 5, c, fade)
			Kind.SLAM:
				var rx := 3.0 + p * 13.0
				ForgeFx.ring(g, FEET.x, FEET.y, rx, rx * 0.32, c[1], fade, 0.15)
				ForgeFx.ring(g, FEET.x, FEET.y, rx * 0.6, rx * 0.6 * 0.32, c[0], fade * 0.7)
				ForgeFx.particles(g, el, FEET.x, FEET.y - 3.0, 6.0, 10, t, 7, c, fade)
			Kind.SPELL:
				# The column grows (level 0), burns (1, 2), then fades away with its particles.
				var level := 0 if i < 2 else (1 if i < 4 else 2)
				ForgeFx.strike(g, el, FEET.x, level, (i + 1) / 2.0 if level == 0 else p, t, 9, c, fade)
				if i >= 2:
					ForgeFx.particles(g, el, FEET.x, FEET.y - 3.0, 5.0, 10, t, 9, c, fade)
			Kind.AURA:
				ForgeFx.glow(g, FEET.x, FEET.y - BODY, 2.0 + p * 5.0, c, fade * 0.8)
				ForgeFx.particles(g, el, FEET.x, FEET.y - 8.0, 6.0, 14, t, 3, c, fade)
		frames.append(ForgeFrame.bake(g))
	_frames[key] = frames
	return frames


## Whether a kind plays on the caster (area and self effects) rather than on its target.
static func on_caster(effect: Kind) -> bool:
	return effect == Kind.SLAM or effect == Kind.AURA


## Plays an effect at a world position under `parent`.
static func play(parent: Node, at: Vector2, effect: Kind, el: String) -> SkillEffect:
	var node := SkillEffect.new()
	node.kind = effect
	node.element = el
	node.z_index = Z
	parent.add_child(node)
	node.global_position = at
	return node


func _process(delta: float) -> void:
	var shown := floori(_time * FPS)
	_time += delta
	if _time * FPS >= FRAMES:
		queue_free()
		return
	if floori(_time * FPS) != shown:
		queue_redraw()


func _draw() -> void:
	var frames := frames_of(kind, element)
	var frame: ForgeFrame = frames[clampi(floori(_time * FPS), 0, frames.size() - 1)]
	frame.draw(self, Vector2.ZERO)
