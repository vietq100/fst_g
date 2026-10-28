class_name QuestSheet
extends Sheet
## Quest board (Evil Hunter Tycoon style guided objectives): what to do next, progress and the
## reward to claim. The next quest appears after the previous one is claimed.


func _watch() -> Array:
	var gm := GameManager
	return [[gm.quests, &"quests_changed"]]


func _build(content: VBoxContainer) -> void:
	var quests := GameManager.quests
	set_title(Loc.t("ui.quest.title"))
	var top_row := UIKit.hbox([
		UIKit.label(Loc.t("ui.quest.done", {"done": quests.get_claimed_count(), "total": quests.get_all().size()}), &"MutedLabel"),
		UIKit.button(Loc.t("ui.bounty.open_btn"), func() -> void: open_requested.emit(BountySheet.new()), &"SmallButton"),
	], 8)
	content.add_child(top_row)
	var active := quests.get_active()
	if active.is_empty():
		content.add_child(UIKit.label(Loc.t("ui.quest.all_done"), &"AccentLabel"))
	for quest in active:
		var progress := quests.get_progress(quest)
		var done := quests.is_complete(quest)
		var info := UIKit.vbox([
			UIKit.label(quest.display_name, &"AccentLabel" if done else &""),
			UIKit.label(quest.description, &"MutedLabel"),
			UIKit.bar(progress.x, progress.y, &"XpBar" if not done else &"HpBar", "%d / %d" % [progress.x, progress.y]),
			UIKit.label(Loc.t("ui.quest.reward", {"reward": quests.describe_reward(quest)}), &"MutedLabel"),
		], 3)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var claim := UIKit.button(Loc.t("ui.quest.claim"), func() -> void:
			run_action("" if quests.claim(quest) else quests.can_claim(quest), Loc.t("ui.quest.claimed", {"reward": quests.describe_reward(quest)})),
			&"PrimaryButton", quests.can_claim(quest))
		claim.size_flags_horizontal = Control.SIZE_SHRINK_END
		claim.custom_minimum_size = Vector2(72, GameTheme.TOUCH)
		var card := UIKit.card(UIKit.hbox([info, claim], 8))
		if done:
			var card_style := GameTheme._box(Color(0.086, 0.11, 0.16, 0.95), Color(0.83, 0.69, 0.22, 0.7), 6, 1, 8)
			card_style.shadow_color = Color(0, 0, 0, 0.4)
			card_style.shadow_size = 4
			card.add_theme_stylebox_override(&"panel", card_style)
		content.add_child(card)
