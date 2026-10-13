class_name ExpeditionHud
extends VBoxContainer
## In-expedition HUD (UI_DESIGN.md → Main HUD: expedition status): destination, section
## progress, stash, and one card per party member with HP. Polls the runtime 4×/s (cheap).

const POLL := 0.25

var _header: Label
var _stash: Label
var _party_box: HBoxContainer
var _bars: Dictionary[StringName, ProgressBar] = {}
var _portraits: Dictionary[StringName, HunterPortrait] = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header = UIKit.label("", &"TitleLabel", false)
	_stash = UIKit.label("", &"MutedLabel", false)
	var top := PanelContainer.new()
	top.theme_type_variation = &"TopBar"
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(UIKit.vbox([_header, _stash], 2))
	add_child(top)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(spacer)
	_party_box = UIKit.hbox([], 4)
	_party_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_party_box)
	var timer := Timer.new()
	timer.wait_time = POLL
	timer.autostart = true
	timer.timeout.connect(_refresh)
	add_child(timer)
	_build_party()
	_refresh()


func _build_party() -> void:
	var service := GameManager.expeditions
	if service.current_run == null:
		return
	for hunter_id in service.current_run.party_ids:
		var runtime := GameManager.hunters.get_hunter(hunter_id)
		if runtime == null:
			continue
		var portrait := HunterPortrait.new().setup(runtime, GameManager.equipment)
		var bar := UIKit.bar(runtime.current_hp, 1.0, &"HpBar")
		_bars[hunter_id] = bar
		_portraits[hunter_id] = portrait
		var card := UIKit.card(UIKit.vbox([UIKit.hbox([portrait, UIKit.label(runtime.display_name, &"MutedLabel", false)], 4), bar], 2))
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_party_box.add_child(card)


func _refresh() -> void:
	var service := GameManager.expeditions
	var run := service.current_run
	if run == null:
		return
	var definition := service.get_current_definition()
	var sections := definition.enemy_groups.size()
	var where := Loc.t("ui.expedition_hud.boss") if run.boss_reached \
		else Loc.t("ui.expedition_hud.area", {"area": clampi(run.section_index + 1, 1, sections), "total": sections})
	if run.phase == ExpeditionRun.Phase.RETURNING:
		where = Loc.t("ui.expedition_hud.returning")
	_header.text = Loc.t("ui.expedition_hud.header", {"dungeon": definition.display_name, "where": where})
	var items := 0
	for quantity in run.stash_items.values():
		items += quantity
	_stash.text = Loc.t("ui.expedition_hud.stash", {"gold": run.stash_gold, "items": items, "kills": run.kills})
	for hunter_id in _bars:
		var runtime := GameManager.hunters.get_hunter(hunter_id)
		var bar := _bars[hunter_id]
		bar.max_value = maxf(GameManager.hunters.get_stat(runtime, HunterService.MAX_HP), 1.0)
		bar.value = runtime.current_hp
		var down := run.downed_ids.has(hunter_id)
		if _portraits[hunter_id].downed != down:
			_portraits[hunter_id].downed = down
			_portraits[hunter_id].queue_redraw()
