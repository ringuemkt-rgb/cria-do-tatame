extends Control

const COMBAT_SCENE := "res://scenes/combat/CombatArenaBase.tscn"
const TERREIRO_SCENE := "res://scenes/hubs/TerreiroDaLuta.tscn"

@export var opponent_id := "davi_relampago"
@export var arena_id := "arena_do_dique"

var _ruleset_ids := ["ibjjf", "adcc", "clandestina"]
var _current_plan: Dictionary = {}

func _ready() -> void:
	$Root/Footer/Confirm.pressed.connect(_on_confirm)
	$Root/Footer/Back.pressed.connect(_on_back)
	$Root/TinkerPanel/Body/ListenPlan.pressed.connect(_on_listen_plan)
	$Root/GameRow/Gameplan/Body/SavePreset.pressed.connect(_on_save_preset)
	$Root/GameRow/Gameplan/Body/LoadPreset.pressed.connect(_on_load_preset)
	_populate_rules()
	_populate_presets()
	_populate_deck()
	_refresh_plan()

func _populate_rules() -> void:
	$Root/GameRow/Rules/Body/Ruleset.clear()
	for id in _ruleset_ids:
		$Root/GameRow/Rules/Body/Ruleset.add_item(id.to_upper())
	$Root/GameRow/Rules/Body/Ruleset.select(0)
	$Root/GameRow/Rules/Body/GiToggle.button_pressed = true

func _populate_presets() -> void:
	var option: OptionButton = $Root/GameRow/Gameplan/Body/Preset
	option.clear()
	for preset_id in ["ofensivo", "defensivo", "adaptativo"]:
		option.add_item(preset_id.to_upper())
		option.set_item_metadata(option.item_count - 1, preset_id)

func _populate_deck() -> void:
	var list: ItemList = $Root/GameRow/Gameplan/Body/DeckList
	list.clear()
	var unlocked: Array = DeckManager.get_unlocked_technique_ids()
	var defaults: Array = DeckManager.get_v2_preset("adaptativo")
	if defaults.is_empty():
		defaults = DeckManager.get_default_v2_selection()
	for technique_id_value in unlocked:
		var technique_id := str(technique_id_value)
		var info: Dictionary = DataRegistry.get_technique(technique_id)
		var label := str(info.get("nome", info.get("name", technique_id))).replace("_", " ")
		list.add_item(label)
		var index := list.item_count - 1
		list.set_item_metadata(index, technique_id)
		if defaults.has(technique_id):
			list.select(index, false)

func _selected_techniques() -> Array:
	var output: Array[String] = []
	var list: ItemList = $Root/GameRow/Gameplan/Body/DeckList
	for index in list.get_selected_items():
		output.append(str(list.get_item_metadata(index)))
	return output

func _refresh_plan() -> Dictionary:
	var selection := _selected_techniques()
	if selection.size() < 6 or selection.size() > 8:
		_set_status("Escolha entre 6 e 8 tecnicas. Atual: %d." % selection.size())
		return {"ok": false, "reason": "deck_size_invalid"}
	var ruleset: String = str(_ruleset_ids[$Root/GameRow/Rules/Body/Ruleset.selected])
	var gi: bool = bool($Root/GameRow/Rules/Body/GiToggle.button_pressed)
	var result: Dictionary = CombatManager.prepare_combat_v2(
		opponent_id,
		arena_id,
		ruleset,
		gi,
		selection
	)
	if not bool(result.get("ok", false)):
		_set_status("Plano bloqueado: %s" % str(result.get("reason", result.get("error", "erro"))))
		return result
	_current_plan = result.get("plan", {}).duplicate(true)
	_render_plan()
	return result

func _render_plan() -> void:
	var scouting: Dictionary = _current_plan.get("scouting", {})
	var counters: Array = scouting.get("counters_known", [])
	var weaknesses: Array = scouting.get("weaknesses", [])
	$Root/GameRow/Scouting/Body.text = (
		"%s\nEstilo: %s\nFacção: %s\nCounters vistos: %s\nFraquezas: %s\nClipes vistos: %d"
		% [
			str(scouting.get("display_name", opponent_id)),
			str(scouting.get("style", "desconhecido")),
			str(scouting.get("faction", "—")),
			", ".join(counters) if not counters.is_empty() else "nenhum",
			", ".join(weaknesses) if not weaknesses.is_empty() else "não confirmadas",
			int(scouting.get("clips_watched", 0))
		]
	)
	var hype := WorldState.get_reputation("hype") if has_node("/root/WorldState") else 0.0
	$Root/GameRow/Stats/Body.text = "Faixa: %s\nEnergia: %d\nHype: %d\nVirada do Cria: disponível" % [
		str(WorldState.belt).capitalize(),
		int(WorldState.energy),
		int(hype)
	]
	$Root/GameRow/Rules/Body/Arena.text = "Arena: %s" % str(_current_plan.get("arena_id", arena_id)).replace("_", " ").capitalize()
	var corner: Dictionary = _current_plan.get("corner_preview", {})
	$Root/TinkerPanel/Body/Advice.text = str(corner.get("reason", "Monta teu jogo. Não entrega teu padrão de graça."))
	_set_status("Plano pronto: %d técnicas • %s • %s" % [
		_current_plan.get("deck", []).size(),
		str(_current_plan.get("ruleset", "ibjjf")).to_upper(),
		"GI" if bool(_current_plan.get("gi", true)) else "NO-GI"
	])

func _on_listen_plan() -> void:
	var result := _refresh_plan()
	if bool(result.get("ok", false)):
		var corner: Dictionary = _current_plan.get("corner_preview", {})
		$Root/TinkerPanel/Body/Advice.text = str(corner.get("reason", "Joga simples e lê a resposta."))

func _on_save_preset() -> void:
	var selection := _selected_techniques()
	var option: OptionButton = $Root/GameRow/Gameplan/Body/Preset
	var preset_id := str(option.get_item_metadata(option.selected))
	var result: Dictionary = DeckManager.save_v2_preset(preset_id, selection)
	_set_status("Preset %s salvo." % preset_id if bool(result.get("ok", false)) else "Falha no preset: %s" % str(result.get("error", "")))
	if bool(result.get("ok", false)):
		SaveManager.save_game(1)

func _on_load_preset() -> void:
	var option: OptionButton = $Root/GameRow/Gameplan/Body/Preset
	var preset_id := str(option.get_item_metadata(option.selected))
	var preset: Array = DeckManager.get_v2_preset(preset_id)
	if preset.is_empty():
		_set_status("Preset %s ainda vazio." % preset_id)
		return
	var list: ItemList = $Root/GameRow/Gameplan/Body/DeckList
	list.deselect_all()
	for index in range(list.item_count):
		if preset.has(str(list.get_item_metadata(index))):
			list.select(index, false)
	_refresh_plan()

func _on_confirm() -> void:
	var result := _refresh_plan()
	if not bool(result.get("ok", false)):
		return
	var error := get_tree().change_scene_to_file(COMBAT_SCENE)
	if error != OK:
		_set_status("Falha ao abrir a luta: %s" % error_string(error))

func _on_back() -> void:
	CombatManager.clear_combat_v2_plan()
	get_tree().change_scene_to_file(TERREIRO_SCENE)

func _set_status(message: String) -> void:
	$Root/Footer/Status.text = message
