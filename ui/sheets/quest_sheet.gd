class_name QuestSheet
extends Sheet
## Quest board (Evil Hunter Tycoon style guided objectives): what to do next, progress and the
## reward to claim. The next quest appears after the previous one is claimed.


func _watch() -> Array:
	var gm := GameManager
	return [[gm.quests, &"quests_changed"]]


func _build(content: VBoxContainer) -> void:
	var quests := GameManager.quests
	set_title("Quests")
	content.add_child(UIKit.label("Done: %d / %d" % [quests.get_claimed_count(), quests.get_all().size()], &"MutedLabel"))
	var active := quests.get_active()
	if active.is_empty():
		content.add_child(UIKit.label("All quests are done. Play on at your own pace.", &"AccentLabel"))
	for quest in active:
		var progress := quests.get_progress(quest)
		var done := quests.is_complete(quest)
		var info := UIKit.vbox([
			UIKit.label(quest.display_name, &"AccentLabel" if done else &""),
			UIKit.label(quest.description, &"MutedLabel"),
			UIKit.bar(progress.x, progress.y, &"XpBar" if not done else &"HpBar", "%d / %d" % [progress.x, progress.y]),
			UIKit.label("Reward: %s" % quests.describe_reward(quest), &"MutedLabel"),
		], 3)
		var claim := UIKit.button("Claim", func() -> void:
			run_action("" if quests.claim(quest) else quests.can_claim(quest), "Reward claimed: %s" % quests.describe_reward(quest)),
			&"PrimaryButton", quests.can_claim(quest))
		claim.size_flags_horizontal = Control.SIZE_SHRINK_END
		claim.custom_minimum_size.x = 64
		content.add_child(UIKit.card(UIKit.hbox([info, claim])))
