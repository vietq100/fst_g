class_name HunterSheet
extends Sheet
## Hunter panel (UI_DESIGN.md → Hunter panel): portrait, name, class, level, HP, XP, equipment,
## needs, purse, traits, mood, activity, bonds, history. Actions go through the services.

## Camera follows this Hunter (D28); UIRoot forwards it to the world.
signal follow_requested(unique_id: StringName)

## Gold moved per Give tap (treasury → purse).
const GIVE_STEP := 50

var runtime: HunterRuntime
var _timer: Timer


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
		[gm.corpses, &"body_delivered"]]


func _build(content: VBoxContainer) -> void:
	var gm := GameManager
	var hunters := gm.hunters
	var definition := hunters.get_definition(runtime)
	set_title(runtime.display_name)
	var max_hp := hunters.get_stat(runtime, HunterService.MAX_HP)
	var required := gm.stats.required_xp(runtime.level)
	var cap := gm.stats.level_cap(gm.progress.town_level)
	var header := UIKit.vbox([
		UIKit.label("%s · Lv %d%s" % [definition.display_name, runtime.level, " (cap)" if runtime.level >= cap else ""]),
		UIKit.bar(runtime.current_hp, max_hp, &"HpBar", "HP %d / %d" % [roundi(runtime.current_hp), roundi(max_hp)]),
		UIKit.bar(runtime.xp, required, &"XpBar", "XP %d / %d" % [runtime.xp, required]),
		UIKit.label("ATK %.1f · DEF %.1f · SPD %d · Crit %d%%" % [
			hunters.get_stat(runtime, HunterService.ATTACK), hunters.get_stat(runtime, HunterService.DEFENSE),
			roundi(hunters.get_stat(runtime, HunterService.MOVE_SPEED)), roundi(hunters.get_stat(runtime, HunterService.CRITICAL_CHANCE) * 100.0)],
			&"MutedLabel"),
		UIKit.label(_status_text(), &"AccentLabel"),
		UIKit.label(_talent_text(), &"MutedLabel"),
	], 3)
	var portrait := HunterPortrait.new().setup(runtime, gm.equipment)
	portrait.custom_minimum_size = Vector2(64, 64)
	content.add_child(UIKit.hbox([portrait, header], 8))
	content.add_child(UIKit.button("Follow on the map", func() -> void: follow_requested.emit(runtime.unique_id), &"",
		"" if runtime.expedition_id == &"" or GameManager.expeditions.is_running() else "Not on the map"))
	_build_needs_and_purse(content)
	_build_equipment(content)
	_build_traits_and_mood(content)
	_build_activity(content)
	_build_bonds_and_history(content)


func _talent_text() -> String:
	var talent := GameManager.talents.get_talent(runtime)
	if talent == null:
		return "No talent"
	return "Talent: %s — %s" % [talent.display_name, talent.description]


func _status_text() -> String:
	var corpses: CorpseService = GameManager.corpses
	if corpses.is_body(runtime):
		if not corpses.has_carrier(runtime):
			return "Fallen — waiting for someone to carry them home"
		var carrier := corpses.get_carrier(runtime)
		var who := carrier.display_name if carrier != null else "Village staff"
		return "Fallen — %s %s" % [who, "is carrying them to the Temple" if corpses.is_carried(runtime) else "is on the way"]
	if not runtime.alive and runtime.injured:
		return "Fallen — revived at the Temple in %s" % UIKit.format_duration(GameManager.temple.get_remaining(runtime))
	var body := corpses.get_body_of(runtime)
	if body != null:
		return "%s %s" % ["Carrying" if corpses.is_carried(body) else "Fetching", body.display_name]
	if runtime.injured:
		return "Injured — %s at the Temple" % UIKit.format_duration(GameManager.temple.get_remaining(runtime))
	if runtime.expedition_id != &"":
		return "On an expedition"
	if runtime.task == HunterRuntime.HUNTING:
		var region := GameManager.world.region_at(runtime.world_position)
		return "Hunting%s" % (" in %s" % region.display_name if region != null and not region.is_town else "")
	if runtime.task != &"":
		return String(runtime.task).capitalize()
	return "In town"


