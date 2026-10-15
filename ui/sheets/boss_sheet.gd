class_name BossSheet
extends Sheet
## The Boss Arena (D58): the weekly boss, whether it is up or when it returns, its rewards, how
## many Hunters are assigned, and buttons to send everyone strong enough or recall them.

## Ask the world to look at the arena.
signal focus_requested(region_id: StringName)


func _init() -> void:
	title = Loc.t("ui.boss.title")


func _watch() -> Array:
	var gm := GameManager
	return [[gm.weekly_boss, &"state_changed"], [gm.hunters, &"hunter_changed"], [gm.hunters, &"hunter_added"],
		[gm.hunters, &"hunter_removed"]]


func _build(content: VBoxContainer) -> void:
	var gm := GameManager
	var service: WeeklyBossService = gm.weekly_boss
	var boss := service.get_boss()
	var region := service.get_region()
	if boss == null or region == null:
		content.add_child(UIKit.label(Loc.t("ui.boss.no_arena"), &"MutedLabel"))
		return
	content.add_child(UIKit.label(boss.display_name, &"AccentLabel"))
	content.add_child(UIKit.label(Loc.t("ui.boss.stats", {"hp": int(boss.hp), "atk": "%.0f" % boss.attack, "def": "%.0f" % boss.defense, "level": region.min_hunter_level}), &"MutedLabel"))
	if service.is_available():
		content.add_child(UIKit.label(Loc.t("ui.boss.available"), &"WarningLabel"))
	else:
		content.add_child(UIKit.label(Loc.t("ui.boss.returns", {"time": UIKit.format_duration(service.seconds_until_available())}), &"MutedLabel"))
	var items := PackedStringArray()
	for item_id: StringName in WeeklyBossService.BONUS_ITEMS:
		var item := DataRegistry.get_item(item_id)
		items.append("%d× %s" % [WeeklyBossService.BONUS_ITEMS[item_id], item.display_name if item != null else String(item_id)])
	content.add_child(UIKit.label(Loc.t("ui.boss.chest", {"gold": WeeklyBossService.BONUS_GOLD, "items": ", ".join(items)}), &"MutedLabel"))
	content.add_child(UIKit.label(Loc.t("ui.boss.kills.one" if service.kills == 1 else "ui.boss.kills.other", {"count": service.kills}), &"MutedLabel"))
	content.add_child(UIKit.separator())
	var assigned := service.get_assigned()
	content.add_child(UIKit.label(Loc.t("ui.boss.assigned", {"count": assigned.size()})))
	var strong: Array[HunterRuntime] = gm.hunters.get_all().filter(func(h: HunterRuntime) -> bool:
		return h.alive and not h.injured and h.level >= region.min_hunter_level)
	content.add_child(UIKit.button(Loc.t("ui.boss.send", {"level": region.min_hunter_level, "count": strong.size()}), func() -> void:
		for hunter in strong:
			gm.regions.set_duty(hunter, WeeklyBossService.REGION_ID)
		run_action("", Loc.t("ui.boss.sent", {"count": strong.size()})), &"PrimaryButton",
		"" if not strong.is_empty() else Loc.t("ui.boss.none_strong")))
	content.add_child(UIKit.button(Loc.t("ui.boss.recall"), func() -> void:
		for hunter in assigned:
			gm.regions.set_duty(hunter, &"")
		run_action("", Loc.t("ui.boss.recalled")), &"", "" if not assigned.is_empty() else Loc.t("ui.boss.none_assigned")))
	content.add_child(UIKit.button(Loc.t("ui.boss.look"), func() -> void:
		focus_requested.emit(WeeklyBossService.REGION_ID)
		closed.emit()))
