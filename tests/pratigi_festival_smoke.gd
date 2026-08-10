extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var config_file := FileAccess.open("res://data/arenas/pratigi_festival_v01.json", FileAccess.READ)
	_check(config_file != null, "festival config opens")
	if config_file == null:
		_finish()
		return
	var config = JSON.parse_string(config_file.get_as_text())
	config_file.close()
	_check(typeof(config) == TYPE_DICTIONARY, "festival config parses")

	var director_script = load("res://src/combat/arena/ClandestineEventDirector.gd")
	_check(director_script != null, "event director script loads")
	var director: Node = director_script.new()
	root.add_child(director)
	director.call("configure", config)
	var bet: Dictionary = director.call("place_bet", 50, 100)
	_check(bool(bet.get("ok", false)), "internal-currency bet is accepted")
	_check(int(bet.get("wallet_delta", 0)) == -50, "stake is debited once")
	var started: Dictionary = director.call("start_event")
	_check(bool(started.get("ok", false)), "event starts")
	director.call("register_public_exposure", 50.0, "smoke_warning")
	_check(str(director.call("get_state_name")) == "warning", "warning threshold is reached")
	director.call("force_interdiction", "smoke_interdiction")
	_check(str(director.call("get_state_name")) == "interdicted", "interdiction state is reached")
	var settlement: Dictionary = director.call("settle", {"interrupted": true}, "ruan_macacao")
	_check(str(settlement.get("status", "")) == "interdicted", "interdicted bet does not pay")
	_check(int(settlement.get("wallet_delta", -1)) == 0, "interdicted event has zero payout")

	var packed_scene = load("res://scenes/combat/arenas/PratigiFestivalArena.tscn")
	_check(packed_scene != null, "Pratigi festival scene parses")
	director.queue_free()
	_finish()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("[OK] ", label)
	else:
		failures.append(label)
		push_error("[FAIL] " + label)


func _finish() -> void:
	print("Pratigi festival smoke: %d failure(s)" % failures.size())
	quit(0 if failures.is_empty() else 1)