## Stamina / energy (D31) and the purse with treasury transfers (D34, 10% fee).
func _build_needs_and_purse(content: VBoxContainer) -> void:
	var gm := GameManager
	var top: float = DataRegistry.config.needs_max
	var stamina_text := "Stamina %d" % roundi(runtime.stamina) + (" — exhausted" if gm.needs.is_exhausted(runtime) else "")
	var energy_text := "Energy %d" % roundi(runtime.energy) + (" — starving" if gm.needs.is_starving(runtime) else (" — hungry" if gm.needs.is_hungry(runtime) else ""))
	var food_problem := gm.supply.food_reason(runtime) if gm.needs.is_hungry(runtime) else ""
	if not food_problem.is_empty():
		energy_text += " (%s)" % food_problem.to_lower()
	content.add_child(UIKit.hbox([
		UIKit.bar(runtime.stamina, top, &"StaminaBar", stamina_text),
		UIKit.bar(runtime.energy, top, &"EnergyBar", energy_text),
	], 6))
	var purses := gm.purses
	var take_amount := runtime.purse
	var give := UIKit.button("Give %d\n(+%d)" % [GIVE_STEP, purses.get_received(GIVE_STEP)], func() -> void:
		run_action(purses.give(runtime, GIVE_STEP), "Gave %d gold to %s" % [purses.get_received(GIVE_STEP), runtime.display_name]),
		&"", purses.can_give(runtime, GIVE_STEP))
	var take := UIKit.button("Take all\n(+%d)" % purses.get_received(take_amount), func() -> void:
		run_action(purses.take(runtime, take_amount), "Treasury +%d gold" % purses.get_received(take_amount)),
		&"", purses.can_take(runtime, take_amount))
	for button: Button in [give, take]:
		button.size_flags_horizontal = Control.SIZE_SHRINK_END
		button.custom_minimum_size.x = 76
	var purse := UIKit.vbox([
		UIKit.label("Purse %d gold" % runtime.purse),
		UIKit.label("Earns by selling materials; buys food and medicine. Transfers lose %d%%." % roundi(DataRegistry.config.transfer_fee * 100.0), &"MutedLabel"),
	], 2)
	content.add_child(UIKit.card(UIKit.hbox([purse, give, take])))
	_build_duty(content)


## Duty (D29): Auto, a fixed region or Stay in town; plus the loot bag.
func _build_duty(content: VBoxContainer) -> void:
	var regions: RegionService = GameManager.regions
	var target := regions.get_duty_region(runtime)
	content.add_child(UIKit.label("Duty: %s%s" % [regions.get_duty_name(runtime.duty),
		" → %s" % target.display_name if runtime.duty == &"" and target != null else ""], &"AccentLabel"))
	var row := UIKit.hbox([], 4)
	for duty in regions.get_duty_options():
		var region := GameManager.world.get_region(duty)
		var text := regions.get_duty_name(duty)
		if region != null:
			text = "%s\nLv %d+" % [text.replace("Ancient ", "").replace("Goblin ", "").replace("Dark ", ""), region.min_hunter_level]
		elif duty == HunterRuntime.STAY_IN_TOWN:
			text = "Stay"
		var button := UIKit.button(text, func() -> void: run_action(regions.set_duty(runtime, duty)),
			&"PrimaryButton" if runtime.duty == duty else &"")
		button.custom_minimum_size.x = 0
		row.add_child(button)
	content.add_child(row)
	var bag := PackedStringArray()
	for item_id in runtime.loot_bag:
		bag.append("%d %s" % [runtime.loot_bag[item_id], DataRegistry.get_item(item_id).display_name])
	content.add_child(UIKit.label("Loot bag %d / %d%s" % [regions.get_bag_count(runtime), DataRegistry.config.loot_bag_capacity,
		": " + ", ".join(bag) if not bag.is_empty() else ""], &"MutedLabel"))


