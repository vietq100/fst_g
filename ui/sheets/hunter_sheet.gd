class_name HunterSheet
extends Sheet
## Hunter panel (UI_DESIGN.md → Hunter panel): portrait, name, class, level, HP, XP, equipment,
## needs, purse, traits, mood, activity, bonds, history. Actions go through the services.

## Camera follows this Hunter (D28); UIRoot forwards it to the world.
signal follow_requested(unique_id: StringName)

## Gold moved per Give tap (treasury → purse).
const GIVE_STEP := 50
## Barber preview figure size (D77).
const LOOK_PREVIEW := Vector2(56, 80)

var runtime: HunterRuntime
var _timer: Timer
## Hair style and colour picked at the barber, shown before paying (-1 = the Hunter's own).
var _style := -1
var _color := -1


func _init(hunter: HunterRuntime) -> void:
	runtime = hunter


func _ready() -> void:
	super()
	# Mood, HP and timers change while the panel is open.
	_timer = Timer.new()
	_timer.wait_time = 1.0
	_timer.autostart = true
	_timer.timeout.connect(request_rebuild)
	add_child(_timer)


func _watch() -> Array:
	var gm := GameManager
	return [[gm.hunters, &"hunter_changed"], [gm.equipment, &"equipment_changed"], [gm.activities, &"activity_changed"],
		[gm.inventory, &"inventory_changed"], [gm.bonds, &"bond_changed"], [gm.purses, &"purse_changed"],
		[gm.wallet, &"gold_changed"], [gm.regions, &"loot_bag_changed"],
		[gm.corpses, &"carrier_assigned"], [gm.corpses, &"staff_dispatched"], [gm.corpses, &"body_picked_up"],
		[gm.corpses, &"body_delivered"], [gm.class_skills, &"skills_changed"]]


func _build(content: VBoxContainer) -> void:
	var gm := GameManager
	var hunters := gm.hunters
	var definition := hunters.get_definition(runtime)
	set_title(runtime.display_name)
	var max_hp := hunters.get_stat(runtime, HunterService.MAX_HP)
	var required := gm.stats.required_xp(runtime.level)
	var cap := gm.stats.level_cap(gm.progress.town_level)
	var header := UIKit.vbox([
		UIKit.label(_header_text(definition.display_name, cap)),
		UIKit.bar(runtime.current_hp, max_hp, &"HpBar", Loc.t("ui.hunter.hp_bar", {"current": roundi(runtime.current_hp), "max": roundi(max_hp)})),
		UIKit.bar(runtime.xp, required, &"XpBar", Loc.t("ui.hunter.xp_bar", {"current": runtime.xp, "max": required})),
		UIKit.label(Loc.t("ui.hunter.stats_line", {
			"atk": "%.1f" % hunters.get_stat(runtime, HunterService.ATTACK), "def": "%.1f" % hunters.get_stat(runtime, HunterService.DEFENSE),
			"spd": roundi(hunters.get_stat(runtime, HunterService.MOVE_SPEED)), "crit": roundi(hunters.get_stat(runtime, HunterService.CRITICAL_CHANCE) * 100.0)}),
			&"MutedLabel"),
		UIKit.label(_status_text(), &"AccentLabel"),
		UIKit.label(_talent_text(), &"MutedLabel"),
		UIKit.label(_skills_text(), &"MutedLabel"),
		UIKit.hbox([
			UIKit.label(Loc.t("ui.hunter.title_label", {"title": _title_text()}), &"AccentLabel"),
			UIKit.button(Loc.t("ui.hunter.title_cycle"), _cycle_title, &"SmallButton") if runtime.unlocked_titles.size() > 1 else Control.new()
		], 6),
	], 3)
	var portrait := HunterPortrait.new().setup(runtime, gm.equipment)
	portrait.custom_minimum_size = Vector2(64, 64)
	content.add_child(UIKit.hbox([portrait, header], 8))
	content.add_child(UIKit.button(Loc.t("ui.hunter.follow"), func() -> void: follow_requested.emit(runtime.unique_id), &"Button",
		"" if runtime.expedition_id == &"" or GameManager.expeditions.is_running() else Loc.t("ui.hunter.not_on_map")))
	_build_needs_and_purse(content)
	_build_equipment(content)
	_build_look(content)
	_build_traits_and_mood(content)
	_build_activity(content)
	_build_bonds_and_history(content)


