class_name ExpeditionHud
extends VBoxContainer
## In-expedition HUD (UI_DESIGN.md → Main HUD: expedition status): destination, section
## progress, stash, and one card per party member with HP. Polls the runtime 4×/s (cheap).

const POLL := 0.25

var _header: Label
var _stash: Label
## How far through the dungeon's sections the party is (full at the boss / on the way back).
var _progress: ProgressBar
var _party_box: HBoxContainer
var _bars: Dictionary[StringName, ProgressBar] = {}
var _mana: Dictionary[StringName, ProgressBar] = {}
## Row of coloured dots, one per status effect on the member (its definition's colour).
var _effects: Dictionary[StringName, HBoxContainer] = {}
var _shown_effects: Dictionary[StringName, String] = {}
var _portraits: Dictionary[StringName, HunterPortrait] = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header = UIKit.label("", &"TitleLabel", false)
	_stash = UIKit.label("", &"MutedLabel", false)
	var top := PanelContainer.new()
	top.theme_type_variation = &"TopBar"
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress = UIKit.bar(0.0, 1.0, &"TimerBar")
	_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(UIKit.vbox([_header, _progress, _stash], 2))
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
		var mana := UIKit.bar(runtime.current_mana, 1.0, &"ManaBar")
		mana.custom_minimum_size.y = 6
		var effects := UIKit.hbox([], 2)
		effects.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bars[hunter_id] = bar
		_mana[hunter_id] = mana
		_effects[hunter_id] = effects
		_portraits[hunter_id] = portrait
		var card := UIKit.card(UIKit.vbox([UIKit.hbox([portrait, UIKit.label(runtime.display_name, &"MutedLabel", false)], 4), bar, mana, effects], 2))
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
	_progress.max_value = maxi(sections, 1)
	_progress.value = _progress.max_value if run.boss_reached or run.phase == ExpeditionRun.Phase.RETURNING \
			else clampi(run.section_index, 0, sections)
	var items := 0
	for quantity in run.stash_items.values():
		items += quantity
	_stash.text = Loc.t("ui.expedition_hud.stash", {"gold": run.stash_gold, "items": items, "kills": run.kills})
	for hunter_id in _bars:
		var runtime := GameManager.hunters.get_hunter(hunter_id)
		var bar := _bars[hunter_id]
		bar.max_value = maxf(GameManager.hunters.get_stat(runtime, HunterService.MAX_HP), 1.0)
		bar.value = runtime.current_hp
		var mana := _mana[hunter_id]
		mana.max_value = maxf(GameManager.hunters.get_stat(runtime, HunterService.MAX_MANA), 1.0)
		mana.value = runtime.current_mana
		_refresh_effects(hunter_id, runtime)
		var down := run.downed_ids.has(hunter_id)
		if _portraits[hunter_id].downed != down:
			_portraits[hunter_id].downed = down
			_portraits[hunter_id].queue_redraw()


## One dot per status effect on the member's actor (D48 colours), rebuilt only when the set changes.
func _refresh_effects(hunter_id: StringName, runtime: HunterRuntime) -> void:
	var actor := _actor_of(runtime)
	var ids := PackedStringArray()
	var colors: Array[Color] = []
	if actor != null:
		for effect in actor.effects.get_effects():
			if effect.definition != null:
				ids.append(String(effect.definition.id))
				colors.append(effect.definition.color)
	var key := ",".join(ids)
	if _shown_effects.get(hunter_id, "") == key:
		return
	_shown_effects[hunter_id] = key
	var row := _effects[hunter_id]
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()
	for color in colors:
		var dot := ColorRect.new()
		dot.color = color
		dot.custom_minimum_size = Vector2(6, 6)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(dot)


func _actor_of(runtime: HunterRuntime) -> Hunter:
	for node in get_tree().get_nodes_in_group(Hunter.GROUP):
		var hunter := node as Hunter
		if hunter != null and hunter.runtime == runtime:
			return hunter
	return null
