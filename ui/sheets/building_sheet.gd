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
}

var building_id: StringName
var instance_id: StringName
var _timer: Timer
var _confirm_remove := false


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
		[gm.housing, &"beds_changed"],
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
		BuildingService.HOUSE:
			_build_house(content, placed)


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