## "Warrior · Lv 5 (cap) · reborn 2×": class, level, level-cap mark and rebirth count.
func _header_text(class_name_text: String, cap: int) -> String:
	var key := "ui.hunter.header_cap" if runtime.level >= cap else "ui.hunter.header"
	var text := Loc.t(key, {"class": class_name_text, "level": runtime.level})
	if runtime.reincarnations > 0:
		text = Loc.t("ui.hunter.header_reborn", {"header": text, "count": runtime.reincarnations})
	return text


## Name of an activity id: its definition's name, else a key per id (sleeping, eating); "" for none.
static func activity_label(activity_id: StringName) -> String:
	var definition := GameManager.activities.get_definition(activity_id)
	if definition != null:
		return definition.display_name
	if activity_id == &"":
		return ""
	var key := "ui.hunter.activity.%s" % activity_id
	if Loc.has_key(key):
		return Loc.t(key)
	var task_key := "ui.hunter.task.%s" % activity_id
	return Loc.t(task_key) if Loc.has_key(task_key) else ""


func _title_text() -> String:
	if runtime.equipped_title == &"":
		return Loc.t("ui.hunter.title_none")
	var key := "hunter.title.%s" % runtime.equipped_title
	return Loc.t(key) if Loc.has_key(key) else String(runtime.equipped_title).capitalize()


func _cycle_title() -> void:
	if runtime.unlocked_titles.is_empty():
		return
	var idx := runtime.unlocked_titles.find(runtime.equipped_title)
	var next_idx := (idx + 1) % runtime.unlocked_titles.size()
	GameManager.hunters.equip_title(runtime, runtime.unlocked_titles[next_idx])
	request_rebuild()


func _skills_text() -> String:
	var parts := PackedStringArray()
	for skill_id in runtime.skills:
		var skill := GameManager.academy.get_skill(skill_id)
		if skill != null and runtime.skills[skill_id] > 0:
			parts.append("%s %d" % [skill.display_name, runtime.skills[skill_id]])
	if runtime.rebirth_points > 0:
		parts.append(Loc.t("ui.hunter.rebirth_pt", {"points": runtime.rebirth_points}))
	return Loc.t("ui.hunter.skills", {"skills": ", ".join(parts) if not parts.is_empty() else Loc.t("ui.hunter.skills_none")})


func _talent_text() -> String:
	var talent := GameManager.talents.get_talent(runtime)
	if talent == null:
		return Loc.t("ui.hunter.no_talent")
	return Loc.t("ui.hunter.talent", {"name": talent.display_name, "desc": talent.description})


func _status_text() -> String:
	var corpses: CorpseService = GameManager.corpses
	if corpses.is_body(runtime):
		if not corpses.has_carrier(runtime):
			return Loc.t("ui.hunter.status.fallen_waiting")
		var carrier := corpses.get_carrier(runtime)
		var who := carrier.display_name if carrier != null else Loc.t("ui.hunter.status.village_staff")
		var key := "ui.hunter.status.fallen_carrying" if corpses.is_carried(runtime) else "ui.hunter.status.fallen_on_way"
		return Loc.t(key, {"who": who})
	if not runtime.alive and runtime.injured:
		return Loc.t("ui.hunter.status.fallen_reviving", {"time": UIKit.format_duration(GameManager.temple.get_remaining(runtime))})
	var body := corpses.get_body_of(runtime)
	if body != null:
		var body_key := "ui.hunter.status.carrying" if corpses.is_carried(body) else "ui.hunter.status.fetching"
		return Loc.t(body_key, {"name": body.display_name})
	if runtime.injured:
		return Loc.t("ui.hunter.status.injured", {"time": UIKit.format_duration(GameManager.temple.get_remaining(runtime))})
	if runtime.expedition_id != &"":
		return Loc.t("ui.hunter.status.on_expedition")
	if runtime.task == HunterRuntime.HUNTING:
		var region := GameManager.world.region_at(runtime.world_position)
		if region != null and not region.is_town:
			return Loc.t("ui.hunter.status.hunting_in", {"region": region.display_name})
		return Loc.t("ui.hunter.status.hunting")
	if runtime.task != &"":
		return Loc.t("ui.hunter.task.%s" % runtime.task)
	return Loc.t("ui.hunter.status.in_town")


