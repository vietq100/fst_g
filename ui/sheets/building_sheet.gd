class_name BuildingSheet
extends Sheet
## Building panel (UI_DESIGN.md → Building panel): name, level, function, upgrade cost and
## requirements, plus the building's own actions (Tavern recruits and cooks, Hospital makes
## medicine, Temple revives, Blacksmith crafts, Warehouse contents, Town Hall capacity, House
## residents) and Move / Remove (D33).

## The player wants to move this building; UIRoot forwards it to the world's placement mode.
signal move_requested(instance_id: StringName)

## Description keys of the building types (translated by `describe`).
const DESCRIPTIONS := {
	&"town_hall": "ui.building.desc.town_hall",
	&"market": "ui.building.desc.market",
	&"tavern": "ui.building.desc.tavern",
	&"blacksmith": "ui.building.desc.blacksmith",
	&"hospital": "ui.building.desc.hospital",
	&"temple": "ui.building.desc.temple",
	&"warehouse": "ui.building.desc.warehouse",
	&"house": "ui.building.desc.house",
	&"trading_post": "ui.building.desc.trading_post",
	&"restaurant": "ui.building.desc.restaurant",
	&"colosseum": "ui.building.desc.colosseum",
	&"inn": "ui.building.desc.inn",
	&"academy": "ui.building.desc.academy",
	&"forge": "ui.building.desc.forge",
	&"portal": "ui.building.desc.portal",
}


## Translated description of a building type ("" when it has none).
static func describe(id: StringName) -> String:
	var key: String = DESCRIPTIONS.get(id, "")
	return Loc.t(key) if not key.is_empty() else ""


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
		[gm.reincarnation, &"difficulty_changed"], [gm.regions, &"loot_bag_changed"],
	]


func _build(content: VBoxContainer) -> void:
	var buildings := GameManager.buildings
	var placed := buildings.get_instance(instance_id)
	if placed == null:
		set_title(Loc.t("ui.building.removed_title"))
		content.add_child(UIKit.label(Loc.t("ui.building.gone"), &"MutedLabel"))
		return
	var definition := buildings.get_definition(building_id)
	set_title(Loc.t("ui.building.title", {"name": definition.display_name, "level": placed.level}))
	content.add_child(UIKit.label(describe(building_id), &"MutedLabel"))
	_build_upgrade(content, buildings, definition, placed)
	_build_placement(content, buildings, definition)
	content.add_child(UIKit.separator())
	match building_id:
		BuildingService.TOWN_HALL:
			_build_town_hall(content)
		BuildingService.TAVERN:
			_build_recipes(content, Loc.t("ui.building.kitchen"), Loc.t("ui.building.kitchen_note", {"count": GameManager.supply.get_food_stock()}))
			content.add_child(UIKit.separator())
			_build_tavern(content)
		BuildingService.HOSPITAL:
			_build_recipes(content, Loc.t("ui.building.pharmacy"), Loc.t("ui.building.pharmacy_note"))
		BuildingService.TEMPLE:
			_build_temple(content)
		BuildingService.BLACKSMITH:
			_build_repairs(content)
			content.add_child(UIKit.separator())
			_build_recipes(content, Loc.t("ui.building.forge_heading"), "")
		BuildingService.WAREHOUSE:
			_build_warehouse(content)
		BuildingService.HOUSE, BuildingService.INN:
			_build_house(content, placed)
		BuildingService.COLOSSEUM:
			content.add_child(UIKit.label(Loc.t("ui.building.colosseum_formats", {"size": int(GameManager.buildings.get_effect(BuildingService.COLOSSEUM, BuildingService.COLOSSEUM_FORMAT, 1.0))})))
			content.add_child(UIKit.button(Loc.t("ui.building.colosseum_enter"), func() -> void: open_requested.emit(ColosseumSheet.new()), &"PrimaryButton"))
		BuildingService.RESTAURANT:
			content.add_child(UIKit.label(Loc.t("ui.building.restaurant_bonus", {"percent": roundi(GameManager.supply.get_food_bonus() * 100.0)})))
		BuildingService.MARKET:
			_build_market(content)
		BuildingService.TRADING_POST:
			_build_trading_post(content)
			content.add_child(UIKit.separator())
			_build_recipes(content, Loc.t("ui.building.boutique"), Loc.t("ui.building.boutique_note"))
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
		content.add_child(UIKit.label(Loc.t("ui.building.max_level", {"level": definition.get_max_level()}), &"MutedLabel"))
		return
	var costs := PackedStringArray([Loc.t("ui.common.gold", {"gold": next.gold_cost})])
	for cost in next.material_costs:
		costs.append(Loc.t("ui.building.material_cost", {"count": cost.quantity, "item": DataRegistry.get_item(cost.item_id).display_name}))
	var reason := buildings.can_upgrade_instance(instance_id)
	var box := UIKit.vbox([
		UIKit.label(Loc.t("ui.building.upgrade_to", {"level": placed.level + 1, "costs": ", ".join(costs)})),
		UIKit.label(_describe_next(next, placed.level + 1), &"MutedLabel"),
	])
	if not reason.is_empty():
		box.add_child(UIKit.label(reason, &"WarningLabel"))
	box.add_child(UIKit.button(Loc.t("ui.building.upgrade"), func() -> void:
		run_action("" if buildings.upgrade_instance(instance_id) else buildings.can_upgrade_instance(instance_id),
			Loc.t("ui.building.upgraded", {"name": definition.display_name})), &"PrimaryButton", reason))
	content.add_child(UIKit.card(box))


