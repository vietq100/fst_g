class_name SettingsSheet
extends Sheet
## Settings (gear button in the top bar): the language picker (LOCALIZATION.md, D61) and the music and
## sound volumes (D78, saved at once). Picking another language saves it; Main then saves the game and
## reloads the scene in that language. Not allowed during a dungeon run (the reload would drop the live run).

## Volume slider steps (0..1).
const VOLUME_STEP := 0.1


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
	if SaveManager.has_profile():
		content.add_child(UIKit.label(Loc.t("ui.settings.profile"), &"AccentLabel"))
		content.add_child(UIKit.label(Loc.t("ui.settings.playing_as", {"name": ProfileStore.get_profile(SaveManager.profile_id).get("name", "")}), &"MutedLabel"))
		content.add_child(UIKit.button(Loc.t("ui.settings.switch_profile"), func() -> void:
			get_tree().call_group(&"ui_root", &"request_logout"), &"", Loc.t("ui.settings.busy_dungeon") if busy else ""))
	content.add_child(UIKit.label(Loc.t("ui.settings.audio"), &"AccentLabel"))
	content.add_child(_volume_row(Loc.t("ui.settings.music"), Audio.MUSIC_BUS))
	content.add_child(_volume_row(Loc.t("ui.settings.sounds"), Audio.SFX_BUS))
	content.add_child(UIKit.label(Loc.t("ui.settings.display"), &"AccentLabel"))
	var shake := CheckButton.new()
	shake.text = Loc.t("ui.settings.screen_shake")
	shake.button_pressed = SettingsStore.get_screen_shake()
	shake.custom_minimum_size.y = GameTheme.TOUCH
	shake.toggled.connect(func(enabled: bool) -> void: SettingsStore.set_screen_shake(enabled))
	content.add_child(shake)


## "Name [slider]" for a bus; changes apply and save at once (0 mutes).
func _volume_row(text: String, bus: StringName) -> HBoxContainer:
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = VOLUME_STEP
	slider.value = Audio.get_volume(bus)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.y = GameTheme.TOUCH
	slider.value_changed.connect(func(value: float) -> void: Audio.set_volume(bus, value))
	var label := UIKit.label(text)
	label.custom_minimum_size.x = 80
	return UIKit.hbox([label, slider], 8)
