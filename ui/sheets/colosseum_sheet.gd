class_name ColosseumSheet
extends Sheet
## Colosseum (ARENA_SYSTEM.md): 1vs1, 4vs4, 6vs6 team relay combat, daily arena tickets,
## and Token Shop for exclusive progression rewards.

signal match_requested(first: HunterRuntime, second: HunterRuntime, result: ArenaResult)

enum Tab { ONE_VS_ONE, FOUR_VS_FOUR, SIX_VS_SIX, SHOP }

var _current_tab: int = Tab.ONE_VS_ONE
var _fighter_id: StringName
var _partner_id: StringName


func _init() -> void:
	title = Loc.t("ui.arena.title")


func _watch() -> Array:
	var gm := GameManager
	return [
		[gm.hunters, &"hunter_changed"],
		[gm.arena, &"match_finished"],
		[gm.arena, &"tickets_refreshed"],
		[gm.wallet, &"tokens_changed"],
		[gm.wallet, &"gold_changed"],
	]


func _build(content: VBoxContainer) -> void:
	var gm := GameManager
	var arena := gm.arena
	set_title(Loc.t("ui.arena.title"))

	# Header status bar: Tickets and Tokens
	var ticket_label := UIKit.label(Loc.t("ui.arena.tickets", {"count": arena.daily_tickets}), &"AccentLabel")
	var token_label := UIKit.label(Loc.t("ui.arena.tokens", {"count": gm.wallet.arena_tokens}), &"AccentLabel")
	var refill_btn := UIKit.button(Loc.t("ui.arena.refill_btn"), func() -> void:
		if arena.daily_tickets >= ArenaService.MAX_DAILY_TICKETS:
			return
		if not arena.refill_tickets():
			toast_requested.emit(Loc.t("err.gold.insufficient"), true)
		else:
			request_rebuild()
	, &"Button")
	refill_btn.custom_minimum_size.x = 88
	content.add_child(UIKit.card(UIKit.hbox([ticket_label, refill_btn, UIKit.spacer(), token_label], 8)))

	# Tab bar
	var tab_bar := UIKit.hbox([
		UIKit.button(Loc.t("ui.arena.tab_1v1"), func() -> void: _switch_tab(Tab.ONE_VS_ONE), _tab_style(Tab.ONE_VS_ONE)),
		UIKit.button(Loc.t("ui.arena.tab_4v4"), func() -> void: _switch_tab(Tab.FOUR_VS_FOUR), _tab_style(Tab.FOUR_VS_FOUR)),
		UIKit.button(Loc.t("ui.arena.tab_6v6"), func() -> void: _switch_tab(Tab.SIX_VS_SIX), _tab_style(Tab.SIX_VS_SIX)),
		UIKit.button(Loc.t("ui.arena.tab_shop"), func() -> void: _switch_tab(Tab.SHOP), _tab_style(Tab.SHOP)),
	], 4)
	content.add_child(tab_bar)
	content.add_child(UIKit.separator())

	match _current_tab:
		Tab.ONE_VS_ONE:
			_build_1v1(content)
		Tab.FOUR_VS_FOUR:
			_build_team(content, 4)
		Tab.SIX_VS_SIX:
			_build_team(content, 6)
		Tab.SHOP:
			_build_shop(content)


func _tab_style(tab: int) -> StringName:
	return &"PrimaryButton" if _current_tab == tab else &"Button"


func _switch_tab(tab: int) -> void:
	_current_tab = tab
	request_rebuild()


func _build_1v1(content: VBoxContainer) -> void:
	var gm := GameManager
	var arena := gm.arena
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
		var fight := UIKit.button(Loc.t("ui.arena.fight"), func() -> void: _start_1v1(fighter, rival), &"PrimaryButton")
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
	content.add_child(UIKit.button(Loc.t("ui.arena.fight"), func() -> void: _start_1v1(fighter, partner), &"PrimaryButton"))


