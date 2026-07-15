extends SceneTree

var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _assert(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("[FactionDirectorSmoke] " + message)

func _run() -> void:
	await process_frame
	var world_state := root.get_node_or_null("WorldState")
	var faction_manager := root.get_node_or_null("FactionManager")
	var director := root.get_node_or_null("FactionDirectorManager")
	var cria_live := root.get_node_or_null("CriaLiveManager")
	var save_manager := root.get_node_or_null("SaveManager")

	_assert(world_state != null, "WorldState ausente")
	_assert(faction_manager != null, "FactionManager ausente")
	_assert(director != null, "FactionDirectorManager ausente")
	_assert(cria_live != null, "CriaLiveManager ausente")
	_assert(save_manager != null, "SaveManager ausente")
	if director == null or world_state == null:
		_finish()
		return

	world_state.call("reset_new_game")
	faction_manager.call("reset")
	director.call("reset_director")
	var initial: Dictionary = director.call("get_snapshot")
	_assert(initial.get("factions", {}).size() == 7, "Diretor nao carregou sete faccoes")
	_assert(initial.get("territories", {}).size() >= 15, "Diretor carregou poucos territorios")
	_assert(int(initial.get("pressure_level", -1)) == 0, "Pressao regional inicial deveria ser zero")
	_assert(not director.call("get_faction", "dragao_vermelho").is_empty(), "Dragao Vermelho ausente")
	_assert(not director.call("get_faction", "fantasma").is_empty(), "Fantasma ausente")

	var feed_before := cria_live.call("get_feed").size()
	director.call("advance_faction_week", 2)
	var after_start: Dictionary = director.call("get_snapshot")
	_assert(after_start.get("active_operations", []).size() >= 4, "Faccoes nao iniciaram operacoes autonomas")
	director.call("advance_faction_week", 3)
	director.call("advance_faction_week", 4)
	var after_resolution: Dictionary = director.call("to_dict")
	_assert(after_resolution.get("operation_history", []).size() > 0, "Nenhuma operacao foi resolvida")
	_assert(cria_live.call("get_feed").size() > feed_before, "Operacoes nao produziram impacto no Cria Live")

	var relation_before := float(faction_manager.call("get_relation", "os_aleluia"))
	var memory: Dictionary = director.call(
		"register_player_action",
		"os_aleluia",
		"recusou_contrato_publicamente",
		-6.0,
		5.0,
		{
			"territory_id": "arena_do_dique",
			"witnesses": ["tinker_bell", "capitao_beto_juiz"],
			"pressure_effects": {"atencao_publica": 14, "exposicao_digital": 12},
			"power_effects": {"coesao": -2}
		}
	)
	_assert(not memory.is_empty(), "Acao do jogador nao gerou memoria")
	_assert(float(faction_manager.call("get_relation", "os_aleluia")) < relation_before, "Relacao nao reagiu a acao do jogador")
	_assert(director.call("get_recent_memories", "os_aleluia", 4).size() > 0, "Memoria da faccao nao foi registrada")
	_assert(int(director.call("get_pressure_level")) >= 1, "Pressao regional nao reagiu a exposicao")

	var debt: Dictionary = director.call("add_debt", "nos_tem_um_molho", "imagem", 25.0, "cassio_molho_oliveira", 8, "Convite aceito em evento publico")
	_assert(str(debt.get("status", "")) == "active", "Divida nao foi criada")
	_assert(director.call("get_active_debts", "nos_tem_um_molho").size() == 1, "Divida ativa nao foi encontrada")
	_assert(bool(director.call("settle_debt", str(debt.get("id", "")), "recusada")), "Divida nao foi resolvida")
	_assert(director.call("get_active_debts", "nos_tem_um_molho").is_empty(), "Divida resolvida permaneceu ativa")

	const SLOT := 9877
	var saved_power := float(director.call("get_faction", "terreiro").get("power", {}).get("coesao", 0.0))
	_assert(bool(save_manager.call("save_game", SLOT)), "Save v4 falhou")
	director.call("adjust_power", "terreiro", "coesao", -25.0, "smoke_mutation")
	_assert(bool(save_manager.call("load_game", SLOT)), "Load v4 falhou")
	var loaded_power := float(director.call("get_faction", "terreiro").get("power", {}).get("coesao", 0.0))
	_assert(is_equal_approx(saved_power, loaded_power), "Save nao restaurou estado politico")
	save_manager.call("delete_save", SLOT)

	faction_manager.call("load_from_dict", {"relations": {"os_aleluia": 12.0}, "heat": {}})
	_assert(faction_manager.call("to_dict").get("relations", {}).has("dragao_vermelho"), "Migracao de save antigo perdeu nova faccao")
	_assert(faction_manager.call("to_dict").get("relations", {}).has("fantasma"), "Migracao de save antigo perdeu Fantasma")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("[FactionDirectorSmoke] OK - %d verificacoes" % checks)
		quit(0)
	else:
		print("[FactionDirectorSmoke] FALHOU - %d de %d verificacoes" % [failures.size(), checks])
		for failure in failures:
			print(" - " + failure)
		quit(1)
