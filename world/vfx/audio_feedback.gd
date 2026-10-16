class_name AudioFeedback
extends Node
## Sounds and music of the world (AUDIO_DESIGN.md, D78), from the game's signals; the Audio autoload
## plays them. Combat sounds are world sounds (heard near the screen); events of the village are UI
## sounds. The music follows what the camera looks at: the Town by day or night, the hunting regions and
## dungeon runs, the boss arena. Presentation only.

## Seconds between two checks of the music.
const MUSIC_CHECK := 1.0
## Village events in the first seconds (loading a save, offline progress) stay silent.
const SETTLE_TIME := 1.5
const TOWN := &"town"
const NIGHT := &"night"
const WILD := &"wild"
const BOSS := &"boss"

var _world: WorldService
var _check := 0.0
var _time := 0.0


func setup(world: WorldService) -> void:
	_world = world


func _ready() -> void:
	var gm := GameManager
	gm.combat.damage_dealt.connect(_on_damage_dealt)
	gm.combat.attack_dodged.connect(_on_attack_dodged)
	gm.combat.actor_defeated.connect(_on_actor_defeated)
	gm.combat.skill_cast.connect(_on_skill_cast)
	gm.combat.monster_skill_cast.connect(_on_monster_skill_cast)
	gm.hunters.hunter_leveled_up.connect(func(_hunter: HunterRuntime, _level: int, _healed: float) -> void:
		_village(&"level_up"))
	gm.buildings.building_placed.connect(func(_placed: BuildingService.Placed) -> void: _village(&"build"))
	gm.buildings.building_upgraded.connect(func(_id: StringName, _level: int) -> void: _village(&"upgrade"))
	gm.crafting.item_crafted.connect(func(_recipe: RecipeDefinition, _instance: StringName) -> void: _village(&"craft"))
	gm.recruitment.hunter_recruited.connect(func(_hunter: HunterRuntime) -> void: _village(&"recruit"))
	gm.expeditions.expedition_started.connect(func(_run: ExpeditionRun) -> void: _village(&"expedition_start"))
	gm.expeditions.expedition_finished.connect(func(_run: ExpeditionRun) -> void: _village(&"expedition_complete"))
	gm.weekly_boss.boss_defeated.connect(func(_reward: Dictionary) -> void: _village(&"victory"))
	gm.regions.bag_deposited.connect(func(_hunter: HunterRuntime, _report: Dictionary) -> void: _village(&"coins"))
	_update_music()


func _process(delta: float) -> void:
	_time += delta
	_check += delta
	if _check >= MUSIC_CHECK:
		_check = 0.0
		_update_music()


## A village event's sound, once the scene has settled.
func _village(id: StringName) -> void:
	if _time >= SETTLE_TIME:
		Audio.play_ui(id)


## Loot picked up (World.collect_drop).
func play_loot(at: Vector2) -> void:
	Audio.play(&"loot", at)


func _on_damage_dealt(_attacker: Actor, target: Actor, _amount: float, is_critical: bool) -> void:
	if is_instance_valid(target):
		Audio.play(&"crit" if is_critical else &"hit", target.global_position)


func _on_attack_dodged(_attacker: Actor, target: Actor) -> void:
	if is_instance_valid(target):
		Audio.play(&"dodge", target.global_position)


func _on_actor_defeated(actor: Actor, _by: Actor) -> void:
	if is_instance_valid(actor):
		Audio.play(&"hunter_fall" if actor is Hunter else &"enemy_death", actor.global_position)


func _on_skill_cast(caster: Actor, skill: ClassSkillDefinition) -> void:
	if not is_instance_valid(caster):
		return
	var element := ForgeLook.element_for_skill(skill)
	var heals := (skill.heal_ratio > 0.0 or skill.shield_ratio > 0.0) and not skill.deals_damage()
	Audio.play(&"heal" if heals and element == "none" else StringName("skill_" + element), caster.global_position)


func _on_monster_skill_cast(monster: Actor, skill: MonsterSkillDefinition) -> void:
	if is_instance_valid(monster):
		Audio.play(StringName("skill_" + SkillEffect.element_for(skill)), monster.global_position)


func _update_music() -> void:
	Audio.set_music(_wanted_music())


func _wanted_music() -> StringName:
	if GameManager.expeditions.is_running():
		return WILD
	var camera := get_viewport().get_camera_2d() if get_viewport() != null else null
	if camera == null or _world == null:
		return TOWN
	var region := _world.region_at(camera.get_screen_center_position())
	if region == null:
		# Over the water or a bridge: keep what plays.
		return Audio.get_music() if Audio.get_music() != &"" else TOWN
	match region.kind:
		RegionDefinition.Kind.BOSS:
			return BOSS
		RegionDefinition.Kind.HUNTING:
			return WILD
	return NIGHT if DayNight.is_night() else TOWN
