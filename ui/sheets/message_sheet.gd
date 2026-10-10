class_name MessageSheet
extends Sheet
## Simple information sheet: expedition results, "while you were away".

var _lines: PackedStringArray


func _init(sheet_title: String, lines: PackedStringArray) -> void:
	title = sheet_title
	_lines = lines


func _build(content: VBoxContainer) -> void:
	for line in _lines:
		content.add_child(UIKit.label(line))
	content.add_child(UIKit.button("OK", func() -> void: closed.emit(), &"PrimaryButton"))


## Text for an expedition result (EXPEDITION_SYSTEM.md → Completion / Failure).
static func for_expedition(run: ExpeditionRun) -> MessageSheet:
	var success := run.phase == ExpeditionRun.Phase.SUCCESS
	var lines := PackedStringArray()
	lines.append("%s · %d enemies defeated" % ["Victory" if success else "The party was defeated", run.kills])
	if success and run.is_first_clear:
		lines.append("First clear! The Town Hall can now be upgraded.")
	lines.append("+%d gold%s" % [run.gold_granted, "" if success else " (half the loot was lost)"])
	if not run.items_granted.is_empty():
		lines.append("Items: " + ItemText.describe(run.items_granted, DataRegistry))
	if not run.items_overflowed.is_empty():
		lines.append("Warehouse full — sold %s for %d gold" % [ItemText.describe(run.items_overflowed, DataRegistry), run.overflow_gold])
	var levels := 0
	for gained in run.levels_gained.values():
		levels += gained
	lines.append("XP %d per Hunter%s" % [run.xp_per_hunter, " · %d level-ups" % levels if levels > 0 else ""])
	if not run.downed_ids.is_empty():
		var names := PackedStringArray()
		for id in run.downed_ids:
			var hunter := GameManager.hunters.get_hunter(id)
			if hunter != null:
				names.append(hunter.display_name)
		lines.append("Injured: %s — recovering at the Hospital" % ", ".join(names))
	return MessageSheet.new("Victory" if success else "Defeat", lines)


## "While you were away" (DECISIONS.md D24).
static func for_offline(summary: Dictionary) -> MessageSheet:
	var lines := PackedStringArray()
	lines.append("You were away for %s%s." % [UIKit.format_duration(summary["seconds"]),
		" (progress is capped at %d hours)" % int(DataRegistry.config.offline_cap_hours) if summary.get("capped", false) else ""])
	var recovered: PackedStringArray = summary.get("recovered", PackedStringArray())
	if not recovered.is_empty():
		lines.append("Recovered at the Hospital: " + ", ".join(recovered))
	if int(summary.get("xp", 0)) > 0:
		lines.append("Training: +%d XP across your Hunters%s" % [int(summary["xp"]), " · %d level-ups" % int(summary["levels"]) if int(summary.get("levels", 0)) > 0 else ""])
	if lines.size() == 1:
		lines.append("Your Hunters rested in town.")
	return MessageSheet.new("While you were away", lines)
