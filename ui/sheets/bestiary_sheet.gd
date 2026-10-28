class_name BestiarySheet
extends Sheet
## Bestiary & Monster Encyclopedia sheet.
## Shows defeated monster species, kill count progression, unlocked lore,
## weaknesses, and mastery combat bonuses.

func _watch() -> Array:
	var gm := GameManager
	return [
		[gm.bestiary, &"kill_recorded"],
		[gm.bestiary, &"mastery_unlocked"],
	]


func _build(content: VBoxContainer) -> void:
	var gm := GameManager
	var bestiary: BestiaryService = gm.bestiary
	set_title(Loc.t("ui.bestiary.title"))

	content.add_child(UIKit.label(Loc.t("ui.bestiary.subtitle"), &"MutedLabel"))

	var monsters := bestiary.get_all_monsters()
	for m: Dictionary in monsters:
		var mid: StringName = m.id
		var kills := bestiary.get_kills(mid)
		var stars := bestiary.get_mastery_stars(mid)
		var th: Array = m.thresholds
		var is_boss: bool = m.is_boss

		var m_name := Loc.t(m.name_key) if Loc.has_key(m.name_key) else String(mid).capitalize()
		var stars_str := ""
		for s in range(3):
			stars_str += "★" if s < stars else "☆"

		var header_text := "%s %s" % [m_name, stars_str]
		if is_boss:
			header_text += " [" + Loc.t("ui.bestiary.boss_tag") + "]"

		var title_label := UIKit.label(header_text, &"AccentLabel" if stars > 0 else &"")
		var kills_label := UIKit.label(Loc.t("ui.bestiary.kills_count", {"count": kills}), &"MutedLabel")

		var next_target := th[0]
		if stars == 1:
			next_target = th[1]
		elif stars >= 2:
			next_target = th[2]

		var progress_bar := UIKit.bar(kills, next_target, &"XpBar", "%d / %d" % [kills, next_target])

		var info_box := UIKit.vbox([title_label, kills_label, progress_bar], 3)
		info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# Lore & Weaknesses section
		if stars >= 1:
			var lore_text := Loc.t(m.lore_key) if Loc.has_key(m.lore_key) else ""
			info_box.add_child(UIKit.label(lore_text, &"MutedLabel"))
		else:
			info_box.add_child(UIKit.label(Loc.t("ui.bestiary.locked_lore", {"needed": th[0]}), &"MutedLabel"))

		if stars >= 2:
			var weak_text := Loc.t(m.weakness_key) if Loc.has_key(m.weakness_key) else ""
			info_box.add_child(UIKit.label(Loc.t("ui.bestiary.weakness_label", {"weakness": weak_text}), &"AccentLabel"))
			var bonus_label := UIKit.label(Loc.t("ui.bestiary.bonus_t2"), &"AccentLabel")
			info_box.add_child(bonus_label)

		if stars >= 3:
			var master_label := UIKit.label(Loc.t("ui.bestiary.bonus_t3"), &"AccentLabel")
			info_box.add_child(master_label)

		var card := UIKit.card(info_box)
		if stars >= 3:
			var card_style := GameTheme._box(Color(0.1, 0.12, 0.16, 0.95), Color(0.75, 0.45, 0.95, 0.8), 6, 1, 8)
			card_style.shadow_color = Color(0, 0, 0, 0.4)
			card_style.shadow_size = 4
			card.add_theme_stylebox_override(&"panel", card_style)
		content.add_child(card)
