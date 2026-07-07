class_name CombatStateMachine
extends Node

enum CombatState {
	STANDING_NEUTRAL,
	TOP_CLINCH,
	BOTTOM_CLINCH,
	TOP_GUARD,
	BOTTOM_GUARD,
	TOP_SIDE,
	BOTTOM_SIDE,
	TOP_MOUNT,
	BOTTOM_MOUNT,
	BACK_ATTACK,
	BACK_DEFENSE,
	TECHNICAL_ATTACK,
	TECHNICAL_DEFENSE,
	RESET
}

var current_state: CombatState = CombatState.STANDING_NEUTRAL
var previous_state: CombatState = CombatState.RESET

func _ready():
	SignalBus.state_changed.emit(StringName("STANDING_NEUTRAL"), StringName("RESET"))

func transition_to(new_state: CombatState) -> bool:
	if new_state == current_state:
		return false
	previous_state = current_state
	current_state = new_state
	SignalBus.state_changed.emit(StringName(get_current_state_name()), StringName(get_previous_state_name()))
	SignalBus.combat_state_changed.emit(get_previous_state_name(), get_current_state_name())
	return true

func get_current_state_name() -> String:
	return CombatState.keys()[current_state]

func get_previous_state_name() -> String:
	return CombatState.keys()[previous_state]

func reset() -> void:
	transition_to(CombatState.RESET)
