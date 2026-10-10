class_name KillReward
extends RefCounted
## What one kill added to the expedition stash (used for loot popups).

var gold: int = 0
## Item id -> quantity.
var items: Dictionary[StringName, int] = {}
