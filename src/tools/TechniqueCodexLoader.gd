extends Node
class_name TechniqueCodexLoader

var registry: DataRegistry
var techniques_by_id: Dictionary = {}

func setup(p_registry: DataRegistry) -> void:
	registry = p_registry
	load_catalog()

func load_catalog() -> void:
	var data := registry.get_technique_catalog()
	techniques_by_id.clear()
	for item in data.get("techniques", []):
		techniques_by_id[str(item.get("id", ""))] = item

func get_technique(technique_id: String) -> Dictionary:
	return techniques_by_id.get(technique_id, {})

func list_by_family(family_id: String) -> Array:
	var out: Array = []
	for tech in techniques_by_id.values():
		if str(tech.get("family", "")) == family_id:
			out.append(tech)
	return out

func validate_catalog() -> Array[String]:
	var errors: Array[String] = []
	for id in techniques_by_id.keys():
		var tech: Dictionary = techniques_by_id[id]
		for required in ["id", "name_ptbr", "family", "state_from", "state_to_success"]:
			if not tech.has(required):
				errors.append("Technique " + str(id) + " missing " + required)
	return errors
