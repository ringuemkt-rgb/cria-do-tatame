extends Node

signal tick_completed(snapshot: Dictionary)
signal ai_plan_ready(plan: Dictionary)
signal ai_plan_failed(reason: String)

const CONFIG_PATH := "res://data/world/world_director_config_v01.json"
const CLIMATE_PATH := "res://data/world/climate_regions_v01.json"
const NPC_ROUTINES_PATH := "res://data/world/npc_routines_v01.json"
const EVENTS_PATH := "res://data/world/dynamic_events_v01.json"

var config: Dictionary = {}
var climate_data: Dictionary = {}
var npc_routines: Dictionary = {}
var event_data: Dictionary = {}

var state: Dictionary = {}
var _http: HTTPRequest
var _ai_backend_url := ""
var _ai_request_active := false
var _time_blocks: Array = ["manha", "tarde", "noite", "madrugada"]

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.name = "WorldDirectorHTTPRequest"
	add_child(_http)
	_http.request_completed.connect(_on_ai_plan_response)
	_load_definitions()
	reset_world()
	if SignalBus.has_signal("day_advanced"):
		SignalBus.day_advanced.connect(_on_day_advanced)
	if SignalBus.has_signal("combat_finished"):
		SignalBus.combat_finished.connect(_on_combat_finished)

func _load_definitions() -> void:
	config = _load_json(CONFIG_PATH)
	climate_data = _load_json(CLIMATE_PATH)
	npc_routines = _load_json(NPC_ROUTINES_PATH)
	event_data = _load_json(EVENTS_PATH)
	_time_blocks = config.get("time_blocks", _time_blocks)

func reset_world() -> void:
	var seed_value := int(config.get("world_seed", 26072026))
	state = {
		"version": 1,
		"seed": seed_value,
		"tick": 0,
		"time_block_index": 0,
		"time_block": str(_time_blocks[0] if not _time_blocks.is_empty() else "manha"),
		"weather_by_region": {},
		"npc_states": {},
		"active_events": [],
		"event_cooldowns": {},
		"rival_directives": {},
		"economy_modifiers": {},
		"director_memory": [],
		"last_ai_plan_tick": -999
	}
	_initialize_weather()
	_update_npc_routines()
	_update_rival_directives(_rng_for("reset_rivals"))
	_update_economy()

func configure_ai_proxy(base_url: String) -> void:
	_ai_backend_url = base_url.strip_edges().trim_suffix("/")

func disable_ai_proxy() -> void:
	_ai_backend_url = ""

func is_ai_proxy_enabled() -> bool:
	return _ai_backend_url != ""

func advance_time_block() -> Dictionary:
	if _time_blocks.is_empty():
		return get_snapshot()
	state["time_block_index"] = (int(state.get("time_block_index", 0)) + 1) % _time_blocks.size()
	state["time_block"] = str(_time_blocks[int(state["time_block_index"])])
	_run_world_tick("time_block")
	return get_snapshot()

func _on_day_advanced(_day_name, _week_number) -> void:
	state["time_block_index"] = 0
	state["time_block"] = str(_time_blocks[0] if not _time_blocks.is_empty() else "manha")
	_run_world_tick("day_advanced")

func _on_combat_finished(result) -> void:
	if typeof(result) == TYPE_DICTIONARY:
		var memory: Array = state.get("director_memory", [])
		memory.append({
			"type": "combat_result",
			"tick": int(state.get("tick", 0)),
			"winner_id": str(result.get("winner_id", "")),
			"opponent_id": str(result.get("opponent_id", result.get("rival_id", ""))),
			"finish": str(result.get("finish", result.get("method", "")))
		})
		_trim_memory(memory)
		state["director_memory"] = memory
		_update_rival_directives(_rng_for("combat_result"))

func _run_world_tick(reason: String) -> void:
	state["tick"] = int(state.get("tick", 0)) + 1
	var rng := _rng_for(reason)
	_advance_event_durations()
	_advance_weather(rng)
	_update_npc_routines()
	_evaluate_dynamic_events(rng)
	_update_faction_pressure(rng)
	_update_rival_directives(rng)
	_update_economy()
	var snapshot := get_snapshot()
	tick_completed.emit(snapshot)
	if SignalBus.has_signal("world_tick_completed"):
		SignalBus.world_tick_completed.emit(snapshot)
	_maybe_request_ai_plan(snapshot)

