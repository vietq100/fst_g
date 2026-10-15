class_name ForgeShapes
extends RefCounted
## Geometric parts of the Pixel Hero Forge: weapons, quiver, arms. A shape is evaluated at the centre of
## each fine cell and answers a palette symbol ("" = empty). Ported 1:1 from pixel-character.html.

const UNIT := 30

## Blade-like weapons share one generator.
const BLADES := {
	"sword": {"len": 10.5, "hw": 1.0, "guard": 2.3, "grip": 1.8},
	"great": {"len": 14.0, "hw": 1.5, "guard": 3.2, "grip": 2.8},
	"katana": {"len": 12.0, "hw": 0.75, "guard": 0.0, "grip": 3.0, "pommel": false, "curve": 0.9, "tsuba": true},
	"dagger": {"len": 5.5, "hw": 0.85, "guard": 1.6, "grip": 1.5},
}


static func rad(d: float) -> float:
	return d * PI / 180.0


static func hyp(a: float, b: float) -> float:
	return sqrt(a * a + b * b)


static func seg_dist(u: float, v: float, a: float, b: float, c: float, d: float) -> float:
	var ex := c - a
	var ey := d - b
	var l2 := ex * ex + ey * ey
	var t := 0.0
	if l2 != 0.0:
		t = maxf(0.0, minf(1.0, ((u - a) * ex + (v - b) * ey) / l2))
	return hyp(u - a - ex * t, v - b - ey * t)


static func shade3(v: float, hw: float) -> String:
	if v < -0.2 * hw:
		return "h"
	return "s" if v > 0.45 * hw else "b"


## Samples shape(x, y) -> String on the 1/K grid around (cx, cy); returns a fine part.
static func rasterize_fine(k: float, cx: float, cy: float, r: float, shape: Callable, extra: Dictionary = {}) -> Dictionary:
	var i0 := floori((cx - r) * k)
	var j0 := floori((cy - r) * k)
	var i1 := ceili((cx + r) * k)
	var j1 := ceili((cy + r) * k)
	var rows: Array = []
	for j in range(j0, j1 + 1):
		var row := ""
		for i in range(i0, i1 + 1):
			var ch: String = shape.call((i + 0.5) / k, (j + 0.5) / k)
			row += ch if ch != "" else "."
		rows.append(row)
	var part := {"ox": i0 * UNIT / k, "oy": j0 * UNIT / k, "rows": rows, "res": k}
	part.merge(extra, true)
	return part


## Samples on the character pixel grid (no own resolution).
static func rasterize(cx: float, cy: float, r: float, shape: Callable, extra: Dictionary = {}) -> Dictionary:
	var x0 := floori(cx - r)
	var y0 := floori(cy - r)
	var rows: Array = []
	for y in range(y0, ceili(cy + r) + 1):
		var row := ""
		for x in range(x0, ceili(cx + r) + 1):
			var ch: String = shape.call(x + 0.5, y + 0.5)
			row += ch if ch != "" else "."
		rows.append(row)
	var part := {"x": x0, "y": y0, "rows": rows}
	part.merge(extra, true)
	return part


## Shape in the frame of a grip point: u along angle ang (degrees), v across.
static func local_shape(gx: float, gy: float, ang: float, shape: Callable) -> Callable:
	var c := cos(rad(ang))
	var s := sin(rad(ang))
	return func(px: float, py: float) -> String:
		var dx := px - gx
		var dy := py - gy
		return shape.call(dx * c + dy * s, -dx * s + dy * c)


static func _wood(u: float, v: float, q: float, lo := "a", hi := "A", hw := 0.6) -> String:
	if q >= 1.0:
		return lo if v < 0.0 else hi
	if v > hw - q * 1.01:
		return hi
	return hi if (floori(u * 1.6 + sin(u * 2.1) * 0.7) & 3) == 0 else lo


