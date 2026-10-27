extends "res://scenes/world/WorldMapScreen.gd"

# UI-only test double: never charges money, writes save slot 1 or changes the world.
var travel_calls: Array[String] = []
var should_succeed := false

func _perform_travel(hub_id: String) -> Dictionary:
	travel_calls.append(hub_id)
	if not should_succeed:
		return {"ok": false, "message": "Viagem recusada pelo teste."}
	return {
		"ok": true,
		"message": "Viagem confirmada pelo teste.",
		"hub": {"entry_scene": "res://scenes/hubs/ZambiapungaHub.tscn"}
	}
