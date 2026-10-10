class_name BondService
extends RefCounted
## Bonds between pairs of Hunters (HUNTER_LIFE_SYSTEM.md §3, BALANCE.md → Bonds).
## One level in MVP: bonded at bond_max. Bonded partners in the same running expedition
## party get an attack bonus.

signal bond_changed(a_id: StringName, b_id: StringName, value: float)

var _hunters: HunterService
var _config: GameConfig
## "a|b" (sorted ids) -> value.
var _values: Dictionary[String, float] = {}
## `func() -> Array[StringName]`: ids of the party currently on an expedition (empty if none).
var _party_provider: Callable = func() -> Array: return []


func _init(hunters: HunterService, config: GameConfig) -> void:
	_hunters = hunters
	_config = config
	_hunters.add_modifier_source(get_modifiers)


func set_party_provider(provider: Callable) -> void:
	_party_provider = provider


func get_value(a_id: StringName, b_id: StringName) -> float:
	return _values.get(_key(a_id, b_id), 0.0)


func is_bonded(a_id: StringName, b_id: StringName) -> bool:
	return a_id != b_id and get_value(a_id, b_id) >= _config.bond_max


func add(a_id: StringName, b_id: StringName, amount: float) -> void:
	if a_id == b_id or amount <= 0.0:
		return
	var key := _key(a_id, b_id)
	var value := minf(_values.get(key, 0.0) + amount, _config.bond_max)
	if is_equal_approx(value, _values.get(key, 0.0)):
		return
	var was_bonded := is_bonded(a_id, b_id)
	_values[key] = value
	bond_changed.emit(a_id, b_id, value)
	if not was_bonded and is_bonded(a_id, b_id):
		# The party attack bonus depends on bonds.
		for hunter_id in [a_id, b_id]:
			var hunter := _hunters.get_hunter(hunter_id)
			if hunter != null:
				_hunters.notify_changed(hunter)


## Hunter id -> bond value for every partner with a non-zero bond.
func get_bonds(hunter_id: StringName) -> Dictionary[StringName, float]:
	var result: Dictionary[StringName, float] = {}
	for key in _values:
		var ids := key.split("|")
		if ids[0] == hunter_id:
			result[StringName(ids[1])] = _values[key]
		elif ids[1] == hunter_id:
			result[StringName(ids[0])] = _values[key]
	return result


func get_modifiers(hunter: HunterRuntime) -> Array[StatModifier]:
	var modifiers: Array[StatModifier] = []
	var party: Array[StringName] = []
	party.assign(_party_provider.call())
	if not party.has(hunter.unique_id):
		return modifiers
	for partner_id in party:
		if is_bonded(hunter.unique_id, partner_id):
			var modifier := StatModifier.new()
			modifier.stat = HunterService.ATTACK
			modifier.type = StatModifier.Type.PERCENT
			modifier.value = _config.bonded_attack_bonus
			modifiers.append(modifier)
			break
	return modifiers


## Every pair in the party grows closer (+20).
func on_expedition_finished(run: ExpeditionRun) -> void:
	for i in run.party_ids.size():
		for j in range(i + 1, run.party_ids.size()):
			add(run.party_ids[i], run.party_ids[j], _config.bond_shared_expedition)


func to_dict() -> Dictionary:
	return _values.duplicate()


## Restores saved bonds; pairs with unknown Hunters are dropped and reported.
func from_dict(data: Dictionary, warnings: PackedStringArray) -> void:
	_values.clear()
	for key in data:
		var ids := String(key).split("|")
		if ids.size() != 2 or _hunters.get_hunter(StringName(ids[0])) == null or _hunters.get_hunter(StringName(ids[1])) == null:
			warnings.append("bonds: dropped '%s'" % key)
			continue
		_values[_key(StringName(ids[0]), StringName(ids[1]))] = clampf(float(data[key]), 0.0, _config.bond_max)


static func _key(a_id: StringName, b_id: StringName) -> String:
	return "%s|%s" % ([a_id, b_id] if String(a_id) < String(b_id) else [b_id, a_id])
