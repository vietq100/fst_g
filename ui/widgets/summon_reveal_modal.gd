class_name SummonRevealModal
extends Control
## The summoning reveal (D83), over everything: no dialog, just big cards in the middle of the
## dimmed screen (one cover on top, then one card per newcomer, face up but dimmed). Drag the top
## card any way; let go early and it eases back; drag far enough (REVEAL_RATIO of the card) and it
## flies off while the card beneath flashes in its tier's colour and shows fully; once the last card
## is open, Skip gives way to Done. Skip jumps to the summary: every card, tap one for its full
## card. Done or Confirm lets them down at the Gate in order
## (RecruitmentService.confirm_arrivals, done by UIRoot when this closes, confirmed or not).

signal confirmed

const CARD_SIZE := Vector2(250, 360)
## Share of the card's height the top card must travel to reveal the one beneath.
const REVEAL_RATIO := 0.8
## Easing back after a short drag (slow, so the hand can change its mind).
const RETURN_TIME := 0.6
const FLY_TIME := 0.35
const STACK_OFFSET := Vector2(3, 3)
const DIM := Color(0.42, 0.42, 0.5)

var _hunters: Array[HunterRuntime] = []
var _effects := true
var _body: VBoxContainer
var _stage: Control
var _cards: Array[SummonCard] = []
## Index into _cards of the draggable top card (0 = the cover).
var _top := 0
var _dragging := false
var _drag_start := Vector2.ZERO
var _card_home := Vector2.ZERO
var _return_tween: Tween
var _confirmed := false
## Under the stack: the swipe hint and Skip, swapped for Done once the last card is open.
var _stack_controls: Array[Control] = []


func setup(hunters: Array[HunterRuntime], with_effects: bool) -> SummonRevealModal:
	_hunters = hunters
	_effects = with_effects and not hunters.is_empty()
	return self


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Above the top-left notices and toasts (z 5 in UIRoot), which otherwise draw over the card.
	z_index = 10
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	dim.modulate.a = 0.0
	dim.create_tween().tween_property(dim, ^"modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_body = UIKit.vbox([], 12)
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_body)
	if _effects:
		_show_stack()
	else:
		_show_summary()


func _exit_tree() -> void:
	if not _confirmed:
		# Closed any other way: the newcomers still come (tickets are spent).
		_confirmed = true
		confirmed.emit()


func _clear_body() -> void:
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()


## Big cream title with a dark outline, straight on the dimmed screen.
func _title(text: String) -> Label:
	var label := UIKit.label(text, &"", false)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(&"font_size", 20)
	label.add_theme_color_override(&"font_color", ItemInfoModal.CREAM)
	label.add_theme_color_override(&"font_outline_color", GameTheme.INK)
	label.add_theme_constant_override(&"outline_size", 5)
	return label


func _hint(text: String) -> Label:
	var hint := UIKit.label(text, &"MutedLabel", false)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return hint


func _plain_button(text: String, action: Callable) -> Button:
	var button := UIKit.button(text, action, &"")
	button.custom_minimum_size = Vector2(130, GameTheme.TOUCH)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ItemInfoModal._style_button(button, ItemInfoModal.BUTTON, ItemInfoModal.FRAME_RIM.darkened(0.2))
	return button


func _go_button(text: String, action: Callable) -> Button:
	var button := UIKit.button(text, action, &"PrimaryButton")
	button.custom_minimum_size = Vector2(170, 46)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override(&"font_size", 16)
	ItemInfoModal._style_button(button, Color("2f5a2a"), ItemInfoModal.GOLD.darkened(0.3))
	return button


# --- The stack ------------------------------------------------------------------------------------

func _show_stack() -> void:
	_clear_body()
	_stage = Control.new()
	_stage.custom_minimum_size = CARD_SIZE + STACK_OFFSET * _hunters.size() + Vector2(24, 24)
	_stage.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_stage.mouse_filter = Control.MOUSE_FILTER_STOP
	_stage.gui_input.connect(_on_stage_input)
	_body.add_child(_stage)
	_cards.clear()
	# Bottom of the stack first (the last newcomer), the cover last so it draws on top.
	var origin := Vector2(12, 12)
	for i in range(_hunters.size() - 1, -1, -1):
		var card := SummonCard.new().setup(_hunters[i], false)
		card.position = origin + STACK_OFFSET * i
		card.modulate = DIM
		_stage.add_child(card)
		_cards.push_front(card)
	var cover := SummonCard.new().setup(null, true)
	cover.position = origin
	_stage.add_child(cover)
	_cards.push_front(cover)
	_top = 0
	_card_home = cover.position
	_stack_controls = [_hint(Loc.t("ui.summon.swipe_hint")), _plain_button(Loc.t("ui.summon.skip"), _show_summary)]
	for control in _stack_controls:
		_body.add_child(control)


