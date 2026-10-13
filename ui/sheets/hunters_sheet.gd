class_name HuntersSheet
extends Sheet
## Hunter tab (Evil Hunter Tycoon style drawer): a grid of Hunter cards with name, grade, class,
## portrait, what the Hunter is doing, Info (opens the Hunter panel) and Locate (camera follows it).
## Header buttons: place everyone's hunting ground, and sort.

## Camera follows this Hunter; UIRoot forwards it to the world.
signal follow_requested(unique_id: StringName)

enum Sort { LEVEL, NAME, CLASS }

const COLUMNS := 4
const GRADES := [["N", Color("b3a593")], ["R", Color("5fa8ff")], ["S", Color("e8c547")], ["L", Color("e0584a")]]

static var _sort := Sort.LEVEL
## Index into RegionService.get_duty_options() of the last "place hunting grounds" choice.
static var _duty_index := 0


func _init() -> void:
	title = "Hunters"


func _watch() -> Array:
	var gm := GameManager
	return [[gm.hunters, &"hunter_added"], [gm.hunters, &"hunter_changed"], [gm.activities, &"activity_changed"],
		[gm.mood, &"mood_changed"], [gm.needs, &"needs_changed"], [gm.purses, &"purse_changed"],
		[gm.corpses, &"hunter_died"], [gm.corpses, &"body_delivered"]]


func _build(content: VBoxContainer) -> void:
	var gm := GameManager
	set_title("Hunters  %d / %d" % [gm.hunters.count(), gm.recruitment.get_capacity()])
	var options := gm.regions.get_duty_options()
	var next_duty: StringName = options[(_duty_index + 1) % options.size()]
	var place := UIKit.button("Hunting grounds: %s" % gm.regions.get_duty_name(options[_duty_index % options.size()]), func() -> void:
		_duty_index = (_duty_index + 1) % options.size()
		for hunter in gm.hunters.get_all():
			gm.regions.set_duty(hunter, options[_duty_index])
		toast_requested.emit("Everyone: %s" % gm.regions.get_duty_name(options[_duty_index]), false)
		request_rebuild(), &"")
	place.tooltip_text = "Tap to send every Hunter to the next hunting ground (next: %s)" % gm.regions.get_duty_name(next_duty)
	var sort := UIKit.button("Sort: %s" % String(Sort.keys()[_sort]).capitalize(), func() -> void:
		_sort = ((_sort + 1) % Sort.size()) as Sort
		request_rebuild(), &"")
	content.add_child(UIKit.hbox([place, sort], 4))
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override(&"h_separation", 4)
	grid.add_theme_constant_override(&"v_separation", 4)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var roster := gm.hunters.get_all()
	roster.sort_custom(_sorter)
	for runtime in roster:
		grid.add_child(_card(runtime))
	content.add_child(grid)
	if gm.hunters.count() < gm.recruitment.get_capacity():
		content.add_child(UIKit.label("Hire more Hunters at the Tavern.", &"MutedLabel"))


func _sorter(a: HunterRuntime, b: HunterRuntime) -> bool:
	match _sort:
		Sort.NAME:
			return a.display_name < b.display_name
		Sort.CLASS:
			return String(a.definition_id) < String(b.definition_id) or (a.definition_id == b.definition_id and a.level > b.level)
	return a.level > b.level or (a.level == b.level and a.reincarnations > b.reincarnations)


static func grade_of(runtime: HunterRuntime) -> Array:
	var index := 0
	if runtime.reincarnations >= 6:
		index = 3
	elif runtime.reincarnations >= 3:
		index = 2
	elif runtime.reincarnations >= 1:
		index = 1
	return GRADES[index]


func _card(runtime: HunterRuntime) -> Control:
	var gm := GameManager
	var definition := gm.hunters.get_definition(runtime)
	var grade := grade_of(runtime)
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"HunterCard"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var star := PixelIcons.rect(&"star", 1)
	star.modulate = Color.WHITE if gm.talents.get_talent(runtime) != null else Color(1, 1, 1, 0.25)
	var name_label := UIKit.label(runtime.display_name, &"HudSmallLabel", false)
	name_label.clip_text = true
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var grade_label := UIKit.label(grade[0], &"HudSmallLabel", false)
	grade_label.add_theme_color_override(&"font_color", grade[1])
	grade_label.add_theme_font_size_override(&"font_size", 13)
	grade_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	var top := UIKit.hbox([star, name_label, grade_label], 2)
	var level_label := UIKit.label("Lv.%d %s" % [runtime.level, definition.display_name], &"MutedLabel", false)
	level_label.clip_text = true
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var portrait := HunterPortrait.new().setup(runtime, gm.equipment)
	portrait.custom_minimum_size = Vector2(56, 56)
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var status := UIKit.label(_status(runtime), &"HudAccentLabel", false)
	status.add_theme_font_size_override(&"font_size", 9)
	status.clip_text = true
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var info := UIKit.button("Info", func() -> void: open_requested.emit(HunterDialog.new(runtime)), &"Button")
	info.custom_minimum_size = Vector2(0, 28)
	info.add_theme_font_size_override(&"font_size", 11)
	var locate := UIKit.button("", func() -> void: follow_requested.emit(runtime.unique_id), &"PrimaryButton")
	locate.icon = PixelIcons.texture(&"target", 1)
	locate.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	locate.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	locate.custom_minimum_size = Vector2(28, 28)
	locate.size_flags_horizontal = Control.SIZE_SHRINK_END
	var buttons := UIKit.hbox([info, locate], 2)
	panel.add_child(UIKit.vbox([top, level_label, portrait, status, buttons], 2))
	return panel


static func _status(runtime: HunterRuntime) -> String:
	if GameManager.corpses.is_body(runtime):
		return "Fallen"
	if not runtime.alive:
		return "Reviving %s" % UIKit.format_duration(GameManager.temple.get_remaining(runtime))
	if runtime.injured:
		return "Injured %s" % UIKit.format_duration(GameManager.temple.get_remaining(runtime))
	if runtime.expedition_id != &"":
		return "On expedition"
	if runtime.task == HunterRuntime.HUNTING:
		var region := GameManager.regions.get_duty_region(runtime)
		return region.display_name if region != null else "Hunting"
	var activity := GameManager.activities.get_definition(runtime.activity)
	if activity != null:
		return activity.display_name
	return String(runtime.activity).capitalize() if runtime.activity != &"" else "Idle"
