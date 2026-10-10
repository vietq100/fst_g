class_name TestCase
extends RefCounted
## Base class for tests run by tests/run_tests.gd (DECISIONS.md D22).
## Methods whose name starts with "test_" are run in declaration order.

var _failures: PackedStringArray = []


func before_each() -> void:
	pass


func after_each() -> void:
	pass


func assert_true(condition: bool, message := "") -> void:
	if not condition:
		_fail("expected true", message)


func assert_false(condition: bool, message := "") -> void:
	if condition:
		_fail("expected false", message)


func assert_eq(actual: Variant, expected: Variant, message := "") -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		_fail("expected %s, got %s" % [var_to_str(expected), var_to_str(actual)], message)


func assert_almost_eq(actual: float, expected: float, tolerance := 0.0001, message := "") -> void:
	if absf(actual - expected) > tolerance:
		_fail("expected %f ± %f, got %f" % [expected, tolerance, actual], message)


func assert_null(value: Variant, message := "") -> void:
	if value != null:
		_fail("expected null, got %s" % var_to_str(value), message)


func assert_not_null(value: Variant, message := "") -> void:
	if value == null:
		_fail("expected non-null", message)


func _fail(reason: String, message: String) -> void:
	_failures.append(reason if message.is_empty() else "%s: %s" % [message, reason])


func _take_failures() -> PackedStringArray:
	var failures := _failures
	_failures = []
	return failures
