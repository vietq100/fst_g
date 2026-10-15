extends TestCase
## Hunter look (D47 data) and the chibi body + animations (D49).


func test_appearance_round_trip_and_sanitize() -> void:
	var look := HunterAppearance.new()
	look.gender = HunterAppearance.FEMALE
	look.hair_style = 4
	look.hair_color = 3
	look.skin = 2
	look.dye = 1
	var copy := HunterAppearance.from_dict(look.to_dict())
	assert_eq(copy.key(), look.key())
	var bad := HunterAppearance.from_dict({"gender": "x", "hair_style": 99, "dye": -1})
	assert_eq(bad.gender, HunterAppearance.MALE)
	assert_eq(bad.hair_style, 99 % HunterAppearance.HAIR_STYLE_COUNT)
	assert_eq(bad.dye, HunterAppearance.DYE_COUNT - 1)


func test_seeded_look_is_stable() -> void:
	assert_eq(HunterAppearance.from_seed("h_1Aldric", 3).key(), HunterAppearance.from_seed("h_1Aldric", 3).key())
	assert_eq(HunterAppearance.from_seed("anything", 11).dye, 3)


func test_runtime_saves_appearance_and_old_saves_get_one() -> void:
	var hunter := HunterRuntime.new()
	hunter.unique_id = &"h_7"
	hunter.appearance = HunterAppearance.from_dict({"gender": "female", "hair_style": 6})
	var restored := HunterRuntime.from_dict(hunter.to_dict())
	assert_eq(restored.appearance.key(), hunter.appearance.key())
	var legacy := hunter.to_dict()
	legacy.erase("appearance")
	var first := HunterRuntime.from_dict(legacy)
	var second := HunterRuntime.from_dict(legacy)
	assert_eq(first.appearance.key(), second.appearance.key())


func test_body_map_is_well_formed() -> void:
	assert_eq(ChibiBody.BODY.size(), ChibiBody.BODY_SIZE.y)
	for view in [ChibiBody.View.FRONT, ChibiBody.View.BACK, ChibiBody.View.SIDE]:
		for row: String in ChibiBody.body_map(view):
			assert_eq(row.length(), ChibiBody.BODY_SIZE.x, "view %d" % view)
	var symbols := ChibiBody.palette_for(HunterAppearance.new())
	for row: String in ChibiBody.BODY:
		for symbol in row:
			assert_true(symbol == "." or symbols.has(symbol), "symbol " + symbol)
	for outfit: StringName in ChibiBody.OUTFITS:
		var rows: Array = ChibiBody.OUTFITS[outfit]
		assert_eq(rows.size(), ChibiBody.BODY_SIZE.y - ChibiBody.TORSO_ROW, "outfit %s rows" % outfit)
		for row: String in rows:
			assert_eq(row.length(), ChibiBody.BODY_SIZE.x, "outfit %s" % outfit)
			for symbol in row:
				assert_true(symbol == "." or symbols.has(symbol), "outfit %s symbol %s" % [outfit, symbol])
	for style in ChibiBody.HAIR_STYLES.size():
		for view in [ChibiBody.View.FRONT, ChibiBody.View.BACK, ChibiBody.View.SIDE]:
			for row: String in ChibiBody.hair_map(style, view):
				assert_eq(row.length(), ChibiBody.BODY_SIZE.x, "hair %d view %d" % [style, view])
				for symbol in row:
					assert_true(symbol == "." or symbols.has(symbol), "hair symbol " + symbol)
	# Back view has no eyes; side view hides the far ear.
	assert_true(String(ChibiBody.BODY[ChibiBody.EYE_ROWS.x + 2]).contains("w"), "front has eye whites")
	assert_false(String(ChibiBody.body_map(ChibiBody.View.BACK)[ChibiBody.EYE_ROWS.x + 2]).contains("w"))
	assert_eq(String(ChibiBody.body_map(ChibiBody.View.SIDE)[ChibiBody.EYE_ROWS.x + 2])[0], ".")