static func _blade(id: String, u: float, v: float, q: float) -> String:
	var p: Dictionary = BLADES[id]
	var length: float = p["len"]
	var hw: float = p["hw"]
	var guard: float = p["guard"]
	var grip: float = p["grip"]
	var pommel: bool = p.get("pommel", true)
	var curve: float = p.get("curve", 0.0)
	var tsuba: bool = p.get("tsuba", false)
	var fine := q < 1.0
	var av := absf(v)
	if pommel:
		var d := hyp(u + grip + 0.5, v)
		if d <= 0.95:
			if fine and d < 0.42:
				return "r"
			return "y" if v < -0.1 else "Y"
	if u >= -grip and u < 0.6 and av <= 0.62:
		if fine:
			return "a" if (floori((u - v * 0.9) * 2.4) & 1) != 0 else "A"
		return "a" if floori(u * 1.4) % 2 != 0 else "A"
	if tsuba:
		var d := hyp(u - 1.0, v)
		if d <= 1.45 and u < 1.6:
			if fine and d > 1.45 - q * 1.1:
				return "Y"
			if fine and d < 0.4:
				return "G"
			return "y" if v < 0.0 else "Y"
	elif u >= 0.6 and u < 1.5 and av <= guard:
		if fine and av < 0.38 and absf(u - 1.05) < 0.32:
			return "r"
		if fine and (u > 1.5 - q * 1.01 or av > guard - q * 1.01):
			return "Y"
		return "y" if v < 0.0 else "Y"
	if u >= 1.5 and u <= length:
		var vv := v - curve * pow((u - 1.5) / (length - 1.5), 2.0)
		var t := length - u
		var h := maxf(hw * t / 2.0 if t < 2.0 else hw, 0.32)
		if absf(vv) <= h:
			if not fine:
				return shade3(vv, hw)
			if vv < -h + q * 1.01:
				return "w"
			if vv > h - q * 1.01:
				return "s"
			if p.get("fuller", true) and u > 2.3 and t > 2.6 and absf(vv) < q * 0.55 + 0.06:
				return "s"
			if curve != 0.0 and absf(vv - h * 0.35) < q * 0.5 and (floori(u * 2.0) & 1) != 0:
				return "w"
			return "h" if vv < 0.0 else "b"
	return ""


static func _axe(u: float, v: float, q: float) -> String:
	var fine := q < 1.0
	var edge := -4.6 + 0.35 * pow(u - 8.3, 2.0)
	if u >= 6.2 and u <= 10.4 and v >= edge and v <= 0.7 and (v < -1.6 or (u >= 7.3 and u <= 9.3)):
		if not fine:
			if v < edge + 0.9:
				return "h"
			return "s" if u > 9.2 else "b"
		if v < edge + q * 1.01:
			return "w"
		if v < edge + 0.85:
			return "h"
		if hyp(u - 8.3, v + 0.8) < 0.4:
			return "G"
		if u > 10.4 - q * 1.01 or (v > -1.6 and u > 9.3 - q * 1.01) or v > 0.7 - q * 1.01:
			return "d"
		return "s" if u > 9.2 else "b"
	if u >= 7.7 and u <= 8.9 and v > 0.6 and v <= 2.2:
		return "d" if fine and v > 2.2 - q * 1.01 else "s"
	if u >= -2.5 and u <= 10.6 and absf(v) <= 0.6:
		return "Y" if fine and u < -1.8 else _wood(u, v, q)
	return ""


static func _hammer(u: float, v: float, q: float) -> String:
	var fine := q < 1.0
	var av := absf(v)
	if u >= 8.0 and u <= 11.3 and av <= 3.0:
		if not fine:
			if av >= 1.1 and av <= 1.6:
				return "Y"
			if u < 8.7:
				return "h"
			return "s" if u > 10.5 else "b"
		if av >= 1.1 and av <= 1.6:
			return "w" if absf(u - 9.65) < 0.4 else "Y"
		if u < 8.0 + q * 1.01 or v < -3.0 + q * 1.01:
			return "w"
		if u > 11.3 - q * 1.01 or v > 3.0 - q * 1.01:
			return "d"
		if av > 2.2 and absf(u - 9.65) < 0.9:
			return "s"
		if u < 8.8:
			return "h"
		return "s" if u > 10.5 else "b"
	if u >= -2.5 and u <= 9.0 and av <= 0.6:
		return "Y" if fine and u < -1.8 else _wood(u, v, q)
	return ""


