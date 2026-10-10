class_name ActivityDefinition
extends GameDefinition
## Town activity for Hunters between expeditions (DECISIONS.md D14).

## Town location where the Hunter performs it, e.g. &"tavern", &"training_yard".
@export var location_id: StringName
## False for activities forced by state (e.g. recovering).
@export var player_assignable: bool = true
@export var tick_seconds: float = 10.0

@export_group("Effects per tick")
## Fraction of max HP restored, e.g. 0.05 = 5%.
@export var hp_percent: float = 0.0
@export var mood: float = 0.0
@export var xp: float = 0.0
## Bond gained with every other Hunter doing the same activity.
@export var bond: float = 0.0
