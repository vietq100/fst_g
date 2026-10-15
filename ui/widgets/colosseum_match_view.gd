class_name ColosseumMatchView
extends Control
## Replay of a simulated Colosseum match (ARENA_SYSTEM.md, phase 1): the two Hunters face each other
## over a sand arena, lunge when they strike, flash when hit, with floating damage, live HP bars and
## the clock; speed ×1 / ×2 and skip; then the result with the mood change. Full screen, takes every tap.

signal finished

const SAND := Color("c9a86a")
const SAND_DARK := Color("a8884e")
const WALL := Color("4b4b55")
const FIGURE_SCALE := Vector2(1.6, 1.6)

var _first: HunterRuntime
var _second: HunterRuntime
var _result: ArenaResult
var _time := 0.0
var _speed := 1.0
var _next_event := 0
var _ended := false
var _figures: Array[HunterFigure] = []
var _bars: Array[ProgressBar] = []
var _bar_labels: Array[Label] = []
var _clock: Label
var _stage: Control
var _result_panel: PanelContainer
var _speed_button: Button


func setup(first: HunterRuntime, second: HunterRuntime, result: ArenaResult) -> ColosseumMatchView:
	_first = first
	_second = second
	_result = result
	return self


func _ready() -> void:
	theme = GameTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.03, 0.06, 0.92)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		margin.add_theme_constant_override(side, 12)
	add_child(margin)
	var column := UIKit.vbox([], 8)
	margin.add_child(column)
	column.add_child(UIKit.label(Loc.t("ui.arena.title"), &"TitleLabel", false))
	_clock = UIKit.label("", &"HudAccentLabel", false)
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_clock)
	# Names and HP bars.
	var header := UIKit.hbox([], 8)
	for side in 2:
		var runtime := _first if side == 0 else _second
		var name_label := UIKit.label(runtime.display_name, &"HudLabel", false)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if side == 0 else HORIZONTAL_ALIGNMENT_RIGHT
		var bar := UIKit.bar(_result.max_hp[side], _result.max_hp[side], &"HpBar", "")
		bar.custom_minimum_size.y = 14
		var label := Label.new()
		label.theme_type_variation = &"MutedLabel"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		bar.add_child(label)
		_bars.append(bar)
		_bar_labels.append(label)
		header.add_child(UIKit.vbox([name_label, bar], 2))
	column.add_child(header)
	# The arena.
	_stage = Control.new()
	_stage.custom_minimum_size = Vector2(0, 230)
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage.clip_contents = true
	_stage.draw.connect(_draw_stage)
	column.add_child(_stage)
	for side in 2:
		var runtime := _first if side == 0 else _second
		var figure := HunterFigure.new().setup(runtime, GameManager.equipment if runtime.unique_id != &"" and GameManager.hunters.get_hunter(runtime.unique_id) != null else null)
		figure.backdrop = false
		figure.scale = FIGURE_SCALE
		figure.pivot_offset = figure.custom_minimum_size * 0.5
		figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_stage.add_child(figure)
		_figures.append(figure)
	_stage.resized.connect(_place_figures)
	_place_figures.call_deferred()
	# Controls.
	_speed_button = UIKit.button(Loc.t("ui.arena.speed", {"speed": 1}), _toggle_speed)
	var skip := UIKit.button(Loc.t("ui.arena.skip"), _skip)
	column.add_child(UIKit.hbox([_speed_button, skip], 8))
	_refresh()


func _toggle_speed() -> void:
	_speed = 2.0 if _speed == 1.0 else 1.0
	_speed_button.text = Loc.t("ui.arena.speed", {"speed": int(_speed)})


func _skip() -> void:
	_time = _result.duration + 0.01
	_advance(0.0)


func _process(delta: float) -> void:
	if not _ended:
		_advance(delta * _speed)


func _advance(delta: float) -> void:
	_time += delta
	while _next_event < _result.events.size() and _result.events[_next_event]["t"] <= _time:
		_play(_result.events[_next_event])
		_next_event += 1
	_refresh()
	if _time >= _result.duration and _next_event >= _result.events.size() and not _ended:
		_end()


func _refresh() -> void:
	var hp: Array = [_result.max_hp[0], _result.max_hp[1]]
	if _next_event > 0:
		hp = _result.events[_next_event - 1]["hp"]
	for side in 2:
		_bars[side].max_value = _result.max_hp[side]
		_bars[side].value = hp[side]
		_bar_labels[side].text = "%d / %d" % [roundi(hp[side]), roundi(_result.max_hp[side])]
	_clock.text = Loc.t("ui.arena.timer", {"seconds": int(minf(_time, _result.duration))})


