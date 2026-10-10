class_name ExpeditionScene
extends Node2D
## Presentation and pacing of one expedition run (EXPEDITION_SYSTEM.md, MAP_DESIGN.md).
## Spawns the party and each section's enemies at the scene's markers, walks the party
## between sections and reports kills, downs and the end of the run to ExpeditionService.
##
## Expected children: NavigationRegion2D, World/Actors, Markers/{HunterSpawn, Sections/*,
## BossRally, BossSpawn, Exit}, Camera2D. Each Sections child is a rally Marker2D whose own
## Marker2D children are enemy spawn points.

const HUNTER_SCENE := preload("res://actors/hunter/hunter.tscn")
## Party counts as arrived when its centre is this close to a rally point.
const ARRIVE_RADIUS := 48.0
## Formation offsets around a travel point so the party does not converge on one spot.
const FORMATION: Array[Vector2] = [Vector2(0, 0), Vector2(-20, 14), Vector2(20, 14)]
const SPAWN_JITTER := 10.0
const LOOT_POPUP_STAGGER := 0.12
const LOOT_LINE_HEIGHT := 12.0

enum Stage { TRAVEL, FIGHT, TO_EXIT, DONE }

@onready var _navigation: NavigationRegion2D = $NavigationRegion2D
@onready var _actors: Node2D = $World/Actors
@onready var _camera: Camera2D = $Camera2D
@onready var _hunter_spawn: Marker2D = $Markers/HunterSpawn
@onready var _sections: Node2D = $Markers/Sections
@onready var _boss_rally: Marker2D = $Markers/BossRally
@onready var _boss_spawn: Marker2D = $Markers/BossSpawn
@onready var _exit: Marker2D = $Markers/Exit

var _service: ExpeditionService
var _definition: ExpeditionDefinition
var _party: Array[Hunter] = []
var _enemies: Array[Enemy] = []
var _stage := Stage.DONE
## Section the party is walking to or fighting in; == enemy_groups.size() is the boss.
var _section := 0
var _travel_point := Vector2.ZERO
var _status_label: Label


func _ready() -> void:
	# Bake at runtime so props in the `navigation_obstacles` group carve the walkable area.
	_navigation.bake_navigation_polygon(false)


## Called by Main once the run has started.
func start(service: ExpeditionService) -> void:
	_service = service
	_definition = service.get_current_definition()
	var index := 0
	for hunter_id in service.current_run.party_ids:
		var runtime := GameManager.hunters.get_hunter(hunter_id)
		var hunter := HUNTER_SCENE.instantiate() as Hunter
		_actors.add_child(hunter)
		hunter.global_position = _hunter_spawn.global_position + FORMATION[index % FORMATION.size()]
		hunter.setup(runtime, GameManager.hunters, GameManager.combat, DataRegistry.config.retarget_interval, GameManager.equipment)
		hunter.health.died.connect(_on_hunter_downed.bind(hunter))
		_party.append(hunter)
		index += 1
	_camera.party = _party
	_camera.snap_to_party()
	_go_to_section(0)


func setup_debug(panel: DebugPanel) -> void:
	panel.add_separator()
	panel.add_button_row([
		["Kill wave", _debug_kill_wave],
		["Party Lv 10", _debug_party_level],
		["Wipe party", _debug_wipe],
	])
	_status_label = panel.add_label("")
	_refresh_status()


func _physics_process(_delta: float) -> void:
	match _stage:
		Stage.TRAVEL:
			if _party_center().distance_to(_travel_point) <= ARRIVE_RADIUS:
				_spawn_section(_section)
		Stage.FIGHT:
			_enemies = _enemies.filter(func(enemy: Enemy) -> bool: return is_instance_valid(enemy) and enemy.is_targetable())
			if _enemies.is_empty():
				_on_section_cleared()
		Stage.TO_EXIT:
			if _party_center().distance_to(_exit.global_position) <= ARRIVE_RADIUS:
				_set_travel(Vector2.INF)
				_stage = Stage.DONE
				_service.complete()
				_refresh_status()


func _go_to_section(index: int) -> void:
	_section = index
	_stage = Stage.TRAVEL
	_service.set_party_traveling()
	_set_travel(_rally_point(index))
	_refresh_status()


