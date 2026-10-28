class_name BountySheet
extends Sheet
## Bounty Board & Urgent Contracts sheet.
## Shows active daily contracts with progress, rewards, and claim buttons.

func _watch() -> Array:
	var gm := GameManager
	return [[gm.bounties, &"bounties_updated"]]


func _build(content: VBoxContainer) -> void:
	var gm := GameManager
	var bounties: BountyService = gm.bounties
	set_title(Loc.t("ui.bounty.title"))

	var timer_text := Loc.t("ui.bounty.refresh_in", {"time": UIKit.format_duration(bounties.get_time_until_refresh())})
	var refresh_row := UIKit.hbox([
		UIKit.label(timer_text, &"MutedLabel"),
		UIKit.button(Loc.t("ui.bounty.refresh_btn"), func() -> void:
			bounties.refresh_bounties(true)
			toast(Loc.t("ui.bounty.refreshed")),
			&"SmallButton"),
	], 8)
	content.add_child(refresh_row)

	var list := bounties.get_bounties()
	if list.is_empty():
		content.add_child(UIKit.label(Loc.t("ui.bounty.none"), &"MutedLabel"))
		return

	for b: Dictionary in list:
		var target_name := Loc.t(b.target_name_key) if Loc.has_key(b.target_name_key) else String(b.target_id)
		var progress: int = b.progress
		var required: int = b.required
		var claimed: bool = b.claimed
		var can_claim: bool = bounties.can_claim(b.id)

		var reward_parts := PackedStringArray()
		if b.reward_gold > 0:
			reward_parts.append(Loc.t("ui.common.gold", {"amount": b.reward_gold}))
		if b.reward_tickets > 0:
			reward_parts.append(Loc.t("ui.bounty.tickets", {"count": b.reward_tickets}))
		if b.reward_item != &"" and b.reward_item_count > 0:
			var item := gm.registry.find_def(&"item", b.reward_item) as ItemDefinition
			var iname := item.display_name if item != null else String(b.reward_item)
			reward_parts.append("%d× %s" % [b.reward_item_count, iname])

		var reward_str := ", ".join(reward_parts)

		var title_label := UIKit.label(Loc.t("ui.bounty.contract_title", {"target": target_name, "count": required}), &"AccentLabel" if can_claim else &"")
		var bar := UIKit.bar(progress, required, &"HpBar" if can_claim else &"XpBar", "%d / %d" % [progress, required])
		var reward_label := UIKit.label(Loc.t("ui.bounty.reward_line", {"reward": reward_str}), &"MutedLabel")

		var claim_btn := UIKit.button(
			Loc.t("ui.bounty.claimed_btn") if claimed else Loc.t("ui.bounty.claim_btn"),
			func() -> void:
				if bounties.claim_bounty(b.id):
					toast(Loc.t("ui.bounty.claim_success", {"reward": reward_str})),
			&"PrimaryButton",
			"" if can_claim else Loc.t("ui.bounty.not_ready")
		)
		claim_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
		claim_btn.custom_minimum_size = Vector2(80, GameTheme.TOUCH)
		claim_btn.disabled = claimed or not can_claim

		var info := UIKit.vbox([title_label, bar, reward_label], 3)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var card := UIKit.card(UIKit.hbox([info, claim_btn], 8))
		if can_claim:
			var card_style := GameTheme._box(Color(0.09, 0.13, 0.18, 0.95), Color(0.85, 0.72, 0.25, 0.8), 6, 1, 8)
			card_style.shadow_color = Color(0, 0, 0, 0.4)
			card_style.shadow_size = 4
			card.add_theme_stylebox_override(&"panel", card_style)
		content.add_child(card)