## Move / Remove (D33). Removing asks twice and refunds part of the build cost.
func _build_placement(content: VBoxContainer, buildings: BuildingService, definition: BuildingDefinition) -> void:
	var move := UIKit.button(Loc.t("ui.building.move"), func() -> void: move_requested.emit(instance_id))
	var remove_reason := buildings.can_remove(instance_id)
	var remove_text := Loc.t("ui.building.remove_refund", {"gold": buildings.get_refund(instance_id)})
	if _confirm_remove:
		remove_text = Loc.t("ui.building.remove_confirm")
	var remove := UIKit.button(remove_text, func() -> void:
		if not _confirm_remove:
			_confirm_remove = true
			request_rebuild()
			return
		var error := buildings.remove(instance_id)
		run_action(error, Loc.t("ui.building.removed", {"name": definition.display_name}))
		if error.is_empty():
			closed.emit(), &"" if not _confirm_remove else &"PrimaryButton", remove_reason)
	content.add_child(UIKit.hbox([move, remove]))


## Effects of the next level plus the recipes it unlocks.
func _describe_next(next: BuildingLevel, level: int) -> String:
	var parts := PackedStringArray()
	if not next.effects.is_empty():
		parts.append_array(_effect_parts(next.effects))
	for recipe in GameManager.crafting.get_recipes(building_id):
		if recipe.required_level == level:
			parts.append(Loc.t("ui.building.unlocks", {"recipe": recipe.display_name}))
	return Loc.t("ui.building.next", {"effects": ", ".join(parts) if not parts.is_empty() else "—"})


static func _describe_effects(effects: Dictionary) -> String:
	return Loc.t("ui.building.next", {"effects": ", ".join(_effect_parts(effects))})


## One "Name value" text per effect (names are keys `ui.building.effect.<effect_id>`).
static func _effect_parts(effects: Dictionary) -> PackedStringArray:
	var parts := PackedStringArray()
	for key in effects:
		var value: float = effects[key]
		var shown := str(int(value)) if is_equal_approx(value, roundf(value)) else str(snappedf(value, 0.01))
		# Ratios read as percentages (the Market's buy price, D63).
		if key == BuildingService.BUY_PRICE:
			shown = "%d%%" % roundi(value * 100.0)
		parts.append(Loc.t("ui.building.effect_value", {"name": Loc.t("ui.building.effect.%s" % key), "value": shown}))
	return parts


func _build_town_hall(content: VBoxContainer) -> void:
	var gm := GameManager
	content.add_child(UIKit.label(Loc.t("ui.building.town_hall_info", {"hunters": gm.hunters.count(), "capacity": gm.recruitment.get_capacity(),
		"cap": gm.stats.level_cap(gm.progress.town_level), "town_level": gm.progress.town_level})))


func _build_tavern(content: VBoxContainer) -> void:
	var recruitment := GameManager.recruitment
	content.add_child(UIKit.label(Loc.t("ui.building.tavern_note")))
	content.add_child(UIKit.label(Loc.t("ui.building.candidates.one" if recruitment.candidates.size() == 1 else "ui.building.candidates.other",
		{"count": recruitment.candidates.size()}), &"MutedLabel"))
	content.add_child(UIKit.button(Loc.t("ui.building.open_gate"), func() -> void: open_requested.emit(GateSheet.new()), &"PrimaryButton"))


