extends Node

const WEEK_ACTIVITIES := {
	"segunda": "treino_tecnico",
	"terca": "sparring_fisico",
	"quarta": "treino_cria_live",
	"quinta": "recuperacao_sponsor",
	"sexta": "evento_missao",
	"sabado": "luta_principal",
	"domingo": "descanso_cerimonia"
}

func current_day():
	return WorldState.days[WorldState.day_index]

func get_today_activity():
	return WEEK_ACTIVITIES.get(current_day(), "descanso_cerimonia")

func advance_day():
	WorldState.advance_day()

func execute_activity(activity_id):
	match str(activity_id):
		"treino_tecnico":
			WorldState.energy = max(WorldState.energy - 20.0, 0.0)
			WorldState.modify_reputation("legado", 1.0)
			WorldState.advance_day()
			return {"message": "Treino tecnico completado. Base fortalecida."}
		"sparring_fisico":
			WorldState.energy = max(WorldState.energy - 35.0, 0.0)
			if randf() < 0.15:
				WorldState.strain_level += 1
				WorldState.advance_day()
				return {"message": "Sparring pesado. Recuperacao marcada."}
			WorldState.advance_day()
			return {"message": "Sparring completado. Cardio em dia."}
		"treino_cria_live":
			WorldState.energy = max(WorldState.energy - 25.0, 0.0)
			WorldState.modify_reputation("hype", 4.0)
			CriaLiveManager.generate_post("treino", {})
			WorldState.advance_day()
			return {"message": "Treino e Cria Live. Hype subiu."}
		"recuperacao_sponsor":
			WorldState.energy = min(100.0, WorldState.energy + 30.0)
			WorldState.money += 150
			WorldState.advance_day()
			return {"message": "Recuperacao e reuniao com apoio."}
		"descanso_cerimonia":
			WorldState.energy = min(100.0, WorldState.energy + 40.0)
			WorldState.modify_reputation("legado", 2.0)
			WorldState.advance_day()
			return {"message": "Descanso e reflexao. Legado cresce."}
		_:
			WorldState.advance_day()
			return {"message": "Dia concluido."}
