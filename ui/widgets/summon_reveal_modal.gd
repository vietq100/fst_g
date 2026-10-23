class_name SummonRevealModal
extends Control
## The summoning reveal (D83), over everything: a stack of cards (one cover on top, then one card
## per newcomer, face up but dimmed). Drag the top card any way; let go early and it eases back;
## drag far enough (REVEAL_RATIO of the card) and it flies off while the card beneath flashes in
## its tier's colour and shows fully. Skip jumps to the summary: every card, tap one for details,
## Confirm lets them down at the Gate in order (RecruitmentService.confirm_arrivals, done by UIRoot
## when this closes, confirmed or not).

signal confirmed

const CARD_SIZE := Vector2(190, 268)
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


func setup(hunters: Array[HunterRuntime], with_effects: bool) -> SummonRevealModal:
	_hunters = hunters
	_effects = with_effects and not hunters.is_empty()
	return self


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var frame := ItemInfoModal.Frame.new()
	frame.custom_minimum_size.x = ItemInfoModal.WIDTH
	frame.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(frame)
	_body = UIKit.vbox([], 8)
	frame.add_child(_body)
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


# --- The stack ------------------------------------------------------------------------------------

func _show_stack() -> void:
	_clear_body()
	var banner := ItemInfoModal.Banner.new()
	banner.text = Loc.t("ui.summon.title")
	_body.add_child(banner)
	_stage = Control.new()
	_stage.custom_minimum_size = CARD_SIZE + STACK_OFFSET * _hunters.size() + Vector2(40, 40)
	_stage.mouse_filter = Control.MOUSE_FILTER_STOP
	_stage.gui_input.connect(_on_stage_input)
	_body.add_child(_stage)
	_cards.clear()
	# Bottom of the stack first (the last newcomer), the cover last so it draws on top.
	var origin := Vector2(20, 20)
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
	var hint := UIKit.label(Loc.t("ui.summon.swipe_hint"), &"MutedLabel")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.add_child(hint)
	var skip := UIKit.button(Loc.t("ui.summon.skip"), _show_summary, &"")
	skip.custom_minimum_size = Vector2(120, GameTheme.TOUCH)
	skip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ItemInfoModal._style_button(skip, ItemInfoModal.BUTTON, ItemInfoModal.FRAME_RIM.darkened(0.2))
	_body.add_child(skip)


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
		# The card beneath brightens as the top one slides off it.
		var ratio := _reveal_ratio(top)
		_cards[_top + 1].modulate = DIM.lerp(Color.WHITE, clampf(ratio * 0.6, 0.0, 0.6))
		_stage.accept_event()


func _reveal_ratio(top: SummonCard) -> float:
	var offset := top.position - _card_home
	return maxf(absf(offset.x) / CARD_SIZE.x, absf(offset.y) / CARD_SIZE.y) / REVEAL_RATIO


