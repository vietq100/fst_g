class_name StatusEffectView
extends Node2D
## Presentation of an actor's status effects (VFX_DESIGN.md → Status effects, D48):
## icon row with stacks and remaining time, a procedural aura per effect, a pulsing body tint,
## and floating text (effect name on apply, heals, absorbed damage). Gameplay never reads it.
## Origin is the actor's feet.

const ICON_SIZE := 9.0
const ICON_GAP := 2.0
## Icons sit this far above the head of a standard actor (bosses add their hit radius).
const ICON_Y := -48.0
const MAX_ICONS := 6
const ICON_OUTLINE := Color("16161c")
## Remaining-time fraction under which the icon blinks.
const EXPIRING_RATIO := 0.25
const TINT_STRENGTH := 0.5
const PULSE_SPEED := 5.0
## The same effect name is not shown again within this many seconds (on-hit spam).
const NAME_POPUP_COOLDOWN := 1.5
const NAME_FONT_SIZE := 9
const HEAL_COLOR := Color("7ee081")
const ABSORB_COLOR := Color("9fd8ff")
## Body centre of a standard actor, used by body-wide auras.
const BODY_Y := -14.0

var _actor: Actor
var _time := 0.0
## Effect id -> time of its last name popup.
var _last_popup: Dictionary[StringName, float] = {}


func bind(actor: Actor) -> void:
	_actor = actor
	z_index = 40
	actor.effects.effect_applied.connect(_on_effect_applied)
	actor.effects.effect_removed.connect(_on_effect_removed)
	actor.effects.shield_absorbed.connect(_on_shield_absorbed)
	actor.health.healed.connect(_on_healed)
	set_process(false)


func _process(delta: float) -> void:
	_time += delta
	_update_tint()
	queue_redraw()


func _draw() -> void:
	if _actor == null:
		return
	var effects: Array[StatusEffect] = _actor.effects.get_effects()
	var size: float = _actor.get_hit_radius()
	for effect in effects:
		_draw_aura(effect, size)
	_draw_icons(effects, ICON_Y - size * 1.5)


# --- Reactions -------------------------------------------------------------------------------


func _on_effect_applied(effect: StatusEffect) -> void:
	set_process(true)
	var id: StringName = effect.get_id()
	if _time - _last_popup.get(id, -INF) >= NAME_POPUP_COOLDOWN:
		_last_popup[id] = _time
		var text: String = effect.definition.display_name
		if effect.stacks > 1:
			text = Loc.t("world.popup.effect_stacks", {"name": text, "stacks": effect.stacks})
		_popup(text, effect.definition.color, NAME_FONT_SIZE, ICON_Y - 8.0)
	queue_redraw()


func _on_effect_removed(_effect: StatusEffect) -> void:
	if _actor.effects.get_effects().is_empty():
		set_process(false)
		_actor.visual.status_tint = Color.WHITE
	queue_redraw()


func _on_healed(amount: float) -> void:
	if amount >= 0.5:
		_popup("+%d" % roundi(amount), HEAL_COLOR, NAME_FONT_SIZE, -30.0)


func _on_shield_absorbed(amount: float) -> void:
	if amount >= 0.5:
		_popup("(%d)" % roundi(amount), ABSORB_COLOR, NAME_FONT_SIZE, -30.0)


## Floating text in the world (not attached to the actor, so it does not lunge with it).
func _popup(text: String, color: Color, font_size: int, height: float) -> void:
	var parent := _actor.get_parent()
	if parent == null:
		return
	var number := DamageNumber.new()
	parent.add_child(number)
	number.z_index = 100
	number.global_position = _actor.global_position + Vector2(randf_range(-4.0, 4.0), height)
	number.show_text(text, color, font_size)


## Latest tinting effect wins; the tint pulses so a coloured actor still reads as "affected".
func _update_tint() -> void:
	var tint := Color.WHITE
	for effect in _actor.effects.get_effects():
		if effect.definition.tints_actor:
			tint = effect.definition.color
	if tint == Color.WHITE:
		_actor.visual.status_tint = Color.WHITE
		return
	var pulse := 0.5 + 0.5 * sin(_time * PULSE_SPEED)
	_actor.visual.status_tint = Color.WHITE.lerp(tint, TINT_STRENGTH * (0.6 + 0.4 * pulse))


# --- Icons -----------------------------------------------------------------------------------


