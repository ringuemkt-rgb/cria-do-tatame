extends RefCounted
class_name WorldRouteResolver

const DEFAULT_MAP_PATH := "res://data/world/world_map_v4.json"
const DEFAULT_TRAVEL_CONTRACT_PATH := "res://data/world/vehicle_world_travel_v1.json"

var map_data: Dictionary = {}
var travel_contract: Dictionary = {}
var initialization_errors: Array[String] = []

func initialize(map_override: Dictionary = {}, contract_override: Dictionary = {}) -> Dictionary:
	initialization_errors.clear()
	map_data = map_override.duplicate(true) if not map_override.is_empty() else _load_json(DEFAULT_MAP_PATH)
	travel_contract = contract_override.duplicate(true) if not contract_override.is_empty() else _load_json(DEFAULT_TRAVEL_CONTRACT_PATH)
	if map_data.is_empty():
		initialization_errors.append("world_map_missing_or_invalid")
	if travel_contract.is_empty():
		initialization_errors.append("vehicle_travel_contract_missing_or_invalid")
	return {
		"ok": initialization_errors.is_empty(),
		"errors": initialization_errors.duplicate(),
		"route_count": _routes().size()
	}

func resolve_route(origin: String, destination: String, world_context: Dictionary = {}) -> Dictionary:
	if map_data.is_empty() or travel_contract.is_empty():
		return _error("resolver_not_initialized")
	if origin.strip_edges() == "" or destination.strip_edges() == "":
		return _error("origin_or_destination_empty")

	var origin_id := _canonical_endpoint(origin)
	var destination_id := _canonical_endpoint(destination)
	if origin_id == destination_id:
		return _error("origin_equals_destination")

	var selected: Dictionary = {}
	var reversed := false
	for route_value in _routes():
		if typeof(route_value) != TYPE_DICTIONARY:
			continue
		var route: Dictionary = route_value
		var from_id := _canonical_endpoint(_route_from(route))
		var to_id := _canonical_endpoint(_route_to(route))
		if from_id == origin_id and to_id == destination_id:
			selected = route.duplicate(true)
			break
		if _reverse_routes_by_default() and not bool(route.get("one_way", false)) and from_id == destination_id and to_id == origin_id:
			selected = route.duplicate(true)
			reversed = true
			break

	if selected.is_empty():
		return _error("route_not_found", {"origin": origin_id, "destination": destination_id})

	var normalized := _normalize_route(selected, origin_id, destination_id, reversed)
	var gate_result := _evaluate_gates(normalized, world_context)
	var node_gate := _evaluate_destination_node_gate(destination_id, world_context)
	var reasons: Array = gate_result.get("reasons", []).duplicate()
	for reason_value in node_gate.get("reasons", []):
		if not reasons.has(reason_value):
			reasons.append(reason_value)
	gate_result["reasons"] = reasons
	gate_result["node_lock"] = node_gate.get("lock", {}).duplicate(true)
	gate_result["traversable"] = reasons.is_empty()

	normalized["traversable"] = bool(gate_result.get("traversable", false))
	normalized["gate_status"] = gate_result
	normalized["world_context_snapshot"] = _context_snapshot(world_context)
	normalized["method_options"] = _method_options(str(normalized.get("route_class", "")))

	var minigame := str(normalized.get("minigame", ""))
	if minigame == "rota_101" and str(normalized.get("type", "")) != "terrestre":
		normalized["traversable"] = false
		var gate_reasons: Array = normalized.get("gate_status", {}).get("reasons", [])
		gate_reasons.append("rota_101_requires_terrestrial_route")
		normalized["gate_status"]["reasons"] = gate_reasons
		normalized["gate_status"]["traversable"] = false

	return {
		"ok": true,
		"route": normalized
	}

func resolve_all_from(origin: String, world_context: Dictionary = {}) -> Array:
	var output: Array = []
	var origin_id := _canonical_endpoint(origin)
	for route_value in _routes():
		if typeof(route_value) != TYPE_DICTIONARY:
			continue
		var route: Dictionary = route_value
		var from_id := _canonical_endpoint(_route_from(route))
		var to_id := _canonical_endpoint(_route_to(route))
		if from_id == origin_id:
			var result := resolve_route(origin_id, to_id, world_context)
			if bool(result.get("ok", false)):
				output.append(result.get("route", {}))
		elif _reverse_routes_by_default() and not bool(route.get("one_way", false)) and to_id == origin_id:
			var reverse_result := resolve_route(origin_id, from_id, world_context)
			if bool(reverse_result.get("ok", false)):
				output.append(reverse_result.get("route", {}))
	return output