func _build_temple(content: VBoxContainer) -> void:
	var temple := GameManager.temple
	content.add_child(UIKit.label(Loc.t("ui.building.revive_info", {"time": UIKit.format_duration(temple.get_recovery_seconds()),
		"percent": roundi(DataRegistry.config.revive_xp_loss_ratio * 100.0)}), &"MutedLabel"))
	var patients := GameManager.hunters.get_all().filter(func(h: HunterRuntime) -> bool: return h.injured)
	if patients.is_empty():
		content.add_child(UIKit.label(Loc.t("ui.building.no_patients")))
	for runtime: HunterRuntime in patients:
		var remaining := temple.get_remaining(runtime)
		var total := temple.get_recovery_seconds()
		var cost := temple.get_speed_up_cost(runtime)
		var info := UIKit.vbox([
			UIKit.label(Loc.t("ui.building.patient", {"name": runtime.display_name, "xp": temple.get_xp_loss(runtime)})),
			UIKit.bar(total - remaining, total, &"TimerBar", Loc.t("ui.building.time_left", {"time": UIKit.format_duration(remaining)})),
		], 2)
		var speed := UIKit.button(Loc.t("ui.building.revive_now", {"gold": cost}), func() -> void:
			run_action("" if temple.speed_up(runtime) else Loc.t("ui.common.needs_gold", {"gold": cost}), Loc.t("ui.building.revived", {"name": runtime.display_name})),
			&"PrimaryButton", "" if GameManager.wallet.can_spend(cost) else Loc.t("ui.common.needs_gold", {"gold": cost}))
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
			costs.append(Loc.t("ui.common.gold_short", {"gold": recipe.gold_cost}))
		for cost in recipe.material_costs:
			costs.append(Loc.t("ui.building.recipe_cost", {"count": cost.quantity, "item": DataRegistry.get_item(cost.item_id).display_name,
				"have": GameManager.inventory.count(cost.item_id)}))
		var reason := crafting.can_craft(recipe.id)
		var title := "%s%s" % [item.display_name, " ×%d" % recipe.result_quantity if recipe.result_quantity > 1 else ""]
		var effect := UIKit.describe_modifiers(item) if item.item_type != ItemDefinition.ItemType.CONSUMABLE else _describe_consumable(item)
		var name_label := UIKit.label("%s · %s" % [title, UIKit.rarity_name(item)])
		name_label.add_theme_color_override(&"font_color", RarityColors.of(item.rarity))
		var info := UIKit.vbox([name_label, UIKit.label(effect, &"AccentLabel"), UIKit.label(", ".join(costs), &"MutedLabel")], 2)
		if not reason.is_empty():
			info.add_child(UIKit.label(reason, &"WarningLabel"))
		var craft := UIKit.button(Loc.t("ui.building.make") if item.stackable else Loc.t("ui.building.craft"), func() -> void:
			run_action("" if crafting.craft(recipe.id) != &"" else crafting.can_craft(recipe.id),
				Loc.t("ui.building.made", {"name": title})), &"PrimaryButton", reason)
		craft.size_flags_horizontal = Control.SIZE_SHRINK_END
		craft.custom_minimum_size.x = 64
		content.add_child(UIKit.card(UIKit.hbox([ItemIcon.new().setup(item, 32), info, craft])))


static func _describe_consumable(item: ItemDefinition) -> String:
	var parts := PackedStringArray()
	if item.energy > 0.0:
		parts.append(Loc.t("ui.building.energy", {"energy": roundi(item.energy)}))
	if item.heal_ratio > 0.0:
		parts.append(Loc.t("ui.building.heals", {"percent": roundi(item.heal_ratio * 100.0)}))
	parts.append(Loc.t("ui.building.consumable_price", {"gold": item.sell_price, "stock": GameManager.inventory.count(item.id)}))
	return " · ".join(parts)


func _build_warehouse(content: VBoxContainer) -> void:
	var inventory := GameManager.inventory
	content.add_child(UIKit.bar(inventory.used_slots(), inventory.capacity, &"TimerBar",
		Loc.t("ui.building.slots", {"used": inventory.used_slots(), "total": inventory.capacity})))
	content.add_child(UIKit.button(Loc.t("ui.building.open_inventory"), func() -> void: open_requested.emit(InventorySheet.new())))