static func _spear(u: float, v: float, q: float) -> String:
	var fine := q < 1.0
	var av := absf(v)
	if u >= 12.0 and u <= 16.0:
		var h := maxf(1.5 * minf(1.0, (16.0 - u) / 3.0), 0.32)
		if av <= h:
			if not fine:
				return "h" if v < 0.0 else "b"
			if av < q * 0.6:
				return "w"
			if av > h - q * 1.01:
				return "w" if v < 0.0 else "s"
			return "h" if v < 0.0 else "b"
	if u >= 11.4 and u < 12.0 and av <= 0.8:
		return "Y" if fine and u < 11.4 + q * 1.01 else "G"
	if u >= 10.2 and u < 11.4 and av <= 1.4:
		if fine:
			return "r" if (floori(v * 3.2) & 1) != 0 else "R"
		return "r" if v < 0.0 else "R"
	if u >= -6.0 and u <= 12.0 and av <= 0.58:
		return "G" if fine and u < -5.3 else _wood(u, v, q, "a", "A", 0.58)
	return ""


static func _staff(u: float, v: float, q: float) -> String:
	var fine := q < 1.0
	var d := hyp(u - 10.6, v)
	if d <= 1.6:
		if not fine:
			if u > 10.9 and v < -0.2:
				return "w"
			return "A" if d > 1.1 else "a"
		if hyp(u - 11.15, v + 0.55) < 0.42 or hyp(u - 10.0, v - 0.7) < 0.2:
			return "w"
		return "A" if d > 1.6 - q * 1.01 or (u < 10.1 and v > 0.3) else "a"
	if d <= 2.4 and u < 11.4:
		return "Y" if fine and d > 2.4 - q * 1.01 else "y"
	if u >= -6.0 and u <= 9.0 and absf(v) <= 0.62:
		if fine and (absf(u - 8.0) < 0.35 or absf(u - 0.2) < 0.3 or absf(u + 0.8) < 0.3):
			return "y"
		return _wood(u, v, q, "h" if v < 0.0 else "b", "s", 0.62)
	return ""


static func arrow_shape(u: float, v: float, q: float, tail := -5.0) -> String:
	var fine := q < 1.0
	var av := absf(v)
	if u > 0.0 and u <= 1.8 and av <= 0.95 * (1.8 - u) / 1.8 + 0.2:
		return "w" if fine and v < -0.95 * (1.8 - u) / 1.8 - 0.2 + q * 1.01 else "g"
	var sw := maxf(q * 0.6, 0.2) if fine else 0.5
	if u >= tail - 0.3 and u <= 0.0:
		if u < tail + 1.4:
			var fw := 0.2 + (tail + 1.4 - u) * 0.45 if fine else 0.5
			if av <= fw:
				if fine and av < sw:
					return "C"
				return "r" if (floori(u * 3.0) & 1) != 0 else "w"
		if av <= sw:
			return "C"
	return ""


static func _bow(u: float, v: float, q: float, pull: float, arrow: bool) -> String:
	var fine := q < 1.0
	var big_r := 7.5
	var a_max := rad(58.0)
	var ex := -big_r + big_r * cos(a_max)
	var ey := big_r * sin(a_max)
	var pu := ex - pull
	var du := u + big_r
	var d := hyp(du, v)
	var a := atan2(v, du)
	if absf(a) <= a_max + 0.05:
		var grip := absf(v) < 1.1
		var th := 0.75 if grip else 0.62 - absf(a) / a_max * 0.2
		if absf(d - big_r) <= th:
			if grip:
				return "A" if fine and (floori(v * 3.0) & 1) != 0 else "a"
			if fine and absf(a) > a_max - 0.1:
				return "y"
			if fine:
				if d - big_r > th - q * 1.01:
					return "h"
				return "s" if d - big_r < -th + q * 1.01 else "b"
			return "h" if v < 0.0 else "b"
	if arrow:
		var r := arrow_shape(u - 3.6, v, q, pu - 3.6)
		if r != "":
			return r
	var sw := maxf(q * 0.75, 0.2) if fine else 0.48
	if seg_dist(u, v, ex, -ey, pu, 0.0) <= sw or seg_dist(u, v, ex, ey, pu, 0.0) <= sw:
		return "w"
	return ""


## Weapon shape: wst = {K, pull, arrow}.
static func weapon_shape(id: String, u: float, v: float, wst: Dictionary) -> String:
	var q := 1.0 / float(wst.get("K", 1.0))
	match id:
		"sword", "great", "katana", "dagger":
			return _blade(id, u, v, q)
		"axe":
			return _axe(u, v, q)
		"hammer":
			return _hammer(u, v, q)
		"spear":
			return _spear(u, v, q)
		"staff":
			return _staff(u, v, q)
		"bow":
			return _bow(u, v, q, wst.get("pull", 0.0), wst.get("arrow", false))
	return ""


