class_name ExpeditionSheet
extends Sheet
## Expedition preparation (UI_DESIGN.md → Expedition panel): destination, recommended level,
## enemy preview, rewards, party selection (mood, traits, bonds shown), start button.

## Party chosen; UIRoot forwards it to the Town, which walks the party to the gate.
signal depart_requested(expedition_id: StringName, party: Array[StringName])

var expedition_id: StringName
var _party: Array[StringName] = []


func _init(id: StringName, default_party: Array[StringName]) -> void:
	expedition_id = id
	_party = default_party.duplicate()


func _watch() -> Array:
	var gm := GameManager
	return [[gm.hunters, &"hunter_changed"], [gm.hunters, &"hunter_added"]]


func _build(content: VBoxContainer) -> void:
	var gm := GameManager
	var definition := gm.expeditions.get_definition(expedition_id)
	set_title(definition.display_name)
	content.add_child(UIKit.label("Recommended level %d" % definition.recommended_level, &"AccentLabel"))
	content.add_child(UIKit.label("Enemies: %s\nBoss: %s" % [_enemy_preview(definition), _enemy_name(definition.boss_id)], &"MutedLabel"))
	content.add_child(UIKit.label("Rewards: gold, Iron Ore, Beast Fang; boss: Dark Essence, chance of a Fang Blade; +%d gold for clearing%s" % [
		definition.completion_bonus_gold, "" if gm.progress.has_flag(&"first_boss_clear") else "; first clear unlocks Town Hall Lv 2"], &"MutedLabel"))
	content.add_child(UIKit.separator())
	_party = _party.filter(func(id: StringName) -> bool: return _is_available(gm.hunters.get_hunter(id)))
	content.add_child(UIKit.label("Party (%d / %d)" % [_party.size(), DataRegistry.config.max_party_size], &"AccentLabel"))
	for runtime in gm.hunters.get_all():
		content.add_child(_member_row(runtime))
	var warnings := _warnings(definition)
	for warning in warnings:
		content.add_child(UIKit.label(warning, &"WarningLabel"))
	var reason := gm.expeditions.validate(expedition_id, _party)
	content.add_child(UIKit.button("Depart through the South Gate", func() -> void:
		depart_requested.emit(expedition_id, _party.duplicate()), &"PrimaryButton", reason))


func _member_row(runtime: HunterRuntime) -> Control:
	var gm := GameManager
	var available := _is_available(runtime)
	var selected := _party.has(runtime.unique_id)
	var traits := PackedStringArray()
	for definition in gm.traits.get_traits(runtime):
		traits.append(definition.display_name)
	var mood: String = MoodService.State.keys()[gm.mood.get_state(runtime)]
	var detail := "%s · Mood %s" % [", ".join(traits), mood.capitalize()]
	if not available:
		detail = "Injured" if runtime.injured else "Busy"
	var info := UIKit.vbox([UIKit.label("%s  Lv %d" % [runtime.display_name, runtime.level], &"", false),
		UIKit.label(detail, &"MutedLabel")], 2)
	var full := _party.size() >= DataRegistry.config.max_party_size
	var toggle := UIKit.button("In party" if selected else "Add", func() -> void:
		if selected:
			_party.erase(runtime.unique_id)
		else:
			_party.append(runtime.unique_id)
		request_rebuild(),
		&"SelectedButton" if selected else &"",
		"" if available and (selected or not full) else ("Party is full" if available else "Not available"))
	toggle.size_flags_horizontal = Control.SIZE_SHRINK_END
	toggle.custom_minimum_size.x = 80
	return UIKit.card(UIKit.hbox([HunterPortrait.new().setup(runtime, gm.equipment), info, toggle]))


func _warnings(definition: ExpeditionDefinition) -> PackedStringArray:
	var gm := GameManager
	var result := PackedStringArray()
	for id in _party:
		var runtime := gm.hunters.get_hunter(id)
		if runtime.level < definition.recommended_level:
			result.append("%s is below the recommended level." % runtime.display_name)
		if gm.mood.get_state(runtime) == MoodService.State.LOW:
			# Low mood never blocks (D13).
			result.append("%s is in a low mood (−10%% ATK/DEF)." % runtime.display_name)
	for i in _party.size():
		for j in range(i + 1, _party.size()):
			if gm.bonds.is_bonded(_party[i], _party[j]):
				result.append("%s and %s are bonded: +5%% ATK together." % [
					gm.hunters.get_hunter(_party[i]).display_name, gm.hunters.get_hunter(_party[j]).display_name])
	return result


static func _is_available(runtime: HunterRuntime) -> bool:
	return runtime != null and not runtime.injured and runtime.state == HunterRuntime.LifecycleState.AVAILABLE


static func _enemy_preview(definition: ExpeditionDefinition) -> String:
	var seen := PackedStringArray()
	for group in definition.enemy_groups:
		for spawn in group.spawns:
			var enemy_name := _enemy_name(spawn.enemy_id)
			if not seen.has(enemy_name):
				seen.append(enemy_name)
	return ", ".join(seen)


static func _enemy_name(enemy_id: StringName) -> String:
	var enemy := DataRegistry.get_enemy(enemy_id)
	return enemy.display_name if enemy != null else String(enemy_id)