## Stamina / energy (D31) and the purse with treasury transfers (D34, 10% fee).
func _build_needs_and_purse(content: VBoxContainer) -> void:
	var gm := GameManager
	var top: float = DataRegistry.config.needs_max
	var stamina_key := "ui.hunter.stamina_exhausted" if gm.needs.is_exhausted(runtime) else "ui.hunter.stamina"
	var stamina_text := Loc.t(stamina_key, {"value": roundi(runtime.stamina)})
	var energy_key := "ui.hunter.energy"
	if gm.needs.is_starving(runtime):
		energy_key = "ui.hunter.energy_starving"
	elif gm.needs.is_hungry(runtime):
		energy_key = "ui.hunter.energy_hungry"
	var energy_text := Loc.t(energy_key, {"value": roundi(runtime.energy)})
	var food_problem := gm.supply.food_reason(runtime) if gm.needs.is_hungry(runtime) else ""
	if not food_problem.is_empty():
		energy_text = Loc.t("ui.hunter.energy_reason", {"text": energy_text, "reason": food_problem.to_lower()})
	# Stacked: the texts get long (hungry / no food reasons, Vietnamese).
	content.add_child(UIKit.vbox([
		UIKit.bar(runtime.stamina, top, &"StaminaBar", stamina_text),
		UIKit.bar(runtime.energy, top, &"EnergyBar", energy_text),
	], 4))
	var purses := gm.purses
	var take_amount := runtime.purse
	var give := UIKit.button(Loc.t("ui.hunter.give", {"amount": GIVE_STEP, "received": purses.get_received(GIVE_STEP)}), func() -> void:
		run_action(purses.give(runtime, GIVE_STEP), Loc.t("ui.hunter.gave", {"gold": purses.get_received(GIVE_STEP), "name": runtime.display_name})),
		&"Button", purses.can_give(runtime, GIVE_STEP))
	var take := UIKit.button(Loc.t("ui.hunter.take_all", {"received": purses.get_received(take_amount)}), func() -> void:
		run_action(purses.take(runtime, take_amount), Loc.t("ui.hunter.treasury_gain", {"gold": purses.get_received(take_amount)})),
		&"Button", purses.can_take(runtime, take_amount))
	for button: Button in [give, take]:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.x = 0
	# Text on top, the two buttons sharing the row under it (fits a phone width).
	var purse := UIKit.vbox([
		UIKit.label(Loc.t("ui.hunter.purse", {"gold": runtime.purse})),
		UIKit.label(Loc.t("ui.hunter.purse_note", {"fee": roundi(DataRegistry.config.transfer_fee * 100.0)}), &"MutedLabel"),
		UIKit.hbox([give, take], 4),
	], 4)
	content.add_child(UIKit.card(purse))
	_build_duty(content)


## Duty (D29): Auto, a fixed region or Stay in town; plus the loot bag.
func _build_duty(content: VBoxContainer) -> void:
	var regions: RegionService = GameManager.regions
	var target := regions.get_duty_region(runtime)
	var duty_text := Loc.t("ui.hunter.duty", {"duty": regions.get_duty_name(runtime.duty)})
	if runtime.duty == &"" and target != null:
		duty_text = Loc.t("ui.hunter.duty_target", {"duty": regions.get_duty_name(runtime.duty), "region": target.display_name})
	content.add_child(UIKit.label(duty_text, &"AccentLabel"))
	# Three per row: six choices never fit side by side on a phone.
	var row := _button_grid(3)
	for duty in regions.get_duty_options():
		var region := GameManager.world.get_region(duty)
		var text := regions.get_duty_name(duty)
		if region != null:
			text = Loc.t("ui.hunter.duty_button", {"name": Loc.t("ui.hunter.duty_short.%s" % duty), "level": region.min_hunter_level})
		elif duty == HunterRuntime.STAY_IN_TOWN:
			text = Loc.t("ui.hunter.duty_stay")
		var button := UIKit.button(text, func() -> void: run_action(regions.set_duty(runtime, duty)),
			&"PrimaryButton" if runtime.duty == duty else &"Button")
		_fit_button(button)
		row.add_child(button)
	content.add_child(row)
	var bag := PackedStringArray()
	for item_id in runtime.loot_bag:
		bag.append("%d %s" % [runtime.loot_bag[item_id], DataRegistry.get_item(item_id).display_name])
	var bag_args := {"count": regions.get_bag_count(runtime), "max": DataRegistry.config.loot_bag_capacity, "items": ", ".join(bag)}
	content.add_child(UIKit.label(Loc.t("ui.hunter.loot_bag" if bag.is_empty() else "ui.hunter.loot_bag_items", bag_args), &"MutedLabel"))


