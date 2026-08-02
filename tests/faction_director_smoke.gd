extends SceneTree

const FactionIdentityV4 = preload("res://src/factions/FactionIdentityV4.gd")

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
	if director == null or world_state == null or faction_manager == null or save_manager == null:
		_finish()
		return

	world_state.call("reset_new_game")
	faction_manager.call("reset")
	director.call("reset_director")
	var initial: Dictionary = director.call("get_snapshot")
	var initial_factions: Dictionary = initial.get("factions", {})
	_assert(initial_factions.size() == 3, "Diretor nao carregou exatamente tres faccoes")
	_assert(initial_factions.has("ALE"), "Facção ALE ausente")
	_assert(initial_factions.has("LEM"), "Facção LEM ausente")
	_assert(initial_factions.has("NTM"), "Facção NTM ausente")
	_assert(str(initial_factions.get("ALE", {}).get("name", "")) == "Os Aleluiados", "Nome canonico de ALE incorreto")
	_assert(initial.get("territories", {}).size() >= 15, "Diretor carregou poucos territorios")
	_assert(int(initial.get("pressure_level", -1)) == 0, "Pressao regional inicial deveria ser zero")
	_assert(director.call("get_faction", "dragao_vermelho").is_empty(), "Dragao Vermelho permaneceu como faccao ativa")
	_assert(director.call("get_faction", "fantasma").is_empty(), "Fantasma permaneceu como faccao ativa")

	var feed_before: int = int(cria_live.call("get_feed").size())
	director.call("advance_faction_week", 2)
	var after_start: Dictionary = director.call("get_snapshot")
	_assert(after_start.get("active_operations", []).size() >= 2, "Faccoes nao iniciaram operacoes autonomas")
	director.call("advance_faction_week", 3)
	director.call("advance_faction_week", 4)
	var after_resolution: Dictionary = director.call("to_dict")
	_assert(after_resolution.get("operation_history", []).size() > 0, "Nenhuma operacao foi resolvida")
	_assert(cria_live.call("get_feed").size() > feed_before, "Operacoes nao produziram impacto no Cria Live")

	var relation_before := float(faction_manager.call("get_relation", "os_aleluia"))
	var memory: Dictionary = director.call(
		"register_player_action",
		"ALE",
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
	_assert(float(faction_manager.call("get_relation", "ALE")) < relation_before, "Relacao canonica nao reagiu a acao do jogador")
	_assert(is_equal_approx(float(faction_manager.call("get_relation", "ALE")), float(faction_manager.call("get_relation", "os_aleluia"))), "Alias os_aleluia divergiu de ALE")
	_assert(director.call("get_recent_memories", "ALE", 4).size() > 0, "Memoria da faccao nao foi registrada")
	_assert(int(director.call("get_pressure_level")) >= 1, "Pressao regional nao reagiu a exposicao")

	var debt: Dictionary = director.call("add_debt", "NTM", "imagem", 25.0, "cassio_molho_oliveira", 8, "Convite aceito em evento publico")
	_assert(str(debt.get("status", "")) == "active", "Divida nao foi criada")
	_assert(director.call("get_active_debts", "NTM").size() == 1, "Divida ativa nao foi encontrada")
	_assert(bool(director.call("settle_debt", str(debt.get("id", "")), "recusada")), "Divida nao foi resolvida")
	_assert(director.call("get_active_debts", "NTM").is_empty(), "Divida resolvida permaneceu ativa")

	const SLOT := 9877
	var saved_power := float(director.call("get_faction", "ALE").get("power", {}).get("coesao", 0.0))
	_assert(bool(save_manager.call("save_game", SLOT)), "Save v5 falhou")
	director.call("adjust_power", "ALE", "coesao", -25.0, "smoke_mutation")
	_assert(bool(save_manager.call("load_game", SLOT)), "Load v5 falhou")
	var loaded_power := float(director.call("get_faction", "ALE").get("power", {}).get("coesao", 0.0))
	_assert(is_equal_approx(saved_power, loaded_power), "Save nao restaurou estado politico")
	save_manager.call("delete_save", SLOT)

	faction_manager.call("load_from_dict", {
		"relations": {"os_aleluia": 12.0, "dragao_vermelho": -18.0},
		"heat": {"la_ele_mil_vezes": 7.0, "fantasma": 5.0},
		"faction_flags": {"nos_tem_um_molho": {"convite": true}}
	})
	var migrated_faction_state: Dictionary = faction_manager.call("to_dict")
	_assert(migrated_faction_state.get("relations", {}).keys().size() == 3, "Migracao nao limitou relacoes ao dominio ativo")
	_assert(is_equal_approx(float(faction_manager.call("get_relation", "ALE")), 12.0), "Alias os_aleluia nao migrou para ALE")
	_assert(is_equal_approx(float(faction_manager.call("get_heat", "LEM")), 7.0), "Alias la_ele_mil_vezes nao migrou para LEM")
	_assert(bool(faction_manager.call("get_flag", "NTM", "convite", false)), "Flag legada nao migrou para NTM")
	_assert(migrated_faction_state.get("legacy_archive", {}).get("relations", {}).has("dragao_vermelho"), "Relacao aposentada nao foi arquivada")
	_assert(migrated_faction_state.get("legacy_archive", {}).get("heat", {}).has("fantasma"), "Heat aposentado nao foi arquivado")

	var migrated_director := FactionIdentityV4.migrate_director_state({
		"version": 2,
		"factions": {
			"os_aleluia": {"id": "os_aleluia", "name": "Os Aleluia", "power": {}},
			"la_ele_mil_vezes": {"id": "la_ele_mil_vezes", "name": "Lá Ele Mil Vezes", "power": {}},
			"nos_tem_um_molho": {"id": "nos_tem_um_molho", "name": "Nós Tem Um Molho", "power": {}},
			"terreiro": {"id": "terreiro", "name": "Terreiro", "power": {}}
		},
		"territories": {
			"teste": {"owner": "terreiro", "challengers": ["os_aleluia"], "influence_by_faction": {"terreiro": 50.0, "os_aleluia": 12.0}}
		},
		"conflicts": {},
		"active_operations": [],
		"operation_history": [],
		"memories": [],
		"debts": [],
		"pressure": {},
		"champions": {},
		"pending_hooks": []
	})
	_assert(migrated_director.get("factions", {}).keys().size() == 3, "Mapper do diretor nao gerou tres faccoes")
	_assert(migrated_director.get("factions", {}).has("ALE"), "Mapper do diretor nao gerou ALE")
	_assert(str(migrated_director.get("factions", {}).get("ALE", {}).get("name", "")) == "Os Aleluiados", "Mapper nao corrigiu display de ALE")
	_assert(str(migrated_director.get("territories", {}).get("teste", {}).get("owner", "")) == "neutral", "Dominio comunitario nao virou territorio neutro")
	_assert(migrated_director.get("legacy_archive", {}).get("factions", {}).has("terreiro"), "Dominio comunitario nao foi arquivado")
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
