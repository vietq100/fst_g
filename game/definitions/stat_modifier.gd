class_name StatModifier
extends Resource
## One stat change from equipment, traits, mood or bonds (DECISIONS.md D18).
## Final stat = (base + level_growth + Σflat) × (1 + Σpercent).

enum Type { FLAT, PERCENT }

@export var stat: StringName
@export var type: Type = Type.FLAT
## FLAT: added to the stat. PERCENT: fraction, e.g. 0.15 = +15%.
@export var value: float = 0.0
## Optional tag that must be active for this modifier to apply, e.g. &"vs_boss".
## Empty means always active.
@export var condition: StringName
