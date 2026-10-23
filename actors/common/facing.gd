class_name Facing
extends RefCounted
## 4-direction facing for sprites (DECISIONS.md D20).

enum Direction { DOWN, UP, LEFT, RIGHT }


## Switching between the side pair and the front/back pair needs the new axis to dominate by this
## factor, so a path wobbling around a diagonal does not flip the sprite every step.
const HYSTERESIS := 1.25


## Dominant axis wins; ties prefer vertical. Zero vector keeps `current`. Near a diagonal the
## pair of `current` is kept (HYSTERESIS).
static func from_vector(vector: Vector2, current: Direction = Direction.DOWN) -> Direction:
	if vector.is_zero_approx():
		return current
	var ax := absf(vector.x)
	var ay := absf(vector.y)
	var sideways := current == Direction.LEFT or current == Direction.RIGHT
	if (ax * HYSTERESIS > ay) if sideways else (ax > ay * HYSTERESIS):
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
