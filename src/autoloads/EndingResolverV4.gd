extends Node

var definitions: Dictionary = {}
var last_resolution: Dictionary = {}

func _ready() -> void:
	definitions = _load_json("res://data/narrative/endings_v4.json")

func evaluate() -> Dictionary:
	var flags: Dictionary = WorldState.story_flags
	var honra := float(WorldState.reputation.get("honra", 0.0))
	var raiz := float(WorldState.reputation.get("raiz", 0.0))
	var sombra := float(WorldState.reputation.get("sombra", 0.0))
	var circuito := float(WorldState.reputation.get("legado", 0.0))
	var hype := float(WorldState.reputation.get("hype", 0.0))
	var mangue_vivo := str(flags.get("mangue_estado", "vivo")) == "vivo"
	var tupa := str(flags.get("tupa200_resolucao", "pendente"))
	var tupa_comunitaria := tupa in ["formalizou", "contexto", "comunitaria"]
	var informant_status := str(flags.get("informant_status", InformantSystem.status))
	var evidence := maxi(int(flags.get("provas_joaquim", 0)), int(InformantSystem.evidence_count))
	var leoa := int(flags.get("leoa_vinculo", 0))
	var underground := str(flags.get("underground_acesso", "nenhum"))
	var molho := Economy.get_balance(Economy.MOLHO)
	var candidates: Array[String] = []

	if honra >= 8.0 and informant_status == "ativo" and evidence >= 3 and tupa_comunitaria:
		candidates.append("martir_do_tatame")
	if honra >= 8.0 and raiz >= 8.0 and leoa >= 3 and tupa_comunitaria and mangue_vivo:
		candidates.append("ponte")
	if honra >= 8.0 and raiz >= 8.0 and mangue_vivo and tupa_comunitaria and informant_status != "queimado":
		candidates.append("cria_de_verdade")
	if sombra >= 40.0 and underground == "cedo" and informant_status == "queimado":
		candidates.append("sombra")
	if (circuito >= 8.0 or hype >= 8.0) and honra < 0.0 and molho > 0:
		candidates.append("campeao_oco")

	var ending_id := _highest_priority(candidates)
	if ending_id == "":
		ending_id = _fallback_ending(honra, raiz, sombra, molho)
	var ending: Dictionary = definitions.get("endings", {}).get(ending_id, {}).duplicate(true)
	last_resolution = {
		"id": ending_id,
		"ending": ending,
		"candidates": candidates,
		"snapshot": {
			"honra": honra,
			"raiz": raiz,
			"sombra": sombra,
			"circuito": circuito,
			"hype": hype,
			"mangue_vivo": mangue_vivo,
			"tupa200_resolucao": tupa,
			"informant_status": informant_status,
			"evidence": evidence,
			"leoa_vinculo": leoa,
			"molho": molho,
		},
	}
	if SignalBus.has_signal("ending_resolved_v4"):
		SignalBus.ending_resolved_v4.emit(last_resolution.duplicate(true))
	return last_resolution.duplicate(true)

func get_boss_contract() -> Dictionary:
	var result := last_resolution if not last_resolution.is_empty() else evaluate()
	return {
		"ending_id": str(result.get("id", "")),
		"boss": str(result.get("ending", {}).get("boss", "vitor_limpo")),
		"moral_boss": definitions.get("moral_boss", {}).duplicate(true),
	}

func get_belt_ceremony() -> Dictionary:
	var result := last_resolution if not last_resolution.is_empty() else evaluate()
	return {
		"ending_id": str(result.get("id", "")),
		"giver": str(result.get("ending", {}).get("ceremony_giver", "dende")),
		"result": str(result.get("ending", {}).get("result", "ciclo_aberto")),
	}

func to_dict() -> Dictionary:
	return {"version": 1, "last_resolution": last_resolution.duplicate(true)}

func load_from_dict(data: Dictionary) -> void:
	last_resolution = data.get("last_resolution", {}).duplicate(true)

func _highest_priority(candidates: Array[String]) -> String:
	for ending_value in definitions.get("priority", []):
		var ending_id := str(ending_value)
		if candidates.has(ending_id):
			return ending_id
	return ""

func _fallback_ending(honra: float, raiz: float, sombra: float, molho: int) -> String:
	if sombra > maxf(honra, raiz): return "sombra"
	if molho > 0 and honra < 0.0: return "campeao_oco"
	if raiz >= honra: return "ponte"
	return "cria_de_verdade"

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
