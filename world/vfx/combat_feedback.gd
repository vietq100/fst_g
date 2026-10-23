class_name CombatFeedback
extends Node2D
## Spawns combat VFX in the world from CombatService signals. Presentation only.
## Add one to any scene where combat happens (test arena, expedition).

## Number appears above the target's head.
const NUMBER_OFFSET := Vector2(0, -36)
const NUMBER_JITTER := 6.0
## Hits on one target this close together (ms) add up into one number instead of a shower of
## small ones.
const MERGE_WINDOW_MS := 350
## Screen shake [strength px, seconds] per cause (CameraShake; Settings → Display).
const SHAKE_BOSS_SKILL := [5.0, 0.35]
const SHAKE_HUNTER_DOWN := [4.0, 0.3]

## Target instance id → {"number": DamageNumber, "until": ticks ms} for merging.
var _merged: Dictionary = {}
var _shake := CameraShake.new()


func _ready() -> void:
	z_index = 100
	add_child(_shake)
	GameManager.combat.damage_dealt.connect(_on_damage_dealt)
	GameManager.combat.effect_damage_dealt.connect(_on_effect_damage_dealt)
	GameManager.combat.skill_cast.connect(_on_skill_cast)
	GameManager.combat.monster_skill_cast.connect(_on_monster_skill_cast)
	GameManager.combat.actor_defeated.connect(_on_actor_defeated)
	GameManager.combat.attack_dodged.connect(_on_attack_dodged)
	GameManager.combat.actor_healed.connect(_on_actor_healed)


## Attackers with a longer reach than this shoot (arrow streak).
const RANGED_REACH := 60.0
const IMMUNE_COLOR := Color("ffe9a8")
const EFFECT_FONT_SIZE := 10


func _on_damage_dealt(attacker: Actor, target: Actor, amount: float, is_critical: bool) -> void:
	if not is_instance_valid(target):
		return
	if is_instance_valid(attacker) and attacker.combat.attack_range > RANGED_REACH:
		var streak := ArrowStreak.new()
		add_child(streak)
		streak.setup(attacker.global_position + Vector2(0, -14), target.global_position + Vector2(0, -12))
	if amount <= 0.0 and target.effects.is_invulnerable():
		_spawn_number(target).show_text(Loc.t("world.popup.immune"), IMMUNE_COLOR)
		return
	if target is Enemy and is_instance_valid(attacker):
		target.visual.play_knockback(target.global_position - attacker.global_position)
	# A hit soon after another on the same target joins that number.
	var key := target.get_instance_id()
	var now := Time.get_ticks_msec()
	var entry: Dictionary = _merged.get(key, {})
	if not entry.is_empty() and now <= entry["until"] and is_instance_valid(entry["number"]):
		entry["number"].absorb(amount, is_critical)
		entry["until"] = now + MERGE_WINDOW_MS
		return
	if _merged.size() > 64:
		_merged.clear()
	var number := _spawn_number(target)
	number.setup(amount, is_critical, target is Hunter)
	_merged[key] = {"number": number, "until": now + MERGE_WINDOW_MS}


## A boss skill rocks the screen a little.
func _on_monster_skill_cast(monster: Actor, _skill: MonsterSkillDefinition) -> void:
	var enemy := monster as Enemy
	if enemy != null and enemy.definition != null and enemy.definition.is_boss:
		_shake.shake(SHAKE_BOSS_SKILL[0], SHAKE_BOSS_SKILL[1])


## A Hunter going down is felt, not just seen.
func _on_actor_defeated(actor: Actor, _by: Actor) -> void:
	if actor is Hunter:
		_shake.shake(SHAKE_HUNTER_DOWN[0], SHAKE_HUNTER_DOWN[1])


## Damage over time and thorns: small number in the effect's colour (D48).
func _on_effect_damage_dealt(_source: Actor, target: Actor, amount: float, effect: StatusEffectDefinition) -> void:
	if not is_instance_valid(target):
		return
	var color := effect.color if effect != null else DamageNumber.COLOR
	if amount <= 0.0:
		if target.effects.is_invulnerable():
			_spawn_number(target).show_text(Loc.t("world.popup.immune"), IMMUNE_COLOR, EFFECT_FONT_SIZE)
		return
	_spawn_number(target).show_text(str(roundi(amount)), color, EFFECT_FONT_SIZE)


func _spawn_number(target: Actor) -> DamageNumber:
	var number := DamageNumber.new()
	add_child(number)
	number.global_position = target.global_position + NUMBER_OFFSET + Vector2(randf_range(-NUMBER_JITTER, NUMBER_JITTER), 0)
	return number


const SKILL_COLOR := Color("9fb4ff")
const HEAL_COLOR := Color("7fe08a")
const MISS_COLOR := Color("d8dde3")


## Class skill name over the caster (D70).
func _on_skill_cast(caster: Actor, skill: ClassSkillDefinition) -> void:
	if is_instance_valid(caster) and skill != null:
		_spawn_number(caster).show_text(skill.display_name, SKILL_COLOR, EFFECT_FONT_SIZE)


func _on_attack_dodged(_attacker: Actor, target: Actor) -> void:
	if is_instance_valid(target):
		_spawn_number(target).show_text(Loc.t("world.popup.miss"), MISS_COLOR, EFFECT_FONT_SIZE)


func _on_actor_healed(_source: Actor, target: Actor, amount: float) -> void:
	if is_instance_valid(target) and amount >= 1.0:
		_spawn_number(target).show_text("+%d" % roundi(amount), HEAL_COLOR, EFFECT_FONT_SIZE)
