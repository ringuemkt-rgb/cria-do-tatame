extends SceneTree

var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _assert(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("[ProgressionOSSmoke] " + message)

func _run() -> void:
	await process_frame
	var progression := root.get_node_or_null("ProgressionOS")
	var world_state := root.get_node_or_null("WorldState")
	var training := root.get_node_or_null("TrainingManager")
	var world_map := root.get_node_or_null("WorldMapManager")
	var mission_manager := root.get_node_or_null("MissionManager")
	var save_manager := root.get_node_or_null("SaveManager")

	_assert(progression != null, "ProgressionOS nao foi registrado como autoload")
	_assert(world_state != null, "WorldState ausente")
	_assert(training != null, "TrainingManager ausente")
	_assert(world_map != null, "WorldMapManager ausente")
	if progression == null or world_state == null:
		_finish()
		return

	world_state.call("reset_new_game")
	if world_map != null:
		world_map.call("reset")
	_assert(int(progression.call("get_snapshot").get("event_count", -1)) == 0, "Novo jogo nao zerou o ledger")
	_assert(progression.call("get_domain_xp", "combat") == 0.0, "Dominio combat nao iniciou zerado")

	var event_id := "smoke:dedup:mission"
	var first: Dictionary = progression.call(
		"record_event",
		"mission_complete",
		"smoke",
		75.0,
		{"mission_id": "smoke_01", "domain": "story", "domain_xp": 75.0, "respect": 10},
		event_id
	)
	var duplicate: Dictionary = progression.call(
		"record_event",
		"mission_complete",
		"smoke",
		75.0,
		{"mission_id": "smoke_01", "domain": "story", "domain_xp": 75.0, "respect": 10},
		event_id
	)
	_assert(bool(first.get("ok", false)), "Evento valido nao entrou no ledger")
	_assert(bool(duplicate.get("duplicate", false)), "Deduplicacao por event_id falhou")
	_assert(is_equal_approx(float(progression.call("get_domain_xp", "story")), 75.0), "Evento duplicado alterou XP de story")

	var technique_id := "smoke_tecnica"
	progression.call(
		"record_event",
		"technical_training",
		"training",
		20.0,
		{
			"technique_id": technique_id,
			"mastery_xp": 100.0,
			"attempted": true,
			"success": true,
			"training": true,
			"domain": "training",
			"domain_xp": 20.0,
			"respect": 0
		},
		"smoke:mastery:learned"
	)
	_assert(str(progression.call("get_mastery_stage", technique_id)) == "learned", "Threshold de maestria learned falhou")
	_assert(world_state.get("techniques_learned").has(technique_id), "Codex aprendido nao sincronizou WorldState")
	_assert(int(progression.call("get_mastery_level", technique_id)) == 2, "Nivel derivado da maestria nao corresponde ao threshold")

	var state: Dictionary = progression.call("to_dict")
	var event_count_before := int(state.get("ledger", []).size())
	var respect_before := int(state.get("respect", 0))
	progression.call("reset")
	progression.call("load_from_dict", state)
	_assert(int(progression.call("get_snapshot").get("event_count", -1)) == event_count_before, "Round-trip do ledger perdeu eventos")
	_assert(int(progression.get("respect")) == respect_before, "Round-trip perdeu Respect")
	_assert(str(progression.call("get_mastery_stage", technique_id)) == "learned", "Round-trip perdeu Codex/maestria")

	progression.call("rebuild_projections_from_ledger")
	_assert(str(progression.call("get_mastery_stage", technique_id)) == "learned", "Rebuild pelo ledger mudou a maestria")
	_assert(is_equal_approx(float(progression.call("get_domain_xp", "story")), 75.0), "Rebuild pelo ledger mudou XP de story")

	progression.call("reset")
	world_state.set("techniques_learned", [])
	progression.call("import_legacy_training_mastery", {"legacy_smoke": 120.0})
	_assert(is_equal_approx(float(progression.call("get_mastery_points", "legacy_smoke")), 120.0), "Migracao da maestria legada perdeu pontos")
	_assert(str(progression.call("get_mastery_stage", "legacy_smoke")) == "learned", "Migracao legada nao derivou stage learned")
	var legacy_count := int(progression.call("get_snapshot").get("event_count", 0))
	progression.call("import_legacy_training_mastery", {"legacy_smoke": 120.0})
	_assert(int(progression.call("get_snapshot").get("event_count", 0)) == legacy_count, "Migracao legada nao foi idempotente")

	if training != null:
		progression.call("reset")
		training.call("reset")
		world_state.set("energy", 100.0)
		var training_result: Dictionary = training.call("run_technical_training", "sprawl", 3)
		_assert(bool(training_result.get("ok", false)), "TrainingManager nao concluiu treino tecnico")
		_assert(float(progression.call("get_mastery_points", "sprawl")) > 0.0, "TrainingManager nao alimentou ProgressionOS")
		_assert(is_equal_approx(float(training.call("get_mastery_points", "sprawl")), float(progression.call("get_mastery_points", "sprawl"))), "TrainingManager divergiu da autoridade de maestria")

	if mission_manager != null:
		var story_before := float(progression.call("get_domain_xp", "story"))
		mission_manager.call("complete_mission", "smoke_progression_mission")
		_assert(float(progression.call("get_domain_xp", "story")) > story_before, "MissionManager nao gerou progresso de story")

	if world_map != null:
		world_state.set("money", 99999)
		var exploration_before := float(progression.call("get_domain_xp", "exploration"))
		var travel_result: Dictionary = world_map.call("travel_to", "salvador")
		_assert(bool(travel_result.get("ok", false)), "Viagem smoke para Salvador falhou")
		_assert(float(progression.call("get_domain_xp", "exploration")) > exploration_before, "WorldMapManager nao gerou progresso de exploracao")
		_assert(progression.get("discoveries").has("hub:salvador"), "Primeira visita nao entrou nas descobertas")

	if save_manager != null:
		save_manager.call("delete_save", 1)
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("[ProgressionOSSmoke] PASS — %d verificacoes" % checks)
		quit(0)
	else:
		print("[ProgressionOSSmoke] FAIL — %d falhas em %d verificacoes" % [failures.size(), checks])
		quit(1)
