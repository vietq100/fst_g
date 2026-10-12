class_name BuildingSheet
extends Sheet
## Building panel (UI_DESIGN.md → Building panel): name, level, function, upgrade cost and
## requirements, plus the building's own actions (Tavern recruits and cooks, Hospital makes
## medicine, Temple revives, Blacksmith crafts, Warehouse contents, Town Hall capacity, House
## residents) and Move / Remove (D33).

## The player wants to move this building; UIRoot forwards it to the world's placement mode.
signal move_requested(instance_id: StringName)

const DESCRIPTIONS := {
	&"town_hall": "The heart of the settlement. Its level sets how many Hunters you can keep and how far they can grow.",
	&"tavern": "Hunters looking for work gather here, rest and eat. The kitchen cooks food from monster materials; Hunters buy it when hungry.",
	&"blacksmith": "Forges better weapons and armor from materials.",
	&"hospital": "Makes medicine from monster materials. Hunters who come home hurt buy it and heal at once.",
	&"temple": "Fallen Hunters are revived here (they lose a little XP). Two village staff live here and carry bodies home for a fee.",
	&"warehouse": "Stores materials and spare equipment. More levels, more slots.",
	&"house": "Hunters sleep here. Every House has beds for four.",
	&"trading_post": "Post material requests. Hunters who bring the material home are paid a bounty on top of the normal price.",
	&"restaurant": "Hunters enjoy their meals more: every portion restores extra energy. Needs a Tavern to cook the food.",
	&"inn": "Rooms for weary Hunters: many beds in one building.",
	&"academy": "Train skills for gold. Rebirth points teach new traits.",
	&"forge": "Enhance weapons and armor. Each level makes the item stronger; the Forge's level sets the limit.",
	&"portal": "Hunters who reach the required level may reincarnate: back to level 1, permanently stronger, with rebirth points. Higher difficulties unlock with total reincarnations.",
}

## Request sizes offered by the Trading Post.
const ORDER_SIZES := [5, 10, 20]

var building_id: StringName
var instance_id: StringName
var _timer: Timer
var _confirm_remove := false
## Hunter chosen in the Academy / Portal pickers (kept across rebuilds).
var _picked: StringName


## `id` is a placed instance id, or a building type (its first instance).
func _init(id: StringName) -> void:
	var buildings := GameManager.buildings
	var placed := buildings.get_instance(id)
	if placed == null:
		placed = buildings.find_first(id)
	building_id = placed.building_id if placed != null else id
	instance_id = placed.instance_id if placed != null else &""


func _ready() -> void:
	super()
	if building_id == BuildingService.TEMPLE:
		# Live revival timers.
		_timer = Timer.new()
		_timer.wait_time = 1.0
		_timer.autostart = true
		_timer.timeout.connect(request_rebuild)
		add_child(_timer)


func _watch() -> Array:
	var gm := GameManager
	return [
		[gm.buildings, &"building_upgraded"], [gm.wallet, &"gold_changed"], [gm.inventory, &"inventory_changed"],
		[gm.recruitment, &"candidates_changed"], [gm.temple, &"hunter_recovered"], [gm.hunters, &"hunter_added"],
		[gm.housing, &"beds_changed"], [gm.trading, &"requests_changed"], [gm.hunters, &"hunter_changed"],
		[gm.reincarnation, &"difficulty_changed"],
	]


