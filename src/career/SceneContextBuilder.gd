extends Node
class_name SceneContextBuilder

func build_context(input: Dictionary) -> Dictionary:
	return {
		"scene_type": input.get("scene_type", "treino"),
		"athlete": input.get("athlete", "Ruan Macacao Silva"),
		"location": input.get("location", "Terreiro da Luta"),
		"mentor": input.get("mentor", "Mestre Dende"),
		"objective": input.get("objective", "evoluir com disciplina"),
		"combat_state": input.get("combat_state", "distancia_media"),
		"techniques": input.get("techniques", []),
		"tone": "PT-BR, tatame brasileiro, direto"
	}

func to_prompt_pack(context: Dictionary) -> String:
	var lines: Array[String] = []
	for key in context.keys():
		lines.append(str(key) + ": " + str(context[key]))
	return "\n".join(lines)
