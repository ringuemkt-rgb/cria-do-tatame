extends Node

signal combat_started(arena_id, player_id, opponent_id)
signal combat_finished(result)
signal combat_state_changed(old_state, new_state)
signal resources_changed(fighter_id, resources)
signal reputation_changed(axis, value, reason)
signal week_advanced(week, day)
signal mission_started(mission_id)
signal mission_completed(mission_id)
signal skill_unlocked(skill_id)
signal cria_live_post_created(post)
signal save_requested(slot_id)
signal save_completed(slot_id)
signal save_loaded(slot_id)
signal data_loaded()
signal system_message(source, message)

func emit_system_message(source, message):
	system_message.emit(source, message)
