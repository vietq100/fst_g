class_name HunterDialog
extends HunterSheet
## Hunter detail dialog (Evil Hunter Tycoon style): name, reincarnation stars and purse, a paper
## doll of the equipment around the portrait, rebirth points, and tabs Info / Skills & Traits /
## Gear / Life. Centered on the screen. Reuses the HunterSheet sections for the tab bodies.

enum Tab { INFO, SKILLS, GEAR, LIFE }

const TAB_NAMES := ["Info", "Skill&Trait", "Gear", "Life"]
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
	var star_box := UIKit.vbox([stars, UIKit.label("Reincarnation %d" % runtime.reincarnations, &"HudSmallLabel", false)], 0)
	var purse := UIKit.hbox([PixelIcons.rect(&"coin", 2), UIKit.label("%d" % runtime.purse, &"HudLabel", false)], 4)
	var purse_panel := PanelContainer.new()
	purse_panel.theme_type_variation = &"HudBubble"
	purse_panel.add_child(purse)
	purse_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	content.add_child(UIKit.hbox([star_box, purse_panel], 6))
	content.add_child(_paper_doll())
	var souls := UIKit.label("Own %d Rebirth Points" % runtime.rebirth_points, &"HudLabel", false)
	souls.add_theme_color_override(&"font_color", SOULS)
	souls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(souls)
	var tabs := UIKit.hbox([], 0)
	for i in TAB_NAMES.size():
		var tab_button := UIKit.button(TAB_NAMES[i], func() -> void:
			_tab = i as Tab
			request_rebuild(), &"NavSelected" if _tab == i else &"NavButton")
		tab_button.custom_minimum_size.y = 32
		tab_button.add_theme_font_size_override(&"font_size", 11)
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
		Tab.GEAR:
			_build_equipment(body)
		Tab.LIFE:
			_build_needs_and_purse(body)
			_build_duty(body)
			_build_activity(body)
			_build_bonds_and_history(body)
	var close := UIKit.button("Close", func() -> void: closed.emit(), &"DangerButton")
	close.custom_minimum_size = Vector2(0, 40)
	content.add_child(close)


## Slots around the portrait: weapon and accessory on the left, armor on the right, spare
## slots dimmed. Tapping a filled slot opens the Gear tab.
func _paper_doll() -> Control:
	var gm := GameManager
	var portrait := HunterPortrait.new().setup(runtime, gm.equipment)
	portrait.custom_minimum_size = Vector2(96, 96)
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var left := UIKit.vbox([_slot(&"weapon"), _slot(&"accessory")], 6)
	var right := UIKit.vbox([_slot(&"armor"), _slot(&"")], 6)
	left.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	right.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var row := UIKit.hbox([left, portrait, right], 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	return row


func _slot(slot: StringName) -> Control:
	var gm := GameManager
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"HunterCard"
	panel.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	var instance_id: StringName = runtime.equipment.get(slot, &"") if slot != &"" else &""
	var item := gm.equipment.get_item(instance_id) if instance_id != &"" else null
	if item == null:
		panel.modulate = Color(1, 1, 1, 0.45)
		var hint := UIKit.label(String(slot).left(3).capitalize() if slot != &"" else "", &"MutedLabel", false)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(hint)
		return panel
	var enhance := gm.inventory.get_enhance(instance_id)
	var icon := ItemIcon.new().setup(item, 28, "+%d" % enhance if enhance > 0 else "")
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var name_label := UIKit.label(item.display_name, &"MutedLabel", false)
	name_label.add_theme_font_size_override(&"font_size", 8)
	name_label.clip_text = true
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override(&"font_color", RarityColors.of(item.rarity))
	var column := UIKit.vbox([icon, name_label], 1)
	panel.add_child(column)
	panel.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_tab = Tab.GEAR
			request_rebuild())
	return panel


