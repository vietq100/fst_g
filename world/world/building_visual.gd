@tool
class_name BuildingVisual
extends Node2D
## Front-facing building on the top-down grid (BUILDING_DESIGN.md, D52, TOWN_DESIGN.md §4), in the
## style of 2D management games: stone plinth, a front wall in one of three materials (stone
## courses, wooden planks, plaster with a timber frame), lit windows, an arched door with a step,
## and a hip roof seen from the front (trapezoid with shingle rows and a ridge cap). One marker per
## building type; Lv2 raises the plinth, adds height and a banner.
## Origin = middle of the footprint's bottom edge, so y-sorting with actors works. The footprint
## is `footprint` tiles wide and deep behind the origin; the wall and roof rise above it.
## `ghost` draws a translucent placement preview tinted green (valid) or red.

const OUTLINE := Color("16161c")
const SHADOW := Color(0, 0, 0, 0.3)
const SELECTION := Color("f2d16b")
const WINDOW := Color("ffcf6b")
const WINDOW_DARK := Color("c9792e")
const STONE := Color("8a8a84")
const TIMBER := Color("4a3424")
const DOOR := Color("4a3020")
const BANNER := Color("a83a3a")
const LABEL := Color("f4f1ea")
const PLAQUE := Color(0.08, 0.06, 0.05, 0.72)
const SMOKE := Color(0.82, 0.82, 0.86, 0.45)
const VALID := Color(0.4, 1.0, 0.45, 0.45)
const INVALID := Color(1.0, 0.35, 0.3, 0.45)
## Roof eaves stick out this far past the walls.
## Chimney smoke redraws at this rate.
const SMOKE_FPS := 6.0
const SMOKY: Array[StringName] = [&"tavern", &"blacksmith", &"house", &"restaurant", &"forge"]
const EAVE := 5.0
## The ridge is this much shorter than the eave line on each side (hip roof).
const HIP := 9.0

enum Wall { STONE, WOOD, PLASTER }

const STYLES := {
	&"town_hall": {"wall": Color("d8ccb0"), "roof": Color("3c5a8c"), "trim": Color("e2c46b"), "height": 46.0, "wall_type": Wall.STONE},
	&"tavern": {"wall": Color("e3d3b4"), "roof": Color("8a3b2e"), "trim": Color("e2a64b"), "height": 34.0, "wall_type": Wall.PLASTER},
	&"blacksmith": {"wall": Color("6d6a64"), "roof": Color("3f4247"), "trim": Color("ff8a3d"), "height": 32.0, "wall_type": Wall.STONE},
	&"hospital": {"wall": Color("eee9de"), "roof": Color("3f8a83"), "trim": Color("c94a4a"), "height": 34.0, "wall_type": Wall.PLASTER},
	&"warehouse": {"wall": Color("8d7050"), "roof": Color("5b4430"), "trim": Color("b08d57"), "height": 32.0, "wall_type": Wall.WOOD},
	&"house": {"wall": Color("c09468"), "roof": Color("9a4b3a"), "trim": Color("e8d3a8"), "height": 28.0, "wall_type": Wall.WOOD},
	&"temple": {"wall": Color("e2dccb"), "roof": Color("b8913a"), "trim": Color("f2d16b"), "height": 40.0, "wall_type": Wall.STONE},
	&"trading_post": {"wall": Color("b08658"), "roof": Color("2f6f5e"), "trim": Color("f2d16b"), "height": 30.0, "wall_type": Wall.WOOD},
	&"restaurant": {"wall": Color("eadcc0"), "roof": Color("a83a3a"), "trim": Color("f4f1ea"), "height": 32.0, "wall_type": Wall.PLASTER},
	&"inn": {"wall": Color("e6d8bc"), "roof": Color("5b6c8f"), "trim": Color("f4f1ea"), "height": 36.0, "wall_type": Wall.PLASTER},
	&"academy": {"wall": Color("c4bfd2"), "roof": Color("5a3f8c"), "trim": Color("9fd6ff"), "height": 42.0, "wall_type": Wall.STONE},
	&"forge": {"wall": Color("55555c"), "roof": Color("8a3b24"), "trim": Color("ff7a2e"), "height": 32.0, "wall_type": Wall.STONE},
	&"portal": {"wall": Color("3a3458"), "roof": Color("6a3fb8"), "trim": Color("c79bff"), "height": 28.0, "wall_type": Wall.STONE},
}

