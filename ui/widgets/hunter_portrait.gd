class_name HunterPortrait
extends Control
## Placeholder portrait matching the world sprite (CHARACTER_DESIGN.md §9): same accent, armor
## tint and silhouette. Replace with portrait art later.

const SKIN := Color("e0b48c")
const OUTLINE := Color("16161c")
const BACKGROUND := Color("1d1814")

var accent := Color("8c3b3b")
var armor := Color("8f969e")
var downed := false


func _init() -> void:
	custom_minimum_size = Vector2(40, 40)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Stay square inside rows.
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


func setup(hunter: HunterRuntime, equipment: EquipmentService) -> HunterPortrait:
	accent = PlaceholderVisual.ACCENT_PALETTE[posmod(hunter.accent_index, PlaceholderVisual.ACCENT_PALETTE.size())]
	var item := equipment.get_equipped_item(hunter, &"armor") if equipment != null else null
	armor = item.tint if item != null else Color("8f969e")
	downed = hunter.injured
	queue_redraw()
	return self


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, BACKGROUND)
	draw_rect(rect, accent.darkened(0.2), false, 2.0)
	var center := size * 0.5
	var unit := size.y / 40.0
	# Shoulders / armor.
	var body := Rect2(center + Vector2(-11, 6) * unit, Vector2(22, 14) * unit)
	draw_rect(body.grow(unit), OUTLINE)
	draw_rect(body, armor)
	draw_rect(Rect2(body.position + Vector2(0, 4) * unit, Vector2(body.size.x, 3 * unit)), accent)
	# Head.
	var head := center + Vector2(0, -3) * unit
	draw_circle(head, 9 * unit, OUTLINE)
	draw_circle(head, 8 * unit, SKIN)
	draw_rect(Rect2(head + Vector2(-4, -1) * unit, Vector2(2, 2) * unit), OUTLINE)
	draw_rect(Rect2(head + Vector2(2, -1) * unit, Vector2(2, 2) * unit), OUTLINE)
	if downed:
		draw_rect(rect, Color(0.1, 0.1, 0.12, 0.55))
		draw_line(center + Vector2(-6, -6) * unit, center + Vector2(6, 6) * unit, GameTheme.DANGER, 2.0)
		draw_line(center + Vector2(6, -6) * unit, center + Vector2(-6, 6) * unit, GameTheme.DANGER, 2.0)
