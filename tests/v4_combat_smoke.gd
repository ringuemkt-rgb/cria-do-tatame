extends SceneTree

const V4DataBridgeScript = preload("res://src/compat/V4DataBridge.gd")
const SkillHubScript = preload("res://src/hub/SkillHubLoadoutV41.gd")
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
	var bridge = V4DataBridgeScript.new()
	var report: Dictionary = bridge.load_all()
	_assert(bool(report.get("ok", false)), "dados v4 devem validar: %s" % report.get("errors", []))
	_assert(int(report.get("cards", 0)) == 20, "catálogo deve ter 20 cartas")
	_assert(int(report.get("positions", 0)) == 8, "FSM deve ter 8 posições")
	_assert(int(report.get("rulesets", 0)) == 6, "devem existir 6 rulesets")

	var hub = SkillHubScript.new()
	var hub_report: Dictionary = hub.configure(bridge.cards)
	_assert(bool(hub_report.get("ok", false)), "Hub deve carregar catálogo final")
	for card_id in ["raspagem_tesoura", "knee_cut_pass", "montada", "kimura", "triangulo", "mata_leao"]:
		_assert(bool(hub.unlock(card_id, "training").get("ok", false)), "deve desbloquear %s" % card_id)
	hub.set_deck_points("ruan_macacao", 100)
	var deck := [
		"grip_de_ferro", "baiana", "guarda_fechada", "raspagem_tesoura",
		"knee_cut_pass", "cem_quilos", "montada", "kimura",
		"triangulo", "mata_leao", "grip_de_ferro", "baiana",
	]
	var loadout_result: Dictionary = hub.set_loadout("ruan_macacao", deck)
	_assert(bool(loadout_result.get("ok", false)), "deck de 12 cartas deve ser aceito")
	_assert(hub.get_loadout("ruan_macacao").size() == 12, "loadout deve persistir 12 cartas")

	var combat: Node = bridge.create_combat({
		"ruan_macacao": deck,
		"davi_relampago": deck,
	})
	var start_result: Dictionary = combat.call("start_combat", "ruan_macacao", "davi_relampago", "OFICIAL")
	_assert(bool(start_result.get("ok", false)), "combate oficial deve iniciar")
	var first_snapshot: Dictionary = combat.call("snapshot")
	_assert(str(first_snapshot.get("position", "")) == "STANDING", "combate inicia em STANDING")
	var hand: Array = combat.call("get_contextual_hand", "ruan_macacao")
	_assert(not hand.is_empty(), "mão contextual inicial não pode estar vazia")
	var grip_result: Dictionary = combat.call("play_card", "ruan_macacao", "grip_de_ferro", 1.0)
	_assert(bool(grip_result.get("ok", false)), "Grip de Ferro deve ser jogável em STANDING")
	var clinch_snapshot: Dictionary = combat.call("snapshot")
	_assert(str(clinch_snapshot.get("position", "")) == "CLINCH", "Grip de Ferro deve levar ao CLINCH")

	var adapter_report: Dictionary = PositionalAdapterScript.validate_contract()
	_assert(bool(adapter_report.get("ok", false)), "adapter legado deve cobrir as 8 posições")

	print("[V4CombatSmoke] %d verificações, %d falhas" % [checks, failures.size()])
	quit(1 if not failures.is_empty() else 0)