func _normalize_route(route: Dictionary, origin_id: String, destination_id: String, reversed: bool) -> Dictionary:
	var raw_type := str(route.get("tipo", route.get("type", "")))
	var normalized_type := raw_type
	var subtype := str(route.get("subtype", ""))
	match raw_type:
		"ponte":
			normalized_type = "terrestre"
			subtype = "bridge"
		"conexao":
			normalized_type = "connection"
		"connection":
			normalized_type = "connection"

	var route_id := str(route.get("id", ""))
	if route_id == "":
		route_id = "%s__%s" % [origin_id, destination_id]

	var distance_km := _as_float(route.get("distance_km", route.get("distancia_km", 0.0)))
	var base_time_minutes := int(route.get("base_time_minutes", 0))
	if base_time_minutes <= 0:
		base_time_minutes = _parse_time_minutes(str(route.get("tempo", route.get("time", ""))))

	return {
		"id": route_id,
		"origin": origin_id,
		"destination": destination_id,
		"source_origin": _route_from(route),
		"source_destination": _route_to(route),
		"reversed": reversed,
		"type": normalized_type,
		"subtype": subtype,
		"route_class": _route_class(normalized_type, subtype),
		"distance_km": distance_km,
		"distance_known": distance_km > 0.0,
		"base_time_minutes": base_time_minutes,
		"time_known": base_time_minutes > 0,
		"base_money_cost": int(route.get("base_money_cost", route.get("cost", 0))),
		"base_fuel_cost": _as_float(route.get("base_fuel_cost", route.get("fuel_cost", 0.0))),
		"minigame": str(route.get("minigame", "")),
		"blocked_by_data": bool(route.get("bloqueada", route.get("blocked", false))),
		"tide_sensitive": bool(route.get("mare", false)) or bool(route.get("bloqueavel_por_mare", false)),
		"gate": route.get("gate", {}).duplicate(true) if typeof(route.get("gate", {})) == TYPE_DICTIONARY else {},
		"raw": route.duplicate(true)
	}

func _evaluate_gates(route: Dictionary, world_context: Dictionary) -> Dictionary:
	var reasons: Array[String] = []
	var route_id := str(route.get("id", ""))
	if bool(route.get("blocked_by_data", false)) and not _route_is_explicitly_unlocked(route_id, world_context):
		reasons.append("route_marked_blocked")

	if bool(route.get("tide_sensitive", false)):
		var required_tide := str(route.get("gate", {}).get("mare", _default_tide_for_gate()))
		var actual_tide := str(world_context.get("tide", world_context.get("mare", "")))
		if actual_tide == "":
			reasons.append("tide_context_missing")
		elif required_tide != "" and actual_tide != required_tide:
			reasons.append("tide_gate_unsatisfied")

	var gate: Dictionary = route.get("gate", {})
	for key_value in gate.keys():
		var key := str(key_value)
		if key == "mare":
			continue
		if not _gate_value_satisfied(key, gate.get(key_value), world_context):
			reasons.append("gate_unsatisfied:%s" % key)

	return {
		"traversable": reasons.is_empty(),
		"reasons": reasons,
		"evaluated_gate": gate.duplicate(true)
	}

func _evaluate_destination_node_gate(destination_id: String, world_context: Dictionary) -> Dictionary:
	var node := _find_node(destination_id)
	if node.is_empty():
		return {"traversable": true, "reasons": [], "lock": {}}
	var lock_value: Variant = node.get("lock", node.get("bloqueio", {}))
	if typeof(lock_value) != TYPE_DICTIONARY or lock_value.is_empty():
		return {"traversable": true, "reasons": [], "lock": {}}
	var lock: Dictionary = lock_value
	var lock_type := str(lock.get("tipo", lock.get("type", "")))
	var requirement: Variant = lock.get("req", lock.get("requirement", null))
	var reasons: Array[String] = []

	match lock_type:
		"mission", "missao":
			if not _named_requirement_satisfied(str(requirement), world_context):
				reasons.append("node_lock_unsatisfied:mission")
		"ato", "act":
			if int(world_context.get("act", world_context.get("ato", 0))) < int(requirement):
				reasons.append("node_lock_unsatisfied:act")
			var extra := str(lock.get("extra", ""))
			if extra != "" and not _named_requirement_satisfied(extra, world_context):
				reasons.append("node_lock_unsatisfied:%s" % extra)
		"rep", "reputation":
			if not _reputation_rank_satisfied(str(requirement), world_context):
				reasons.append("node_lock_unsatisfied:reputation")
		"composto", "compound":
			var requirements: Array = requirement if typeof(requirement) == TYPE_ARRAY else []
			for requirement_value in requirements:
				var token := str(requirement_value)
				if not _named_requirement_satisfied(token, world_context):
					reasons.append("node_lock_unsatisfied:%s" % token)
		"hype":
			if float(world_context.get("hype", -1.0)) < float(requirement):
				reasons.append("node_lock_unsatisfied:hype")
			if lock.has("ato") and int(world_context.get("act", world_context.get("ato", 0))) < int(lock.get("ato", 0)):
				reasons.append("node_lock_unsatisfied:act")
		"heat":
			var heat_value := _heat_for_node(node, world_context)
			if heat_value < 0.0:
				reasons.append("node_lock_context_missing:heat")
			elif heat_value < float(requirement):
				reasons.append("node_lock_unsatisfied:heat")
			if lock.has("ato") and int(world_context.get("act", world_context.get("ato", 0))) < int(lock.get("ato", 0)):
				reasons.append("node_lock_unsatisfied:act")
		"fragmentos", "fragments":
			if _fragment_count(world_context) < int(requirement):
				reasons.append("node_lock_unsatisfied:fragments")
		_:
			if lock_type != "":
				reasons.append("node_lock_unsupported:%s" % lock_type)

	return {"traversable": reasons.is_empty(), "reasons": reasons, "lock": lock.duplicate(true)}

