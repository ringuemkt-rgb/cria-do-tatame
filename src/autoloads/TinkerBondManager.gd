extends Node

signal bond_state_changed(new_state)
signal bond_event_triggered(event_id)

var confianca := 70.0
var presenca := 100.0
var limite := 3
var ferida := 0.0
var cumplicidade := 0.0
var estado := "IRMANDADE"
var historico := []

func _ready() -> void:
	load_defaults_from_registry()

func load_defaults_from_registry() -> void:
	var data = DataRegistry.tinker_bond.get("tinker_bond", {})
	if data.is_empty():
		return
	confianca = float(data.get("confianca", confianca))
	presenca = float(data.get("presenca", presenca))
	limite = int(data.get("limite", limite))
	ferida = float(data.get("ferida", ferida))
	cumplicidade = float(data.get("cumplicidade", cumplicidade))
	estado = str(data.get("estado", estado))
	historico = data.get("historico", [])
	_update_state()

func reset() -> void:
	confianca = 70.0
	presenca = 100.0
	limite = 3
	ferida = 0.0
	cumplicidade = 0.0
	historico = []
	_update_state()

func apply_choice(choice_id: String) -> Dictionary:
	return apply_event(choice_id)

func apply_event(event_id: String) -> Dictionary:
	var effects := _effects_for(event_id)
	if effects.is_empty():
		push_warning("[TinkerBondManager] Evento sem efeito: " + event_id)
		return to_dict()
	_apply_effects(effects)
	historico.append({"event_id": event_id, "timestamp": Time.get_datetime_string_from_system(), "effects": effects})
	_update_state()
	bond_event_triggered.emit(event_id)
	return to_dict()

func _effects_for(choice_id: String) -> Dictionary:
	var registry_events = DataRegistry.tinker_bond.get("eventos_alteracao", [])
	for event in registry_events:
		if str(event.get("id", "")) == choice_id:
			return event.get("efeitos", {})
	match choice_id:
		"assumir_erro_publico": return {"confianca": 15, "ferida": -10, "honra": 10, "legado": 4}
		"culpar_midia": return {"confianca": -20, "ferida": 10, "hype": 10, "sombra": 4}
		"aceitar_luta_suja": return {"confianca": -10, "limite": -1, "sombra": 15}
		"proteger_terreiro": return {"confianca": 20, "legado": 15, "honra": 5, "raiz": 10}
		"usar_tinker_escudo", "usar_tinker_como_escudo": return {"confianca": -30, "ferida": 20, "limite": -1}
		"pedir_perdao_sem_desculpa": return {"confianca": 25, "presenca": 40, "ferida": -20, "honra": 8}
		"mentir_para_tinker": return {"confianca": -40, "ferida": 25, "limite": -1}
		"recusar_contrato_cassio": return {"confianca": 15, "honra": 15, "legado": 10, "raiz": 8}
		"assinar_contrato_cassio": return {"confianca": -35, "presenca": -80, "ferida": 50, "limite": -2, "hype": 20, "sombra": 30, "money": 5000}
		"negociar_sem_tinker": return {"confianca": -20, "ferida": 25, "limite": -1, "hype": 10, "sombra": 15, "money": 2000}
		_: return {}

func _apply_effects(effects: Dictionary) -> void:
	confianca = clamp(confianca + float(effects.get("confianca", 0)), 0.0, 100.0)
	presenca = clamp(presenca + float(effects.get("presenca", 0)), 0.0, 100.0)
	ferida = clamp(ferida + float(effects.get("ferida", 0)), 0.0, 100.0)
	cumplicidade = clamp(cumplicidade + float(effects.get("cumplicidade", 0)), 0.0, 100.0)
	limite = clamp(limite + int(effects.get("limite", 0)), 0, 3)
	if effects.has("money"):
		WorldState.money += int(effects["money"])
	for axis in ["honra", "hype", "sombra", "legado", "moral", "raiz"]:
		if effects.has(axis):
			WorldState.modify_reputation(axis, float(effects[axis]))

func _update_state() -> void:
	var old_state := estado
	if limite <= 0 or ferida >= 80.0:
		estado = "RUPTURA"
	elif ferida >= 50.0 and confianca >= 45.0 and limite >= 1:
		estado = "RETORNO_DIFICIL"
	elif confianca < 35.0 or presenca < 50.0:
		estado = "AFASTAMENTO"
	elif confianca >= 35.0 and ferida >= 35.0:
		estado = "RACHADURA"
	elif confianca >= 50.0 and ferida < 35.0:
		estado = "ALERTA"
	elif confianca >= 80.0 and ferida < 20.0:
		estado = "IRMANDADE"
	if confianca >= 90.0 and ferida < 10.0 and WorldState.get_reputation("honra") >= 70.0 and WorldState.get_reputation("legado") >= 70.0:
		estado = "LEGADO"
	if old_state != estado:
		SignalBus.emit_system_message("TinkerBond", "Estado do vinculo: " + estado)
		bond_state_changed.emit(estado)

func get_state() -> String:
	return estado

func get_confianca() -> float:
	return confianca

func is_tinker_present() -> bool:
	return estado in ["IRMANDADE", "ALERTA", "RACHADURA", "RETORNO_DIFICIL", "LEGADO"] and presenca > 0.0

func can_unlock_final_raiz() -> bool:
	return estado == "LEGADO" and WorldState.get_reputation("honra") >= 70.0 and WorldState.get_reputation("legado") >= 70.0

func to_dict() -> Dictionary:
	return {"confianca": confianca, "presenca": presenca, "limite": limite, "ferida": ferida, "cumplicidade": cumplicidade, "estado": estado, "historico": historico}

func load_from_dict(data: Dictionary) -> void:
	confianca = float(data.get("confianca", 70.0))
	presenca = float(data.get("presenca", 100.0))
	limite = int(data.get("limite", 3))
	ferida = float(data.get("ferida", 0.0))
	cumplicidade = float(data.get("cumplicidade", 0.0))
	estado = str(data.get("estado", "IRMANDADE"))
	historico = data.get("historico", [])
	_update_state()