## Fine part of a weapon with its grip at g, pointing at angle ang (degrees).
static func weapon_part(weapon: Dictionary, k: float, grip: Array, ang: float, wst: Dictionary) -> Dictionary:
	var id: String = weapon["id"]
	var shape := func(u: float, v: float) -> String:
		return weapon_shape(id, u, v, wst)
	return rasterize_fine(k, grip[0], grip[1], weapon["reach"], local_shape(grip[0], grip[1], ang, shape))


## Quiver on the back (bow only): oy is the body bob.
static func quiver_parts(oy: float, k: float) -> Array:
	var a := [17.6, 14.0 + oy]
	var b := [21.0, 23.5 + oy]
	var ang := atan2(b[1] - a[1], b[0] - a[0]) * 180.0 / PI
	var length := hyp(b[0] - a[0], b[1] - a[1])
	var q := 1.0 / k
	var fine := q < 1.0
	var shape := func(u: float, v: float) -> String:
		if u < 0.0:
			for entry: Array in [[-0.75, "w"], [0.0, "r"], [0.75, "w"]]:
				var dv := absf(v - float(entry[0]))
				if u >= -1.4 and dv <= (maxf(q * 0.6, 0.2) if fine else 0.4):
					return "C"
				if u >= -3.2 and u < -1.4 and dv <= 0.2 + (u + 3.2) * 0.17:
					return entry[1]
			return ""
		if u > length or absf(v) > 1.4:
			return ""
		if u < 1.3 or length - u < 1.0:
			return "Y"
		if fine and absf(v - 0.75) < q * 0.6 and (floori(u * 2.5) & 1) != 0:
			return "Y"
		if v < -0.3:
			return "h"
		return "s" if v > 0.5 else "b"
	return [rasterize_fine(k, (a[0] + b[0]) / 2.0, (a[1] + b[1]) / 2.0 - 2.0, length / 2.0 + 5.0, local_shape(a[0], a[1], ang, shape))]


## Quiver strap across the chest.
static func quiver_strap(oy: float, k: float) -> Dictionary:
	var shape := func(px: float, py: float) -> String:
		var d := seg_dist(px, py, 12.5, 18.6 + oy, 6.4, 26.0 + oy)
		if d <= 0.55:
			return "A" if k > 1.0 and d > 0.55 - 1.0 / k else "a"
		return ""
	return rasterize_fine(k, 9.5, 22.5 + oy, 6.0, shape, {"outline": false})


## Arm from shoulder s at angle ang: [[part, palette], ...]. kind: none|short|long, sp sleeve palette, kp skin palette.
static func arm_parts(s: Array, ang: float, kind: String, sp: Dictionary, kp: Dictionary, arm_len: float, k: float) -> Array:
	var cap := func(length: float, r: float, kk: float) -> Dictionary:
		var fn := local_shape(s[0], s[1], ang, func(u: float, v: float) -> String:
			var inside := (u >= 0.0 and u <= length and absf(v) <= r) or hyp(u, v) <= r or hyp(u - length, v) <= r
			if not inside:
				return ""
			return "d" if kk > 1.0 and u > length - 0.6 and u <= length + r else shade3(v, r))
		var cx: float = s[0] + cos(rad(ang)) * length / 2.0
		var cy: float = s[1] + sin(rad(ang)) * length / 2.0
		if kk > 1.0:
			return rasterize_fine(kk, cx, cy, length / 2.0 + r + 1.0, fn, {"thick": true})
		return rasterize(cx, cy, length / 2.0 + r + 1.0, fn)
	var out: Array = []
	if kind != "long":
		out.append([cap.call(arm_len - 0.6, 0.95, 1.0), kp])
	if kind == "long":
		out.append([cap.call(arm_len - 1.6, 1.15, k), sp])
	if kind == "short":
		out.append([cap.call(3.4, 1.2, k), sp])
	return out


static func fist(hx: float, hy: float) -> Dictionary:
	return rasterize(hx, hy, 2.5, func(px: float, py: float) -> String:
		if hyp(px - hx, py - hy) <= 1.25:
			return "s" if py - hy > 0.35 or px - hx > 0.5 else "b"
		return "")