func _release(top: SummonCard) -> void:
	if _reveal_ratio(top) < 1.0:
		# Not far enough: ease back, slowly.
		_return_tween = create_tween()
		_return_tween.tween_property(top, ^"position", _card_home, RETURN_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		_cards[_top + 1].modulate = DIM
		return
	# Flies off the way it was dragged and fades; the card beneath is revealed.
	var direction := (top.position - _card_home).normalized()
	var fly := create_tween().set_parallel()
	fly.tween_property(top, ^"position", top.position + direction * 420.0, FLY_TIME).set_ease(Tween.EASE_IN)
	fly.tween_property(top, ^"modulate:a", 0.0, FLY_TIME)
	fly.chain().tween_callback(top.queue_free)
	_top += 1
	var revealed := _cards[_top]
	_card_home = revealed.position
	revealed.reveal()
	if not _can_drag():
		# The last card is open: on to the summary.
		var go := UIKit.button(Loc.t("ui.summon.continue"), _show_summary, &"PrimaryButton")
		go.custom_minimum_size = Vector2(150, 46)
		go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		ItemInfoModal._style_button(go, Color("2f5a2a"), ItemInfoModal.GOLD.darkened(0.3))
		_body.add_child(go)


# --- The summary -----------------------------------------------------------------------------------

func _show_summary() -> void:
	_dragging = false
	_clear_body()
	var banner := ItemInfoModal.Banner.new()
	banner.text = Loc.t("ui.summon.summary_title", {"count": _hunters.size()})
	_body.add_child(banner)
	var grid := GridContainer.new()
	grid.columns = 5 if _hunters.size() > 5 else maxi(_hunters.size(), 1)
	grid.add_theme_constant_override(&"h_separation", 4)
	grid.add_theme_constant_override(&"v_separation", 4)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for hunter in _hunters:
		grid.add_child(_summary_tile(hunter))
	_body.add_child(grid)
	var hint := UIKit.label(Loc.t("ui.summon.tap_detail"), &"MutedLabel")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.add_child(hint)
	var confirm := UIKit.button(Loc.t("ui.summon.confirm"), func() -> void:
		_confirmed = true
		confirmed.emit()
		queue_free(), &"PrimaryButton")
	confirm.custom_minimum_size = Vector2(160, 46)
	confirm.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	confirm.add_theme_font_size_override(&"font_size", 16)
	ItemInfoModal._style_button(confirm, Color("2f5a2a"), ItemInfoModal.GOLD.darkened(0.3))
	_body.add_child(confirm)


## A small card: figure over a tier-coloured plate, name, tier code; tapping opens the details.
func _summary_tile(hunter: HunterRuntime) -> Control:
	var tile := PanelContainer.new()
	tile.theme_type_variation = &"HunterCard"
	tile.custom_minimum_size = Vector2(58, 96)
	tile.mouse_filter = Control.MOUSE_FILTER_STOP
	var figure := HunterFigure.new().setup(hunter, null)
	figure.custom_minimum_size = Vector2(48, 60)
	figure.accent = Tier.color(hunter.tier)
	var name_label := UIKit.label(hunter.display_name, &"HudSmallLabel", false)
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var code := UIKit.label(Tier.code(hunter.tier), &"HudSmallLabel", false)
	code.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	code.add_theme_color_override(&"font_color", Tier.color(hunter.tier))
	tile.add_child(UIKit.vbox([figure, name_label, code], 1))
	tile.gui_input.connect(func(event: InputEvent) -> void:
		if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
			tile.accept_event()
			_show_detail(hunter))
	return tile


## One newcomer in full: figure, name, tier, class and level, graded stats, traits, talent, fate.
func _show_detail(hunter: HunterRuntime) -> void:
	_clear_body()
	var gm := GameManager
	var definition := gm.hunters.get_definition(hunter)
	var banner := ItemInfoModal.Banner.new()
	banner.text = hunter.display_name
	_body.add_child(banner)
	var figure := HunterFigure.new().setup(hunter, null)
	figure.custom_minimum_size = Vector2(72, 100)
	figure.accent = Tier.color(hunter.tier)
	var facts := UIKit.vbox([], 3)
	facts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tier_label := UIKit.label("%s  %s" % [Tier.code(hunter.tier), Tier.name_of(hunter.tier)], &"HudLabel", false)
	tier_label.add_theme_color_override(&"font_color", Tier.color(hunter.tier))
	facts.add_child(tier_label)
	facts.add_child(UIKit.label(Loc.t("ui.common.level_class", {"level": hunter.level, "class": definition.display_name if definition != null else "?"}), &"MutedLabel", false))
	var grade := gm.grades.hunter_grade(hunter)
	var grade_label := UIKit.label(Loc.t("ui.common.grade", {"grade": StatGradeService.name_of(grade)}), &"HudSmallLabel", false)
	grade_label.add_theme_color_override(&"font_color", StatGradeService.color(grade))
	facts.add_child(grade_label)
	for stat: StringName in [HunterService.MAX_HP, HunterService.ATTACK, HunterService.DEFENSE, HunterService.ATTACK_SPEED]:
		var value := gm.hunters.get_stat(hunter, stat)
		var text := "%s %s" % [Loc.t("stat.%s" % stat), ("%.2f" % value) if stat == HunterService.ATTACK_SPEED else ("%d" % roundi(value))]
		var row := UIKit.label(text, &"HudSmallLabel", false)
		row.add_theme_color_override(&"font_color", StatGradeService.color(gm.grades.hunter_step(hunter, stat)))
		facts.add_child(row)
	_body.add_child(UIKit.hbox([figure, facts], 10))
	var traits := PackedStringArray()
	for trait_def in gm.traits.get_traits(hunter):
		traits.append(trait_def.display_name)
	_body.add_child(UIKit.label(Loc.t("ui.summon.traits", {"traits": ", ".join(traits) if not traits.is_empty() else "—"}), &"MutedLabel"))
	var talent := gm.talents.get_talent(hunter)
	_body.add_child(UIKit.label(Loc.t("ui.summon.talent", {"talent": talent.display_name}) if talent != null else Loc.t("ui.summon.no_talent"), &"MutedLabel"))
	var fate := UIKit.label(Loc.t("ui.summon.arrival_mount" if hunter.hibernating else "ui.summon.arrival_village"), &"HudSmallLabel")
	fate.add_theme_color_override(&"font_color", Color("8fb3ff") if hunter.hibernating else GameTheme.GOOD)
	_body.add_child(fate)
	var back := UIKit.button(Loc.t("ui.summon.back"), _show_summary, &"")
	back.custom_minimum_size = Vector2(120, GameTheme.TOUCH)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ItemInfoModal._style_button(back, ItemInfoModal.BUTTON, ItemInfoModal.FRAME_RIM.darkened(0.2))
	_body.add_child(back)


# --- A card --------------------------------------------------------------------------------------

## One card of the stack: a tier-framed plate with the newcomer's figure, name, tier and class, or
## the cover (the Gate's emblem). `reveal` flashes it in its tier colour and pops it.
class SummonCard extends Control:
	const OUTLINE := Color("16161c")
	const PLATE := Color("1b1a26")
	const COVER := Color("2a2f4a")
	const COVER_TRIM := Color("e2c46b")

	var hunter: HunterRuntime
	var is_cover := false
	var _flash := 0.0

	func setup(newcomer: HunterRuntime, cover: bool) -> SummonCard:
		hunter = newcomer
		is_cover = cover
		custom_minimum_size = SummonRevealModal.CARD_SIZE
		size = SummonRevealModal.CARD_SIZE
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		pivot_offset = SummonRevealModal.CARD_SIZE * 0.5
		if hunter != null:
			var figure := HunterFigure.new().setup(hunter, null)
			figure.accent = Tier.color(hunter.tier)
			figure.position = Vector2((size.x - 96.0) * 0.5, 44.0)
			figure.size = Vector2(96, 130)
			figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(figure)
		return self

	func reveal() -> void:
		modulate = Color.WHITE
		_flash = 1.0
		var tween := create_tween()
		tween.tween_property(self, ^"scale", Vector2(1.07, 1.07), 0.12).from(Vector2(0.92, 0.92)).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, ^"scale", Vector2.ONE, 0.16).set_ease(Tween.EASE_IN_OUT)
		tween.parallel().tween_property(self, ^"_flash", 0.0, 0.6)
		tween.tween_callback(queue_redraw)

	func _process(_delta: float) -> void:
		if _flash > 0.0:
			queue_redraw()

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var color := Tier.color(hunter.tier) if hunter != null else COVER_TRIM
		draw_rect(rect.grow(2.0), OUTLINE)
		draw_rect(rect, color.darkened(0.35))
		draw_rect(rect.grow(-5.0), PLATE if hunter != null else COVER)
		if is_cover:
			# The Gate's emblem: an arch, a star, "Hunter Gate".
			var centre := size * 0.5
			draw_arc(centre + Vector2(0, 10), 44.0, PI, TAU, 24, COVER_TRIM, 4.0)
			for side: float in [-1.0, 1.0]:
				draw_line(centre + Vector2(side * 44.0, 10.0), centre + Vector2(side * 44.0, 60.0), COVER_TRIM, 4.0)
			draw_circle(centre + Vector2(0, -20), 9.0, COVER_TRIM)
			draw_circle(centre + Vector2(0, -20), 5.0, COVER)
			var font := ThemeDB.fallback_font
			var text := Loc.t("ui.summon.cover")
			var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
			draw_string(font, Vector2((size.x - width) * 0.5, size.y - 24.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COVER_TRIM)
			return
		var font := ThemeDB.fallback_font
		var definition := GameManager.hunters.get_definition(hunter)
		var name_width := font.get_string_size(hunter.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		draw_string_outline(font, Vector2((size.x - name_width) * 0.5, 30.0), hunter.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 3, OUTLINE)
		draw_string(font, Vector2((size.x - name_width) * 0.5, 30.0), hunter.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("f4f1ea"))
		var code := Tier.code(hunter.tier)
		draw_string_outline(font, Vector2(12.0, 30.0), code, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 3, OUTLINE)
		draw_string(font, Vector2(12.0, 30.0), code, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color)
		var line := Loc.t("ui.common.level_class", {"level": hunter.level, "class": definition.display_name if definition != null else "?"})
		var line_width := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(font, Vector2((size.x - line_width) * 0.5, size.y - 40.0), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("c9bfa8"))
		var fate := Loc.t("ui.gate.went_asleep" if hunter.hibernating else "ui.gate.went_village")
		var fate_width := font.get_string_size(fate, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_string(font, Vector2((size.x - fate_width) * 0.5, size.y - 20.0), fate, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("8fb3ff") if hunter.hibernating else GameTheme.GOOD)
		if _flash > 0.0:
			draw_rect(rect.grow(6.0 + 10.0 * _flash), Color(color, 0.5 * _flash), false, 3.0)
			draw_rect(rect, Color(color, 0.35 * _flash))
