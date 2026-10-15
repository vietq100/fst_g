class_name ForgeComposer
extends RefCounted
## Builds a ForgeRenderer from a look config, like compose() of the Pixel Hero Forge.
## cfg: {skin, eyes, tank, shorts, black, hair/shirt/pants/shoes/glasses/hat/weapon: {id, color, accent}, fx}
## st: {bob, blink}

const OPT_CATS := ["hair", "shirt", "pants", "shoes", "glasses", "hat", "weapon"]


static func _draw_all(g: ForgeRenderer, parts: Variant, pal: Dictionary, options: Dictionary) -> void:
	if parts == null:
		return
	for part: Dictionary in parts:
		g.draw_part(part, pal, options)


static func compose(cfg: Dictionary, st: Dictionary = {}) -> ForgeRenderer:
	var data := ForgeData.data()
	var g := ForgeRenderer.new()
	var outline := "black" if cfg.get("black", true) else "color"
	var item := {}
	for cat: String in OPT_CATS:
		item[cat] = ForgeData.find_item(cat, cfg.get(cat, {}).get("id", "none"))
	var pal := func(cat: String) -> Dictionary:
		return ForgePalette.make_pal(cfg[cat]["color"], cfg[cat].get("accent", ""))
	var skin := ForgePalette.body_pal(cfg["skin"], cfg["eyes"], st.get("blink", false))
	var clip: Variant = item["hat"].get("clip")
	var oy: float = st.get("bob", 0.0)
	var up := {"dx": 0.0, "dy": oy, "outline": outline}
	var plain := {"outline": outline}
	var fixed := ForgePalette.fixed()
	var kw: float = data["res"]["weapon"]
	var ks: float = data["res"]["shirt"]
	var weapon: Dictionary = item["weapon"]
	var shirt: Dictionary = item["shirt"]
	var has_shape: bool = weapon.get("has_shape", false)
	var wpal: Dictionary = pal.call("weapon") if has_shape else {}
	var shoulder: Array = data["shoulder"]

	# Rest pose: the arm reaches the grip; the weapon does not follow the breathing bob.
	var gm := {}
	var w_part := {}
	if has_shape:
		var hold: Array = weapon["hold"]
		var h2 := [hold[0], hold[1]]
		var s2 := [shoulder[0], shoulder[1] + oy]
		gm = {"S": s2, "H": h2, "G": h2, "arm": atan2(h2[1] - s2[1], h2[0] - s2[0]) * 180.0 / PI,
			"len": ForgeShapes.hyp(h2[0] - s2[0], h2[1] - s2[1])}
		w_part = ForgeShapes.weapon_part(weapon, kw, h2, hold[2], {"K": kw, "pull": 0.0, "arrow": false})
	var kind := "none"
	if shirt.has("parts"):
		kind = shirt.get("sleeve", "long")
	var sleeve_pal: Dictionary = ForgePalette.make_pal(shirt["sleeveColor"]) if shirt.has("sleeveColor") else pal.call("shirt")

	_draw_all(g, data["shadow"], fixed, plain)
	var hair_pal: Dictionary = pal.call("hair")
	hair_pal["K"] = skin["s"]
	_draw_all(g, item["hair"].get("back"), hair_pal, up.merged({"clip": clip}))
	_draw_all(g, shirt.get("back"), pal.call("shirt"), up)
	if weapon["id"] == "bow":
		_draw_all(g, ForgeShapes.quiver_parts(oy, kw), wpal, plain)
	_draw_all(g, data["body"]["legs"], skin, plain)
	var upper: Array = data["body"]["upper"]
	_draw_all(g, upper.slice(0, 2) if has_shape else upper, skin, up)
	if item["pants"].has("parts"):
		_draw_all(g, item["pants"]["parts"], pal.call("pants"), plain)
	else:
		_draw_all(g, data["under"]["shorts"], ForgePalette.make_pal(cfg["shorts"]), plain)
	_draw_all(g, item["shoes"].get("parts"), pal.call("shoes"), plain)
	if shirt.has("parts"):
		var shirt_parts: Array = shirt["parts"]
		if has_shape:
			shirt_parts = shirt_parts.filter(func(q: Dictionary) -> bool: return not q.get("near", false))
		_draw_all(g, shirt_parts, pal.call("shirt"), up)
	else:
		_draw_all(g, data["under"]["tank"], ForgePalette.make_pal(cfg["tank"]), up)
	if weapon["id"] == "bow":
		g.draw_part(ForgeShapes.quiver_strap(oy, kw), wpal, {"outline": outline, "dx": 0.0})
	_draw_all(g, data["body"]["head"], skin, up.merged({"cast": true}))
	_draw_all(g, item["hair"].get("parts"), hair_pal, up.merged({"clip": clip, "cast": true, "inner": false}))
	var glass_id: String = item["glasses"]["id"]
	if data["glasses"].has(glass_id):
		g.draw_part(data["glasses"][glass_id], pal.call("glasses"), up)
	else:
		_draw_all(g, item["glasses"].get("parts"), pal.call("glasses"), up)
	_draw_all(g, item["hat"].get("parts"), pal.call("hat"), up.merged({"cast": true}))
	if gm.is_empty():
		return g
	g.draw_part(w_part, wpal, plain)
	for entry: Array in ForgeShapes.arm_parts(gm["S"], gm["arm"], kind, sleeve_pal, skin, gm["len"], ks):
		g.draw_part(entry[0], entry[1], plain)
	g.draw_part(ForgeShapes.fist(gm["H"][0], gm["H"][1]), skin, plain)
	return g
