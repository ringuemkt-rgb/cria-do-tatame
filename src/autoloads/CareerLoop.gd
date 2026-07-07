extends Node

var activities := {
	"segunda": ["treino_tecnico", "treino_fisico"],
	"terça": ["drilling", "dialogo"],
	"quarta": ["sparring", "recuperacao"],
	"quinta": ["missao", "cria_live"],
	"sexta": ["preparacao_luta"],
	"sábado": ["luta"],
	"domingo": ["descanso"]
}

func current_day():
	return WorldState.days[WorldState.day_index]

func advance_day():
	WorldState.day_index += 1
	if WorldState.day_index >= WorldState.days.size():
		WorldState.day_index = 0
		WorldState.week += 1
	SignalBus.week_advanced.emit(WorldState.week, current_day())

func apply_training(training_id: String):
	match training_id:
		"treino_tecnico":
			WorldState.energy = max(WorldState.energy - 10, 0)
		"treino_fisico":
			WorldState.energy = max(WorldState.energy - 14, 0)
		"recuperacao":
			WorldState.energy = min(WorldState.energy + 20, 100)
	advance_day()
