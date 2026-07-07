extends Node

signal data_loaded()
signal data_validation_finished(report)

signal combat_started(arena_id, player_id, opponent_id)
signal combat_finished(result)
signal combat_state_changed(old_state, new_state)
signal state_changed(new_state, old_state)
signal resources_changed(fighter_id, resources)
signal resource_changed(resource_name, new_value, max_value)
signal technique_started(technique_id, actor_id)
signal technique_resolved(result)
signal grip_integrity_broken(character_id)
signal technical_phase_changed(phase)

signal week_advanced(week, day)
signal day_advanced(day_name, week_number)
signal mission_started(mission_id)
signal mission_completed(mission_id)
signal skill_unlocked(skill_id)
signal sponsor_contract_signed(sponsor_id)
signal crisis_triggered(crisis_id)

signal reputation_changed(axis, value, reason)
signal reputation_delta(axis, delta)
signal cria_live_post_created(post)
signal cria_live_post_generated(post_data)

signal save_requested(slot_id)
signal save_completed(slot_id)
signal save_loaded(slot_id)
signal scene_transition_requested(scene_path)
signal system_message(source, message)

func emit_system_message(source, message):
	system_message.emit(source, message)

func request_scene(scene_path):
	scene_transition_requested.emit(scene_path)
