class_name ForgeComposer
extends RefCounted
## Builds a ForgeRenderer from a look config, like compose() of the Pixel Hero Forge.
## cfg: {skin, eyes, tank, shorts, black, hair/shirt/pants/shoes/glasses/hat/weapon: {id, color, accent}, fx}
## st:
## - bob, blink: breathing and blinking of the rest pose (HTML anim loop).
## - pose: one frame of ANIMS (arm / wpn / dx / dy / ext / behind / draw / elbow / pull / arrow) with its effects
##   (arc, hit, shock, circle, charge, strike, proj, lines, mark, fade) in the element `cfg.fx`.
## - frames, fi: the whole sequence (default: the weapon's ANIMS) and this frame's index (impact point, particles
##   from the hit frame on); p: progress inside the frame (0..1); t: time (ms, particles and flicker); seed.
## - offsets: part group -> Vector2i, the game's animation tables (ChibiAnimations) moving whole parts
##   (head, torso, arm_l, arm_r, leg_l, leg_r; pants follow the higher leg).
## - hand: Vector2i, moves the resting weapon hand (the shoulder follows arm_r).
## - no_weapon: draw empty hands (picked-up items, lying bodies); no_shadow: skip the ground shadow.
## - back: the rear view (facing up, HTML composeRear): no face or glasses, hair over the head, the weapon
##   behind the body, quiver and long hair over the back. Rest and table animations only (no pose).
## Zero offsets give exactly the original engine's output (golden tests).

const OPT_CATS := ["hair", "shirt", "pants", "shoes", "glasses", "hat", "weapon"]


## group: a part group, or a rule picking it per part ("@upper", "@leg", "@shirt").
static func _draw_all(g: ForgeRenderer, parts: Variant, pal: Dictionary, options: Dictionary, offsets: Dictionary = {},
		group: String = "") -> void:
	if parts == null:
		return
	for part: Dictionary in parts:
		var name := group
		match group:
			"@upper":
				name = _upper_group(part)
			"@leg":
				name = _leg_group(part)
			"@shirt":
				name = _shirt_group(part)
		g.draw_part(part, pal, _moved(options, offsets, name))


## Options moved by a part group's offset.
static func _moved(options: Dictionary, offsets: Dictionary, group: String) -> Dictionary:
	if group == "" or offsets.is_empty():
		return options
	var offset := _offset(offsets, group)
	if offset == Vector2i.ZERO:
		return options
	return options.merged({"dx": float(options.get("dx", 0.0)) + offset.x, "dy": float(options.get("dy", 0.0)) + offset.y}, true)


static func _offset(offsets: Dictionary, group: String) -> Vector2i:
	if group == "hips":
		# Pants and shorts cover both legs: they follow the higher one.
		var left: Vector2i = offsets.get(&"leg_l", Vector2i.ZERO)
		var right: Vector2i = offsets.get(&"leg_r", Vector2i.ZERO)
		return Vector2i(left.x if left.x == right.x else 0, mini(left.y, right.y))
	return offsets.get(StringName(group), Vector2i.ZERO)


## Body parts: far arm, torso, near arm (by column).
static func _upper_group(part: Dictionary) -> String:
	var x: int = part["x"]
	if x <= 4:
		return "arm_l"
	return "arm_r" if x >= 12 else "torso"


static func _leg_group(part: Dictionary) -> String:
	return "leg_l" if int(part["x"]) <= 8 else "leg_r"


## Far sleeve of a top (HTML isFar: left of the body, at most 3 character pixels wide).
static func _is_far(part: Dictionary) -> bool:
	var width := float(String(part["rows"][0]).length()) / float(part.get("res", 1.0))
	return int(part["x"]) <= 4 and width <= 3.0


static func _shirt_group(part: Dictionary) -> String:
	if part.get("near", false):
		return "arm_r"
	return "arm_l" if _is_far(part) else "torso"


