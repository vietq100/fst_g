class_name DayNight
extends Node2D
## Day and night over the map (D77), from the in-game clock (ProgressService.day_time / day_length): a
## shade layer multiplies the world by the hour's tint (white by day, warm at dusk and dawn, blue at night),
## and a glow layer adds the warm light of lamps, camp fires, the shrine, the obelisk and the lighthouse as
## the night falls. Both are drawn once; only their modulate changes with the hour, so the cycle costs no
## redraw. Light sources join the `LIGHT_GROUP` group with metadata `light_radius` (px), optional
## `light_offset` (Vector2) and `light_color`. Presentation only.

const LIGHT_GROUP := &"night_lights"
## Above the actors, clouds and the sky layer; below skill effects, status icons and popups.
const SHADE_Z := 25
const GLOW_Z := 26
## The shade covers the world bounds and this much more (world px).
const SHADE_MARGIN := 900.0
## Hour (fraction of the day from dawn) → tint. Interpolated, wrapping from the last key to the first.
const TINTS := [
	[0.0, Color(1.0, 0.86, 0.8)],
	[0.08, Color.WHITE],
	[0.55, Color.WHITE],
	[0.64, Color(1.0, 0.74, 0.58)],
	[0.72, Color(0.42, 0.48, 0.72)],
	[0.92, Color(0.42, 0.48, 0.72)],
]
const DEFAULT_LIGHT := Color(1.0, 0.78, 0.42)
## Luminance of the tint at which lights are fully on (night) and off (day).
const NIGHT_LUMA := 0.5
const DAY_LUMA := 0.95

var _shade: Node2D
var _glow: Node2D
var _area := Rect2()


func setup(world: WorldService) -> void:
	_area = world.get_bounds(SHADE_MARGIN)
	_shade = _layer(SHADE_Z, CanvasItemMaterial.BLEND_MODE_MUL, _draw_shade)
	_glow = _layer(GLOW_Z, CanvasItemMaterial.BLEND_MODE_ADD, _draw_glow)
	# Light sources are spawned with the props: draw their glows once everything is in the tree.
	refresh_lights.call_deferred()
	_apply(_phase())


func _layer(z: int, blend: CanvasItemMaterial.BlendMode, painter: Callable) -> Node2D:
	var node := Node2D.new()
	node.z_index = z
	var blending := CanvasItemMaterial.new()
	blending.blend_mode = blend
	node.material = blending
	node.draw.connect(func() -> void: painter.call(node))
	add_child(node)
	return node


## Redraws the glows (a light source appeared, moved or was hidden).
func refresh_lights() -> void:
	if _glow != null:
		_glow.queue_redraw()


## The hour changes slowly: the tint is refreshed a few times a second, not every frame.
const REFRESH := 0.25
var _since := REFRESH


func _process(delta: float) -> void:
	_since += delta
	if _since >= REFRESH:
		_since = 0.0
		_apply(_phase())


## Fraction of the current day, 0 = dawn.
func _phase() -> float:
	return current_phase()


## Fraction of the current in-game day, 0 = dawn (noon when days are off).
static func current_phase() -> float:
	var length: float = DataRegistry.config.day_length_seconds
	return fposmod(GameManager.progress.day_time / length, 1.0) if length > 0.0 else 0.3


## Whether it is night now (lights more than half on).
static func is_night() -> bool:
	return night_of(tint_at(current_phase())) > 0.5


func _apply(phase: float) -> void:
	var tint := tint_at(phase)
	var night := night_of(tint)
	_shade.modulate = tint
	_glow.modulate = Color(1, 1, 1, night)
	# By day the shade is plain white and the glow invisible: skip the two full-screen blended passes.
	_shade.visible = not tint.is_equal_approx(Color.WHITE)
	_glow.visible = night > 0.01


## Tint of an hour (0..1 from dawn).
static func tint_at(phase: float) -> Color:
	var count := TINTS.size()
	for i in count:
		var key: Array = TINTS[i]
		var next: Array = TINTS[(i + 1) % count]
		var start: float = key[0]
		var end: float = next[0] if i + 1 < count else 1.0 + float(TINTS[0][0])
		if phase >= start and phase < end:
			return (key[1] as Color).lerp(next[1], (phase - start) / (end - start))
	return TINTS[0][1]


## 0 by day → 1 at full night, from the tint's brightness.
static func night_of(tint: Color) -> float:
	return clampf(inverse_lerp(DAY_LUMA, NIGHT_LUMA, tint.get_luminance()), 0.0, 1.0)


func _draw_shade(node: Node2D) -> void:
	node.draw_rect(_area, Color.WHITE)


func _draw_glow(node: Node2D) -> void:
	for source in get_tree().get_nodes_in_group(LIGHT_GROUP):
		var item := source as Node2D
		if item == null or not item.is_visible_in_tree():
			continue
		var radius: float = item.get_meta(&"light_radius", 24.0)
		var offset: Vector2 = item.get_meta(&"light_offset", Vector2.ZERO)
		var color: Color = item.get_meta(&"light_color", DEFAULT_LIGHT)
		var at := node.to_local(item.global_position) + offset
		# A soft disc: rings from the edge (faint) to the core (bright).
		for ring in 5:
			var k := 1.0 - ring / 5.0
			node.draw_circle(at, radius * k, Color(color, 0.09 + 0.05 * ring))
