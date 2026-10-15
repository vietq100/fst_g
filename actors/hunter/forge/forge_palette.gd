class_name ForgePalette
extends RefCounted
## Colour ramps of the Pixel Hero Forge: shade towards cold violet, light towards warm yellow.
## Colours are [r, g, b] arrays (0..255); a palette maps a part symbol to {c: [r, g, b], a: alpha}.


static func _round(v: float) -> float:
	return floorf(v + 0.5)


static func hex_to_rgb(hex: String) -> Array:
	var h := hex.trim_prefix("#")
	if h.length() == 3:
		h = "%s%s%s%s%s%s" % [h[0], h[0], h[1], h[1], h[2], h[2]]
	var n := h.hex_to_int()
	return [float((n >> 16) & 255), float((n >> 8) & 255), float(n & 255)]


static func rgb_to_hsl(r: float, g: float, b: float) -> Array:
	r /= 255.0
	g /= 255.0
	b /= 255.0
	var mx := maxf(r, maxf(g, b))
	var mn := minf(r, minf(g, b))
	var h := 0.0
	var s := 0.0
	var l := (mx + mn) / 2.0
	if mx != mn:
		var d := mx - mn
		s = d / (2.0 - mx - mn) if l > 0.5 else d / (mx + mn)
		if mx == r:
			h = (g - b) / d + (6.0 if g < b else 0.0)
		elif mx == g:
			h = (b - r) / d + 2.0
		else:
			h = (r - g) / d + 4.0
		h *= 60.0
	return [h, s * 100.0, l * 100.0]


static func hsl_to_rgb(h: float, s: float, l: float) -> Array:
	s /= 100.0
	l /= 100.0
	var a := s * minf(l, 1.0 - l)
	var out: Array = []
	for n in [0, 8, 4]:
		var k := fmod(n + h / 30.0, 12.0)
		out.append(_round((l - a * maxf(-1.0, minf(k - 3.0, minf(9.0 - k, 1.0)))) * 255.0))
	return out


static func hue_toward(h: float, target: float, amount: float) -> float:
	var d := fposmod(target - h + 540.0, 360.0) - 180.0
	return fposmod(h + signf(d) * minf(absf(d), amount) + 360.0, 360.0)


static func tone(rgb: Array, dl: float, ds: float, toward: float, amount: float) -> Array:
	var hsl := rgb_to_hsl(rgb[0], rgb[1], rgb[2])
	var h: float = hsl[0]
	if hsl[1] > 4.0:
		h = hue_toward(h, toward, amount)
	return hsl_to_rgb(h, clampf(hsl[1] + ds, 0.0, 100.0), clampf(hsl[2] + dl, 3.0, 97.0))


static func mix(a: Array, b: Array, t: float) -> Array:
	return [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t]


## Ramp of a base colour: h (light), b (base), s (shade), d (deep), o (outline), i (inner line).
static func ramp(hex: String) -> Dictionary:
	var b := hex_to_rgb(hex)
	var hsl := rgb_to_hsl(b[0], b[1], b[2])
	var h: float = hsl[0]
	var s: float = hsl[1]
	var l: float = hsl[2]
	return {
		"h": tone(b, 5.0 if l > 85.0 else 11.0, -4.0, 55.0, 8.0),
		"b": b,
		"s": tone(b, -12.0, 4.0, 250.0, 10.0),
		"d": tone(b, -22.0, 6.0, 250.0, 16.0),
		"o": hsl_to_rgb(hue_toward(h, 250.0, 18.0) if s > 4.0 else h, clampf(s * 0.7 + 8.0, 0.0, 70.0), clampf(l * 0.28, 5.0, 20.0)),
		"i": hsl_to_rgb(hue_toward(h, 250.0, 14.0) if s > 4.0 else h, clampf(s * 0.8 + 10.0, 0.0, 75.0), clampf(l * 0.38, 10.0, 28.0)),
	}


static func fixed() -> Dictionary:
	return ForgeData.data()["fixed"]


## Palette of an item: base colour and accent colour.
static func make_pal(color: String, accent: String = "") -> Dictionary:
	var r := ramp(color)
	var a := ramp(accent if accent != "" else color)
	var pal: Dictionary = fixed().duplicate()
	pal["b"] = {"c": r["b"]}
	pal["h"] = {"c": r["h"]}
	pal["s"] = {"c": r["s"]}
	pal["d"] = {"c": r["d"]}
	pal["a"] = {"c": a["b"]}
	pal["A"] = {"c": a["s"]}
	pal["l"] = {"c": a["h"], "a": 0.45}
	pal["o"] = r["o"]
	pal["i"] = r["i"]
	return pal


static func body_pal(skin: String, eyes: String, blink: bool) -> Dictionary:
	var p := make_pal(skin)
	var eye := {"c": hex_to_rgb(eyes)}
	p["e"] = eye
	p["E"] = p["b"] if blink else eye
	p["k"] = {"c": mix(p["b"]["c"], [255, 105, 120], 0.4)}
	p["m"] = {"c": mix(p["s"]["c"], [150, 45, 60], 0.55)}
	return p
