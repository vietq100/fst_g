extends TestCase
## CorpseService and revival (AUTONOMY_SYSTEM.md → Bodies, DECISIONS.md D30, BALANCE.md → Bodies).

const DataRegistryScript := preload("res://core/data_registry.gd")
const GameManagerScript := preload("res://core/game_manager.gd")

var _registry: Node
var _game: Node
var _corpses: CorpseService
var _fallen: HunterRuntime
var _carrier: HunterRuntime


func before_each() -> void:
	_registry = DataRegistryScript.new()
	_registry.report_errors = false
	_registry.load_all(DataRegistryScript.DATA_ROOT, DataRegistryScript.CONFIG_PATH)
	_game = GameManagerScript.new()
	_game.rng.seed = 4
	_game.build(_registry)
	_game.start_new_game()
	_corpses = _game.corpses
	_fallen = _game.hunters.get_all()[0]
	_carrier = _game.hunters.create_hunter(&"warrior", _game.rng)


func after_each() -> void:
	_game.hunters.clear_modifier_sources()
	_game.bonds.set_party_provider(func() -> Array: return [])
	_game.free()
	_registry.free()


func test_death_leaves_a_body() -> void:
	_fallen.task = HunterRuntime.HUNTING
	_corpses.die(_fallen, Vector2(10, 500))
	assert_false(_fallen.alive)
	assert_true(_corpses.is_body(_fallen))
	assert_eq(_fallen.world_position, Vector2(10, 500))
	assert_eq(_fallen.task, &"")
	assert_eq(_corpses.get_bodies(), [_fallen] as Array[HunterRuntime])
	assert_false(_corpses.can_carry(_fallen), "the dead do not carry")
	assert_false(_game.expeditions.validate(&"dark_forest", [_fallen.unique_id] as Array[StringName]).is_empty())


func test_carrier_rules() -> void:
	_corpses.die(_fallen, Vector2.ZERO)
	_carrier.stamina = 20.0
	assert_false(_corpses.can_carry(_carrier), "too tired")
	_carrier.stamina = 80.0
	_carrier.activity = ActivityService.SLEEPING
	assert_false(_corpses.can_carry(_carrier), "asleep")
	_carrier.activity = ActivityService.RESTING
	assert_eq(_corpses.assign(_fallen, _carrier), "")
	assert_eq(_corpses.get_carrier(_fallen), _carrier)
	assert_eq(_corpses.get_body_of(_carrier), _fallen)
	assert_false(_corpses.can_carry(_carrier), "already carrying")
	assert_false(_corpses.assign(_fallen, _carrier).is_empty())


func test_dragging_slows_the_carrier() -> void:
	var speed: float = _game.hunters.get_stat(_carrier, HunterService.MOVE_SPEED)
	_corpses.die(_fallen, Vector2.ZERO)
	_corpses.assign(_fallen, _carrier)
	assert_almost_eq(_game.hunters.get_stat(_carrier, HunterService.MOVE_SPEED), speed, 0.01, "walking to the body: full speed")
	_corpses.pick_up(_fallen)
	assert_true(_corpses.is_carried(_fallen))
	assert_almost_eq(_game.hunters.get_stat(_carrier, HunterService.MOVE_SPEED), speed * 0.7, 0.01)


func test_carrier_death_drops_the_body() -> void:
	_corpses.die(_fallen, Vector2.ZERO)
	_corpses.assign(_fallen, _carrier)
	_corpses.pick_up(_fallen)
	_corpses.die(_carrier, Vector2(40, 40))
	assert_null(_corpses.get_carrier(_fallen))
	assert_false(_corpses.is_carried(_fallen))
	assert_eq(_fallen.world_position, Vector2(40, 40))
	assert_eq(_corpses.get_bodies().size(), 2)


