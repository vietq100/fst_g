class_name Sheet
extends PanelContainer
## Base bottom sheet (UI_DESIGN.md → Mobile layout): title, close button, scrolling content.
## Subclasses implement `_build(content)` using services only (no gameplay rules in UI) and
## list the signals that should rebuild them in `_watch()`. Rebuilds are coalesced per frame.

signal closed
## Ask the UI root to open another sheet (e.g. a Hunter from the list).
signal open_requested(sheet: Sheet)
## Show a short message (errors from actions, confirmations).
signal toast_requested(text: String, is_error: bool)

var title := ""
var _content: VBoxContainer
var _title_label: Label
## Title row; subclasses may add buttons to it.
var _header: HBoxContainer
var _rebuild_queued := false
var _watched: Array[Array] = []


func _ready() -> void:
	theme_type_variation = &"Sheet"
	mouse_filter = Control.MOUSE_FILTER_STOP
	var layout := UIKit.vbox([], 6)
	add_child(layout)
	_title_label = UIKit.label(title, &"TitleLabel", false)
	var close := UIKit.button("", func() -> void: closed.emit(), &"RoundButton")
	close.icon = PixelIcons.texture(&"close", 2)
	close.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	close.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.custom_minimum_size = Vector2(36, 36)
	_header = UIKit.hbox([_title_label, close])
	layout.add_child(_header)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	_content = UIKit.vbox([], 6)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_content)
	for entry in _watch():
		var source: Object = entry[0]
		source.connect(entry[1], _on_watched)
		_watched.append(entry)
	_rebuild()


func _exit_tree() -> void:
	for entry in _watched:
		if is_instance_valid(entry[0]) and entry[0].is_connected(entry[1], _on_watched):
			entry[0].disconnect(entry[1], _on_watched)
	_watched.clear()


## [[object, signal_name], …] whose emission rebuilds this sheet.
func _watch() -> Array:
	return []


func _build(_content_box: VBoxContainer) -> void:
	pass


func request_rebuild() -> void:
	if not _rebuild_queued:
		_rebuild_queued = true
		_rebuild.call_deferred()


func set_title(text: String) -> void:
	title = text
	if _title_label != null:
		_title_label.text = text


## Calls a service action that returns an error string ("" = success) and reports it.
func run_action(error: String, success_text: String = "") -> void:
	if not error.is_empty():
		toast_requested.emit(error, true)
	elif not success_text.is_empty():
		toast_requested.emit(success_text, false)
	request_rebuild()


func _on_watched(_a: Variant = null, _b: Variant = null, _c: Variant = null, _d: Variant = null) -> void:
	request_rebuild()


func _rebuild() -> void:
	_rebuild_queued = false
	if _content == null:
		return
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	_build(_content)
