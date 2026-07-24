extends Node

signal data_loaded()
signal data_validation_finished(report)

signal combat_started(arena_id, player_id, opponent_id)
signal combat_finished(result)
signal combat_ended(result)
signal combat_state_changed(old_state, new_state)
signal state_changed(new_state, old_state)
signal resources_changed(fighter_id, resources)
signal resource_changed(resource_name, new_value, max_value)
signal technique_started(technique_id, actor_id)
signal technique_executed(character_id, technique_id)
signal technique_resolved(result)
signal grip_integrity_broken(character_id)
signal technical_phase_changed(phase)
signal submission_phase_changed(phase)
signal combat_deck_hand_changed(hand, selected_card_id)
signal combat_card_selected(card)
signal technique_clash_resolved(result)
signal card_xp_changed(card_id, xp, xp_to_next)
signal deck_configuration_changed(deck_state)

# Contratos do combate posicional v4.1.
signal positional_mode_changed(active, ruleset_id)
signal positional_snapshot_changed(snapshot)
signal combat_hand_changed_v41(hand)
signal combat_card_selected_v41(card_id)
signal defense_window_opened_v41(window)
signal dirty_move_attempted(card_id)
signal moral_tension_changed(value)
signal code_break_in_final(broken)

# Contratos de compatibilidade PT-BR usados por módulos e conteúdo legado.
# Mantidos explicitamente para que listeners antigos não falhem em silêncio.
signal combate_iniciado(opponent_id)
signal combate_finalizado(result)
signal estado_combate_mudou(new_state, old_state)
signal recurso_mudou(fighter_id, resource_name, value, max_value)
signal tecnica_executada(character_id, technique_id, success)

signal week_advanced(week, day)
signal week_completed(week_number)
signal day_advanced(day_name, week_number)
signal belt_promoted(new_belt)
signal mission_started(mission_id)
signal mission_completed(mission_id)
signal skill_unlocked(skill_id)
signal sponsor_contract_signed(sponsor_id)
signal sponsor_contract_broken(sponsor_id)
signal crisis_triggered(crisis_id)

signal dia_avancou(day_name, week_number)

signal reputation_changed(axis, value, reason)
signal reputation_delta(axis, delta)
signal cria_live_post_created(post)
signal cria_live_post_generated(post_data)
signal cria_live_metrics_changed(faction_id, metrics)

signal reputacao_mudou(axis, delta, new_value)

signal faction_relation_changed(faction_id, delta, new_value, reason)
signal faction_heat_changed(faction_id, delta, new_value, reason)
signal faction_power_changed(faction_id, dimension, delta, new_value, reason)
signal faction_week_completed(snapshot)
signal faction_operation_started(operation)
signal faction_operation_resolved(operation)
signal faction_conflict_changed(conflict)
signal faction_territory_changed(territory_id, territory)
signal faction_leadership_changed(faction_id, old_leader, new_leader)
signal faction_memory_recorded(memory)
signal faction_debt_changed(debt)
signal regional_pressure_changed(level, axes)

signal world_tick_completed(snapshot)
signal weather_changed(region_id, old_weather, new_weather)
signal world_event_triggered(event_data)
signal npc_routine_changed(npc_id, routine)
signal rival_strategy_updated(rival_id, directive)
signal world_economy_changed(multipliers)
signal world_ai_plan_applied(plan)
signal world_ai_plan_failed(reason)

signal nft_entitlements_synced(entitlements, source)
signal nft_entitlement_sync_failed(reason)

signal save_requested(slot_id)
signal save_completed(slot_id)
signal save_loaded(slot_id)
signal scene_transition_requested(scene_path)
signal dialogue_started(dialogue_id)
signal dialogue_ended(dialogue_id)
signal system_message(source, message)

func emit_system_message(source, message):
	system_message.emit(source, message)

func request_scene(scene_path):
	scene_transition_requested.emit(scene_path)
