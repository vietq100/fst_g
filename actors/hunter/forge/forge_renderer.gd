class_name ForgeRenderer
extends RefCounted
## Square-op renderer of the Pixel Hero Forge. Coordinates are in UNIT (30) parts per character pixel;
## every part may have its own resolution (res), so clothes/weapons/glasses are finer than the body.
## An occupancy grid (OCC cells per character pixel) tells outer outline from inner line and cast shadow.

const UNIT := 30
const OCC := 10
const W := 40
const H := 42
const OX := 14
const OY := 4
const BLACK := [27.0, 22.0, 34.0]
const SHADE := [38.0, 22.0, 60.0]
const DIR4 := [[1, 0], [-1, 0], [0, 1], [0, -1]]

## ops: [x, y, size, r, g, b, a]
var ops: Array = []
var occ := PackedByteArray()


func _init() -> void:
	occ.resize(W * OCC * H * OCC)


## 0 empty · 1 outer outline · 2 painted · 3 outside the frame
func occ_at(ux: float, uy: float) -> int:
	var x := floori(ux * OCC / UNIT)
	var y := floori(uy * OCC / UNIT)
	if x < 0 or y < 0 or x >= W * OCC or y >= H * OCC:
		return 3
	return occ[y * W * OCC + x]


func add_rect(ux: float, uy: float, s: float, c: Array, a: float = 1.0, kind: int = 2) -> void:
	if ux >= W * UNIT or uy >= H * UNIT or ux + s <= 0 or uy + s <= 0:
		return
	ops.append([ux, uy, s, c[0], c[1], c[2], 1.0 if a >= 1.0 else a])
	if kind == 0:
		return
	var k := float(OCC) / UNIT
	var ow := W * OCC
	var x0 := maxi(0, floori(ux * k + 0.5))
	var x1 := mini(ow, floori((ux + s) * k + 0.5))
	var y0 := maxi(0, floori(uy * k + 0.5))
	var y1 := mini(H * OCC, floori((uy + s) * k + 0.5))
	for y in range(y0, y1):
		for x in range(x0, x1):
			var i := y * ow + x
			if kind == 2:
				occ[i] = 2
			elif occ[i] < 2:
				occ[i] = 1


## One character pixel.
func put(px: float, py: float, c: Array, a: float = 1.0, kind: int = 2) -> void:
	add_rect(px * UNIT, py * UNIT, UNIT, c, a, kind)


static func _key(x: int, y: int) -> int:
	return (x + 4096) * 16384 + (y + 4096)


static func part_base(part: Dictionary, dx: float, dy: float) -> Vector2:
	var res: float = part.get("res", 0.0)
	var bx: float = (part["ox"] if res else part["x"] * UNIT) + (OX + dx) * UNIT
	var by: float = (part["oy"] if res else part["y"] * UNIT) + (OY + dy) * UNIT
	return Vector2(bx, by)


## options: dx, dy, clip (int or null), outline ("color"|"black"), cast, inner
func draw_part(part: Dictionary, pal: Dictionary, options: Dictionary = {}) -> void:
	var dx: float = options.get("dx", 0.0)
	var dy: float = options.get("dy", 0.0)
	var clip: Variant = options.get("clip")
	var outline: String = options.get("outline", "color")
	var cast: bool = options.get("cast", false)
	var inner_opt: bool = options.get("inner", true)
	var f: float = part.get("res", 1.0)
	var u: float = UNIT / f
	var inn: bool = part.get("inner", inner_opt)
	var base := part_base(part, dx, dy)
	var rows: Array = part["rows"]
	var cells: Array = []
	var cell_set := {}
	for ry in rows.size():
		if clip != null and not part.has("res") and int(part["y"]) + ry < int(clip):
			continue
		var row: String = rows[ry]
		for rx in row.length():
			var ch := row[rx]
			if ch == "." or ch == " ":
				continue
			cells.append([rx, ry, ch])
			cell_set[_key(rx, ry)] = true
	if part.get("outline", true) != false:
		var outer: Array = BLACK if outline == "black" else pal["o"]
		var thick := roundi(f) if part.get("thick", false) else 1
		var seen := cell_set.duplicate()
		var front: Array = cells
		for d in range(1, thick + 1):
			var next: Array = []
			for cell: Array in front:
				for dir: Array in DIR4:
					var nx: int = cell[0] + dir[0]
					var ny: int = cell[1] + dir[1]
					var k := _key(nx, ny)
					if seen.has(k):
						continue
					seen[k] = true
					var kd := occ_at(base.x + nx * u + u / 2, base.y + ny * u + u / 2)
					if kd == 3:
						continue
					if kd == 2:
						if d == 1 and inn:
							add_rect(base.x + nx * u, base.y + ny * u, u, pal["i"], 1.0, 2)
						continue
					add_rect(base.x + nx * u, base.y + ny * u, u, outer, 1.0, 1)
					next.append([nx, ny])
			front = next
	for cell: Array in cells:
		var e: Variant = pal.get(cell[2])
		if e is Dictionary:
			add_rect(base.x + cell[0] * u, base.y + cell[1] * u, u, e["c"], e.get("a", 1.0), 0 if cell[2] == "p" else 2)
	if cast:
		var done := {}
		var n := roundi(f)
		for cell: Array in cells:
			var x: int = cell[0]
			var y: int = cell[1]
			var targets: Array = []
			if inn:
				for i in n:
					targets.append([x, y + 2 + i])
			else:
				targets = [[x, y + 1], [x + 1, y]]
			for t: Array in targets:
				var k := _key(t[0], t[1])
				if done.has(k) or cell_set.has(k) or occ_at(base.x + t[0] * u + u / 2, base.y + t[1] * u + u / 2) != 2:
					continue
				if inn and cell_set.has(_key(x, y + 1)):
					continue
				done[k] = true
				add_rect(base.x + t[0] * u, base.y + t[1] * u, u, SHADE, 0.2, 0)