static func _rad(degrees: float) -> float:
	return degrees * PI / 180.0


## Shoulder, hand, grip and tip of a posed weapon arm (HTML poseGeom).
static func _pose_geom(pose: Dictionary, ox: float, oy: float, weapon: Dictionary) -> Dictionary:
	var data := ForgeData.data()
	var shoulder: Array = data["shoulder"]
	var arm_len: float = data["arm_len"]
	var s := [shoulder[0] + ox, shoulder[1] + oy]
	var a := _rad(pose.get("arm", 0.0))
	var w := _rad(pose.get("wpn", 0.0))
	var e: float = pose.get("ext", 0.0)
	var h := [s[0] + arm_len * cos(a), s[1] + arm_len * sin(a)]
	var grip := [h[0] + e * cos(w), h[1] + e * sin(w)]
	var tip: float = weapon.get("tip", 0.0)
	return {"S": s, "H": h, "G": grip, "T": [grip[0] + tip * cos(w), grip[1] + tip * sin(w)]}


## Item of every category for a config (the empty-handed "none" weapon with `st.no_weapon`).
static func _items(cfg: Dictionary, st: Dictionary) -> Dictionary:
	var item := {}
	for cat: String in OPT_CATS:
		item[cat] = ForgeData.find_item(cat, cfg.get(cat, {}).get("id", "none"))
	if st.get("no_weapon", false):
		item["weapon"] = ForgeData.find_item("weapon", "none")
	return item


## Resting weapon arm: the hand on the grip (moved by `st.hand`), the shoulder following the body bob and
## the arm_r offset; arm angle and length from shoulder to hand.
static func _rest_arm(weapon: Dictionary, st: Dictionary, bob: float) -> Dictionary:
	var shoulder: Array = ForgeData.data()["shoulder"]
	var hold: Array = weapon["hold"]
	var arm := _offset(st.get("offsets", {}), "arm_r")
	var hand: Vector2i = st.get("hand", Vector2i.ZERO)
	var h2 := [hold[0] + hand.x, hold[1] + hand.y]
	var s2 := [shoulder[0] + arm.x, shoulder[1] + bob + arm.y]
	return {"S": s2, "H": h2, "G": h2, "arm": atan2(h2[1] - s2[1], h2[0] - s2[0]) * 180.0 / PI,
		"len": ForgeShapes.hyp(h2[0] - s2[0], h2[1] - s2[1])}