func _place_figures() -> void:
	if _stage == null or _figures.size() < 2:
		return
	var size := _stage.size
	for side in 2:
		var figure := _figures[side]
		figure.position = Vector2(size.x * (0.22 if side == 0 else 0.78) - figure.custom_minimum_size.x * 0.5, size.y * 0.62 - figure.custom_minimum_size.y * 0.5)
	_stage.queue_redraw()


## One hit: the striker lunges, the target flashes, a number floats up.
func _play(event: Dictionary) -> void:
	var from: int = event["from"]
	var striker := _figures[from]
	var target := _figures[1 - from]
	var home := striker.position
	var toward := Vector2(26.0 if from == 0 else -26.0, 0.0)
	var tween := create_tween()
	tween.tween_property(striker, ^"position", home + toward, 0.08)
	tween.tween_property(striker, ^"position", home, 0.12)
	if event["dodged"]:
		_float_text(Loc.t("ui.arena.miss"), Color("b3a593"), target)
		var dodge := create_tween()
		dodge.tween_property(target, ^"position:y", target.position.y - 10.0, 0.08)
		dodge.tween_property(target, ^"position:y", target.position.y, 0.12)
		return
	var flash := create_tween()
	flash.tween_property(target, ^"modulate", Color(1.0, 0.45, 0.4), 0.05)
	flash.tween_property(target, ^"modulate", Color.WHITE, 0.15)
	_float_text(("%d!" if event["crit"] else "%d") % event["damage"], Color("ffd23f") if event["crit"] else Color("ffffff"), target)


func _float_text(text: String, color: Color, over: Control) -> void:
	var label := UIKit.label(text, &"HudLabel", false)
	label.add_theme_color_override(&"font_color", color)
	label.position = over.position + Vector2(over.custom_minimum_size.x * 0.5 - 12.0, -18.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, ^"position:y", label.position.y - 34.0, 0.7)
	tween.tween_property(label, ^"modulate:a", 0.0, 0.7)
	tween.chain().tween_callback(label.queue_free)


func _draw_stage() -> void:
	var size := _stage.size
	_stage.draw_rect(Rect2(Vector2.ZERO, size), WALL)
	var floor_rect := Rect2(Vector2(0, size.y * 0.16), Vector2(size.x, size.y * 0.84))
	_stage.draw_rect(floor_rect, SAND)
	for i in 14:
		var y := floor_rect.position.y + floor_rect.size.y * (float(i) / 14.0)
		_stage.draw_line(Vector2(0, y), Vector2(size.x, y), Color(SAND_DARK, 0.25), 1.0)
	_stage.draw_ellipse(Vector2(size.x * 0.5, size.y * 0.8), size.x * 0.46, size.y * 0.12, Color(SAND_DARK, 0.45))
	for side in 2:
		_stage.draw_ellipse(Vector2(size.x * (0.22 if side == 0 else 0.78), size.y * 0.78), 34.0, 9.0, Color(0, 0, 0, 0.3))


func _end() -> void:
	_ended = true
	var arena := GameManager.arena
	var winner := _result.winner
	var title := Loc.t("ui.arena.result_draw") if winner == -1 else Loc.t("ui.arena.result_win", {"name": _result.names[winner]})
	var delta := arena.mood_delta(_result, 0)
	var column := UIKit.vbox([
		UIKit.label(title, &"TitleLabel", false),
		UIKit.label(Loc.t("ui.arena.result_stats", {"a": roundi(_result.hp_ratio(0) * 100.0), "b": roundi(_result.hp_ratio(1) * 100.0),
			"seconds": int(_result.duration), "timeout": Loc.t("ui.arena.result_timeout") if _result.timed_out else ""}), &"MutedLabel"),
		UIKit.label(Loc.t("ui.arena.result_mood", {"name": _first.display_name, "delta": "%+d" % roundi(delta)}), &"AccentLabel"),
		UIKit.button(Loc.t("ui.arena.close"), _close, &"PrimaryButton"),
	], 6)
	_result_panel = PanelContainer.new()
	_result_panel.theme_type_variation = &"Sheet"
	_result_panel.add_child(column)
	_result_panel.set_anchors_preset(Control.PRESET_CENTER)
	_result_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_result_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_result_panel.custom_minimum_size = Vector2(280, 0)
	add_child(_result_panel)


func _close() -> void:
	if GameManager.hunters.get_hunter(_first.unique_id) == _first:
		GameManager.arena.apply_result(_first, _result, 0)
	finished.emit()
	queue_free()
