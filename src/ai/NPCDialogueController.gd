extends Node
class_name NPCDialogueController

signal response_received(text: String, source: String)
signal response_failed(reason: String)

@export var npc_id: String = "mestre_dende"
@export var default_category: String = "default"

var _active_request_id: int = -1

func _ready() -> void:
	if not LocalAIManager.dialogue_ready.is_connected(_on_dialogue_ready):
		LocalAIManager.dialogue_ready.connect(_on_dialogue_ready)
	if not LocalAIManager.dialogue_failed.is_connected(_on_dialogue_failed):
		LocalAIManager.dialogue_failed.connect(_on_dialogue_failed)

func ask(user_message: String, context: Dictionary = {}) -> int:
	var request_context := context.duplicate(true)
	if not request_context.has("category"):
		request_context["category"] = default_category
	_active_request_id = LocalAIManager.request_dialogue(npc_id, user_message, request_context)
	return _active_request_id

func clear_history() -> void:
	LocalAIManager.clear_history(npc_id)

func get_immediate_fallback(category: String = "") -> String:
	var resolved_category := category if category != "" else default_category
	return LocalAIManager.get_fallback_dialogue(npc_id, resolved_category)

func _on_dialogue_ready(request_id: int, response_npc_id: String, text: String, source: String) -> void:
	if request_id != _active_request_id or response_npc_id != npc_id:
		return
	_active_request_id = -1
	response_received.emit(text, source)

func _on_dialogue_failed(request_id: int, response_npc_id: String, reason: String) -> void:
	if request_id != _active_request_id or response_npc_id != npc_id:
		return
	response_failed.emit(reason)
