extends Node
## Autoload. Owns game-wide state and gameplay services. Keep minimal (ARCHITECTURE.md).
## Services are plain objects created here; this node also drives real-time town timers.
## `build(registry)` also works on a fresh instance that is not in the tree (save tests).

signal game_initialized
## A world asks Main to show another world (e.g. &"sandbox", &"town").
signal world_change_requested(world_id: StringName)
## Any service asked for an autosave (DECISIONS.md D21). SaveManager listens.
signal autosave_requested(reason: StringName)

var is_initialized := false
var registry: Node
var rng := RandomNumberGenerator.new()
var stats: StatService
var hunters: HunterService
var combat: CombatService
var wallet: WalletService
var progress: ProgressService
var inventory: InventoryService
var loot: LootService
var world: WorldService
var buildings: BuildingService
var housing: HousingService
var recruitment: RecruitmentService
var temple: TempleService
var equipment: EquipmentService
var crafting: CraftingService
var traits: TraitService
var mood: MoodService
var bonds: BondService
var activities: ActivityService
var purses: PurseService
var supply: SupplyService
var needs: NeedsService
var regions: RegionService
var corpses: CorpseService
var talents: TalentService
var expeditions: ExpeditionService


func _ready() -> void:
	rng.randomize()
	build(DataRegistry)
	start_new_game()
	is_initialized = true
	game_initialized.emit()


func build(data_registry: Node) -> void:
	registry = data_registry
	var config: GameConfig = registry.config
	stats = StatService.new(config)
	hunters = HunterService.new(registry, stats, config)
	combat = CombatService.new(stats, rng)
	wallet = WalletService.new()
	progress = ProgressService.new()
	inventory = InventoryService.new(registry, wallet)
	loot = LootService.new(registry, rng)
	world = WorldService.new(registry)
	buildings = BuildingService.new(registry, wallet, inventory, progress, world)
	housing = HousingService.new(hunters, buildings)
	recruitment = RecruitmentService.new(registry, hunters, buildings, wallet, rng)
	recruitment.housing = housing
	temple = TempleService.new(hunters, buildings, wallet, stats, config)
	equipment = EquipmentService.new(registry, hunters, inventory)
	crafting = CraftingService.new(registry, buildings, wallet, inventory)
	traits = TraitService.new(registry, hunters, config, rng)
	mood = MoodService.new(hunters, traits, config)
	bonds = BondService.new(hunters, config)
	activities = ActivityService.new(registry, hunters, traits, mood, bonds, stats, progress, config)
	purses = PurseService.new(wallet, config)
	supply = SupplyService.new(registry, inventory, purses, hunters, buildings)
	needs = NeedsService.new(hunters, housing, supply, mood, config)
	activities.needs = needs
	corpses = CorpseService.new(hunters, wallet, config)
	regions = RegionService.new(registry, world, hunters, purses, inventory, wallet, loot, stats, progress, config, rng)
	talents = TalentService.new(registry, hunters, regions, config, rng)
	needs.talents = talents
	expeditions = ExpeditionService.new(registry, hunters, wallet, progress, inventory, loot, stats, config, rng)
	_connect_services()


func _connect_services() -> void:
	recruitment.add_candidate_decorator(traits.assign_random_traits)
	recruitment.add_candidate_decorator(talents.assign_random_talent)
	recruitment.hunter_recruited.connect(equipment.give_starting_gear)
	hunters.hunter_added.connect(func(hunter: HunterRuntime) -> void:
		hunter.history[HunterRuntime.RECRUIT_DAY] = progress.day)
	bonds.set_party_provider(func() -> Array:
		return expeditions.current_run.party_ids if expeditions.is_running() else [])
	expeditions.expedition_finished.connect(func(run: ExpeditionRun) -> void:
		mood.on_expedition_finished(run, expeditions.get_definition(run.expedition_id))
		bonds.on_expedition_finished(run)
		recruitment.refresh_candidates())
	expeditions.downed_handler = func(hunter: HunterRuntime, expedition_id: StringName) -> void:
		var definition := expeditions.get_definition(expedition_id)
		if definition != null and definition.region_id != &"":
			corpses.die(hunter, world.get_entrance_point(definition))
		else:
			hunters.mark_injured(hunter)
	for service in [expeditions, buildings, recruitment, crafting]:
		service.autosave_requested.connect(autosave_requested.emit)


## Fresh state (DECISIONS.md D25). SaveManager replaces it when a save exists.
func start_new_game() -> void:
	var config: GameConfig = registry.config
	wallet.gold = config.start_gold
	for i in config.starting_hunter_count:
		var candidate := hunters.generate_candidate(config.starting_hunter_class, rng)
		traits.assign_random_traits(candidate)
		talents.assign_random_talent(candidate)
		equipment.give_starting_gear(hunters.add_hunter(candidate))
	for item_id in config.starting_food:
		inventory.add_item(item_id, config.starting_food[item_id])
	recruitment.refresh_candidates()


## Clears every service back to an empty world, then starts a new game.
func reset_to_new_game() -> void:
	var warnings := PackedStringArray()
	expeditions.current_run = null
	corpses.clear()
	hunters.from_dict({}, warnings)
	inventory.from_dict({}, warnings)
	bonds.from_dict({}, warnings)
	progress.from_dict({})
	buildings.reset()
	start_new_game()


func _process(delta: float) -> void:
	advance_town_time(delta)


## Real-time town timers: Hospital, activities, day counter. Also the entry point for offline
## catch-up (DECISIONS.md D24).
## `offline`: Hunters out in the regions are frozen while the app is closed (D36).
func advance_town_time(seconds: float, offline: bool = false) -> void:
	if seconds <= 0.0:
		return
	temple.tick(seconds)
	activities.tick(seconds, not offline)
	progress.advance(seconds, registry.config.day_length_seconds)


func request_world(world_id: StringName) -> void:
	world_change_requested.emit(world_id)