func _build(content: VBoxContainer) -> void:
	var buildings := GameManager.buildings
	var placed := buildings.get_instance(instance_id)
	if placed == null:
		set_title("Removed")
		content.add_child(UIKit.label("This building is gone.", &"MutedLabel"))
		return
	var definition := buildings.get_definition(building_id)
	set_title("%s  Lv %d" % [definition.display_name, placed.level])
	content.add_child(UIKit.label(DESCRIPTIONS.get(building_id, ""), &"MutedLabel"))
	_build_upgrade(content, buildings, definition, placed)
	_build_placement(content, buildings, definition)
	content.add_child(UIKit.separator())
	match building_id:
		BuildingService.TOWN_HALL:
			_build_town_hall(content)
		BuildingService.TAVERN:
			_build_recipes(content, "Kitchen", "Food in stock: %d portions. Hungry Hunters buy the most filling food they can afford." % GameManager.supply.get_food_stock())
			content.add_child(UIKit.separator())
			_build_tavern(content)
		BuildingService.HOSPITAL:
			_build_recipes(content, "Pharmacy", "Hunters who come home hurt buy the strongest medicine they can afford until they are above 90% HP.")
		BuildingService.TEMPLE:
			_build_temple(content)
		BuildingService.BLACKSMITH:
			_build_recipes(content, "Forge", "")
		BuildingService.WAREHOUSE:
			_build_warehouse(content)
		BuildingService.HOUSE, BuildingService.INN:
			_build_house(content, placed)
		BuildingService.RESTAURANT:
			content.add_child(UIKit.label("Meals give +%d%% energy." % roundi(GameManager.supply.get_food_bonus() * 100.0)))
		BuildingService.TRADING_POST:
			_build_trading_post(content)
		BuildingService.ACADEMY:
			_build_academy(content)
		BuildingService.FORGE:
			_build_forge(content)
		BuildingService.PORTAL:
			_build_portal(content)


func _build_upgrade(content: VBoxContainer, buildings: BuildingService, definition: BuildingDefinition,
		placed: BuildingService.Placed) -> void:
	var next := buildings.get_instance_next_level(instance_id)
	if next == null:
		content.add_child(UIKit.label("Max level (%d)." % definition.get_max_level(), &"MutedLabel"))
		return
	var costs := PackedStringArray(["%d gold" % next.gold_cost])
	for cost in next.material_costs:
		costs.append("%d %s" % [cost.quantity, DataRegistry.get_item(cost.item_id).display_name])
	var reason := buildings.can_upgrade_instance(instance_id)
	var box := UIKit.vbox([
		UIKit.label("Upgrade to Lv %d: %s" % [placed.level + 1, ", ".join(costs)]),
		UIKit.label(_describe_next(next, placed.level + 1), &"MutedLabel"),
	])
	if not reason.is_empty():
		box.add_child(UIKit.label(reason, &"WarningLabel"))
	box.add_child(UIKit.button("Upgrade", func() -> void:
		run_action("" if buildings.upgrade_instance(instance_id) else buildings.can_upgrade_instance(instance_id),
			"%s upgraded" % definition.display_name), &"PrimaryButton", reason))
	content.add_child(UIKit.card(box))


## Move / Remove (D33). Removing asks twice and refunds part of the build cost.
func _build_placement(content: VBoxContainer, buildings: BuildingService, definition: BuildingDefinition) -> void:
	var move := UIKit.button("Move", func() -> void: move_requested.emit(instance_id))
	var remove_reason := buildings.can_remove(instance_id)
	var remove_text := "Remove (+%d g)" % buildings.get_refund(instance_id)
	if _confirm_remove:
		remove_text = "Tap again to remove"
	var remove := UIKit.button(remove_text, func() -> void:
		if not _confirm_remove:
			_confirm_remove = true
			request_rebuild()
			return
		var error := buildings.remove(instance_id)
		run_action(error, "%s removed" % definition.display_name)
		if error.is_empty():
			closed.emit(), &"" if not _confirm_remove else &"PrimaryButton", remove_reason)
	content.add_child(UIKit.hbox([move, remove]))


## Effects of the next level plus the recipes it unlocks.
func _describe_next(next: BuildingLevel, level: int) -> String:
	var parts := PackedStringArray()
	if not next.effects.is_empty():
		parts.append(_describe_effects(next.effects).trim_prefix("Next: "))
	for recipe in GameManager.crafting.get_recipes(building_id):
		if recipe.required_level == level:
			parts.append("unlocks %s" % recipe.display_name)
	return "Next: " + (", ".join(parts) if not parts.is_empty() else "—")


static func _describe_effects(effects: Dictionary) -> String:
	var parts := PackedStringArray()
	for key in effects:
		var value: float = effects[key]
		parts.append("%s %s" % [String(key).capitalize(), str(int(value)) if is_equal_approx(value, roundf(value)) else str(snappedf(value, 0.01))])
	return "Next: " + ", ".join(parts)


