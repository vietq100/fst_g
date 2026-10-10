class_name StateController
extends Node
## In-scene behaviour state of an actor. Not the Hunter lifecycle (that lives in HunterRuntime).

signal state_changed(previous: State, current: State)

enum State { IDLE, MOVING, ATTACKING, DOWNED }

var current: State = State.IDLE


## DOWNED can only be left through `revive()`. Returns false when the change is not allowed.
func change(new_state: State) -> bool:
	if new_state == current:
		return true
	if current == State.DOWNED:
		return false
	_apply(new_state)
	return true


func revive() -> void:
	if current == State.DOWNED:
		_apply(State.IDLE)


func is_state(state: State) -> bool:
	return current == state


func _apply(new_state: State) -> void:
	var previous := current
	current = new_state
	state_changed.emit(previous, current)
