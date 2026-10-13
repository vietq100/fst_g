class_name SettingsSheet
extends Sheet
## Settings (gear button in the top bar): the language picker (LOCALIZATION.md, D61). Picking
## another language saves it; Main then saves the game and reloads the scene in that language.
## Not allowed during a dungeon run (the reload would drop the live run).


func _init() -> void:
	title = Loc.t("ui.settings.title")


func _watch() -> Array:
	var gm := GameManager
	return [[gm.expeditions, &"expedition_started"], [gm.expeditions, &"expedition_finished"]]


func _build(content: VBoxContainer) -> void:
	content.add_child(UIKit.label(Loc.t("ui.settings.language"), &"AccentLabel"))
	var busy := GameManager.expeditions.is_running()
	var row := UIKit.hbox([], 6)
	for code in Loc.LOCALES:
		var current := code == Loc.locale
		# Language names are shown in their own language (never translated).
		var reason := Loc.t("ui.settings.busy_dungeon") if busy and not current else ""
		row.add_child(UIKit.button(Loc.LOCALE_NAMES[code], func() -> void:
			if not current:
				Loc.set_locale(code), &"PrimaryButton" if current else &"", reason))
	content.add_child(row)
	if busy:
		content.add_child(UIKit.label(Loc.t("ui.settings.busy_dungeon"), &"WarningLabel"))
	content.add_child(UIKit.label(Loc.t("ui.settings.language_note"), &"MutedLabel"))