func test_every_animation_composes_on_every_facing() -> void:
	# Long hair (the widest lying silhouette) in the Guardian outfit.
	var look := HunterAppearance.from_dict({"hair_style": 1})
	for animation: StringName in ChibiAnimations.ANIMATIONS:
		for facing in [Facing.Direction.DOWN, Facing.Direction.UP, Facing.Direction.LEFT, Facing.Direction.RIGHT]:
			var frames := ChibiBody.get_frames(look, facing, animation, &"guardian")
			assert_eq(frames.size(), ChibiAnimations.get_frames(animation).size(), "%s %d" % [animation, facing])
			for texture in frames:
				var image := texture.get_image()
				assert_eq(image.get_size(), ChibiBody.CANVAS)
				var used := image.get_used_rect()
				assert_true(used.size.x >= 12 and used.size.y >= 12, "%s %d visible" % [animation, facing])
				assert_true(used.end.y <= ChibiBody.CANVAS.y, "inside canvas")


func test_rest_pose_matches_reference_and_lying_is_wide() -> void:
	var look := HunterAppearance.new()
	var rest := ChibiBody.compose(look, ChibiBody.View.FRONT, {})
	var rest_used := rest.get_used_rect()
	# The body fills its box; hair adds a few rows above the head.
	assert_eq(rest_used.end, ChibiBody.BODY_ORIGIN + ChibiBody.BODY_SIZE)
	assert_eq(rest_used.position.x, ChibiBody.BODY_ORIGIN.x)
	assert_true(rest_used.position.y <= ChibiBody.BODY_ORIGIN.y and rest_used.position.y >= ChibiBody.BODY_ORIGIN.y + ChibiBody.HAIR_TOP)
	# Between the eyes, below the nose, is skin.
	var cheek := ChibiBody.BODY_ORIGIN + Vector2i(7, 10) * ChibiBody.SCALE
	assert_true(rest.get_pixel(cheek.x, cheek.y).is_equal_approx(ChibiBody.SKINS[0][1]))
	var lying := ChibiBody.compose(look, ChibiBody.View.FRONT, {"lying": true})
	var used := lying.get_used_rect()
	assert_true(used.size.x > used.size.y, "lying body is horizontal")
	assert_eq(used.end.y, ChibiBody.CANVAS.y - 1)


func test_raised_body_never_tears_from_the_legs() -> void:
	var image := ChibiBody.compose(HunterAppearance.new(), ChibiBody.View.FRONT, {"body": [0, -2]})
	# Every row between the head top and the feet has pixels.
	var used := image.get_used_rect()
	for y in range(used.position.y, used.end.y):
		var filled := false
		for x in range(used.position.x, used.end.x):
			if image.get_pixel(x, y).a > 0.0:
				filled = true
				break
		assert_true(filled, "row %d" % y)


func test_skin_and_dye_recolour() -> void:
	var a := HunterAppearance.from_dict({"skin": 0, "dye": 0})
	var b := HunterAppearance.from_dict({"skin": 3, "dye": 5})
	var head := ChibiBody.BODY_ORIGIN + Vector2i(7, 10) * ChibiBody.SCALE
	var shorts := ChibiBody.BODY_ORIGIN + Vector2i(7, 23) * ChibiBody.SCALE
	var image_a := ChibiBody.compose(a, ChibiBody.View.FRONT, {})
	var image_b := ChibiBody.compose(b, ChibiBody.View.FRONT, {})
	assert_false(image_a.get_pixel(head.x, head.y).is_equal_approx(image_b.get_pixel(head.x, head.y)))
	assert_false(image_a.get_pixel(shorts.x, shorts.y).is_equal_approx(image_b.get_pixel(shorts.x, shorts.y)))
	assert_eq(ChibiBody.get_portrait(a).get_size(), Vector2(ChibiBody.PORTRAIT_RECT.size))


