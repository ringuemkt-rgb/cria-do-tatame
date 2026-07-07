extends Node
class_name SignalBus

signal career_state_changed(state: Dictionary)
signal world_week_advanced(clock_state: Dictionary)
signal rival_memory_changed(rival_id: String, memory: Dictionary)
signal reputation_changed(reputation: Dictionary)
signal technique_started(technique_id: String, actor_id: String)
signal technique_resolved(result: Dictionary)
signal combat_state_changed(previous_state: String, next_state: String)
signal score_changed(score_state: Dictionary)
signal cria_live_posted(post: Dictionary)
signal pending_event_triggered(event_data: Dictionary)

func publish_career_state(state: Dictionary) -> void:
	career_state_changed.emit(state)

func publish_combat_state(previous_state: String, next_state: String) -> void:
	combat_state_changed.emit(previous_state, next_state)

func publish_technique_result(result: Dictionary) -> void:
	technique_resolved.emit(result)
