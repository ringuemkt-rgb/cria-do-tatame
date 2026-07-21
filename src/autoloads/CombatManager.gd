# Deprecated Strangler Fig facade. New code must call TransitionManager.
extends Node

var phase: int:
	get: return TransitionManager.phase
var arena_id: String:
	get: return TransitionManager.arena_id
var player_id: String:
	get: return TransitionManager.player_id
var opponent_id: String:
	get: return TransitionManager.opponent_id
var fighters: Dictionary:
	get: return TransitionManager.fighters
var is_running: bool:
	get: return TransitionManager.is_running
var last_result: Dictionary:
	get: return TransitionManager.last_result

func _ready() -> void:
	push_warning("[CombatManager] FACHADA ATIVA (deprecated). Migre para TransitionManager.")

func start_combat(new_arena_id: String, new_player_id: String, new_opponent_id: String) -> Dictionary:
	push_warning("[CombatManager] start_combat deprecated.")
	return TransitionManager.start_combat(new_arena_id, new_player_id, new_opponent_id)

func iniciar_combate(id_jogador: String, id_oponente: String, arena: String) -> void:
	push_warning("[CombatManager] iniciar_combate deprecated.")
	TransitionManager.iniciar_combate(id_jogador, id_oponente, arena)

func get_current_state_name() -> String:
	return TransitionManager.get_current_state_name()

func get_actor_state_name(actor_id: String) -> String:
	return TransitionManager.get_actor_state_name(actor_id)

func get_available_techniques(actor_id: String = "") -> Array:
	return TransitionManager.get_available_techniques(actor_id)

func apply_player_action(action_id: String) -> Dictionary:
	push_warning("[CombatManager] apply_player_action deprecated.")
	return TransitionManager.apply_player_action(action_id)

func apply_opponent_action(action_id: String) -> Dictionary:
	push_warning("[CombatManager] apply_opponent_action deprecated.")
	return TransitionManager.apply_opponent_action(action_id)

func apply_actor_action(actor_id: String, action_id: String) -> Dictionary:
	push_warning("[CombatManager] apply_actor_action deprecated.")
	return TransitionManager.apply_actor_action(actor_id, action_id)

func execute_technique(actor_id: String, defender_id: String, technique: Dictionary) -> Dictionary:
	push_warning("[CombatManager] execute_technique deprecated.")
	return TransitionManager.execute_technique(actor_id, defender_id, technique)

func finish_combat(result: Dictionary) -> void:
	push_warning("[CombatManager] finish_combat deprecated.")
	TransitionManager.finish_combat(result)

func finalizar_combate(result: Dictionary) -> void:
	push_warning("[CombatManager] finalizar_combate deprecated.")
	TransitionManager.finalizar_combate(result)
