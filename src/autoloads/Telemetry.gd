extends Node
var sessions: Array[Dictionary] = []
func _ready() -> void:
	if not SignalBus.combat_finished.is_connected(_on_combat_finished): SignalBus.combat_finished.connect(_on_combat_finished)
func _on_combat_finished(result: Dictionary) -> void:
	sessions.append({"event": "combat_finished", "winner": str(result.get("winner", "")), "crash": false})
