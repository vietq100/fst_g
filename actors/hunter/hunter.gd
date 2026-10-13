class_name Hunter
extends Actor
## Scene presentation of one HunterRuntime. Holds no gameplay rules.

const GROUP := &"hunters"
const DEFAULT_WEAPON_TINT := Color("d8dde3")

var runtime: HunterRuntime
var _service: HunterService
var _equipment: EquipmentService
## Class skills (D70); null = no skills (older callers, some tests).
var _skills: ClassSkillService
var skill_caster: ClassSkillCaster


## Call after the node is in the tree. `equipment` (optional) shows equipped items' tints.
## `skills` (optional) casts class skills with mana (D70).
func setup(hunter: HunterRuntime, service: HunterService, combat_service: CombatService,
		retarget_interval: float, equipment: EquipmentService = null, skills: ClassSkillService = null) -> void:
	runtime = hunter
	_service = service
	_equipment = equipment
	_skills = skills
	name = String(hunter.unique_id)
	add_to_group(GROUP)
	_refresh_equipment_look()
	var plate := ActorNameplate.new()
	add_child(plate)
	plate.setup(self, hunter.display_name, 60.0)
	health.setup(_service.get_stat(hunter, HunterService.MAX_HP), hunter.current_hp)
	health.health_changed.connect(_on_health_changed)
	_service.hunter_changed.connect(_on_hunter_changed)
	_service.hunter_leveled_up.connect(_on_hunter_leveled_up)
	var definition := _service.get_definition(hunter)
	combat.setup(Enemy.GROUP, _attack_range(), retarget_interval, combat_service)
	if _skills != null:
		skill_caster = ClassSkillCaster.new()
		skill_caster.name = "ClassSkills"
		add_child(skill_caster)
		skill_caster.setup(self, _skills, combat_service, DataRegistry.config if _config_override == null else _config_override)
	auto_combat = true
	if hunter.injured or hunter.current_hp <= 0.0:
		# Injured Hunters are shown downed until they recover.
		_on_died()


func get_team_group() -> StringName:
	return GROUP


func get_move_speed() -> float:
	return _service.get_stat(runtime, HunterService.MOVE_SPEED)


## Config for the skill caster when the DataRegistry autoload is not the one in use (tests).
var _config_override: GameConfig


## Final value of one Hunter stat (no combat conditions).
func get_hunter_stat(stat: StringName) -> float:
	return _service.get_stat(runtime, stat)


func get_tenacity() -> float:
	var cap := _config_override.tenacity_cap if _config_override != null else DataRegistry.config.tenacity_cap
	return minf(_service.get_stat(runtime, HunterService.TENACITY), cap)


func get_on_hit_effects() -> Array[StatusEffectChance]:
	return _skills.get_on_hit_effects(runtime) if _skills != null else [] as Array[StatusEffectChance]


## Conditions for conditional modifiers against `against` (D70): vs_boss, vs_<tag>,
## unnoticed (the enemy targets someone else), vs_full_hp, low_hp / high_hp (own HP).
func get_conditions(against: Actor) -> Array[StringName]:
	var conditions: Array[StringName] = []
	var enemy := against as Enemy
	if enemy != null and enemy.definition != null:
		if enemy.definition.is_boss:
			conditions.append(&"vs_boss")
		for tag in enemy.definition.tags:
			conditions.append(StringName("vs_%s" % tag))
	if against != null and is_instance_valid(against) and against.is_inside_tree():
		if against.combat.target != self:
			conditions.append(&"unnoticed")
		if against.health.get_ratio() >= 0.9:
			conditions.append(&"vs_full_hp")
	if is_inside_tree() and health.max_health > 0.0:
		var ratio := health.get_ratio()
		if ratio < 0.5:
			conditions.append(&"low_hp")
		elif ratio > 0.7:
			conditions.append(&"high_hp")
	return conditions


func get_combat_stats(against: Actor = null) -> CombatStats:
	var conditions := get_conditions(against)
	var stats := CombatStats.new()
	stats.attack = _service.get_stat(runtime, HunterService.ATTACK, conditions)
	stats.defense = _service.get_stat(runtime, HunterService.DEFENSE, conditions)
	stats.attack_speed = _service.get_stat(runtime, HunterService.ATTACK_SPEED, conditions)
	stats.critical_chance = _service.get_stat(runtime, HunterService.CRITICAL_CHANCE, conditions)
	stats.critical_damage = _service.get_stat(runtime, HunterService.CRITICAL_DAMAGE, conditions)
	stats.damage_dealt = _service.get_stat(runtime, HunterService.DAMAGE_DEALT, conditions)
	stats.damage_taken = _service.get_stat(runtime, HunterService.DAMAGE_TAKEN, conditions)
	var cap := _config_override.dodge_cap if _config_override != null else DataRegistry.config.dodge_cap
	stats.dodge = minf(_service.get_stat(runtime, HunterService.DODGE, conditions), cap)
	return stats


## Attack range after range passives (D70).
func _attack_range() -> float:
	var definition := _service.get_definition(runtime)
	var base := definition.attack_range if definition != null else 0.0
	return _skills.get_attack_range(runtime, base) if _skills != null else base


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
	combat.attack_range = _attack_range()
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
	look.dress = _equipment.get_dress(runtime) if _equipment != null else ChibiDress.plain(ChibiBody.outfit_for(definition))
	look.weapon_sprite = WeaponSprites.kind_for_item(weapon, look.get_default_weapon_sprite())
	look.weapon_width = definition.weapon_width if definition != null else look.weapon_width
	# Reach of the slash arc: the sprite's length, a little more for better gear.
	var base_length := WeaponSprites.length_of(look.weapon_sprite) if WeaponSprites.has_kind(look.weapon_sprite) \
		else (definition.weapon_length if definition != null else 12.0)
	look.weapon_length = base_length + (2.0 if weapon != null and weapon.rarity >= Tier.Level.U else 0.0)
