class_name Facing
extends RefCounted
## 4-direction facing for sprites (DECISIONS.md D20).

enum Direction { DOWN, UP, LEFT, RIGHT }


## Dominant axis wins; ties prefer vertical. Zero vector keeps `current`.
static func from_vector(vector: Vector2, current: Direction = Direction.DOWN) -> Direction:
	if vector.is_zero_approx():
		return current
	if absf(vector.x) > absf(vector.y):
		return Direction.RIGHT if vector.x > 0.0 else Direction.LEFT
	return Direction.DOWN if vector.y > 0.0 else Direction.UP


static func to_vector(direction: Direction) -> Vector2:
	match direction:
		Direction.UP:
			return Vector2.UP
		Direction.LEFT:
			return Vector2.LEFT
		Direction.RIGHT:
			return Vector2.RIGHT
	return Vector2.DOWN
