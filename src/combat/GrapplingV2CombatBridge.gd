class_name GrapplingV2CombatBridge
extends RefCounted
## Maps CombatManager / TechniqueResolver results into V2 motion queries.
## Never steps BJJGraphReducerV2. Never becomes an autoload.

const BRIDGE_PATH := "res://data/combat/grappling_v2_combat_manager_bridge_v1.json"

var spec: Dictionary = {}

func _init(spec_override: Dictionary = {}) -> void:
	if spec_override.is_empty():
		spec = _load_json(BRIDGE_PATH)
	else:
		spec = spec_override.duplicate(true)

func is_ready() -> bool:
	return not spec.is_empty() and str(spec.get("authorities", {}).get("scene", "")) == "CombatManager"

func query_from_resolver(result: Dictionary, context: Dictionary = {}) -> Dictionary:
	var flag := _resolver_flag(result)
	var technique_id := str(result.get("technique_id", context.get("technique_id", "")))
	var hints: Dictionary = spec.get("slice_ouro_hints", {}).get(technique_id, {})
	var reaction := str(spec.get("resolver_to_reaction", {}).get(flag, "stabilize"))
	if flag == "denied" and str(hints.get("deny_reaction", "")) != "":
		reaction = str(hints.get("deny_reaction"))
	var phase := str(context.get("phase", _phase_from_flag(flag, hints)))
	var frames := int(result.get("frame", context.get("frame", 0)))
	var ms_per := int(spec.get("clock", {}).get("ms_per_frame_default", 16))
	return {
		"ok": true,
		"shipping": false,
		"authority": "CombatManager",
		"presentation": "CriaGrapplingEngineV2",
		"technique_id": technique_id,
		"attack_type": str(hints.get("attack_type", context.get("attack_type", ""))),
		"position_id": str(context.get("position_id", result.get("state_to", ""))),
		"top_role": str(context.get("top_role", "neutral")),
		"mode": str(context.get("mode", "gi")),
		"phase": phase,
		"reaction_id": reaction,
		"gas_bucket": str(context.get("gas_bucket", "working")),
		"resolver_flag": flag,
		"denied": bool(result.get("denied", false)),
		"time_ms": frames * ms_per,
		"may_mutate_combat": false
	}

func _resolver_flag(result: Dictionary) -> String:
	if bool(result.get("denied", false)):
		return "denied"
	if bool(result.get("faked", false)) or bool(result.get("released_before_commit", false)):
		return "faked"
	if str(result.get("chain_id", "")) != "":
		return "chained"
	if bool(result.get("committed", false)):
		return "committed"
	return "success"

func _phase_from_flag(flag: String, hints: Dictionary) -> String:
	var phases = hints.get("phases", [])
	if typeof(phases) == TYPE_ARRAY and not phases.is_empty():
		if flag == "denied" or flag == "faked":
			return "response"
		if flag == "committed":
			return "establish"
		return str(phases[0])
	if flag == "denied":
		return "response"
	return "entry"

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	return {}
