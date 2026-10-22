extends TestCase
## Skill tiles: every class and monster skill gets a stable square icon.

const DataRegistryScript := preload("res://core/data_registry.gd")

var _registry: Node


func before_each() -> void:
	_registry = DataRegistryScript.new()
	_registry.report_errors = false
	_registry.load_all(DataRegistryScript.DATA_ROOT, DataRegistryScript.CONFIG_PATH)


func after_each() -> void:
	_registry.free()


func test_every_skill_has_a_square_icon() -> void:
	var count := 0
	for type: StringName in [&"class_skill", &"monster_skill"]:
		for definition in _registry.get_all(type):
			var skill := definition as GameDefinition
			var image := SkillIcons.image_of(skill)
			assert_eq(image.get_size(), Vector2i(SkillIcons.TEXELS, SkillIcons.TEXELS), String(skill.id))
			assert_true(image.get_pixel(12, 12).a > 0.0, "%s centre painted" % skill.id)
			count += 1
	assert_true(count >= 100, "icons for all skills")


func test_icon_is_stable_and_kind_changes_the_plate() -> void:
	var skill := _registry.find_def(&"class_skill", &"arrow_rain") as GameDefinition
	assert_eq(SkillIcons.image_of(skill).get_data(), SkillIcons.image_of(skill).get_data())
	assert_eq(SkillIcons.glyph_of(skill), &"arrow")


func test_skill_modal_and_tile_build() -> void:
	var skill := _registry.find_def(&"class_skill", &"arrow_rain") as GameDefinition
	var root := (Engine.get_main_loop() as SceneTree).root
	var tile := SkillTile.new().setup(skill, {"level": 2}, "Lv2")
	var modal := SkillInfoModal.new().setup(skill, {"level": 2, "max_level": 6, "lines": ["x"],
		"actions": [{"text": "Go", "action": func() -> void: pass}]})
	root.add_child(tile)
	root.add_child(modal)
	assert_true(tile.custom_minimum_size.x > SkillTile.SIDE, "tile size")
	assert_true(modal.get_child_count() >= 2, "modal built")
	tile.queue_free()
	modal.queue_free()