func _build_equipment(content: VBoxContainer) -> void:
	var equipment := GameManager.equipment
	content.add_child(UIKit.label(Loc.t("ui.hunter.equipment"), &"AccentLabel"))
	for slot in EquipmentService.SLOT_ORDER:
		var item := equipment.get_equipped_item(runtime, slot)
		var text := "%s: %s" % [EquipmentService.slot_label(slot), "—" if item == null else "%s (%s)" % [item.display_name, UIKit.describe_modifiers(item)]]
		var label := UIKit.label(text)
		if item != null:
			label.add_theme_color_override(&"font_color", RarityColors.of(item.rarity))
		var unequip := UIKit.button(Loc.t("ui.common.remove"), func() -> void:
			run_action(equipment.unequip(runtime, slot)), &"DangerButton" if item != null else &"Button", "" if item != null else Loc.t("ui.hunter.nothing_equipped"))
		unequip.size_flags_horizontal = Control.SIZE_SHRINK_END
		unequip.custom_minimum_size = Vector2(72, GameTheme.TOUCH)
		content.add_child(UIKit.hbox([label, unequip]))
	# Stored items that fit: one button each.
	var options := 0
	for instance_id in GameManager.inventory.get_instances():
		var item := equipment.get_item(instance_id)
		if item == null or not EquipmentService.SLOT_NAMES.has(item.equipment_slot):
			continue
		options += 1
		var slot_name: String = EquipmentService.slot_label(EquipmentService.SLOT_NAMES[item.equipment_slot])
		var button := UIKit.button(Loc.t("ui.hunter.equip_option", {"slot": slot_name, "item": item.display_name, "mods": UIKit.describe_modifiers(item)}), func() -> void:
			run_action(equipment.equip(runtime, instance_id), Loc.t("ui.hunter.equipped", {"item": item.display_name})))
		button.add_theme_color_override(&"font_color", RarityColors.of(item.rarity))
		button.clip_text = true
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		content.add_child(button)
	if options == 0:
		content.add_child(UIKit.label(Loc.t("ui.hunter.no_spare"), &"MutedLabel"))


## Barber (D77): browse hair styles and colours on a preview, then pay to keep them.
func _build_look(content: VBoxContainer) -> void:
	var barber := GameManager.barber
	if _style < 0:
		_style = runtime.appearance.hair_style
		_color = runtime.appearance.hair_color
	content.add_child(UIKit.label(Loc.t("ui.hunter.look"), &"AccentLabel"))
	var look := HunterAppearance.from_dict(runtime.appearance.to_dict())
	look.hair_style = _style
	look.hair_color = _color
	var preview := HunterFigure.new().setup(runtime, GameManager.equipment, look)
	preview.custom_minimum_size = LOOK_PREVIEW
	var pickers := UIKit.vbox([
		_stepper(Loc.t("ui.hunter.hair_style", {"index": _style + 1, "total": HunterAppearance.HAIR_STYLE_COUNT}), func(step: int) -> void:
			_style = posmod(_style + step, HunterAppearance.HAIR_STYLE_COUNT)),
		_stepper(Loc.t("ui.hunter.hair_color", {"index": _color + 1, "total": HunterAppearance.HAIR_COLOR_COUNT}), func(step: int) -> void:
			_color = posmod(_color + step, HunterAppearance.HAIR_COLOR_COUNT)),
	], 4)
	pickers.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var reason := barber.can_restyle(runtime, _style, _color)
	var pay := UIKit.button(Loc.t("ui.hunter.restyle", {"gold": barber.get_cost()}), func() -> void:
		run_action(barber.restyle(runtime, _style, _color), Loc.t("ui.hunter.restyled", {"name": runtime.display_name})),
		&"PrimaryButton", reason)
	pickers.add_child(pay)
	content.add_child(UIKit.hbox([preview, pickers], 8))


## "< label >" row; `change(step)` moves the choice by −1 / +1, then the sheet redraws.
func _stepper(text: String, change: Callable) -> HBoxContainer:
	var back := UIKit.button(Loc.t("ui.common.previous"), func() -> void:
		change.call(-1)
		request_rebuild(), &"Button")
	var forward := UIKit.button(Loc.t("ui.common.next"), func() -> void:
		change.call(1)
		request_rebuild(), &"Button")
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	forward.size_flags_horizontal = Control.SIZE_SHRINK_END
	var label := UIKit.label(text)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return UIKit.hbox([back, label, forward], 4)


