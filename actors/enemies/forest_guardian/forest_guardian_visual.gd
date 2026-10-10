@tool
class_name ForestGuardianVisual
extends ActorVisual
## Placeholder Forest Guardian: large, heavy, rooted; stone-bark armor, branch-like horns,
## glowing core, large hands (BOSS_DESIGN.md). Origin is at the feet.

@export var bark_color := Color("4a3f35"):
	set(value):
		bark_color = value
		queue_redraw()
@export var stone_color := Color("6d7068"):
	set(value):
		stone_color = value
		queue_redraw()
@export var core_color := Color("7dffb0"):
	set(value):
		core_color = value
		queue_redraw()

var _pulse := 0.0


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_pulse = fmod(_pulse + delta * 2.0, TAU)
	queue_redraw()


func _draw() -> void:
	fill_ellipse(Vector2.ZERO, Vector2(24.0, 6.0), SHADOW_COLOR)
	if selected:
		outline_ellipse(Vector2.ZERO, Vector2(27.0, 8.0), SELECTION_COLOR)
	if downed:
		_draw_rubble()
		return
	# Root-like feet.
	for x in [-12.0, 12.0]:
		draw_rect(Rect2(Vector2(x - 6.0, -10.0), Vector2(12, 10)).grow(1.0), OUTLINE_COLOR)
		draw_rect(Rect2(Vector2(x - 6.0, -10.0), Vector2(12, 10)), bark_color)
	# Trunk body.
	var body := Rect2(Vector2(-16, -46), Vector2(32, 38))
	draw_rect(body.grow(1.0), OUTLINE_COLOR)
	draw_rect(body, bark_color)
	# Stone plates.
	for plate in [Rect2(-14, -44, 12, 9), Rect2(3, -40, 11, 8), Rect2(-13, -22, 10, 8), Rect2(5, -20, 9, 9)]:
		draw_rect(plate, stone_color)
	# Glowing core.
	var glow := 0.75 + 0.25 * sin(_pulse)
	draw_circle(Vector2(0, -29), 7.0, Color(core_color, 0.25 * glow))
	draw_circle(Vector2(0, -29), 4.0, core_color * Color(glow, glow, glow))
	# Large hands.
	for side in [-1.0, 1.0]:
		var hand := Vector2(side * 22.0, -20.0)
		draw_line(Vector2(side * 16.0, -38.0), hand, OUTLINE_COLOR, 6.0)
		draw_line(Vector2(side * 16.0, -38.0), hand, bark_color, 4.0)
		draw_circle(hand, 6.0, OUTLINE_COLOR)
		draw_circle(hand, 5.0, stone_color)
	# Head with branch horns and eyes.
	var head := Rect2(Vector2(-9, -58), Vector2(18, 13))
	draw_rect(head.grow(1.0), OUTLINE_COLOR)
	draw_rect(head, bark_color.darkened(0.15))
	for side in [-1.0, 1.0]:
		var root := Vector2(side * 6.0, -58.0)
		var tip := root + Vector2(side * 10.0, -14.0)
		draw_line(root, tip, OUTLINE_COLOR, 4.0)
		draw_line(root, tip, bark_color, 2.0)
		draw_line(root.lerp(tip, 0.5), root.lerp(tip, 0.5) + Vector2(side * 6.0, -2.0), bark_color, 2.0)
	if facing != Facing.Direction.UP:
		for side in [-1.0, 1.0]:
			draw_rect(Rect2(Vector2(side * 4.0 - 1.5, -53.0), Vector2(3, 2)), core_color)


func _draw_rubble() -> void:
	for piece in [Rect2(-22, -8, 14, 8), Rect2(-6, -12, 16, 12), Rect2(10, -7, 12, 7)]:
		draw_rect(piece.grow(1.0), OUTLINE_COLOR)
		draw_rect(piece, stone_color.darkened(0.2))
	draw_circle(Vector2(2, -6), 2.0, core_color.darkened(0.6))
