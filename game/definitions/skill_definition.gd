class_name SkillDefinition
extends GameDefinition
## Academy skill (Evil Hunter Tycoon style): trained for gold, each level adds `modifiers`
## once more. Needs an Academy of `required_academy_level`.

## A translation key (D61); reading it returns the translated text.
@export_multiline var description: String:
	get:
		return tr(description) if not description.is_empty() else description
@export var max_level: int = 5
@export var gold_per_level: int = 100
@export var required_academy_level: int = 1
## Applied once per skill level (a FLAT 2 attack at level 3 = +6 attack).
@export var modifiers: Array[StatModifier] = []
