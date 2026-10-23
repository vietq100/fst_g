class_name GateSheet
extends Sheet
## The Hunter Gate (D83): summon Hunters for tickets (×1 / ×10), see who just came, and the
## roster with an Expel button per Hunter (two taps: Expel → Confirm). Newcomers walk in through
## the Gate, awake into the village or asleep over the bridge to the Hibernation Mount.

var _confirm_id: StringName = &""
## Who the last summons called (shown until the sheet closes).
var _arrivals: Array[HunterRuntime] = []


func _init() -> void:
	title = Loc.t("ui.gate.title")


func _watch() -> Array:
	var gm := GameManager
	return [[gm.recruitment, &"hibernation_changed"], [gm.recruitment, &"arrivals_confirmed"], [gm.hunters, &"hunter_added"],
		[gm.hunters, &"hunter_removed"], [gm.hunters, &"hunter_changed"], [gm.wallet, &"tickets_changed"], [gm.housing, &"beds_changed"]]


func _build(content: VBoxContainer) -> void:
	var gm := GameManager
	var recruitment := gm.recruitment
	content.add_child(UIKit.label(Loc.t("ui.gate.counts", {"active": gm.hunters.count_active(), "active_max": recruitment.get_active_cap(),
		"asleep": gm.hunters.count_hibernating(), "asleep_max": recruitment.get_hibernation_cap(), "beds": gm.housing.get_free_beds()}), &"MutedLabel"))
	content.add_child(UIKit.label(Loc.t("ui.gate.summon_title"), &"AccentLabel"))
	var tickets := UIKit.hbox([PixelIcons.rect(&"mail", 2), UIKit.label(Loc.t("ui.gate.tickets", {"count": gm.wallet.summon_tickets}), &"HudLabel", false)], 4)
	content.add_child(tickets)
	var reason := recruitment.can_summon()
	var cost := recruitment.get_ticket_cost()
	var one := UIKit.button(Loc.t("ui.gate.summon_one", {"tickets": cost}), func() -> void: _summon(1), &"PrimaryButton", reason)
	var five := UIKit.button(Loc.t("ui.gate.summon_five", {"tickets": cost * 5}), func() -> void: _summon(5), &"", reason)
	var ten := UIKit.button(Loc.t("ui.gate.summon_ten", {"tickets": cost * 10}), func() -> void: _summon(10), &"", reason)
	content.add_child(UIKit.hbox([one, five, ten], 6))
	var effects := CheckButton.new()
	effects.text = Loc.t("ui.gate.effects_toggle")
	effects.button_pressed = SettingsStore.get_summon_effects()
	effects.custom_minimum_size.y = GameTheme.TOUCH
	effects.toggled.connect(func(enabled: bool) -> void: SettingsStore.set_summon_effects(enabled))
	content.add_child(effects)
	content.add_child(UIKit.label(Loc.t("ui.gate.summon_note" if recruitment.has_active_room() else "ui.gate.summon_note_asleep"), &"MutedLabel"))
	_arrivals = recruitment.last_arrivals
	if not _arrivals.is_empty():
		content.add_child(UIKit.label(Loc.t("ui.gate.arrivals"), &"AccentLabel"))
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override(&"h_separation", 4)
		grid.add_theme_constant_override(&"v_separation", 4)
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for hunter in _arrivals:
			if gm.hunters.get_hunter(hunter.unique_id) != null:
				grid.add_child(_arrival_card(hunter))
		content.add_child(grid)
	content.add_child(UIKit.separator())
	content.add_child(UIKit.label(Loc.t("ui.gate.expel_title"), &"AccentLabel"))
	content.add_child(UIKit.label(Loc.t("ui.gate.expel_note"), &"MutedLabel"))
	for hunter in gm.hunters.get_all():
		content.add_child(_roster_row(hunter))


## Calls the batch and shows the reveal (cards, or straight to the summary); they join on Confirm.
func _summon(count: int) -> void:
	var recruitment := GameManager.recruitment
	var called := recruitment.summon_batch(count)
	if called.is_empty():
		run_action(recruitment.can_summon())
		return
	get_tree().call_group(&"ui_root", &"open_summon_reveal", called, SettingsStore.get_summon_effects())
	request_rebuild()


## One newcomer: figure, name, tier, class and level, grade, where it went.
func _arrival_card(hunter: HunterRuntime) -> Control:
	var gm := GameManager
	var definition := gm.hunters.get_definition(hunter)
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"HunterCard"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := UIKit.label(hunter.display_name, &"HudSmallLabel", false)
	name_label.clip_text = true
	var code := UIKit.label(Tier.code(hunter.tier), &"HudSmallLabel", false)
	code.add_theme_color_override(&"font_color", Tier.color(hunter.tier))
	var top := UIKit.hbox([name_label, code], 4)
	var portrait := HunterFigure.new().setup(hunter, null)
	portrait.custom_minimum_size = Vector2(52, 72)
	var class_label := UIKit.label(Loc.t("ui.common.level_class", {"level": hunter.level, "class": definition.display_name if definition != null else "?"}), &"MutedLabel", false)
	class_label.clip_text = true
	var grade := gm.grades.hunter_grade(hunter)
	var grade_label := UIKit.label(Loc.t("ui.common.grade", {"grade": StatGradeService.name_of(grade)}), &"MutedLabel", false)
	grade_label.add_theme_font_size_override(&"font_size", GameTheme.SMALL_SIZE)
	grade_label.add_theme_color_override(&"font_color", StatGradeService.color(grade))
	var where := UIKit.label(Loc.t("ui.gate.went_asleep" if hunter.hibernating else "ui.gate.went_village"), &"HudSmallLabel", false)
	where.add_theme_color_override(&"font_color", Color("8fb3ff") if hunter.hibernating else GameTheme.GOOD)
	var side := UIKit.vbox([class_label, grade_label, where], 1)
	panel.add_child(UIKit.vbox([top, UIKit.hbox([portrait, side], 4)], 3))
	return panel


## Name, level and class with an Expel button; the first tap asks for confirmation.
func _roster_row(hunter: HunterRuntime) -> Control:
	var gm := GameManager
	var definition := gm.hunters.get_definition(hunter)
	var text := "%s  ·  %s" % [hunter.display_name, Loc.t("ui.common.level_class", {"level": hunter.level, "class": definition.display_name if definition != null else "?"})]
	if hunter.hibernating:
		text += "  ·  " + Loc.t("ui.hunters.status.asleep")
	var label := UIKit.label(text, &"", false)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	var reason := gm.recruitment.can_dismiss(hunter)
	var button: Button
	if _confirm_id == hunter.unique_id:
		button = UIKit.button(Loc.t("ui.common.confirm"), func() -> void:
			_confirm_id = &""
			var name := hunter.display_name
			run_action(gm.recruitment.dismiss(hunter), Loc.t("ui.gate.expelled", {"name": name})), &"DangerButton", reason)
	else:
		button = UIKit.button(Loc.t("ui.gate.expel"), func() -> void:
			_confirm_id = hunter.unique_id
			request_rebuild(), &"", reason)
	button.custom_minimum_size = Vector2(72, GameTheme.TOUCH)
	return UIKit.hbox([label, button], 6)