@export var building_id: StringName = &"house":
	set(value):
		building_id = value
		queue_redraw()
@export var footprint := Vector2i(2, 2):
	set(value):
		footprint = value
		queue_redraw()
@export var level := 1:
	set(value):
		level = value
		queue_redraw()
@export var title := "":
	set(value):
		title = value
		queue_redraw()

var selected := false:
	set(value):
		selected = value
		queue_redraw()

var _smoke_time := 0.0
var _smoke_frame := 0


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or ghost or not SMOKY.has(building_id):
		return
	_smoke_time += delta
	if _smoke_time >= 1.0 / SMOKE_FPS:
		_smoke_time -= 1.0 / SMOKE_FPS
		_smoke_frame += 1
		queue_redraw()
var ghost := false:
	set(value):
		ghost = value
		queue_redraw()
var ghost_valid := true:
	set(value):
		ghost_valid = value
		queue_redraw()


## Corners of the footprint relative to the origin (bottom-centre): top-left, top-right,
## bottom-right, bottom-left.
func get_corners() -> PackedVector2Array:
	var half := footprint.x * WorldService.TILE * 0.5
	var depth := footprint.y * WorldService.TILE
	return PackedVector2Array([Vector2(-half, -depth), Vector2(half, -depth), Vector2(half, 0), Vector2(-half, 0)])


## Footprint width in world units.
func get_width() -> float:
	return footprint.x * WorldService.TILE


## Height of the drawing above the origin (plinth, wall and roof).
func get_height() -> float:
	return _plinth() + _wall_height() + _roof_height() + 4.0


func _wall_height() -> float:
	return float(_style()["height"]) * (1.15 if level >= 2 else 1.0)


func _plinth() -> float:
	return 6.0 if level >= 2 else 4.0


func _roof_height() -> float:
	return footprint.y * WorldService.TILE * 0.55 + 10.0


func _style() -> Dictionary:
	return STYLES.get(building_id, STYLES[&"house"])


func _draw() -> void:
	var style := _style()
	var corners := get_corners()
	var half := get_width() * 0.5
	var h := _wall_height()
	var plinth := _plinth()
	var tint := Color(1, 1, 1, 0.55) if ghost else Color.WHITE
	if ghost:
		draw_colored_polygon(corners, VALID if ghost_valid else INVALID)
	else:
		draw_ellipse(Vector2(0, -2), half + 8.0, 9.0, SHADOW)
		_draw_plinth(half, plinth)
	# Front wall above the plinth.
	var wall_top := -plinth - h
	var wall_rect := Rect2(Vector2(-half, wall_top), Vector2(half * 2.0, h))
	var wall: Color = style["wall"]
	draw_rect(wall_rect, wall * tint)
	if not ghost:
		_draw_wall_material(style, wall_rect)
		_draw_windows(style, wall_rect)
		_draw_door(wall_rect)
	draw_rect(wall_rect, OUTLINE, false, 1.0)
	var ridge := _draw_roof(style, half, wall_top, tint)
	var apex := (ridge[0] + ridge[1]) * 0.5
	if not ghost:
		_draw_details(style, wall_rect, ridge)
	if selected:
		draw_rect(Rect2(corners[0] - Vector2(4, 4), Vector2(half * 2.0 + 8.0, footprint.y * WorldService.TILE + 8.0)), SELECTION, false, 2.0)
	if not title.is_empty() and not ghost:
		_draw_label(apex)


## Stone foundation band under the wall, slightly wider than it.
func _draw_plinth(half: float, plinth: float) -> void:
	var rect := Rect2(Vector2(-half - 2.0, -plinth), Vector2(half * 2.0 + 4.0, plinth))
	draw_rect(rect, STONE)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 1.0)), STONE.lightened(0.2))
	var blocks := int(rect.size.x / 10.0)
	for i in range(1, blocks):
		var x := rect.position.x + rect.size.x * i / blocks
		draw_line(Vector2(x, rect.position.y + 1.0), Vector2(x, rect.end.y), STONE.darkened(0.4), 1.0)
	draw_rect(rect, OUTLINE, false, 1.0)


