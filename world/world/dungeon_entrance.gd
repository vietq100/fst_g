class_name DungeonEntrance
extends Node2D
## A dungeon entrance on a region edge (D35): dark doorway in a stone frame with a name plate.
## Locked entrances are greyed out.

const OUTLINE := Color("16161c")
const STONE := Color("6d7068")
const GLOW := Color(0.55, 0.85, 1.0, 0.45)

var expedition_id: StringName
var title := ""
var locked := false


func setup(definition: ExpeditionDefinition) -> void:
	expedition_id = definition.id
	title = definition.display_name
	locked = definition.locked
	position = WorldService.tile_center(definition.entrance_tile)
	queue_redraw()


func hit_test(world_point: Vector2) -> bool:
	return Rect2(global_position + Vector2(-28, -52), Vector2(56, 60)).has_point(world_point)


## Where a party stands before entering (one tile towards the region).
func get_approach_point(region_center: Vector2) -> Vector2:
	return global_position + (region_center - global_position).normalized() * 40.0


func _draw() -> void:
	draw_ellipse(Vector2.ZERO, 26, 10, Color(0, 0, 0, 0.35))
	var frame := PackedVector2Array([Vector2(-22, 0), Vector2(-22, -30), Vector2(-12, -42), Vector2(12, -42), Vector2(22, -30), Vector2(22, 0)])
	draw_colored_polygon(IsoBuildingVisual._grow(frame, 1.5), OUTLINE)
	draw_colored_polygon(frame, STONE.darkened(0.3) if locked else STONE)
	var door := PackedVector2Array([Vector2(-12, 0), Vector2(-12, -26), Vector2(-6, -32), Vector2(6, -32), Vector2(12, -26), Vector2(12, 0)])
	draw_colored_polygon(door, Color("0b0b10"))
	if not locked:
		draw_circle(Vector2(0, -16), 9.0, GLOW)
	else:
		draw_line(Vector2(-10, -24), Vector2(10, -4), Color("8a3a2e"), 3.0)
		draw_line(Vector2(10, -24), Vector2(-10, -4), Color("8a3a2e"), 3.0)
	var font := ThemeDB.fallback_font
	var text := title + (" (locked)" if locked else "")
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
	var at := Vector2(-size.x * 0.5, -48)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, OUTLINE)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("9aa3ad") if locked else Color("bfe3ff"))
