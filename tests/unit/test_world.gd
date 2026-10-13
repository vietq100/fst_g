extends TestCase
## WorldService geometry, BuildingService placement and HousingService beds
## (WORLD_DESIGN.md, BUILD_SYSTEM.md, DECISIONS.md D52, D32, D33).

const DataRegistryScript := preload("res://core/data_registry.gd")

var _registry: Node
var _wallet: WalletService
var _inventory: InventoryService
var _progress: ProgressService
var _hunters: HunterService
var _world: WorldService
var _buildings: BuildingService
var _housing: HousingService
var _rng: RandomNumberGenerator


func before_each() -> void:
	_registry = DataRegistryScript.new()
	_registry.report_errors = false
	_registry.load_all(DataRegistryScript.DATA_ROOT, DataRegistryScript.CONFIG_PATH)
	_rng = RandomNumberGenerator.new()
	_rng.seed = 11
	_wallet = WalletService.new()
	_inventory = InventoryService.new(_registry, _wallet)
	_progress = ProgressService.new()
	_hunters = HunterService.new(_registry, StatService.new(_registry.config), _registry.config)
	_world = WorldService.new(_registry)
	_buildings = BuildingService.new(_registry, _wallet, _inventory, _progress, _world)
	_housing = HousingService.new(_hunters, _buildings)


func after_each() -> void:
	_registry.free()


# --- WorldService ---------------------------------------------------------------------------

func test_tile_world_round_trip() -> void:
	for tile in [Vector2i(0, 0), Vector2i(5, 9), Vector2i(30, 2), Vector2i(17, 37)]:
		assert_eq(WorldService.tile_at(WorldService.tile_center(tile)), tile, str(tile))
	assert_eq(WorldService.tile_to_world(Vector2(1, 0)), Vector2(32, 0))
	assert_eq(WorldService.tile_to_world(Vector2(0, 1)), Vector2(0, 32))
	assert_eq(WorldService.rect_to_world(Rect2i(1, 2, 3, 4)), Rect2(32, 64, 96, 128))


func test_four_regions_and_four_gates() -> void:
	assert_eq(_world.get_regions().size(), 4)
	assert_eq(_world.get_town().id, &"town")
	var pairs: Array[String] = []
	for gate in _world.get_gates():
		var ids := [String(gate.region_a), String(gate.region_b)]
		ids.sort()
		pairs.append("-".join(ids))
	pairs.sort()
	assert_eq(pairs, ["ancient_ruins-goblin_cave", "ancient_ruins-town", "dark_forest-goblin_cave", "dark_forest-town"])
	assert_eq(_world.gates_of(&"town").size(), 2)


func test_region_lookup() -> void:
	assert_eq(_world.region_at(WorldService.tile_center(Vector2i(4, 4))).id, &"town")
	assert_eq(_world.region_at(WorldService.tile_center(Vector2i(45, 3))).id, &"ancient_ruins")
	assert_eq(_world.region_at(WorldService.tile_center(Vector2i(3, 45))).id, &"dark_forest")
	assert_eq(_world.region_at(WorldService.tile_center(Vector2i(50, 50))).id, &"goblin_cave")
	assert_null(_world.region_at(WorldService.tile_center(Vector2i(36, 3))), "gap between regions")


func test_dungeon_entrances_sit_outside_their_region() -> void:
	var active := 0
	for definition in _registry.get_all(&"expedition"):
		var expedition := definition as ExpeditionDefinition
		var region := _world.get_region(expedition.region_id)
		assert_not_null(region, String(expedition.id))
		assert_false(region.tile_rect.has_point(expedition.entrance_tile), "entrance on the outer edge")
		assert_true(region.tile_rect.grow(1).has_point(expedition.entrance_tile), "entrance next to the edge")
		if not expedition.locked:
			active += 1
	assert_eq(active, 1, "only the Forest Guardian's Grove is open")


# --- BuildingService placement --------------------------------------------------------------

func test_default_layout_is_valid() -> void:
	assert_eq(_buildings.get_instances().size(), 7)
	for placed in _buildings.get_instances():
		assert_eq(_buildings.can_place(placed.building_id, placed.tile, placed.instance_id), "", String(placed.building_id))


