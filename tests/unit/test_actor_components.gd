extends TestCase

var _health: HealthController
var _state: StateController


func before_each() -> void:
	_health = HealthController.new()
	_state = StateController.new()


func after_each() -> void:
	_health.free()
	_state.free()


func test_health_setup_full_or_current() -> void:
	_health.setup(100.0)
	assert_almost_eq(_health.current_health, 100.0)
	_health.setup(100.0, 40.0)
	assert_almost_eq(_health.current_health, 40.0)
	_health.setup(100.0, 500.0)
	assert_almost_eq(_health.current_health, 100.0)


func test_damage_clamps_and_dies_once() -> void:
	_health.setup(30.0)
	var deaths: Array[int] = [0]
	_health.died.connect(func() -> void: deaths[0] += 1)
	assert_almost_eq(_health.take_damage(20.0), 20.0)
	assert_almost_eq(_health.take_damage(20.0), 10.0)
	assert_true(_health.is_dead())
	assert_almost_eq(_health.take_damage(5.0), 0.0)
	assert_eq(deaths[0], 1)


func test_heal_clamps_and_not_when_dead() -> void:
	_health.setup(100.0, 90.0)
	assert_almost_eq(_health.heal(25.0), 10.0)
	_health.take_damage(100.0)
	assert_almost_eq(_health.heal(25.0), 0.0)
	_health.revive(30.0)
	assert_false(_health.is_dead())
	assert_almost_eq(_health.current_health, 30.0)


func test_set_max_health_clamps_current() -> void:
	_health.setup(100.0)
	_health.set_max_health(60.0)
	assert_almost_eq(_health.current_health, 60.0)
	_health.set_max_health(120.0)
	assert_almost_eq(_health.current_health, 60.0)


func test_health_changed_signal() -> void:
	var values: Array[float] = []
	_health.health_changed.connect(func(current: float, _max: float) -> void: values.append(current))
	_health.setup(50.0)
	_health.take_damage(10.0)
	assert_eq(values, [50.0, 40.0] as Array[float])


func test_state_transitions() -> void:
	assert_true(_state.change(StateController.State.MOVING))
	assert_true(_state.is_state(StateController.State.MOVING))
	assert_true(_state.change(StateController.State.DOWNED))
	assert_false(_state.change(StateController.State.IDLE), "downed is sticky")
	_state.revive()
	assert_true(_state.is_state(StateController.State.IDLE))


func test_facing_from_vector() -> void:
	assert_eq(Facing.from_vector(Vector2(1, 0.2)), Facing.Direction.RIGHT)
	assert_eq(Facing.from_vector(Vector2(-3, 1)), Facing.Direction.LEFT)
	assert_eq(Facing.from_vector(Vector2(0.5, -2)), Facing.Direction.UP)
	assert_eq(Facing.from_vector(Vector2(1, 1)), Facing.Direction.DOWN)
	assert_eq(Facing.from_vector(Vector2.ZERO, Facing.Direction.LEFT), Facing.Direction.LEFT)