func test_delivery_and_revival_at_half() -> void:
	_corpses.die(_fallen, Vector2.ZERO)
	_fallen.stamina = 10.0
	_fallen.energy = 80.0
	_corpses.assign(_fallen, _carrier)
	_corpses.pick_up(_fallen)
	_corpses.deliver(_fallen)
	assert_true(_fallen.injured)
	assert_false(_corpses.is_body(_fallen))
	assert_null(_corpses.get_body_of(_carrier))
	_game.temple.tick(1.0)
	_game.temple.tick(_game.temple.get_recovery_seconds())
	assert_true(_fallen.alive)
	assert_false(_fallen.injured)
	var max_hp: float = _game.hunters.get_stat(_fallen, HunterService.MAX_HP)
	assert_almost_eq(_fallen.current_hp, max_hp * 0.5, 0.01)
	assert_almost_eq(_fallen.stamina, 50.0)
	assert_almost_eq(_fallen.energy, 80.0, 0.0001, "needs only rise to 50%")
	assert_eq(_fallen.state, HunterRuntime.LifecycleState.AVAILABLE)


func test_bodies_do_not_tick() -> void:
	_corpses.die(_fallen, Vector2.ZERO)
	var energy := _fallen.energy
	_game.advance_town_time(60.0)
	assert_almost_eq(_fallen.energy, energy)
	assert_almost_eq(_fallen.current_hp, 0.0)


func test_bodies_survive_save_and_load() -> void:
	_corpses.die(_fallen, Vector2(-300, 600))
	var data := SaveCodec.capture(_game)
	var copy: Node = GameManagerScript.new()
	copy.build(_registry)
	var warnings := PackedStringArray()
	SaveCodec.restore(copy, JSON.parse_string(JSON.stringify(data)), warnings)
	var restored: HunterRuntime = copy.hunters.get_hunter(_fallen.unique_id)
	assert_false(restored.alive)
	assert_eq(restored.world_position, Vector2(-300, 600))
	assert_true(copy.corpses.is_body(restored))
	assert_eq(restored.state, HunterRuntime.LifecycleState.RECOVERING)
	copy.hunters.clear_modifier_sources()
	copy.bonds.set_party_provider(func() -> Array: return [])
	copy.free()


func test_fallen_dungeon_party_lies_at_the_entrance() -> void:
	var party: Array[StringName] = [_fallen.unique_id, _carrier.unique_id]
	assert_not_null(_game.expeditions.start(&"dark_forest", party))
	_game.expeditions.mark_downed(_fallen.unique_id)
	_game.expeditions.complete()
	var entrance: Vector2 = _game.world.get_entrance_point(_game.expeditions.get_definition(&"dark_forest"))
	assert_true(_corpses.is_body(_fallen))
	assert_eq(_fallen.world_position, entrance)
	assert_true(_carrier.alive, "survivor")
	assert_eq(_carrier.expedition_id, &"")
	assert_eq(_game.world.region_at(entrance).id, &"dark_forest", "the entrance point is walkable forest")


func test_staff_carry_for_a_fee() -> void:
	_corpses.die(_fallen, Vector2.ZERO)
	var staff := _corpses.get_staff_ids()
	assert_eq(staff.size(), 2)
	_game.wallet.gold = 20
	assert_eq(_corpses.assign_staff(_fallen, staff[0]), "")
	assert_eq(_game.wallet.gold, 5, "15 gold per trip (D43)")
	assert_eq(_corpses.get_carrier_id(_fallen), staff[0])
	assert_null(_corpses.get_carrier(_fallen), "not a Hunter")
	assert_false(_corpses.is_staff_free(staff[0]))
	assert_eq(_corpses.get_free_staff(), [staff[1]] as Array[StringName])
	_corpses.pick_up(_fallen)
	_corpses.deliver(_fallen)
	assert_true(_fallen.injured)
	assert_true(_corpses.is_staff_free(staff[0]))


func test_staff_need_the_fee() -> void:
	_corpses.die(_fallen, Vector2.ZERO)
	_game.wallet.gold = 10
	assert_false(_corpses.assign_staff(_fallen, _corpses.get_staff_ids()[0]).is_empty())
	assert_false(_corpses.has_carrier(_fallen))
	assert_eq(_corpses.assign(_fallen, _carrier), "", "a Hunter carries for free instead")
