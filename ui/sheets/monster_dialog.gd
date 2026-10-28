class_name MonsterDialog
extends Sheet
## Monster dialog (tap a monster on the map), laid out like the Hunter dialog: name and tier, the
## monster's picture with its gear slots around it (weapon and accessory left, armor right), live
## HP, and tabs Info / Skills / Items. Rewards use the same scaling as `RegionService.record_kill`.

enum Tab { INFO, SKILLS, ITEMS }

const TAB_NAMES := ["ui.common.info", "ui.monster.tab.skills", "ui.monster.tab.items"]
const SLOT_SIZE := 44.0

var enemy: Enemy
var _definition: EnemyDefinition
var _level := 1
var _tier := 0
var _tab := Tab.INFO
var _timer: Timer


func _init(monster: Enemy) -> void:
	enemy = monster
	_definition = monster.definition
	_level = monster.level
	_tier = monster.tier


func _ready() -> void:
	super()
	# The monster keeps fighting while the dialog is open.
	_timer = Timer.new()
	_timer.wait_time = 0.5
	_timer.autostart = true
	_timer.timeout.connect(request_rebuild)
	add_child(_timer)


func _alive() -> bool:
	return is_instance_valid(enemy) and enemy.is_targetable()


func _loadout() -> MonsterLoadout:
	return enemy.loadout if is_instance_valid(enemy) else null


func _build(content: VBoxContainer) -> void:
	var tier_color := Tier.color(_tier)
	set_title("%s%s" % ["[%s] " % Tier.code(_tier) if _tier > Tier.Level.C else "", _definition.display_name])
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override(&"font_size", 18)
	_title_label.add_theme_color_override(&"font_color", tier_color)
	var tier_label := UIKit.label(Loc.t("ui.monster.level_tier", {"level": _level, "tier": Tier.name_of(_tier)}), &"HudLabel", false)
	tier_label.add_theme_color_override(&"font_color", tier_color)
	tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(tier_label)
	if _definition.is_boss:
		var boss := UIKit.label(Loc.t("ui.monster.boss"), &"WarningLabel", false)
		boss.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(boss)
	var bestiary_btn := UIKit.button(Loc.t("ui.bestiary.open_btn"), func() -> void: open_requested.emit(BestiarySheet.new()), &"SmallButton")
	bestiary_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(bestiary_btn)
	content.add_child(_paper_doll())
	if _alive():
		content.add_child(UIKit.bar(enemy.health.current_health, enemy.health.max_health, &"HpBar",
			Loc.t("ui.monster.hp", {"current": roundi(enemy.health.current_health), "max": roundi(enemy.health.max_health)})))
	else:
		var defeated := UIKit.label(Loc.t("ui.monster.defeated"), &"MutedLabel", false)
		defeated.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(defeated)
	var loadout := _loadout()
	if loadout != null:
		var gold := UIKit.hbox([PixelIcons.rect(&"coin", 2), UIKit.label(Loc.t("ui.monster.gold", {"gold": loadout.gold}), &"HudLabel", false)], 4)
		gold.alignment = BoxContainer.ALIGNMENT_CENTER
		var gold_chip := PanelContainer.new()
		gold_chip.theme_type_variation = &"Chip"
		gold_chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		gold_chip.add_child(gold)
		content.add_child(gold_chip)
	var tabs := UIKit.hbox([], 0)
	for i in TAB_NAMES.size():
		var tab_button := UIKit.button(Loc.t(TAB_NAMES[i]), func() -> void:
			_tab = i as Tab
			request_rebuild(), &"NavSelected" if _tab == i else &"NavButton")
		tab_button.custom_minimum_size.y = GameTheme.TOUCH
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
			_build_info(body)
		Tab.SKILLS:
			_build_skills(body, loadout)
		Tab.ITEMS:
			_build_items(body, loadout)
	var close := UIKit.button(Loc.t("ui.common.close"), func() -> void: closed.emit(), &"DangerButton")
	close.custom_minimum_size = Vector2(0, GameTheme.TOUCH)
	content.add_child(close)


