class_name SliceStateMapper
extends RefCounted

## Maps catalog alphabet (guarda_aberta) to CombatStateMachine (PLAYER_TOP_GUARD).
## Not a second judge. CombatManager still scores.

const MAPPER_PATH := "res://data/combat/state_mapper_v1.json"
const ALIASES := {
	"knee_cut": "corte_joelho",
	"corte_joelho": "corte_joelho",
	"clinch_entry": "grip_de_ferro",
	"grip_de_ferro": "grip_de_ferro",
	"kimura": "chave_braco",
	"chave_braco": "chave_braco"
}

var catalog_to_runtime: Dictionary = {}
var mirror: Dictionary = {}
var loaded: bool = false

func load_from_disk() -> void:
	if loaded:
		return
	if not FileAccess.file_exists(MAPPER_PATH):
		_seed_defaults()
		loaded = true
		return
	var file := FileAccess.open(MAPPER_PATH, FileAccess.READ)
	if file == null:
		_seed_defaults()
		loaded = true
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		_seed_defaults()
		loaded = true
		return
	catalog_to_runtime = parsed.get("catalog_to_runtime", {})
	mirror = parsed.get("mirror", {})
	if catalog_to_runtime.is_empty():
		_seed_defaults()
	loaded = true

func _seed_defaults() -> void:
	catalog_to_runtime = {
		"distancia_media": "PLAYER_STANDING_NEUTRAL",
		"disputa_pegada": "PLAYER_STANDING_NEUTRAL",
		"entrada_queda": "PLAYER_STANDING_NEUTRAL",
		"clinch_neutro": "PLAYER_TOP_CLINCH",
		"guarda_aberta": "PLAYER_TOP_GUARD",
		"guarda_fechada": "PLAYER_TOP_GUARD",
		"meia_guarda": "PLAYER_TOP_SIDE",
		"cem_quilos": "PLAYER_TOP_SIDE",
		"montada": "PLAYER_TOP_MOUNT",
		"costas": "PLAYER_BACK_ATTACK",
		"finalizacao": "PLAYER_SUBMISSION_ATTACK",
		"tartaruga": "PLAYER_BOTTOM_SIDE"
	}
	mirror = {
		"PLAYER_TOP_CLINCH": "PLAYER_BOTTOM_CLINCH",
		"PLAYER_BOTTOM_CLINCH": "PLAYER_TOP_CLINCH",
		"PLAYER_TOP_GUARD": "PLAYER_BOTTOM_GUARD",
		"PLAYER_BOTTOM_GUARD": "PLAYER_TOP_GUARD",
		"PLAYER_TOP_SIDE": "PLAYER_BOTTOM_SIDE",
		"PLAYER_BOTTOM_SIDE": "PLAYER_TOP_SIDE",
		"PLAYER_TOP_MOUNT": "PLAYER_BOTTOM_MOUNT",
		"PLAYER_BOTTOM_MOUNT": "PLAYER_TOP_MOUNT",
		"PLAYER_BACK_ATTACK": "PLAYER_BACK_DEFENSE",
		"PLAYER_BACK_DEFENSE": "PLAYER_BACK_ATTACK",
		"PLAYER_SUBMISSION_ATTACK": "PLAYER_SUBMISSION_DEFENSE",
		"PLAYER_SUBMISSION_DEFENSE": "PLAYER_SUBMISSION_ATTACK"
	}

func to_runtime(state_name: String) -> String:
	load_from_disk()
	var raw := state_name.strip_edges()
	if raw == "":
		return "PLAYER_STANDING_NEUTRAL"
	if raw.begins_with("PLAYER_") or raw == "RESET":
		return raw
	return str(catalog_to_runtime.get(raw, raw))

func mirror_state(state_name: String) -> String:
	load_from_disk()
	var runtime := to_runtime(state_name)
	return str(mirror.get(runtime, runtime))

static func canonical_technique_id(technique_id: String) -> String:
	return str(ALIASES.get(technique_id, technique_id))
