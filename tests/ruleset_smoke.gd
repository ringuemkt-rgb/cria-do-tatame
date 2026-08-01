extends SceneTree

var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _assert(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		return
	failures.append(message)
	push_error("[RulesetSmoke] " + message)

func _run() -> void:
	await process_frame
	var registry := root.get_node_or_null("DataRegistry")
	var deck := root.get_node_or_null("DeckManager")
	_assert(registry != null, "DataRegistry ausente")
	_assert(deck != null, "DeckManager ausente")
	if registry == null or deck == null:
		_finish()
		return

	_assert(str(registry.call("normalize_ruleset_id", "kimono")) == "GI", "Alias kimono não normalizou para GI")
	_assert(str(registry.call("normalize_ruleset_id", "no-gi")) == "NO_GI", "Alias no-gi não normalizou para NO_GI")
	_assert(str(registry.call("normalize_ruleset_id", "vale_tudo")) == "", "Ruleset desconhecido foi aceito")
	_assert(str(registry.call("get_default_ruleset_id")) == "GI", "Ruleset padrão não é GI")
	_assert(bool(registry.call("technique_allowed_in_ruleset", "baiana", "GI")), "Baiana deveria funcionar no GI")
	_assert(bool(registry.call("technique_allowed_in_ruleset", "baiana", "NO_GI")), "Baiana deveria funcionar no No-Gi")
	_assert(str(registry.call("get_technique_visual_variant", "grip_de_ferro", "NO_GI")) == "grip_de_ferro_punho_collar_tie", "Variante visual No-Gi do Grip de Ferro incorreta")

	var original_rulesets: Dictionary = registry.get("technique_rulesets").duplicate(true)
	var fixture_rulesets: Dictionary = original_rulesets.duplicate(true)
	var fixture_policies: Dictionary = fixture_rulesets.get("techniques", {}).duplicate(true)
	fixture_policies["test_fabric_grip"] = fixture_rulesets.get("fabric_technique_template", {}).duplicate(true)
	fixture_rulesets["techniques"] = fixture_policies
	registry.set("technique_rulesets", fixture_rulesets)

	_assert(not bool(registry.call("technique_allowed_in_ruleset", "test_fabric_grip", "NO_GI")), "Fixture de pegada de tecido foi permitida no No-Gi")
	_assert(str(registry.call("get_technique_ruleset_block_reason", "test_fabric_grip", "NO_GI")).find("tecido") >= 0, "Bloqueio No-Gi não possui explicação em português")

	var fixture := {
		"schema_version": "1.1.0",
		"owner_id": "ruan_macacao",
		"belt": "branca",
		"current_ruleset": "GI",
		"cards": [
			{
				"id": "card_baiana_test",
				"name": "Baiana",
				"kind": "active",
				"technique_id": "baiana",
				"level": 1,
				"activation_cost": {},
				"valid_states": ["PLAYER_STANDING_NEUTRAL"],
				"unlocked": true
			},
			{
				"id": "card_tecido_test",
				"name": "Pegada de Tecido — Fixture",
				"kind": "active",
				"technique_id": "test_fabric_grip",
				"level": 1,
				"activation_cost": {},
				"valid_states": ["PLAYER_STANDING_NEUTRAL"],
				"unlocked": true
			}
		],
		"equipped": {
			"active": ["card_baiana_test", "card_tecido_test"],
			"passive": []
		}
	}
	var configured: Dictionary = deck.call("configure_from_data", fixture)
	_assert(bool(configured.get("ok", false)), "Deck de teste não foi configurado")
	_assert(str(deck.call("get_ruleset_id")) == "GI", "Deck não iniciou em GI")
	_assert(deck.call("get_hand").size() == 2, "GI não carregou as duas cartas compatíveis")

	var invalid: Dictionary = deck.call("set_ruleset", "vale_tudo")
	_assert(not bool(invalid.get("ok", true)), "Deck aceitou ruleset explícito inválido")
	_assert(str(invalid.get("error", "")) == "ruleset_invalid", "Erro de ruleset inválido incorreto")
	_assert(str(deck.call("get_ruleset_id")) == "GI", "Ruleset inválido alterou o estado atual")

	var no_gi: Dictionary = deck.call("set_ruleset", "NO_GI")
	_assert(bool(no_gi.get("ok", false)), "Falha ao ativar No-Gi")
	_assert(str(deck.call("get_ruleset_id")) == "NO_GI", "Deck não registrou No-Gi")
	var no_gi_hand: Array = deck.call("get_hand")
	_assert(no_gi_hand.size() == 1, "No-Gi não filtrou exatamente uma carta de tecido")
	_assert(str(no_gi_hand[0].get("technique_id", "")) == "baiana", "Carta universal não permaneceu na mão No-Gi")
	var blocked: Array = deck.call("get_blocked_equipped_cards")
	_assert(blocked.size() == 1, "Carta de tecido não apareceu como bloqueada")
	_assert(str(blocked[0].get("card_id", "")) == "card_tecido_test", "Carta bloqueada incorreta")
	_assert(str(blocked[0].get("reason", "")).find("tecido") >= 0, "Carta bloqueada não explica o motivo")

	var saved: Dictionary = deck.call("to_dict")
	_assert(saved.get("cards", []).size() == 2, "Troca de ruleset apagou carta da coleção")
	_assert(saved.get("equipped", {}).get("active", []).size() == 2, "Troca de ruleset removeu carta equipada")
	_assert(str(saved.get("current_ruleset", "")) == "NO_GI", "Save do deck não preservou o ruleset")

	var gi: Dictionary = deck.call("set_ruleset", "kimono")
	_assert(bool(gi.get("ok", false)), "Falha ao retornar ao GI pelo alias")
	_assert(deck.call("get_hand").size() == 2, "Carta de tecido não retornou ao GI")

	registry.set("technique_rulesets", original_rulesets)
	deck.call("configure_from_data", registry.get("combat_deck"))
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("[RulesetSmoke] OK - %d verificações" % checks)
		quit(0)
		return
	print("[RulesetSmoke] FALHOU - %d de %d verificações" % [failures.size(), checks])
	for failure in failures:
		print(" - " + failure)
	quit(1)
