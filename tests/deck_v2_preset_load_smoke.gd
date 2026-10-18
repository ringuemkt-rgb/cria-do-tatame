extends SceneTree

var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("[DeckPresetLoad] " + message)

func _run() -> void:
	var deck := root.get_node("DeckManager")
	var original: Dictionary = deck.to_dict().duplicate(true)
	var unlocked: Array = deck.get_unlocked_technique_ids()
	var six: Array = unlocked.slice(0, 6)
	_check(six.size() == 6, "fixture has six unlocked techniques")
	var duplicate: Array = six.duplicate()
	duplicate[5] = duplicate[0]
	var locked: Array = six.duplicate()
	locked[5] = "unknown_locked_technique"
	var invalid_values: Array = [null, 42, "not_an_array", {"bad": true}, duplicate, six.slice(0, 5), six + six, locked]
	for invalid in invalid_values:
		var saved: Dictionary = original.duplicate(true)
		saved["v2_presets"] = {"ofensivo": six.duplicate(), "adaptativo": invalid, "unknown_preset": six.duplicate()}
		var input_before: Dictionary = saved.duplicate(true)
		deck.load_from_dict(saved)
		_check(deck.get_v2_preset("ofensivo") == six, "valid sibling preset survives load")
		_check(not deck.v2_presets.has("adaptativo"), "malformed, duplicate, short or locked saved preset is discarded")
		_check(not deck.v2_presets.has("unknown_preset"), "unknown preset ID is not imported")
		_check(deck.get_collection().size() == original["cards"].size(), "bad preset does not erase collection")
		_check(saved == input_before, "load does not mutate caller save data")
	var clean: Dictionary = original.duplicate(true)
	clean["v2_presets"] = {"adaptativo": six.duplicate()}
	deck.load_from_dict(clean)
	_check(deck.get_v2_preset("adaptativo") == six, "valid persisted preset round trips")
	var copy: Array = deck.get_v2_preset("adaptativo")
	copy[0] = "external_mutation"
	_check(deck.get_v2_preset("adaptativo") == six, "preset read is detached from stored state")
	deck.load_from_dict(original)
	print("[DeckPresetLoad] checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
