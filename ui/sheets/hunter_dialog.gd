class_name HunterDialog
extends HunterSheet
## Hunter detail dialog (Evil Hunter Tycoon style): name, reincarnation stars and purse, a paper
## doll of the equipment around the portrait, rebirth points, and tabs Info / Skills & Traits /
## Gear / Life. Centered on the screen. Reuses the HunterSheet sections for the tab bodies.

enum Tab { INFO, SKILLS, BAG, LIFE }

## Translation keys of the tab titles (consts cannot call Loc.t; translated where shown).
const TAB_NAMES := ["ui.common.info", "ui.hunter.tab.skills", "ui.hunter.tab.bag", "ui.hunter.tab.life"]
const SLOT_SIZE := 44.0
const STAR_PINK := Color("ff7ad9")
const SOULS := Color("b79cff")

var _tab := Tab.INFO


func _build(content: VBoxContainer) -> void:
	var gm := GameManager
	var hunters := gm.hunters
	var definition := hunters.get_definition(runtime)
	set_title(runtime.display_name)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override(&"font_size", 18)
	# Reincarnation stars and purse.
	var stars := UIKit.hbox([], 2)
	for i in maxi(runtime.reincarnations, 1):
		var star := PixelIcons.rect(&"star", 2)
		star.modulate = STAR_PINK if runtime.reincarnations > 0 else Color(1, 1, 1, 0.2)
		stars.add_child(star)
	var star_box := UIKit.vbox([stars, UIKit.label(Loc.t("ui.hunter.reincarnation", {"count": runtime.reincarnations}), &"HudSmallLabel", false)], 0)
	var purse := UIKit.hbox([PixelIcons.rect(&"coin", 2), UIKit.label("%d" % runtime.purse, &"HudLabel", false)], 4)
	var purse_panel := PanelContainer.new()
	purse_panel.theme_type_variation = &"Chip"
	purse_panel.add_child(purse)
	purse_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	content.add_child(UIKit.hbox([star_box, purse_panel], 6))
	content.add_child(_paper_doll())
	var souls := UIKit.label(Loc.t("ui.hunter.rebirth_points", {"points": runtime.rebirth_points}), &"HudLabel", false)
	souls.add_theme_color_override(&"font_color", SOULS)
	souls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(souls)
	var tabs := UIKit.hbox([], 0)
	for i in TAB_NAMES.size():
		var tab_button := UIKit.button(Loc.t(TAB_NAMES[i]), func() -> void:
			_tab = i as Tab
			request_rebuild(), &"NavSelected" if _tab == i else &"NavButton")
		tab_button.custom_minimum_size = Vector2(0, GameTheme.TOUCH)
		tab_button.add_theme_font_size_override(&"font_size", 11)
		tab_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_button.clip_text = true
		tab_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		tabs.add_child(tab_button)
	content.add_child(tabs)
	var body := UIKit.vbox([], 6)
	var body_panel := PanelContainer.new()
	body_panel.theme_type_variation = &"HudBubble"
	body_panel.add_child(body)
	content.add_child(body_panel)
	match _tab:
		Tab.INFO:
			_build_info(body, definition)
		Tab.SKILLS:
			_build_skills(body)
		Tab.BAG:
			_build_bag(body)
		Tab.LIFE:
			# _build_needs_and_purse already adds the duty section.
			_build_needs_and_purse(body)
			_build_activity(body)
			_build_bonds_and_history(body)


