class_name BuildingSheet
extends Sheet
## Building panel (UI_DESIGN.md → Building panel): name, level, function, upgrade cost and
## requirements, plus the building's own actions (Tavern recruits, Hospital recovery, Blacksmith
## crafting, Warehouse contents, Town Hall capacity).

const DESCRIPTIONS := {
	&"town_hall": "The heart of the settlement. Its level sets how many Hunters you can keep and how far they can grow.",
	&"tavern": "Hunters looking for work gather here. Rest and socializing also happen here.",
	&"blacksmith": "Forges better weapons and armor from materials.",
	&"hospital": "Injured Hunters recover here over time.",
	&"warehouse": "Stores materials and spare equipment. More levels, more slots.",
}

var building_id: StringName
var _timer: Timer


func _init(id: StringName) -> void:
	building_id = id


func _ready() -> void:
	super()
	if building_id == BuildingService.HOSPITAL:
		# Live recovery timers.
		_timer = Timer.new()
		_timer.wait_time = 1.0
		_timer.autostart = true
		_timer.timeout.connect(request_rebuild)
		add_child(_timer)


func _watch() -> Array:
	var gm := GameManager
	return [
		[gm.buildings, &"building_upgraded"], [gm.wallet, &"gold_changed"], [gm.inventory, &"inventory_changed"],
		[gm.recruitment, &"candidates_changed"], [gm.hospital, &"hunter_recovered"], [gm.hunters, &"hunter_added"],
	]


func _build(content: VBoxContainer) -> void:
	var buildings := GameManager.buildings
	var definition := buildings.get_definition(building_id)
	set_title("%s  Lv %d" % [definition.display_name, buildings.get_level(building_id)])
	content.add_child(UIKit.label(DESCRIPTIONS.get(building_id, ""), &"MutedLabel"))
	_build_upgrade(content, buildings, definition)
	content.add_child(UIKit.separator())
	match building_id:
		BuildingService.TOWN_HALL:
			_build_town_hall(content)
		BuildingService.TAVERN:
			_build_tavern(content)
		BuildingService.HOSPITAL:
			_build_hospital(content)
		BuildingService.BLACKSMITH:
			_build_blacksmith(content)
		BuildingService.WAREHOUSE:
			_build_warehouse(content)


func _build_upgrade(content: VBoxContainer, buildings: BuildingService, definition: BuildingDefinition) -> void:
	var next := buildings.get_next_level(building_id)
	if next == null:
		content.add_child(UIKit.label("Max level (%d)." % definition.get_max_level(), &"MutedLabel"))
		return
	var costs := PackedStringArray(["%d gold" % next.gold_cost])
	for cost in next.material_costs:
		costs.append("%d %s" % [cost.quantity, DataRegistry.get_item(cost.item_id).display_name])
	var reason := buildings.can_upgrade(building_id)
	var box := UIKit.vbox([
		UIKit.label("Upgrade to Lv %d: %s" % [buildings.get_level(building_id) + 1, ", ".join(costs)]),
		UIKit.label(_describe_effects(next.effects), &"MutedLabel"),
	])
	if not reason.is_empty():
		box.add_child(UIKit.label(reason, &"WarningLabel"))
	box.add_child(UIKit.button("Upgrade", func() -> void:
		run_action("" if buildings.upgrade(building_id) else buildings.can_upgrade(building_id),
			"%s upgraded" % definition.display_name), &"PrimaryButton", reason))
	content.add_child(UIKit.card(box))


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
			UIKit.label("Traits: %s" % ", ".join(traits), &"AccentLabel"),
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


func _build_hospital(content: VBoxContainer) -> void:
	var hospital := GameManager.hospital
	var injured := GameManager.hunters.get_all().filter(func(h: HunterRuntime) -> bool: return h.injured)
	content.add_child(UIKit.label("Recovery takes %s." % UIKit.format_duration(hospital.get_recovery_seconds()), &"MutedLabel"))
	if injured.is_empty():
		content.add_child(UIKit.label("No injured Hunters."))
	for runtime: HunterRuntime in injured:
		var remaining := hospital.get_remaining(runtime)
		var total := hospital.get_recovery_seconds()
		var cost := hospital.get_speed_up_cost(runtime)
		var info := UIKit.vbox([
			UIKit.label(runtime.display_name),
			UIKit.bar(total - remaining, total, &"TimerBar", "%s left" % UIKit.format_duration(remaining)),
		], 2)
		var speed := UIKit.button("Heal now\n%d g" % cost, func() -> void:
			run_action("" if hospital.speed_up(runtime) else "Needs %d gold" % cost, "%s recovered" % runtime.display_name),
			&"PrimaryButton", "" if GameManager.wallet.can_spend(cost) else "Needs %d gold" % cost)
		speed.size_flags_horizontal = Control.SIZE_SHRINK_END
		speed.custom_minimum_size.x = 72
		content.add_child(UIKit.card(UIKit.hbox([HunterPortrait.new().setup(runtime, GameManager.equipment), info, speed])))


func _build_blacksmith(content: VBoxContainer) -> void:
	var crafting := GameManager.crafting
	for recipe in crafting.get_recipes():
		var item := DataRegistry.get_item(recipe.result_item_id)
		var costs := PackedStringArray(["%d g" % recipe.gold_cost])
		for cost in recipe.material_costs:
			costs.append("%d %s (have %d)" % [cost.quantity, DataRegistry.get_item(cost.item_id).display_name,
				GameManager.inventory.count(cost.item_id)])
		var reason := crafting.can_craft(recipe.id)
		var name_label := UIKit.label("%s · %s" % [item.display_name, UIKit.rarity_name(item)])
		name_label.add_theme_color_override(&"font_color", RarityColors.of(item.rarity))
		var info := UIKit.vbox([name_label, UIKit.label(UIKit.describe_modifiers(item), &"AccentLabel"),
			UIKit.label(", ".join(costs), &"MutedLabel")], 2)
		if not reason.is_empty():
			info.add_child(UIKit.label(reason, &"WarningLabel"))
		var craft := UIKit.button("Craft", func() -> void:
			run_action("" if crafting.craft(recipe.id) != &"" else crafting.can_craft(recipe.id),
				"Crafted %s" % item.display_name), &"PrimaryButton", reason)
		craft.size_flags_horizontal = Control.SIZE_SHRINK_END
		craft.custom_minimum_size.x = 64
		content.add_child(UIKit.card(UIKit.hbox([UIKit.swatch(RarityColors.of(item.rarity), 14), info, craft])))


func _build_warehouse(content: VBoxContainer) -> void:
	var inventory := GameManager.inventory
	content.add_child(UIKit.bar(inventory.used_slots(), inventory.capacity, &"TimerBar",
		"Slots %d / %d" % [inventory.used_slots(), inventory.capacity]))
	content.add_child(UIKit.button("Open inventory", func() -> void: open_requested.emit(InventorySheet.new())))
