extends SceneTree

const HUB_SCENE := "res://scenes/hubs/TerreiroDaLuta.tscn"
const TRAINING_SCENE := "res://scenes/training/TrainingScreen.tscn"
const ARENA_SCENE := "res://scenes/combat/CombatArenaBase.tscn"
const CRIA_LIVE_SCENE := "res://scenes/ui/CriaLiveUI.tscn"

var checks := 0
var failures: Array[String] = []
var _save_snapshots: Dictionary = {}
var _save_paths: Array[String] = []
var _world: Node
var _flow: Node
var _cutscene: Node
var _save: Node
var _training_manager: Node
var _progression: Node
var _deck: Node
var _combat: Node
var _cria_live_manager: Node

func _initialize() -> void:
	call_deferred("_run")

func _assert(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("[FirstRunFlowSmoke] " + message)

func _run() -> void:
	await process_frame
	_world = root.get_node_or_null("WorldState")
	_flow = root.get_node_or_null("GameFlowManager")
	_cutscene = root.get_node_or_null("CutsceneRuntime")
	_save = root.get_node_or_null("SaveManager")
	_training_manager = root.get_node_or_null("TrainingManager")
	_progression = root.get_node_or_null("ProgressionOS")
	_deck = root.get_node_or_null("DeckManager")
	_combat = root.get_node_or_null("CombatManager")
	_cria_live_manager = root.get_node_or_null("CriaLiveManager")
	if _save == null or _flow == null or _world == null:
		_assert(false, "Autoloads essenciais ausentes no smoke")
		_finish()
		return
	_capture_save_files()
	_world.call("reset_new_game")
	_flow.call("start_new_run")
	_cria_live_manager.set("posts", [])
	_cria_live_manager.set("_last_combat_fingerprint", "")

	await _test_intro_and_training()
	await _test_first_fight_and_cria_live()
	_restore_save_files()
	_finish()

func _test_intro_and_training() -> void:
	var hub: Node = load(HUB_SCENE).instantiate()
	root.add_child(hub)
	await process_frame
	var overlay: Node = hub.get_node_or_null("CutsceneOverlay")
	_assert(overlay != null, "Terreiro nao iniciou automaticamente a cutscene recomendada")
	_assert(str(_cutscene.get("current_cutscene")) == "intro_terreiro", "A cutscene ativa nao e intro_terreiro")
	var cutscene_data: Dictionary = _cutscene.call("get_cutscene", "intro_terreiro")
	var beats: Array = cutscene_data.get("beats", [])
	_assert(not beats.is_empty(), "A cinematica canonica intro_terreiro nao tem falas")
	if overlay != null:
		var continue_button: Button = overlay.get_node("Frame/Content/Stack/Actions/Continue")
		for _beat in beats:
			continue_button.emit_signal("pressed")
			await process_frame
	var completed: Array = _flow.get("completed_steps")
	_assert(completed.has("intro_terreiro"), "Concluir a abertura nao marcou o milestone")
	_assert(str(_cutscene.get("current_cutscene")) == "", "A abertura permaneceu ativa apos a ultima fala")
	var cutscene_save := _read_save()
	var flow_save: Dictionary = cutscene_save.get("game_flow_state", {})
	_assert(flow_save.get("completed_steps", []).has("intro_terreiro"), "O milestone da abertura nao foi salvo")
	if is_instance_valid(hub):
		root.remove_child(hub)
		hub.free()

	var recommendation: Dictionary = _flow.call("next_recommended_action")
	_assert(str(recommendation.get("type", "")) == "training", "A abertura nao recomendou o treino tecnico")
	_assert(str(recommendation.get("id", "")) == "rolagem_tecnica", "O treino recomendado nao corresponde ao dado executado")
	_world.set("energy", 100.0)
	var training: Node = load(TRAINING_SCENE).instantiate()
	root.add_child(training)
	await process_frame
	var repeat_button: Button = training.get_node("Frame/Content/Stack/Actions/Repeat")
	var mastery_before := float(_progression.call("get_mastery_points", "grip_de_ferro"))
	for _repetition in range(3):
		repeat_button.emit_signal("pressed")
		await process_frame
	completed = _flow.get("completed_steps")
	_assert(completed.has("primeiro_treino_basico"), "Tres repeticoes nao concluiram o treino inicial")
	_assert(float(_progression.call("get_mastery_points", "grip_de_ferro")) > mastery_before, "O treino nao atualizou a maestria de Grip de Ferro")
	_assert(str(_flow.call("next_recommended_action").get("type", "")) == "combat", "Apos o treino, o proximo passo nao e o combate")
	if is_instance_valid(training):
		root.remove_child(training)
		training.free()

func _test_first_fight_and_cria_live() -> void:
	var selection: Array = _deck.call("get_v2_preset", "adaptativo")
	if selection.is_empty():
		selection = _deck.call("get_default_v2_selection")
	var plan: Dictionary = _combat.call("prepare_combat_v2", "davi_relampago", "arena_do_dique", "ibjjf", true, selection)
	_assert(bool(plan.get("ok", false)), "Nao foi possivel preparar o combate de smoke")
	if not bool(plan.get("ok", false)):
		return

	var arena: Node = load(ARENA_SCENE).instantiate()
	root.add_child(arena)
	await process_frame
	_assert(bool(_combat.get("is_running")), "A cena de combate nao iniciou a luta")
	# Resultado sintético apenas para provar a integração do evento de fim e dos milestones.
	arena.set("_turn_in_progress", true)
	_combat.call("finish_combat", {"winner": "ruan_macacao", "method": "smoke_flow", "technical": true})
	await process_frame
	var completed: Array = _flow.get("completed_steps")
	_assert(completed.has("primeira_luta_davi"), "Fim do combate nao marcou a primeira luta contra Davi")
	_assert(bool(_flow.call("has_flag", "first_davi_combat_post_pending")), "Fim do combate nao deixou o post pendente")
	var feed_has_combat_post := false
	for post_value in _cria_live_manager.call("get_feed"):
		if str(post_value.get("source_event", "")) == "combat_finished":
			feed_has_combat_post = true
			break
	_assert(feed_has_combat_post, "O evento da luta nao gerou postagem no Cria Live")
	if is_instance_valid(arena):
		root.remove_child(arena)
		arena.free()

	var cria_live: Node = load(CRIA_LIVE_SCENE).instantiate()
	root.add_child(cria_live)
	await process_frame
	completed = _flow.get("completed_steps")
	_assert(completed.has("primeiro_post_cria_live"), "Abrir Cria Live nao concluiu o milestone do primeiro post")
	_assert(not bool(_flow.call("has_flag", "first_davi_combat_post_pending")), "O post pendente nao foi encerrado depois de exibido")
	_assert(str(_flow.call("next_recommended_action").get("type", "")) == "mission", "O fluxo nao avançou para a próxima missão")
	var saved_flow: Dictionary = _read_save().get("game_flow_state", {})
	var saved_steps: Array = saved_flow.get("completed_steps", [])
	_assert(saved_steps.has("intro_terreiro") and saved_steps.has("primeiro_treino_basico") and saved_steps.has("primeira_luta_davi") and saved_steps.has("primeiro_post_cria_live"), "A persistencia nao preservou todos os milestones do slice")
	if is_instance_valid(cria_live):
		root.remove_child(cria_live)
		cria_live.free()

func _capture_save_files() -> void:
	var primary := str(_save.call("get_slot_path", 1))
	_save_paths = [primary, primary + ".bak", primary + ".tmp"]
	for path in _save_paths:
		var exists := FileAccess.file_exists(path)
		var content := ""
		if exists:
			var file := FileAccess.open(path, FileAccess.READ)
			if file != null:
				content = file.get_as_text()
				file.close()
		_save_snapshots[path] = {"exists": exists, "content": content}

func _restore_save_files() -> void:
	for path in _save_paths:
		var snapshot: Dictionary = _save_snapshots.get(path, {})
		if bool(snapshot.get("exists", false)):
			var file := FileAccess.open(path, FileAccess.WRITE)
			if file != null:
				file.store_string(str(snapshot.get("content", "")))
				file.flush()
				file.close()
		else:
			var absolute_path := ProjectSettings.globalize_path(path)
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(absolute_path)

func _read_save() -> Dictionary:
	var path := str(_save.call("get_slot_path", 1))
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func _finish() -> void:
	print("[FirstRunFlowSmoke] checks=%d failures=%d" % [checks, failures.size()])
	if failures.is_empty():
		print("[FirstRunFlowSmoke] PASS")
		quit(0)
	else:
		for failure in failures:
			print("[FirstRunFlowSmoke] FAIL: " + failure)
		quit(1)