func _build_town_hall(content: VBoxContainer) -> void:
	var gm := GameManager
	content.add_child(UIKit.label("Hunters %d / %d\nHunter level cap %d\nTown level %d" % [
		gm.hunters.count(), gm.recruitment.get_capacity(), gm.stats.level_cap(gm.progress.town_level), gm.progress.town_level]))


func _build_tavern(content: VBoxContainer) -> void:
	var recruitment := GameManager.recruitment
	var hunters := GameManager.hunters
	content.add_child(UIKit.label("Candidates", &"AccentLabel"))
	if recruitment.candidates.is_empty():
		content.add_child(UIKit.label("Nobody is looking for work right now.", &"MutedLabel"))
	for i in recruitment.candidates.size():
		var candidate := recruitment.candidates[i]
		var traits := PackedStringArray()
		for definition in GameManager.traits.get_traits(candidate):
			traits.append(definition.display_name)
		var info := UIKit.vbox([
			UIKit.label("%s — %s" % [candidate.display_name, hunters.get_definition(candidate).display_name]),
			UIKit.label("Traits: %s%s" % [", ".join(traits), "  ·  Talent: %s" % GameManager.talents.get_talent(candidate).display_name if GameManager.talents.get_talent(candidate) != null else ""], &"AccentLabel"),
			UIKit.label("HP %d · ATK %.1f · DEF %.1f" % [hunters.get_stat(candidate, HunterService.MAX_HP),
				hunters.get_stat(candidate, HunterService.ATTACK), hunters.get_stat(candidate, HunterService.DEFENSE)], &"MutedLabel"),
		], 2)
		var portrait := HunterPortrait.new().setup(candidate, null)
		var recruit := UIKit.button("Hire\n%d g" % recruitment.get_recruit_cost(i), func() -> void:
			var hunter := recruitment.recruit(i)
			run_action("" if hunter != null else recruitment.can_recruit(i),
				"%s joined the roster" % hunter.display_name if hunter != null else ""), &"PrimaryButton", recruitment.can_recruit(i))
		recruit.size_flags_horizontal = Control.SIZE_SHRINK_END
		recruit.custom_minimum_size.x = 64
		content.add_child(UIKit.card(UIKit.hbox([portrait, info, recruit])))
	var blocked := recruitment.can_recruit(0) if not recruitment.candidates.is_empty() else ""
	if blocked.begins_with("Roster full"):
		content.add_child(UIKit.label(blocked, &"WarningLabel"))
	var cost := recruitment.get_refresh_cost()
	content.add_child(UIKit.button("New candidates (%d gold)" % cost, func() -> void:
		run_action("" if recruitment.paid_refresh() else "Needs %d gold" % cost),
		&"", "" if GameManager.wallet.can_spend(cost) else "Needs %d gold" % cost))
	content.add_child(UIKit.label("Candidates also change after every expedition.", &"MutedLabel"))


func _build_temple(content: VBoxContainer) -> void:
	var temple := GameManager.temple
	content.add_child(UIKit.label("Revival takes %s and costs %d%% of the XP of the Hunter's level." % [
		UIKit.format_duration(temple.get_recovery_seconds()), roundi(DataRegistry.config.revive_xp_loss_ratio * 100.0)], &"MutedLabel"))
	var patients := GameManager.hunters.get_all().filter(func(h: HunterRuntime) -> bool: return h.injured)
	if patients.is_empty():
		content.add_child(UIKit.label("Nobody is waiting to be revived."))
	for runtime: HunterRuntime in patients:
		var remaining := temple.get_remaining(runtime)
		var total := temple.get_recovery_seconds()
		var cost := temple.get_speed_up_cost(runtime)
		var info := UIKit.vbox([
			UIKit.label("%s  (−%d XP)" % [runtime.display_name, temple.get_xp_loss(runtime)]),
			UIKit.bar(total - remaining, total, &"TimerBar", "%s left" % UIKit.format_duration(remaining)),
		], 2)
		var speed := UIKit.button("Revive now\n%d g" % cost, func() -> void:
			run_action("" if temple.speed_up(runtime) else "Needs %d gold" % cost, "%s is back" % runtime.display_name),
			&"PrimaryButton", "" if GameManager.wallet.can_spend(cost) else "Needs %d gold" % cost)
		speed.size_flags_horizontal = Control.SIZE_SHRINK_END
		speed.custom_minimum_size.x = 72
		content.add_child(UIKit.card(UIKit.hbox([HunterPortrait.new().setup(runtime, GameManager.equipment), info, speed])))
	content.add_child(UIKit.separator())
	content.add_child(UIKit.label(GameManager.corpses.describe_staff(), &"MutedLabel"))


