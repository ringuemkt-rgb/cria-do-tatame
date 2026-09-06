class_name WorldMapRules
extends RefCounted

static func evaluate_node(node: Dictionary, context: Dictionary) -> Dictionary:
	var lock: Dictionary = node.get("lock", {})
	if lock.is_empty():
		return {"unlocked": true, "reason": ""}
	var kind := str(lock.get("tipo", ""))
	match kind:
		"ato":
			var ok := int(context.get("act", 1)) >= int(lock.get("req", 1))
			if ok and lock.has("extra"):
				ok = _token_ok(str(lock.get("extra", "")), context)
			return {"unlocked": ok, "reason": _reason(lock)}
		"missao":
			var req := str(lock.get("req", ""))
			var ok := _contains(context.get("completed_missions", []), req) or _token_ok(req, context)
			return {"unlocked": ok, "reason": _reason(lock)}
		"hype":
			var ok := float(context.get("hype", 0.0)) >= float(lock.get("req", 0))
			if lock.has("ato"):
				ok = ok and int(context.get("act", 1)) >= int(lock.get("ato", 1))
			return {"unlocked": ok, "reason": _reason(lock)}
		"fragmentos":
			return {"unlocked": int(context.get("fragments", 0)) >= int(lock.get("req", 0)), "reason": _reason(lock)}
		"heat":
			var ok := int(context.get("heat", 0)) >= int(lock.get("req", 0))
			if lock.has("ato"):
				ok = ok and int(context.get("act", 1)) >= int(lock.get("ato", 1))
			return {"unlocked": ok, "reason": _reason(lock)}
		"rep":
			var req := str(lock.get("req", ""))
			return {"unlocked": str(context.get("reputation_tier", "")) == req or _token_ok(req, context), "reason": _reason(lock)}
		"composto":
			for token_value in lock.get("req", []):
				if not _token_ok(str(token_value), context):
					return {"unlocked": false, "reason": _reason(lock)}
			return {"unlocked": true, "reason": ""}
		_:
			return {"unlocked": false, "reason": "Requisito ainda não suportado: %s" % kind}

static func route_state(route: Dictionary, _context: Dictionary) -> Dictionary:
	if bool(route.get("bloqueada", false)):
		return {"available": false, "reason": "Rota bloqueada por progressão."}
	if bool(route.get("bloqueavel_por_mare", false)):
		return {
			"available": true,
			"conditional": true,
			"dependency": "TideSystem",
			"reason": "Disponibilidade final depende da maré (EPIC45)."
		}
	return {"available": true, "conditional": false, "reason": ""}

static func _token_ok(token: String, context: Dictionary) -> bool:
	if token == "":
		return true
	if token.begins_with("ato") and token.length() > 3:
		return int(context.get("act", 1)) >= int(token.substr(3))
	if token.begins_with("hype_"):
		return float(context.get("hype", 0.0)) >= float(token.trim_prefix("hype_"))
	if token.begins_with("fragmentos_"):
		return int(context.get("fragments", 0)) >= int(token.trim_prefix("fragmentos_"))
	if token == "heat_baixo":
		return int(context.get("heat", 0)) < 40
	if _contains(context.get("completed_missions", []), token):
		return true
	var flags: Dictionary = context.get("flags", {})
	return bool(flags.get(token, false))

static func _contains(values, needle: String) -> bool:
	if values is Array:
		return values.has(needle)
	return false

static func _reason(lock: Dictionary) -> String:
	var kind := str(lock.get("tipo", ""))
	if kind == "composto":
		return "Requisitos: " + _join_values(lock.get("req", []))
	return "Requisito: %s %s" % [kind, str(lock.get("req", ""))]

static func _join_values(values) -> String:
	var parts := PackedStringArray()
	if values is Array:
		for value in values:
			parts.append(str(value))
	return ", ".join(parts)