## Stone courses with staggered joints, horizontal planks, or plaster with a timber frame.
func _draw_wall_material(style: Dictionary, rect: Rect2) -> void:
	var wall: Color = style["wall"]
	var wall_type: int = style["wall_type"]
	match wall_type:
		Wall.STONE:
			var rows := maxi(int(rect.size.y / 6.0), 2)
			var columns := maxi(int(rect.size.x / 12.0), 2)
			for k in range(1, rows):
				var y := rect.position.y + rect.size.y * k / rows
				draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), wall.darkened(0.35), 1.0)
				var shift := 0.5 if k % 2 == 1 else 0.0
				for i in columns:
					var x := rect.position.x + rect.size.x * (i + shift) / columns
					if x > rect.position.x and x < rect.end.x:
						draw_line(Vector2(x, y), Vector2(x, y + rect.size.y / rows), wall.darkened(0.35), 1.0)
			# Lit top-left courses.
			draw_rect(Rect2(rect.position, Vector2(rect.size.x, rect.size.y / rows)), Color(1, 1, 1, 0.08))
		Wall.WOOD:
			var planks := maxi(int(rect.size.y / 4.0), 2)
			for k in range(1, planks):
				var y := rect.position.y + rect.size.y * k / planks
				draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), wall.darkened(0.3), 1.0)
				draw_line(Vector2(rect.position.x, y - 1.0), Vector2(rect.end.x, y - 1.0), wall.lightened(0.08), 1.0)
			# Nail heads at the corner posts.
			for y in range(int(rect.position.y) + 4, int(rect.end.y) - 2, 8):
				draw_rect(Rect2(Vector2(rect.position.x + 2.0, y), Vector2(1, 1)), wall.darkened(0.5))
				draw_rect(Rect2(Vector2(rect.end.x - 3.0, y), Vector2(1, 1)), wall.darkened(0.5))
		_:
			for t: float in [0.25, 0.75]:
				var x := rect.position.x + rect.size.x * t
				draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), TIMBER, 2.0)
			var mid := rect.position.y + rect.size.y * 0.45
			draw_line(Vector2(rect.position.x, mid), Vector2(rect.end.x, mid), TIMBER, 2.0)
			# Diagonal braces in the upper panels.
			draw_line(Vector2(rect.position.x + 2.0, mid - 2.0), Vector2(rect.position.x + rect.size.x * 0.25 - 2.0, rect.position.y + 2.0), TIMBER, 1.5)
			draw_line(Vector2(rect.end.x - 2.0, mid - 2.0), Vector2(rect.end.x - rect.size.x * 0.25 + 2.0, rect.position.y + 2.0), TIMBER, 1.5)
	var post := wall.darkened(0.45) if wall_type == Wall.STONE else TIMBER
	draw_line(rect.position, Vector2(rect.position.x, rect.end.y), post, 2.0)
	draw_line(Vector2(rect.end.x, rect.position.y), rect.end, post, 2.0)
	draw_line(rect.position, Vector2(rect.end.x, rect.position.y), post, 2.0)


## Two lit windows with a sill, either side of the door.
func _draw_windows(style: Dictionary, rect: Rect2) -> void:
	var glass := WINDOW if building_id != &"hospital" else Color("bfe3ff")
	var trim: Color = style["trim"]
	var y := rect.position.y + rect.size.y * 0.32
	for t: float in [0.22, 0.78]:
		var x := rect.position.x + rect.size.x * t
		var pane := Rect2(Vector2(x - 4.0, y), Vector2(8, 10))
		draw_rect(pane.grow(1.0), OUTLINE)
		draw_rect(pane, glass)
		draw_rect(Rect2(pane.position, Vector2(pane.size.x, 3.0)), glass.darkened(0.25) if building_id == &"hospital" else WINDOW_DARK)
		draw_line(Vector2(pane.position.x, y + 5.0), Vector2(pane.end.x, y + 5.0), OUTLINE, 1.0)
		draw_line(Vector2(x, pane.position.y), Vector2(x, pane.end.y), OUTLINE, 1.0)
		draw_line(Vector2(pane.position.x - 1.5, pane.end.y + 1.5), Vector2(pane.end.x + 1.5, pane.end.y + 1.5), trim.lightened(0.2), 1.5)


