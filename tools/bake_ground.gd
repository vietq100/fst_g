extends SceneTree
## Bakes the pixel-art ground of every region into res://assets/ground/<region id>.png
## (GroundPainter). Run after changing a region's shape or the painter:
##   godot --headless --path . --script tools/bake_ground.gd
## then `godot --headless --path . --import` so the PNGs are imported.

const OUT_DIR := "res://assets/ground"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var registry: Node = load("res://core/data_registry.gd").new()
	registry.report_errors = false
	registry.load_all("res://data", "res://data/config/game_config.tres")
	var world := WorldService.new(registry)
	for region in world.get_regions():
		var started := Time.get_ticks_msec()
		var image := GroundPainter.new().paint(world, region)
		if image == null:
			continue
		var path := "%s/%s.png" % [OUT_DIR, region.id]
		image.save_png(ProjectSettings.globalize_path(path))
		print("baked %s %s in %d ms" % [path, image.get_size(), Time.get_ticks_msec() - started])
	var water_started := Time.get_ticks_msec()
	var water := WaterPainter.new().paint(world)
	water.save_png(ProjectSettings.globalize_path("%s/water.png" % OUT_DIR))
	print("baked water %s in %d ms" % [water.get_size(), Time.get_ticks_msec() - water_started])
	registry.free()
	quit()