func _find_node(node_id: String) -> Dictionary:
	var nodes: Array = map_data.get("nodes", map_data.get("nos", []))
	for node_value in nodes:
		if typeof(node_value) != TYPE_DICTIONARY:
			continue
		var node: Dictionary = node_value
		if _canonical_endpoint(str(node.get("id", ""))) == node_id:
			return node.duplicate(true)
	return {}

func _named_requirement_satisfied(token: String, world_context: Dictionary) -> bool:
	var requirement := token.strip_edges()
	if requirement == "":
		return true
	var flags: Dictionary = world_context.get("flags", {})
	if flags.has(requirement) and bool(flags.get(requirement, false)):
		return true
	var missions: Array = world_context.get("completed_missions", [])
	if missions.has(requirement):
		return true
	if requirement.begins_with("ato"):
		var act_text := requirement.trim_prefix("ato")
		if act_text.is_valid_int():
			return int(world_context.get("act", world_context.get("ato", 0))) >= int(act_text)
	if requirement == "lua_cheia":
		return bool(world_context.get("lua_cheia", false))
	if requirement == "mare_baixa":
		return str(world_context.get("tide", world_context.get("mare", ""))) == "baixa"
	if requirement == "mare_alta":
		return str(world_context.get("tide", world_context.get("mare", ""))) == "alta"
	if requirement.begins_with("hype_"):
		var hype_text := requirement.trim_prefix("hype_")
		if hype_text.is_valid_float():
			return float(world_context.get("hype", -1.0)) >= float(hype_text)
	return false

func _reputation_rank_satisfied(rank_id: String, world_context: Dictionary) -> bool:
	var ranks: Dictionary = map_data.get("reputation_ranks", {})
	var rank: Dictionary = ranks.get(rank_id, {})
	if rank.is_empty():
		return bool(world_context.get("flags", {}).get(rank_id, false))
	var axis := str(rank.get("axis", ""))
	if axis == "":
		return false
	return float(world_context.get(axis, -1.0)) >= float(rank.get("min", 0.0))

func _heat_for_node(node: Dictionary, world_context: Dictionary) -> float:
	var by_faction: Dictionary = world_context.get("heat_by_faction", {})
	var faction := str(node.get("faccao", node.get("faction", "")))
	if faction != "" and by_faction.has(faction):
		return float(by_faction.get(faction, -1.0))
	if world_context.has("heat"):
		return float(world_context.get("heat", -1.0))
	return -1.0

func _fragment_count(world_context: Dictionary) -> int:
	var collectibles: Dictionary = world_context.get("collectibles", {})
	if collectibles.has("fragmentos"):
		return int(collectibles.get("fragmentos", 0))
	if collectibles.has("fragmentos_total"):
		return int(collectibles.get("fragmentos_total", 0))
	return int(collectibles.get("fragmento_reliquia", 0)) + int(collectibles.get("fragmento_memoria", 0))

