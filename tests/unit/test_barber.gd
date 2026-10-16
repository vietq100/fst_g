extends TestCase
## BarberService (D77): paid hair style and colour changes.

const DataRegistryScript := preload("res://core/data_registry.gd")

var _registry: Node
var _wallet: WalletService
var _hunters: HunterService
var _barber: BarberService
var _rng: RandomNumberGenerator


func before_each() -> void:
	_registry = DataRegistryScript.new()
	_registry.report_errors = false
	_registry.load_all(DataRegistryScript.DATA_ROOT, DataRegistryScript.CONFIG_PATH)
	var config: GameConfig = _registry.config
	_rng = RandomNumberGenerator.new()
	_rng.seed = 5
	_wallet = WalletService.new()
	_hunters = HunterService.new(_registry, StatService.new(config), config)
	_barber = BarberService.new(_hunters, _wallet, config)


func after_each() -> void:
	_hunters.clear_modifier_sources()
	_registry.free()


func test_restyle_costs_gold_and_changes_the_look() -> void:
	var hunter := _hunters.create_hunter(&"warrior", _rng)
	var style := (hunter.appearance.hair_style + 3) % HunterAppearance.HAIR_STYLE_COUNT
	var color := (hunter.appearance.hair_color + 1) % HunterAppearance.HAIR_COLOR_COUNT
	assert_false(_barber.restyle(hunter, style, color).is_empty(), "no gold, no new look")
	_wallet.add(_barber.get_cost() + 5)
	var changed := [0]
	_hunters.hunter_changed.connect(func(_hunter: HunterRuntime) -> void: changed[0] += 1)
	assert_eq(_barber.restyle(hunter, style, color), "")
	assert_eq(hunter.appearance.hair_style, style)
	assert_eq(hunter.appearance.hair_color, color)
	assert_eq(_wallet.gold, 5)
	assert_eq(changed[0], 1, "the sprite and panels refresh")
	assert_eq(HunterAppearance.from_dict(hunter.appearance.to_dict()).key(), hunter.appearance.key(), "saved")


func test_restyle_refuses_the_same_look_and_absent_hunters() -> void:
	var hunter := _hunters.create_hunter(&"ranger", _rng)
	_wallet.add(1000)
	assert_false(_barber.can_restyle(hunter, hunter.appearance.hair_style, hunter.appearance.hair_color).is_empty(), "same look")
	var other := (hunter.appearance.hair_style + 1) % HunterAppearance.HAIR_STYLE_COUNT
	hunter.expedition_id = &"dark_forest"
	assert_false(_barber.can_restyle(hunter, other, hunter.appearance.hair_color).is_empty(), "away on an expedition")
	hunter.expedition_id = &""
	hunter.alive = false
	assert_false(_barber.can_restyle(hunter, other, hunter.appearance.hair_color).is_empty(), "fallen")
	hunter.alive = true
	assert_eq(_barber.can_restyle(hunter, other, hunter.appearance.hair_color), "")
	assert_eq(_wallet.gold, 1000, "asking costs nothing")
