class_name ColosseumSheet
extends Sheet
## Colosseum (ARENA_SYSTEM.md, phase 1): pick a fighter, then a rival (weaker / even / stronger
## than it) or one of your own Hunters for a friendly match. Starts the replay view.

## The player chose a fight: the replay opens over the screen (UIRoot).
signal match_requested(first: HunterRuntime, second: HunterRuntime, result: ArenaResult)

var _fighter_id: StringName
var _partner_id: StringName


func _init() -> void:
	title = Loc.t("ui.arena.title")


func _watch() -> Array:
	var gm := GameManager
	return [[gm.hunters, &"hunter_changed"], [gm.arena, &"match_finished"]]


func _build(content: VBoxContainer) -> void:
	var gm := GameManager
	var arena := gm.arena
	set_title(Loc.t("ui.arena.title"))
	content.add_child(UIKit.label(Loc.t("ui.arena.safe_note"), &"MutedLabel"))
	var eligible := arena.get_eligible()
	if eligible.is_empty():
		content.add_child(UIKit.label(Loc.t("ui.arena.no_fighters"), &"WarningLabel"))
		for hunter in gm.hunters.get_active():
			var reason := arena.can_enter(hunter)
			if not reason.is_empty():
				content.add_child(UIKit.label("%s — %s" % [hunter.display_name, reason], &"MutedLabel"))
		return
	var fighter := gm.hunters.get_hunter(_fighter_id)
	if fighter == null or not eligible.has(fighter):
		fighter = eligible[0]
		_fighter_id = fighter.unique_id
	content.add_child(UIKit.label(Loc.t("ui.arena.your_fighter"), &"AccentLabel"))
	content.add_child(_picker(eligible, fighter, func(hunter: HunterRuntime) -> void:
		_fighter_id = hunter.unique_id
		request_rebuild()))
	content.add_child(UIKit.label(_fighter_line(fighter), &"MutedLabel"))
	if arena.board_owner != fighter.unique_id or arena.board.is_empty():
		arena.refresh_board(fighter)
	content.add_child(UIKit.hbox([UIKit.label(Loc.t("ui.arena.rivals"), &"AccentLabel"),
		UIKit.button(Loc.t("ui.arena.refresh"), func() -> void:
			arena.refresh_board(fighter)
			request_rebuild(), &"Button")], 6))
	var tiers := ["ui.arena.rival_weaker", "ui.arena.rival_even", "ui.arena.rival_stronger"]
	for i in arena.board.size():
		var rival := arena.board[i]
		var definition := gm.hunters.get_definition(rival)
		var info := UIKit.label(Loc.t("ui.arena.rival_line", {"name": rival.display_name, "level": rival.level,
			"class": definition.display_name, "tier": Loc.t(tiers[i]), "power": roundi(arena.get_power(rival))}), &"")
		var fight := UIKit.button(Loc.t("ui.arena.fight"), func() -> void: _start(fighter, rival), &"PrimaryButton")
		fight.custom_minimum_size.x = 72
		fight.size_flags_horizontal = Control.SIZE_SHRINK_END
		content.add_child(UIKit.card(UIKit.hbox([HunterPortrait.new().setup(rival, null), info, fight], 8)))
	content.add_child(UIKit.separator())
	content.add_child(UIKit.label(Loc.t("ui.arena.friendly"), &"AccentLabel"))
	var partners := gm.hunters.get_active().filter(func(h: HunterRuntime) -> bool: return h != fighter and arena.can_enter(h).is_empty())
	if partners.is_empty():
		content.add_child(UIKit.label(Loc.t("ui.arena.no_partner"), &"MutedLabel"))
		return
	content.add_child(UIKit.label(Loc.t("ui.arena.friendly_hint"), &"MutedLabel"))
	var partner := gm.hunters.get_hunter(_partner_id)
	if partner == null or not partners.has(partner):
		partner = partners[0]
		_partner_id = partner.unique_id
	var typed: Array[HunterRuntime] = []
	typed.assign(partners)
	content.add_child(_picker(typed, partner, func(hunter: HunterRuntime) -> void:
		_partner_id = hunter.unique_id
		request_rebuild()))
	content.add_child(UIKit.button(Loc.t("ui.arena.fight"), func() -> void: _start(fighter, partner), &"PrimaryButton"))


func _fighter_line(hunter: HunterRuntime) -> String:
	var gm := GameManager
	return Loc.t("ui.arena.fighter_line", {"name": hunter.display_name, "level": hunter.level,
		"class": gm.hunters.get_definition(hunter).display_name, "power": roundi(gm.arena.get_power(hunter))})


func _picker(options: Array[HunterRuntime], chosen: HunterRuntime, on_pick: Callable) -> OptionButton:
	var picker := OptionButton.new()
	picker.custom_minimum_size.y = GameTheme.TOUCH
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in options.size():
		picker.add_item("%s · Lv %d" % [options[i].display_name, options[i].level])
		if options[i] == chosen:
			picker.select(i)
	picker.item_selected.connect(func(index: int) -> void: on_pick.call(options[index]))
	return picker


func _start(first: HunterRuntime, second: HunterRuntime) -> void:
	var reason := GameManager.arena.can_enter(first)
	if not reason.is_empty():
		toast_requested.emit(reason, true)
		return
	match_requested.emit(first, second, GameManager.arena.simulate(first, second))