## Crafting list of this building (Blacksmith equipment, Tavern food, Hospital medicine).
func _build_recipes(content: VBoxContainer, heading: String, note: String) -> void:
	var crafting := GameManager.crafting
	content.add_child(UIKit.label(heading, &"AccentLabel"))
	if not note.is_empty():
		content.add_child(UIKit.label(note, &"MutedLabel"))
	for recipe in crafting.get_recipes(building_id):
		var item := DataRegistry.get_item(recipe.result_item_id)
		var costs := PackedStringArray()
		if recipe.gold_cost > 0:
			costs.append("%d g" % recipe.gold_cost)
		for cost in recipe.material_costs:
			costs.append("%d %s (have %d)" % [cost.quantity, DataRegistry.get_item(cost.item_id).display_name,
				GameManager.inventory.count(cost.item_id)])
		var reason := crafting.can_craft(recipe.id)
		var title := "%s%s" % [item.display_name, " ×%d" % recipe.result_quantity if recipe.result_quantity > 1 else ""]
		var effect := UIKit.describe_modifiers(item) if item.item_type != ItemDefinition.ItemType.CONSUMABLE else _describe_consumable(item)
		var name_label := UIKit.label("%s · %s" % [title, UIKit.rarity_name(item)])
		name_label.add_theme_color_override(&"font_color", RarityColors.of(item.rarity))
		var info := UIKit.vbox([name_label, UIKit.label(effect, &"AccentLabel"), UIKit.label(", ".join(costs), &"MutedLabel")], 2)
		if not reason.is_empty():
			info.add_child(UIKit.label(reason, &"WarningLabel"))
		var craft := UIKit.button("Make" if item.stackable else "Craft", func() -> void:
			run_action("" if crafting.craft(recipe.id) != &"" else crafting.can_craft(recipe.id),
				"Made %s" % title), &"PrimaryButton", reason)
		craft.size_flags_horizontal = Control.SIZE_SHRINK_END
		craft.custom_minimum_size.x = 64
		content.add_child(UIKit.card(UIKit.hbox([UIKit.swatch(RarityColors.of(item.rarity), 14), info, craft])))


static func _describe_consumable(item: ItemDefinition) -> String:
	var parts := PackedStringArray()
	if item.energy > 0.0:
		parts.append("+%d energy" % roundi(item.energy))
	if item.heal_ratio > 0.0:
		parts.append("heals %d%% HP" % roundi(item.heal_ratio * 100.0))
	parts.append("Hunters pay %d g · in stock %d" % [item.sell_price, GameManager.inventory.count(item.id)])
	return " · ".join(parts)


func _build_warehouse(content: VBoxContainer) -> void:
	var inventory := GameManager.inventory
	content.add_child(UIKit.bar(inventory.used_slots(), inventory.capacity, &"TimerBar",
		"Slots %d / %d" % [inventory.used_slots(), inventory.capacity]))
	content.add_child(UIKit.button("Open inventory", func() -> void: open_requested.emit(InventorySheet.new())))