func _build_house(content: VBoxContainer, placed: BuildingService.Placed) -> void:
	var housing := GameManager.housing
	var residents := GameManager.hunters.get_all().filter(func(h: HunterRuntime) -> bool:
		var home := housing.get_home(h)
		return home != null and home.instance_id == placed.instance_id)
	var beds := int(GameManager.buildings.get_instance_effect(placed, BuildingService.BEDS))
	content.add_child(UIKit.label(Loc.t("ui.building.beds", {"used": residents.size(), "total": beds})))
	for runtime: HunterRuntime in residents:
		content.add_child(UIKit.label("· %s" % runtime.display_name, &"MutedLabel"))
	content.add_child(UIKit.label(Loc.t("ui.building.town_beds", {"free": housing.get_free_beds(), "total": housing.get_total_beds()}), &"MutedLabel"))


## Blacksmith repairs (D64): every worn weapon, worn or stored, with its durability and the
## repair price paid by the treasury. Hunters also come here on their own and pay themselves.
func _build_repairs(content: VBoxContainer) -> void:
	var gm := GameManager
	var equipment := gm.equipment
	content.add_child(UIKit.label(Loc.t("ui.repair.heading"), &"AccentLabel"))
	content.add_child(UIKit.label(Loc.t("ui.repair.note"), &"MutedLabel"))
	var worn: Array[StringName] = []
	for hunter in gm.hunters.get_all():
		var weapon: StringName = hunter.equipment.get(&"weapon", &"")
		if weapon != &"" and gm.inventory.get_wear(weapon) > 0:
			worn.append(weapon)
	for instance_id in gm.inventory.get_instances():
		if gm.inventory.get_wear(instance_id) > 0:
			worn.append(instance_id)
	if worn.is_empty():
		content.add_child(UIKit.label(Loc.t("ui.repair.none"), &"MutedLabel"))
		return
	for instance_id in worn:
		var item := equipment.get_item(instance_id)
		var owner := gm.hunters.get_hunter(gm.inventory.get_owner_id(instance_id))
		var full := EquipmentService.max_durability(item)
		var current := equipment.get_durability(instance_id)
		var name_label := UIKit.label(Loc.t("ui.repair.worn_by", {"item": item.display_name, "name": owner.display_name}) if owner != null else item.display_name)
		name_label.add_theme_color_override(&"font_color", RarityColors.of(item.rarity))
		var info := UIKit.vbox([name_label, UIKit.bar(current, full, &"HpBar" if current > full * EquipmentService.REPAIR_THRESHOLD else &"TimerBar",
			Loc.t("ui.item.durability", {"current": current, "max": full}))], 2)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var fix := UIKit.button(Loc.t("ui.item.repair", {"gold": equipment.get_repair_cost(instance_id)}), func() -> void:
			run_action(equipment.repair(instance_id), Loc.t("ui.item.repaired", {"item": item.display_name})), &"PrimaryButton",
			equipment.can_repair(instance_id))
		fix.size_flags_horizontal = Control.SIZE_SHRINK_END
		fix.custom_minimum_size.x = 76
		content.add_child(UIKit.card(UIKit.hbox([ItemIcon.new().setup(item, 32, "", instance_id), info, fix], 6)))


