class_name ActiveSkills
extends RefCounted
## Lookup and loadout rules for active skills (D55). Pure functions over the registry: which
## skills a class owns, which a Hunter has unlocked, and which two it carries into a fight —
## the player's picks (`HunterRuntime.active_skills`) when still valid, otherwise the two highest
## unlocked skills. Monsters list their skills on the EnemyDefinition.

const SLOTS := 2


## Skills of a base class (or &"monster"), lowest unlock level first.
static func for_class(registry: Node, owner_class: StringName) -> Array[ActiveSkillDefinition]:
	var result: Array[ActiveSkillDefinition] = []
	for definition in registry.get_all(DataRegistry.ACTIVE_SKILL):
		var skill := definition as ActiveSkillDefinition
		if skill.owner_class == owner_class:
			result.append(skill)
	result.sort_custom(func(a: ActiveSkillDefinition, b: ActiveSkillDefinition) -> bool:
		return a.required_level < b.required_level or (a.required_level == b.required_level and String(a.id) < String(b.id)))
	return result


## Base class of a Hunter definition (subclasses use their base class's skills).
static func base_class_of(definition: HunterDefinition) -> StringName:
	if definition == null:
		return &""
	return definition.promotion_of if definition.promotion_of != &"" else definition.class_id


static func get_skill(registry: Node, skill_id: StringName) -> ActiveSkillDefinition:
	return registry.find_def(DataRegistry.ACTIVE_SKILL, skill_id) as ActiveSkillDefinition


static func is_unlocked(skill: ActiveSkillDefinition, hunter: HunterRuntime) -> bool:
	return skill != null and hunter != null and hunter.level >= skill.required_level


## The skills a Hunter fights with: its valid picks first, then the highest unlocked ones to
## fill the slots. Empty when nothing is unlocked.
static func loadout(registry: Node, hunter: HunterRuntime, definition: HunterDefinition) -> Array[ActiveSkillDefinition]:
	var result: Array[ActiveSkillDefinition] = []
	if hunter == null or definition == null:
		return result
	var owner_class := base_class_of(definition)
	for skill_id in hunter.active_skills:
		var skill := get_skill(registry, skill_id)
		if skill != null and skill.owner_class == owner_class and is_unlocked(skill, hunter) and not result.has(skill):
			result.append(skill)
		if result.size() >= SLOTS:
			break
	if result.size() < SLOTS:
		var owned := for_class(registry, owner_class)
		for i in range(owned.size() - 1, -1, -1):
			if result.size() >= SLOTS:
				break
			if is_unlocked(owned[i], hunter) and not result.has(owned[i]):
				result.append(owned[i])
	return result


## Player pick: puts `skill_id` in `slot` (0 / 1) if the Hunter owns and has unlocked it.
## Returns "" or the reason it cannot.
static func set_slot(registry: Node, hunter: HunterRuntime, definition: HunterDefinition, slot: int, skill_id: StringName) -> String:
	var skill := get_skill(registry, skill_id)
	if skill == null or skill.owner_class != base_class_of(definition):
		return "Not a skill of this class"
	if not is_unlocked(skill, hunter):
		return "Unlocks at level %d" % skill.required_level
	var picks := loadout(registry, hunter, definition)
	var ids: Array[StringName] = []
	for pick in picks:
		ids.append(pick.id)
	while ids.size() < SLOTS:
		ids.append(&"")
	var other := 1 - clampi(slot, 0, SLOTS - 1)
	if ids[other] == skill_id:
		ids[other] = ids[clampi(slot, 0, SLOTS - 1)]
	ids[clampi(slot, 0, SLOTS - 1)] = skill_id
	hunter.active_skills.clear()
	for id in ids:
		if id != &"":
			hunter.active_skills.append(id)
	return ""