static func compose(cfg: Dictionary, st: Dictionary = {}) -> ForgeRenderer:
	if st.get("back", false) and not st.has("pose"):
		return compose_rear(cfg, st)
	var data := ForgeData.data()
	var g := ForgeRenderer.new()
	var outline := "black" if cfg.get("black", true) else "color"
	var item := _items(cfg, st)
	var pal := func(cat: String) -> Dictionary:
		return ForgePalette.make_pal(cfg[cat]["color"], cfg[cat].get("accent", ""))
	var skin := ForgePalette.body_pal(cfg["skin"], cfg["eyes"], st.get("blink", false))
	var clip: Variant = item["hat"].get("clip")
	var offsets: Dictionary = st.get("offsets", {})
	var weapon: Dictionary = item["weapon"]
	var has_shape: bool = weapon.get("has_shape", false)
	var pose: Dictionary = st.get("pose", {}) if has_shape else {}
	var posed := not pose.is_empty()
	var ox: float = pose.get("dx", 0.0) if posed else 0.0
	var oy: float = pose.get("dy", 0.0) if posed else st.get("bob", 0.0)
	var up := {"dx": ox, "dy": oy, "outline": outline}
	var plain := {"outline": outline}
	var fixed := ForgePalette.fixed()
	var kw: float = data["res"]["weapon"]
	var ks: float = data["res"]["shirt"]
	var shirt: Dictionary = item["shirt"]
	var wpal: Dictionary = pal.call("weapon") if has_shape else {}
	var shoulder: Array = data["shoulder"]
	var archer: bool = posed and weapon.get("anim", "") == "shoot"

	# Weapon arm: rest pose (the arm reaches the grip; the weapon does not follow the breathing bob),
	# an attack pose, or the archer's two arms.
	var gm := {}
	var w_part := {}
	if archer:
		var bow_hand: Array = data["bow_hand"]
		var far: Array = data["far_shoulder"]
		var draw_at: Array = pose["draw"]
		var elbow: Array = pose["elbow"]
		var bh := [bow_hand[0] + ox, bow_hand[1] + oy]
		gm = {"S": [shoulder[0] + ox, shoulder[1] + oy], "H": [draw_at[0] + ox, draw_at[1] + oy], "G": bh,
			"E": [elbow[0] + ox, elbow[1] + oy], "FS": [far[0] + ox, far[1] + oy], "T": [bh[0] - 5.4, bh[1]]}
	elif posed:
		gm = _pose_geom(pose, ox, oy, weapon)
	elif has_shape:
		gm = _rest_arm(weapon, st, oy)
	if has_shape:
		var angle: float = 180.0 if archer else (pose.get("wpn", 0.0) if posed else weapon["hold"][2])
		var wst := {"K": kw, "pull": pose.get("pull", 0.0), "arrow": pose.get("arrow", false)}
		if archer:
			wst["pull"] = maxf(0.0, gm["H"][0] - gm["G"][0] - 3.53) if pose.get("arrow", false) else 0.0
		w_part = ForgeShapes.weapon_part(weapon, kw, gm["G"], angle, wst)
	var kind := "none"
	if shirt.has("parts"):
		kind = shirt.get("sleeve", "long")
	var sleeve_pal: Dictionary = ForgePalette.make_pal(shirt["sleeveColor"]) if shirt.has("sleeveColor") else pal.call("shirt")
	var draw_arm := func(entries: Array) -> void:
		for entry: Array in entries:
			g.draw_part(entry[0], entry[1], plain)
	# Effects (HTML "HIỆU ỨNG"): element colours, fading, impact point of the sequence.
	var el: String = cfg.get("fx", "none")
	var fc := ForgeFx.colors(el)
	var fade: float = pose.get("fade", 1.0) if posed else 1.0
	var p: float = st.get("p", 0.0)
	var t: float = st.get("t", 0.0)
	var seed_value := int(st.get("seed", 1))
	var frames: Array = st.get("frames", []) if st.has("frames") else ForgeData.data()["anims"].get(weapon.get("anim", ""), [])
	var hit: Array = _impact(frames, weapon) if posed else []
	var ground: float = data["ground"]
	var draw_weapon := func() -> void:
		g.draw_part(w_part, wpal, plain)
		if el != "none":
			ForgeFx.aura(g, w_part, fc[1], 0.55 if posed else 0.25 + 0.15 * sin(t / 140.0))

	if not st.get("no_shadow", false):
		_draw_all(g, data["shadow"], fixed, plain)
	# Ground layer: magic circle, shock wave.
	if posed and pose.has("circle"):
		var rx: float = 6.5 + float(pose["circle"])
		var ca: float = 0.5 + float(pose["circle"]) * 0.2
		ForgeFx.ring(g, 9.5, ground, rx, rx * 0.3, fc[1], ca, 0.12)
		ForgeFx.ring(g, 9.5, ground, rx * 0.62, rx * 0.62 * 0.3, fc[2], ca * 0.8)
		for k in 6:
			var an := t * 0.004 + k * PI / 3.0
			ForgeFx.put(g, 9.5 + cos(an) * rx * 0.82, ground + sin(an) * rx * 0.82 * 0.3, fc[0], ca)
	if posed and pose.has("shock") and not hit.is_empty():
		var shock := float(pose["shock"])
		var sx := 3.0 + shock * 3.5 + p * 3.0
		ForgeFx.ring(g, hit[0], ground, sx, sx * 0.32, fc[1] if shock != 0.0 else fc[0], fade, 0.15)
	var hair_pal: Dictionary = pal.call("hair")
	hair_pal["K"] = skin["s"]
	_draw_all(g, item["hair"].get("back"), hair_pal, up.merged({"clip": clip}), offsets, "head")
	_draw_all(g, shirt.get("back"), pal.call("shirt"), up, offsets, "torso")
	if posed and pose.get("behind", false):
		draw_weapon.call()
	if weapon["id"] == "bow":
		_draw_all(g, ForgeShapes.quiver_parts(oy, kw), wpal, plain, offsets, "torso")
	_draw_all(g, data["body"]["legs"], skin, plain, offsets, "@leg")
	var upper: Array = data["body"]["upper"]
	if archer:
		upper = upper.slice(1, 2)
	elif not gm.is_empty():
		upper = upper.slice(0, 2)
	_draw_all(g, upper, skin, up, offsets, "@upper")
	if item["pants"].has("parts"):
		_draw_all(g, item["pants"]["parts"], pal.call("pants"), plain, offsets, "hips")
	else:
		_draw_all(g, data["under"]["shorts"], ForgePalette.make_pal(cfg["shorts"]), plain, offsets, "hips")
	_draw_all(g, item["shoes"].get("parts"), pal.call("shoes"), plain, offsets, "@leg")
	if shirt.has("parts"):
		var shirt_parts: Array = shirt["parts"]
		if not gm.is_empty():
			shirt_parts = shirt_parts.filter(func(q: Dictionary) -> bool:
				return not q.get("near", false) and not (archer and _is_far(q)))
		_draw_all(g, shirt_parts, pal.call("shirt"), up, offsets, "@shirt")
	else:
		_draw_all(g, data["under"]["tank"], ForgePalette.make_pal(cfg["tank"]), up, offsets, "torso")
	if weapon["id"] == "bow":
		g.draw_part(ForgeShapes.quiver_strap(oy, kw), wpal, _moved({"outline": outline, "dx": ox}, offsets, "torso"))
	if archer:
		# Far arm stretched to the bow (behind the head, over the body).
		var fs: Array = gm["FS"]
		draw_arm.call(ForgeShapes.arm_parts(fs, 180.0, kind, sleeve_pal, skin, fs[0] - gm["G"][0], ks))
		draw_weapon.call()
		g.draw_part(ForgeShapes.fist(gm["G"][0], gm["G"][1]), skin, plain)
	_draw_all(g, data["body"]["head"], skin, up.merged({"cast": true}), offsets, "head")
	_draw_all(g, item["hair"].get("parts"), hair_pal, up.merged({"clip": clip, "cast": true, "inner": false}), offsets, "head")
	var glass_id: String = item["glasses"]["id"]
	if data["glasses"].has(glass_id):
		g.draw_part(data["glasses"][glass_id], pal.call("glasses"), _moved(up, offsets, "head"))
	else:
		_draw_all(g, item["glasses"].get("parts"), pal.call("glasses"), up, offsets, "head")
	_draw_all(g, item["hat"].get("parts"), pal.call("hat"), up.merged({"cast": true}), offsets, "head")
	if gm.is_empty():
		return g
	var arm_len: float = data["arm_len"]
	if posed and pose.get("arc") != null:
		var tip: float = weapon.get("tip", 0.0)
		ForgeFx.arc(g, gm["S"], arm_len + tip - 4.0, arm_len + tip + 0.5, pose["arc"][0], pose["arc"][1], fc, fade)
	if archer:
		# Near arm: elbow raised back, forearm drawing the string to the cheek.
		var seg := func(a: Array, b: Array, k: String) -> Array:
			return ForgeShapes.arm_parts(a, atan2(b[1] - a[1], b[0] - a[0]) * 180.0 / PI, k, sleeve_pal, skin,
				ForgeShapes.hyp(b[0] - a[0], b[1] - a[1]), ks)
		draw_arm.call(seg.call(gm["S"], gm["E"], kind) + seg.call(gm["E"], gm["H"], "long" if kind == "long" else "none"))
	else:
		if not pose.get("behind", false):
			draw_weapon.call()
		var arm_angle: float = pose.get("arm", 0.0) if posed else gm["arm"]
		var arm_length: float = arm_len if posed else gm["len"]
		draw_arm.call(ForgeShapes.arm_parts(gm["S"], arm_angle, kind, sleeve_pal, skin, arm_length, ks))
	g.draw_part(ForgeShapes.fist(gm["H"][0], gm["H"][1]), skin, plain)
	if not posed:
		return g
	_draw_effects(g, pose, gm, weapon, wpal, outline, el, fc, fade, hit, frames, int(st.get("fi", 0)), p, t, seed_value)
	return g