## Arched door in the middle of the wall, with a stone step on the plinth.
func _draw_door(rect: Rect2) -> void:
	var base := Vector2(0, rect.end.y)
	draw_rect(Rect2(base + Vector2(-9, 0), Vector2(18, 3)), STONE.lightened(0.15))
	draw_rect(Rect2(base + Vector2(-9, 0), Vector2(18, 3)), OUTLINE, false, 1.0)
	var door := PackedVector2Array([base + Vector2(-6, 0), base + Vector2(-6, -14), base + Vector2(-3, -19), base + Vector2(3, -19),
		base + Vector2(6, -14), base + Vector2(6, 0)])
	if building_id == &"warehouse":
		# Wide barn door.
		door = PackedVector2Array([base + Vector2(-10, 0), base + Vector2(-10, -20), base + Vector2(10, -20), base + Vector2(10, 0)])
	draw_colored_polygon(_grow(door, 1.2), OUTLINE)
	draw_colored_polygon(door, DOOR)
	draw_line(base + Vector2(0, -1), base + Vector2(0, -18), DOOR.darkened(0.4), 1.0)
	if building_id == &"warehouse":
		draw_line(base + Vector2(-9, -19), base + Vector2(9, -1), DOOR.darkened(0.4), 1.0)
		draw_line(base + Vector2(9, -19), base + Vector2(-9, -1), DOOR.darkened(0.4), 1.0)
	draw_circle(base + Vector2(3, -8), 1.0, Color("e8c547"))


## Hip roof seen from the front: eave line over the wall, shorter ridge above it.
## Returns the ridge ends [left, right].
func _draw_roof(style: Dictionary, half: float, wall_top: float, tint: Color) -> PackedVector2Array:
	var roof: Color = style["roof"]
	var eave_y := wall_top + 3.0
	var ridge_y := wall_top - _roof_height()
	var eave_l := Vector2(-half - EAVE, eave_y)
	var eave_r := Vector2(half + EAVE, eave_y)
	var ridge_l := Vector2(-half + HIP, ridge_y)
	var ridge_r := Vector2(half - HIP, ridge_y)
	var slope := PackedVector2Array([eave_l, eave_r, ridge_r, ridge_l])
	draw_colored_polygon(slope, roof * tint)
	if not ghost:
		# Shingle rows, closer together towards the ridge; darker hip edges; bright eave.
		for t: float in [0.18, 0.34, 0.48, 0.6, 0.7, 0.79, 0.87]:
			draw_line(eave_l.lerp(ridge_l, t), eave_r.lerp(ridge_r, t), roof.darkened(0.3), 1.0)
		draw_line(eave_l, ridge_l, roof.darkened(0.4), 2.0)
		draw_line(eave_r, ridge_r, roof.darkened(0.4), 2.0)
		draw_line(eave_l, eave_r, roof.lightened(0.25), 2.0)
		draw_rect(Rect2(Vector2(-half - EAVE, eave_y), Vector2(half * 2.0 + EAVE * 2.0, 2.0)), OUTLINE)
		# Ridge cap.
		draw_line(ridge_l + Vector2(-1, 0), ridge_r + Vector2(1, 0), OUTLINE, 4.0)
		draw_line(ridge_l, ridge_r, roof.lightened(0.35), 2.0)
	draw_polyline(slope + PackedVector2Array([slope[0]]), OUTLINE, 1.0)
	return PackedVector2Array([ridge_l, ridge_r])