func _gate_value_satisfied(key: String, requirement: Variant, world_context: Dictionary) -> bool:
	match key:
		"ato", "act":
			return int(world_context.get("act", world_context.get("ato", 0))) >= int(requirement)
		"ng_plus":
			return bool(world_context.get("ng_plus", false)) == bool(requirement)
		"fragmento_reliquia":
			var collectibles: Dictionary = world_context.get("collectibles", {})
			return int(collectibles.get("fragmento_reliquia", 0)) >= int(requirement)
		"fragmento_memoria":
			var memory_collectibles: Dictionary = world_context.get("collectibles", {})
			return int(memory_collectibles.get("fragmento_memoria", 0)) >= int(requirement)
		"sombra":
			return int(world_context.get("sombra", 0)) >= int(requirement)
		"lua_cheia":
			return bool(world_context.get("lua_cheia", false)) == bool(requirement)

	if world_context.has(key):
		var actual: Variant = world_context.get(key)
		if typeof(requirement) in [TYPE_INT, TYPE_FLOAT] and typeof(actual) in [TYPE_INT, TYPE_FLOAT]:
			return float(actual) >= float(requirement)
		return actual == requirement

	var flags: Dictionary = world_context.get("flags", {})
	if flags.has(key):
		return flags.get(key) == requirement
	return false

func _route_is_explicitly_unlocked(route_id: String, world_context: Dictionary) -> bool:
	var unlocks: Array = world_context.get("route_unlocks", [])
	return unlocks.has(route_id)

func _method_options(route_class: String) -> Array:
	var output: Array = []
	var vehicles: Dictionary = travel_contract.get("vehicles", {})
	for vehicle_id_value in vehicles.keys():
		var vehicle_id := str(vehicle_id_value)
		var vehicle: Dictionary = vehicles.get(vehicle_id_value, {})
		var classes: Array = vehicle.get("route_classes", [])
		if classes.has(route_class):
			output.append({
				"vehicle_id": vehicle_id,
				"mode": str(vehicle.get("playable_mode", "resolved_travel")),
				"role": str(vehicle.get("role", ""))
			})
	return output

func _route_class(route_type: String, subtype: String) -> String:
	match route_type:
		"terrestre":
			return "terrestrial_secondary" if subtype in ["trail", "vicinal"] else "terrestrial_primary"
		"maritima":
			return "maritime"
		"trilha":
			return "trail"
		"secreta":
			return "secret_access"
		"connection":
			return "local"
	return route_type

func _canonical_endpoint(endpoint: String) -> String:
	var current := endpoint.strip_edges()
	var aliases: Dictionary = map_data.get("aliases", {})
	if aliases.has(current):
		current = str(aliases.get(current))
	var resolver_config: Dictionary = travel_contract.get("route_resolver", {})
	var endpoint_aliases: Dictionary = resolver_config.get("endpoint_aliases", {})
	if endpoint_aliases.has(current):
		current = str(endpoint_aliases.get(current))
	return current

func _routes() -> Array:
	if map_data.has("routes"):
		return map_data.get("routes", [])
	return map_data.get("rotas", [])

func _route_from(route: Dictionary) -> String:
	return str(route.get("from", route.get("de", "")))

func _route_to(route: Dictionary) -> String:
	return str(route.get("to", route.get("para", "")))

func _reverse_routes_by_default() -> bool:
	return bool(travel_contract.get("route_resolver", {}).get("reverse_routes_by_default", true))

func _default_tide_for_gate() -> String:
	return str(travel_contract.get("route_resolver", {}).get("default_tide_for_mare_gate", "alta"))

func _context_snapshot(world_context: Dictionary) -> Dictionary:
	var allowed_keys := ["weather", "tide", "mare", "act", "ato", "ng_plus", "lua_cheia", "sombra", "hype", "honra", "heat", "heat_by_faction", "collectibles", "flags", "completed_missions", "route_unlocks"]
	var output := {}
	for key in allowed_keys:
		if world_context.has(key):
			var value: Variant = world_context.get(key)
			output[key] = value.duplicate(true) if typeof(value) in [TYPE_DICTIONARY, TYPE_ARRAY] else value
	return output

func _parse_time_minutes(raw: String) -> int:
	var value := raw.strip_edges().to_lower()
	if value == "":
		return 0
	if value.ends_with("min"):
		return int(value.trim_suffix("min"))
	var h_index := value.find("h")
	if h_index >= 0:
		var hours := int(value.substr(0, h_index))
		var rest := value.substr(h_index + 1).strip_edges()
		var minutes := int(rest) if rest != "" else 0
		return hours * 60 + minutes
	return int(value) if value.is_valid_int() else 0

func _as_float(value: Variant) -> float:
	if typeof(value) in [TYPE_INT, TYPE_FLOAT]:
		return float(value)
	var raw := str(value)
	return float(raw) if raw.is_valid_float() else 0.0

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func _error(code: String, details: Dictionary = {}) -> Dictionary:
	return {"ok": false, "error": code, "details": details.duplicate(true)}