## Attack effects over the figure (the end of the HTML compose).
static func _draw_effects(g: ForgeRenderer, pose: Dictionary, gm: Dictionary, weapon: Dictionary, wpal: Dictionary,
		outline: String, el: String, fc: Array, fade: float, hit: Array, frames: Array, fi: int, p: float, t: float,
		seed_value: int) -> void:
	var data := ForgeData.data()
	var tx: float = gm["T"][0]
	var ty: float = gm["T"][1]
	if pose.get("lines", false):
		# Speed lines behind a thrust.
		for i in range(-2, 3):
			var length := 3 + ((i + 5) * 7 + seed_value) % 4
			var x0 := tx + 2.0 + absi(i)
			ForgeFx.line(g, x0, ty + i * 1.3, x0 + length, ty + i * 1.3, fc[1] if i != 0 else fc[0], fade * 0.7)
	if pose.has("mark"):
		var mark := float(pose["mark"])
		ForgeFx.cross(g, tx - 1.0 + mark * 0.5, ty - mark * 0.5, 1.5 + mark * 0.5, fc, fade)
	if pose.has("charge"):
		# Gathering power at the staff's tip (or the weapon's).
		var o := [tx, ty]
		if weapon.get("anim", "") == "cast":
			var w := ForgeShapes.rad(pose.get("wpn", 0.0))
			var tip: float = weapon.get("tip", 0.0)
			o = [gm["G"][0] + tip * cos(w), gm["G"][1] + tip * sin(w)]
		ForgeFx.glow(g, o[0], o[1], 1.4 + float(pose["charge"]) + 0.4 * sin(t / 50.0), fc, 0.85)
		var r := ForgeFx.rng(seed_value)
		for i in 10:
			var an := ForgeFx.next(r) * PI * 2.0
			var q := fmod(t * 0.003 + ForgeFx.next(r), 1.0)
			var d := 7.0 * (1.0 - q)
			ForgeFx.put(g, o[0] + cos(an) * d, o[1] + sin(an) * d, fc[0] if q > 0.6 else fc[1], 0.9)
	if pose.has("strike"):
		ForgeFx.strike(g, el, data["cast_x"], int(pose["strike"]), p, t, seed_value, fc, fade)
	if pose.has("proj"):
		# Arrow in flight.
		var kw: float = data["res"]["weapon"]
		var ax: float = gm["G"][0] - 7.5 - 3.5 * (float(pose["proj"]) + p)
		var ay: float = gm["G"][1]
		ForgeFx.line(g, ax + 1.0, ay, ax + 9.0, ay, fc[1], 0.7)
		ForgeFx.line(g, ax + 3.0, ay - 1.0, ax + 7.0, ay - 1.0, fc[2], 0.4)
		var arrow := func(u: float, v: float) -> String:
			return ForgeShapes.arrow_shape(u, v, 1.0 / kw)
		g.draw_part(ForgeShapes.rasterize_fine(kw, ax, ay, 6.0, ForgeShapes.local_shape(ax, ay, 180.0, arrow)), wpal,
			{"outline": outline})
	if hit.is_empty():
		return
	var first_hit := -1
	for i in frames.size():
		if (frames[i] as Dictionary).get("hit", false):
			first_hit = i
			break
	if pose.get("hit", false):
		ForgeFx.burst(g, hit[0], hit[1], 2.5 + p * 2.5, fc, 1.0 - p * 0.4)
	if fi >= first_hit:
		ForgeFx.particles(g, el, hit[0], hit[1], 3.5, 12, t, seed_value, fc, fade)


