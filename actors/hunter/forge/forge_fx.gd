class_name ForgeFx
extends RefCounted
## Attack effects of the Pixel Hero Forge (HTML "HIỆU ỨNG"), ported 1:1: drawn straight into the renderer at
## 1× with transparency (kind 0: they never count as painted). Slash crescent, ground rings, burst star,
## glow, X mark, element particles, spell column, lightning, weapon aura.
## `c` is the element's three colours [light, base, deep] as [r, g, b] arrays (ForgeData fx[el].c).

const MASK := 0xFFFFFFFF
const CROSS := [[1, 0], [-1, 0], [0, 1], [0, -1]]


## Element colours as [r, g, b] arrays.
static func colors(element: String) -> Array:
	var fx: Dictionary = ForgeData.data()["fx"]
	var entry: Dictionary = fx.get(element, fx["none"])
	var out: Array = []
	for hex: String in entry["c"]:
		out.append(ForgePalette.hex_to_rgb(hex))
	return out


static func ground() -> float:
	return ForgeData.data()["ground"]


# --- Random numbers (mulberry32, like the HTML's rng32) -----------------------------------------


## A generator: [state]; `next(rng)` gives 0..1.
static func rng(seed_value: int) -> Array:
	return [seed_value & MASK]


static func next(generator: Array) -> float:
	var a: int = (int(generator[0]) + 0x6D2B79F5) & MASK
	generator[0] = a
	var t := _imul(a ^ (a >> 15), 1 | a)
	t = ((t + _imul(t ^ (t >> 7), 61 | t)) & MASK) ^ t
	return float(t ^ (t >> 14)) / 4294967296.0


## Low 32 bits of a 32-bit product (Math.imul), without overflowing 64-bit ints.
static func _imul(a: int, b: int) -> int:
	a &= MASK
	b &= MASK
	return (a * (b & 0xFFFF) + (((a * (b >> 16)) & 0xFFFF) << 16)) & MASK


# --- Primitives ----------------------------------------------------------------------------------


static func put(g: ForgeRenderer, x: float, y: float, c: Array, a: float) -> void:
	if a > 0.04:
		g.put(floorf(x) + ForgeRenderer.OX, floorf(y) + ForgeRenderer.OY, c, minf(1.0, a), 0)


static func line(g: ForgeRenderer, x0: float, y0: float, x1: float, y1: float, c: Array, a: float) -> void:
	var n := maxi(1, ceili(ForgeShapes.hyp(x1 - x0, y1 - y0) * 2.0))
	for i in n + 1:
		put(g, x0 + (x1 - x0) * i / n, y0 + (y1 - y0) * i / n, c, a)


## Crescent slash around the shoulder s, between radii r0 and r1, from angle `start` back to `end`.
static func arc(g: ForgeRenderer, s: Array, r0: float, r1: float, start: float, end: float, c: Array, fade: float) -> void:
	var y := floori(s[1] - r1 - 1.0)
	while y <= s[1] + r1 + 1.0:
		var x := floori(s[0] - r1 - 1.0)
		while x <= s[0] + r1 + 1.0:
			var dx: float = x + 0.5 - s[0]
			var dy: float = y + 0.5 - s[1]
			var r := ForgeShapes.hyp(dx, dy)
			if r >= r0 and r <= r1:
				var th := atan2(dy, dx) * 180.0 / PI
				th = end + fposmod(th - end, 360.0)
				if th <= start:
					var k := 1.0 - (th - end) / (start - end)
					var edge := r1 - r < 1.4
					put(g, x, y, c[0] if edge else ForgePalette.mix(c[2], c[1], k),
						fade * (minf(1.0, k * 1.6) if edge else k * k * 0.85))
			x += 1
		y += 1


