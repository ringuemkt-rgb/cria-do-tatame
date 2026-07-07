extends Node
class_name RivalMemoryManager

var save_manager: SaveManager
var rivals: Dictionary = {}

func setup(p_save_manager: SaveManager) -> void:
	save_manager = p_save_manager
	rivals = save_manager.load_json("rivals.json", {"rivals": {}})

func save() -> void:
	save_manager.save_json("rivals.json", rivals)

func ensure_rival(rival_id: String) -> Dictionary:
	var table: Dictionary = rivals.get("rivals", {})
	if not table.has(rival_id):
		table[rival_id] = {
			"respect": 0,
			"pressure": 0,
			"last_match": "none",
			"seen_patterns": {},
			"notes": []
		}
	rivals["rivals"] = table
	return table[rival_id]

func record_pattern(rival_id: String, technique_id: String) -> void:
	var data := ensure_rival(rival_id)
	var patterns: Dictionary = data.get("seen_patterns", {})
	patterns[technique_id] = int(patterns.get(technique_id, 0)) + 1
	data["seen_patterns"] = patterns
	rivals["rivals"][rival_id] = data
	save()

func get_counter_bias(rival_id: String, technique_id: String) -> float:
	var data := ensure_rival(rival_id)
	var count := int(data.get("seen_patterns", {}).get(technique_id, 0))
	return clamp(float(count) * 0.08, 0.0, 0.4)

func add_note(rival_id: String, note: String) -> void:
	var data := ensure_rival(rival_id)
	var notes: Array = data.get("notes", [])
	notes.append(note)
	data["notes"] = notes
	rivals["rivals"][rival_id] = data
	save()
