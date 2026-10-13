class_name HuntersSheet
extends Sheet
## Hunter tab (Evil Hunter Tycoon style drawer): a grid of Hunter cards with name, grade, class,
## full-body figure with gear and pet (D59), what the Hunter is doing, Info (opens the Hunter panel) and Locate (camera follows it).
## Header buttons: place everyone's hunting ground, and sort.

## Camera follows this Hunter; UIRoot forwards it to the world.
signal follow_requested(unique_id: StringName)

enum Sort { LEVEL, NAME, CLASS }

const COLUMNS := 3

static var _sort := Sort.LEVEL
## Index into RegionService.get_duty_options() of the last "place hunting grounds" choice.
static var _duty_index := 0


func _init() -> void:
	title = Loc.t("ui.hunters.title")


func _watch() -> Array:
	var gm := GameManager
	return [[gm.hunters, &"hunter_added"], [gm.hunters, &"hunter_changed"], [gm.activities, &"activity_changed"],
		[gm.mood, &"mood_changed"], [gm.needs, &"needs_changed"], [gm.purses, &"purse_changed"],
		[gm.corpses, &"hunter_died"], [gm.corpses, &"body_delivered"]]


func _build(content: VBoxContainer) -> void:
	var gm := GameManager
	set_title(Loc.t("ui.hunters.title_count", {"count": gm.hunters.count(), "max": gm.recruitment.get_capacity()}))
	var options := gm.regions.get_duty_options()
	var next_duty: StringName = options[(_duty_index + 1) % options.size()]
	var place := UIKit.button(Loc.t("ui.hunters.hunting_grounds", {"duty": gm.regions.get_duty_name(options[_duty_index % options.size()])}), func() -> void:
		_duty_index = (_duty_index + 1) % options.size()
		for hunter in gm.hunters.get_all():
			gm.regions.set_duty(hunter, options[_duty_index])
		toast_requested.emit(Loc.t("ui.hunters.everyone", {"duty": gm.regions.get_duty_name(options[_duty_index])}), false)
		request_rebuild(), &"")
	place.tooltip_text = Loc.t("ui.hunters.hunting_grounds_tip", {"next": gm.regions.get_duty_name(next_duty)})
	var sort := UIKit.button(Loc.t("ui.hunters.sort", {"mode": Loc.t("ui.hunters.sort_mode.%s" % String(Sort.keys()[_sort]).to_lower())}), func() -> void:
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
		content.add_child(UIKit.label(Loc.t("ui.hunters.hire_more"), &"MutedLabel"))


func _sorter(a: HunterRuntime, b: HunterRuntime) -> bool:
	match _sort:
		Sort.NAME:
			return a.display_name < b.display_name
		Sort.CLASS:
			return String(a.definition_id) < String(b.definition_id) or (a.definition_id == b.definition_id and a.level > b.level)
	return a.level > b.level or (a.level == b.level and a.reincarnations > b.reincarnations)


## Tier badge of a Hunter (D60): [code, colour].
static func grade_of(runtime: HunterRuntime) -> Array:
	return [Tier.code(runtime.tier), Tier.color(runtime.tier)]


## Tier-coloured card (D62): see HunterCard.
func _card(runtime: HunterRuntime) -> Control:
	var card := HunterCard.new().setup(runtime, _status(runtime))
	card.info_pressed.connect(func() -> void: open_requested.emit(HunterDialog.new(runtime)))
	card.locate_pressed.connect(func() -> void: follow_requested.emit(runtime.unique_id))
	return card


static func _status(runtime: HunterRuntime) -> String:
	if GameManager.corpses.is_body(runtime):
		return Loc.t("ui.hunters.status.fallen")
	if not runtime.alive:
		return Loc.t("ui.hunters.status.reviving", {"time": UIKit.format_duration(GameManager.temple.get_remaining(runtime))})
	if runtime.injured:
		return Loc.t("ui.hunters.status.injured", {"time": UIKit.format_duration(GameManager.temple.get_remaining(runtime))})
	if runtime.expedition_id != &"":
		return Loc.t("ui.hunters.status.on_expedition")
	if runtime.task == HunterRuntime.HUNTING:
		var region := GameManager.regions.get_duty_region(runtime)
		return region.display_name if region != null else Loc.t("ui.hunters.status.hunting")
	if runtime.activity == &"":
		return Loc.t("ui.hunters.status.idle")
	return HunterSheet.activity_label(runtime.activity)