## Market (D63): its buying price, every Hunter carrying loot with what it is worth, and buying
## one bag or all of them into the Warehouse now.
func _build_market(content: VBoxContainer) -> void:
	var gm := GameManager
	var regions: RegionService = gm.regions
	var ratio := gm.buildings.get_effect(BuildingService.MARKET, BuildingService.BUY_PRICE, 1.0)
	content.add_child(UIKit.label(Loc.t("ui.market.price", {"percent": roundi(ratio * 100.0)}), &"AccentLabel"))
	content.add_child(UIKit.label(Loc.t("ui.market.note"), &"MutedLabel"))
	var carriers: Array[HunterRuntime] = gm.hunters.get_all().filter(func(h: HunterRuntime) -> bool: return not h.loot_bag.is_empty())
	if carriers.is_empty():
		content.add_child(UIKit.label(Loc.t("ui.market.no_loot"), &"MutedLabel"))
		return
	for hunter in carriers:
		var value := 0
		for item_id: StringName in hunter.loot_bag:
			value += regions.get_buy_price(DataRegistry.get_item(item_id)) * int(hunter.loot_bag[item_id])
		var text := UIKit.label(Loc.t("ui.market.bag", {"name": hunter.display_name, "count": regions.get_bag_count(hunter), "gold": value}))
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var buy := UIKit.button(Loc.t("ui.market.buy"), func() -> void:
			regions.deposit(hunter)
			run_action("", Loc.t("ui.market.bought", {"name": hunter.display_name})), &"PrimaryButton")
		buy.size_flags_horizontal = Control.SIZE_SHRINK_END
		buy.custom_minimum_size.x = 64
		content.add_child(UIKit.card(UIKit.hbox([text, buy], 6)))
	content.add_child(UIKit.button(Loc.t("ui.market.buy_all", {"count": carriers.size()}), func() -> void:
		for hunter in carriers:
			regions.deposit(hunter)
		run_action("", Loc.t("ui.market.bought_all", {"count": carriers.size()})), &"PrimaryButton"))


# --- Evil Hunter Tycoon style buildings -------------------------------------------------------------

func _build_trading_post(content: VBoxContainer) -> void:
	var trading := GameManager.trading
	content.add_child(UIKit.label(Loc.t("ui.building.requests", {"used": trading.requests.size(), "total": trading.get_slots()}), &"AccentLabel"))
	if trading.requests.is_empty():
		content.add_child(UIKit.label(Loc.t("ui.building.no_requests"), &"MutedLabel"))
	for i in trading.requests.size():
		var request: Dictionary = trading.requests[i]
		var item := DataRegistry.get_item(request["item_id"])
		var info := UIKit.vbox([
			UIKit.label("%s ×%d" % [item.display_name, request["quantity"]]),
			UIKit.bar(request["delivered"], request["quantity"], &"TimerBar", Loc.t("ui.building.delivered", {"delivered": request["delivered"], "quantity": request["quantity"]})),
			UIKit.label(Loc.t("ui.building.bounty", {"gold": trading.get_bounty(item.id)}), &"MutedLabel"),
		], 2)
		var cancel := UIKit.button(Loc.t("ui.common.cancel"), func() -> void:
			trading.cancel(i)
			request_rebuild())
		cancel.size_flags_horizontal = Control.SIZE_SHRINK_END
		cancel.custom_minimum_size.x = 64
		content.add_child(UIKit.card(UIKit.hbox([info, cancel])))
	content.add_child(UIKit.separator())
	content.add_child(UIKit.label(Loc.t("ui.building.order_materials"), &"AccentLabel"))
	for item in trading.get_orderable_items():
		var buttons := UIKit.hbox([], 4)
		for size: int in ORDER_SIZES:
			var reason := trading.can_order(item.id, size)
			var order := UIKit.button("×%d" % size, func() -> void:
				run_action("" if trading.order(item.id, size) else trading.can_order(item.id, size),
					Loc.t("ui.building.requested", {"count": size, "item": item.display_name})), &"PrimaryButton", reason)
			order.custom_minimum_size.x = 48
			buttons.add_child(order)
		var info := UIKit.vbox([
			UIKit.label(Loc.t("ui.building.order_item", {"item": item.display_name, "gold": item.sell_price, "stock": GameManager.inventory.count(item.id)})),
		], 2)
		content.add_child(UIKit.card(UIKit.hbox([info, buttons])))


