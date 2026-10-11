class_name RegionSpawner
extends Node
## Monsters of one region (AUTONOMY_SYSTEM.md → Hunting, BALANCE.md → Regions, D29): fills the
## region up to its population cap, respawns the fallen after `respawn_seconds`, keeps monsters
## near their spawn point (wander, aggro range, leash) and reports kills to RegionService.
## Monster nodes live under the world's y-sorted Actors node.

## A monster died; `reward` went to `killer` (popups).
signal monster_killed(enemy: Enemy, killer: Hunter, reward: KillReward)

const WANDER_RADIUS := 56.0
const WANDER_MIN_WAIT := 3.0
const WANDER_MAX_WAIT := 8.0
## Back home after a leash: within this distance it may aggro again.
const HOME_DISTANCE := 16.0
## Spawn points keep this far from gates and dungeon entrances.
const SPAWN_CLEARANCE := 110.0
const SPAWN_TRIES := 20

## Per-monster state.
class Monster:
	var enemy: Enemy
	var home: Vector2
	var leashing := false
	var wander_in := 0.0
	## Hunters that hit it (they share the XP).
	var attackers: Array[Hunter] = []

var region: RegionDefinition
var _map: WorldMap
var _actors: Node2D
var _monsters: Array[Monster] = []
## Seconds left for each pending respawn.
var _respawns: Array[float] = []
var _rng := RandomNumberGenerator.new()


func setup(map: WorldMap, actors: Node2D, region_definition: RegionDefinition, seed_value: int) -> void:
	_map = map
	_actors = actors
	region = region_definition
	name = "Spawner_%s" % region.id
	_rng.seed = seed_value
	GameManager.combat.damage_dealt.connect(_on_damage_dealt)
	GameManager.combat.actor_defeated.connect(_on_actor_defeated)


## Fills the region (call once navigation is baked).
func populate() -> void:
	for i in region.population_cap - _monsters.size():
		if _spawn() == null:
			# No spot found (yet): try again shortly.
			_respawns.append(1.0)


func get_monsters() -> Array[Enemy]:
	var result: Array[Enemy] = []
	for monster in _monsters:
		if is_instance_valid(monster.enemy) and monster.enemy.is_targetable():
			result.append(monster.enemy)
	return result


func _physics_process(delta: float) -> void:
	for i in range(_respawns.size() - 1, -1, -1):
		_respawns[i] -= delta
		if _respawns[i] <= 0.0:
			_respawns.remove_at(i)
			if _spawn() == null:
				_respawns.append(1.0)
	for monster in _monsters:
		if is_instance_valid(monster.enemy) and monster.enemy.is_targetable():
			_update_monster(monster, delta)


func _spawn() -> Enemy:
	var definition := GameManager.regions.roll_monster(region)
	if definition == null or definition.actor_scene == null:
		return null
	var at := _random_point()
	if at == Vector2.INF:
		return null
	var level := GameManager.regions.roll_level(region)
	var enemy := definition.actor_scene.instantiate() as Enemy
	_actors.add_child(enemy)
	enemy.global_position = at
	enemy.setup(definition, GameManager.combat, DataRegistry.config.retarget_interval, level, GameManager.regions.get_stat_scale(level))
	var monster := Monster.new()
	monster.enemy = enemy
	monster.home = at
	monster.wander_in = _rng.randf_range(0.0, WANDER_MAX_WAIT)
	enemy.combat.acquire_filter = _can_aggro.bind(monster)
	enemy.combat.keep_filter = _can_keep.bind(monster)
	_monsters.append(monster)
	return enemy


## A walkable point inside the region, away from gates and dungeon entrances.
func _random_point() -> Vector2:
	var rect := region.tile_rect.grow(-1)
	var navigation_map := _map.get_world_2d().navigation_map
	for attempt in SPAWN_TRIES:
		var tile := Vector2(_rng.randf_range(rect.position.x, rect.end.x), _rng.randf_range(rect.position.y, rect.end.y))
		var point := NavigationServer2D.map_get_closest_point(navigation_map, WorldService.tile_to_world(tile))
		if _map.world.region_at(point) != region:
			continue
		if _map.get_keep_clear_points().any(func(p: Vector2) -> bool: return p.distance_to(point) < SPAWN_CLEARANCE):
			continue
		return point
	return Vector2.INF


func _update_monster(monster: Monster, delta: float) -> void:
	var enemy := monster.enemy
	var config: GameConfig = DataRegistry.config
	var from_home := enemy.global_position.distance_to(monster.home)
	if not monster.leashing and from_home > config.monster_leash_range:
		# Pulled too far: give up and walk home (BALANCE.md → Regions).
		monster.leashing = true
		monster.attackers.clear()
		enemy.combat.recheck()
		enemy.travel_target = monster.home
	if monster.leashing:
		if from_home <= HOME_DISTANCE:
			monster.leashing = false
			enemy.health.heal(enemy.health.max_health)
		return
	if enemy.combat.target != null:
		return
	monster.wander_in -= delta
	if monster.wander_in <= 0.0:
		monster.wander_in = _rng.randf_range(WANDER_MIN_WAIT, WANDER_MAX_WAIT)
		var offset := Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(0.0, WANDER_RADIUS)
		enemy.travel_target = monster.home + Vector2(offset.x, offset.y * 0.5)


## New targets: Hunters in this region within aggro range, or Hunters already hitting it.
func _can_aggro(candidate: Actor, monster: Monster) -> bool:
	if monster.leashing or not _in_region(candidate):
		return false
	return candidate.global_position.distance_to(monster.enemy.global_position) <= DataRegistry.config.monster_aggro_range \
		or candidate.combat.target == monster.enemy


func _can_keep(candidate: Actor, monster: Monster) -> bool:
	return not monster.leashing and _in_region(candidate)


func _in_region(actor: Actor) -> bool:
	return _map.world.region_at(actor.global_position) == region


func _find(enemy: Actor) -> Monster:
	for monster in _monsters:
		if monster.enemy == enemy:
			return monster
	return null


func _on_damage_dealt(attacker: Actor, target: Actor, _amount: float, _is_critical: bool) -> void:
	var monster := _find(target)
	if monster != null and attacker is Hunter and not monster.attackers.has(attacker):
		monster.attackers.append(attacker as Hunter)


func _on_actor_defeated(actor: Actor, by: Actor) -> void:
	var monster := _find(actor)
	if monster == null:
		return
	_monsters.erase(monster)
	_respawns.append(region.respawn_seconds)
	var killer := by as Hunter
	if killer == null or killer.runtime == null:
		return
	var helpers: Array[HunterRuntime] = []
	for hunter in monster.attackers:
		if is_instance_valid(hunter) and hunter != killer:
			helpers.append(hunter.runtime)
	var reward := GameManager.regions.record_kill(killer.runtime, helpers, monster.enemy.definition, monster.enemy.level)
	monster_killed.emit(monster.enemy, killer, reward)
