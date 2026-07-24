extends SceneTree

const PositionalAdapterScript = preload("res://src/compat/PositionalCombatAdapter.gd")
const PositionalRuntimeScript = preload("res://src/combat/PositionalCardCombatV41.gd")
const SkillHubScript = preload("res://src/hub/SkillHubLoadoutV41.gd")
const AnimationResolverScript = preload("res://src/combat/AnimationBindingResolver.gd")

var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _assert(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("[V4CombatSmoke] " + message)

func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func _new_runtime(ruleset_id: String, deck: Array, passives: Dictionary = {}) -> PositionalCardCombatV41:
	var runtime: PositionalCardCombatV41 = PositionalRuntimeScript.new()
	root.add_child(runtime)
	var report := runtime.configure(
		DataRegistry.combat_cards_v41,
		DataRegistry.combat_positions_v41,
		DataRegistry.combat_rulesets_v41,
		{"ruan_macacao": deck, "davi_relampago": deck},
		{},
		{"ruan_macacao": passives}
	)
	_assert(bool(report.get("ok", false)), "runtime local deve configurar dados v4.1")
	var start := runtime.start_combat("ruan_macacao", "davi_relampago", ruleset_id)
	_assert(bool(start.get("ok", false)), "runtime local deve iniciar ruleset %s" % ruleset_id)
	return runtime

func _force_submission(runtime: PositionalCardCombatV41) -> void:
	runtime.position = "SUBMISSION"
	runtime.player_side = "top"
	runtime.phase = "submission"
	runtime.pending_action = {
		"attacker_id": "ruan_macacao",
		"defender_id": "davi_relampago",
		"card_id": "kimura",
	}
	runtime.fighters["ruan_macacao"]["grip"] = 3.0

func _run() -> void:
	await process_frame
	_assert(DataRegistry.validation_report.get("ok", false), "DataRegistry deve validar dados v4: %s" % DataRegistry.validation_report.get("errors", []))
	_assert(DataRegistry.combat_cards_v41.get("cartas", []).size() == 20, "catálogo oficial deve ter 20 cartas")
	_assert(DataRegistry.combat_positions_v41.get("posicoes", {}).size() == 8, "FSM oficial deve ter 8 posições")
	_assert(DataRegistry.combat_rulesets_v41.get("rulesets", {}).size() == 6, "DataRegistry deve carregar 6 rulesets")
	_assert(CombatManager.has_method("start_positional_combat_v41"), "CombatManager oficial não expõe modo v4.1")
	_assert(CombatManager.has_method("start_combat"), "API legada do CombatManager foi perdida")

	var deck := [
		"grip_de_ferro", "baiana", "guarda_fechada", "raspagem_tesoura",
		"knee_cut_pass", "cem_quilos", "montada", "kimura",
		"triangulo", "mata_leao", "grip_de_ferro", "baiana",
	]

	# Ponte progressão → política por dono.
	var local_hub: SkillHubLoadoutV41 = SkillHubScript.new()
	root.add_child(local_hub)
	local_hub.configure(DataRegistry.combat_cards_v41)
	local_hub.forbid_moral_for_owner("ruan_macacao", "suja")
	var dirty_unlock := local_hub.unlock_for_owner("ruan_macacao", "dedo_no_olho", "skill_tree")
	_assert(not bool(dirty_unlock.get("ok", false)), "Código do Cria deve bloquear desbloqueio sujo por dono")
	_assert(str(dirty_unlock.get("error", "")) == "card_forbidden_by_profile", "bloqueio sujo deve usar erro canônico")
	local_hub.queue_free()

	# Ponte passivo → combate e política persistente → fachada oficial.
	WorldState.set_narrative_flag("dirty_cards_forbidden", true)
	WorldState.set_narrative_flag("combat_passives", {
		"ruan_macacao": {"sweet_spot_mult": 1.15, "grip_inicial": 1.0}
	})
	var start_result: Dictionary = CombatManager.start_positional_combat_v41(
		"terreiro_da_luta",
		"ruan_macacao",
		"davi_relampago",
		"OFICIAL",
		deck,
		deck
	)
	_assert(bool(start_result.get("ok", false)), "combate v4.1 oficial deve iniciar: %s" % start_result)
	var first_snapshot: Dictionary = CombatManager.get_positional_snapshot_v41()
	_assert(str(first_snapshot.get("position", "")) == "STANDING", "combate inicia em STANDING")
	_assert(str(CombatManager.get_current_state_name()) == "PLAYER_STANDING_NEUTRAL", "estado v4 deve sincronizar a máquina legada")
	_assert(is_equal_approx(float(first_snapshot.get("passive_snapshots", {}).get("ruan_macacao", {}).get("sweet_spot_mult", 0.0)), 1.15), "sweet spot passivo deve chegar ao runtime")
	_assert(is_equal_approx(float(first_snapshot.get("fighters", {}).get("ruan_macacao", {}).get("grip", 0.0)), 1.0), "grip inicial passivo deve alterar recursos")
	var hand: Array = CombatManager.get_contextual_hand_v41("ruan_macacao")
	_assert(not hand.is_empty(), "mão contextual oficial não pode estar vazia")
	_assert(hand.size() <= 3, "mão contextual não pode ultrapassar três cartas")

	var select_result: Dictionary = CombatManager.select_card_v41("grip_de_ferro")
	_assert(bool(select_result.get("ok", false)), "Grip de Ferro deve ser selecionável em STANDING")
	var transition_result: Dictionary = CombatManager.execute_command_v41("ruan_macacao", "transicao", "", 1.0)
	_assert(bool(transition_result.get("ok", false)), "TRANSIÇÃO deve jogar a carta selecionada")
	var clinch_snapshot: Dictionary = CombatManager.get_positional_snapshot_v41()
	_assert(str(clinch_snapshot.get("position", "")) == "CLINCH", "Grip de Ferro deve levar ao CLINCH")
	_assert(str(CombatManager.get_current_state_name()).begins_with("PLAYER_TOP_CLINCH"), "CLINCH v4 deve sincronizar estado legado")

	var grip_before := float(clinch_snapshot.get("fighters", {}).get("ruan_macacao", {}).get("grip", 0.0))
	var grip_result: Dictionary = CombatManager.execute_command_v41("ruan_macacao", "grip", "", 0.8)
	_assert(bool(grip_result.get("ok", false)), "comando GRIP deve funcionar pelo CombatManager")
	var grip_after := float(CombatManager.get_positional_snapshot_v41().get("fighters", {}).get("ruan_macacao", {}).get("grip", 0.0))
	_assert(grip_after > grip_before, "GRIP deve aumentar o nível de pegada")

	var exported: Dictionary = CombatManager.export_v41_state()
	_assert(exported.has("hub"), "CombatManager deve exportar estado persistível do Hub")
	_assert(exported.get("hub", {}).get("loadouts", {}).get("ruan_macacao", []).size() == 12, "loadout v4.1 deve persistir 12 cartas")
	_assert(exported.get("hub", {}).get("owner_policies", {}).get("ruan_macacao", {}).get("forbidden_morals", []).has("suja"), "política moral deve persistir no hub")

	# Regra única pode_jogar deve explicar posição inválida.
	var official_runtime := _new_runtime("OFICIAL", deck)
	official_runtime.hands["ruan_macacao"] = ["kimura"]
	var invalid_position := official_runtime.pode_jogar("ruan_macacao", "kimura")
	_assert(str(invalid_position.get("reason_code", "")) == "POSITION_INVALID", "Kimura em STANDING deve retornar POSITION_INVALID")
	_force_submission(official_runtime)
	var official_submission := official_runtime.resolve_submission(1.0, 0.0)
	_assert(bool(official_submission.get("victory", {}).get("accepted", false)), "Kimura no OFICIAL deve aceitar vitória")
	_assert(official_runtime.phase == "finished", "OFICIAL deve encerrar após finalização aceita")
	official_runtime.queue_free()

	var moral_runtime := _new_runtime("MORAL", deck, {"sweet_spot_mult": 1.15})
	_force_submission(moral_runtime)
	var moral_submission := moral_runtime.resolve_submission(1.0, 0.0)
	_assert(bool(moral_submission.get("victory_blocked", false)), "Kimura no MORAL não pode vencer")
	_assert(moral_runtime.phase != "finished", "MORAL deve continuar após finalização técnica")
	moral_runtime.queue_free()

	var rito_runtime := _new_runtime("RITO", deck)
	_force_submission(rito_runtime)
	var rito_submission := rito_runtime.resolve_submission(1.0, 0.0)
	_assert(bool(rito_submission.get("victory_blocked", false)), "finalização convencional no RITO deve ser bloqueada")
	_assert(rito_runtime.phase != "finished", "RITO não pode terminar por finalização convencional")
	rito_runtime.queue_free()

	# Binding semântico carta ↔ CPS ↔ estado de animação.
	var resolver: AnimationBindingResolver = AnimationResolverScript.new()
	var manifest := _load_json("res://data/characters/ruan/animation_manifest.json")
	_assert(bool(resolver.configure(manifest).get("ok", false)), "animation manifest do Ruan deve configurar")
	_assert(bool(resolver.validate_against_cards(DataRegistry.combat_cards_v41).get("ok", false)), "binding Kimura deve bater com cards.json")
	_assert(str(resolver.resolve("kimura").get("animation_state", "")) == "ruan_kimura_right", "Kimura deve resolver estado de animação canônico")

	var adapter_report: Dictionary = PositionalAdapterScript.validate_contract()
	_assert(bool(adapter_report.get("ok", false)), "adapter legado deve cobrir as 8 posições")

	CombatManager.stop_positional_mode_v41()
	var legacy_result: Dictionary = CombatManager.start_combat("terreiro_da_luta", "ruan_macacao", "davi_relampago")
	_assert(bool(legacy_result.get("ok", false)), "modo legado deve continuar iniciando após a extensão v4.1")
	_assert(str(legacy_result.get("state", "")) == "PLAYER_STANDING_NEUTRAL", "modo legado deve manter estado inicial")

	print("[V4CombatSmoke] %d verificações, %d falhas" % [checks, failures.size()])
	quit(1 if not failures.is_empty() else 0)
