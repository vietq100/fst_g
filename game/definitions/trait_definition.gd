class_name TraitDefinition
extends GameDefinition
## Hunter personality trait (HUNTER_LIFE_SYSTEM.md §1).

## A translation key (D61); reading it returns the translated text.
@export_multiline var description: String:
	get:
		return tr(description) if not description.is_empty() else description
@export var modifiers: Array[StatModifier] = []
## Activity id -> rate multiplier, e.g. { &"training": 1.5 }.
@export var activity_rate_modifiers: Dictionary[StringName, float] = {}
## Event tags that raise / lower mood, e.g. &"boss_fight".
@export var mood_likes: Array[StringName] = []
@export var mood_dislikes: Array[StringName] = []
@export var icon: Texture2D
## Academy: reincarnation points needed to learn it (0 = cannot be learned, e.g. flaws).
@export var academy_cost: int = 1

@export_group("Behaviour")
## Added to the HP ratio at which the Hunter breaks off and goes home to rest (negative = fights on).
@export var retreat_bias: float = 0.0
## Multiplier of the range in which it picks a fight (cautious < 1 < brave).
@export var aggro_mult: float = 1.0
## Prefers wounded enemies (finishes them off, focus fire) when positive.
@export var weak_bias: float = 0.0
## Positive: seeks bosses and elites; negative: avoids them, most of all when hurt.
@export var boss_bias: float = 0.0
## Added to the HP ratio at which it drinks medicine from its bag in the middle of a fight.
@export var potion_bias: float = 0.0
## Multiplier of the range in which it goes for loot on the ground.
@export var loot_mult: float = 1.0
