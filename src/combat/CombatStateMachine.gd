class_name CombatStateMachine
extends Node

# Maquina de estados relativa ao jogador.
# Mantem aliases antigos para nao quebrar o CombatManager ja existente.

enum CombatState {
	PLAYER_STANDING_NEUTRAL,
	PLAYER_TOP_CLINCH,
	PLAYER_BOTTOM_CLINCH,
	PLAYER_TOP_GUARD,
	PLAYER_BOTTOM_GUARD,
	PLAYER_TOP_SIDE,
	PLAYER_BOTTOM_SIDE,
	PLAYER_TOP_MOUNT,
	PLAYER_BOTTOM_MOUNT,
	PLAYER_BACK_ATTACK,
	PLAYER_BACK_DEFENSE,
	PLAYER_SUBMISSION_ATTACK,
	PLAYER_SUBMISSION_DEFENSE,
	RESET,
	STANDING_NEUTRAL = PLAYER_STANDING_NEUTRAL,
	TOP_CLINCH = PLAYER_TOP_CLINCH,
	BOTTOM_CLINCH = PLAYER_BOTTOM_CLINCH,
	TOP_GUARD = PLAYER_TOP_GUARD,
	BOTTOM_GUARD = PLAYER_BOTTOM_GUARD,
	TOP_SIDE = PLAYER_TOP_SIDE,
	BOTTOM_SIDE = PLAYER_BOTTOM_SIDE,
	TOP_MOUNT = PLAYER_TOP_MOUNT,
	BOTTOM_MOUNT = PLAYER_BOTTOM_MOUNT,
	BACK_ATTACK = PLAYER_BACK_ATTACK,
	BACK_DEFENSE = PLAYER_BACK_DEFENSE,
	TECHNICAL_ATTACK = PLAYER_SUBMISSION_ATTACK,
	TECHNICAL_DEFENSE = PLAYER_SUBMISSION_DEFENSE
}

var current_state: int = CombatState.PLAYER_STANDING_NEUTRAL
var previous_state: int = CombatState.RESET

var transicoes_validas := {
	CombatState.PLAYER_STANDING_NEUTRAL: [CombatState.PLAYER_TOP_CLINCH, CombatState.PLAYER_BOTTOM_CLINCH, CombatState.PLAYER_TOP_GUARD, CombatState.PLAYER_BOTTOM_GUARD, CombatState.RESET],
	CombatState.PLAYER_TOP_CLINCH: [CombatState.PLAYER_STANDING_NEUTRAL, CombatState.PLAYER_TOP_GUARD, CombatState.PLAYER_TOP_SIDE, CombatState.PLAYER_BACK_ATTACK, CombatState.RESET],
	CombatState.PLAYER_BOTTOM_CLINCH: [CombatState.PLAYER_STANDING_NEUTRAL, CombatState.PLAYER_BOTTOM_GUARD, CombatState.PLAYER_BOTTOM_SIDE, CombatState.PLAYER_BACK_DEFENSE, CombatState.RESET],
	CombatState.PLAYER_TOP_GUARD: [CombatState.PLAYER_TOP_SIDE, CombatState.PLAYER_TOP_MOUNT, CombatState.PLAYER_BOTTOM_GUARD, CombatState.PLAYER_STANDING_NEUTRAL, CombatState.RESET],
	CombatState.PLAYER_BOTTOM_GUARD: [CombatState.PLAYER_TOP_GUARD, CombatState.PLAYER_BOTTOM_SIDE, CombatState.PLAYER_SUBMISSION_ATTACK, CombatState.PLAYER_STANDING_NEUTRAL, CombatState.RESET],
	CombatState.PLAYER_TOP_SIDE: [CombatState.PLAYER_TOP_MOUNT, CombatState.PLAYER_BACK_ATTACK, CombatState.PLAYER_TOP_GUARD, CombatState.PLAYER_SUBMISSION_ATTACK, CombatState.RESET],
	CombatState.PLAYER_BOTTOM_SIDE: [CombatState.PLAYER_BOTTOM_GUARD, CombatState.PLAYER_BOTTOM_MOUNT, CombatState.PLAYER_BACK_DEFENSE, CombatState.RESET],
	CombatState.PLAYER_TOP_MOUNT: [CombatState.PLAYER_BACK_ATTACK, CombatState.PLAYER_TOP_SIDE, CombatState.PLAYER_SUBMISSION_ATTACK, CombatState.RESET],
	CombatState.PLAYER_BOTTOM_MOUNT: [CombatState.PLAYER_BOTTOM_GUARD, CombatState.PLAYER_BOTTOM_SIDE, CombatState.PLAYER_SUBMISSION_DEFENSE, CombatState.RESET],
	CombatState.PLAYER_BACK_ATTACK: [CombatState.PLAYER_SUBMISSION_ATTACK, CombatState.PLAYER_TOP_MOUNT, CombatState.PLAYER_TOP_SIDE, CombatState.RESET],
	CombatState.PLAYER_BACK_DEFENSE: [CombatState.PLAYER_BOTTOM_GUARD, CombatState.PLAYER_BOTTOM_SIDE, CombatState.PLAYER_SUBMISSION_DEFENSE, CombatState.RESET],
	CombatState.PLAYER_SUBMISSION_ATTACK: [CombatState.RESET, CombatState.PLAYER_TOP_MOUNT, CombatState.PLAYER_TOP_SIDE, CombatState.PLAYER_BACK_ATTACK],
	CombatState.PLAYER_SUBMISSION_DEFENSE: [CombatState.RESET, CombatState.PLAYER_BOTTOM_GUARD, CombatState.PLAYER_BOTTOM_SIDE, CombatState.PLAYER_BACK_DEFENSE],
	CombatState.RESET: [CombatState.PLAYER_STANDING_NEUTRAL]
}