static func ring(g: ForgeRenderer, cx: float, cy: float, rx: float, ry: float, c: Array, a: float, fill := 0.0) -> void:
	var y := floori(cy - ry - 2.0)
	while y <= cy + ry + 2.0:
		var x := floori(cx - rx - 2.0)
		while x <= cx + rx + 2.0:
			var e := ForgeShapes.hyp((x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry)
			if e > 0.8 and e < 1.12:
				put(g, x, y, c, a)
			elif e <= 0.8 and fill != 0.0:
				put(g, x, y, c, a * fill)
			x += 1
		y += 1


static func burst(g: ForgeRenderer, cx: float, cy: float, r: float, c: Array, fade: float) -> void:
	for k in 8:
		var a := k * PI / 4.0
		var length := r * 0.55 if k % 2 != 0 else r
		var s := 0.0
		while s <= length:
			put(g, cx + cos(a) * s, cy + sin(a) * s, c[0] if s < length * 0.45 else c[1], fade * (1.0 - s / (length + 1.0)))
			s += 0.5
	glow(g, cx, cy, r * 0.45, c, fade)


static func glow(g: ForgeRenderer, cx: float, cy: float, r: float, c: Array, fade: float) -> void:
	var y := floori(cy - r - 2.0)
	while y <= cy + r + 2.0:
		var x := floori(cx - r - 2.0)
		while x <= cx + r + 2.0:
			var d := ForgeShapes.hyp(x + 0.5 - cx, y + 0.5 - cy)
			if d <= r * 0.55:
				put(g, x, y, c[0], fade)
			elif d <= r:
				put(g, x, y, c[1], fade * 0.85)
			elif d <= r + 1.3:
				put(g, x, y, c[2], fade * 0.35)
			x += 1
		y += 1


## X-shaped cut mark.
static func cross(g: ForgeRenderer, cx: float, cy: float, s: float, c: Array, fade: float) -> void:
	line(g, cx - s, cy - s, cx + s, cy + s, c[0], fade)
	line(g, cx - s, cy + s, cx + s, cy - s, c[1], fade)


## Element particles around the impact: embers, ice glints, sparks, bubbles, smoke, or white glints.
static func particles(g: ForgeRenderer, el: String, cx: float, cy: float, spread: float, n: int, t: float, seed_value: int,
		c: Array, fade: float) -> void:
	var rnd := rng(seed_value)
	for i in n:
		var ox := (next(rnd) - 0.5) * spread * 2.0
		var oy := (next(rnd) - 0.5) * spread
		var q := fmod(t * 0.0025 + next(rnd), 1.0)
		var x := cx + ox
		var y := cy + oy
		var flick := next(rnd)
		match el:
			"fire":
				put(g, x + sin(q * 9.0 + i) * 0.8, y - q * 7.0, ForgePalette.mix(c[1], c[2], q), fade * (1.0 - q))
				if flick < 0.4:
					put(g, x + 1.0, y - q * 7.0, c[0], fade * (1.0 - q) * 0.8)
			"ice":
				var s := sin(q * PI)
				put(g, x, y, c[0], fade * s)
				if s > 0.5:
					for d: Array in CROSS:
						put(g, x + d[0], y + d[1], c[1], fade * s * 0.7)
			"thunder":
				var tick := floori(t / 70.0)
				if (tick + i) % 3 == 0:
					var px := x
					var py := y - 3.0
					var r2 := rng(seed_value + i + tick)
					for k in 4:
						var nx := px + (next(r2) - 0.5) * 2.6
						var ny := py + 1.6
						line(g, px, py, nx, ny, c[1] if k % 2 != 0 else c[0], fade)
						px = nx
						py = ny
			"poison":
				var yy := y - q * 5.0
				var a := fade * (1.0 - q)
				put(g, x, yy, c[1], a)
				put(g, x + 1.0, yy, c[1], a)
				put(g, x, yy - 1.0, c[0], a * 0.8)
				put(g, x + 1.0, yy + 1.0, c[2], a * 0.6)
			"shadow":
				put(g, x + q * 3.0, y - q * 4.0, ForgePalette.mix(c[2], c[1], q), fade * (1.0 - q) * 0.85)
				put(g, x + q * 3.0 + 1.0, y - q * 4.0, c[2], fade * (1.0 - q) * 0.5)
			_:
				var s := sin(q * PI)
				if s > 0.3:
					put(g, x, y, c[0], fade * s)
					if s > 0.75:
						for d: Array in CROSS:
							put(g, x + d[0], y + d[1], c[1], fade * 0.6)


## Spell column striking down at tx: level 0 grows, 1–2 burn, 3 fades out (nothing).
static func strike(g: ForgeRenderer, el: String, tx: float, lvl: int, p: float, t: float, seed_value: int, c: Array, fade: float) -> void:
	var top := -4.0
	var floor_y := ground()
	var length := floor_y - top
	if lvl == 0:
		var y_end := top + length * p
		if el == "thunder":
			bolt(g, tx, top, y_end, seed_value, c, 1.0)
		else:
			var y := top
			while y < y_end:
				put(g, tx, y, c[0], 1.0)
				put(g, tx - 1.0, y, c[1], 0.6)
				put(g, tx + 1.0, y, c[1], 0.6)
				y += 1.0
		return
	if lvl > 2:
		return
	var w := 2.5 if lvl == 1 else 1.5
	var a := 1.0 if lvl == 1 else fade
	if el == "thunder":
		var tick := floori(t / 50.0)
		bolt(g, tx, top, floor_y, seed_value + tick, c, a)
		bolt(g, tx + 1.0, top, floor_y, seed_value + 7 + tick, c, a * 0.5)
	else:
		var y := top
		while y < floor_y:
			var x := floori(tx - w - 1.0)
			while x <= tx + w + 1.0:
				var d := absf(x + 0.5 - tx)
				put(g, x, y, c[0] if d < w * 0.45 else (c[1] if d < w else c[2]), a * (1.0 if d < w else 0.4))
				x += 1
			y += 1.0
	var rx := 3.0 + lvl * 3.0 + p * 2.0
	ring(g, tx, floor_y, rx, rx * 0.32, c[0] if lvl == 1 else c[1], a)
	if el == "ice":
		for spike: Array in [[-3.0, 3.0], [-1.5, 5.0], [1.5, 4.0], [3.2, 2.5]]:
			var o: float = spike[0]
			var h: float = spike[1]
			var k := 0
			while k < h:
				put(g, tx + o, floor_y - k, c[0] if k > h - 2.0 else c[1], a)
				if k < h - 2.0:
					put(g, tx + o + (-1.0 if o < 0.0 else 1.0), floor_y - k, c[2], a * 0.8)
				k += 1
	if el == "poison":
		for k in 6:
			glow(g, tx + (k - 2.5) * 1.6, floor_y - 2.0 - (k % 2) * 1.5, 1.6, c, a * 0.6)
	if el == "shadow":
		glow(g, tx, floor_y - 4.0, 3.5 - lvl, [c[2], c[2], c[1]], a * 0.9)


static func bolt(g: ForgeRenderer, x: float, y0: float, y1: float, seed_value: int, c: Array, a: float) -> void:
	var r := rng(seed_value)
	var px := x
	var py := y0
	while py < y1:
		var ny := minf(y1, py + 2.0 + next(r) * 2.0)
		var nx := x + (next(r) - 0.5) * 4.0
		line(g, px, py, nx, ny, c[0], a)
		line(g, px + 1.0, py, nx + 1.0, ny, c[1], a * 0.7)
		px = nx
		py = ny


## Glow around a weapon part (its own fine cells) where nothing is painted yet.
static func aura(g: ForgeRenderer, part: Dictionary, c: Array, a: float) -> void:
	var f: float = part.get("res", 1.0)
	var u := ForgeRenderer.UNIT / f
	var reach := roundi(f) + 1
	var base := ForgeRenderer.part_base(part, 0.0, 0.0)
	var cells: Array = []
	var cell_set := {}
	var rows: Array = part["rows"]
	for ry in rows.size():
		var row: String = rows[ry]
		for rx in row.length():
			if row[rx] != ".":
				cells.append([rx, ry])
				cell_set[ForgeRenderer._key(rx, ry)] = true
	var best := {}
	for cell: Array in cells:
		for dy in range(-reach, reach + 1):
			for dx in range(-reach, reach + 1):
				var d := maxi(absi(dx), absi(dy))
				if d < 2:
					continue
				var k := ForgeRenderer._key(cell[0] + dx, cell[1] + dy)
				if cell_set.has(k):
					continue
				if not best.has(k) or best[k] > d:
					best[k] = d
	for k: int in best:
		var d: int = best[k]
		var x := floori(k / 16384.0) - 4096
		var y := k % 16384 - 4096
		var px := base.x + x * u
		var py := base.y + y * u
		if g.occ_at(px + u / 2.0, py + u / 2.0) == 0:
			g.add_rect(px, py, u, c, a * (1.0 - float(d - 2) / reach), 0)