func _build_equipment(content: VBoxContainer) -> void:
	var equipment := GameManager.equipment
	content.add_child(UIKit.label("Equipment", &"AccentLabel"))
	for slot in [&"weapon", &"armor"]:
		var item := equipment.get_equipped_item(runtime, slot)
		var text := "%s: %s" % [String(slot).capitalize(), "—" if item == null else "%s (%s)" % [item.display_name, UIKit.describe_modifiers(item)]]
		var label := UIKit.label(text)
		if item != null:
			label.add_theme_color_override(&"font_color", RarityColors.of(item.rarity))
		var unequip := UIKit.button("Remove", func() -> void:
			run_action(equipment.unequip(runtime, slot)), &"", "" if item != null else "Nothing equipped")
		unequip.size_flags_horizontal = Control.SIZE_SHRINK_END
		unequip.custom_minimum_size.x = 72
		content.add_child(UIKit.hbox([label, unequip]))
	# Stored items that fit: one button each.
	var options := 0
	for instance_id in GameManager.inventory.get_instances():
		var item := equipment.get_item(instance_id)
		if item == null or not EquipmentService.SLOT_NAMES.has(item.equipment_slot):
			continue
		options += 1
		var button := UIKit.button("Equip %s (%s)" % [item.display_name, UIKit.describe_modifiers(item)], func() -> void:
			run_action(equipment.equip(runtime, instance_id), "Equipped %s" % item.display_name))
		button.add_theme_color_override(&"font_color", RarityColors.of(item.rarity))
		content.add_child(button)
	if options == 0:
		content.add_child(UIKit.label("No spare equipment in the Warehouse. Craft some at the Blacksmith.", &"MutedLabel"))


func _build_traits_and_mood(content: VBoxContainer) -> void:
	var gm := GameManager
	content.add_child(UIKit.label("Personality", &"AccentLabel"))
	for definition in gm.traits.get_traits(runtime):
		content.add_child(UIKit.label("%s — %s" % [definition.display_name, definition.description], &"MutedLabel"))
	var state: String = MoodService.State.keys()[gm.mood.get_state(runtime)]
	var effect := ""
	match gm.mood.get_state(runtime):
		MoodService.State.HIGH:
			effect = " · fights and learns better"
		MoodService.State.LOW:
			effect = " · weaker until rested"
	content.add_child(UIKit.bar(runtime.mood, DataRegistry.config.mood_max, &"MoodBar", "Mood %d — %s%s" % [roundi(runtime.mood), state.capitalize(), effect]))


func _build_activity(content: VBoxContainer) -> void:
	if runtime.injured or not runtime.alive or runtime.expedition_id != &"":
		return
	var activities := GameManager.activities
	var current := activities.get_definition(runtime.activity)
	content.add_child(UIKit.label("Doing: %s%s" % [current.display_name if current != null else String(runtime.activity).capitalize(),
		" (automatic)" if runtime.assigned_activity == &"" else ""], &"AccentLabel"))
	var row := UIKit.hbox([], 4)
	for option in [[&"", "Auto"], [ActivityService.RESTING, "Rest"], [ActivityService.TRAINING, "Train"], [ActivityService.SOCIALIZING, "Social"]]:
		var selected: bool = runtime.assigned_activity == option[0]
		row.add_child(UIKit.button(option[1], func() -> void: run_action(activities.set_assignment(runtime, option[0])),
			&"SelectedButton" if selected else &""))
	content.add_child(row)


func _build_bonds_and_history(content: VBoxContainer) -> void:
	var gm := GameManager
	content.add_child(UIKit.label("Bonds", &"AccentLabel"))
	var bonds := gm.bonds.get_bonds(runtime.unique_id)
	if bonds.is_empty():
		content.add_child(UIKit.label("No bonds yet — share expeditions or socialize at the Tavern.", &"MutedLabel"))
	for partner_id in bonds:
		var partner := gm.hunters.get_hunter(partner_id)
		if partner == null:
			continue
		var bonded := gm.bonds.is_bonded(runtime.unique_id, partner_id)
		content.add_child(UIKit.bar(bonds[partner_id], DataRegistry.config.bond_max, &"MoodBar",
			"%s%s" % [partner.display_name, " — bonded (+5% ATK together)" if bonded else ""]))
	var history := runtime.history
	content.add_child(UIKit.label("History", &"AccentLabel"))
	content.add_child(UIKit.label("Joined on day %d · %d expeditions won · %d lost · %d bosses defeated · injured %d times" % [
		history.get(HunterRuntime.RECRUIT_DAY, 1), history.get(HunterRuntime.EXPEDITIONS_COMPLETED, 0),
		history.get(HunterRuntime.EXPEDITIONS_FAILED, 0), history.get(HunterRuntime.BOSSES_DEFEATED, 0),
		history.get(HunterRuntime.TIMES_INJURED, 0)], &"MutedLabel"))
