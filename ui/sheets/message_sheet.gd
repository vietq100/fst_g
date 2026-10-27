class_name MessageSheet
extends Sheet
## Simple information sheet: expedition results, "while you were away".

var _lines: PackedStringArray


func _init(sheet_title: String, lines: PackedStringArray) -> void:
	title = sheet_title
	_lines = lines


func _build(content: VBoxContainer) -> void:
	var list := UIKit.vbox([], 6)
	for line in _lines:
		list.add_child(UIKit.label(line))
	content.add_child(UIKit.card(list))
	content.add_child(UIKit.button(Loc.t("ui.common.ok"), func() -> void: closed.emit(), &"PrimaryButton"))


## Text for an expedition result (EXPEDITION_SYSTEM.md → Completion / Failure).
static func for_expedition(run: ExpeditionRun) -> MessageSheet:
	var success := run.phase == ExpeditionRun.Phase.SUCCESS
	var lines := PackedStringArray()
	lines.append(Loc.t("ui.message.result_victory" if success else "ui.message.result_defeat", {"kills": run.kills}))
	if success and run.is_first_clear:
		lines.append(Loc.t("ui.message.first_clear"))
	lines.append(Loc.t("ui.message.gold_gained" if success else "ui.message.gold_gained_half", {"gold": run.gold_granted}))
	if not run.items_granted.is_empty():
		lines.append(Loc.t("ui.message.items", {"items": ItemText.describe(run.items_granted, DataRegistry)}))
	if not run.items_overflowed.is_empty():
		lines.append(Loc.t("ui.message.overflow", {"items": ItemText.describe(run.items_overflowed, DataRegistry), "gold": run.overflow_gold}))
	var levels := 0
	for gained in run.levels_gained.values():
		levels += gained
	lines.append(Loc.t("ui.message.xp_levels" if levels > 0 else "ui.message.xp", {"xp": run.xp_per_hunter, "levels": levels}))
	if not run.downed_ids.is_empty():
		var names := PackedStringArray()
		for id in run.downed_ids:
			var hunter := GameManager.hunters.get_hunter(id)
			if hunter != null:
				names.append(hunter.display_name)
		lines.append(Loc.t("ui.message.fallen", {"names": ", ".join(names)}))
	return MessageSheet.new(Loc.t("ui.message.title_victory") if success else Loc.t("ui.message.title_defeat"), lines)


## "While you were away" (DECISIONS.md D24).
static func for_offline(summary: Dictionary) -> MessageSheet:
	var lines := PackedStringArray()
	lines.append(Loc.t("ui.message.away_capped" if summary.get("capped", false) else "ui.message.away", {
		"time": UIKit.format_duration(summary["seconds"]), "hours": int(DataRegistry.config.offline_cap_hours)}))
	var recovered: PackedStringArray = summary.get("recovered", PackedStringArray())
	if not recovered.is_empty():
		lines.append(Loc.t("ui.message.recovered", {"names": ", ".join(recovered)}))
	if int(summary.get("xp", 0)) > 0:
		var levels := int(summary.get("levels", 0))
		lines.append(Loc.t("ui.message.training_levels" if levels > 0 else "ui.message.training", {"xp": int(summary["xp"]), "levels": levels}))
	if int(summary.get("meals", 0)) > 0:
		lines.append(Loc.t("ui.message.meals", {"meals": int(summary["meals"])}))
	if int(summary.get("hungry_ticks", 0)) > 0:
		lines.append(Loc.t("ui.message.hungry"))
	if lines.size() == 1:
		lines.append(Loc.t("ui.message.rested"))
	return MessageSheet.new(Loc.t("ui.message.offline_title"), lines)