## The monster's picture in the middle, gear slots around it.
func _paper_doll() -> Control:
	var loadout := _loadout()
	var body_id: StringName = enemy.visual.body_id if is_instance_valid(enemy) and "body_id" in enemy.visual else _definition.id
	var picture := TextureRect.new()
	if MonsterBodies.has_body(body_id):
		picture.texture = MonsterBodies.get_texture(body_id, ChibiBody.View.FRONT, 0, false, not _alive())
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size = Vector2(112, 112)
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var frame := PanelContainer.new()
	frame.theme_type_variation = &"HunterCard"
	frame.add_child(picture)
	var tint := Tier.color(_tier)
	frame.self_modulate = Color(tint, 0.9) if _tier > Tier.Level.C else Color.WHITE
	var left := UIKit.vbox([_slot("ui.monster.slot_weapon", loadout.weapon if loadout != null else &""),
		_slot("ui.monster.slot_accessory", loadout.accessory if loadout != null else &"")], 6)
	var right := UIKit.vbox([_slot("ui.monster.slot_armor", loadout.armor if loadout != null else &""),
		_slot("", &"")], 6)
	left.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	right.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var row := UIKit.hbox([left, frame, right], 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	return row


func _slot(name_key: String, item_id: StringName) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	var item := DataRegistry.find_def(&"item", item_id) as ItemDefinition if item_id != &"" else null
	if item == null:
		var empty_style := StyleBoxFlat.new()
		empty_style.bg_color = Color(0.06, 0.07, 0.1, 0.9)
		empty_style.border_color = Color(0.18, 0.22, 0.32, 0.8)
		empty_style.set_border_width_all(1)
		empty_style.set_corner_radius_all(4)
		empty_style.set_content_margin_all(4)
		panel.add_theme_stylebox_override(&"panel", empty_style)
		var hint := UIKit.label(Loc.t(name_key) if name_key != "" and _definition.can_equip else "", &"MutedLabel", false)
		hint.add_theme_font_size_override(&"font_size", GameTheme.SMALL_SIZE)
		hint.clip_text = true
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(hint)
		return panel
	panel.theme_type_variation = &"HunterCard"
	# The icon opens the item's details (ItemInfoModal), like a Hunter's worn gear.
	var icon := ItemIcon.new().setup(item, 28)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var name_label := UIKit.label(item.display_name, &"MutedLabel", false)
	name_label.add_theme_font_size_override(&"font_size", GameTheme.SMALL_SIZE)
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.custom_minimum_size.x = SLOT_SIZE - 6.0
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override(&"font_color", RarityColors.of(item.rarity))
	panel.add_child(UIKit.vbox([icon, name_label], 1))
	panel.tooltip_text = "%s · %s" % [item.display_name, UIKit.rarity_name(item)]
	return panel


func _build_info(body: VBoxContainer) -> void:
	var gm := GameManager
	var stats := enemy.get_combat_stats() if is_instance_valid(enemy) else null
	var scale := gm.regions.get_stat_scale(_level) * Tier.stat_scale(_tier)
	var attack: float = stats.attack if stats != null else _definition.attack * scale
	var defense: float = stats.defense if stats != null else _definition.defense * scale
	var speed: float = stats.attack_speed if stats != null else _definition.attack_speed
	var move: float = enemy.get_move_speed() if is_instance_valid(enemy) else _definition.move_speed
	var dps := attack * speed * (1.0 + _definition.critical_chance * (_definition.critical_damage - 1.0))
	var rows := UIKit.vbox([], 4)
	# Each value in the colour of its grade against the average regular monster at this level and
	# tier (D80); the total grades the monster as a whole.
	var grades := gm.grades
	var values := {&"hp": enemy.health.max_health if is_instance_valid(enemy) else _definition.hp * scale,
		&"attack": attack, &"defense": defense, &"attack_speed": speed, &"move_speed": move,
		&"critical_chance": _definition.critical_chance, &"critical_damage": _definition.critical_damage}
	for entry in [["stat.attack", "%d" % roundi(attack), &"attack"], ["stat.defense", "%d" % roundi(defense), &"defense"],
			["stat.attack_speed", "%.2f" % speed, &"attack_speed"], ["stat.move_speed", "%d" % roundi(move), &"move_speed"],
			["stat.critical_chance", "%d%%" % roundi(_definition.critical_chance * 100.0), &"critical_chance"],
			["stat.critical_damage", "×%.1f" % _definition.critical_damage, &"critical_damage"], ["ui.monster.dps", "%.1f" % dps, &""]]:
		var name_label := UIKit.label(Loc.t(entry[0]), &"HudSmallLabel", false)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var value := UIKit.label(entry[1], &"HudAccentLabel", false)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if entry[2] != &"":
			value.add_theme_color_override(&"font_color", StatGradeService.color(grades.monster_step(entry[2], values[entry[2]], scale)))
		rows.add_child(UIKit.hbox([name_label, value], 4))
	var grade := grades.monster_grade(values, scale)
	var grade_label := UIKit.label(Loc.t("ui.common.grade", {"grade": StatGradeService.name_of(grade)}), &"HudSmallLabel", false)
	grade_label.add_theme_color_override(&"font_color", StatGradeService.color(grade))
	rows.add_child(grade_label)
	body.add_child(rows)
	var reward_scale := gm.regions.get_reward_scale(_level) * Tier.reward_scale(_tier)
	body.add_child(UIKit.label(Loc.t("ui.monster.rewards", {"xp": roundi(_definition.xp_reward * reward_scale),
		"gold_min": roundi(_definition.gold_min * reward_scale), "gold_max": roundi(_definition.gold_max * reward_scale)}), &"AccentLabel"))
	body.add_child(UIKit.label(Loc.t("ui.monster.difficulty", {"name": gm.reincarnation.get_difficulty_name(gm.progress.difficulty),
		"stat": "%.1f" % gm.regions.get_stat_scale(1), "reward": "%.1f" % gm.regions.get_reward_scale(1)}), &"MutedLabel"))
	var region := GameManager.world.region_at(enemy.global_position) if is_instance_valid(enemy) else null
	if region != null:
		body.add_child(UIKit.label(Loc.t("ui.monster.region", {"region": region.display_name}), &"MutedLabel"))
	if not _definition.on_hit_effects.is_empty():
		var names := PackedStringArray()
		for chance_entry in _definition.on_hit_effects:
			names.append("%s %d%%" % [chance_entry.effect.display_name, roundi(chance_entry.chance * 100.0)])
		body.add_child(UIKit.label(Loc.t("ui.monster.hits", {"effects": ", ".join(names)}), &"MutedLabel"))
	if not _definition.can_equip:
		body.add_child(UIKit.label(Loc.t("ui.monster.no_gear"), &"MutedLabel"))


func _build_skills(body: VBoxContainer, loadout: MonsterLoadout) -> void:
	if loadout == null or loadout.skills.is_empty():
		body.add_child(UIKit.label(Loc.t("ui.monster.no_skills"), &"MutedLabel"))
		return
	var tiles: Array = []
	for skill_id in loadout.skills:
		var skill := DataRegistry.find_def(&"monster_skill", skill_id) as MonsterSkillDefinition
		if skill != null:
			tiles.append(SkillTile.new().setup(skill, {"lines": _skill_lines(skill)}))
	body.add_child(SkillTile.grid(tiles))
	body.add_child(UIKit.label(Loc.t("ui.skill.tap_hint"), &"MutedLabel"))


func _skill_lines(skill: MonsterSkillDefinition) -> Array[String]:
	var lines: Array[String] = []
	if skill.attack_ratio > 0.0:
		lines.append(Loc.t("ui.skill.damage", {"percent": roundi(skill.attack_ratio * 100.0), "hits": skill.hits}))
	if skill.heal_ratio > 0.0:
		lines.append(Loc.t("ui.skill.heal", {"percent": roundi(skill.heal_ratio * 100.0)}))
	if skill.trigger_hp_below > 0.0:
		lines.append(Loc.t("ui.skill.below_hp", {"percent": roundi(skill.trigger_hp_below * 100.0)}))
	for modifier in skill.modifiers:
		lines.append(ItemInfoModal._modifier_text(modifier))
	return lines


func _build_items(body: VBoxContainer, loadout: MonsterLoadout) -> void:
	if loadout != null:
		body.add_child(UIKit.label(Loc.t("ui.monster.carried"), &"AccentLabel"))
		body.add_child(UIKit.label(Loc.t("ui.monster.gold", {"gold": loadout.gold}), &"MutedLabel"))
		for item_id in loadout.resources:
			body.add_child(_item_row(item_id, loadout.resources[item_id]))
		if loadout.meat > 0:
			body.add_child(_item_row(RegionService.MEAT_ITEM, loadout.meat))
		for item_id in loadout.get_gear():
			body.add_child(_item_row(item_id, 1))
		body.add_child(UIKit.label(Loc.t("ui.monster.gear_drop", {"chance": roundi((RegionService.GEAR_DROP_BASE + RegionService.GEAR_DROP_PER_TIER * _tier) * 100.0)}), &"MutedLabel"))
		body.add_child(UIKit.separator())
	body.add_child(UIKit.label(Loc.t("ui.monster.drops"), &"AccentLabel"))
	var table := DataRegistry.find_def(&"loot_table", _definition.loot_table_id) as LootTableDefinition if _definition.loot_table_id != &"" else null
	if table == null or table.entries.is_empty():
		body.add_child(UIKit.label(Loc.t("ui.monster.no_drops"), &"MutedLabel"))
		return
	for entry in table.entries:
		var item := DataRegistry.find_def(&"item", entry.item_id) as ItemDefinition
		var name_text := item.display_name if item != null else String(entry.item_id)
		var chance := roundi(entry.chance * 100.0)
		var text := Loc.t("ui.monster.drop_line", {"name": name_text, "qty": entry.quantity_max, "chance": chance}) \
			if entry.quantity_min == entry.quantity_max \
			else Loc.t("ui.monster.drop_line_range", {"name": name_text, "min": entry.quantity_min, "max": entry.quantity_max, "chance": chance})
		var line := UIKit.label(text, &"MutedLabel")
		if item != null:
			line.add_theme_color_override(&"font_color", RarityColors.of(item.rarity))
		var icon: Control = ItemIcon.new().setup(item, 20) if item != null else UIKit.swatch(Color.WHITE, 10)
		body.add_child(UIKit.hbox([icon, line], 6))


func _item_row(item_id: StringName, quantity: int) -> Control:
	var item := DataRegistry.find_def(&"item", item_id) as ItemDefinition
	var label := UIKit.label("%s ×%d" % [item.display_name if item != null else String(item_id), quantity], &"")
	if item != null:
		label.add_theme_color_override(&"font_color", RarityColors.of(item.rarity))
	var icon: Control = ItemIcon.new().setup(item, 24) if item != null else UIKit.swatch(Color.WHITE, 12)
	return UIKit.hbox([icon, label], 6)
