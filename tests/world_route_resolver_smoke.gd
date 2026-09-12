extends SceneTree

const ResolverScript = preload("res://src/world/WorldRouteResolver.gd")

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	var fixture_map := {
		"aliases": {"ponte_do_saci": "ponte_do_saici"},
		"rotas": [
			{"de": "itubera_hub", "para": "valenca_hub", "tipo": "terrestre", "minigame": "rota_101", "distancia_km": 56.0, "base_time_minutes": 70},
			{"de": "valenca_hub", "para": "cairu_hub", "tipo": "maritima", "mare": true, "base_time_minutes": 50},
			{"de": "valenca_hub", "para": "ponte_do_saici", "tipo": "ponte", "base_time_minutes": 15},
			{"de": "itubera_hub", "para": "atalho_secreto", "tipo": "secreta", "gate": {"ato": 3}},
			{"de": "cairu_hub", "para": "marau_hub", "tipo": "maritima", "minigame": "rota_101"}
		]
	}
	var fixture_contract := {
		"vehicles": {
			"kombi_terreiro": {"route_classes": ["terrestrial_primary"], "playable_mode": "rota_101", "role": "team_default"},
			"onibus_regional": {"route_classes": ["terrestrial_primary"], "playable_mode": "resolved_travel", "role": "safe_fallback"},
			"barco_ferry": {"route_classes": ["maritime"], "playable_mode": "resolved_travel", "role": "maritime_required"},
			"moto_emprestada": {"route_classes": ["secret_access"], "playable_mode": "moto_route", "role": "solo_fast_access"}
		},
		"route_resolver": {
			"reverse_routes_by_default": true,
			"default_tide_for_mare_gate": "alta"
		}
	}
	var map_before := fixture_map.duplicate(true)
	var contract_before := fixture_contract.duplicate(true)
	var resolver = ResolverScript.new()
	var init_result: Dictionary = resolver.initialize(fixture_map, fixture_contract)
	_check(bool(init_result.get("ok", false)), "resolver initializes with fixture")

	var road_result: Dictionary = resolver.resolve_route("itubera_hub", "valenca_hub", {"weather": "chuva", "tide": "alta", "act": 1})
	_check(bool(road_result.get("ok", false)), "golden terrestrial route resolves")
	var road: Dictionary = road_result.get("route", {})
	_check(bool(road.get("traversable", false)), "golden route is traversable")
	_check(str(road.get("type", "")) == "terrestre", "golden route type stays terrestrial")
	_check(str(road.get("minigame", "")) == "rota_101", "golden route launches rota_101")
	_check(float(road.get("distance_km", 0.0)) == 56.0, "distance is preserved")
	_check(int(road.get("base_time_minutes", 0)) == 70, "base time is preserved")
	_check(_has_method(road.get("method_options", []), "kombi_terreiro"), "kombi allowed on terrestrial route")
	_check(_has_method(road.get("method_options", []), "onibus_regional"), "bus fallback allowed")
	_check(str(road.get("world_context_snapshot", {}).get("weather", "")) == "chuva", "weather snapshot preserved")

	var reverse_result: Dictionary = resolver.resolve_route("valenca_hub", "itubera_hub", {"tide": "alta"})
	_check(bool(reverse_result.get("ok", false)), "reverse route resolves by default")
	_check(bool(reverse_result.get("route", {}).get("reversed", false)), "reverse route marked reversed")

	var low_tide_result: Dictionary = resolver.resolve_route("valenca_hub", "cairu_hub", {"tide": "baixa"})
	_check(bool(low_tide_result.get("ok", false)), "maritime route resolves even when gated")
	_check(not bool(low_tide_result.get("route", {}).get("traversable", true)), "low tide blocks tide-sensitive route")
	_check(_has_reason(low_tide_result.get("route", {}), "tide_gate_unsatisfied"), "low tide exposes gate reason")

	var high_tide_result: Dictionary = resolver.resolve_route("valenca_hub", "cairu_hub", {"tide": "alta"})
	_check(bool(high_tide_result.get("route", {}).get("traversable", false)), "high tide opens maritime route")
	_check(_has_method(high_tide_result.get("route", {}).get("method_options", []), "barco_ferry"), "ferry allowed on maritime route")
	_check(not _has_method(high_tide_result.get("route", {}).get("method_options", []), "kombi_terreiro"), "kombi rejected on maritime route")

	var bridge_result: Dictionary = resolver.resolve_route("valenca_hub", "ponte_do_saci", {"tide": "alta"})
	_check(str(bridge_result.get("route", {}).get("type", "")) == "terrestre", "ponte normalizes to terrestrial")
	_check(str(bridge_result.get("route", {}).get("subtype", "")) == "bridge", "ponte keeps bridge subtype")

	var secret_locked: Dictionary = resolver.resolve_route("itubera_hub", "atalho_secreto", {"act": 2})
	_check(not bool(secret_locked.get("route", {}).get("traversable", true)), "secret route fails closed before act gate")
	var secret_open: Dictionary = resolver.resolve_route("itubera_hub", "atalho_secreto", {"act": 3})
	_check(bool(secret_open.get("route", {}).get("traversable", false)), "secret route opens when act gate satisfied")
	_check(_has_method(secret_open.get("route", {}).get("method_options", []), "moto_emprestada"), "moto can serve secret access")

	var bad_mode: Dictionary = resolver.resolve_route("cairu_hub", "marau_hub", {"tide": "alta"})
	_check(not bool(bad_mode.get("route", {}).get("traversable", true)), "maritime rota_101 conflict fails closed")
	_check(_has_reason(bad_mode.get("route", {}), "rota_101_requires_terrestrial_route"), "maritime conflict reason exposed")

	_check(fixture_map == map_before, "resolver does not mutate map input")
	_check(fixture_contract == contract_before, "resolver does not mutate contract input")

	var missing: Dictionary = resolver.resolve_route("itubera_hub", "nao_existe", {})
	_check(not bool(missing.get("ok", true)), "missing route fails closed")
	_check(str(missing.get("error", "")) == "route_not_found", "missing route has deterministic error")

	print("WORLD_ROUTE_RESOLVER_SMOKE checks=%d failures=%d" % [checks, failures.size()])
	for failure in failures:
		push_error(failure)
	quit(0 if failures.is_empty() else 1)

func _has_method(options: Array, vehicle_id: String) -> bool:
	for option_value in options:
		if typeof(option_value) == TYPE_DICTIONARY and str(option_value.get("vehicle_id", "")) == vehicle_id:
			return true
	return false

func _has_reason(route: Dictionary, reason: String) -> bool:
	var gate_status: Dictionary = route.get("gate_status", {})
	return gate_status.get("reasons", []).has(reason)

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
