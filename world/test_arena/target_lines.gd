extends Node2D
## Debug overlay: draws a line from each enemy to its current target.

const LINE_COLOR := Color(1.0, 0.35, 0.3, 0.6)
const IN_RANGE_COLOR := Color(1.0, 0.85, 0.3, 0.9)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	for node in get_tree().get_nodes_in_group(Enemy.GROUP):
		var enemy := node as Enemy
		if enemy == null or not enemy.combat.is_valid_target(enemy.combat.target):
			continue
		var color := IN_RANGE_COLOR if enemy.combat.is_target_in_range() else LINE_COLOR
		draw_line(enemy.global_position + Vector2(0, -6), enemy.combat.target.global_position + Vector2(0, -12), color, 1.0)