func _initialize_weather() -> void:
	var regions: Dictionary = climate_data.get("regions", {})
	var weather_by_region: Dictionary = {}
	for region_id_value in regions.keys():
		var region_id := str(region_id_value)
		weather_by_region[region_id] = str(regions[region_id].get("initial", "nublado_quente"))
	state["weather_by_region"] = weather_by_region

func _advance_weather(rng: RandomNumberGenerator) -> void:
	var regions: Dictionary = climate_data.get("regions", {})
	var weather_by_region: Dictionary = state.get("weather_by_region", {})
	for region_id_value in regions.keys():
		var region_id := str(region_id_value)
		var region: Dictionary = regions[region_id]
		var old_weather := str(weather_by_region.get(region_id, region.get("initial", "nublado_quente")))
		var transitions: Dictionary = region.get("transitions", {}).get(old_weather, {})
		var new_weather := _weighted_pick(transitions, rng, old_weather)
		weather_by_region[region_id] = new_weather
		if new_weather != old_weather and SignalBus.has_signal("weather_changed"):
			SignalBus.weather_changed.emit(region_id, old_weather, new_weather)
	state["weather_by_region"] = weather_by_region

func _update_npc_routines() -> void:
	var current_block := str(state.get("time_block", "manha"))
	var npc_states: Dictionary = {}
	var schedules: Dictionary = npc_routines.get("npcs", {})
	for npc_id_value in schedules.keys():
		var npc_id := str(npc_id_value)
		var profile: Dictionary = schedules[npc_id]
		var routine: Dictionary = profile.get("schedule", {}).get(current_block, profile.get("fallback", {})).duplicate(true)
		var hub_id := str(routine.get("hub", WorldState.current_hub))
		var weather := get_weather_for_hub(hub_id)
		var override: Dictionary = profile.get("weather_overrides", {}).get(weather, {})
		if not override.is_empty():
			for key in override.keys():
				routine[key] = override[key]
		routine["time_block"] = current_block
		routine["weather"] = weather
		routine["available"] = bool(routine.get("available", true))
		npc_states[npc_id] = routine
		if SignalBus.has_signal("npc_routine_changed"):
			SignalBus.npc_routine_changed.emit(npc_id, routine)
	state["npc_states"] = npc_states

func _evaluate_dynamic_events(rng: RandomNumberGenerator) -> void:
	var events: Array = event_data.get("events", [])
	var candidates: Array = []
	for event_value in events:
		if typeof(event_value) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = event_value
		if _event_is_eligible(event, rng):
			candidates.append(event)
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("priority", 0)) > int(b.get("priority", 0)))
	var max_events := int(config.get("max_new_events_per_tick", 1))
	for index in range(min(max_events, candidates.size())):
		_trigger_event(candidates[index])

func _event_is_eligible(event: Dictionary, rng: RandomNumberGenerator) -> bool:
	var event_id := str(event.get("id", ""))
	if event_id == "" or int(state.get("event_cooldowns", {}).get(event_id, 0)) > 0:
		return false
	var conditions: Dictionary = event.get("conditions", {})
	var week := int(WorldState.week)
	if week < int(conditions.get("min_week", 1)):
		return false
	if conditions.has("max_week") and week > int(conditions.get("max_week", week)):
		return false
	var hubs: Array = conditions.get("hubs", [])
	if not hubs.is_empty() and not hubs.has(WorldState.current_hub):
		return false
	var weather_list: Array = conditions.get("weather", [])
	if not weather_list.is_empty() and not weather_list.has(get_weather_for_hub(WorldState.current_hub)):
		return false
	var reputation_min: Dictionary = conditions.get("reputation_min", {})
	for axis in reputation_min.keys():
		if WorldState.get_reputation(str(axis)) < float(reputation_min[axis]):
			return false
	var reputation_max: Dictionary = conditions.get("reputation_max", {})
	for axis in reputation_max.keys():
		if WorldState.get_reputation(str(axis)) > float(reputation_max[axis]):
			return false
	return rng.randf() <= clamp(float(event.get("chance", 0.0)), 0.0, 1.0)

