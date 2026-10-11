class_name StatusEffectChance
extends Resource
## "Hits have `chance` to apply `effect`" — on-hit effects of enemies (D48).

@export var effect: StatusEffectDefinition
@export_range(0.0, 1.0) var chance: float = 1.0
@export var stacks: int = 1
