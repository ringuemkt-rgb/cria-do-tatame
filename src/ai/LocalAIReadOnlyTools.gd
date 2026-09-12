extends RefCounted

# Read-only projection layer for optional generative dialogue.
# It intentionally exposes a small public view of canon/runtime state.
# LLM output never writes back through this object.

const CANON_CONTRACT_PATH := "res://data/production/canon_contract_v4_1.json"
const BRAND_CANON_PATH := "res://data/brand/canon_lock.json"

func definitions() -> Array:
	return [
		{
			"type": "function",
			"function": {
				"name": "canon_lookup",
				"description": "Consulta somente fatos publicos e canonicos do Cria do Tatame. Use antes de afirmar lore, personagens, faccoes ou geografia.",
				"parameters": {
					"type": "object",
					"properties": {
						"query": {"type": "string", "description": "Pergunta factual curta."},
						"entity_id": {"type": "string", "description": "ID canonico opcional de personagem ou faccao."}
					},
					"required": ["query"]
				}
			}
		},
		{
			"type": "function",
			"function": {
				"name": "scene_state_get",
				"description": "Retorna somente estado publico da cena atual, sem flags secretas e sem capacidade de escrita.",
				"parameters": {
					"type": "object",
					"properties": {}
				}
			}
		},
		{
			"type": "function",
			"function": {
				"name": "progression_summary_get",
				"description": "Retorna um resumo publico e agregado da progressao social do jogador, sem ledger detalhado.",
				"parameters": {
					"type": "object",
					"properties": {}
				}
			}
		}
	]

func execute(tool_name: String, arguments: Dictionary, request_context: Dictionary = {}) -> Dictionary:
	match tool_name:
		"canon_lookup":
			return _canon_lookup(arguments)
		"scene_state_get":
			return _scene_state_get(request_context)
		"progression_summary_get":
			return _progression_summary_get()
		_:
			return {
				"ok": false,
				"status": "tool_not_allowed",
				"tool": tool_name
			}

func _canon_lookup(arguments: Dictionary) -> Dictionary:
	var query := str(arguments.get("query", "")).strip_edges().to_lower()
	var entity_id := str(arguments.get("entity_id", "")).strip_edges()
	if query == "" and entity_id == "":
		return {"ok": false, "status": "invalid_query"}

	var canon_contract := _load_json(CANON_CONTRACT_PATH)
	var brand_canon := _load_json(BRAND_CANON_PATH)
	var matches: Array = []

	if entity_id != "":
		var explicit := _lookup_entity(entity_id, canon_contract)
		if not explicit.is_empty():
			matches.append(explicit)

	if matches.is_empty():
		for faction_value in canon_contract.get("active_factions_future_domain", []):
			if not (faction_value is Dictionary):
				continue
			var faction: Dictionary = faction_value
			var searchable := "%s %s" % [
				str(faction.get("id", "")),
				str(faction.get("display_name", ""))
			]
			if _query_matches(query, searchable):
				matches.append({
					"type": "faction",
					"id": str(faction.get("id", "")),
					"display_name": str(faction.get("display_name", "")),
					"legacy_ids": faction.get("legacy_ids", []).duplicate()
				})

	if matches.is_empty():
		var data_registry := _root_node("DataRegistry")
		if data_registry != null:
			var characters_value = data_registry.get("characters")
			if characters_value is Dictionary:
				for character_id_value in characters_value.keys():
					var character_id := str(character_id_value)
					var character: Dictionary = characters_value[character_id]
					if character.get("canon", false) != true:
						continue
					var public_character := _public_character(character_id, character)
					var searchable := JSON.stringify(public_character).to_lower()
					if _query_matches(query, searchable):
						matches.append(public_character)
						if matches.size() >= 4:
							break

	var public_world := {
		"core_phrase": str(brand_canon.get("tese", "")),
		"region": str(brand_canon.get("setting", {}).get("regiao", "")),
		"hub": str(brand_canon.get("setting", {}).get("hub", "")),
		"symbol": str(brand_canon.get("simbolo", ""))
	}
	if matches.is_empty() and _query_matches(
		query,
		"%s %s %s %s itubera baixo sul bahia mundo local regiao simbolo frase" % [
			public_world["core_phrase"],
			public_world["region"],
			public_world["hub"],
			public_world["symbol"]
		]
	):
		matches.append({"type": "world", "public": public_world})

	if matches.is_empty():
		return {
			"ok": false,
			"status": "unknown_public_canon",
			"message": "Nenhum fato publico canonico foi localizado para esta consulta."
		}

	return {
		"ok": true,
		"status": "found",
		"authority": "canon_contract_v4_1 + active_runtime_data",
		"matches": matches
	}

