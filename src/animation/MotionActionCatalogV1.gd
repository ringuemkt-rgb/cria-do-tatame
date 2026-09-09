class_name MotionActionCatalogV1
extends RefCounted

var actions: Dictionary = {}
var validation_errors: Array[String] = []

func build(taxonomy: Dictionary, bjj_graph: Dictionary = {}) -> bool:
	actions.clear()
	validation_errors.clear()
	var family_map: Dictionary = taxonomy.get("family_category_map", {})
	var families: Dictionary = taxonomy.get("families", {})
	var family_names: Array = families.keys()
	family_names.sort()
	for family_value in family_names:
		var family := str(family_value)
		var category := str(family_map.get(family, ""))
		if category == "":
			validation_errors.append("family_category_missing:%s" % family)
			continue
		var raw_actions = families.get(family, [])
		if typeof(raw_actions) != TYPE_ARRAY:
			validation_errors.append("family_not_array:%s" % family)
			continue
		# Generic BJJ taxonomy entries are visual vocabulary only. Executable BJJ
		# actions are derived exclusively from graph technique ids below.
		if category == "BJJ":
			continue
		for raw_action in raw_actions:
			var action_id := str(raw_action)
			if action_id == "":
				validation_errors.append("empty_action:%s" % family)
				continue
			_register(action_id, {
				"id": action_id,
				"category": category,
				"authority": "BASE_SEMANTIC",
				"from_state": "",
				"to_state": "",
				"requires_target": false
			})

	for raw_technique in bjj_graph.get("techniques", bjj_graph.get("tecnicas", [])):
		if typeof(raw_technique) != TYPE_DICTIONARY:
			validation_errors.append("bjj_technique_not_dictionary")
			continue
		var technique: Dictionary = raw_technique
		var technique_id := str(technique.get("id", ""))
		if technique_id == "":
			validation_errors.append("bjj_technique_missing_id")
			continue
		_register(technique_id, {
			"id": technique_id,
			"category": "BJJ",
			"authority": "BJJ_GRAPH",
			"from_state": str(technique.get("from", technique.get("de", ""))),
			"to_state": str(technique.get("to", technique.get("para", ""))),
			"requires_target": true,
			"technique_type": str(technique.get("type", technique.get("tipo", "")))
		})
	return validation_errors.is_empty()

func has_action(action_id: String) -> bool:
	return actions.has(action_id)

func get_action(action_id: String) -> Dictionary:
	if not actions.has(action_id):
		return {}
	return actions[action_id].duplicate(true)

func as_dictionary() -> Dictionary:
	return actions.duplicate(true)

func ids_for_category(category: String) -> Array:
	var out: Array = []
	var ids: Array = actions.keys()
	ids.sort()
	for raw_id in ids:
		var action_id := str(raw_id)
		if str(actions[action_id].get("category", "")) == category:
			out.append(action_id)
	return out

func _register(action_id: String, row: Dictionary) -> void:
	if actions.has(action_id):
		validation_errors.append("duplicate_action_id:%s" % action_id)
		return
	actions[action_id] = row.duplicate(true)
