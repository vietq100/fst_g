class_name GateSheet
extends Sheet
## The Hunter Gate (D58): the "Hunters waiting" board (hire candidates, paid refresh) and the
## roster with an Expel button per Hunter (two taps: Expel → Confirm).

var _confirm_id: StringName = &""


func _init() -> void:
	title = Loc.t("ui.gate.title")


func _watch() -> Array:
	var gm := GameManager
	return [[gm.recruitment, &"candidates_changed"], [gm.hunters, &"hunter_added"], [gm.hunters, &"hunter_removed"],
		[gm.hunters, &"hunter_changed"], [gm.wallet, &"gold_changed"]]


func _build(content: VBoxContainer) -> void:
	var gm := GameManager
	var recruitment := gm.recruitment
	content.add_child(UIKit.label(Loc.t("ui.gate.roster", {"count": gm.hunters.count(), "max": recruitment.get_capacity(), "beds": gm.housing.get_free_beds()}), &"MutedLabel"))
	content.add_child(UIKit.label(Loc.t("ui.gate.waiting"), &"AccentLabel"))
	if recruitment.candidates.is_empty():
		content.add_child(UIKit.label(Loc.t("ui.gate.nobody_waiting"), &"MutedLabel"))
	# Two columns of candidate cards (like the reference game's "Hunters Waiting" board).
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 4)
	grid.add_theme_constant_override(&"v_separation", 4)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in recruitment.candidates.size():
		grid.add_child(_candidate_card(i))
	content.add_child(grid)
	# Roster full: show the reason (checked by count, never by the displayed text).
	if not recruitment.candidates.is_empty() and gm.hunters.count() >= recruitment.get_capacity():
		content.add_child(UIKit.label(recruitment.can_recruit(0), &"WarningLabel"))
	var cost := recruitment.get_refresh_cost()
	content.add_child(UIKit.button(Loc.t("ui.gate.refresh", {"gold": cost}), func() -> void:
		run_action("" if recruitment.paid_refresh() else Loc.t("ui.common.needs_gold", {"gold": cost})),
		&"", "" if gm.wallet.can_spend(cost) else Loc.t("ui.common.needs_gold", {"gold": cost})))
	content.add_child(UIKit.label(Loc.t("ui.gate.refresh_note"), &"MutedLabel"))
	content.add_child(UIKit.separator())
	content.add_child(UIKit.label(Loc.t("ui.gate.expel_title"), &"AccentLabel"))
	content.add_child(UIKit.label(Loc.t("ui.gate.expel_note"), &"MutedLabel"))
	for hunter in gm.hunters.get_all():
		content.add_child(_roster_row(hunter))


## One candidate: portrait, name and class, talent star, traits, stats and the Hire button.
func _candidate_card(index: int) -> Control:
	var recruitment := GameManager.recruitment
	var hunters := GameManager.hunters
	var candidate := recruitment.candidates[index]
	var talent := GameManager.talents.get_talent(candidate)
	var traits := PackedStringArray()
	for definition in GameManager.traits.get_traits(candidate):
		traits.append(definition.display_name)
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"HunterCard"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var star := PixelIcons.rect(&"star", 1)
	star.modulate = Color.WHITE if talent != null else Color(1, 1, 1, 0.25)
	star.tooltip_text = talent.display_name if talent != null else Loc.t("ui.hunter.no_talent")
	var name_label := UIKit.label(candidate.display_name, &"HudSmallLabel", false)
	name_label.clip_text = true
	var top := UIKit.hbox([star, name_label], 2)
	var portrait := HunterFigure.new().setup(candidate, null)
	portrait.custom_minimum_size = Vector2(52, 72)
	var class_label := UIKit.label(Loc.t("ui.common.level_class", {"level": candidate.level, "class": hunters.get_definition(candidate).display_name}), &"MutedLabel", false)
	class_label.clip_text = true
	var stats := UIKit.label(Loc.t("ui.gate.candidate_stats", {"hp": "%d" % hunters.get_stat(candidate, HunterService.MAX_HP),
		"atk": "%.0f" % hunters.get_stat(candidate, HunterService.ATTACK), "def": "%.0f" % hunters.get_stat(candidate, HunterService.DEFENSE)}), &"MutedLabel", false)
	stats.add_theme_font_size_override(&"font_size", 9)
	stats.clip_text = true
	var side := UIKit.vbox([class_label, stats], 1)
	var trait_text := ", ".join(traits) + ("  ·  %s" % talent.display_name if talent != null else "")
	var trait_label := UIKit.label(trait_text, &"HudAccentLabel")
	trait_label.add_theme_font_size_override(&"font_size", 9)
	var reason := recruitment.can_recruit(index)
	var recruit := UIKit.button(Loc.t("ui.gate.hire", {"gold": recruitment.get_recruit_cost(index)}), func() -> void:
		var hunter := recruitment.recruit(index)
		run_action("" if hunter != null else recruitment.can_recruit(index),
			Loc.t("ui.gate.hired", {"name": hunter.display_name}) if hunter != null else ""), &"PrimaryButton", reason)
	recruit.custom_minimum_size.y = 32
	recruit.add_theme_font_size_override(&"font_size", 11)
	panel.add_child(UIKit.vbox([top, UIKit.hbox([portrait, side], 4), trait_label, recruit], 3))
	return panel


## Name, level and class with an Expel button; the first tap asks for confirmation.
func _roster_row(hunter: HunterRuntime) -> Control:
	var gm := GameManager
	var definition := gm.hunters.get_definition(hunter)
	var label := UIKit.label("%s  ·  %s" % [hunter.display_name, Loc.t("ui.common.level_class", {"level": hunter.level, "class": definition.display_name if definition != null else "?"})], &"", false)
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
	button.custom_minimum_size = Vector2(72, 32)
	return UIKit.hbox([label, button], 6)
