extends SceneTree

const PositionalAdapterScript = preload("res://src/compat/PositionalCombatAdapter.gd")

var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _assert(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("[V4CombatSmoke] " + message)

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

	var adapter_report: Dictionary = PositionalAdapterScript.validate_contract()
	_assert(bool(adapter_report.get("ok", false)), "adapter legado deve cobrir as 8 posições")

	CombatManager.stop_positional_mode_v41()
	var legacy_result: Dictionary = CombatManager.start_combat("terreiro_da_luta", "ruan_macacao", "davi_relampago")
	_assert(bool(legacy_result.get("ok", false)), "modo legado deve continuar iniciando após a extensão v4.1")
	_assert(str(legacy_result.get("state", "")) == "PLAYER_STANDING_NEUTRAL", "modo legado deve manter estado inicial")

	print("[V4CombatSmoke] %d verificações, %d falhas" % [checks, failures.size()])
	quit(1 if not failures.is_empty() else 0)
