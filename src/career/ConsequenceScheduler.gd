extends Node
class_name ConsequenceScheduler

var save_manager: SaveManager
var state: Dictionary = {}

func setup(p_save_manager: SaveManager) -> void:
	save_manager = p_save_manager
	state = save_manager.load_json("pending_events.json", {"events": []})

func save() -> void:
	save_manager.save_json("pending_events.json", state)

func schedule_event(event_id: String, due_week: int, payload: Dictionary = {}) -> void:
	var events: Array = state.get("events", [])
	events.append({
		"id": event_id,
		"due_week": due_week,
		"payload": payload,
		"status": "pending"
	})
	state["events"] = events
	save()

func collect_due(current_week: int) -> Array:
	var due: Array = []
	var events: Array = state.get("events", [])
	for event in events:
		if event.get("status", "pending") == "pending" and int(event.get("due_week", 0)) <= current_week:
			due.append(event)
			event["status"] = "done"
	state["events"] = events
	save()
	return due
