class_name LootDrop
extends Node2D
## What a slain monster dropped: gold, gear, materials and meat lying on the ground until a Hunter
## walks over and picks it up (or it fades after `LIFETIME`). Origin = the spot on the ground.

const LIFETIME := 90.0
const FADE_TIME := 10.0
const SACK := Color("8b5e3c")
const OUTLINE := Color("16161c")
const GLOW := Color(1.0, 0.85, 0.35, 0.35)

var gold: int = 0
var items: Dictionary[StringName, int] = {}
var _age := 0.0


func setup(drop_gold: int, drop_items: Dictionary[StringName, int]) -> void:
	gold = drop_gold
	items = drop_items.duplicate()
	queue_redraw()


func is_empty() -> bool:
	return gold <= 0 and items.is_empty()


func get_item_count() -> int:
	var total := 0
	for item_id in items:
		total += items[item_id]
	return total


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME or is_empty():
		queue_free()
		return
	modulate.a = clampf((LIFETIME - _age) / FADE_TIME, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_age * 4.0)
	draw_ellipse(Vector2(0, 0), 9.0, 3.5, Color(0, 0, 0, 0.3))
	draw_circle(Vector2(0, -5), 9.0 + pulse * 2.0, GLOW)
	# A little sack with a gold coin on top.
	draw_circle(Vector2(0, -4), 5.5, OUTLINE)
	draw_circle(Vector2(0, -4), 4.5, SACK)
	draw_line(Vector2(-2, -8), Vector2(2, -8), OUTLINE, 2.0)
	if gold > 0:
		draw_circle(Vector2(0, -11 - pulse), 2.5, OUTLINE)
		draw_circle(Vector2(0, -11 - pulse), 1.8, Color("f2c94c"))