func _spawn_section(index: int) -> void:
	_stage = Stage.FIGHT
	_set_travel(Vector2.INF)
	if _service.is_boss_section(index):
		_spawn_enemy(_definition.boss_id, _boss_spawn.global_position)
	else:
		var points := _sections.get_child(index).get_children()
		var slot := 0
		for spawn in _definition.enemy_groups[index].spawns:
			for i in spawn.count:
				var marker := points[slot % points.size()] as Marker2D
				var jitter := Vector2(randf_range(-SPAWN_JITTER, SPAWN_JITTER), randf_range(-SPAWN_JITTER, SPAWN_JITTER))
				_spawn_enemy(spawn.enemy_id, marker.global_position + jitter)
				slot += 1
	_service.begin_section(index)
	_refresh_status()


func _on_section_cleared() -> void:
	if _service.is_boss_section(_section):
		_stage = Stage.TO_EXIT
		_service.begin_return()
		_set_travel(_exit.global_position)
		_refresh_status()
	else:
		_go_to_section(_section + 1)


func _spawn_enemy(enemy_id: StringName, at: Vector2) -> void:
	var definition := DataRegistry.get_enemy(enemy_id)
	if definition == null or definition.actor_scene == null:
		return
	var enemy := definition.actor_scene.instantiate() as Enemy
	_actors.add_child(enemy)
	enemy.global_position = at
	enemy.setup(definition, GameManager.combat, DataRegistry.config.retarget_interval)
	enemy.health.died.connect(_on_enemy_died.bind(enemy))
	_enemies.append(enemy)


func _on_enemy_died(enemy: Enemy) -> void:
	var reward := _service.record_kill(enemy.definition)
	_show_loot(reward, enemy.global_position)
	_refresh_status()


## Loot is collected automatically (D5); popups show what went into the stash.
## Lines stack upwards (gold at the bottom) so several drops never overlap.
func _show_loot(reward: KillReward, at: Vector2) -> void:
	var line := 0
	if reward.gold > 0:
		_spawn_popup("+%d gold" % reward.gold, RarityColors.GOLD, at, 0.0)
		line += 1
	for item_id in reward.items:
		var item := DataRegistry.get_item(item_id)
		if item != null:
			var offset := Vector2(0, -LOOT_LINE_HEIGHT * line)
			_spawn_popup("+%d %s" % [reward.items[item_id], item.display_name], RarityColors.of(item.rarity), at + offset, LOOT_POPUP_STAGGER * line)
			line += 1


func _spawn_popup(text: String, color: Color, at: Vector2, delay: float) -> void:
	var popup := LootPopup.new()
	_actors.get_parent().add_child(popup)
	popup.global_position = at
	popup.setup(text, color, delay)


func _on_hunter_downed(hunter: Hunter) -> void:
	if _stage == Stage.DONE:
		return
	_service.mark_downed(hunter.runtime.unique_id)
	if _service.is_party_wiped():
		_stage = Stage.DONE
		_service.fail()
	_refresh_status()


func _set_travel(point: Vector2) -> void:
	_travel_point = point
	for i in _party.size():
		_party[i].travel_target = Vector2.INF if point == Vector2.INF else point + FORMATION[i % FORMATION.size()]


func _rally_point(index: int) -> Vector2:
	if _service.is_boss_section(index):
		return _boss_rally.global_position
	return (_sections.get_child(index) as Marker2D).global_position


func _party_center() -> Vector2:
	var sum := Vector2.ZERO
	var count := 0
	for hunter in _party:
		if hunter.is_targetable():
			sum += hunter.global_position
			count += 1
	return sum / count if count > 0 else Vector2.INF


func _refresh_status() -> void:
	if _status_label == null or _service == null or _service.current_run == null:
		return
	var run := _service.current_run
	var where := "Boss" if _service.is_boss_section(_section) else "Section %d/%d" % [_section + 1, _definition.enemy_groups.size()]
	_status_label.text = "%s  %s  %s\nKills %d  Stash %d gold  XP %d each\nDowned %d/%d\nStash: %s" % [
		_definition.display_name, where, Stage.keys()[_stage],
		run.kills, run.stash_gold, run.xp_per_hunter,
		run.downed_ids.size(), run.party_ids.size(),
		ItemText.describe(run.stash_items, DataRegistry),
	]


func _debug_kill_wave() -> void:
	for enemy in _enemies.duplicate():
		if is_instance_valid(enemy):
			enemy.health.take_damage(INF)


func _debug_party_level() -> void:
	for hunter in _party:
		GameManager.hunters.set_level(hunter.runtime, 10)


func _debug_wipe() -> void:
	for hunter in _party:
		hunter.health.take_damage(INF)