func _lookup_entity(entity_id: String, canon_contract: Dictionary) -> Dictionary:
	for faction_value in canon_contract.get("active_factions_future_domain", []):
		if not (faction_value is Dictionary):
			continue
		var faction: Dictionary = faction_value
		if str(faction.get("id", "")) == entity_id or faction.get("legacy_ids", []).has(entity_id):
			return {
				"type": "faction",
				"id": str(faction.get("id", "")),
				"display_name": str(faction.get("display_name", "")),
				"legacy_ids": faction.get("legacy_ids", []).duplicate()
			}

	var data_registry := _root_node("DataRegistry")
	if data_registry == null:
		return {}
	var character_value = data_registry.call("get_character", entity_id)
	if not (character_value is Dictionary):
		return {}
	var character: Dictionary = character_value
	if character.is_empty() or character.get("canon", false) != true:
		return {}
	return _public_character(entity_id, character)

func _public_character(character_id: String, character: Dictionary) -> Dictionary:
	var output := {
		"type": "character",
		"id": character_id
	}
	for key in ["name", "role", "origin", "style", "narrative_function"]:
		if character.has(key):
			output[key] = character[key]
	return output

func _scene_state_get(request_context: Dictionary) -> Dictionary:
	var public_state := {
		"scene_id": str(request_context.get("scene_id", "")),
		"location": str(request_context.get("location", "")),
		"category": str(request_context.get("category", "default"))
	}
	var world_state := _root_node("WorldState")
	if world_state != null:
		public_state["current_hub"] = str(world_state.get("current_hub"))
		public_state["week"] = int(world_state.get("week"))
		public_state["day"] = str(world_state.get("current_day"))
		public_state["act"] = int(world_state.get("act"))
	return {
		"ok": true,
		"status": "public_scene_state",
		"data": public_state
	}

func _progression_summary_get() -> Dictionary:
	var progression := _root_node("ProgressionOS")
	if progression == null:
		return {
			"ok": true,
			"status": "progression_unavailable",
			"data": {}
		}
	var social_xp := 0.0
	if progression.has_method("get_domain_xp"):
		social_xp = float(progression.call("get_domain_xp", "social"))
	return {
		"ok": true,
		"status": "public_progression_summary",
		"data": {
			"respect": int(progression.get("respect")),
			"social_xp": social_xp
		}
	}

func _query_matches(query: String, searchable: String) -> bool:
	if query == "":
		return false
	var normalized_searchable := searchable.to_lower()
	if normalized_searchable.find(query) >= 0:
		return true
	var ignored := {
		"quem": true, "qual": true, "quais": true, "como": true, "onde": true,
		"que": true, "de": true, "do": true, "da": true, "dos": true, "das": true,
		"um": true, "uma": true, "o": true, "a": true, "os": true, "as": true,
		"e": true, "é": true, "eh": true, "no": true, "na": true
	}
	for raw_token in query.split(" "):
		var token := raw_token.strip_edges()
		if token.length() < 3 or ignored.has(token):
			continue
		if normalized_searchable.find(token) >= 0:
			return true
	return false

func _root_node(name: String):
	var loop = Engine.get_main_loop()
	if loop == null or not (loop is SceneTree):
		return null
	return loop.root.get_node_or_null("/root/%s" % name)

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}