func _draw_icons(effects: Array[StatusEffect], top: float) -> void:
	var count := mini(effects.size(), MAX_ICONS)
	if count == 0:
		return
	var font := ThemeDB.fallback_font
	var width := count * ICON_SIZE + (count - 1) * ICON_GAP
	var x := -width * 0.5
	for index in count:
		var effect := effects[index]
		var definition: StatusEffectDefinition = effect.definition
		var ratio: float = effect.get_remaining_ratio()
		var alpha := 1.0
		if ratio < EXPIRING_RATIO and not effect.is_permanent():
			alpha = 0.45 + 0.55 * absf(sin(_time * 10.0))
		var rect := Rect2(x, top, ICON_SIZE, ICON_SIZE)
		draw_rect(rect.grow(1.0), Color(ICON_OUTLINE, alpha))
		draw_rect(rect, Color(definition.color.darkened(0.45), alpha))
		# Buffs get a light top edge, debuffs a dark bottom edge, so the two read apart.
		if definition.kind == StatusEffectDefinition.Kind.BUFF:
			draw_rect(Rect2(rect.position, Vector2(ICON_SIZE, 1.0)), Color(definition.color.lightened(0.4), alpha))
		# Two-letter glyphs use a smaller size so they fit the icon.
		var glyph_size := 7 if definition.icon.length() < 2 else 5
		var glyph_width := font.get_string_size(definition.icon, HORIZONTAL_ALIGNMENT_LEFT, -1, glyph_size).x
		draw_string(font, Vector2(x + (ICON_SIZE - glyph_width) * 0.5, top + 6.5 + (0.0 if glyph_size == 7 else -0.5)),
				definition.icon, HORIZONTAL_ALIGNMENT_LEFT, -1, glyph_size, Color(definition.color.lightened(0.5), alpha))
		if effect.stacks > 1:
			draw_string_outline(font, Vector2(x + 4.0, top + ICON_SIZE + 2.0), str(effect.stacks),
					HORIZONTAL_ALIGNMENT_RIGHT, 6.0, 6, 2, Color(ICON_OUTLINE, alpha))
			draw_string(font, Vector2(x + 4.0, top + ICON_SIZE + 2.0), str(effect.stacks),
					HORIZONTAL_ALIGNMENT_RIGHT, 6.0, 6, Color(1, 1, 1, alpha))
		# Remaining time (or shield left) as a bar under the icon.
		var fill := ratio
		if definition.shield > 0.0:
			fill = clampf(effect.shield / (definition.shield * effect.stacks), 0.0, 1.0)
		draw_rect(Rect2(x, top + ICON_SIZE + 1.0, ICON_SIZE * fill, 1.0), Color(definition.color.lightened(0.2), alpha))
		x += ICON_SIZE + ICON_GAP


# --- Auras -----------------------------------------------------------------------------------


func _draw_aura(effect: StatusEffect, size: float) -> void:
	var color: Color = effect.definition.color
	var scale_factor := 1.0 + size / 12.0
	match effect.definition.aura:
		StatusEffectDefinition.Aura.BUBBLES:
			_draw_bubbles(color, scale_factor)
		StatusEffectDefinition.Aura.FLAMES:
			_draw_flames(color, scale_factor)
		StatusEffectDefinition.Aura.DROPS:
			_draw_drops(color, scale_factor)
		StatusEffectDefinition.Aura.SPARKLES:
			_draw_sparkles(color, scale_factor)
		StatusEffectDefinition.Aura.STARS:
			_draw_stars(color, ICON_Y - size * 1.5 + 12.0)
		StatusEffectDefinition.Aura.ICE:
			_draw_ice(color, scale_factor)
		StatusEffectDefinition.Aura.ROOTS:
			_draw_roots(color, scale_factor)
		StatusEffectDefinition.Aura.ARROWS_UP:
			_draw_arrows(color, scale_factor, -1.0)
		StatusEffectDefinition.Aura.ARROWS_DOWN:
			_draw_arrows(color, scale_factor, 1.0)
		StatusEffectDefinition.Aura.SHIELD:
			_draw_shield(effect, scale_factor)
		StatusEffectDefinition.Aura.GLOW:
			_draw_glow(color, scale_factor)
		StatusEffectDefinition.Aura.SPIKES:
			_draw_spikes(color, scale_factor)
		StatusEffectDefinition.Aura.DRAIN:
			_draw_drain(color, scale_factor)
		StatusEffectDefinition.Aura.CROSS:
			_draw_cross(color, ICON_Y - size * 1.5 + 14.0)