func _top_card() -> SummonCard:
	return _cards[_top] if _top >= 0 and _top < _cards.size() else null


## Cards under the top one can still be revealed while one lies beneath the top card.
func _can_drag() -> bool:
	return _top_card() != null and _top + 1 < _cards.size()


func _on_stage_input(event: InputEvent) -> void:
	if not _can_drag():
		return
	var top := _top_card()
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pressed: bool = event.pressed
		var at: Vector2 = event.position
		if pressed and not _dragging and top.get_rect().has_point(at):
			if _return_tween != null:
				_return_tween.kill()
			_dragging = true
			_drag_start = at - top.position
			_stage.accept_event()
		elif not pressed and _dragging:
			_dragging = false
			_release(top)
			_stage.accept_event()
	elif (event is InputEventScreenDrag or event is InputEventMouseMotion) and _dragging:
		top.position = event.position - _drag_start
		# A little tilt the way it is dragged; the card beneath brightens as the top one slides off.
		top.rotation = clampf((top.position.x - _card_home.x) / CARD_SIZE.x, -1.0, 1.0) * 0.18
		var ratio := _reveal_ratio(top)
		_cards[_top + 1].modulate = DIM.lerp(Color.WHITE, clampf(ratio * 0.6, 0.0, 0.6))
		_stage.accept_event()


func _reveal_ratio(top: SummonCard) -> float:
	var offset := top.position - _card_home
	return maxf(absf(offset.x) / CARD_SIZE.x, absf(offset.y) / CARD_SIZE.y) / REVEAL_RATIO


