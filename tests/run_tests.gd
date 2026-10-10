extends SceneTree
## Headless test runner (DECISIONS.md D22).
## Usage: godot --headless --path . -s res://tests/run_tests.gd [-- <file name filter>]
## Runs every tests/**/test_*.gd script that extends TestCase. Exit code 1 on failure.
## A script/runtime error during a test also fails that test.

const TEST_ROOT := "res://tests"


## Collects engine/script errors so the runner can fail the current test.
class ErrorCollector extends Logger:
	var errors: PackedStringArray = []
	var _mutex := Mutex.new()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		_mutex.lock()
		errors.append("%s (%s:%d %s)" % [rationale if not rationale.is_empty() else code, file.get_file(), line, function])
		_mutex.unlock()

	func take() -> PackedStringArray:
		_mutex.lock()
		var result := errors
		errors = []
		_mutex.unlock()
		return result


var _started := false


func _process(_delta: float) -> bool:
	# Run on the first frame (not in _initialize) so nodes added to root get _ready().
	if _started:
		return false
	_started = true
	var collector := ErrorCollector.new()
	OS.add_logger(collector)
	var result := _run_all(collector)
	OS.remove_logger(collector)
	print("\n%d passed, %d failed" % [result.x, result.y])
	quit(1 if result.y > 0 else 0)
	return false


func _run_all(collector: ErrorCollector) -> Vector2i:
	var passed := 0
	var failed := 0
	var args := OS.get_cmdline_user_args()
	var filter := args[0] if not args.is_empty() else ""
	for path in _find_test_scripts(TEST_ROOT):
		if not filter.is_empty() and not path.get_file().contains(filter):
			continue
		collector.take()
		var script := load(path) as GDScript
		if script == null or not script.can_instantiate():
			printerr("  FAIL %s: could not load / compile" % path)
			failed += 1
			continue
		for method in script.get_script_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			var test_case := script.new() as TestCase
			if test_case == null:
				printerr("  FAIL %s: does not extend TestCase" % path)
				failed += 1
				break
			collector.take()
			test_case.before_each()
			test_case.call(method_name)
			test_case.after_each()
			var failures := test_case._take_failures()
			for error in collector.take():
				failures.append("runtime error: " + error)
			if failures.is_empty():
				passed += 1
				print("  ok   %s :: %s" % [path.get_file(), method_name])
			else:
				failed += 1
				printerr("  FAIL %s :: %s" % [path.get_file(), method_name])
				for failure in failures:
					printerr("       - " + failure)
	return Vector2i(passed, failed)


func _find_test_scripts(folder: String) -> PackedStringArray:
	var result := PackedStringArray()
	for file in DirAccess.get_files_at(folder):
		if file.begins_with("test_") and file.ends_with(".gd"):
			result.append(folder.path_join(file))
	for directory in DirAccess.get_directories_at(folder):
		if directory != "fixtures":
			result.append_array(_find_test_scripts(folder.path_join(directory)))
	result.sort()
	return result