func _ready() -> void:
	_emitir_estado()

func transition_to(new_state: int) -> bool:
	if new_state == current_state:
		return false
	if not pode_transicionar(current_state, new_state):
		return false
	previous_state = current_state
	current_state = new_state
	_emitir_estado()
	return true

func forcar_estado(new_state: int) -> void:
	previous_state = current_state
	current_state = new_state
	_emitir_estado()

func pode_transicionar(from_state: int, to_state: int) -> bool:
	return transicoes_validas.get(from_state, []).has(to_state)

func get_current_state_name() -> String:
	return nome_estado(current_state)

func get_previous_state_name() -> String:
	return nome_estado(previous_state)

func nome_estado(state_id: int) -> String:
	match state_id:
		CombatState.PLAYER_STANDING_NEUTRAL: return "PLAYER_STANDING_NEUTRAL"
		CombatState.PLAYER_TOP_CLINCH: return "PLAYER_TOP_CLINCH"
		CombatState.PLAYER_BOTTOM_CLINCH: return "PLAYER_BOTTOM_CLINCH"
		CombatState.PLAYER_TOP_GUARD: return "PLAYER_TOP_GUARD"
		CombatState.PLAYER_BOTTOM_GUARD: return "PLAYER_BOTTOM_GUARD"
		CombatState.PLAYER_TOP_SIDE: return "PLAYER_TOP_SIDE"
		CombatState.PLAYER_BOTTOM_SIDE: return "PLAYER_BOTTOM_SIDE"
		CombatState.PLAYER_TOP_MOUNT: return "PLAYER_TOP_MOUNT"
		CombatState.PLAYER_BOTTOM_MOUNT: return "PLAYER_BOTTOM_MOUNT"
		CombatState.PLAYER_BACK_ATTACK: return "PLAYER_BACK_ATTACK"
		CombatState.PLAYER_BACK_DEFENSE: return "PLAYER_BACK_DEFENSE"
		CombatState.PLAYER_SUBMISSION_ATTACK: return "PLAYER_SUBMISSION_ATTACK"
		CombatState.PLAYER_SUBMISSION_DEFENSE: return "PLAYER_SUBMISSION_DEFENSE"
		CombatState.RESET: return "RESET"
	return "PLAYER_STANDING_NEUTRAL"

func estado_por_nome(nome: String) -> int:
	var n := nome.to_upper()
	match n:
		"STANDING_NEUTRAL", "PLAYER_STANDING_NEUTRAL": return CombatState.PLAYER_STANDING_NEUTRAL
		"TOP_CLINCH", "PLAYER_TOP_CLINCH": return CombatState.PLAYER_TOP_CLINCH
		"BOTTOM_CLINCH", "PLAYER_BOTTOM_CLINCH": return CombatState.PLAYER_BOTTOM_CLINCH
		"TOP_GUARD", "PLAYER_TOP_GUARD": return CombatState.PLAYER_TOP_GUARD
		"BOTTOM_GUARD", "PLAYER_BOTTOM_GUARD": return CombatState.PLAYER_BOTTOM_GUARD
		"TOP_SIDE", "PLAYER_TOP_SIDE": return CombatState.PLAYER_TOP_SIDE
		"BOTTOM_SIDE", "PLAYER_BOTTOM_SIDE": return CombatState.PLAYER_BOTTOM_SIDE
		"TOP_MOUNT", "PLAYER_TOP_MOUNT": return CombatState.PLAYER_TOP_MOUNT
		"BOTTOM_MOUNT", "PLAYER_BOTTOM_MOUNT": return CombatState.PLAYER_BOTTOM_MOUNT
		"BACK_ATTACK", "PLAYER_BACK_ATTACK": return CombatState.PLAYER_BACK_ATTACK
		"BACK_DEFENSE", "PLAYER_BACK_DEFENSE": return CombatState.PLAYER_BACK_DEFENSE
		"SUBMISSION_ATTACK", "TECHNICAL_ATTACK", "PLAYER_SUBMISSION_ATTACK": return CombatState.PLAYER_SUBMISSION_ATTACK
		"SUBMISSION_DEFENSE", "TECHNICAL_DEFENSE", "PLAYER_SUBMISSION_DEFENSE": return CombatState.PLAYER_SUBMISSION_DEFENSE
		"RESET": return CombatState.RESET
	return CombatState.PLAYER_STANDING_NEUTRAL

func reset() -> void:
	forcar_estado(CombatState.RESET)

func reiniciar_em_pe() -> void:
	previous_state = current_state
	current_state = CombatState.PLAYER_STANDING_NEUTRAL
	_emitir_estado()

func _emitir_estado() -> void:
	SignalBus.state_changed.emit(StringName(get_current_state_name()), StringName(get_previous_state_name()))
	SignalBus.combat_state_changed.emit(get_previous_state_name(), get_current_state_name())
	if SignalBus.has_signal("estado_combate_mudou"):
		SignalBus.estado_combate_mudou.emit(StringName(get_current_state_name()), StringName(get_previous_state_name()))