## Fraction 0..1 of a looping particle `index` of `count`, moving at `speed` loops per second.
func _phase(index: int, count: int, speed: float) -> float:
	return fposmod(_time * speed + float(index) / count, 1.0)


func _draw_bubbles(color: Color, k: float) -> void:
	for i in 5:
		var p := _phase(i, 5, 0.6)
		var center := Vector2(sin(i * 2.1 + _time * 2.0) * 7.0 * k, (-4.0 - p * 30.0) * k)
		var radius := 1.2 + (i % 2) * 0.8
		draw_circle(center, radius + 0.6, Color(ICON_OUTLINE, 0.5 * (1.0 - p)))
		draw_circle(center, radius, Color(color, 0.85 * (1.0 - p)))


func _draw_flames(color: Color, k: float) -> void:
	for i in 7:
		var p := _phase(i, 7, 1.6)
		var base := Vector2(sin(i * 2.4 + p * 2.0) * 7.0 * k, (-2.0 - p * 24.0) * k)
		var flame_size := (1.0 - p) * 2.2 + 0.6
		var tip := base + Vector2(sin(_time * 9.0 + i) * 1.2, -flame_size * 2.0)
		var flame := PackedVector2Array([base + Vector2(-flame_size, 0), tip, base + Vector2(flame_size, 0)])
		var hot := Color("ffe36b").lerp(color, p)
		draw_colored_polygon(flame, Color(hot, 0.9 * (1.0 - p * 0.8)))


func _draw_drops(color: Color, k: float) -> void:
	for i in 3:
		var p := _phase(i, 3, 0.9)
		var center := Vector2((i - 1) * 5.0 * k, (-18.0 + p * 17.0) * k)
		var drop := Color(color, 1.0 - p * 0.7)
		draw_colored_polygon(PackedVector2Array([center + Vector2(-1.2, 0), center + Vector2(0, -2.5), center + Vector2(1.2, 0)]), drop)
		draw_circle(center, 1.3, drop)


func _draw_sparkles(color: Color, k: float) -> void:
	for i in 5:
		var p := _phase(i, 5, 0.5)
		var center := Vector2(sin(i * 1.7) * 9.0 * k, (-6.0 - p * 32.0) * k)
		var arm := 1.0 + 2.0 * (1.0 - absf(p - 0.5) * 2.0)
		var sparkle := Color(color.lightened(0.3), 1.0 - p * 0.6)
		draw_line(center + Vector2(-arm, 0), center + Vector2(arm, 0), sparkle, 1.0)
		draw_line(center + Vector2(0, -arm), center + Vector2(0, arm), sparkle, 1.0)


func _draw_stars(color: Color, height: float) -> void:
	for i in 3:
		var angle := _time * 4.0 + i * TAU / 3.0
		var center := Vector2(cos(angle) * 8.0, height + sin(angle) * 2.5)
		# Stars behind the head (top half of the orbit) are dimmer.
		var alpha := 0.55 if sin(angle) < 0.0 else 1.0
		_draw_star(center, 2.6, Color(color, alpha))


