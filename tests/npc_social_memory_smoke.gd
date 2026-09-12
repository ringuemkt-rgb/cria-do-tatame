extends SceneTree

var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _assert(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("[NPCSocialMemorySmoke] " + message)

func _run() -> void:
	await process_frame
	var memory := root.get_node_or_null("NPCMemoryManager")
	var save_manager := root.get_node_or_null("SaveManager")
	_assert(memory != null, "NPCMemoryManager nao foi registrado como autoload")
	_assert(save_manager != null, "SaveManager ausente")
	if memory == null:
		_finish()
		return

	memory.call("reset")
	var secret_fact := {
		"id": "smoke_fact_owner",
		"subject_id": "smoke_subject",
		"predicate": "owner",
		"value": "valor_canonico",
		"scope": "SECRET",
		"authority": "smoke_world_state"
	}
	var observed: Dictionary = memory.call(
		"observe_fact",
		secret_fact,
		["mestre_dende"],
		"smoke:observed:secret",
		"world"
	)
	_assert(bool(observed.get("ok", false)), "Fato observado valido foi rejeitado")
	_assert(bool(memory.call("knows_fact", "mestre_dende", "smoke_fact_owner")), "Testemunha nao aprendeu fato observado")
	_assert(not bool(memory.call("knows_fact", "tinker_bell", "smoke_fact_owner")), "Fato SECRET vazou para NPC que nao percebeu nem recebeu reveal")

	var rumor_claim := {
		"id": "smoke_claim_wrong_owner",
		"subject_id": "smoke_subject",
		"predicate": "owner",
		"value": "valor_falso",
		"confidence": 0.75
	}
	var heard: Dictionary = memory.call(
		"hear_claim",
		rumor_claim,
		["tinker_bell"],
		"smoke:claim:rumor",
		"rumor_source"
	)
	_assert(bool(heard.get("ok", false)), "Claim valido foi rejeitado")
	_assert(not bool(memory.call("knows_fact", "tinker_bell", "smoke_fact_owner")), "Claim foi promovido indevidamente a fato")
	var before_reveal: Dictionary = memory.call("get_context", "tinker_bell")
	var belief_key := "smoke_subject|owner"
	var belief_before: Dictionary = before_reveal.get("beliefs", {}).get(belief_key, {})
	_assert(str(belief_before.get("value", "")) == "valor_falso", "Rumor nao entrou como belief separado")
	_assert(str(belief_before.get("status", "")) == "unverified", "Belief inicial deveria permanecer nao verificado")

	var reveal: Dictionary = memory.call(
		"reveal_fact",
		secret_fact,
		["tinker_bell"],
		"smoke:reveal:secret",
		"mestre_dende"
	)
	_assert(bool(reveal.get("ok", false)), "Reveal explicito foi rejeitado")
	_assert(bool(memory.call("knows_fact", "tinker_bell", "smoke_fact_owner")), "Reveal explicito nao concedeu conhecimento")
	var after_reveal: Dictionary = memory.call("get_context", "tinker_bell")
	var belief_after: Dictionary = after_reveal.get("beliefs", {}).get(belief_key, {})
	_assert(str(belief_after.get("status", "")) == "contradicted_by_fact", "Fato canonico nao venceu belief contraditorio")
	_assert(after_reveal.get("contradictions", []).size() >= 1, "Contradicao nao ficou inspecionavel")
	var rumor_relation: Dictionary = after_reveal.get("relationships", {}).get("rumor_source", {})
	_assert(float(rumor_relation.get("suspicion", 0.0)) >= 12.0, "Evidencia contraditoria nao elevou suspeita da fonte")
	_assert(float(rumor_relation.get("trust", 0.0)) <= -8.0, "Evidencia contraditoria nao reduziu confianca na fonte")

	var sequence_before_duplicate := int(memory.call("get_debug_snapshot").get("sequence", -1))
	var duplicate: Dictionary = memory.call(
		"reveal_fact",
		secret_fact,
		["tinker_bell"],
		"smoke:reveal:secret",
		"mestre_dende"
	)
	_assert(bool(duplicate.get("duplicate", false)), "Deduplicacao por event_id falhou")
	_assert(int(memory.call("get_debug_snapshot").get("sequence", -1)) == sequence_before_duplicate, "Evento duplicado alterou sequencia")

	var sequence_before_forbidden := int(memory.call("get_debug_snapshot").get("sequence", -1))
	var forbidden: Dictionary = memory.call("record_event", {
		"type": "RELATIONSHIP_DELTA",
		"event_id": "smoke:forbidden:nex_write",
		"npc_id": "tinker_bell",
		"target_id": "ruan_macacao",
		"deltas": {"trust": 99.0}
	}, "Nex-N2.5-mini")
	_assert(not bool(forbidden.get("ok", true)), "Nex conseguiu escrever memoria social")
	_assert(str(forbidden.get("error", "")) == "producer_forbidden", "Write proibido nao retornou motivo correto")
	_assert(int(memory.call("get_debug_snapshot").get("sequence", -1)) == sequence_before_forbidden, "Write proibido alterou estado")

	var candidates := [
		{"id": "approach_source", "target_id": "rumor_source", "base_utility": 0.0, "tags": ["approach"]},
		{"id": "investigate_source", "target_id": "rumor_source", "base_utility": 0.0, "tags": ["investigate"]}
	]
	var choice_a: Dictionary = memory.call("choose_action", "tinker_bell", candidates)
	var choice_b: Dictionary = memory.call("choose_action", "tinker_bell", candidates)
	_assert(bool(choice_a.get("ok", false)), "Utility social nao escolheu acao")
	_assert(str(choice_a.get("action", "")) == "investigate_source", "Suspeita nao influenciou acao deterministica esperada")
	_assert(JSON.stringify(choice_a) == JSON.stringify(choice_b), "Mesma memoria e candidatos produziram decisoes diferentes")

	var saved_state: Dictionary = memory.call("to_dict")
	memory.call("reset")
	_assert(not bool(memory.call("knows_fact", "tinker_bell", "smoke_fact_owner")), "Reset nao zerou memoria")
	memory.call("load_from_dict", saved_state)
	_assert(bool(memory.call("knows_fact", "tinker_bell", "smoke_fact_owner")), "Round-trip direto perdeu fato conhecido")
	var restored_context: Dictionary = memory.call("get_context", "tinker_bell")
	_assert(str(restored_context.get("beliefs", {}).get(belief_key, {}).get("status", "")) == "contradicted_by_fact", "Round-trip direto perdeu estado da belief")

	if save_manager != null:
		var slot := 97
		save_manager.call("delete_save", slot)
		_assert(bool(save_manager.call("save_game", slot)), "SaveManager nao serializou memoria social")
		memory.call("reset")
		_assert(not bool(memory.call("knows_fact", "tinker_bell", "smoke_fact_owner")), "Reset antes do load falhou")
		_assert(bool(save_manager.call("load_game", slot)), "SaveManager nao carregou slot de smoke")
		_assert(bool(memory.call("knows_fact", "tinker_bell", "smoke_fact_owner")), "Save/load perdeu memoria social")
		var loaded_context: Dictionary = memory.call("get_context", "tinker_bell")
		_assert(float(loaded_context.get("relationships", {}).get("rumor_source", {}).get("suspicion", 0.0)) >= 12.0, "Save/load perdeu suspeita derivada")
		save_manager.call("delete_save", slot)

	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("[NPCSocialMemorySmoke] PASS — %d verificacoes" % checks)
		quit(0)
	else:
		print("[NPCSocialMemorySmoke] FAIL — %d falhas em %d verificacoes" % [failures.size(), checks])
		quit(1)
