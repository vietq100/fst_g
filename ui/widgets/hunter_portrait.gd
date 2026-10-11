class_name HunterPortrait
extends Control
## Head and shoulders of the Hunter's chibi body (CHARACTER_DESIGN.md §9, D49): same skin and
## dye as the world sprite, drawn at an integer scale.

const BACKGROUND := Color("1d1814")

var accent := Color("8c3b3b")
var downed := false
var _texture: Texture2D


func _init() -> void:
	custom_minimum_size = Vector2(40, 40)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Stay square inside rows.
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


## `_equipment` is kept for callers; equipment is not shown on the portrait yet.
func setup(hunter: HunterRuntime, _equipment: EquipmentService) -> HunterPortrait:
	accent = PlaceholderVisual.ACCENT_PALETTE[posmod(hunter.accent_index, PlaceholderVisual.ACCENT_PALETTE.size())]
	_texture = ChibiBody.get_portrait(hunter.appearance)
	downed = hunter.injured
	queue_redraw()
	return self


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, BACKGROUND)
	if _texture != null:
		var source := _texture.get_size()
		var zoom := maxi(1, floori(minf(size.x / source.x, size.y / source.y)))
		var shown := source * zoom
		# Bottom-aligned so the shoulders sit on the frame.
		var origin := Vector2(floorf((size.x - shown.x) * 0.5), size.y - shown.y - 2.0).floor()
		draw_texture_rect(_texture, Rect2(origin, shown), false)
	draw_rect(rect, accent.darkened(0.2), false, 2.0)
	if downed:
		var center := size * 0.5
		var unit := size.y / 40.0
		draw_rect(rect, Color(0.1, 0.1, 0.12, 0.55))
		draw_line(center + Vector2(-6, -6) * unit, center + Vector2(6, 6) * unit, GameTheme.DANGER, 2.0)
		draw_line(center + Vector2(6, -6) * unit, center + Vector2(-6, 6) * unit, GameTheme.DANGER, 2.0)