## Dropdown of the roster; returns the chosen Hunter (kept in `_picked`).
func _hunter_picker(content: VBoxContainer) -> HunterRuntime:
	var roster := GameManager.hunters.get_all()
	if roster.is_empty():
		content.add_child(UIKit.label(Loc.t("ui.building.no_hunters"), &"MutedLabel"))
		return null
	var chosen := GameManager.hunters.get_hunter(_picked)
	if chosen == null:
		chosen = roster[0]
		_picked = chosen.unique_id
	var picker := OptionButton.new()
	picker.custom_minimum_size.y = GameTheme.TOUCH
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in roster.size():
		picker.add_item(Loc.t("ui.building.picker_entry", {"name": roster[i].display_name, "level": roster[i].level}))
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
	content.add_child(UIKit.label(Loc.t("ui.building.rebirth_points", {"points": hunter.rebirth_points, "used": hunter.trait_ids.size(),
		"max": academy.get_max_traits()}), &"AccentLabel"))
	var promotions := academy.get_promotions(hunter)
	if not promotions.is_empty():
		content.add_child(UIKit.label(Loc.t("ui.building.class_change", {"count": AcademyService.PROMOTION_REINCARNATIONS, "gold": AcademyService.PROMOTION_COST}), &"AccentLabel"))
		for target in promotions:
			var reason := academy.can_change_class(hunter, target.id)
			var change := UIKit.button(Loc.t("ui.building.become", {"class": target.display_name}), func() -> void:
				run_action("" if academy.change_class(hunter, target.id) else academy.can_change_class(hunter, target.id),
					Loc.t("ui.building.class_changed", {"name": hunter.display_name, "class": target.display_name})), &"PrimaryButton", reason)
			content.add_child(change)
	content.add_child(UIKit.label(Loc.t("ui.building.skills"), &"AccentLabel"))
	for skill in academy.get_skills():
		var level := academy.get_skill_level(hunter, skill.id)
		var reason := academy.can_learn_skill(hunter, skill.id)
		var info := UIKit.vbox([
			UIKit.label("%s  %d / %d" % [skill.display_name, level, skill.max_level]),
			UIKit.label(skill.description, &"MutedLabel"),
		], 2)
		if not reason.is_empty() and level < skill.max_level:
			info.add_child(UIKit.label(reason, &"WarningLabel"))
		var learn := UIKit.button(Loc.t("ui.building.train", {"gold": academy.get_next_skill_cost(hunter, skill)}) if level < skill.max_level else Loc.t("ui.building.max"),
			func() -> void:
				run_action("" if academy.learn_skill(hunter, skill.id) else academy.can_learn_skill(hunter, skill.id),
					Loc.t("ui.building.trained", {"name": skill.display_name})), &"PrimaryButton", reason)
		learn.size_flags_horizontal = Control.SIZE_SHRINK_END
		learn.custom_minimum_size.x = 64
		content.add_child(UIKit.card(UIKit.hbox([info, learn])))
	content.add_child(UIKit.separator())
	content.add_child(UIKit.label(Loc.t("ui.building.known_traits"), &"AccentLabel"))
	for trait_def in GameManager.traits.get_traits(hunter):
		var forget := UIKit.button(Loc.t("ui.building.forget", {"gold": AcademyService.FORGET_COST}), func() -> void:
			run_action("" if academy.forget_trait(hunter, trait_def.id) else academy.can_forget_trait(hunter, trait_def.id),
				Loc.t("ui.building.forgotten", {"name": trait_def.display_name})), &"", academy.can_forget_trait(hunter, trait_def.id))
		forget.size_flags_horizontal = Control.SIZE_SHRINK_END
		forget.custom_minimum_size.x = 72
		content.add_child(UIKit.card(UIKit.hbox([UIKit.vbox([UIKit.label(trait_def.display_name), UIKit.label(trait_def.description, &"MutedLabel")], 2), forget])))
	content.add_child(UIKit.label(Loc.t("ui.building.learn_trait"), &"AccentLabel"))
	for trait_def in academy.get_learnable_traits(hunter):
		var reason := academy.can_learn_trait(hunter, trait_def.id)
		var learn := UIKit.button(Loc.t("ui.building.learn", {"points": trait_def.academy_cost}), func() -> void:
			run_action("" if academy.learn_trait(hunter, trait_def.id) else academy.can_learn_trait(hunter, trait_def.id),
				Loc.t("ui.building.learned", {"name": trait_def.display_name})), &"PrimaryButton", reason)
		learn.size_flags_horizontal = Control.SIZE_SHRINK_END
		learn.custom_minimum_size.x = 64
		content.add_child(UIKit.card(UIKit.hbox([UIKit.vbox([UIKit.label(trait_def.display_name), UIKit.label(trait_def.description, &"MutedLabel")], 2), learn])))