func _build_info(body: VBoxContainer, definition: HunterDefinition) -> void:
	var gm := GameManager
	var hunters := gm.hunters
	var grade := HuntersSheet.grade_of(runtime)
	var grade_name: String = ["COMMON", "RARE", "SUPERIOR", "LEGENDARY"][HuntersSheet.GRADES.find(grade)]
	var attack := hunters.get_stat(runtime, HunterService.ATTACK)
	var speed := hunters.get_stat(runtime, HunterService.ATTACK_SPEED)
	var crit := hunters.get_stat(runtime, HunterService.CRITICAL_CHANCE)
	var crit_damage := hunters.get_stat(runtime, HunterService.CRITICAL_DAMAGE)
	var dps := attack * speed * (1.0 + crit * (crit_damage - 1.0))
	var rank := UIKit.label(grade_name, &"HudLabel", false)
	rank.add_theme_color_override(&"font_color", grade[1])
	rank.add_theme_font_size_override(&"font_size", 17)
	var title := UIKit.vbox([rank, UIKit.label("Lv.%d %s" % [runtime.level, definition.display_name], &"HudLabel", false)], 0)
	var dps_box := UIKit.vbox([UIKit.label("DPS", &"HudLabel", false), UIKit.label("%.1f" % dps, &"HudAccentLabel", false)], 0)
	dps_box.size_flags_horizontal = Control.SIZE_SHRINK_END
	body.add_child(UIKit.hbox([title, dps_box]))
	var max_hp := hunters.get_stat(runtime, HunterService.MAX_HP)
	var top: float = DataRegistry.config.needs_max
	var bars := UIKit.vbox([
		UIKit.bar(runtime.current_hp, max_hp, &"HpBar", "HP %d/%d" % [roundi(runtime.current_hp), roundi(max_hp)]),
		UIKit.bar(runtime.energy, top, &"EnergyBar", "Satiety %d/%d" % [roundi(runtime.energy), roundi(top)]),
		UIKit.bar(runtime.mood, DataRegistry.config.mood_max, &"MoodBar", "Mood %d/%d" % [roundi(runtime.mood), roundi(DataRegistry.config.mood_max)]),
		UIKit.bar(runtime.stamina, top, &"StaminaBar", "Stamina %d/%d" % [roundi(runtime.stamina), roundi(top)]),
		UIKit.bar(runtime.xp, gm.stats.required_xp(runtime.level), &"XpBar", "XP %d/%d" % [runtime.xp, gm.stats.required_xp(runtime.level)]),
	], 4)
	var stats := UIKit.vbox([], 4)
	for entry in [["ATK", "%d" % roundi(attack)], ["DEF", "%d" % roundi(hunters.get_stat(runtime, HunterService.DEFENSE))],
			["CRIT", "%d%%" % roundi(crit * 100.0)], ["ATK SPD", "%.2f" % speed],
			["MOVE", "%d" % roundi(hunters.get_stat(runtime, HunterService.MOVE_SPEED))]]:
		var name_label := UIKit.label(entry[0], &"HudSmallLabel", false)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var value := UIKit.label(entry[1], &"HudAccentLabel", false)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stats.add_child(UIKit.hbox([name_label, value], 4))
	bars.size_flags_stretch_ratio = 1.4
	body.add_child(UIKit.hbox([bars, stats], 10))
	body.add_child(UIKit.label("Awakening   Reborn %d×   ·   %s" % [runtime.reincarnations, _status_text()], &"HudSmallLabel"))
	var follow := UIKit.button("Follow on the map", func() -> void: follow_requested.emit(runtime.unique_id), &"",
		"" if runtime.expedition_id == &"" or GameManager.expeditions.is_running() else "Not on the map")
	body.add_child(follow)


func _build_skills(body: VBoxContainer) -> void:
	_build_active_skills(body)
	body.add_child(UIKit.separator())
	body.add_child(UIKit.label(_talent_text(), &"HudSmallLabel"))
	body.add_child(UIKit.label(_skills_text(), &"HudSmallLabel"))
	_build_traits_and_mood(body)


