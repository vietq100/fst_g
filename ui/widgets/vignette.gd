class_name Vignette
extends TextureRect
## Soft dark corners over the map (ambient lighting): a radial gradient from clear in the middle to
## a translucent dark blue at the screen edges. Ignores the mouse.


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([Color(0.02, 0.05, 0.1, 0.0), Color(0.02, 0.05, 0.1, 0.0), Color(0.02, 0.05, 0.1, 0.45)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 1.0)
	texture.width = 128
	texture.height = 128
	self.texture = texture
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
