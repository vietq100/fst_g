class_name TraitService
extends RefCounted
## Hunter traits (HUNTER_LIFE_SYSTEM.md §1): random traits for recruits, trait stat modifiers,
## activity rate modifiers and like/dislike event tags. All values are data.

## Event tags (TraitDefinition.mood_likes / mood_dislikes). DECISIONS.md D26.
const BOSS_FIGHT := &"boss_fight"
const BOSS_KILL := &"boss_kill"
const SUCCESS := &"success"
const FAILURE := &"failure"
const ABOVE_LEVEL := &"above_level"
const RECKLESS_PARTNER := &"reckless_partner"
const BACK_TO_BACK := &"back_to_back"
const IDLE_CYCLES := &"idle_cycles"
const LONG_REST := &"long_rest"
## Activity tags = activity ids (&"training", &"resting", &"socializing").

const RECKLESS := &"reckless"

var _registry: Node
var _config: GameConfig
var _rng: RandomNumberGenerator


func _init(registry: Node, hunters: HunterService, config: GameConfig, rng: RandomNumberGenerator) -> void:
	_registry = registry
	_config = config
	_rng = rng
	hunters.add_modifier_source(get_modifiers)


func get_traits(hunter: HunterRuntime) -> Array[TraitDefinition]:
	var result: Array[TraitDefinition] = []
	for trait_id in hunter.trait_ids:
		var definition := _registry.find_def(&"trait", trait_id) as TraitDefinition
		if definition != null:
			result.append(definition)
	return result


func get_modifiers(hunter: HunterRuntime) -> Array[StatModifier]:
	var modifiers: Array[StatModifier] = []
	for definition in get_traits(hunter):
		modifiers.append_array(definition.modifiers)
	return modifiers


## Product of the Hunter's trait multipliers for an activity (1.0 = normal).
func get_activity_rate(hunter: HunterRuntime, activity_id: StringName) -> float:
	var rate := 1.0
	for definition in get_traits(hunter):
		rate *= definition.activity_rate_modifiers.get(activity_id, 1.0)
	return rate


## Number of the Hunter's traits that like (+) and dislike (-) the tag.
func count_reactions(hunter: HunterRuntime, tag: StringName) -> Vector2i:
	var likes := 0
	var dislikes := 0
	for definition in get_traits(hunter):
		if definition.mood_likes.has(tag):
			likes += 1
		if definition.mood_dislikes.has(tag):
			dislikes += 1
	return Vector2i(likes, dislikes)


func has_trait(hunter: HunterRuntime, trait_id: StringName) -> bool:
	return hunter.trait_ids.has(trait_id)


## Gives a new candidate traits_min..traits_max distinct random traits.
func assign_random_traits(hunter: HunterRuntime) -> void:
	var pool: Array[StringName] = _registry.get_ids(&"trait")
	hunter.trait_ids.clear()
	var count := mini(_rng.randi_range(_config.traits_min, _config.traits_max), pool.size())
	for i in count:
		var index := _rng.randi_range(0, pool.size() - 1)
		hunter.trait_ids.append(pool[index])
		pool.remove_at(index)


## Drops unknown trait ids (after loading).
func validate(hunter: HunterRuntime, warnings: PackedStringArray) -> void:
	for trait_id in hunter.trait_ids.duplicate():
		if not _registry.has_def(&"trait", trait_id):
			warnings.append("%s: dropped unknown trait %s" % [hunter.unique_id, trait_id])
			hunter.trait_ids.erase(trait_id)
