class_name ProfileScreen
extends Control
## Login screen (a stand-in until real accounts exist): pick one of the local profiles to play, create
## a new one by name, or delete one (tap twice). Shown by Main at start and after "Switch profile".

signal chosen(profile_id: String)

const GOLD := Color("e8c35a")
const CREAM := Color("f4ead2")
const PANEL := Color(0.09, 0.07, 0.055, 0.9)
const RIM := Color("8c7552")

var _list: VBoxContainer
var _name_input: LineEdit
## Profile whose delete button was tapped once.
var _delete_armed := ""


func _ready() -> void:
	theme = GameTheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var solid := ColorRect.new()
	solid.color = Color("070b18")
	solid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(solid)
	var backdrop := ProfileBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	add_child(margin)
	var column := UIKit.vbox([], 12)
	margin.add_child(column)
	column.add_child(_logo())
	# The profiles on a dark framed panel over the village.
	var frame := ItemInfoModal.Frame.new()
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(frame)
	var inner := UIKit.vbox([], 8)
	frame.add_child(inner)
	var banner := ItemInfoModal.Banner.new()
	banner.text = Loc.t("ui.profile.title")
	inner.add_child(banner)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(scroll)
	_list = UIKit.vbox([], 8)
	scroll.add_child(_list)
	_name_input = LineEdit.new()
	_name_input.placeholder_text = Loc.t("ui.profile.name_hint")
	_name_input.max_length = ProfileStore.MAX_NAME
	_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_input.custom_minimum_size.y = 44
	_name_input.text_submitted.connect(func(_text: String) -> void: _create())
	var create := UIKit.button(Loc.t("ui.profile.create"), _create)
	create.size_flags_horizontal = Control.SIZE_SHRINK_END
	create.custom_minimum_size = Vector2(100, 44)
	ItemInfoModal._style_button(create, Color("2f5a2a"), GOLD.darkened(0.3))
	create.size_flags_horizontal = Control.SIZE_SHRINK_END
	inner.add_child(UIKit.hbox([_name_input, create], 6))
	ProfilePresets.install_missing()
	_rebuild()


## Game name in big outlined gold letters with a thin rule and the subtitle under it.
func _logo() -> Control:
	var title := Label.new()
	title.text = str(ProjectSettings.get_setting("application/config/name", "Dark Hunter Tycoon")).to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override(&"font_size", 30)
	title.add_theme_color_override(&"font_color", GOLD)
	title.add_theme_color_override(&"font_outline_color", Color("1a0d05"))
	title.add_theme_constant_override(&"outline_size", 10)
	title.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.6))
	title.add_theme_constant_override(&"shadow_offset_y", 3)
	var subtitle := Label.new()
	subtitle.text = Loc.t("ui.profile.subtitle")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override(&"font_size", 13)
	subtitle.add_theme_color_override(&"font_color", CREAM)
	subtitle.add_theme_color_override(&"font_outline_color", Color("0b0805"))
	subtitle.add_theme_constant_override(&"outline_size", 4)
	return UIKit.vbox([title, subtitle], 2)


func _rebuild() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	# The three sample slots (Lv 10 / 50 / 100) first, then the player's own profiles.
	var profiles: Array[Dictionary] = []
	for preset: Dictionary in ProfilePresets.PRESETS:
		for profile in ProfileStore.list():
			if str(profile.get("preset", "")) == preset["id"]:
				profiles.append(profile)
	for profile in ProfileStore.list():
		if str(profile.get("preset", "")).is_empty():
			profiles.append(profile)
	if profiles.is_empty():
		var empty := _small(Loc.t("ui.profile.empty"), Color("b9b0dc"), 14)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_list.add_child(empty)
	for profile in profiles:
		_list.add_child(_card(profile))


func _card(profile: Dictionary) -> Control:
	var id: String = profile["id"]
	var summary := Loc.t("ui.profile.summary", {"town": int(profile.get("town", 1)), "hunters": int(profile.get("hunters", 0)), "gold": int(profile.get("gold", 0))})
	var played := Time.get_datetime_string_from_unix_time(int(profile.get("played", 0.0)), true)
	var name_label := Label.new()
	name_label.text = profile["name"]
	name_label.add_theme_font_size_override(&"font_size", 18)
	name_label.add_theme_color_override(&"font_color", GOLD)
	name_label.add_theme_color_override(&"font_outline_color", Color("0b0805"))
	name_label.add_theme_constant_override(&"outline_size", 4)
	name_label.clip_text = true
	var info := UIKit.vbox([name_label, _small(summary, CREAM, 13), _small(Loc.t("ui.profile.last_played", {"date": played}), Color("9a917c"), 11)], 2)
	var avatar := PanelContainer.new()
	var avatar_style := StyleBoxFlat.new()
	avatar_style.bg_color = Color("14110e")
	avatar_style.border_color = GOLD
	avatar_style.set_border_width_all(2)
	avatar_style.set_corner_radius_all(4)
	avatar_style.set_content_margin_all(6)
	avatar.add_theme_stylebox_override(&"panel", avatar_style)
	avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	avatar.add_child(PixelIcons.rect(&"hunters", 3))
	var play := UIKit.button(Loc.t("ui.profile.play"), func() -> void: chosen.emit(id))
	play.custom_minimum_size = Vector2(82, 40)
	ItemInfoModal._style_button(play, Color("2f6a30"), GOLD.darkened(0.2))
	play.add_theme_font_size_override(&"font_size", 16)
	play.size_flags_horizontal = Control.SIZE_SHRINK_END
	var armed := _delete_armed == id
	var remove := UIKit.button(Loc.t("ui.profile.delete_confirm") if armed else Loc.t("ui.profile.delete"), func() -> void:
		if _delete_armed == id:
			_delete_armed = ""
			ProfileStore.delete(id)
		else:
			_delete_armed = id
		_rebuild())
	remove.custom_minimum_size = Vector2(82, 28)
	remove.add_theme_font_size_override(&"font_size", 11)
	remove.clip_text = true
	ItemInfoModal._style_button(remove, Color("7a2a22") if armed else ItemInfoModal.BUTTON, Color("c8562a") if armed else ItemInfoModal.FRAME_RIM.darkened(0.2))
	remove.size_flags_horizontal = Control.SIZE_SHRINK_END
	var buttons := UIKit.vbox([play, remove], 4)
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_END
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("241d17")
	style.border_color = RIM
	style.set_border_width_all(1)
	style.border_width_left = 4
	style.border_color = RIM
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	card.add_theme_stylebox_override(&"panel", style)
	card.add_child(UIKit.hbox([avatar, info, buttons], 10))
	return card


func _small(text: String, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	return label


func _create() -> void:
	var id := ProfileStore.create(_name_input.text)
	_name_input.text = ""
	chosen.emit(id)