func _build_house(content: VBoxContainer, placed: BuildingService.Placed) -> void:
	var housing := GameManager.housing
	var residents := GameManager.hunters.get_all().filter(func(h: HunterRuntime) -> bool:
		var home := housing.get_home(h)
		return home != null and home.instance_id == placed.instance_id)
	var beds := int(GameManager.buildings.get_instance_effect(placed, BuildingService.BEDS))
	content.add_child(UIKit.label("Beds %d / %d" % [residents.size(), beds]))
	for runtime: HunterRuntime in residents:
		content.add_child(UIKit.label("· %s" % runtime.display_name, &"MutedLabel"))
	content.add_child(UIKit.label("Town beds: %d free of %d" % [housing.get_free_beds(), housing.get_total_beds()], &"MutedLabel"))


# --- Evil Hunter Tycoon style buildings -------------------------------------------------------------

func _build_trading_post(content: VBoxContainer) -> void:
	var trading := GameManager.trading
	content.add_child(UIKit.label("Requests %d / %d" % [trading.requests.size(), trading.get_slots()], &"AccentLabel"))
	if trading.requests.is_empty():
		content.add_child(UIKit.label("No open requests. Order a material below.", &"MutedLabel"))
	for i in trading.requests.size():
		var request: Dictionary = trading.requests[i]
		var item := DataRegistry.get_item(request["item_id"])
		var info := UIKit.vbox([
			UIKit.label("%s ×%d" % [item.display_name, request["quantity"]]),
			UIKit.bar(request["delivered"], request["quantity"], &"TimerBar", "%d / %d delivered" % [request["delivered"], request["quantity"]]),
			UIKit.label("Bounty +%d g each for the Hunter who brings it" % trading.get_bounty(item.id), &"MutedLabel"),
		], 2)
		var cancel := UIKit.button("Cancel", func() -> void:
			trading.cancel(i)
			request_rebuild())
		cancel.size_flags_horizontal = Control.SIZE_SHRINK_END
		cancel.custom_minimum_size.x = 64
		content.add_child(UIKit.card(UIKit.hbox([info, cancel])))
	content.add_child(UIKit.separator())
	content.add_child(UIKit.label("Order materials", &"AccentLabel"))
	for item in trading.get_orderable_items():
		var buttons := UIKit.hbox([], 4)
		for size: int in ORDER_SIZES:
			var reason := trading.can_order(item.id, size)
			var order := UIKit.button("×%d" % size, func() -> void:
				run_action("" if trading.order(item.id, size) else trading.can_order(item.id, size),
					"Requested %d %s" % [size, item.display_name]), &"PrimaryButton", reason)
			order.custom_minimum_size.x = 48
			buttons.add_child(order)
		var info := UIKit.vbox([
			UIKit.label("%s · price %d g · in stock %d" % [item.display_name, item.sell_price, GameManager.inventory.count(item.id)]),
		], 2)
		content.add_child(UIKit.card(UIKit.hbox([info, buttons])))


## Dropdown of the roster; returns the chosen Hunter (kept in `_picked`).
func _hunter_picker(content: VBoxContainer) -> HunterRuntime:
	var roster := GameManager.hunters.get_all()
	if roster.is_empty():
		content.add_child(UIKit.label("No Hunters.", &"MutedLabel"))
		return null
	var chosen := GameManager.hunters.get_hunter(_picked)
	if chosen == null:
		chosen = roster[0]
		_picked = chosen.unique_id
	var picker := OptionButton.new()
	picker.custom_minimum_size.y = GameTheme.TOUCH
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in roster.size():
		picker.add_item("%s · Lv %d" % [roster[i].display_name, roster[i].level])
		if roster[i] == chosen:
			picker.select(i)
	picker.item_selected.connect(func(index: int) -> void:
		_picked = roster[index].unique_id
		request_rebuild())
	content.add_child(picker)
	return chosen


