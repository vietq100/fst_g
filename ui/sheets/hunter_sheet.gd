class_name HunterSheet
extends Sheet
## Hunter panel (UI_DESIGN.md → Hunter panel): portrait, name, class, level, HP, XP, equipment,
## traits, mood, activity, bonds, history. Actions go through the services.

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
		[gm.inventory, &"inventory_changed"], [gm.bonds, &"bond_changed"]]


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
	], 3)
	var portrait := HunterPortrait.new().setup(runtime, gm.equipment)
	portrait.custom_minimum_size = Vector2(64, 64)
	content.add_child(UIKit.hbox([portrait, header], 8))
	_build_equipment(content)
	_build_traits_and_mood(content)
	_build_activity(content)
	_build_bonds_and_history(content)


func _status_text() -> String:
	if runtime.injured:
		return "Injured — %s at the Hospital" % UIKit.format_duration(GameManager.hospital.get_remaining(runtime))
	if runtime.expedition_id != &"":
		return "On an expedition"
	return "Available"


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
	if runtime.injured or runtime.expedition_id != &"":
		return
	var activities := GameManager.activities
	var current := activities.get_definition(runtime.activity)
	content.add_child(UIKit.label("Doing: %s%s" % [current.display_name if current != null else "—",
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