func _draw_star(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var r := radius if i % 2 == 0 else radius * 0.45
		points.append(center + Vector2.UP.rotated(i * TAU / 10.0) * r)
	draw_colored_polygon(points, color)


func _draw_ice(color: Color, k: float) -> void:
	draw_ellipse(Vector2(0, -1), 10.0 * k, 3.5 * k, Color(color, 0.35))
	draw_ellipse(Vector2(0, -1), 10.0 * k, 3.5 * k, Color(color.lightened(0.4), 0.8), false, 1.0)
	var crystals: Array[Vector2] = [Vector2(-8, -4), Vector2(7, -6), Vector2(-5, -20), Vector2(6, -16)]
	for i in crystals.size():
		var center := crystals[i] * k
		var shimmer := 0.55 + 0.45 * sin(_time * 3.0 + i * 1.3)
		var crystal := PackedVector2Array([center + Vector2(0, -3), center + Vector2(1.5, 0), center + Vector2(0, 3), center + Vector2(-1.5, 0)])
		draw_colored_polygon(crystal, Color(color.lightened(0.5), shimmer))


func _draw_roots(color: Color, k: float) -> void:
	draw_ellipse(Vector2(0, -1), 9.0 * k, 3.0 * k, Color(color, 0.8), false, 1.0)
	for i in 5:
		var x := (float(i) / 4.0 - 0.5) * 16.0 * k
		var height := (8.0 + (i % 2) * 4.0 + sin(_time * 2.0 + i) * 1.0) * k
		var mid := Vector2(x + (2.0 if i % 2 == 0 else -2.0), -height * 0.5)
		draw_polyline(PackedVector2Array([Vector2(x, 0), mid, Vector2(x * 0.6, -height)]), color, 1.5)


func _draw_arrows(color: Color, k: float, direction: float) -> void:
	for i in 3:
		var p := _phase(i, 3, 0.8)
		var y := BODY_Y * k + direction * (p - 0.5) * 26.0 * k
		var x := (i - 1) * 8.0 * k
		var tip := Vector2(x, y + direction * 2.0)
		var arrow := Color(color, 1.0 - absf(p - 0.5) * 1.6)
		draw_polyline(PackedVector2Array([Vector2(x - 2.5, y - direction * 1.0), tip, Vector2(x + 2.5, y - direction * 1.0)]), arrow, 1.5)


func _draw_shield(effect: StatusEffect, k: float) -> void:
	var color: Color = effect.definition.color
	var full: float = effect.definition.shield * effect.stacks
	var strength := clampf(effect.shield / full, 0.0, 1.0) if full > 0.0 else 1.0
	var center := Vector2(0, BODY_Y * k)
	var radii := Vector2(13.0, 21.0) * k
	draw_ellipse(center, radii.x, radii.y, Color(color, 0.12 + 0.08 * strength))
	draw_ellipse(center, radii.x, radii.y, Color(color.lightened(0.3), 0.35 + 0.5 * strength), false, 1.0)
	# Shimmer: a short highlight arc travelling around the bubble.
	var start := _time * 2.5
	var arc := PackedVector2Array()
	for i in 6:
		var angle := start + i * 0.12
		arc.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_polyline(arc, Color(1, 1, 1, 0.7 * strength), 1.0)


func _draw_glow(color: Color, k: float) -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 4.0)
	for ring in 2:
		var radius := (9.0 + ring * 4.0 + pulse * 2.0) * k
		draw_ellipse(Vector2(0, -1), radius, radius * 0.4, Color(color, (0.7 - ring * 0.3) * (0.6 + 0.4 * pulse)), false, 1.5)
	draw_rect(Rect2(-6.0 * k, -40.0 * k, 12.0 * k, 40.0 * k), Color(color, 0.08 + 0.06 * pulse))


func _draw_spikes(color: Color, k: float) -> void:
	var pulse := 1.0 + 0.25 * sin(_time * 6.0)
	for i in 8:
		var angle := i * TAU / 8.0 + 0.2
		var direction := Vector2(cos(angle), sin(angle) * 1.6)
		var base := Vector2(0, BODY_Y * k) + direction * 9.0 * k
		var side := direction.orthogonal().normalized() * 1.5
		var tip := base + direction.normalized() * 4.0 * pulse * k
		draw_colored_polygon(PackedVector2Array([base - side, tip, base + side]), Color(color, 0.9))


func _draw_drain(color: Color, k: float) -> void:
	for i in 4:
		var p := _phase(i, 4, 0.7)
		var angle := -_time * 3.0 + i * TAU / 4.0
		var radius := 16.0 * (1.0 - p) * k
		var center := Vector2(0, BODY_Y * k) + Vector2(cos(angle) * radius, sin(angle) * radius * 0.8)
		draw_circle(center, 1.6 * (1.0 - p * 0.5), Color(color, 0.9 * p + 0.1))


func _draw_cross(color: Color, height: float) -> void:
	var c := Vector2(0, height)
	draw_line(c + Vector2(-3, -3), c + Vector2(3, 3), ICON_OUTLINE, 3.0)
	draw_line(c + Vector2(3, -3), c + Vector2(-3, 3), ICON_OUTLINE, 3.0)
	draw_line(c + Vector2(-3, -3), c + Vector2(3, 3), color, 1.5)
	draw_line(c + Vector2(3, -3), c + Vector2(-3, 3), color, 1.5)
