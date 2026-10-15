class_name StatService
extends RefCounted
## Single place for the stat pipeline and combat/progression formulas
## (DECISIONS.md D18, D19; BALANCE.md → Formulas). Constants come from GameConfig.

var _config: GameConfig


func _init(config: GameConfig) -> void:
	_config = config


## (base + growth × (level - 1) + Σflat) × (1 + Σpercent), never below 0.
## Modifiers for other stats, or with a condition not in `active_conditions`, are ignored.
func compute_stat(
		stat: StringName,
		base: float,
		growth_per_level: float,
		level: int,
		modifiers: Array[StatModifier] = [],
		active_conditions: Array[StringName] = []
) -> float:
	var flat := 0.0
	var percent := 0.0
	for modifier in modifiers:
		if modifier == null or modifier.stat != stat:
			continue
		if modifier.condition != &"" and not active_conditions.has(modifier.condition):
			continue
		match modifier.type:
			StatModifier.Type.FLAT:
				flat += modifier.value
			StatModifier.Type.PERCENT:
				percent += modifier.value
	var value := (base + growth_per_level * maxi(level - 1, 0) + flat) * (1.0 + percent)
	return maxf(value, 0.0)


func calculate_damage(attack: float, defense: float) -> float:
	return maxf(_config.min_damage, attack - defense * _config.defense_factor)


func apply_critical(damage: float, critical_damage: float) -> float:
	return damage * critical_damage


func roll_critical(critical_chance: float, rng: RandomNumberGenerator) -> bool:
	return rng.randf() < critical_chance


## Seconds between attacks. Returns INF for non-positive attack speed.
func attack_cooldown(attack_speed: float) -> float:
	if attack_speed <= 0.0:
		return INF
	return 1.0 / attack_speed


## XP needed to go from `level` to `level + 1`.
func required_xp(level: int) -> int:
	return ceili(_config.base_xp * pow(maxi(level, 1), _config.xp_exponent))


func level_cap(town_hall_level: int) -> int:
	return mini(maxi(town_hall_level, 1) * _config.level_cap_per_town_level, _config.max_hunter_level)
