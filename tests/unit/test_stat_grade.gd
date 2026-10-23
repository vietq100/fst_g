extends TestCase
## StatGradeService (D80): the ten-step ladder, and averages built from the data.

const DataRegistryScript := preload("res://core/data_registry.gd")

var _registry: Node
var _hunters: HunterService
var _grades: StatGradeService
var _rng: RandomNumberGenerator


func before_each() -> void:
	_registry = DataRegistryScript.new()
	_registry.report_errors = false
	_registry.load_all(DataRegistryScript.DATA_ROOT, DataRegistryScript.CONFIG_PATH)
	var stats := StatService.new(_registry.config)
	_hunters = HunterService.new(_registry, stats, _registry.config)
	_grades = StatGradeService.new(_registry, stats, _hunters)
	_rng = RandomNumberGenerator.new()
	_rng.seed = 7


func after_each() -> void:
	_registry.free()


func test_ladder_steps_from_ratio() -> void:
	assert_eq(StatGradeService.step_of(0.3), StatGradeService.Step.POOR)
	assert_eq(StatGradeService.step_of(0.7), StatGradeService.Step.PLAIN)
	assert_eq(StatGradeService.step_of(1.0), StatGradeService.Step.AVERAGE, "blue is average")
	assert_eq(StatGradeService.step_of(1.149), StatGradeService.Step.AVERAGE)
	assert_eq(StatGradeService.step_of(1.15), StatGradeService.Step.GOOD, "lower bound belongs to the step")
	assert_eq(StatGradeService.step_of(2.0), StatGradeService.Step.STRONG)
	assert_eq(StatGradeService.step_of(4.0), StatGradeService.Step.ELITE)
	assert_eq(StatGradeService.step_of(50.0), StatGradeService.Step.SUPREME)
	assert_eq(StatGradeService.COLORS.size(), StatGradeService.Step.size())
	assert_eq(StatGradeService.NAME_KEYS.size(), StatGradeService.Step.size())
	assert_eq(StatGradeService.BOUNDS.size(), StatGradeService.Step.size() - 1)


func test_ratio_and_total() -> void:
	assert_almost_eq(StatGradeService.ratio_of(30.0, 20.0), 1.5)
	assert_almost_eq(StatGradeService.ratio_of(5.0, 0.0), 1.0, 0.0001, "no average → average")
	assert_almost_eq(StatGradeService.total_of([1.0, 3.0], [1.0, 1.0]), 2.0)
	assert_almost_eq(StatGradeService.total_of([1.0, 100.0], [1.0, 1.0]), (1.0 + StatGradeService.RATIO_CAP) * 0.5, 0.0001, "one freak stat is capped")
	assert_almost_eq(StatGradeService.total_of([], []), 1.0)


func test_hunter_average_is_the_mean_of_the_classes() -> void:
	var definitions: Array[GameDefinition] = _registry.get_all(&"hunter")
	var sum := 0.0
	for definition: HunterDefinition in definitions:
		sum += definition.base_attack
	assert_almost_eq(_grades.hunter_average(HunterService.ATTACK, 1), sum / definitions.size(), 0.001)
	assert_true(_grades.hunter_average(HunterService.MAX_HP, 10) > _grades.hunter_average(HunterService.MAX_HP, 1), "grows with the level")


func test_fresh_hunter_sits_near_the_average() -> void:
	var hunter := _hunters.create_hunter(&"warrior", _rng)
	var total := _grades.hunter_total(hunter)
	assert_true(total > 0.5 and total < 2.0, "a new tier-C Hunter is near average: %f" % total)
	var step := _grades.hunter_step(hunter, HunterService.ATTACK)
	assert_true(step >= StatGradeService.Step.POOR and step <= StatGradeService.Step.SUPREME)


func test_monster_and_item_grades() -> void:
	assert_true(_grades.monster_average(&"attack") > 0.0, "regular monsters have an average attack")
	assert_almost_eq(_grades.monster_average(&"attack", 2.0), _grades.monster_average(&"attack") * 2.0, 0.001, "level scale")
	assert_almost_eq(_grades.monster_average(&"attack_speed", 2.0), _grades.monster_average(&"attack_speed"), 0.001, "speed does not scale")
	assert_eq(_grades.monster_step(&"attack", _grades.monster_average(&"attack") * 3.0, 1.0), StatGradeService.Step.ELITE)
	var graded := 0
	for definition: ItemDefinition in _registry.get_all(&"item"):
		if definition.modifiers.is_empty():
			assert_almost_eq(_grades.item_total(definition), 1.0, 0.0001, "no bonuses → average")
			continue
		graded += 1
		assert_true(_grades.item_total(definition) > 0.0)
	assert_true(graded > 0, "gear with bonuses exists")


func test_item_delta_against_the_worn_item() -> void:
	var gear: Array[ItemDefinition] = []
	for definition: ItemDefinition in _registry.get_all(&"item"):
		if not definition.modifiers.is_empty():
			gear.append(definition)
	assert_true(gear.size() >= 2, "two pieces of gear to compare")
	assert_almost_eq(_grades.item_delta(gear[0], gear[0]), 0.0, 0.0001, "same item: no change")
	assert_almost_eq(_grades.item_delta(gear[0], null), _grades.item_total(gear[0]), 0.0001, "empty slot: the whole total")
	assert_almost_eq(_grades.item_delta(gear[0], gear[1]), -_grades.item_delta(gear[1], gear[0]), 0.0001, "antisymmetric")
	assert_true(_grades.item_delta(gear[0], gear[0], 3, 0) > 0.0, "+3 beats the same item unenhanced")


func test_hunter_grades_are_cached_until_the_hunter_changes() -> void:
	var hunter := _hunters.create_hunter(&"warrior", _rng)
	var before := _grades.hunter_total(hunter)
	_hunters.set_level(hunter, hunter.level + 5)
	# set_level emits hunter_changed → the cache is dropped and the new level counts at once.
	var after := _grades.hunter_total(hunter)
	assert_true(absf(after - before) < 0.5, "a higher level is measured against a higher average: %f → %f" % [before, after])
	hunter.level += 1
	assert_almost_eq(_grades.hunter_total(hunter), after, 0.0001, "a silent change is served from the cache")
	_grades.invalidate(hunter)
	var fresh := StatGradeService.ratio_of(_hunters.get_stat(hunter, HunterService.MAX_HP), _grades.hunter_average(HunterService.MAX_HP, hunter.level))
	assert_almost_eq(_grades.hunter_ratio(hunter, HunterService.MAX_HP), fresh, 0.0001, "recomputed after invalidate")
