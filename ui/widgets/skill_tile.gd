class_name SkillTile
extends Control
## Square skill slot: the skill's generated icon on a rimmed plate, a level badge in the corner and
## the skill's name under it. Tapping opens the skill's details (SkillInfoModal) over the screen.
## `options` is handed to the modal: {level, lines, actions}.

const SIDE := 60.0
const NAME_HEIGHT := 30.0

var _skill: GameDefinition
var _options: Dictionary = {}
var _badge := ""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(SIDE + 8.0, SIDE + NAME_HEIGHT + 4.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL


func setup(skill: GameDefinition, options: Dictionary = {}, badge: String = "") -> SkillTile:
	_skill = skill
	_options = options
	_badge = badge
	tooltip_text = skill.display_name
	queue_redraw()
	return self


func _gui_input(event: InputEvent) -> void:
	if _skill != null and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		get_tree().call_group(&"ui_root", &"open_skill_info", _skill, _options)


func _draw() -> void:
	if _skill == null:
		return
	var active := SkillIcons.is_active(_skill)
	var plate := Rect2(Vector2((size.x - SIDE) * 0.5, 2.0), Vector2(SIDE, SIDE))
	var rim := Color("e0874a") if active else Color("5fa8ff")
	draw_rect(plate.grow(2.0), rim.darkened(0.45))
	draw_rect(plate.grow(1.0), rim)
	draw_texture_rect(SkillIcons.texture(_skill, 2), plate, false)
	if _badge != "":
		var font := ThemeDB.fallback_font
		var width := font.get_string_size(_badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 8.0
		var tag := Rect2(plate.end - Vector2(width, 16.0), Vector2(width, 16.0))
		draw_rect(tag, Color(0.06, 0.05, 0.04, 0.9))
		draw_string(font, tag.position + Vector2(4.0, 12.0), _badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("f4ead2"))
	var name_rect := Rect2(Vector2(0.0, plate.end.y + 3.0), Vector2(size.x, NAME_HEIGHT))
	var font := ThemeDB.fallback_font
	var lines := _wrap(_skill.display_name, font, 12, size.x - 4.0)
	for i in mini(lines.size(), 2):
		var line: String = lines[i]
		var width := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		var at := Vector2((size.x - width) * 0.5, name_rect.position.y + 11.0 + i * 13.0)
		draw_string_outline(font, at, line, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color("0b0805"))
		draw_string(font, at, line, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("f4ead2"))


static func _wrap(text: String, font: Font, font_size: int, max_width: float) -> Array[String]:
	var lines: Array[String] = []
	var current := ""
	for word in text.split(" "):
		var trial := word if current.is_empty() else current + " " + word
		if current.is_empty() or font.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= max_width:
			current = trial
		else:
			lines.append(current)
			current = word
	if not current.is_empty():
		lines.append(current)
	return lines


## Grid of tiles, four per row.
static func grid(tiles: Array) -> GridContainer:
	var container := GridContainer.new()
	container.columns = 4
	container.add_theme_constant_override(&"h_separation", 4)
	container.add_theme_constant_override(&"v_separation", 6)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for tile in tiles:
		container.add_child(tile)
	return container
