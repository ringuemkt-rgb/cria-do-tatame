extends SceneTree

const Living = preload("res://src/world/TerreiroLivingHubV1.gd")
var checks := 0
var failures := 0

func _init() -> void:
	var hub = Living.new()
	var snapshot := {
		"time_block": "tarde",
		"current_weather": "chuva_passageira",
		"active_events": [{"id":"chuva_no_treino"}],
		"npc_states": {
			"mestre_dende": {"hub":"terreiro_da_luta","activity":"treino_tecnico","available":true},
			"tinker_bell": {"hub":"terreiro_da_luta","activity":"analisar_treino","available":true},
			"davi_relampago": {"hub":"arena_do_dique","activity":"sparring","available":true}
		}
	}
	var composed: Dictionary = hub.compose(snapshot)
	_expect(str(composed.get("time_label")) == "TARDE", "time label")
	_expect(str(composed.get("weather_label")) == "CHUVA PASSAGEIRA", "weather label")
	_expect(composed.get("present_npcs", []).size() == 2, "only NPCs physically at Terreiro are present")
	_expect(hub.presence_text(composed).contains("Mestre Dendê"), "Dende presence")
	_expect(hub.presence_text(composed).contains("Tinker Bell"), "Tinker presence")
	_expect(not hub.presence_text(composed).contains("Davi"), "Davi absent")
	_expect(composed.get("ambience_layers", []).has("chuva_telhas"), "weather ambience")
	_expect(composed.get("ambience_layers", []).size() <= 4, "ambience cap")
	print("Terreiro living hub smoke: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("[TerreiroLivingHub] FAIL: " + label)
