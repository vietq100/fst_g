class_name WaterShimmer
extends Node2D
## Twinkling glints on the water around the plateaus (WORLD_DESIGN.md → Biome identity): a fixed
## set of points outside every region and bridge, each blinking on its own phase. Redrawn at a
## low rate; the static waves are part of the ground. Presentation only.

const FPS := 8.0
const COUNT := 90
const GLINT := Color(0.85, 0.97, 1.0)

var _points: Array[Vector2] = []
var _time := 0.0
var _frame_time := 0.0


func setup(world: WorldService) -> void:
	var area := world.get_bounds(WorldScenery.MARGIN)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var tries := 0
	while _points.size() < COUNT and tries < COUNT * 20:
		tries += 1
		var point := area.position + Vector2(rng.randf() * area.size.x, rng.randf() * area.size.y)
		if world.region_at(point) != null:
			continue
		var on_bridge := false
		for gate in world.get_gates():
			if WorldService.rect_to_world(gate.tiles.grow(1)).has_point(point):
				on_bridge = true
				break
		if not on_bridge:
			_points.append(point)


func _process(delta: float) -> void:
	_time += delta
	_frame_time += delta
	if _frame_time >= 1.0 / FPS:
		_frame_time -= 1.0 / FPS
		queue_redraw()


func _draw() -> void:
	for i in _points.size():
		var phase := _time * 1.6 + i * 0.7
		var alpha := maxf(sin(phase), 0.0)
		if alpha < 0.15:
			continue
		var at := _points[i] + Vector2(fmod(_time * 4.0 + i * 3.0, 12.0) - 6.0, 0)
		var width := 2.0 + alpha * 4.0
		draw_line(at + Vector2(-width, 0), at + Vector2(width, 0), Color(GLINT, alpha * 0.55), 1.0)
		if alpha > 0.7:
			draw_line(at + Vector2(0, -1.5), at + Vector2(0, 1.5), Color(GLINT, (alpha - 0.7) * 1.5), 1.0)
