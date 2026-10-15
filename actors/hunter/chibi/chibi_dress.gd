class_name ChibiDress
extends RefCounted
## What a chibi Hunter wears on top of its look (D59): the outfit pattern (class or skin), the
## cloth colour of the top or skin, pants and boots colours, a hat and a pet. Built by
## EquipmentService.get_dress from the equipped items; ChibiBody composes frames from it.

## ChibiBody.OUTFITS id (&"" = the reference tank top).
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
## ChibiBody.HATS id (&"" = bare head).
var hat: StringName = &""
var hat_tint := Color.WHITE
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
	return "%s|%s|%s|%s|%s|%s" % [outfit, cloth.to_html(false) if has_cloth else "-", pants.to_html(false) if has_pants else "-",
		boots.to_html(false) if has_boots else "-", hat, hat_tint.to_html(false) if hat != &"" else "-"]


## Five-step ramp (light → darkest) from a base colour.
static func ramp(base: Color) -> Array:
	return [base.lightened(0.28), base, base.darkened(0.22), base.darkened(0.42), base.darkened(0.6)]
