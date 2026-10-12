class_name TraitDefinition
extends GameDefinition
## Hunter personality trait (HUNTER_LIFE_SYSTEM.md §1).

@export_multiline var description: String
@export var modifiers: Array[StatModifier] = []
## Activity id -> rate multiplier, e.g. { &"training": 1.5 }.
@export var activity_rate_modifiers: Dictionary[StringName, float] = {}
## Event tags that raise / lower mood, e.g. &"boss_fight".
@export var mood_likes: Array[StringName] = []
@export var mood_dislikes: Array[StringName] = []
@export var icon: Texture2D
## Academy: reincarnation points needed to learn it (0 = cannot be learned, e.g. flaws).
@export var academy_cost: int = 1
