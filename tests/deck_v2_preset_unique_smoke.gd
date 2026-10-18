extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var deck := root.get_node_or_null("DeckManager")
	if deck == null:
		_fail("DeckManager autoload missing")
		return
	var unlocked: Array[String] = deck.get_unlocked_technique_ids()
	if unlocked.size() < 6:
		_fail("fixture requires six unlocked techniques")
		return
	var six: Array = []
	for i in range(6):
		six.append(unlocked[i])
	var saved: Dictionary = deck.save_v2_preset("adaptativo", six)
	if not bool(saved.get("ok", false)):
		_fail("valid unique preset rejected: %s" % str(saved))
		return
	var before: Array = deck.get_v2_preset("adaptativo")
	var duplicate: Array = six.duplicate()
	duplicate[5] = duplicate[0]
	var rejected: Dictionary = deck.save_v2_preset("adaptativo", duplicate)
	if bool(rejected.get("ok", true)) or str(rejected.get("error", "")) != "duplicate_technique":
		_fail("duplicate technique was not rejected")
		return
	if deck.get_v2_preset("adaptativo") != before:
		_fail("rejected preset mutated the previous configuration")
		return
	print("PASS: unique preset accepted; duplicate rejected transactionally")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