func _draw_details(style: Dictionary, wall: Rect2, ridge: PackedVector2Array) -> void:
	var trim: Color = style["trim"]
	var apex := (ridge[0] + ridge[1]) * 0.5
	var h := wall.size.y
	# Sign spot: on the wall, left of the door, under the window line.
	var sign_at := Vector2(wall.position.x + wall.size.x * 0.22, wall.end.y - 14.0)
	var right_eave := Vector2(wall.end.x + 2.0, wall.position.y)
	match building_id:
		&"town_hall":
			_draw_banner(ridge[0] + Vector2(2, 0))
			_draw_banner(ridge[1] + Vector2(-2, 0))
			draw_line(Vector2(wall.position.x, wall.position.y + 3.0), Vector2(wall.end.x, wall.position.y + 3.0), trim, 2.0)
			# Clock over the door.
			var clock := Vector2(0, wall.position.y + h * 0.3)
			draw_circle(clock, 5.5, OUTLINE)
			draw_circle(clock, 4.5, Color("f4f1ea"))
			draw_line(clock, clock + Vector2(0, -3), OUTLINE, 1.0)
			draw_line(clock, clock + Vector2(2, 0), OUTLINE, 1.0)
		&"tavern":
			_draw_hanging_sign(sign_at, trim)
			draw_rect(Rect2(sign_at + Vector2(-2, 1), Vector2(4, 5)), Color("f4f1ea"))
			draw_rect(Rect2(sign_at + Vector2(2, 2), Vector2(1, 3)), Color("f4f1ea"))
			_draw_chimney(ridge[1] + Vector2(-6, 4), Color("7a5a48"), true)
		&"blacksmith":
			_draw_chimney(ridge[1] + Vector2(-6, 4), Color("4a4542"), true)
			# Forge glow and an anvil beside the door.
			var anvil := Vector2(wall.end.x - 12.0, wall.end.y)
			draw_circle(anvil + Vector2(0, -4), 9.0, Color(trim, 0.25))
			draw_rect(Rect2(anvil + Vector2(-5, -5), Vector2(10, 3)), OUTLINE)
			draw_rect(Rect2(anvil + Vector2(-2, -2), Vector2(4, 2)), OUTLINE)
		&"hospital":
			var cross := Vector2(0, wall.position.y + h * 0.3)
			draw_rect(Rect2(cross - Vector2(6, 6), Vector2(12, 12)), OUTLINE)
			draw_rect(Rect2(cross - Vector2(5, 5), Vector2(10, 10)), Color("f4f1ea"))
			draw_rect(Rect2(cross - Vector2(4, 1.5), Vector2(8, 3)), trim)
			draw_rect(Rect2(cross - Vector2(1.5, 4), Vector2(3, 8)), trim)
		&"warehouse":
			# Crates by the front corner.
			for offset: Vector2 in [Vector2(-8, 0), Vector2(0, 0), Vector2(-4, -6)]:
				_draw_crate(Vector2(wall.position.x + 10.0, wall.end.y + 2.0) + offset, trim)
		&"house":
			_draw_chimney(ridge[0] + Vector2(6, 4), Color("7a5a48"), true)
		&"trading_post":
			_draw_hanging_sign(sign_at, trim)
			draw_circle(sign_at + Vector2(0, 3.5), 2.5, Color("b8892a"))
			draw_circle(sign_at + Vector2(0, 3.5), 1.5, Color("f2c94c"))
			for offset: Vector2 in [Vector2(-6, 0), Vector2(2, 0)]:
				_draw_crate(Vector2(wall.end.x - 8.0, wall.end.y + 2.0) + offset, Color("b08d57"))
		&"restaurant":
			_draw_hanging_sign(sign_at, trim)
			draw_circle(sign_at + Vector2(0, 3.5), 2.5, Color("c9503f"))
			_draw_chimney(ridge[1] + Vector2(-6, 4), Color("8a6a58"), true)
		&"inn":
			_draw_hanging_sign(sign_at, Color("5b6c8f"))
			draw_rect(Rect2(sign_at + Vector2(-3, 2), Vector2(6, 3)), Color("f4f1ea"))
			draw_rect(Rect2(sign_at + Vector2(-3, 1), Vector2(2, 2)), Color("e8c35a"))
			# Lantern by the door.
			var lantern := Vector2(10, wall.end.y - 16.0)
			draw_circle(lantern, 5.0, Color(1.0, 0.8, 0.35, 0.3))
			draw_rect(Rect2(lantern - Vector2(1.5, 2), Vector2(3, 4)), Color("ffcf6b"))
		&"academy":
			_draw_banner(apex)
			for t: float in [0.1, 0.9]:
				var x := wall.position.x + wall.size.x * t
				draw_line(Vector2(x, wall.position.y + 2.0), Vector2(x, wall.end.y), Color(1, 1, 1, 0.45), 3.0)
			var crest := Vector2(0, wall.position.y + h * 0.3)
			draw_circle(crest, 4.0, OUTLINE)
			draw_circle(crest, 3.0, trim)
		&"forge":
			_draw_chimney(ridge[1] + Vector2(-6, 4), Color("4a4542"), true)
			draw_circle(Vector2(0, wall.end.y - 8.0), 11.0, Color(trim, 0.3))
		&"portal":
			var ring := apex + Vector2(0, -12)
			draw_circle(ring, 12.0, Color(trim, 0.2))
			draw_arc(ring, 9.0, 0.0, TAU, 24, OUTLINE, 4.0)
			draw_arc(ring, 9.0, 0.0, TAU, 24, trim, 2.0)
			draw_circle(ring, 6.0, Color("120d24"))
			draw_circle(ring + Vector2(-2, -2), 2.0, Color(trim, 0.6))
		&"temple":
			# Spire with a golden sun; pale columns either side of the door.
			draw_line(apex, apex + Vector2(0, -14), OUTLINE, 3.0)
			draw_line(apex, apex + Vector2(0, -14), trim.darkened(0.3), 1.0)
			draw_circle(apex + Vector2(0, -18), 5.0, OUTLINE)
			draw_circle(apex + Vector2(0, -18), 4.0, trim)
			for x: float in [-12.0, 12.0]:
				draw_line(Vector2(x, wall.position.y + 2.0), Vector2(x, wall.end.y), Color(1, 1, 1, 0.5), 3.0)
	if level >= 2 and building_id != &"town_hall":
		_draw_banner(right_eave)


