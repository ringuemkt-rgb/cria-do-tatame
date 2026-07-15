extends Node
class_name JsonDataRegistry

# Registry instanciavel usado por ferramentas e testes isolados.
# O singleton global DataRegistry permanece em src/autoloads/DataRegistry.gd.

var cache: Dictionary = {}

func load_json(path: String, fallback: Dictionary = {}) -> Dictionary:
	if cache.has(path):
		return cache[path]
	if not FileAccess.file_exists(path):
		push_warning("JsonDataRegistry missing file: " + path)
		cache[path] = fallback.duplicate(true)
		return cache[path]
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("JsonDataRegistry failed to open: " + path)
		cache[path] = fallback.duplicate(true)
		return cache[path]
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("JsonDataRegistry invalid JSON: " + path)
		cache[path] = fallback.duplicate(true)
		return cache[path]
	cache[path] = parsed
	return parsed

func clear_cache() -> void:
	cache.clear()

func get_technique_catalog() -> Dictionary:
	return load_json("res://data/techniques/technique_catalog_v05.json", {"techniques": []})

func get_combat_states() -> Dictionary:
	return load_json("res://data/combat/combat_states_v05.json", {"states": []})
