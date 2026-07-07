extends Node

var confianca := 70.0
var presenca := 100.0
var limite := 3
var ferida := 0.0
var cumplicidade := 0.0
var estado := "IRMANDADE"

func reset() -> void:
	confianca = 70.0
	presenca = 100.0
	limite = 3
	ferida = 0.0
	cumplicidade = 0.0
	_update_state()

func apply_choice(choice_id: String) -> Dictionary:
	var effects := _effects_for(choice_id)
	_apply_effects(effects)
	_update_state()
	return to_dict()

func _effects_for(choice_id: String) -> Dictionary:
	match choice_id:
		"assumir_erro_publico": return {"confianca": 10, "ferida": -10, "honra": 8, "legado": 4}
		"culpar_midia": return {"confianca": -12, "ferida": 12, "hype": 5, "sombra": 4}
		"aceitar_luta_suja": return {"confianca": -18, "limite": -1, "ferida": 18, "sombra": 12, "money": 500}
		"proteger_terreiro": return {"confianca": 8, "legado": 10, "honra": 5}
		"usar_tinker_como_escudo": return {"confianca": -25, "ferida": 30, "cumplicidade": 20, "limite": -1}
		"pedir_perdao_sem_desculpa": return {"confianca": 18, "ferida": -20, "honra": 8}
		"mentir_para_tinker": return {"confianca": -20, "ferida": 20, "limite": -1}
		"recusar_contrato_cassio": return {"confianca": 15, "honra": 10, "legado": 8, "money": -100}
		"assinar_contrato_cassio": return {"confianca": -35, "presenca": -60, "ferida": 45, "limite": -2, "hype": 20, "sombra": 25, "money": 2000}
		"negociar_sem_tinker": return {"confianca": -20, "ferida": 25, "limite": -1, "hype": 10, "sombra": 12}
		_: return {}

func _apply_effects(effects: Dictionary) -> void:
	confianca = clamp(confianca + float(effects.get("confianca", 0)), 0.0, 100.0)
	presenca = clamp(presenca + float(effects.get("presenca", 0)), 0.0, 100.0)
	ferida = clamp(ferida + float(effects.get("ferida", 0)), 0.0, 100.0)
	cumplicidade = clamp(cumplicidade + float(effects.get("cumplicidade", 0)), 0.0, 100.0)
	limite = clamp(limite + int(effects.get("limite", 0)), 0, 3)
	if effects.has("money"):
		WorldState.money += int(effects["money"])
	for axis in ["honra", "hype", "sombra", "legado", "moral"]:
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
	if confianca >= 80.0 and ferida < 20.0 and WorldState.get_reputation("honra") >= 70.0 and WorldState.get_reputation("legado") >= 70.0:
		estado = "LEGADO"
	if old_state != estado:
		SignalBus.emit_system_message("TinkerBond", "Estado do vinculo: " + estado)

func is_tinker_present() -> bool:
	return estado in ["IRMANDADE", "ALERTA", "RACHADURA", "RETORNO_DIFICIL", "LEGADO"] and presenca > 0.0

func to_dict() -> Dictionary:
	return {"confianca": confianca, "presenca": presenca, "limite": limite, "ferida": ferida, "cumplicidade": cumplicidade, "estado": estado}

func load_from_dict(data: Dictionary) -> void:
	confianca = float(data.get("confianca", 70.0))
	presenca = float(data.get("presenca", 100.0))
	limite = int(data.get("limite", 3))
	ferida = float(data.get("ferida", 0.0))
	cumplicidade = float(data.get("cumplicidade", 0.0))
	estado = str(data.get("estado", "IRMANDADE"))