func _trigger_event(event: Dictionary) -> void:
	var event_id := str(event.get("id", ""))
	var active_events: Array = state.get("active_events", [])
	for active in active_events:
		if str(active.get("id", "")) == event_id:
			return
	var runtime_event := {"id": event_id, "title": str(event.get("title", event_id)), "remaining_ticks": max(1, int(event.get("duration_ticks", 1))), "tags": event.get("tags", []), "source": "deterministic"}
	active_events.append(runtime_event)
	state["active_events"] = active_events
	var cooldowns: Dictionary = state.get("event_cooldowns", {})
	cooldowns[event_id] = max(1, int(event.get("cooldown_ticks", 3)))
	state["event_cooldowns"] = cooldowns
	_apply_world_effects(event.get("effects", {}))
	if SignalBus.has_signal("world_event_triggered"):
		SignalBus.world_event_triggered.emit(runtime_event)

func _advance_event_durations() -> void:
	var remaining: Array = []
	for event_value in state.get("active_events", []):
		var active: Dictionary = event_value.duplicate(true)
		active["remaining_ticks"] = int(active.get("remaining_ticks", 1)) - 1
		if int(active["remaining_ticks"]) > 0:
			remaining.append(active)
	state["active_events"] = remaining
	var cooldowns: Dictionary = state.get("event_cooldowns", {})
	for key in cooldowns.keys():
		cooldowns[key] = max(0, int(cooldowns[key]) - 1)
	state["event_cooldowns"] = cooldowns

func _apply_world_effects(effects: Dictionary) -> void:
	if effects.is_empty():
		return
	var faction_effects: Dictionary = {}
	for key_value in effects.keys():
		var key := str(key_value)
		if key in ["honra", "hype", "sombra", "legado", "moral", "raiz", "money"] or key.ends_with("_heat"):
			faction_effects[key] = effects[key]
	if not faction_effects.is_empty() and has_node("/root/FactionManager"):
		FactionManager.apply_choice_effects(faction_effects)
	if effects.has("energy"):
		WorldState.energy = clamp(float(WorldState.energy) + float(effects["energy"]), 0.0, 100.0)

func _update_faction_pressure(rng: RandomNumberGenerator) -> void:
	if not has_node("/root/FactionManager"):
		return
	var pressure_rules: Dictionary = config.get("faction_pressure", {})
	for faction_id_value in FactionManager.heat.keys():
		var faction_id := str(faction_id_value)
		var base_delta := float(pressure_rules.get(faction_id, 0.0))
		var reputation_factor := WorldState.get_reputation("sombra") / 100.0
		var noise := rng.randf_range(-0.5, 0.5)
		FactionManager.heat[faction_id] = clamp(float(FactionManager.heat[faction_id]) + base_delta + reputation_factor + noise, 0.0, 100.0)

func _update_rival_directives(rng: RandomNumberGenerator) -> void:
	var directives: Dictionary = {}
	var profiles: Dictionary = config.get("rival_strategy_profiles", {})
	for rival_id_value in profiles.keys():
		var rival_id := str(rival_id_value)
		var profile: Dictionary = profiles[rival_id]
		var styles: Array = profile.get("strategies", [])
		if styles.is_empty():
			continue
		var selected: Dictionary = styles[rng.randi_range(0, styles.size() - 1)].duplicate(true)
		var shadow_factor := WorldState.get_reputation("sombra") / 100.0
		selected["aggression"] = clamp(float(selected.get("aggression", 0.5)) + shadow_factor * 0.15, 0.0, 1.0)
		selected["risk_tolerance"] = clamp(float(selected.get("risk_tolerance", 0.5)), 0.0, 1.0)
		selected["gas_budget"] = clamp(float(selected.get("gas_budget", 0.7)), 0.2, 1.0)
		selected["generated_at_tick"] = int(state.get("tick", 0))
		directives[rival_id] = selected
		if SignalBus.has_signal("rival_strategy_updated"):
			SignalBus.rival_strategy_updated.emit(rival_id, selected)
	state["rival_directives"] = directives

