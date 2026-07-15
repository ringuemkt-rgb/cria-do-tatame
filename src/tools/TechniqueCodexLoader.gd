extends Node
class_name TechniqueCodexLoader

var registry: JsonDataRegistry
var techniques_by_id: Dictionary = {}

func setup(p_registry: JsonDataRegistry) -> void:
	registry = p_registry
	load_catalog()

func load_catalog() -> void:
	if registry == null:
		techniques_by_id.clear()
		return
	var data: Dictionary = registry.get_technique_catalog()
	techniques_by_id.clear()
	for item_value in data.get("techniques", []):
		if typeof(item_value) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = item_value
		techniques_by_id[str(item.get("id", ""))] = item

func get_technique(technique_id: String) -> Dictionary:
	return techniques_by_id.get(technique_id, {})

func list_by_family(family_id: String) -> Array:
	var out: Array = []
	for tech_value in techniques_by_id.values():
		if typeof(tech_value) != TYPE_DICTIONARY:
			continue
		var tech: Dictionary = tech_value
		if str(tech.get("family", "")) == family_id:
			out.append(tech)
	return out

func validate_catalog() -> Array[String]:
	var errors: Array[String] = []
	for id_value in techniques_by_id.keys():
		var id: String = str(id_value)
		var tech: Dictionary = techniques_by_id[id]
		for required_value in ["id", "name_ptbr", "family", "state_from", "state_to_success"]:
			var required: String = str(required_value)
			if not tech.has(required):
				errors.append("Technique " + id + " missing " + required)
	return errors
