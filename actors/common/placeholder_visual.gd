@tool
class_name PlaceholderVisual
extends ActorVisual
## Humanoid shape stand-in for Hunter art. Origin is at the feet.

## Colour accents chosen by HunterRuntime.accent_index.
const ACCENT_PALETTE: Array[Color] = [
	Color("8c3b3b"), Color("3b5c8c"), Color("3b8c5a"), Color("8c7a3b"),
	Color("6b3b8c"), Color("3b8c8c"), Color("8c5a3b"), Color("5a5a5a"),
]
const DOWNED_TINT := Color(0.45, 0.45, 0.5)

@export var body_color := Color("8f969e"):
	set(value):
		body_color = value
		queue_redraw()
@export var accent_color := Color("8c3b3b"):
	set(value):
		accent_color = value
		queue_redraw()
@export var skin_color := Color("e0b48c"):
	set(value):
		skin_color = value
		queue_redraw()
## Body width and height in px (head is drawn on top).
@export var body_size := Vector2(14, 22):
	set(value):
		body_size = value
		queue_redraw()
## Pointed ears sticking out of the head (goblins). 0 = none.
@export var ear_length := 0.0:
	set(value):
		ear_length = value
		queue_redraw()
@export var weapon_color := Color("d8dde3"):
	set(value):
		weapon_color = value
		queue_redraw()
@export var weapon_length := 12.0:
	set(value):
		weapon_length = value
		queue_redraw()
## Inner width of the weapon line (sword 1, club 2).
@export var weapon_width := 1.0:
	set(value):
		weapon_width = value
		queue_redraw()


func set_accent_index(index: int) -> void:
	accent_color = ACCENT_PALETTE[posmod(index, ACCENT_PALETTE.size())]


func _on_downed_changed() -> void:
	modulate = DOWNED_TINT if downed else Color.WHITE


func _draw() -> void:
	var half_width := body_size.x * 0.5
	fill_ellipse(Vector2.ZERO, Vector2(half_width + 2.0, 3.0), SHADOW_COLOR)
	if selected:
		outline_ellipse(Vector2.ZERO, Vector2(half_width + 4.0, 5.0), SELECTION_COLOR)
	if downed:
		_draw_downed(half_width)
		return
	var body := Rect2(-half_width, -body_size.y, body_size.x, body_size.y)
	draw_rect(body.grow(1.0), OUTLINE_COLOR)
	draw_rect(body, body_color)
	# Accent band (belt / tabard).
	draw_rect(Rect2(-half_width, -body_size.y * 0.45, body_size.x, 3.0), accent_color)
	var head_center := Vector2(0.0, -body_size.y - 4.0)
	if ear_length > 0.0:
		_draw_ears(head_center)
	draw_circle(head_center, 6.0, OUTLINE_COLOR)
	draw_circle(head_center, 5.0, skin_color)
	if facing == Facing.Direction.UP:
		draw_circle(head_center, 5.0, accent_color.darkened(0.3))
	else:
		_draw_eyes(head_center)
	_draw_weapon(half_width)


func _draw_eyes(head_center: Vector2) -> void:
	if facing == Facing.Direction.DOWN:
		draw_rect(Rect2(head_center + Vector2(-3, 0), Vector2(2, 2)), OUTLINE_COLOR)
		draw_rect(Rect2(head_center + Vector2(1, 0), Vector2(2, 2)), OUTLINE_COLOR)
	else:
		var offset := Facing.to_vector(facing) * 2.0
		draw_rect(Rect2(head_center + Vector2(offset.x - 1.0, 0), Vector2(2, 2)), OUTLINE_COLOR)


func _draw_weapon(half_width: float) -> void:
	# Sword held on the facing side (right hand when facing down/up).
	var side := -1.0 if facing == Facing.Direction.LEFT else 1.0
	var hand := Vector2(side * (half_width + 2.0), -body_size.y * 0.4)
	var tip := hand + Vector2(side * 2.0, -weapon_length)
	draw_line(hand, tip, OUTLINE_COLOR, weapon_width + 2.0)
	draw_line(hand, tip, weapon_color, weapon_width)


func _draw_ears(head_center: Vector2) -> void:
	for side in [-1.0, 1.0]:
		var base := head_center + Vector2(side * 4.0, -1.0)
		var ear := PackedVector2Array([base + Vector2(0, -2), base + Vector2(side * ear_length, -3), base + Vector2(0, 2)])
		draw_colored_polygon(ear, OUTLINE_COLOR)
		draw_colored_polygon(PackedVector2Array([ear[0] + Vector2(0, 1), ear[1] - Vector2(side, 0), ear[2] - Vector2(0, 1)]), skin_color)


func _draw_downed(half_width: float) -> void:
	var body := Rect2(-body_size.y * 0.5, -6.0, body_size.y, half_width)
	draw_rect(body.grow(1.0), OUTLINE_COLOR)
	draw_rect(body, body_color)
	draw_circle(Vector2(body_size.y * 0.5 + 4.0, -3.0), 5.0, skin_color)