func test_hair_and_outfit_layers() -> void:
	var dark := HunterAppearance.from_dict({"hair_style": 0, "hair_color": 0})
	var blonde := HunterAppearance.from_dict({"hair_style": 0, "hair_color": 4})
	var top := ChibiBody.BODY_ORIGIN + Vector2i(7, 1) * ChibiBody.SCALE
	var image_dark := ChibiBody.compose(dark, ChibiBody.View.FRONT, {})
	var image_blonde := ChibiBody.compose(blonde, ChibiBody.View.FRONT, {})
	assert_false(image_dark.get_pixel(top.x, top.y).is_equal_approx(image_blonde.get_pixel(top.x, top.y)), "hair colour")
	var chest := ChibiBody.BODY_ORIGIN + Vector2i(7, 17) * ChibiBody.SCALE
	var warrior := ChibiBody.compose(dark, ChibiBody.View.FRONT, {}, &"warrior")
	var ranger := ChibiBody.compose(dark, ChibiBody.View.FRONT, {}, &"ranger")
	assert_false(warrior.get_pixel(chest.x, chest.y).is_equal_approx(ranger.get_pixel(chest.x, chest.y)), "class outfit")
	var promoted := HunterDefinition.new()
	promoted.class_id = &"templar"
	promoted.promotion_of = &"guardian"
	assert_eq(ChibiBody.outfit_for(promoted), &"guardian")
	var unknown := HunterDefinition.new()
	unknown.class_id = &"bard"
	assert_eq(ChibiBody.outfit_for(unknown), &"")
	assert_eq(ChibiBody.outfit_for(null), &"")


func test_offsets_groups_and_side_override() -> void:
	var frame := {"body": [0, -1], "arm_r": [0, 1], "side": {"arm_r": [2, 0]}}
	var front := ChibiAnimations.resolve_offsets(frame, false)
	assert_eq(front[&"head"], Vector2i(0, -1))
	assert_eq(front[&"arm_r"], Vector2i(0, 0))
	assert_eq(front[&"leg_l"], Vector2i.ZERO)
	var side := ChibiAnimations.resolve_offsets(frame, true)
	assert_eq(side[&"arm_r"], Vector2i(2, -1))


func test_visual_state_machine() -> void:
	var visual := ChibiVisual.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(visual)
	visual._process(0.3)
	assert_eq(visual.get_animation(), ChibiAnimations.IDLE)
	visual.moving = true
	visual._process(0.01)
	assert_eq(visual.get_animation(), ChibiAnimations.WALK)
	visual.running = true
	visual._process(0.01)
	assert_eq(visual.get_animation(), ChibiAnimations.RUN)
	visual.play_action(ChibiAnimations.ATTACK)
	visual.play_action(ChibiAnimations.PICKUP)
	assert_eq(visual.get_animation(), ChibiAnimations.ATTACK, "lower priority does not interrupt")
	visual._process(1.0)
	assert_eq(visual.get_animation(), ChibiAnimations.RUN, "one-shot returns to the state animation")
	visual.moving = false
	visual.play_action(ChibiAnimations.LOOT)
	visual._process(2.0)
	assert_eq(visual.get_animation(), ChibiAnimations.IDLE)
	visual.downed = true
	assert_eq(visual.get_animation(), ChibiAnimations.DEATH)
	assert_true(visual.modulate.r < 1.0, "downed Hunter is darkened")
	visual.play_action(ChibiAnimations.SKILL)
	assert_eq(visual.get_animation(), ChibiAnimations.DEATH, "downed Hunters do not act")
	visual._process(2.0)
	assert_eq(visual.get_frame(), ChibiAnimations.get_frames(ChibiAnimations.DEATH).size() - 1, "death holds")
	visual.downed = false
	assert_eq(visual.get_animation(), ChibiAnimations.IDLE)
	assert_eq(visual.modulate, Color.WHITE)
	visual.free()


func test_world_size_is_unchanged_by_the_texel_density() -> void:
	# D56: twice the texels, same 32×48 world footprint; hands stay where they were.
	assert_eq(ChibiBody.CANVAS / ChibiBody.SCALE, Vector2i(32, 48))
	assert_eq(ChibiBody.FEET / ChibiBody.SCALE, Vector2i(16, 48))
	assert_eq(ChibiBody.hand_position(ChibiBody.View.FRONT, Vector2i.ZERO), Vector2(5.5, -8.5))
	assert_eq(ChibiBody.hand_position(ChibiBody.View.BACK, Vector2i.ZERO), Vector2(-6.5, -8.5))
	assert_eq(ChibiBody.hand_position(ChibiBody.View.FRONT, Vector2i(1, -2)), Vector2(6.5, -10.5))
	assert_eq(MonsterBodies.get_world_size(&"goblin"), Vector2(MonsterBodies.get_width(&"goblin"), MonsterBodies.get_height(&"goblin")) / MonsterBodies.SCALE)
	assert_almost_eq(WeaponSprites.length_of(&"sword"), 15.0)