## Active skills (D55): the two equipped slots, then every skill of the class with its unlock
## level; tapping an unlocked one puts it in the first slot (long list → scrolls with the tab).
func _build_active_skills(body: VBoxContainer) -> void:
	var gm := GameManager
	var definition := gm.hunters.get_definition(runtime)
	var equipped := ActiveSkills.loadout(DataRegistry, runtime, definition)
	body.add_child(UIKit.label("Active skills", &"HudAccentLabel", false))
	var slots := UIKit.hbox([], 4)
	for i in ActiveSkills.SLOTS:
		var skill: ActiveSkillDefinition = equipped[i] if i < equipped.size() else null
		var card := PanelContainer.new()
		card.theme_type_variation = &"HunterCard"
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var title := UIKit.label(skill.display_name if skill != null else "Empty slot", &"HudSmallLabel", false)
		title.clip_text = true
		var detail := UIKit.label("CD %ds · %s" % [roundi(skill.cooldown), _skill_summary(skill)] if skill != null else "Unlocks with levels", &"MutedLabel")
		detail.add_theme_font_size_override(&"font_size", 9)
		card.add_child(UIKit.vbox([title, detail], 1))
		slots.add_child(card)
	body.add_child(slots)
	var owned := ActiveSkills.for_class(DataRegistry, ActiveSkills.base_class_of(definition))
	body.add_child(UIKit.label("%d / %d unlocked — tap a skill to equip it" % [
		owned.filter(func(k: ActiveSkillDefinition) -> bool: return ActiveSkills.is_unlocked(k, runtime)).size(), owned.size()], &"MutedLabel"))
	for skill in owned:
		var unlocked := ActiveSkills.is_unlocked(skill, runtime)
		var in_use := equipped.has(skill)
		var row := UIKit.button("%s%s" % [skill.display_name, "  ✓" if in_use else ("  Lv %d" % skill.required_level if not unlocked else "")], func() -> void:
			run_action(ActiveSkills.set_slot(DataRegistry, runtime, definition, 1 if equipped.size() > 0 and equipped[0] != skill and not in_use and equipped.size() >= ActiveSkills.SLOTS else 0, skill.id),
				"%s equipped" % skill.display_name),
			&"SelectedButton" if in_use else (&"RowButton" if unlocked else &""), "" if unlocked else "Unlocks at level %d" % skill.required_level)
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.custom_minimum_size.y = 34
		row.add_theme_font_size_override(&"font_size", 11)
		row.tooltip_text = skill.description
		var summary := UIKit.label(_skill_summary(skill), &"MutedLabel", false)
		summary.add_theme_font_size_override(&"font_size", 9)
		summary.clip_text = true
		summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		summary.custom_minimum_size.x = 90
		body.add_child(UIKit.hbox([row, summary], 4))


static func _skill_summary(skill: ActiveSkillDefinition) -> String:
	if skill == null:
		return ""
	var parts := PackedStringArray()
	if skill.damage > 0.0:
		parts.append("×%.1f" % skill.damage + (" ×%d foes" % skill.targets if skill.targets > 1 else ""))
	if skill.effect_id != &"":
		parts.append(String(skill.effect_id).replace("_", " ").capitalize())
	if skill.self_effect_id != &"":
		parts.append("+" + String(skill.self_effect_id).replace("_", " ").capitalize())
	if skill.heal_ratio > 0.0:
		parts.append("heal %d%%" % roundi(skill.heal_ratio * 100.0))
	return " · ".join(parts)
	if GameManager.buildings.has_building(BuildingService.ACADEMY):
		body.add_child(UIKit.button("Open the Academy", func() -> void:
			open_requested.emit(BuildingSheet.new(BuildingService.ACADEMY)), &"PrimaryButton"))
	else:
		body.add_child(UIKit.label("Build an Academy (Town Hall Lv 3) to train skills and learn traits.", &"MutedLabel"))
