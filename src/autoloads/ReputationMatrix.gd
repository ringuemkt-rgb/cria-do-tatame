extends Node

func apply_result(result: Dictionary) -> void:
	var changes = result.get("reputation", {})
	for axis in changes.keys():
		add(axis, int(changes[axis]), result.get("reason", "result"))

func add(axis: String, amount: int, reason := ""):
	if not WorldState.reputation.has(axis):
		WorldState.reputation[axis] = 0
	WorldState.reputation[axis] += amount
	SignalBus.reputation_changed.emit(axis, WorldState.reputation[axis], reason)

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
