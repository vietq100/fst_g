class_name Enemy
extends Actor
## Enemy actor driven by an EnemyDefinition. AI: find nearest Hunter → approach →
## attack in range → retarget when the target is invalid (AI_SYSTEM.md).

const GROUP := &"enemies"
## Seconds the death effect plays before the node is removed.
const DEATH_DURATION := 0.5

var definition: EnemyDefinition


## Call after the node is in the tree.
func setup(enemy_definition: EnemyDefinition, combat_service: CombatService, retarget_interval: float) -> void:
	definition = enemy_definition
	add_to_group(GROUP)
	health.setup(definition.hp)
	combat.setup(Hunter.GROUP, definition.attack_range, retarget_interval, combat_service)
	auto_combat = true
	repositions_in_range = not definition.is_boss


func get_team_group() -> StringName:
	return GROUP


func get_move_speed() -> float:
	return definition.move_speed if definition != null else 0.0


func get_hit_radius() -> float:
	return definition.hit_radius if definition != null else 0.0


func get_combat_stats(_against: Actor = null) -> CombatStats:
	var stats := CombatStats.new()
	stats.attack = definition.attack
	stats.defense = definition.defense
	stats.attack_speed = definition.attack_speed
	stats.critical_chance = definition.critical_chance
	stats.critical_damage = definition.critical_damage
	return stats


func _on_died() -> void:
	super()
	remove_from_group(GROUP)
	visual.play_death(DEATH_DURATION)
	get_tree().create_timer(DEATH_DURATION).timeout.connect(queue_free)
