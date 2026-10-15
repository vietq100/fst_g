class_name TalentDefinition
extends GameDefinition
## A Hunter talent (DECISIONS.md D46): recipes it can make in the field from its own loot bag.

## A translation key (D61); reading it returns the translated text.
@export_multiline var description: String:
	get:
		return tr(description) if not description.is_empty() else description
## Chance weight at recruitment (BALANCE.md → Talents); "no talent" has GameConfig.talent_none_weight.
@export var weight: float = 1.0
@export var recipe_ids: Array[StringName] = []
@export var icon: Texture2D
