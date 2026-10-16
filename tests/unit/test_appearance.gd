extends TestCase
## Hunter look (D47 data), the Forge body (D73) and the animations (D49).


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


func test_every_hair_style_is_a_forge_hair() -> void:
	assert_eq(ForgeLook.HAIR_IDS.size(), HunterAppearance.HAIR_STYLE_COUNT)
	for id: String in ForgeLook.HAIR_IDS:
		assert_true(ForgeData.has_item("hair", id), "hair " + id)
		assert_true(ForgeData.find_item("hair", id).has("rear"), "hair %s has a rear view" % id)
	assert_eq(ChibiBody.SKINS.size(), HunterAppearance.SKIN_COUNT)
	assert_eq(ChibiBody.HAIR_COLORS.size(), HunterAppearance.HAIR_COLOR_COUNT)


func test_every_animation_bakes_on_every_facing() -> void:
	# Long hair in the Guardian outfit, hammer and shield.
	var visual := ChibiVisual.new()
	visual.set_class_style(&"guardian")
	visual.appearance = HunterAppearance.from_dict({"hair_style": 6})
	for facing in [Facing.Direction.DOWN, Facing.Direction.UP, Facing.Direction.LEFT, Facing.Direction.RIGHT]:
		visual.facing = facing
		for animation: StringName in ChibiAnimations.ANIMATIONS:
			visual._animation = animation
			for index in visual._frames_of(animation).size():
				visual._frame = index
				var frame := visual._body_frame()
				assert_true(frame.textures.size() > 0, "%s %d %d" % [animation, facing, index])
				assert_true(frame.rect.size.x >= 10.0 and frame.rect.size.y >= 20.0, "%s %d visible" % [animation, facing])
				assert_true(frame.rect.end.y <= 1.5, "%s %d on the feet" % [animation, facing])
	visual.facing = Facing.Direction.UP
	visual._animation = ChibiAnimations.WALK
	visual._frame = 0
	assert_true(visual._state_key().begins_with("rear|"), "facing up shows the back")
	visual.free()


func test_rest_figure_and_portrait() -> void:
	var figure := ForgeLook.figure(HunterAppearance.new(), ChibiDress.plain(&"warrior"))
	# A ~16×35 body standing on the origin.
	assert_true(figure.rect.size.x >= 12.0 and figure.rect.size.x <= 30.0, "width %s" % figure.rect)
	assert_true(figure.rect.size.y >= 30.0 and figure.rect.size.y <= 44.0, "height %s" % figure.rect)
	assert_true(absf(figure.rect.end.y) <= 1.5, "feet at the origin")
	assert_true(figure.rect.intersects(ForgeLook.PORTRAIT), "the portrait crops the head")


func test_skin_hair_and_outfit_change_the_look() -> void:
	var a := HunterAppearance.from_dict({"skin": 0, "dye": 0, "hair_color": 0})
	var b := HunterAppearance.from_dict({"skin": 3, "dye": 5, "hair_color": 4})
	var cfg_a := ForgeLook.config(a)
	var cfg_b := ForgeLook.config(b)
	assert_true(cfg_a["skin"] != cfg_b["skin"], "skin")
	assert_true(cfg_a["shorts"] != cfg_b["shorts"], "dye")
	assert_true(cfg_a["hair"]["color"] != cfg_b["hair"]["color"], "hair colour")
	assert_true(cfg_a["eyes"] != cfg_b["eyes"], "eyes follow the hair (D51)")
	assert_eq(ForgeLook.config(a, ChibiDress.plain(&"warrior"))["shirt"]["id"], "armor")
	assert_eq(ForgeLook.config(a, ChibiDress.plain(&"ranger"))["shirt"]["id"], "jacket")
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
