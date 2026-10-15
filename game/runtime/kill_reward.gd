class_name KillReward
extends RefCounted
## What one kill added to the expedition stash (used for loot popups).

var gold: int = 0
## True when the loot was not handed to the killer: it lies on the ground for Hunters to pick up.
var on_ground: bool = false
## Item id -> quantity.
var items: Dictionary[StringName, int] = {}
