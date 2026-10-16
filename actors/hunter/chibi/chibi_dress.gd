class_name ChibiDress
extends RefCounted
## What a Hunter wears on top of its look (D59, D73): the outfit pattern (class or skin), the
## cloth colour of the top or skin, pants and boots colours, a hat and a pet. Built by
## EquipmentService.get_dress from the equipped items; ForgeLook turns it into the Forge look (D73).

## Class outfit (ForgeLook.CLASS_LOOKS, &"" = the core tank top and shorts).
var outfit: StringName = &""
## Cloth ramp base colour (the top's or the skin's tint); unused when `has_cloth` is false.
var cloth := Color.WHITE
var has_cloth := false
## A skin is worn: its pattern and colour win over the top.
var skin := false
var pants := Color.WHITE
var has_pants := false
var boots := Color.WHITE
var has_boots := false
## Forge top named by the gear (D73): the top's `look_id` or a skin's outfit; &"" = the outfit's own.
var top: StringName = &""
## Forge pants / shoes named by the gear's `look_id`; &"" = the outfit's own.
var pants_style: StringName = &""
var boots_style: StringName = &""
## Hat style (ChibiBody.hat_style_for; Forge hat ids, helm, hood; &"" = bare head).
var hat: StringName = &""
var hat_tint := Color.WHITE
## Forge glasses from an accessory (`look_id` = glasses_<id>, D73 / Q3); &"" = none.
var glasses: StringName = &""
var glasses_tint := Color.WHITE
## PetSprites kind (&"" = no pet).
var pet: StringName = &""
var pet_tint := Color.WHITE


## Only the outfit (no gear): what a class wears out of the box.
static func plain(outfit_id: StringName) -> ChibiDress:
	var dress := ChibiDress.new()
	dress.outfit = outfit_id
	return dress


## Cache key of everything that changes the body frames (the pet is drawn separately).
func key() -> String:
	return "%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s" % [outfit, cloth.to_html(false) if has_cloth else "-", pants.to_html(false) if has_pants else "-",
		boots.to_html(false) if has_boots else "-", hat, hat_tint.to_html(false) if hat != &"" else "-", top, pants_style,
		boots_style, glasses, glasses_tint.to_html(false) if glasses != &"" else "-"]

