class_name CombatStats
extends RefCounted
## Snapshot of the stats combat needs from one actor against one opponent, after all modifiers.

var attack: float = 0.0
var defense: float = 0.0
## Attacks per second.
var attack_speed: float = 1.0
var critical_chance: float = 0.0
var critical_damage: float = 1.0
## Outgoing / incoming damage multipliers (traits, e.g. Reckless, Cautious, Brave vs boss).
var damage_dealt: float = 1.0
var damage_taken: float = 1.0