func test_can_place_reasons() -> void:
	var hall := _buildings.find_first(BuildingService.TOWN_HALL)
	assert_eq(_buildings.can_place(BuildingService.HOUSE, hall.tile), "Space is taken")
	assert_eq(_buildings.can_place(BuildingService.HOUSE, Vector2i(35, 0)), "Must be inside the Town")
	assert_eq(_buildings.can_place(BuildingService.HOUSE, Vector2i(-1, 0)), "Must be inside the Town")
	# The tiles in front of the Town → Ruins gate (x 34..35, y 17..18) stay free.
	assert_eq(_buildings.can_place(BuildingService.HOUSE, Vector2i(34, 17)), "Keep the gate road free")
	assert_eq(_buildings.can_place(BuildingService.HOUSE, Vector2i(14, 6)), "")
	# The Hospital at (6, 24) has its door at (7, 26), in front of its bottom face: nothing may
	# stand there.
	assert_eq(BuildingService.get_door_tile(Rect2i(6, 24, 2, 2)), Vector2i(7, 26))
	assert_eq(_buildings.can_place(BuildingService.HOUSE, Vector2i(6, 26)), "Blocks a door")


func test_build_costs_gold_and_unique_buildings_are_limited() -> void:
	assert_eq(_buildings.can_build(BuildingService.HOUSE), "Needs 120 gold")
	assert_eq(_buildings.can_build(BuildingService.TAVERN), "Already built")
	assert_false(_buildings.can_build(BuildingService.TOWN_HALL).is_empty())
	_wallet.add(150)
	var house := _buildings.build(BuildingService.HOUSE, Vector2i(14, 6))
	assert_not_null(house)
	assert_eq(_wallet.gold, 30)
	assert_eq(_buildings.get_instances_of(BuildingService.HOUSE).size(), 2)
	assert_null(_buildings.build(BuildingService.HOUSE, Vector2i(14, 6)), "occupied and no gold")


func test_move_and_remove() -> void:
	var warehouse := _buildings.find_first(BuildingService.WAREHOUSE)
	assert_eq(_buildings.move(warehouse.instance_id, Vector2i(20, 1)), "")
	assert_eq(warehouse.tile, Vector2i(20, 1))
	assert_eq(_buildings.move(warehouse.instance_id, _buildings.find_first(BuildingService.TOWN_HALL).tile), "Space is taken")
	assert_eq(_buildings.get_refund(warehouse.instance_id), 75)
	assert_eq(_buildings.remove(warehouse.instance_id), "")
	assert_eq(_wallet.gold, 75)
	assert_false(_buildings.has_building(BuildingService.WAREHOUSE))
	assert_eq(_inventory.capacity, 0, "no Warehouse, no storage")
	var hall := _buildings.find_first(BuildingService.TOWN_HALL)
	assert_false(_buildings.can_remove(hall.instance_id).is_empty())
	assert_false(_buildings.remove(hall.instance_id).is_empty())


func test_layout_save_round_trip_drops_overlaps() -> void:
	_wallet.add(500)
	_buildings.build(BuildingService.HOUSE, Vector2i(14, 6))
	var data := _buildings.to_dict()
	var instances: Array = data["instances"]
	# A corrupted entry on top of the Town Hall is dropped on load.
	instances.append({"instance_id": "b_99", "building_id": "house", "tile": [16, 14], "level": 1})
	var restored := BuildingService.new(_registry, _wallet, _inventory, _progress, _world)
	var warnings := PackedStringArray()
	restored.from_dict(data, warnings)
	assert_eq(restored.get_instances_of(BuildingService.HOUSE).size(), 2)
	assert_false(warnings.is_empty())


# --- HousingService -------------------------------------------------------------------------

func test_houses_give_four_beds_each() -> void:
	assert_eq(_housing.get_total_beds(), 4)
	for i in 5:
		_hunters.create_hunter(&"warrior", _rng)
	assert_eq(_housing.get_used_beds(), 4)
	assert_eq(_housing.get_free_beds(), 0)
	var homeless := _hunters.get_all().filter(func(h: HunterRuntime) -> bool: return _housing.get_home(h) == null)
	assert_eq(homeless.size(), 1)
	_wallet.add(200)
	_buildings.build(BuildingService.HOUSE, Vector2i(14, 6))
	assert_eq(_housing.get_total_beds(), 8)
	assert_eq(_housing.get_used_beds(), 5)
	assert_true(_hunters.get_all().all(func(h: HunterRuntime) -> bool: return _housing.get_home(h) != null))


func test_recruiting_needs_a_free_bed() -> void:
	var recruitment := RecruitmentService.new(_registry, _hunters, _buildings, _wallet, _rng)
	recruitment.housing = _housing
	recruitment.refresh_candidates()
	_wallet.add(1000)
	assert_eq(recruitment.can_recruit(0), "")
	_buildings.remove(_buildings.find_first(BuildingService.HOUSE).instance_id)
	assert_eq(_housing.get_total_beds(), 0)
	assert_eq(recruitment.can_recruit(0), "No free bed — build a House")


func test_pond_blocks_building() -> void:
	var pond := _world.get_town_pond()
	assert_true(pond.size != Vector2i.ZERO)
	assert_eq(_buildings.can_place(&"house", pond.position), "The pond is in the way")
