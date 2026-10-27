class_name ExpeditionSheet
extends Sheet
## Dungeon preparation (UI_DESIGN.md → Expedition panel, D35): where the entrance is,
## recommended level, enemy preview, rewards, party selection (mood, traits, bonds, needs shown),
## start button. Locked dungeons only show that they are sealed.

## Party chosen; UIRoot forwards it to the world, which walks the party to the entrance.
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
	var region := gm.world.get_region(definition.region_id)
	if region != null:
		content.add_child(UIKit.label(Loc.t("ui.expedition.entrance", {"region": region.display_name}), &"MutedLabel"))
	if definition.locked:
		content.add_child(UIKit.label(Loc.t("ui.expedition.sealed"), &"WarningLabel"))
		return
	content.add_child(UIKit.label(Loc.t("ui.expedition.recommended", {"level": definition.recommended_level}), &"AccentLabel"))
	content.add_child(UIKit.label(Loc.t("ui.expedition.enemies", {"enemies": _enemy_preview(definition), "boss": _enemy_name(definition.boss_id)}), &"MutedLabel"))
	var rewards_key := "ui.expedition.rewards" if gm.progress.has_flag(&"first_boss_clear") else "ui.expedition.rewards_first"
	content.add_child(UIKit.label(Loc.t(rewards_key, {"gold": definition.completion_bonus_gold, "ore": _item_name(&"iron_ore"),
		"fang": _item_name(&"beast_fang"), "essence": _item_name(&"dark_essence"), "blade": _item_name(&"fang_blade")}), &"MutedLabel"))
	content.add_child(UIKit.separator())
	_party = _party.filter(func(id: StringName) -> bool: return _is_available(gm.hunters.get_hunter(id)))
	content.add_child(UIKit.label(Loc.t("ui.expedition.party", {"count": _party.size(), "max": DataRegistry.config.max_party_size}), &"AccentLabel"))
	for runtime in gm.hunters.get_active():
		content.add_child(_member_row(runtime))
	var warnings := _warnings(definition)
	for warning in warnings:
		content.add_child(UIKit.label(warning, &"WarningLabel"))
	var reason := gm.expeditions.validate(expedition_id, _party)
	content.add_child(UIKit.label(Loc.t("ui.expedition.fallen_note"), &"MutedLabel"))
	content.add_child(UIKit.button(Loc.t("ui.expedition.walk"), func() -> void:
		depart_requested.emit(expedition_id, _party.duplicate()), &"PrimaryButton", reason))


func _member_row(runtime: HunterRuntime) -> Control:
	var gm := GameManager
	var available := _is_available(runtime)
	var selected := _party.has(runtime.unique_id)
	var traits := PackedStringArray()
	for definition in gm.traits.get_traits(runtime):
		traits.append(definition.display_name)
	var detail_args := {"traits": ", ".join(traits), "mood": HunterSheet.mood_state_name(gm.mood.get_state(runtime))}
	var detail := Loc.t("ui.expedition.member_detail", detail_args)
	if not available:
		if not runtime.alive:
			detail = Loc.t("ui.expedition.fallen")
		else:
			detail = Loc.t("ui.expedition.injured") if runtime.injured else Loc.t("ui.expedition.busy")
	elif GameManager.needs.is_exhausted(runtime) or GameManager.needs.is_hungry(runtime):
		detail = Loc.t("ui.expedition.member_detail_tired", detail_args)
	var info := UIKit.vbox([UIKit.label(Loc.t("ui.expedition.member_name", {"name": runtime.display_name, "level": runtime.level}), &"", false),
		UIKit.label(detail, &"MutedLabel")], 2)
	var full := _party.size() >= DataRegistry.config.max_party_size
	var toggle := UIKit.button(Loc.t("ui.expedition.in_party") if selected else Loc.t("ui.expedition.add"), func() -> void:
		if selected:
			_party.erase(runtime.unique_id)
		else:
			_party.append(runtime.unique_id)
		request_rebuild(),
		&"SelectedButton" if selected else &"Button",
		"" if available and (selected or not full) else (Loc.t("ui.expedition.party_full") if available else Loc.t("ui.expedition.not_available")))
	toggle.size_flags_horizontal = Control.SIZE_SHRINK_END
	toggle.custom_minimum_size.x = 80
	return UIKit.card(UIKit.hbox([HunterPortrait.new().setup(runtime, gm.equipment), info, toggle]))


func _warnings(definition: ExpeditionDefinition) -> PackedStringArray:
	var gm := GameManager
	var result := PackedStringArray()
	for id in _party:
		var runtime := gm.hunters.get_hunter(id)
		if runtime.level < definition.recommended_level:
			result.append(Loc.t("ui.expedition.warn_level", {"name": runtime.display_name}))
		if gm.mood.get_state(runtime) == MoodService.State.LOW:
			# Low mood never blocks (D13).
			result.append(Loc.t("ui.expedition.warn_mood", {"name": runtime.display_name}))
	for i in _party.size():
		for j in range(i + 1, _party.size()):
			if gm.bonds.is_bonded(_party[i], _party[j]):
				result.append(Loc.t("ui.expedition.warn_bonded", {
					"a": gm.hunters.get_hunter(_party[i]).display_name, "b": gm.hunters.get_hunter(_party[j]).display_name}))
	return result


static func _is_available(runtime: HunterRuntime) -> bool:
	return runtime != null and runtime.alive and not runtime.injured and not runtime.hibernating \
			and runtime.state == HunterRuntime.LifecycleState.AVAILABLE


static func _enemy_preview(definition: ExpeditionDefinition) -> String:
	var seen := PackedStringArray()
	for group in definition.enemy_groups:
		for spawn in group.spawns:
			var enemy_name := _enemy_name(spawn.enemy_id)
			if not seen.has(enemy_name):
				seen.append(enemy_name)
	return ", ".join(seen)


static func _item_name(item_id: StringName) -> String:
	var item := DataRegistry.get_item(item_id)
	return item.display_name if item != null else String(item_id)


static func _enemy_name(enemy_id: StringName) -> String:
	var enemy := DataRegistry.get_enemy(enemy_id)
	return enemy.display_name if enemy != null else String(enemy_id)
