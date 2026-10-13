@tool
extends Node2D
## Dark Forest pine (expedition map): three drooping tiers, lit left half, dark right half, the
## same look as the world map's pines (WorldProp). Origin at the trunk base.

const OUTLINE := Color("10140f")
const TRUNK := Color("5a3f2a")

@export var canopy_color := Color("23452b"):
	set(value):
		canopy_color = value
		queue_redraw()
@export var size := 1.0:
	set(value):
		size = value
		queue_redraw()


func _draw() -> void:
	draw_ellipse(Vector2(2.0 * size, 0.0), 12.0 * size, 4.5 * size, Color(0, 0, 0, 0.35))
	var trunk := _scaled([Vector2(-4, 0), Vector2(-2.5, -2), Vector2(-2, -9), Vector2(2, -9), Vector2(2.5, -2), Vector2(4, 0)])
	draw_colored_polygon(BuildingVisual._grow(trunk, 1.0), OUTLINE)
	draw_colored_polygon(trunk, TRUNK)
	draw_line(Vector2(1.0, -1.0) * size, Vector2(1.0, -8.0) * size, TRUNK.darkened(0.35), 1.0)
	for tier: Array in [[-7.0, 12.0, 15.0], [-16.0, 9.5, 14.0], [-25.0, 6.5, 13.0]]:
		var base: float = tier[0]
		var half: float = tier[1]
		var height: float = tier[2]
		var outline := _scaled([Vector2(-half, base), Vector2(0, base + 2.0), Vector2(half, base), Vector2(0, base - height)])
		draw_colored_polygon(BuildingVisual._grow(outline, 1.0), OUTLINE)
		draw_colored_polygon(_scaled([Vector2(0, base + 2.0), Vector2(half, base), Vector2(0, base - height)]), canopy_color.darkened(0.3))
		draw_colored_polygon(_scaled([Vector2(-half, base), Vector2(0, base + 2.0), Vector2(0, base - height)]), canopy_color)
		draw_line(Vector2(-half * 0.55, base - height * 0.3) * size, Vector2(-1.0, base - height * 0.75) * size, canopy_color.lightened(0.18), 1.0)


func _scaled(points: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point: Vector2 in points:
		result.append(point * size)
	return result
