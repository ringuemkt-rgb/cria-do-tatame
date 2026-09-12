extends SceneTree

var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _assert(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("[WorldMapLifeSmoke] " + message)

func _run() -> void:
	await process_frame
	var scene := load("res://scenes/world/WorldMapScreen.tscn") as PackedScene
	_assert(scene != null, "WorldMapScreen não carregou")
	if scene != null:
		var screen := scene.instantiate()
		root.add_child(screen)
		await process_frame
		_assert(screen.get_map_page_count() == 10, "Mapa não expõe as dez páginas canônicas")
		_assert(screen.get_map_node_count() == 40, "Mapa não expõe os quarenta nós canônicos")
		var contract: Dictionary = screen.get_map_visual_contract()
		_assert(contract.get("shipping", true) == false, "Referências visuais foram promovidas sem QA humano")
		_assert(str(contract.get("authority", {}).get("travel_state", "")) == "WorldMapManager", "Mapa criou autoridade concorrente de viagem")
		var candidate_assets: Array = contract.get("candidate_assets", [])
		_assert(candidate_assets.size() == 1, "Base visual candidata do Baixo Sul não foi registrada")
		if not candidate_assets.is_empty():
			_assert(ResourceLoader.exists(str(candidate_assets[0].get("path", ""))), "Base visual candidata não é carregável pelo Godot")
		var layer: Node = screen.get_node_or_null("WorldMapLifeLayer")
		_assert(layer != null and layer.open_page("02"), "Página de Ituberá não abre no runtime")
		_assert(str(layer.get("active_page_id")) == "02", "Página ativa não foi atualizada")
		screen.queue_free()
	if failures.is_empty():
		print("[WorldMapLifeSmoke] PASS — %d verificações" % checks)
		quit(0)
	else:
		print("[WorldMapLifeSmoke] FAIL — %d falhas em %d verificações" % [failures.size(), checks])
		quit(1)