func _build_traits_and_mood(content: VBoxContainer) -> void:
	var gm := GameManager
	content.add_child(UIKit.label(Loc.t("ui.hunter.personality"), &"AccentLabel"))
	for definition in gm.traits.get_traits(runtime):
		content.add_child(UIKit.label("%s — %s" % [definition.display_name, definition.description], &"MutedLabel"))
	var mood_key := "ui.hunter.mood_bar"
	match gm.mood.get_state(runtime):
		MoodService.State.HIGH:
			mood_key = "ui.hunter.mood_bar_high"
		MoodService.State.LOW:
			mood_key = "ui.hunter.mood_bar_low"
	content.add_child(UIKit.bar(runtime.mood, DataRegistry.config.mood_max, &"MoodBar", Loc.t(mood_key, {
		"mood": roundi(runtime.mood), "state": mood_state_name(gm.mood.get_state(runtime))})))


## "Low" / "Normal" / "High" for a MoodService.State.
static func mood_state_name(state: int) -> String:
	return Loc.t("ui.hunter.mood_state.%s" % String(MoodService.State.keys()[state]).to_lower())


func _build_activity(content: VBoxContainer) -> void:
	if runtime.injured or not runtime.alive or runtime.expedition_id != &"":
		return
	var activities := GameManager.activities
	var doing_key := "ui.hunter.doing_auto" if runtime.assigned_activity == &"" else "ui.hunter.doing"
	content.add_child(UIKit.label(Loc.t(doing_key, {"activity": activity_label(runtime.activity)}), &"AccentLabel"))
	var row := _button_grid(2)
	for option in [[&"", "ui.hunter.assign.auto"], [ActivityService.RESTING, "ui.hunter.assign.rest"],
			[ActivityService.TRAINING, "ui.hunter.assign.train"], [ActivityService.SOCIALIZING, "ui.hunter.assign.social"],
			[ActivityService.GATHERING, "ui.hunter.assign.gather"]]:
		var selected: bool = runtime.assigned_activity == option[0]
		var button := UIKit.button(Loc.t(option[1]), func() -> void: run_action(activities.set_assignment(runtime, option[0])),
			&"SelectedButton" if selected else &"Button")
		_fit_button(button)
		row.add_child(button)
	content.add_child(row)


## A grid of equal buttons that wraps instead of growing wider than the screen.
static func _button_grid(columns: int) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override(&"h_separation", 4)
	grid.add_theme_constant_override(&"v_separation", 4)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return grid


## Shares the row width; long labels shrink with an ellipsis instead of widening the sheet.
static func _fit_button(button: Button) -> void:
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.x = 0
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.add_theme_font_size_override(&"font_size", 12)


func _build_bonds_and_history(content: VBoxContainer) -> void:
	var gm := GameManager
	content.add_child(UIKit.label(Loc.t("ui.hunter.bonds"), &"AccentLabel"))
	var bonds := gm.bonds.get_bonds(runtime.unique_id)
	if bonds.is_empty():
		content.add_child(UIKit.label(Loc.t("ui.hunter.no_bonds"), &"MutedLabel"))
	for partner_id in bonds:
		var partner := gm.hunters.get_hunter(partner_id)
		if partner == null:
			continue
		var m := gm.bonds.get_milestone(runtime.unique_id, partner_id)
		var label_text := partner.display_name
		if m == 2:
			label_text = Loc.t("ui.hunter.bond_milestone_2", {"name": partner.display_name})
		elif m == 1:
			label_text = Loc.t("ui.hunter.bond_milestone_1", {"name": partner.display_name})
		content.add_child(UIKit.bar(bonds[partner_id], DataRegistry.config.bond_max, &"MoodBar", label_text))
	var history := runtime.history
	content.add_child(UIKit.label(Loc.t("ui.hunter.history"), &"AccentLabel"))
	content.add_child(UIKit.label(Loc.t("ui.hunter.history_line", {
		"day": int(history.get(HunterRuntime.RECRUIT_DAY, 1)), "won": int(history.get(HunterRuntime.EXPEDITIONS_COMPLETED, 0)),
		"lost": int(history.get(HunterRuntime.EXPEDITIONS_FAILED, 0)), "bosses": int(history.get(HunterRuntime.BOSSES_DEFEATED, 0)),
		"injured": int(history.get(HunterRuntime.TIMES_INJURED, 0))}), &"MutedLabel"))

	# Chronicle & Deeds
	if not runtime.chronicle.is_empty():
		content.add_child(UIKit.label(Loc.t("ui.hunter.chronicle"), &"AccentLabel"))
		var chronicle_box := UIKit.vbox([], 2)
		var entries := runtime.chronicle.slice(-6)
		entries.reverse()
		for entry in entries:
			var text := Loc.t(entry.get("key", ""), {"detail": entry.get("details", "")})
			chronicle_box.add_child(UIKit.label("📜 " + text, &"MutedLabel"))
		content.add_child(UIKit.card(chronicle_box))
