extends TestCase

const DataRegistryScript := preload("res://core/data_registry.gd")
const FIXTURE_ROOT := "res://tests/fixtures/data"
const BAD_ROOT := "res://tests/fixtures/bad_data"
const REAL_CONFIG := "res://data/config/game_config.tres"
const MISSING_CONFIG := "res://tests/fixtures/missing_config.tres"

var _registry: Node


func before_each() -> void:
	_registry = DataRegistryScript.new()
	_registry.report_errors = false


func after_each() -> void:
	_registry.free()


func test_loads_definition_by_id() -> void:
	_registry.load_all(FIXTURE_ROOT, REAL_CONFIG)
	var hunter := _registry.find_def(&"hunter", &"test_hunter") as HunterDefinition
	assert_not_null(hunter)
	assert_eq(hunter.display_name, "Test Hunter")
	assert_almost_eq(hunter.base_hp, 100.0)
	assert_eq(_registry.load_errors.size(), 0)


func test_unknown_id_returns_null() -> void:
	_registry.load_all(FIXTURE_ROOT, REAL_CONFIG)
	assert_null(_registry.find_def(&"hunter", &"does_not_exist"))
	assert_false(_registry.has_def(&"hunter", &"does_not_exist"))
	assert_null(_registry.find_def(&"unknown_category", &"test_hunter"))


func test_missing_folders_are_empty_not_errors() -> void:
	_registry.load_all(FIXTURE_ROOT, REAL_CONFIG)
	assert_eq(_registry.get_count(&"item"), 0)
	assert_eq(_registry.get_all(&"item").size(), 0)


func test_missing_config_falls_back_to_defaults() -> void:
	_registry.load_all(FIXTURE_ROOT, MISSING_CONFIG)
	assert_not_null(_registry.config)
	assert_eq(_registry.load_errors.size(), 1)
	assert_true(_registry.load_errors[0].contains("GameConfig"))


func test_rejects_duplicate_missing_id_and_wrong_type() -> void:
	_registry.load_all(BAD_ROOT, REAL_CONFIG)
	var errors: PackedStringArray = _registry.load_errors
	assert_eq(errors.size(), 3, "duplicate + missing id + wrong type")
	assert_true(_contains(errors, "duplicate"))
	assert_true(_contains(errors, "missing id"))
	assert_true(_contains(errors, "expected HunterDefinition"))
	# The first duplicate (alphabetical path order) is kept.
	assert_eq(_registry.get_count(&"hunter"), 1)
	assert_eq(_registry.find_def(&"hunter", &"duplicate").display_name, "Duplicate A")


func _contains(errors: PackedStringArray, text: String) -> bool:
	for error in errors:
		if error.contains(text):
			return true
	return false