## Paper doll (D59): the whole figure with its gear and pet in the middle; worn pieces on the
## left (helmet, top, pants, boots), weapon and jewelry on the right (weapon, necklace, ring,
## charm), skin and pet under the figure. Empty slots are dimmed and named. Tapping a slot opens
## the Gear tab.
func _paper_doll() -> Control:
	var gm := GameManager
	var figure := HunterFigure.new().setup(runtime, gm.equipment)
	figure.custom_minimum_size = Vector2(120, 150)
	var cosmetics := UIKit.hbox([_slot(&"skin"), _slot(&"pet")], 8)
	cosmetics.alignment = BoxContainer.ALIGNMENT_CENTER
	var middle := UIKit.vbox([figure, cosmetics], 4)
	middle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var left := UIKit.vbox([_slot(&"helmet"), _slot(&"armor"), _slot(&"pants"), _slot(&"boots")], 6)
	var right := UIKit.vbox([_slot(&"weapon"), _slot(&"necklace"), _slot(&"ring"), _slot(&"accessory")], 6)
	left.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	right.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var row := UIKit.hbox([left, middle, right], 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	# Puts on every stored piece that grades above the worn one (StatGradeService.suggest_gear, D80).
	var best := UIKit.button(Loc.t("ui.hunter.equip_best"), func() -> void:
		var picks: Dictionary = gm.grades.suggest_gear(runtime, gm.inventory, gm.equipment)
		var count := 0
		for slot: StringName in picks:
			if gm.equipment.equip(runtime, picks[slot]).is_empty():
				count += 1
		get_tree().call_group(&"ui_root", &"toast",
			Loc.t("ui.hunter.equip_best_done", {"count": count}) if count > 0 else Loc.t("ui.hunter.equip_best_none"), false), &"PrimaryButton")
	return UIKit.vbox([row, best], 6)


func _slot(slot: StringName) -> Control:
	var gm := GameManager
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"HunterCard"
	panel.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	var instance_id: StringName = runtime.equipment.get(slot, &"") if slot != &"" else &""
	var item := gm.equipment.get_item(instance_id) if instance_id != &"" else null
	# Tapping a worn item opens its details; an empty slot opens the picker (D66). Both are
	# modals over this dialog.
	panel.gui_input.connect(func(event: InputEvent) -> void:
		var is_tap: bool = (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
		if slot == &"" or not is_tap:
			return
		if item != null:
			get_tree().call_group(&"ui_root", &"open_item_info", item, instance_id)
		else:
			get_tree().call_group(&"ui_root", &"open_equip_picker", runtime, slot))
	if item == null:
		var empty_box := StyleBoxFlat.new()
		empty_box.bg_color = Color("10131d", 0.75)
		empty_box.border_color = Color("38415c", 0.6)
		empty_box.set_border_width_all(1)
		empty_box.set_corner_radius_all(5)
		panel.add_theme_stylebox_override(&"panel", empty_box)
		var hint := UIKit.label(EquipmentService.slot_label(slot), &"MutedLabel", false)
		hint.add_theme_font_size_override(&"font_size", GameTheme.SMALL_SIZE)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		panel.add_child(hint)
		return panel
	var enhance := gm.inventory.get_enhance(instance_id)
	var icon := ItemIcon.new().setup(item, 28, "+%d" % enhance if enhance > 0 else "", instance_id)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var name_label := UIKit.label(item.display_name, &"MutedLabel", false)
	name_label.add_theme_font_size_override(&"font_size", GameTheme.SMALL_SIZE)
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.custom_minimum_size.x = SLOT_SIZE - 6.0
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override(&"font_color", RarityColors.of(item.rarity))
	panel.tooltip_text = "%s · %s" % [item.display_name, UIKit.rarity_name(item)]
	var column := UIKit.vbox([icon, name_label], 1)
	panel.add_child(column)
	return panel


func _build_info(body: VBoxContainer, definition: HunterDefinition) -> void:
	var gm := GameManager
	var hunters := gm.hunters
	var grade := HuntersSheet.grade_of(runtime)
	var grade_name: String = "%s  %s" % [Tier.name_of(runtime.tier).to_upper(), grade[0]]
	var attack := hunters.get_stat(runtime, HunterService.ATTACK)
	var speed := hunters.get_stat(runtime, HunterService.ATTACK_SPEED)
	var crit := hunters.get_stat(runtime, HunterService.CRITICAL_CHANCE)
	var crit_damage := hunters.get_stat(runtime, HunterService.CRITICAL_DAMAGE)
	var dps := attack * speed * (1.0 + crit * (crit_damage - 1.0))
	var rank := UIKit.label(grade_name, &"HudLabel", false)
	rank.add_theme_color_override(&"font_color", grade[1])
	rank.add_theme_font_size_override(&"font_size", 17)
	var title := UIKit.vbox([rank, UIKit.label(Loc.t("ui.common.level_class", {"level": runtime.level, "class": definition.display_name}), &"HudLabel", false)], 0)
	var dps_box := UIKit.vbox([UIKit.label(Loc.t("ui.hunter.dps"), &"HudLabel", false), UIKit.label("%.1f" % dps, &"HudAccentLabel", false)], 0)
	dps_box.size_flags_horizontal = Control.SIZE_SHRINK_END
	body.add_child(UIKit.hbox([title, dps_box]))
	var max_hp := hunters.get_stat(runtime, HunterService.MAX_HP)
	var top: float = DataRegistry.config.needs_max
	var bars := UIKit.vbox([
		UIKit.bar(runtime.current_hp, max_hp, &"HpBar", Loc.t("ui.hunter.hp_short", {"current": roundi(runtime.current_hp), "max": roundi(max_hp)})),
		UIKit.bar(runtime.energy, top, &"EnergyBar", Loc.t("ui.hunter.satiety_short", {"current": roundi(runtime.energy), "max": roundi(top)})),
		UIKit.bar(runtime.mood, DataRegistry.config.mood_max, &"MoodBar", Loc.t("ui.hunter.mood_short", {"current": roundi(runtime.mood), "max": roundi(DataRegistry.config.mood_max)})),
		UIKit.bar(runtime.stamina, top, &"StaminaBar", Loc.t("ui.hunter.stamina_short", {"current": roundi(runtime.stamina), "max": roundi(top)})),
		UIKit.bar(runtime.xp, gm.stats.required_xp(runtime.level), &"XpBar", Loc.t("ui.hunter.xp_short", {"current": runtime.xp, "max": gm.stats.required_xp(runtime.level)})),
	], 4)
	var stats := UIKit.vbox([], 4)
	# Each value in the colour of its grade against the average Hunter of this level (D80).
	var grades := gm.grades
	for entry in [[Loc.t("stat.attack"), "%d" % roundi(attack), HunterService.ATTACK],
			[Loc.t("stat.defense"), "%d" % roundi(hunters.get_stat(runtime, HunterService.DEFENSE)), HunterService.DEFENSE],
			[Loc.t("ui.hunter.crit"), "%d%%" % roundi(crit * 100.0), HunterService.CRITICAL_CHANCE],
			[Loc.t("stat.attack_speed"), "%.2f" % speed, HunterService.ATTACK_SPEED],
			[Loc.t("stat.move_speed"), "%d" % roundi(hunters.get_stat(runtime, HunterService.MOVE_SPEED)), HunterService.MOVE_SPEED]]:
		var name_label := UIKit.label(entry[0], &"HudSmallLabel", false)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var value := UIKit.label(entry[1], &"HudAccentLabel", false)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value.add_theme_color_override(&"font_color", StatGradeService.color(grades.hunter_step(runtime, entry[2])))
		stats.add_child(UIKit.hbox([name_label, value], 4))
	var stat_grade := grades.hunter_grade(runtime)
	var grade_label := UIKit.label(Loc.t("ui.common.grade", {"grade": StatGradeService.name_of(stat_grade)}), &"HudSmallLabel", false)
	grade_label.add_theme_color_override(&"font_color", StatGradeService.color(stat_grade))
	stats.add_child(grade_label)
	bars.size_flags_stretch_ratio = 1.4
	body.add_child(UIKit.hbox([bars, stats], 10))
	body.add_child(UIKit.label(Loc.t("ui.hunter.awakening", {"count": runtime.reincarnations, "status": _status_text()}), &"HudSmallLabel"))
	var follow := UIKit.button(Loc.t("ui.hunter.follow"), func() -> void: follow_requested.emit(runtime.unique_id), &"",
		"" if runtime.expedition_id == &"" or GameManager.expeditions.is_running() else Loc.t("ui.hunter.not_on_map"))
	body.add_child(follow)


func _build_skills(body: VBoxContainer) -> void:
	_build_class_skills(body)
	body.add_child(UIKit.separator())
	body.add_child(UIKit.label(_talent_text(), &"HudSmallLabel"))
	body.add_child(UIKit.label(_skills_text(), &"HudSmallLabel"))
	_build_traits_and_mood(body)
	if GameManager.buildings.has_building(BuildingService.ACADEMY):
		body.add_child(UIKit.button(Loc.t("ui.hunter.open_academy"), func() -> void:
			open_requested.emit(BuildingSheet.new(BuildingService.ACADEMY)), &"PrimaryButton"))
	else:
		body.add_child(UIKit.label(Loc.t("ui.hunter.academy_hint"), &"MutedLabel"))


## The loot bag (D63): what the Hunter carries from the monsters it killed, what the Market pays
## for it, and selling it to the Market now (into the Warehouse, gold to the Hunter's purse).
func _build_bag(body: VBoxContainer) -> void:
	var gm := GameManager
	var regions: RegionService = gm.regions
	var capacity: int = DataRegistry.config.loot_bag_capacity
	var count := regions.get_bag_count(runtime)
	body.add_child(UIKit.bar(count, capacity, &"TimerBar", Loc.t("ui.hunter.bag.capacity", {"count": count, "max": capacity})))
	if runtime.loot_bag.is_empty():
		body.add_child(UIKit.label(Loc.t("ui.hunter.bag.empty"), &"MutedLabel"))
	var total := 0
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 4)
	grid.add_theme_constant_override(&"v_separation", 4)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for item_id: StringName in runtime.loot_bag:
		var item := DataRegistry.get_item(item_id)
		if item == null:
			continue
		var quantity: int = runtime.loot_bag[item_id]
		var price := regions.get_buy_price(item)
		total += price * quantity
		var name_label := UIKit.label(item.display_name, &"HudSmallLabel", false)
		name_label.clip_text = true
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_label.add_theme_color_override(&"font_color", RarityColors.of(item.rarity))
		var info := UIKit.vbox([name_label, UIKit.label(Loc.t("ui.hunter.bag.each", {"gold": price}), &"MutedLabel", false)], 0)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row := UIKit.hbox([ItemIcon.new().setup(item, 28, "×%d" % quantity), info], 4)
		grid.add_child(UIKit.card(row))
	body.add_child(grid)
	var has_market := gm.buildings.has_building(BuildingService.MARKET)
	var reason := ""
	if runtime.loot_bag.is_empty():
		reason = Loc.t("ui.hunter.bag.empty")
	elif not has_market:
		reason = Loc.t("err.market.missing")
	var sell := UIKit.button(Loc.t("ui.hunter.bag.sell", {"gold": total}), func() -> void:
		var report := regions.deposit(runtime)
		var stored := 0
		for quantity in report["items"].values():
			stored += quantity
		run_action("", Loc.t("ui.hunter.bag.sold", {"count": stored, "gold": report["village_gold"] + report["trader_gold"]})),
		&"PrimaryButton", reason)
	body.add_child(sell)
	body.add_child(UIKit.label(Loc.t("ui.hunter.bag.note") if has_market else Loc.t("err.market.missing"), &"MutedLabel"))


## Class skills (D70): mana, skill and swap points, the owned skills with their numbers, level up
## and swap buttons, and learning a random new skill.
func _build_class_skills(body: VBoxContainer) -> void:
	var skills: ClassSkillService = GameManager.class_skills
	var hunters := GameManager.hunters
	var config: GameConfig = DataRegistry.config
	skills.sync_points(runtime)
	body.add_child(UIKit.label(Loc.t("ui.class_skill.title"), &"AccentLabel"))
	var max_mana := hunters.get_stat(runtime, HunterService.MAX_MANA)
	var mana := minf(runtime.current_mana, max_mana) if runtime.current_mana > 0.0 else max_mana
	body.add_child(UIKit.bar(mana, max_mana, &"ManaBar", Loc.t("ui.class_skill.mana", {
		"current": roundi(mana), "max": roundi(max_mana), "regen": "%.1f" % hunters.get_stat(runtime, HunterService.MANA_REGEN)})))
	body.add_child(UIKit.label(Loc.t("ui.class_skill.points", {"points": runtime.skill_points, "swaps": runtime.skill_swap_points}), &"HudSmallLabel"))
	var every := maxi(config.class_skill_point_every, 1)
	var next_level := (runtime.level / every + 1) * every
	if next_level <= config.max_hunter_level:
		body.add_child(UIKit.label(Loc.t("ui.class_skill.next_point", {"level": next_level}), &"MutedLabel"))
	body.add_child(UIKit.label(Loc.t("ui.class_skill.slots", {"count": runtime.class_skills.size(), "max": config.class_skill_max_count}), &"MutedLabel"))
	var owned := skills.get_owned(runtime)
	if owned.is_empty():
		body.add_child(UIKit.label(Loc.t("ui.class_skill.none"), &"MutedLabel"))
	var tiles: Array = []
	for skill in owned:
		tiles.append(_class_skill_tile(skills, skill, config))
	if not tiles.is_empty():
		body.add_child(SkillTile.grid(tiles))
		body.add_child(UIKit.label(Loc.t("ui.skill.tap_hint"), &"MutedLabel"))
	var reason := skills.can_unlock(runtime)
	body.add_child(UIKit.button(Loc.t("ui.class_skill.unlock"), func() -> void:
		var learned := skills.unlock_random(runtime)
		run_action("" if learned != null else skills.can_unlock(runtime),
			Loc.t("ui.class_skill.learned", {"name": learned.display_name}) if learned != null else ""),
		&"PrimaryButton", reason))


## Tile of an owned class skill; its details dialog carries the numbers and the upgrade / swap buttons.
func _class_skill_tile(skills: ClassSkillService, skill: ClassSkillDefinition, config: GameConfig) -> Control:
	var level := skills.get_level(runtime, skill.id)
	var actions: Array = [{
		"text": Loc.t("ui.class_skill.upgrade"),
		"reason": skills.can_upgrade(runtime, skill.id),
		"action": func() -> void:
			var done := skills.upgrade(runtime, skill.id)
			run_action("" if done else skills.can_upgrade(runtime, skill.id),
				Loc.t("ui.class_skill.upgraded", {"name": skill.display_name, "level": skills.get_level(runtime, skill.id)})),
	}]
	if runtime.skill_swap_points > 0:
		actions.append({
			"text": Loc.t("ui.class_skill.swap"),
			"reason": skills.can_swap(runtime, skill.id),
			"action": func() -> void:
				var swapped := skills.swap(runtime, skill.id)
				run_action("" if swapped != null else skills.can_swap(runtime, skill.id),
					Loc.t("ui.class_skill.swapped", {"name": swapped.display_name}) if swapped != null else ""),
		})
	var options := {"level": level, "max_level": config.class_skill_max_level, "lines": [skills.describe(skill, level)], "actions": actions}
	return SkillTile.new().setup(skill, options, "Lv%d" % level)
