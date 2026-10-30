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
	if _skill == null:
		return
	var is_tap: bool = (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if is_tap:
		accept_event()
		get_tree().call_group(&"ui_root", &"open_skill_info", _skill, _options)


func _draw() -> void:
	if _skill == null:
		return
	var active := SkillIcons.is_active(_skill)
	var plate := Rect2(Vector2((size.x - SIDE) * 0.5, 2.0), Vector2(SIDE, SIDE))
	var rim := Color("f97316") if active else Color("38bdf8")

	var box := StyleBoxFlat.new()
	box.bg_color = Color("12151f")
	box.border_color = rim.darkened(0.2)
	box.set_border_width_all(2)
	box.border_width_bottom = 3
	box.set_corner_radius_all(6)
	box.shadow_color = Color(0, 0, 0, 0.45)
	box.shadow_size = 3
	box.shadow_offset = Vector2(0, 1)
	draw_style_box(box, plate.grow(2.0))

	# Inner glowing sheen on top
	draw_rect(Rect2(plate.position + Vector2(2, 2), Vector2(SIDE - 4.0, 2.0)), Color(rim.lightened(0.2), 0.35))

	draw_texture_rect(SkillIcons.texture(_skill, 2), plate, false)

	# Grade bar along the plate foot: the skill's stars against the other skills of its kind (D80).
	if _skill is ClassSkillDefinition and is_instance_valid(GameManager) and GameManager.grades != null:
		var grade_color := StatGradeService.color(GameManager.grades.skill_grade(_skill))
		var bar_rect := Rect2(plate.position + Vector2(1.0, SIDE - 4.0), Vector2(SIDE - 2.0, 3.0))
		draw_rect(bar_rect, Color("090b0f"))
		draw_rect(bar_rect.grow(-0.5), grade_color)

	if _badge != "":
		var font := ThemeDB.fallback_font
		var font_size := 11
		var width := font.get_string_size(_badge, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 8.0
		var tag := Rect2(plate.end - Vector2(width + 1.0, 15.0), Vector2(width, 15.0))
		var tag_box := StyleBoxFlat.new()
		tag_box.bg_color = Color("090b0f", 0.92)
		tag_box.border_color = Color(rim, 0.75)
		tag_box.set_border_width_all(1)
		tag_box.set_corner_radius_all(3)
		draw_style_box(tag_box, tag)
		draw_string_outline(font, tag.position + Vector2(4.0, 11.0), _badge, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color("090b0f"))
		draw_string(font, tag.position + Vector2(4.0, 11.0), _badge, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("fef3c7"))

	var name_rect := Rect2(Vector2(0.0, plate.end.y + 4.0), Vector2(size.x, NAME_HEIGHT))
	var font := ThemeDB.fallback_font
	var lines := _wrap(_skill.display_name, font, 12, size.x - 4.0)
	for i in mini(lines.size(), 2):
		var line: String = lines[i]
		var width := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		var at := Vector2((size.x - width) * 0.5, name_rect.position.y + 11.0 + i * 13.0)
		draw_string_outline(font, at, line, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color("090b0f"))
		draw_string(font, at, line, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("f7f4ec"))


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
