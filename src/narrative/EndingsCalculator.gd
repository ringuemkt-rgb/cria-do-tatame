class_name EndingsCalculator
extends RefCounted

static func calculate(reputation: Dictionary, tinker_state: String, endings_data: Dictionary) -> String:
	var finals_value = endings_data.get("finals", {})
	if typeof(finals_value) != TYPE_DICTIONARY:
		return ""
	var finals: Dictionary = finals_value
	var order_value = endings_data.get("evaluation_order", [])
	if typeof(order_value) != TYPE_ARRAY:
		return ""
	for final_key_value in order_value:
		var final_key := str(final_key_value)
		var definition_value = finals.get(final_key, {})
		if typeof(definition_value) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = definition_value
		var conditions_value = definition.get("condicoes", {})
		if typeof(conditions_value) != TYPE_DICTIONARY:
			continue
		if _matches(conditions_value, reputation, tinker_state):
			return str(definition.get("short_id", ""))
	return _resolve_fallback(endings_data, finals)

static func _matches(conditions: Dictionary, reputation: Dictionary, tinker_state: String) -> bool:
	for condition_key_value in conditions.keys():
		var condition_key := str(condition_key_value)
		var expected = conditions[condition_key_value]
		if condition_key == "tinker_estado":
			if typeof(expected) == TYPE_ARRAY:
				if not expected.has(tinker_state):
					return false
			elif tinker_state != str(expected):
				return false
		elif condition_key.ends_with("_min"):
			var minimum_axis := condition_key.trim_suffix("_min")
			if float(reputation.get(minimum_axis, 0.0)) < float(expected):
				return false
		elif condition_key.ends_with("_max"):
			var maximum_axis := condition_key.trim_suffix("_max")
			if float(reputation.get(maximum_axis, 0.0)) > float(expected):
				return false
		else:
			return false
	return true

static func _resolve_fallback(endings_data: Dictionary, finals: Dictionary) -> String:
	var fallback_key := str(endings_data.get("fallback", ""))
	var fallback_value = finals.get(fallback_key, {})
	if typeof(fallback_value) != TYPE_DICTIONARY:
		return ""
	return str(fallback_value.get("short_id", ""))
