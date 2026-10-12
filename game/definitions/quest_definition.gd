class_name QuestDefinition
extends GameDefinition
## Guided objective (Evil Hunter Tycoon "novice quests"): a condition checked against the game
## state and a reward. Quests are listed in `order`; locked ones show only after the previous
## quest was claimed.

enum Kind { BUILDING, TOWN_LEVEL, HUNTERS, FLAG, REINCARNATIONS, DIFFICULTY, HUNTER_LEVEL, SKILLS_LEARNED, ENHANCED }

@export_multiline var description: String
@export var order: int = 0
@export var kind: Kind = Kind.BUILDING
## Building id / progress flag for BUILDING and FLAG.
@export var target_id: StringName
## Needed amount (level, count).
@export var amount: int = 1
@export var reward_gold: int = 0
@export var reward_items: Array[ItemAmount] = []
