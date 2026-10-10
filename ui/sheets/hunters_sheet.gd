class_name HuntersSheet
extends Sheet
## Roster list: portrait, name, level, HP, mood and what the Hunter is doing. Tap → Hunter panel.


func _init() -> void:
	title = "Hunters"


func _watch() -> Array:
	var gm := GameManager
	return [[gm.hunters, &"hunter_added"], [gm.hunters, &"hunter_changed"], [gm.activities, &"activity_changed"],
		[gm.mood, &"mood_changed"]]


func _build(content: VBoxContainer) -> void:
	var gm := GameManager
	set_title("Hunters  %d / %d" % [gm.hunters.count(), gm.recruitment.get_capacity()])
	for runtime in gm.hunters.get_all():
		content.add_child(_row(runtime))
	if gm.hunters.count() < gm.recruitment.get_capacity():
		content.add_child(UIKit.label("Hire more Hunters at the Tavern.", &"MutedLabel"))


func _row(runtime: HunterRuntime) -> Control:
	var gm := GameManager
	var max_hp := gm.hunters.get_stat(runtime, HunterService.MAX_HP)
	var info := UIKit.vbox([
		UIKit.label("%s  Lv %d" % [runtime.display_name, runtime.level], &"", false),
		UIKit.bar(runtime.current_hp, max_hp, &"HpBar", "%d / %d" % [roundi(runtime.current_hp), roundi(max_hp)]),
		UIKit.label("%s · Mood %s" % [_status(runtime), _mood_text(runtime)], &"MutedLabel", false),
	], 2)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in info.get_children():
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := UIKit.hbox([HunterPortrait.new().setup(runtime, gm.equipment), info])
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var button := Button.new()
	button.theme_type_variation = &"RowButton"
	button.custom_minimum_size = Vector2(0, 58)
	button.pressed.connect(func() -> void: open_requested.emit(HunterSheet.new(runtime)))
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		margin.add_theme_constant_override(side, 6)
	margin.add_child(row)
	button.add_child(margin)
	return button


static func _status(runtime: HunterRuntime) -> String:
	if runtime.injured:
		return "Injured %s" % UIKit.format_duration(GameManager.hospital.get_remaining(runtime))
	if runtime.expedition_id != &"":
		return "On expedition"
	var activity := GameManager.activities.get_definition(runtime.activity)
	return activity.display_name if activity != null else "Idle"


static func _mood_text(runtime: HunterRuntime) -> String:
	var state: String = MoodService.State.keys()[GameManager.mood.get_state(runtime)]
	return "%d %s" % [roundi(runtime.mood), state.capitalize()]
