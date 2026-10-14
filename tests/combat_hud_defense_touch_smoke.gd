extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("[CombatHudDefenseTouch] PENDING CI")
	quit(1)