## Where the sequence's hit lands (HTML impactPoint), in design pixels; [] without a hit frame.
static func _impact(frames: Array, weapon: Dictionary) -> Array:
	var data := ForgeData.data()
	var hf := {}
	for frame: Dictionary in frames:
		if frame.get("hit", false):
			hf = frame
			break
	if hf.is_empty():
		return []
	var anim: String = weapon.get("anim", "")
	var dy: float = hf.get("dy", 0.0)
	if anim == "shoot":
		return [float(data["bow_x"]), float(data["bow_hand"][1]) + dy]
	var gm := _pose_geom(hf, hf.get("dx", 0.0), dy, weapon)
	var ground: float = data["ground"]
	if anim == "smash" or anim == "heavy":
		return [gm["T"][0], ground - 1.0 if anim == "smash" else gm["T"][1]]
	if anim == "cast":
		return [float(data["cast_x"]), ground - 3.0]
	return gm["T"]


## Rear view (HTML composeRear), with the same `offsets` / `hand` / `no_weapon` / `no_shadow` as compose.
static func compose_rear(cfg: Dictionary, st: Dictionary = {}) -> ForgeRenderer:
	var data := ForgeData.data()
	var g := ForgeRenderer.new()
	var outline := "black" if cfg.get("black", true) else "color"
	var item := _items(cfg, st)
	var pal := func(cat: String) -> Dictionary:
		return ForgePalette.make_pal(cfg[cat]["color"], cfg[cat].get("accent", ""))
	var skin := ForgePalette.body_pal(cfg["skin"], cfg["eyes"], false)
	var clip: Variant = item["hat"].get("clip")
	var offsets: Dictionary = st.get("offsets", {})
	var bob: float = st.get("bob", 0.0)
	var up := {"dx": 0.0, "dy": bob, "outline": outline}
	var plain := {"outline": outline}
	var kw: float = data["res"]["weapon"]
	var ks: float = data["res"]["shirt"]
	var weapon: Dictionary = item["weapon"]
	var has_shape: bool = weapon.get("has_shape", false)
	var wpal: Dictionary = pal.call("weapon") if has_shape else {}
	var shirt: Dictionary = item["shirt"]
	var kind := "none"
	if shirt.has("parts"):
		kind = shirt.get("sleeve", "long")
	var sleeve_pal: Dictionary = ForgePalette.make_pal(shirt["sleeveColor"]) if shirt.has("sleeveColor") else pal.call("shirt")
	var hair_pal: Dictionary = pal.call("hair")
	hair_pal["K"] = skin["s"]
	var gm := _rest_arm(weapon, st, bob) if has_shape else {}

	if not st.get("no_shadow", false):
		_draw_all(g, data["shadow"], ForgePalette.fixed(), plain)
	# The weapon in front of the body is hidden behind it, seen from the back.
	if has_shape:
		var wst := {"K": kw, "pull": 0.0, "arrow": false}
		g.draw_part(ForgeShapes.weapon_part(weapon, kw, gm["H"], weapon["hold"][2], wst), wpal, plain)
	_draw_all(g, data["body"]["legs"], skin, plain, offsets, "@leg")
	var upper: Array = data["body"]["upper"]
	_draw_all(g, upper.slice(0, 2) if has_shape else upper, skin, up, offsets, "@upper")
	if item["pants"].has("parts"):
		_draw_all(g, item["pants"]["parts"], pal.call("pants"), plain, offsets, "hips")
	else:
		_draw_all(g, data["under"]["shorts"], ForgePalette.make_pal(cfg["shorts"]), plain, offsets, "hips")
	_draw_all(g, item["shoes"].get("parts"), pal.call("shoes"), plain, offsets, "@leg")
	if shirt.has("parts"):
		var shirt_parts: Array = shirt["parts"]
		if has_shape:
			shirt_parts = shirt_parts.filter(func(q: Dictionary) -> bool: return not q.get("near", false))
		_draw_all(g, shirt_parts, pal.call("shirt"), up, offsets, "@shirt")
	else:
		_draw_all(g, data["under"]["tank"], ForgePalette.make_pal(cfg["tank"]), up, offsets, "torso")
	if weapon["id"] == "bow":
		_draw_all(g, ForgeShapes.quiver_parts(bob, kw), wpal, plain, offsets, "torso")
	_draw_all(g, shirt.get("back"), pal.call("shirt"), up, offsets, "torso")
	_draw_all(g, data["body"]["head_rear"], skin, up.merged({"cast": true}), offsets, "head")
	var hair_opts := up.merged({"clip": clip, "cast": true, "inner": false})
	if item["hair"].get("has_custom_rear", false):
		_draw_all(g, item["hair"].get("rear"), hair_pal, hair_opts, offsets, "head")
	else:
		_draw_all(g, item["hair"].get("rear"), hair_pal, hair_opts, offsets, "head")
		_draw_all(g, item["hair"].get("parts"), hair_pal, hair_opts, offsets, "head")
		_draw_all(g, item["hair"].get("back"), hair_pal, up.merged({"clip": clip, "cast": true}), offsets, "head")
	_draw_all(g, _rear_hat(item["hat"]), pal.call("hat"), up.merged({"cast": true}), offsets, "head")
	if gm.is_empty():
		return g
	for entry: Array in ForgeShapes.arm_parts(gm["S"], gm["arm"], kind, sleeve_pal, skin, gm["len"], ks):
		g.draw_part(entry[0], entry[1], plain)
	g.draw_part(ForgeShapes.fist(gm["H"][0], gm["H"][1]), skin, plain)
	return g