func _release(top: SummonCard) -> void:
	if _reveal_ratio(top) < 1.0:
		# Not far enough: ease back, slowly.
		_return_tween = create_tween().set_parallel()
		_return_tween.tween_property(top, ^"position", _card_home, RETURN_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		_return_tween.tween_property(top, ^"rotation", 0.0, RETURN_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		_cards[_top + 1].modulate = DIM
		return
	# Flies off the way it was dragged and fades; the card beneath is revealed.
	var direction := (top.position - _card_home).normalized()
	var fly := create_tween().set_parallel()
	fly.tween_property(top, ^"position", top.position + direction * 520.0, FLY_TIME).set_ease(Tween.EASE_IN)
	fly.tween_property(top, ^"rotation", top.rotation * 2.5, FLY_TIME)
	fly.tween_property(top, ^"modulate:a", 0.0, FLY_TIME)
	fly.chain().tween_callback(top.queue_free)
	_top += 1
	var revealed := _cards[_top]
	_card_home = revealed.position
	revealed.reveal()
	_check_last_card()


func _check_last_card() -> void:
	if not _can_drag():
		# The last card is open: nothing left to skip, Done lets them in.
		for control in _stack_controls:
			if is_instance_valid(control):
				control.queue_free()
		_stack_controls.clear()
		_body.add_child(_go_button(Loc.t("ui.summon.finish"), _finish))


# --- The summary -----------------------------------------------------------------------------------

func _show_summary() -> void:
	_dragging = false
	_clear_body()
	_body.add_child(_title(Loc.t("ui.summon.summary_title", {"count": _hunters.size()})))
	var grid := GridContainer.new()
	grid.columns = 5 if _hunters.size() > 5 else maxi(_hunters.size(), 1)
	grid.add_theme_constant_override(&"h_separation", 6)
	grid.add_theme_constant_override(&"v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for hunter in _hunters:
		grid.add_child(_summary_tile(hunter))
	_body.add_child(grid)
	_body.add_child(_hint(Loc.t("ui.summon.tap_detail")))
	_body.add_child(_go_button(Loc.t("ui.summon.confirm"), _finish))


func _finish() -> void:
	_confirmed = true
	confirmed.emit()
	queue_free()


## A small card: figure over a tier-coloured plate, name, tier code; tapping opens its full card.
func _summary_tile(hunter: HunterRuntime) -> Control:
	var color := Tier.color(hunter.tier)
	var tile := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = SummonCard.PLATE
	box.border_color = color.darkened(0.15)
	box.set_border_width_all(2)
	box.set_corner_radius_all(4)
	box.content_margin_left = 3
	box.content_margin_right = 3
	box.content_margin_top = 3
	box.content_margin_bottom = 3
	box.shadow_color = Color(color, 0.25)
	box.shadow_size = 3
	tile.add_theme_stylebox_override(&"panel", box)
	tile.custom_minimum_size = Vector2(60, 98)
	tile.mouse_filter = Control.MOUSE_FILTER_STOP
	var figure := HunterFigure.new().setup(hunter, null)
	figure.custom_minimum_size = Vector2(50, 60)
	figure.accent = color
	var name_label := UIKit.label(hunter.display_name, &"HudSmallLabel", false)
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var code := UIKit.label(Tier.code(hunter.tier), &"HudSmallLabel", false)
	code.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	code.add_theme_color_override(&"font_color", color)
	tile.add_child(UIKit.vbox([figure, name_label, code], 1))
	tile.gui_input.connect(func(event: InputEvent) -> void:
		if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
			tile.accept_event()
			_show_detail(hunter))
	return tile


## One newcomer in full: its big card (figure, tier, class and level, grade, stats, fate), then
## traits and talent under it.
func _show_detail(hunter: HunterRuntime) -> void:
	_clear_body()
	var gm := GameManager
	var holder := Control.new()
	holder.custom_minimum_size = CARD_SIZE
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(SummonCard.new().setup(hunter, false))
	_body.add_child(holder)
	var traits := PackedStringArray()
	for trait_def in gm.traits.get_traits(hunter):
		traits.append(trait_def.display_name)
	var talent := gm.talents.get_talent(hunter)
	for text: String in [Loc.t("ui.summon.traits", {"traits": ", ".join(traits) if not traits.is_empty() else "—"}),
			Loc.t("ui.summon.talent", {"talent": talent.display_name}) if talent != null else Loc.t("ui.summon.no_talent")]:
		var line := UIKit.label(text, &"MutedLabel")
		line.custom_minimum_size.x = CARD_SIZE.x
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_body.add_child(line)
	_body.add_child(_plain_button(Loc.t("ui.summon.back"), _show_summary))


# --- A card --------------------------------------------------------------------------------------

## One card: a tier-framed plate with the newcomer's tier gem, name, figure over a glowing window
## (rays and a passing shine from SR up), tier stars, class and level, grade, graded stats and
## where it goes — or the cover (the Gate's emblem on a starry navy plate). `reveal` flashes it in
## its tier colour and pops it.
class SummonCard extends Control:
	const OUTLINE := Color("0b0d12")
	const PLATE := Color("15141d")
	const COVER := Color("232a4a")
	const COVER_DEEP := Color("10132a")
	const COVER_TRIM := Color("e2c46b")
	const TEXT := Color("f4f1ea")
	const SOFT := Color("c9bfa8")
	const ART := Rect2(14, 56, 222, 176)
	const SHINE_PERIOD := 3.4

	var hunter: HunterRuntime
	var is_cover := false
	var _flash := 0.0
	var _time := 0.0
	## SR and up (and the cover) keep moving: rays, shine, a pulsing emblem.
	var _animated := false
	var _color := COVER_TRIM
	var _class_line := ""
	var _grade_text := ""
	var _grade_color := Color.WHITE
	## [[label, value, colour], …] for HP, attack, defense, attack speed.
	var _stats: Array = []

	func setup(newcomer: HunterRuntime, cover: bool) -> SummonCard:
		hunter = newcomer
		is_cover = cover
		custom_minimum_size = SummonRevealModal.CARD_SIZE
		size = SummonRevealModal.CARD_SIZE
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		pivot_offset = SummonRevealModal.CARD_SIZE * 0.5
		_animated = cover
		if hunter == null:
			return self
		var gm := GameManager
		_color = Tier.color(hunter.tier)
		_animated = hunter.tier >= Tier.Level.SR
		var definition := gm.hunters.get_definition(hunter)
		_class_line = Loc.t("ui.common.level_class", {"level": hunter.level, "class": definition.display_name if definition != null else "?"})
		var grade := gm.grades.hunter_grade(hunter)
		_grade_text = Loc.t("ui.common.grade", {"grade": StatGradeService.name_of(grade)})
		_grade_color = StatGradeService.color(grade)
		for stat: StringName in [HunterService.MAX_HP, HunterService.ATTACK, HunterService.DEFENSE, HunterService.ATTACK_SPEED]:
			var value := gm.hunters.get_stat(hunter, stat)
			_stats.append([Loc.t("stat.%s" % stat), ("%.2f" % value) if stat == HunterService.ATTACK_SPEED else ("%d" % roundi(value)),
				StatGradeService.color(gm.grades.hunter_step(hunter, stat))])
		var figure := HunterFigure.new().setup(hunter, null)
		figure.accent = _color
		figure.position = ART.position + Vector2(8, 8)
		figure.size = ART.size - Vector2(16, 20)
		figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(figure)
		return self

	func reveal() -> void:
		modulate = Color.WHITE
		_flash = 1.0
		var tween := create_tween()
		tween.tween_property(self, ^"scale", Vector2(1.08, 1.08), 0.12).from(Vector2(0.92, 0.92)).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, ^"scale", Vector2.ONE, 0.18).set_ease(Tween.EASE_IN_OUT)
		tween.parallel().tween_property(self, ^"_flash", 0.0, 0.7)
		tween.tween_callback(queue_redraw)

	func _process(delta: float) -> void:
		_time += delta
		if _flash > 0.0 or _animated:
			queue_redraw()

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var rim := _color if hunter != null else COVER_TRIM
		if _flash > 0.0:
			# A soft halo behind the card, spreading as it fades.
			var spread := 10.0 + 16.0 * (1.0 - _flash)
			for i in 8:
				draw_rect(rect.grow(spread * (1.0 - i / 8.0)), Color(rim.lightened(0.25), 0.24 * _flash))
		# Shadow, dark outline, the tier rim with a light top edge, then the plate inside.
		draw_rect(Rect2(Vector2(4, 7), size), Color(0, 0, 0, 0.45))
		draw_rect(rect.grow(2.0), OUTLINE)
		_gradient(rect, rim.lightened(0.15), rim.darkened(0.45))
		draw_line(Vector2(3, 1.5), Vector2(size.x - 3, 1.5), Color(rim.lightened(0.6), 0.8), 1.0)
		var plate := rect.grow(-6.0)
		draw_rect(plate.grow(1.0), OUTLINE)
		if is_cover:
			_draw_cover(plate)
		else:
			_draw_face(plate)
		if _flash > 0.0:
			draw_rect(rect, Color(rim.lightened(0.45), 0.45 * _flash))

	# --- The face ---

	func _draw_face(plate: Rect2) -> void:
		var font := ThemeDB.fallback_font
		_gradient(plate, _color.darkened(0.72), PLATE)
		# Header: tier gem on the left, the name in the rest of the band.
		var band := Rect2(plate.position, Vector2(plate.size.x, 44))
		_gradient(band, Color(_color, 0.28), Color(_color, 0.04))
		draw_line(Vector2(plate.position.x, band.end.y), Vector2(plate.end.x, band.end.y), Color(_color, 0.6), 1.0)
		var gem := Vector2(32, 30)
		draw_circle(gem, 21.0, OUTLINE)
		draw_circle(gem, 19.0, _color.darkened(0.25))
		draw_circle(gem, 15.5, _color)
		draw_arc(gem, 12.5, PI * 1.1, PI * 1.6, 8, Color(1, 1, 1, 0.55), 2.0)
		var code := Tier.code(hunter.tier)
		_text(font, code, gem.x, gem.y + 5.0, _fit(font, code, 15, 28.0), OUTLINE, Color.TRANSPARENT)
		var name_left := 58.0
		var name_width := plate.end.x - 6.0 - name_left
		_text(font, hunter.display_name, name_left + name_width * 0.5, 36.0, _fit(font, hunter.display_name, 19, name_width), TEXT, OUTLINE)
		# The figure's window: tier glow, rays from SR up, a thin frame with gold corner ticks.
		draw_rect(ART, Color(0, 0, 0, 0.35))
		var centre := ART.get_center() + Vector2(0, 8)
		if _animated:
			for i in 14:
				var angle := _time * 0.35 + i * TAU / 14.0
				var points := PackedVector2Array([centre, centre + Vector2.from_angle(angle - 0.08) * 86.0, centre + Vector2.from_angle(angle + 0.08) * 86.0])
				draw_polygon(points, PackedColorArray([Color(_color, 0.3), Color(_color, 0.0), Color(_color, 0.0)]))
		for i in 8:
			draw_circle(centre, 84.0 * (1.0 - i / 8.0), Color(_color.lightened(0.2), 0.045))
		draw_rect(ART, Color(_color, 0.75), false, 1.0)
		for corner: Vector2 in [ART.position, Vector2(ART.end.x, ART.position.y), Vector2(ART.position.x, ART.end.y), ART.end]:
			var sx := 1.0 if corner.x < size.x * 0.5 else -1.0
			var sy := 1.0 if corner.y < size.y * 0.5 else -1.0
			draw_line(corner, corner + Vector2(10 * sx, 0), ItemInfoModal.GOLD, 2.0)
			draw_line(corner, corner + Vector2(0, 10 * sy), ItemInfoModal.GOLD, 2.0)
		# One star per tier step, astride the window's bottom edge.
		var stars := Tier.clamp_level(hunter.tier) + 1
		for i in stars:
			_star(Vector2(size.x * 0.5 + (i - (stars - 1) * 0.5) * 15.0, ART.end.y), 7.0, _color)
		# Class and level, grade, then the four stats in two columns over a dark strip.
		_text(font, _class_line, size.x * 0.5, 262.0, _fit(font, _class_line, 14, plate.size.x - 16.0), TEXT, OUTLINE)
		_text(font, _grade_text, size.x * 0.5, 280.0, 12, _grade_color, OUTLINE)
		var strip := Rect2(plate.position.x + 8, 288, plate.size.x - 16, 44)
		draw_rect(strip, Color(0, 0, 0, 0.3))
		draw_line(Vector2(strip.get_center().x, strip.position.y + 5), Vector2(strip.get_center().x, strip.end.y - 5), Color(_color, 0.3), 1.0)
		for i in _stats.size():
			var cell := Rect2(strip.position + Vector2((i % 2) * strip.size.x * 0.5 + 8, floori(i / 2.0) * 20 + 15), Vector2(strip.size.x * 0.5 - 16, 0))
			var label: String = _stats[i][0]
			var value: String = _stats[i][1]
			draw_string(font, cell.position, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, SOFT)
			var value_width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			draw_string_outline(font, Vector2(cell.end.x - value_width, cell.position.y + 1), value, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 3, OUTLINE)
			draw_string(font, Vector2(cell.end.x - value_width, cell.position.y + 1), value, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, _stats[i][2])
		var fate := Loc.t("ui.gate.went_asleep" if hunter.hibernating else "ui.gate.went_village")
		_text(font, fate, size.x * 0.5, plate.end.y - 7.0, _fit(font, fate, 11, plate.size.x - 16.0), Color("8fb3ff") if hunter.hibernating else GameTheme.GOOD, OUTLINE)
		if _animated:
			_shine(plate)

	## A light band sweeping across the plate now and then (SR and up).
	func _shine(plate: Rect2) -> void:
		var travel := plate.size.x + plate.size.y * 0.5 + 60.0
		var at := fmod(_time, SHINE_PERIOD) / SHINE_PERIOD * travel * 1.6 - plate.size.y * 0.5 - 30.0
		if at > plate.end.x:
			return
		var band := PackedVector2Array([Vector2(at, plate.position.y), Vector2(at + 26.0, plate.position.y),
			Vector2(at + 26.0 + plate.size.y * 0.5, plate.end.y), Vector2(at + plate.size.y * 0.5, plate.end.y)])
		var bounds := PackedVector2Array([plate.position, Vector2(plate.end.x, plate.position.y), plate.end, Vector2(plate.position.x, plate.end.y)])
		for piece in Geometry2D.intersect_polygons(band, bounds):
			draw_colored_polygon(piece, Color(1, 1, 1, 0.09))

	# --- The cover ---

	func _draw_cover(plate: Rect2) -> void:
		_gradient(plate, COVER, COVER_DEEP)
		# A faint lattice of little diamonds.
		for y in range(int(plate.position.y) + 14, int(plate.end.y) - 6, 18):
			for x in range(int(plate.position.x) + 14 + (9 if floori(y / 18.0) % 2 == 1 else 0), int(plate.end.x) - 6, 18):
				_diamond(Vector2(x, y), 2.0, Color(COVER_TRIM, 0.08))
		# Double gold rim with corner ornaments.
		var inner := plate.grow(-7.0)
		draw_rect(inner, Color(COVER_TRIM, 0.85), false, 1.5)
		draw_rect(inner.grow(-4.0), Color(COVER_TRIM, 0.35), false, 1.0)
		for corner: Vector2 in [inner.position, Vector2(inner.end.x, inner.position.y), Vector2(inner.position.x, inner.end.y), inner.end]:
			var sx := 1.0 if corner.x < size.x * 0.5 else -1.0
			var sy := 1.0 if corner.y < size.y * 0.5 else -1.0
			draw_line(corner, corner + Vector2(18 * sx, 0), COVER_TRIM, 3.0)
			draw_line(corner, corner + Vector2(0, 18 * sy), COVER_TRIM, 3.0)
			_diamond(corner + Vector2(9 * sx, 9 * sy), 4.0, COVER_TRIM)
		# The Gate: a pulsing glow, the arch on two pillars, a keystone gem, a star in the doorway.
		var centre := size * 0.5 + Vector2(0, -6)
		var pulse := 0.75 + 0.25 * sin(_time * 2.4)
		for i in 10:
			draw_circle(centre + Vector2(0, 10), 92.0 * (1.0 - i / 10.0), Color(COVER_TRIM, 0.03 * pulse))
		var radius := 52.0
		draw_rect(Rect2(centre + Vector2(-radius, 0), Vector2(radius * 2.0, 70)), Color(COVER_DEEP, 0.7))
		draw_circle(centre, radius, Color(COVER_DEEP, 0.7))
		draw_arc(centre, radius + 3.0, PI, TAU, 32, OUTLINE, 9.0)
		draw_arc(centre, radius, PI, TAU, 32, COVER_TRIM, 6.0)
		for side: float in [-1.0, 1.0]:
			var pillar := Rect2(centre + Vector2(side * radius - 4.0, 0), Vector2(8, 70))
			draw_rect(pillar.grow(1.5), OUTLINE)
			draw_rect(pillar, COVER_TRIM)
			draw_rect(Rect2(pillar.position + Vector2(-4, 66), Vector2(16, 6)), COVER_TRIM.darkened(0.2))
		_diamond(centre + Vector2(0, -radius), 10.0, OUTLINE)
		_diamond(centre + Vector2(0, -radius), 8.0, Color("8fd6ff"))
		_diamond(centre + Vector2(-2, -radius - 2), 2.5, Color(1, 1, 1, 0.8))
		_star(centre + Vector2(0, 26), 16.0 + 2.0 * pulse, COVER_TRIM)
		var font := ThemeDB.fallback_font
		var text := Loc.t("ui.summon.cover")
		_text(font, text, size.x * 0.5, plate.end.y - 30.0, _fit(font, text, 20, plate.size.x - 40.0), COVER_TRIM, OUTLINE)

	# --- Helpers ---

	func _gradient(rect: Rect2, top: Color, bottom: Color) -> void:
		draw_polygon(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]),
			PackedColorArray([top, top, bottom, bottom]))

	func _diamond(at: Vector2, half: float, color: Color) -> void:
		draw_colored_polygon(PackedVector2Array([at + Vector2(0, -half), at + Vector2(half, 0), at + Vector2(0, half), at + Vector2(-half, 0)]), color)

	## A five-point star with a dark outline.
	func _star(at: Vector2, radius: float, color: Color) -> void:
		for layer: Array in [[radius + 2.0, OUTLINE], [radius, color]]:
			var points := PackedVector2Array()
			for i in 10:
				var r: float = layer[0] * (1.0 if i % 2 == 0 else 0.45)
				points.append(at + Vector2.from_angle(-PI * 0.5 + i * PI / 5.0) * r)
			draw_colored_polygon(points, layer[1])

	## Largest font size from `start` down to 10 that fits `width`.
	static func _fit(font: Font, text: String, start: int, width: float) -> int:
		var font_size := start
		while font_size > 10 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
			font_size -= 1
		return font_size

	## `text` centred on `centre_x` with its baseline at `baseline`; outline skipped when transparent.
	func _text(font: Font, text: String, centre_x: float, baseline: float, font_size: int, color: Color, outline: Color) -> void:
		var at := Vector2(centre_x - font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x * 0.5, baseline)
		if outline.a > 0.0:
			draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, outline)
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

