extends Node

func get_axis_value(axis) -> float:
	return float(WorldState.reputation.get(str(axis), 0.0))

func get_dominant_axis():
	var max_axis = "honra"
	var max_value := -1.0
	for axis in ["honra", "hype", "sombra", "legado"]:
		var value := get_axis_value(axis)
		if value > max_value:
			max_value = value
			max_axis = axis
	return max_axis

func add(axis, amount, reason := ""):
	var key := str(axis)
	if not WorldState.reputation.has(key):
		WorldState.reputation[key] = 0.0
	WorldState.reputation[key] = clamp(float(WorldState.reputation[key]) + float(amount), 0.0, 100.0)
	SignalBus.reputation_changed.emit(key, float(amount), float(WorldState.reputation[key]))
	SignalBus.reputation_delta.emit(key, float(amount))
	if check_crisis_trigger() != "":
		SignalBus.crisis_triggered.emit(check_crisis_trigger())

func apply_result(result: Dictionary) -> void:
	var changes = result.get("reputation", {})
	for axis in changes.keys():
		add(axis, changes[axis], result.get("reason", "result"))

func check_crisis_trigger():
	if get_axis_value("honra") < 20.0:
		return "crise_honra_baixa"
	if get_axis_value("hype") > 85.0 and get_axis_value("honra") < 40.0:
		return "crise_hype_toxico"
	if get_axis_value("sombra") > 70.0:
		return "crise_investigacao"
	return ""

func apply_clean_win():
	add("honra", 2, "clean_win")
	add("legado", 1, "clean_win")

func apply_hype_choice():
	add("hype", 2, "hype_choice")
	add("sombra", 1, "hype_choice")
	add("honra", -1, "hype_choice")

func apply_help_rival():
	add("honra", 2, "help_rival")
	add("legado", 2, "help_rival")
	add("moral", 1, "help_rival")
