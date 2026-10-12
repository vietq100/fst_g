class_name DebugPanel
extends PanelContainer
## Developer-only panel for validating phases before the real UI (DECISIONS.md D22).
## Removed in release builds. Tap the header (or press F1 on desktop) to collapse.
## `set_status` is owned by Main (gold, last run); the content below belongs to the world.

const FONT_SIZE := 12
## Wrapped labels need a fixed width or the panel collapses to one word per line.
const WIDTH := 236.0
## Collapsed: just the header button, so it hides as little of the game as possible.
const COLLAPSED_WIDTH := 80.0

@onready var _header: Button = %Header
@onready var _body: VBoxContainer = %Body
@onready var _status: Label = %Status
@onready var _content: VBoxContainer = %Content


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	var panel_theme := Theme.new()
	panel_theme.default_font_size = FONT_SIZE
	theme = panel_theme
	_header.pressed.connect(toggle)
	# Starts collapsed: the game UI is the real UI; this is for developers.
	_body.visible = true
	toggle()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_debug"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	_body.visible = not _body.visible
	_header.text = "Dev %s" % ("-" if _body.visible else "+")
	custom_minimum_size.x = WIDTH if _body.visible else COLLAPSED_WIDTH
	reset_size()
	# Anchored top-right: keep the right edge fixed while the size changes.
	position.x = get_parent_area_size().x - size.x - 4.0
	# Below the HUD header so it never covers the shortcuts.
	position.y = 196.0


func set_status(text: String) -> void:
	_status.text = text
	_status.visible = not text.is_empty()


func add_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(label)
	return label


func add_button(text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 40.0
	button.pressed.connect(on_pressed)
	_content.add_child(button)
	return button


## Buttons side by side to save vertical space. `buttons` is an array of [text, Callable].
func add_button_row(buttons: Array) -> Array[Button]:
	var row := HBoxContainer.new()
	var created: Array[Button] = []
	for entry: Array in buttons:
		var button := Button.new()
		button.text = entry[0]
		button.custom_minimum_size = Vector2(40.0, 40.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(entry[1])
		row.add_child(button)
		created.append(button)
	_content.add_child(row)
	return created


func add_separator() -> void:
	_content.add_child(HSeparator.new())


## Removes the world's content (the status line stays).
func clear() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	reset_size()