func _build_academy(content: VBoxContainer) -> void:
	var academy := GameManager.academy
	var hunter := _hunter_picker(content)
	if hunter == null:
		return
	content.add_child(UIKit.label("Rebirth points: %d · Trait slots %d / %d" % [
		hunter.rebirth_points, hunter.trait_ids.size(), academy.get_max_traits()], &"AccentLabel"))
	var promotions := academy.get_promotions(hunter)
	if not promotions.is_empty():
		content.add_child(UIKit.label("Class change (needs %d reincarnations, %d g)" % [AcademyService.PROMOTION_REINCARNATIONS, AcademyService.PROMOTION_COST], &"AccentLabel"))
		for target in promotions:
			var reason := academy.can_change_class(hunter, target.id)
			var change := UIKit.button("Become\n%s" % target.display_name, func() -> void:
				run_action("" if academy.change_class(hunter, target.id) else academy.can_change_class(hunter, target.id),
					"%s is now a %s" % [hunter.display_name, target.display_name]), &"PrimaryButton", reason)
			content.add_child(change)
	content.add_child(UIKit.label("Skills", &"AccentLabel"))
	for skill in academy.get_skills():
		var level := academy.get_skill_level(hunter, skill.id)
		var reason := academy.can_learn_skill(hunter, skill.id)
		var info := UIKit.vbox([
			UIKit.label("%s  %d / %d" % [skill.display_name, level, skill.max_level]),
			UIKit.label(skill.description, &"MutedLabel"),
		], 2)
		if not reason.is_empty() and level < skill.max_level:
			info.add_child(UIKit.label(reason, &"WarningLabel"))
		var learn := UIKit.button("Train\n%d g" % academy.get_next_skill_cost(hunter, skill) if level < skill.max_level else "Max",
			func() -> void:
				run_action("" if academy.learn_skill(hunter, skill.id) else academy.can_learn_skill(hunter, skill.id),
					"%s trained" % skill.display_name), &"PrimaryButton", reason)
		learn.size_flags_horizontal = Control.SIZE_SHRINK_END
		learn.custom_minimum_size.x = 64
		content.add_child(UIKit.card(UIKit.hbox([info, learn])))
	content.add_child(UIKit.separator())
	content.add_child(UIKit.label("Known traits", &"AccentLabel"))
	for trait_def in GameManager.traits.get_traits(hunter):
		var forget := UIKit.button("Forget\n%d g" % AcademyService.FORGET_COST, func() -> void:
			run_action("" if academy.forget_trait(hunter, trait_def.id) else academy.can_forget_trait(hunter, trait_def.id),
				"%s forgotten" % trait_def.display_name), &"", academy.can_forget_trait(hunter, trait_def.id))
		forget.size_flags_horizontal = Control.SIZE_SHRINK_END
		forget.custom_minimum_size.x = 72
		content.add_child(UIKit.card(UIKit.hbox([UIKit.vbox([UIKit.label(trait_def.display_name), UIKit.label(trait_def.description, &"MutedLabel")], 2), forget])))
	content.add_child(UIKit.label("Learn a trait (rebirth points)", &"AccentLabel"))
	for trait_def in academy.get_learnable_traits(hunter):
		var reason := academy.can_learn_trait(hunter, trait_def.id)
		var learn := UIKit.button("Learn\n%d pt" % trait_def.academy_cost, func() -> void:
			run_action("" if academy.learn_trait(hunter, trait_def.id) else academy.can_learn_trait(hunter, trait_def.id),
				"%s learned" % trait_def.display_name), &"PrimaryButton", reason)
		learn.size_flags_horizontal = Control.SIZE_SHRINK_END
		learn.custom_minimum_size.x = 64
		content.add_child(UIKit.card(UIKit.hbox([UIKit.vbox([UIKit.label(trait_def.display_name), UIKit.label(trait_def.description, &"MutedLabel")], 2), learn])))


