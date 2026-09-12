extends SceneTree

const AdapterScript = preload("res://src/combat/BJJIdAdapterV1.gd")
var failures: Array[String] = []
var checks := 0

func _init() -> void:
	var adapter = AdapterScript.new()
	var status: Dictionary = adapter.initialize()
	_check(bool(status.get("ok", false)), "adapter initializes")

	var baiana: Dictionary = adapter.normalize_technique("baiana", "legacy")
	_check(bool(baiana.get("ok", false)), "legacy baiana maps")
	_check(str(baiana.get("canonical", "")) == "t001", "baiana -> t001")

	var canonical: Dictionary = adapter.normalize_technique("t005", "canonical")
	_check(bool(canonical.get("ok", false)), "canonical technique accepted")
	_check(str(canonical.get("canonical", "")) == "t005", "t005 stays t005")

	var side: Dictionary = adapter.normalize_position("PLAYER_TOP_SIDE", "legacy")
	_check(bool(side.get("ok", false)), "legacy side maps")
	_check(str(side.get("canonical", "")) == "side_control", "top side -> side_control")

	var ambiguous: Dictionary = adapter.normalize_position("PLAYER_TOP_GUARD", "legacy")
	_check(not bool(ambiguous.get("ok", true)), "ambiguous guard fails closed")

	var unknown: Dictionary = adapter.normalize_technique("invented_move", "auto")
	_check(not bool(unknown.get("ok", true)), "unknown technique fails closed")

	print("BJJ_ID_ADAPTER_SMOKE checks=%d failures=%d" % [checks, failures.size()])
	for failure in failures:
		push_error(failure)
	quit(0 if failures.is_empty() else 1)

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
