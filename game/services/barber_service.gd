class_name BarberService
extends RefCounted
## Barber (D77, like the reference game's beauty salon): a Hunter in town changes its hair style and hair
## colour (HunterAppearance) for `GameConfig.restyle_cost` gold. The look has no gameplay effect; it is
## saved with the Hunter.

signal restyled(hunter: HunterRuntime)
signal autosave_requested(reason: StringName)

var _hunters: HunterService
var _wallet: WalletService
var _config: GameConfig


func _init(hunters: HunterService, wallet: WalletService, config: GameConfig) -> void:
	_hunters = hunters
	_wallet = wallet
	_config = config


func get_cost() -> int:
	return _config.restyle_cost


## Why `hunter` cannot take this hair style and colour now ("" = it can).
func can_restyle(hunter: HunterRuntime, hair_style: int, hair_color: int) -> String:
	if not hunter.alive:
		return Loc.t("err.barber.dead", {"name": hunter.display_name})
	if hunter.expedition_id != &"":
		return Loc.t("err.barber.away", {"name": hunter.display_name})
	var look := hunter.appearance
	if posmod(hair_style, HunterAppearance.HAIR_STYLE_COUNT) == look.hair_style \
			and posmod(hair_color, HunterAppearance.HAIR_COLOR_COUNT) == look.hair_color:
		return Loc.t("err.barber.same")
	if _wallet.gold < get_cost():
		return Loc.t("ui.common.needs_gold", {"gold": get_cost()})
	return ""


## Pays and changes the look; returns an error ("" = done).
func restyle(hunter: HunterRuntime, hair_style: int, hair_color: int) -> String:
	var reason := can_restyle(hunter, hair_style, hair_color)
	if not reason.is_empty():
		return reason
	if not _wallet.spend(get_cost()):
		return Loc.t("ui.common.needs_gold", {"gold": get_cost()})
	hunter.appearance.hair_style = posmod(hair_style, HunterAppearance.HAIR_STYLE_COUNT)
	hunter.appearance.hair_color = posmod(hair_color, HunterAppearance.HAIR_COLOR_COUNT)
	_hunters.notify_changed(hunter)
	restyled.emit(hunter)
	autosave_requested.emit(&"barber")
	return ""
