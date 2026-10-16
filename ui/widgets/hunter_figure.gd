class_name HunterFigure
extends Control
## The Hunter's whole Forge figure with its gear and pet (D59, D73), as in the reference game's Hunter
## cards and detail panel: drawn at the largest integer scale that fits, feet on a lit floor
## ellipse over a soft glow in the Hunter's accent colour. Downed / dead Hunters are greyed out.

const PET_GAP := 2.0

var accent := Color("8c3b3b")
var downed := false
## Draw the glow and floor (off inside dark panels that have their own backdrop).
var backdrop := true
var _figure: ForgeFrame
var _pet: Texture2D


func _init() -> void:
	custom_minimum_size = Vector2(48, 72)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


## `equipment` null = the plain class outfit (Tavern / gate candidates have no gear). `look` shows another
## appearance in the same gear (the barber's preview, D77).
func setup(hunter: HunterRuntime, equipment: EquipmentService, look: HunterAppearance = null) -> HunterFigure:
	accent = PlaceholderVisual.ACCENT_PALETTE[posmod(hunter.accent_index, PlaceholderVisual.ACCENT_PALETTE.size())]
	var definition := DataRegistry.find_def(DataRegistry.HUNTER, hunter.definition_id) as HunterDefinition
	var dress := equipment.get_dress(hunter) if equipment != null and hunter.unique_id != &"" \
		else ChibiDress.plain(ChibiBody.outfit_for(definition))
	_figure = ForgeLook.figure(look if look != null else hunter.appearance, dress)
	_pet = PetSprites.texture(dress.pet, dress.pet_tint) if dress.pet != &"" else null
	downed = hunter.injured or not hunter.alive
	queue_redraw()
	return self


func _draw() -> void:
	if _figure == null:
		return
	var rect := _figure.get_rect()
	var source := rect.size
	var pet_size := Vector2(PetSprites.SIZE) if _pet != null else Vector2.ZERO
	# The pet stands beside the feet; leave room for it on the left.
	var needed := Vector2(source.x + (pet_size.x * 0.75 + PET_GAP if _pet != null else 0.0), source.y)
	var zoom := maxi(1, floori(minf(size.x / needed.x, size.y / needed.y)))
	var shown := source * zoom
	var floor_y := size.y - 2.0 * zoom
	var left := floorf((size.x - needed.x * zoom) * 0.5 + (needed.x - source.x) * zoom)
	if backdrop:
		draw_circle(Vector2(left + shown.x * 0.5, floor_y - shown.y * 0.45), shown.x * 0.75, Color(accent.lightened(0.3), 0.22))
		draw_set_transform(Vector2(left + shown.x * 0.5, floor_y), 0.0, Vector2(1.0, 0.32))
		draw_circle(Vector2.ZERO, shown.x * 0.55, Color(0, 0, 0, 0.35))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var tint := Color(0.55, 0.55, 0.6, 0.85) if downed else Color.WHITE
	if _pet != null:
		# A little smaller than the Hunter on big figures, like a pet at its owner's heels.
		var pet_zoom := maxi(1, roundi(zoom * 0.7)) if zoom >= 3 else zoom
		var pet_shown := pet_size * pet_zoom
		draw_texture_rect(_pet, Rect2(Vector2(left - pet_shown.x * 0.7 - PET_GAP * zoom, floor_y - pet_shown.y + zoom), pet_shown), false, tint)
	_figure.draw(self, Vector2(left, floor_y - shown.y + zoom) - rect.position * zoom, false, zoom, 0.0, tint)
