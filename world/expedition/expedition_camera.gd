extends Camera2D
## Follows the centre of the standing party, clamped to the map (MAP_DESIGN.md §7).
## In portrait the map is one screen wide, so it mostly scrolls vertically.

@export var map_size := Vector2(360, 1440)

var party: Array[Hunter] = []


func _ready() -> void:
	limit_left = 0
	limit_top = 0
	limit_right = int(map_size.x)
	limit_bottom = int(map_size.y)
	position_smoothing_enabled = true
	position_smoothing_speed = 4.0


func snap_to_party() -> void:
	var center := _party_center()
	if center != Vector2.INF:
		global_position = center
		reset_smoothing()


func _process(_delta: float) -> void:
	var center := _party_center()
	if center != Vector2.INF:
		global_position = center


func _party_center() -> Vector2:
	var sum := Vector2.ZERO
	var count := 0
	for hunter in party:
		if is_instance_valid(hunter) and hunter.is_targetable():
			sum += hunter.global_position
			count += 1
	return sum / count if count > 0 else Vector2.INF
