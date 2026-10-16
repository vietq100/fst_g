class_name HunterPortrait
extends Control
## Hair, face and shoulders of the Hunter's Forge body (CHARACTER_DESIGN.md §9, D73): same look
## and outfit as the world sprite (ForgeLook.PORTRAIT crop of the standing figure), drawn at an integer
## scale over a backdrop lit in the Hunter's accent colour, inside a two-tone frame.

const BACKGROUND := Color("1d1814")

var accent := Color("8c3b3b")
var downed := false
var _figure: ForgeFrame


func _init() -> void:
	custom_minimum_size = Vector2(40, 40)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The figure is drawn whole: keep only the crop inside the frame.
	clip_contents = true
	# Stay square inside rows.
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


## `_equipment` is kept for callers; equipment is not shown on the portrait yet.
func setup(hunter: HunterRuntime, _equipment: EquipmentService) -> HunterPortrait:
	accent = PlaceholderVisual.ACCENT_PALETTE[posmod(hunter.accent_index, PlaceholderVisual.ACCENT_PALETTE.size())]
	var definition := DataRegistry.find_def(DataRegistry.HUNTER, hunter.definition_id) as HunterDefinition
	_figure = ForgeLook.figure(hunter.appearance, ChibiDress.plain(ChibiBody.outfit_for(definition)))
	downed = hunter.injured
	queue_redraw()
	return self


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, BACKGROUND)
	# Backdrop: accent-tinted vignette with a soft light behind the head.
	draw_rect(rect.grow(-2.0), accent.darkened(0.55))
	draw_circle(Vector2(size.x * 0.5, size.y * 0.42), minf(size.x, size.y) * 0.36, Color(accent.lightened(0.25), 0.35))
	draw_rect(Rect2(Vector2(2, size.y * 0.72), Vector2(size.x - 4, size.y * 0.28 - 2)), Color(0, 0, 0, 0.2))
	if _figure != null:
		var crop := ForgeLook.PORTRAIT
		var zoom := maxi(1, floori(minf(size.x / crop.size.x, size.y / crop.size.y)))
		var shown := crop.size * zoom
		# Bottom-aligned so the shoulders sit on the frame.
		var origin := Vector2(floorf((size.x - shown.x) * 0.5), size.y - shown.y - 2.0).floor()
		_figure.draw(self, origin - crop.position * zoom, false, zoom)
	draw_rect(rect, BACKGROUND, false, 2.0)
	draw_rect(rect.grow(-2.0), accent.lightened(0.1), false, 1.0)
	if downed:
		var center := size * 0.5
		var unit := size.y / 40.0
		draw_rect(rect, Color(0.1, 0.1, 0.12, 0.55))
		draw_line(center + Vector2(-6, -6) * unit, center + Vector2(6, 6) * unit, GameTheme.DANGER, 2.0)
		draw_line(center + Vector2(6, -6) * unit, center + Vector2(-6, 6) * unit, GameTheme.DANGER, 2.0)