func _update_economy() -> void:
	var multipliers: Dictionary = {}
	var economy_config: Dictionary = config.get("economy", {})
	var base_by_hub: Dictionary = economy_config.get("base_multiplier_by_hub", {})
	for hub_id_value in base_by_hub.keys():
		var hub_id := str(hub_id_value)
		var value := float(base_by_hub[hub_id])
		var weather := get_weather_for_hub(hub_id)
		value *= float(economy_config.get("weather_multipliers", {}).get(weather, 1.0))
		for active in state.get("active_events", []):
			value *= float(economy_config.get("event_multipliers", {}).get(str(active.get("id", "")), 1.0))
		multipliers[hub_id] = clamp(value, 0.65, 1.75)
	state["economy_modifiers"] = multipliers
	if SignalBus.has_signal("world_economy_changed"):
		SignalBus.world_economy_changed.emit(multipliers)

func _maybe_request_ai_plan(snapshot: Dictionary) -> void:
	if not is_ai_proxy_enabled() or _ai_request_active:
		return
	var interval: int = maxi(1, int(config.get("remote_ai", {}).get("interval_ticks", 3)))
	if int(state.get("tick", 0)) - int(state.get("last_ai_plan_tick", -999)) < interval:
		return
	var payload := {"campaign_id": WorldState.campaign_id, "snapshot": snapshot, "constraints": {"combat_llm_allowed": false, "allow_new_major_canon": false, "max_event_nudges": 2, "language": "pt-BR"}}
	var headers := PackedStringArray(["Content-Type: application/json"])
	_http.timeout = float(config.get("remote_ai", {}).get("timeout_seconds", 8.0))
	var error := _http.request(_ai_backend_url + "/v1/world/plan", headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if error == OK:
		_ai_request_active = true
	else:
		_emit_ai_failure("request_start_failed_%s" % error)

func _on_ai_plan_response(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_ai_request_active = false
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		_emit_ai_failure("http_%s_result_%s" % [response_code, result])
		return
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		_emit_ai_failure("invalid_json")
		return
	var plan: Dictionary = parsed.get("plan", parsed)
	if not _validate_and_apply_ai_plan(plan):
		_emit_ai_failure("invalid_plan")
		return
	state["last_ai_plan_tick"] = int(state.get("tick", 0))
	ai_plan_ready.emit(plan)
	if SignalBus.has_signal("world_ai_plan_applied"):
		SignalBus.world_ai_plan_applied.emit(plan)

func _validate_and_apply_ai_plan(plan: Dictionary) -> bool:
	if plan.is_empty():
		return false
	var allowed_keys := ["event_nudges", "rival_directives", "faction_pressure", "economy_modifiers", "narrative_hooks", "summary"]
	for key in plan.keys():
		if not allowed_keys.has(str(key)):
			return false
	var known_event_ids: Array = []
	for event in event_data.get("events", []):
		known_event_ids.append(str(event.get("id", "")))
	var applied_nudges := 0
	for event_id_value in plan.get("event_nudges", []):
		var event_id := str(event_id_value)
		if known_event_ids.has(event_id) and applied_nudges < 2:
			var event := _find_event(event_id)
			if not event.is_empty():
				_trigger_event(event)
				applied_nudges += 1
	var current_directives: Dictionary = state.get("rival_directives", {})
	for rival_id_value in plan.get("rival_directives", {}).keys():
		var rival_id := str(rival_id_value)
		if not current_directives.has(rival_id):
			continue
		var incoming: Dictionary = plan["rival_directives"][rival_id]
		var existing: Dictionary = current_directives[rival_id]
		for numeric_key in ["aggression", "risk_tolerance", "gas_budget"]:
			if incoming.has(numeric_key):
				existing[numeric_key] = clamp(float(incoming[numeric_key]), 0.0, 1.0)
		if incoming.has("strategy_id"):
			existing["strategy_id"] = str(incoming["strategy_id"]).left(48)
		if incoming.has("preferred_action"):
			var candidate := str(incoming["preferred_action"])
			var profile: Dictionary = DataRegistry.rival_ai_profiles.get("profiles", {}).get(rival_id, {})
			if profile.get("preferred_actions", []).has(candidate):
				existing["preferred_action"] = candidate
		current_directives[rival_id] = existing
	state["rival_directives"] = current_directives
	var memory: Array = state.get("director_memory", [])
	for hook_value in plan.get("narrative_hooks", []):
		memory.append({"type": "ai_hook", "tick": int(state.get("tick", 0)), "text": str(hook_value).left(180)})
	_trim_memory(memory)
	state["director_memory"] = memory
	return true

func _emit_ai_failure(reason: String) -> void:
	_ai_request_active = false
	ai_plan_failed.emit(reason)
	if SignalBus.has_signal("world_ai_plan_failed"):
		SignalBus.world_ai_plan_failed.emit(reason)

func _find_event(event_id: String) -> Dictionary:
	for event_value in event_data.get("events", []):
		if str(event_value.get("id", "")) == event_id:
			return event_value
	return {}

func get_weather_for_hub(hub_id: String) -> String:
	var region_id := str(climate_data.get("hub_region_map", {}).get(hub_id, "itubera_litoral"))
	return str(state.get("weather_by_region", {}).get(region_id, "nublado_quente"))

func get_weather_definition(weather_id: String) -> Dictionary:
	return climate_data.get("weather_states", {}).get(weather_id, {})

func get_npc_state(npc_id: String) -> Dictionary:
	return state.get("npc_states", {}).get(npc_id, {})

func get_rival_directive(rival_id: String) -> Dictionary:
	return state.get("rival_directives", {}).get(rival_id, {})

func get_economy_multiplier(hub_id: String) -> float:
	return float(state.get("economy_modifiers", {}).get(hub_id, 1.0))

func get_snapshot() -> Dictionary:
	return {"version": int(state.get("version", 1)), "tick": int(state.get("tick", 0)), "week": int(WorldState.week), "day": str(WorldState.current_day), "time_block": str(state.get("time_block", "manha")), "current_hub": str(WorldState.current_hub), "weather_by_region": state.get("weather_by_region", {}).duplicate(true), "current_weather": get_weather_for_hub(WorldState.current_hub), "active_events": state.get("active_events", []).duplicate(true), "npc_states": state.get("npc_states", {}).duplicate(true), "rival_directives": state.get("rival_directives", {}).duplicate(true), "economy_modifiers": state.get("economy_modifiers", {}).duplicate(true), "faction_state": FactionManager.to_dict() if has_node("/root/FactionManager") else {}, "reputation": WorldState.reputation.duplicate(true), "director_memory": state.get("director_memory", []).duplicate(true)}

func to_dict() -> Dictionary:
	return state.duplicate(true)

func load_from_dict(data: Dictionary) -> void:
	if data.is_empty():
		reset_world()
		return
	state = data.duplicate(true)
	if not state.has("weather_by_region"):
		_initialize_weather()
	_update_npc_routines()
	_update_economy()

func _rng_for(reason: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(hash("%s|%s|%s|%s|%s" % [state.get("seed", 26072026), state.get("tick", 0), WorldState.week, WorldState.current_day, reason]))
	return rng

func _weighted_pick(weights: Dictionary, rng: RandomNumberGenerator, fallback: String) -> String:
	if weights.is_empty():
		return fallback
	var keys: Array = weights.keys()
	keys.sort()
	var total := 0.0
	for key in keys:
		total += max(0.0, float(weights[key]))
	if total <= 0.0:
		return fallback
	var roll := rng.randf_range(0.0, total)
	var cursor := 0.0
	for key in keys:
		cursor += max(0.0, float(weights[key]))
		if roll <= cursor:
			return str(key)
	return str(keys.back())

func _trim_memory(memory: Array) -> void:
	var limit: int = maxi(4, int(config.get("memory_limit", 16)))
	while memory.size() > limit:
		memory.pop_front()

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("[WorldDirector] Arquivo ausente: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
