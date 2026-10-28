class_name BondService
extends RefCounted
## Bonds between pairs of Hunters (HUNTER_LIFE_SYSTEM.md §3, BALANCE.md → Bonds).
## One level in MVP: bonded at bond_max. Bonded partners in the same running expedition
## party get an attack bonus.

signal bond_changed(a_id: StringName, b_id: StringName, value: float)
signal milestone_reached(a_id: StringName, b_id: StringName, level: int)

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


func get_milestone(a_id: StringName, b_id: StringName) -> int:
	var val := get_value(a_id, b_id)
	if val >= _config.bond_max:
		return 2
	elif val >= _config.bond_max * 0.5:
		return 1
	return 0


func add(a_id: StringName, b_id: StringName, amount: float) -> void:
	if a_id == b_id or amount <= 0.0:
		return
	var key := _key(a_id, b_id)
	var old_val := _values.get(key, 0.0)
	var old_m := get_milestone(a_id, b_id)
	var value := minf(old_val + amount, _config.bond_max)
	if is_equal_approx(value, old_val):
		return
	_values[key] = value
	bond_changed.emit(a_id, b_id, value)
	var new_m := get_milestone(a_id, b_id)
	if new_m > old_m:
		milestone_reached.emit(a_id, b_id, new_m)
		var h_a := _hunters.get_hunter(a_id)
		var h_b := _hunters.get_hunter(b_id)
		if h_a != null and h_b != null:
			var deed_key := "chronicle.bond_oath" if new_m == 2 else "chronicle.bond_comrade"
			h_a.record_chronicle(deed_key, h_b.display_name)
			h_b.record_chronicle(deed_key, h_a.display_name)
			_hunters.notify_changed(h_a)
			_hunters.notify_changed(h_b)


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
	var highest_milestone := 0
	for partner_id in party:
		if partner_id == hunter.unique_id:
			continue
		var m := get_milestone(hunter.unique_id, partner_id)
		if m > highest_milestone:
			highest_milestone = m

	if highest_milestone >= 1:
		var atk := StatModifier.new()
		atk.stat = HunterService.ATTACK
		atk.type = StatModifier.Type.PERCENT
		atk.value = _config.bonded_attack_bonus if highest_milestone == 2 else (_config.bonded_attack_bonus * 0.5)
		modifiers.append(atk)

		var spd := StatModifier.new()
		spd.stat = HunterService.MOVE_SPEED
		spd.type = StatModifier.Type.PERCENT
		spd.value = 0.05
		modifiers.append(spd)

	if highest_milestone >= 2:
		var hp := StatModifier.new()
		hp.stat = HunterService.MAX_HP
		hp.type = StatModifier.Type.PERCENT
		hp.value = 0.10
		modifiers.append(hp)

		var def := StatModifier.new()
		def.stat = HunterService.DEFENSE
		def.type = StatModifier.Type.PERCENT
		def.value = 0.05
		modifiers.append(def)

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
