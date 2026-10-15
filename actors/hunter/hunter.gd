class_name Hunter
extends Actor
## Scene presentation of one HunterRuntime. Holds no gameplay rules.

const GROUP := &"hunters"
const DEFAULT_WEAPON_TINT := Color("d8dde3")

var runtime: HunterRuntime
var _service: HunterService
var _equipment: EquipmentService


## Call after the node is in the tree. `equipment` (optional) shows equipped items' tints.
func setup(hunter: HunterRuntime, service: HunterService, combat_service: CombatService,
		retarget_interval: float, equipment: EquipmentService = null) -> void:
	runtime = hunter
	_service = service
	_equipment = equipment
	name = String(hunter.unique_id)
	add_to_group(GROUP)
	_refresh_equipment_look()
	var plate := ActorNameplate.new()
	add_child(plate)
	plate.setup(self, hunter.display_name, 42.0)
	health.setup(_service.get_stat(hunter, HunterService.MAX_HP), hunter.current_hp)
	health.health_changed.connect(_on_health_changed)
	_service.hunter_changed.connect(_on_hunter_changed)
	_service.hunter_leveled_up.connect(_on_hunter_leveled_up)
	var definition := _service.get_definition(hunter)
	combat.setup(Enemy.GROUP, definition.attack_range, retarget_interval, combat_service)
	auto_combat = true
	if hunter.injured or hunter.current_hp <= 0.0:
		# Injured Hunters are shown downed until they recover.
		_on_died()


func get_team_group() -> StringName:
	return GROUP


func get_move_speed() -> float:
	return _service.get_stat(runtime, HunterService.MOVE_SPEED)


func get_combat_stats(against: Actor = null) -> CombatStats:
	var conditions: Array[StringName] = []
	if against is Enemy and (against as Enemy).definition != null and (against as Enemy).definition.is_boss:
		conditions.append(&"vs_boss")
	var stats := CombatStats.new()
	stats.attack = _service.get_stat(runtime, HunterService.ATTACK, conditions)
	stats.defense = _service.get_stat(runtime, HunterService.DEFENSE, conditions)
	stats.attack_speed = _service.get_stat(runtime, HunterService.ATTACK_SPEED, conditions)
	stats.critical_chance = _service.get_stat(runtime, HunterService.CRITICAL_CHANCE, conditions)
	stats.critical_damage = _service.get_stat(runtime, HunterService.CRITICAL_DAMAGE, conditions)
	stats.damage_dealt = _service.get_stat(runtime, HunterService.DAMAGE_DEALT, conditions)
	stats.damage_taken = _service.get_stat(runtime, HunterService.DAMAGE_TAKEN, conditions)
	return stats


## The two active skills the Hunter fights with (D55): its picks, or the highest unlocked.
func get_active_skills() -> Array[ActiveSkillDefinition]:
	return ActiveSkills.loadout(DataRegistry, runtime, _service.get_definition(runtime))


func _on_health_changed(current: float, _maximum: float) -> void:
	runtime.current_hp = current


func _on_hunter_changed(hunter: HunterRuntime) -> void:
	if hunter != runtime:
		return
	# Read before set_max_health: its health_changed signal writes the actor's HP back to runtime.
	var runtime_hp := hunter.current_hp
	health.set_max_health(_service.get_stat(hunter, HunterService.MAX_HP))
	if health.is_dead():
		# A downed actor must not overwrite a revived Hunter's HP; the world revives the actor.
		hunter.current_hp = runtime_hp
	# Out of combat, HP can change in town (resting): follow the runtime value.
	if not hunter.injured and not health.is_dead() and not combat.is_valid_target(combat.target) \
			and not is_equal_approx(health.current_health, runtime_hp):
		health.setup(health.max_health, runtime_hp)
	_refresh_equipment_look()


func _on_hunter_leveled_up(hunter: HunterRuntime, _new_level: int, healed: float) -> void:
	if hunter != runtime:
		return
	health.set_max_health(_service.get_stat(hunter, HunterService.MAX_HP))
	health.heal(healed)
	visual.play_level_up()


## Skin, hair and dye from the Hunter's look, outfit from its base class, the weapon sprite from
## the equipped item (or the class default) tinted by the item (D49, D53).
func _refresh_equipment_look() -> void:
	var look := visual as ChibiVisual
	if look == null:
		return
	var weapon := _equipment.get_equipped_item(runtime, &"weapon") if _equipment != null else null
	look.appearance = runtime.appearance
	look.dead = not runtime.alive
	look.weapon_color = weapon.tint if weapon != null else DEFAULT_WEAPON_TINT
	var definition := _service.get_definition(runtime)
	look.set_class_style(ChibiBody.outfit_for(definition))
	look.weapon_sprite = WeaponSprites.kind_for_item(weapon, look.get_default_weapon_sprite())
	look.weapon_width = definition.weapon_width if definition != null else look.weapon_width
	# Reach of the slash arc: the sprite's length, a little more for better gear.
	var base_length := WeaponSprites.length_of(look.weapon_sprite) if WeaponSprites.has_kind(look.weapon_sprite) \
		else (definition.weapon_length if definition != null else 12.0)
	look.weapon_length = base_length + (2.0 if weapon != null and weapon.rarity >= ItemDefinition.Rarity.UNCOMMON else 0.0)