func _build_forge(content: VBoxContainer) -> void:
	var forge := GameManager.forge
	var inventory := GameManager.inventory
	content.add_child(UIKit.label(Loc.t("ui.building.enhance_limit", {"limit": forge.get_max_level(), "ore": inventory.count(ForgeService.ORE)}), &"AccentLabel"))
	var entries: Array = []
	for instance_id in inventory.get_equipped():
		var wearer := GameManager.hunters.get_hunter(inventory.get_equipped()[instance_id])
		entries.append([instance_id, Loc.t("ui.building.worn_by", {"name": wearer.display_name}) if wearer != null else Loc.t("ui.building.worn")])
	for instance_id in inventory.get_instances():
		entries.append([instance_id, Loc.t("ui.building.in_warehouse")])
	if entries.is_empty():
		content.add_child(UIKit.label(Loc.t("ui.building.no_equipment"), &"MutedLabel"))
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
			UIKit.label(Loc.t("ui.building.enhance_cost", {"gold": forge.get_gold_cost(instance_id), "ore": forge.get_ore_cost(instance_id)}), &"MutedLabel")], 2)
		if not reason.is_empty():
			info.add_child(UIKit.label(reason, &"WarningLabel"))
		var enhance := UIKit.button(Loc.t("ui.building.enhance"), func() -> void:
			run_action("" if forge.enhance(instance_id) else forge.can_enhance(instance_id), Loc.t("ui.building.enhanced", {"name": item.display_name})),
			&"PrimaryButton", reason)
		enhance.size_flags_horizontal = Control.SIZE_SHRINK_END
		enhance.custom_minimum_size.x = 72
		content.add_child(UIKit.card(UIKit.hbox([ItemIcon.new().setup(item, 32, "+%d" % level if level > 0 else ""), info, enhance])))


func _build_portal(content: VBoxContainer) -> void:
	var gm := GameManager
	var rein := gm.reincarnation
	content.add_child(UIKit.label(Loc.t("ui.building.difficulty"), &"AccentLabel"))
	content.add_child(UIKit.label(Loc.t("ui.building.total_reincarnations", {"count": gm.progress.total_reincarnations}), &"MutedLabel"))
	var row := UIKit.hbox([], 4)
	for difficulty in rein.get_difficulty_count():
		var unlocked := rein.is_unlocked(difficulty)
		var label := rein.get_difficulty_name(difficulty) if unlocked else "%s\n(%d)" % [rein.get_difficulty_name(difficulty), rein.get_unlock_requirement(difficulty)]
		var button := UIKit.button(label, func() -> void:
			run_action(rein.set_difficulty(difficulty)), &"SelectedButton" if gm.progress.difficulty == difficulty else &"",
			"" if unlocked else Loc.t("ui.building.locked"))
		row.add_child(button)
	content.add_child(row)
	content.add_child(UIKit.label(Loc.t("ui.building.difficulty_scale", {
		"stat": "%.1f" % DataRegistry.config.difficulty_stat_scale[clampi(gm.progress.difficulty, 0, DataRegistry.config.difficulty_stat_scale.size() - 1)],
		"reward": "%.1f" % DataRegistry.config.difficulty_reward_scale[clampi(gm.progress.difficulty, 0, DataRegistry.config.difficulty_reward_scale.size() - 1)]}), &"MutedLabel"))
	content.add_child(UIKit.separator())
	content.add_child(UIKit.label(Loc.t("ui.building.reincarnate_title"), &"AccentLabel"))
	content.add_child(UIKit.label(Loc.t("ui.hunter.reincarnate_swap"), &"MutedLabel"))
	for runtime: HunterRuntime in gm.hunters.get_all():
		var reason := rein.can_reincarnate(runtime)
		var info := UIKit.vbox([
			UIKit.label(Loc.t("ui.building.reincarnate_entry", {"name": runtime.display_name, "level": runtime.level, "count": runtime.reincarnations})),
			UIKit.label(Loc.t("ui.building.rebirth_bonus", {"percent": roundi(DataRegistry.config.reincarnation_stat_bonus * 100.0), "points": rein.points_for_next(runtime)}), &"MutedLabel"),
		], 2)
		if not reason.is_empty():
			info.add_child(UIKit.label(reason, &"WarningLabel"))
		var go := UIKit.button(Loc.t("ui.building.reincarnate"), func() -> void:
			run_action("" if rein.reincarnate(runtime) else rein.can_reincarnate(runtime), Loc.t("ui.building.reborn", {"name": runtime.display_name})),
			&"PrimaryButton", reason)
		go.size_flags_horizontal = Control.SIZE_SHRINK_END
		go.custom_minimum_size.x = 88
		content.add_child(UIKit.card(UIKit.hbox([info, go])))