## Hat parts seen from the back: its own `rear` parts, the `rear_keep` parts, or the front parts.
static func _rear_hat(hat: Dictionary) -> Variant:
	if hat.has("rear"):
		return hat["rear"]
	if hat.has("rear_keep"):
		var parts: Array = hat["parts"]
		var kept: Array = []
		for index: float in hat["rear_keep"]:
			kept.append(parts[int(index)])
		return kept
	return hat.get("parts")


## Weapon hand (fist centre) of a frame in design pixels: rest grip, posed hand or the bow hand.
static func hand_of(cfg: Dictionary, st: Dictionary = {}) -> Vector2:
	var data := ForgeData.data()
	var weapon := ForgeData.find_item("weapon", cfg.get("weapon", {}).get("id", "none"))
	var pose: Dictionary = st.get("pose", {})
	if not weapon.get("has_shape", false) or st.get("no_weapon", false):
		var idle: Array = data["idle_hand"]
		var arm: Vector2i = _offset(st.get("offsets", {}), "arm_r")
		return Vector2(idle[0] + arm.x, idle[1] + arm.y)
	if pose.is_empty():
		var hold: Array = weapon["hold"]
		var hand: Vector2i = st.get("hand", Vector2i.ZERO)
		return Vector2(hold[0] + hand.x, hold[1] + hand.y)
	var ox: float = pose.get("dx", 0.0)
	var oy: float = pose.get("dy", 0.0)
	if weapon.get("anim", "") == "shoot":
		var bow_hand: Array = data["bow_hand"]
		return Vector2(bow_hand[0] + ox, bow_hand[1] + oy)
	var gm := _pose_geom(pose, ox, oy, weapon)
	return Vector2(gm["H"][0], gm["H"][1])
