class_name HibernationSheet
extends Sheet
## The Hibernation Mount (D83): the sleepers with a Wake button each, the awake Hunters with a
## Sleep button each, and Swap: pick one of each and they trade places (both walk over the bridge).

## The awake Hunter picked for a swap (empty: none).
var _swap_awake: StringName = &""


func _init() -> void:
	title = Loc.t("ui.mount.title")


func _watch() -> Array:
	var gm := GameManager
	return [[gm.recruitment, &"hibernation_changed"], [gm.hunters, &"hunter_added"], [gm.hunters, &"hunter_removed"],
		[gm.hunters, &"hunter_changed"], [gm.housing, &"beds_changed"]]


func _build(content: VBoxContainer) -> void:
	var gm := GameManager
	var recruitment := gm.recruitment
	content.add_child(UIKit.label(Loc.t("ui.mount.counts", {"active": gm.hunters.count_active(), "active_max": recruitment.get_active_cap(),
		"asleep": gm.hunters.count_hibernating(), "asleep_max": recruitment.get_hibernation_cap(), "beds": gm.housing.get_free_beds()}), &"MutedLabel"))
	content.add_child(UIKit.label(Loc.t("ui.mount.note"), &"MutedLabel"))
	var sleepers := gm.hunters.get_hibernating()
	sleepers.sort_custom(_by_level)
	var awake := gm.hunters.get_active()
	awake.sort_custom(_by_level)
	content.add_child(UIKit.label(Loc.t("ui.mount.asleep", {"count": sleepers.size()}), &"AccentLabel"))
	if sleepers.is_empty():
		content.add_child(UIKit.label(Loc.t("ui.mount.nobody_asleep"), &"MutedLabel"))
	for hunter in sleepers:
		content.add_child(_row(hunter, true))
	content.add_child(UIKit.separator())
	content.add_child(UIKit.label(Loc.t("ui.mount.awake", {"count": awake.size()}), &"AccentLabel"))
	if _swap_awake != &"":
		var picked := gm.hunters.get_hunter(_swap_awake)
		content.add_child(UIKit.label(Loc.t("ui.mount.swap_hint", {"name": picked.display_name if picked != null else "?"}), &"WarningLabel"))
	for hunter in awake:
		content.add_child(_row(hunter, false))


static func _by_level(a: HunterRuntime, b: HunterRuntime) -> bool:
	return a.level > b.level or (a.level == b.level and String(a.unique_id) < String(b.unique_id))


## Name · level / class · grade, with Wake (sleepers) or Sleep + Swap (awake).
func _row(hunter: HunterRuntime, asleep: bool) -> Control:
	var gm := GameManager
	var recruitment := gm.recruitment
	var definition := gm.hunters.get_definition(hunter)
	var grade := gm.grades.hunter_grade(hunter)
	var name_label := UIKit.label("%s  ·  %s" % [hunter.display_name, Loc.t("ui.common.level_class", {"level": hunter.level, "class": definition.display_name if definition != null else "?"})], &"", false)
	name_label.clip_text = true
	var grade_label := UIKit.label(StatGradeService.name_of(grade), &"HudSmallLabel", false)
	grade_label.add_theme_color_override(&"font_color", StatGradeService.color(grade))
	var info := UIKit.vbox([name_label, grade_label], 0)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var buttons := UIKit.hbox([], 4)
	if asleep:
		if _swap_awake != &"":
			var awake := gm.hunters.get_hunter(_swap_awake)
			var swap := UIKit.button(Loc.t("ui.mount.swap"), func() -> void:
				_swap_awake = &""
				run_action(recruitment.swap(awake, hunter), Loc.t("ui.mount.swapped", {"a": awake.display_name if awake != null else "?", "b": hunter.display_name})), &"PrimaryButton")
			swap.custom_minimum_size = Vector2(72, GameTheme.TOUCH)
			buttons.add_child(swap)
		var wake := UIKit.button(Loc.t("ui.mount.wake"), func() -> void:
			run_action(recruitment.activate(hunter), Loc.t("ui.mount.woke", {"name": hunter.display_name})), &"Button", recruitment.can_activate(hunter))
		wake.custom_minimum_size = Vector2(72, GameTheme.TOUCH)
		buttons.add_child(wake)
	else:
		var pick := UIKit.button(Loc.t("ui.mount.pick_swap"), func() -> void:
			_swap_awake = &"" if _swap_awake == hunter.unique_id else hunter.unique_id
			request_rebuild(), &"SelectedButton" if _swap_awake == hunter.unique_id else &"Button", recruitment.can_hibernate(hunter))
		pick.custom_minimum_size = Vector2(60, GameTheme.TOUCH)
		buttons.add_child(pick)
		var sleep := UIKit.button(Loc.t("ui.mount.sleep"), func() -> void:
			run_action(recruitment.hibernate(hunter), Loc.t("ui.mount.slept", {"name": hunter.display_name})), &"Button", recruitment.can_hibernate(hunter))
		sleep.custom_minimum_size = Vector2(72, GameTheme.TOUCH)
		buttons.add_child(sleep)
	return UIKit.hbox([info, buttons], 6)
