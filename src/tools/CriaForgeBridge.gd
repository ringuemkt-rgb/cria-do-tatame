extends Node
class_name CriaForgeBridge

func get_manifest() -> Dictionary:
	return {"name": "Cria Game Forge", "version": "0.6.0", "engine": "Godot 4.2+"}

func build_sprite_request(technique: Dictionary) -> Dictionary:
	return {
		"character_id": "ruan_macacao",
		"technique_id": technique.get("id", "unknown"),
		"name_ptbr": technique.get("name_ptbr", "Tecnica"),
		"style": "HD Pixel Art 2.5D Regional Premium",
		"actions": ["leitura", "entrada", "contato", "controle", "transicao"]
	}

func validate_technique(technique: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for field in ["id", "name_ptbr", "family", "state_from", "state_to_success"]:
		if not technique.has(field):
			errors.append("missing " + field)
	return errors