func _build_forge(content: VBoxContainer) -> void:
	var forge := GameManager.forge
	var inventory := GameManager.inventory
	content.add_child(UIKit.label("Enhancement limit: +%d · Iron Ore: %d" % [forge.get_max_level(), inventory.count(ForgeService.ORE)], &"AccentLabel"))
	var entries: Array = []
	for instance_id in inventory.get_equipped():
		var wearer := GameManager.hunters.get_hunter(inventory.get_equipped()[instance_id])
		entries.append([instance_id, "worn by %s" % wearer.display_name if wearer != null else "worn"])
	for instance_id in inventory.get_instances():
		entries.append([instance_id, "in the Warehouse"])
	if entries.is_empty():
		content.add_child(UIKit.label("No equipment to enhance.", &"MutedLabel"))
	for entry in entries:
		var instance_id: StringName = entry[0]
		var item := GameManager.equipment.get_item(instance_id)
		if item == null or item.equipment_slot == ItemDefinition.EquipmentSlot.NONE:
			continue
		var level := forge.get_level(instance_id)
		var reason := forge.can_enhance(instance_id)
		var name_label := UIKit.label("%s%s · %s" % [item.display_name, " +%d" % level if level > 0 else "", entry[1]])
		name_label.add_theme_color_override(&"font_color", RarityColors.of(item.rarity))
		var info := UIKit.vbox([name_label, UIKit.label(UIKit.describe_modifiers(item), &"AccentLabel"),
			UIKit.label("Next: %d g + %d Iron Ore" % [forge.get_gold_cost(instance_id), forge.get_ore_cost(instance_id)], &"MutedLabel")], 2)
		if not reason.is_empty():
			info.add_child(UIKit.label(reason, &"WarningLabel"))
		var enhance := UIKit.button("Enhance", func() -> void:
			run_action("" if forge.enhance(instance_id) else forge.can_enhance(instance_id), "%s enhanced" % item.display_name),
			&"PrimaryButton", reason)
		enhance.size_flags_horizontal = Control.SIZE_SHRINK_END
		enhance.custom_minimum_size.x = 72
		content.add_child(UIKit.card(UIKit.hbox([UIKit.swatch(RarityColors.of(item.rarity), 14), info, enhance])))


func _build_portal(content: VBoxContainer) -> void:
	var gm := GameManager
	var rein := gm.reincarnation
	content.add_child(UIKit.label("Difficulty", &"AccentLabel"))
	content.add_child(UIKit.label("Total reincarnations: %d" % gm.progress.total_reincarnations, &"MutedLabel"))
	var row := UIKit.hbox([], 4)
	for difficulty in rein.get_difficulty_count():
		var unlocked := rein.is_unlocked(difficulty)
		var label := rein.get_difficulty_name(difficulty) if unlocked else "%s\n(%d)" % [rein.get_difficulty_name(difficulty), rein.get_unlock_requirement(difficulty)]
		var button := UIKit.button(label, func() -> void:
			run_action(rein.set_difficulty(difficulty)), &"SelectedButton" if gm.progress.difficulty == difficulty else &"",
			"" if unlocked else "Locked")
		row.add_child(button)
	content.add_child(row)
	content.add_child(UIKit.label("Monsters are %.1f× stronger and give %.1f× rewards." % [
		DataRegistry.config.difficulty_stat_scale[clampi(gm.progress.difficulty, 0, DataRegistry.config.difficulty_stat_scale.size() - 1)],
		DataRegistry.config.difficulty_reward_scale[clampi(gm.progress.difficulty, 0, DataRegistry.config.difficulty_reward_scale.size() - 1)]], &"MutedLabel"))
	content.add_child(UIKit.separator())
	content.add_child(UIKit.label("Reincarnate a Hunter", &"AccentLabel"))
	for runtime: HunterRuntime in gm.hunters.get_all():
		var reason := rein.can_reincarnate(runtime)
		var info := UIKit.vbox([
			UIKit.label("%s · Lv %d · reborn %d×" % [runtime.display_name, runtime.level, runtime.reincarnations]),
			UIKit.label("+%d%% HP/ATK/DEF per rebirth · +%d point(s) next" % [roundi(DataRegistry.config.reincarnation_stat_bonus * 100.0), rein.points_for_next(runtime)], &"MutedLabel"),
		], 2)
		if not reason.is_empty():
			info.add_child(UIKit.label(reason, &"WarningLabel"))
		var go := UIKit.button("Reincarnate", func() -> void:
			run_action("" if rein.reincarnate(runtime) else rein.can_reincarnate(runtime), "%s was reborn" % runtime.display_name),
			&"PrimaryButton", reason)
		go.size_flags_horizontal = Control.SIZE_SHRINK_END
		go.custom_minimum_size.x = 88
		content.add_child(UIKit.card(UIKit.hbox([info, go])))
