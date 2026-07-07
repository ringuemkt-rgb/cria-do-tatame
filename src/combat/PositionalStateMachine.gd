extends Node
class_name PositionalStateMachine

var current_state: String = "distancia_media"
var history: Array[String] = []

var transitions := {
	"distancia_media": ["disputa_pegada", "clinch_neutro", "entrada_queda"],
	"disputa_pegada": ["clinch_neutro", "clinch_dominante", "entrada_queda", "guarda_fechada"],
	"clinch_neutro": ["clinch_dominante", "entrada_queda", "reset"],
	"clinch_dominante": ["entrada_queda", "disputa_queda", "reset"],
	"entrada_queda": ["disputa_queda", "clinch_neutro"],
	"disputa_queda": ["guarda_fechada", "guarda_aberta", "meia_guarda", "reset"],
	"guarda_fechada": ["guarda_aberta", "meia_guarda", "cem_quilos", "setup_tecnico"],
	"guarda_aberta": ["meia_guarda", "cem_quilos", "reset", "setup_tecnico"],
	"meia_guarda": ["cem_quilos", "guarda_aberta", "costas"],
	"cem_quilos": ["norte_sul", "joelho_na_barriga", "montada", "costas"],
	"norte_sul": ["cem_quilos", "setup_tecnico"],
	"joelho_na_barriga": ["montada", "cem_quilos"],
	"montada": ["costas", "setup_tecnico", "guarda_fechada"],
	"costas": ["setup_tecnico", "tartaruga", "resultado_tecnico"],
	"tartaruga": ["costas", "cem_quilos", "reset"],
	"setup_tecnico": ["controle_tecnico", "reset"],
	"controle_tecnico": ["resultado_tecnico", "reset"],
	"resultado_tecnico": ["reset"],
	"reset": ["distancia_media"]
}

func can_transition(to_state: String) -> bool:
	return to_state in transitions.get(current_state, ["reset"])

func transition(to_state: String) -> bool:
	if not can_transition(to_state):
		return false
	history.append(current_state)
	current_state = to_state
	return true

func force_state(to_state: String) -> void:
	history.append(current_state)
	current_state = to_state