func _draw_banner(at: Vector2) -> void:
	draw_line(at, at + Vector2(0, -16), OUTLINE, 2.0)
	draw_colored_polygon(PackedVector2Array([at + Vector2(1, -16), at + Vector2(12, -13), at + Vector2(1, -9)]), BANNER)
	draw_line(at + Vector2(1, -15), at + Vector2(10, -13), BANNER.lightened(0.3), 1.0)


## Wooden board on a bracket sticking out of the wall; the caller draws its emblem at +3 px.
func _draw_hanging_sign(at: Vector2, color: Color) -> void:
	draw_line(at + Vector2(-6, -4), at + Vector2(6, -4), OUTLINE, 2.0)
	draw_line(at + Vector2(-4, -4), at + Vector2(-4, -1), OUTLINE, 1.0)
	draw_line(at + Vector2(4, -4), at + Vector2(4, -1), OUTLINE, 1.0)
	draw_rect(Rect2(at + Vector2(-6, -1), Vector2(12, 9)), OUTLINE)
	draw_rect(Rect2(at + Vector2(-5, 0), Vector2(10, 7)), color.darkened(0.25))


func _draw_chimney(at: Vector2, color: Color, smoke: bool) -> void:
	draw_rect(Rect2(at + Vector2(-4, -14), Vector2(8, 16)), OUTLINE)
	draw_rect(Rect2(at + Vector2(-3, -13), Vector2(6, 14)), color)
	draw_rect(Rect2(at + Vector2(-3, -13), Vector2(2, 14)), color.lightened(0.15))
	draw_rect(Rect2(at + Vector2(-5, -16), Vector2(10, 3)), OUTLINE)
	if smoke:
		# Three puffs rising and drifting right, each fading as it climbs.
		for i in 3:
			var t := fmod((_smoke_frame + i * 6) / 18.0, 1.0)
			draw_circle(at + Vector2(1.0 + t * 8.0 + i, -18.0 - t * 18.0), 2.0 + t * 2.5, Color(SMOKE, SMOKE.a * (1.0 - t)))


func _draw_crate(at: Vector2, color: Color) -> void:
	draw_rect(Rect2(at + Vector2(-4, -8), Vector2(8, 8)), OUTLINE)
	draw_rect(Rect2(at + Vector2(-3, -7), Vector2(6, 6)), color)
	draw_line(at + Vector2(-3, -7), at + Vector2(3, -1), color.darkened(0.35), 1.0)
	draw_rect(Rect2(at + Vector2(-3, -7), Vector2(6, 1)), color.lightened(0.25))


## Name (and level) on a dark plaque above the roof.
func _draw_label(apex: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var text := "%s%s" % [title, "  Lv%d" % level if level > 1 else ""]
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
	var top := apex.y - 8.0 - size.y
	if building_id == &"temple" or building_id == &"portal":
		top -= 18.0
	var plaque := Rect2(Vector2(apex.x - size.x * 0.5 - 4.0, top), Vector2(size.x + 8.0, size.y + 2.0))
	draw_rect(plaque, PLAQUE)
	var trim: Color = _style()["trim"]
	draw_rect(plaque, Color(trim, 0.7), false, 1.0)
	var at := Vector2(apex.x - size.x * 0.5, top + font.get_ascent(10) + 1.0)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 2, OUTLINE)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, LABEL)


static func _grow(points: PackedVector2Array, amount: float) -> PackedVector2Array:
	var grown := Geometry2D.offset_polygon(points, amount)
	return grown[0] if not grown.is_empty() else points