func _build_team(content: VBoxContainer, count: int) -> void:
	var gm := GameManager
	var arena := gm.arena
	content.add_child(UIKit.label(Loc.t("ui.arena.safe_note"), &"MutedLabel"))
	var eligible := arena.get_eligible()
	if eligible.size() < count:
		content.add_child(UIKit.label(Loc.t("ui.arena.squad_need_more", {"count": count}), &"WarningLabel"))
		return

	var squad: Array[HunterRuntime] = []
	for i in count:
		squad.append(eligible[i])

	var total_power := 0.0
	for h in squad:
		total_power += arena.get_power(h)

	var avg_power := total_power / float(count)
	content.add_child(UIKit.label(Loc.t("ui.arena.squad_power", {"power": roundi(total_power)}), &"AccentLabel"))

	var squad_box := UIKit.vbox([], 4)
	for h in squad:
		squad_box.add_child(UIKit.label("• %s (Lv %d %s) — HP: %d" % [
			h.display_name, h.level, gm.hunters.get_definition(h).display_name,
			roundi(gm.hunters.get_stat(h, HunterService.MAX_HP))
		], &"MutedLabel"))
	content.add_child(UIKit.card(squad_box))

	var rival_team := arena.make_rival_team(avg_power, count)
	var rival_power := 0.0
	for r in rival_team:
		rival_power += arena.get_power(r)

	var rival_card := UIKit.vbox([
		UIKit.label(Loc.t("ui.arena.rival_squad"), &"AccentLabel"),
		UIKit.label(Loc.t("ui.arena.squad_power", {"power": roundi(rival_power)}), &"MutedLabel"),
		UIKit.button(Loc.t("ui.arena.fight"), func() -> void: _start_team(squad, rival_team, count), &"PrimaryButton")
	], 6)
	content.add_child(UIKit.card(rival_card))


func _build_shop(content: VBoxContainer) -> void:
	var gm := GameManager
	var arena := gm.arena
	for item_key: StringName in ArenaService.TOKEN_SHOP:
		var item: Dictionary = ArenaService.TOKEN_SHOP[item_key]
		var item_title := Loc.t(item["name_key"])
		var cost: int = item["cost"]
		var cost_text := Loc.t("ui.arena.buy_item", {"cost": cost})
		var buy_btn := UIKit.button(cost_text, func() -> void:
			if arena.buy_token_shop_item(item_key):
				toast_requested.emit(Loc.t("ui.arena.bought_success"), false)
				request_rebuild()
			else:
				toast_requested.emit(Loc.t("ui.arena.bought_failed"), true)
		, &"PrimaryButton")
		buy_btn.custom_minimum_size.x = 100
		buy_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
		var card := UIKit.hbox([
			UIKit.vbox([UIKit.label(item_title, &"AccentLabel"), UIKit.label("x%d" % item["amount"], &"MutedLabel")], 2),
			UIKit.spacer(),
			buy_btn
		], 8)
		content.add_child(UIKit.card(card))


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


func _start_1v1(first: HunterRuntime, second: HunterRuntime) -> void:
	var gm := GameManager
	var reason := gm.arena.can_enter(first)
	if not reason.is_empty():
		toast_requested.emit(reason, true)
		return
	if not gm.arena.can_fight():
		toast_requested.emit(Loc.t("ui.arena.no_tickets"), true)
		return
	gm.arena.spend_ticket()
	var result := gm.arena.simulate(first, second)
	gm.arena.apply_result(first, result, 0)
	match_requested.emit(first, second, result)


func _start_team(team_a: Array[HunterRuntime], team_b: Array[HunterRuntime], count: int) -> void:
	var gm := GameManager
	if not gm.arena.can_fight():
		toast_requested.emit(Loc.t("ui.arena.no_tickets"), true)
		return
	gm.arena.spend_ticket()
	var result := gm.arena.simulate_team(team_a, team_b)
	var format := ArenaService.Format.FOUR_VS_FOUR if count == 4 else ArenaService.Format.SIX_VS_SIX
	gm.arena.apply_team_result(team_a, result, format)
	match_requested.emit(team_a[0], team_b[0], result)
