extends Node

signal dialogue_ready(request_id: int, npc_id: String, text: String, source: String)
signal dialogue_failed(request_id: int, npc_id: String, reason: String)

enum BackendType { DISABLED, OLLAMA_HTTP, OPENAI_COMPATIBLE }

const LocalAIReadOnlyTools := preload("res://src/ai/LocalAIReadOnlyTools.gd")

var backend_id: String = "disabled"
var backend_type: int = BackendType.DISABLED
var base_url: String = ""
var chat_path: String = ""
var model_name: String = ""
var timeout_seconds: float = 8.0
var max_tokens: int = 96
var temperature: float = 0.55
var top_p: float = 0.85
var num_ctx: int = 0
var supports_tools: bool = false
var max_tool_rounds: int = 0
var max_response_chars: int = 420
var max_history_messages: int = 6

var _http: HTTPRequest
var _queue: Array[Dictionary] = []
var _active: Dictionary = {}
var _next_request_id: int = 1
var _history_by_npc: Dictionary = {}
var _read_only_tools = LocalAIReadOnlyTools.new()

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.name = "LocalAIHTTPRequest"
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)
	call_deferred("_initialize_from_registry")

func _initialize_from_registry() -> void:
	var policy: Dictionary = DataRegistry.local_ai_config.get("runtime_policy", {})
	max_response_chars = int(policy.get("max_response_chars", 420))
	max_history_messages = int(policy.get("max_history_messages", 6))
	# O APK sempre inicia em modo offline seguro. Rede ou servidor local so entram
	# quando um menu de desenvolvimento chama configure_backend explicitamente.
	configure_backend("disabled")

func configure_backend(p_backend_id: String, override_url: String = "") -> bool:
	var backend_config: Dictionary = DataRegistry.local_ai_config.get("backends", {}).get(p_backend_id, {})
	if backend_config.is_empty():
		return false
	backend_id = p_backend_id
	var type_name := str(backend_config.get("type", "disabled"))
	match type_name:
		"ollama_http": backend_type = BackendType.OLLAMA_HTTP
		"openai_compatible": backend_type = BackendType.OPENAI_COMPATIBLE
		_: backend_type = BackendType.DISABLED
	model_name = str(backend_config.get("model", ""))
	timeout_seconds = float(backend_config.get("timeout_seconds", 8.0))
	max_tokens = int(backend_config.get("max_tokens", 96))
	temperature = float(backend_config.get("temperature", 0.55))
	top_p = float(backend_config.get("top_p", 0.85))
	num_ctx = maxi(0, int(backend_config.get("num_ctx", 0)))
	supports_tools = bool(backend_config.get("supports_tools", false))
	max_tool_rounds = clampi(int(backend_config.get("max_tool_rounds", 0)), 0, 4)
	chat_path = str(backend_config.get("chat_path", ""))
	if override_url != "":
		base_url = override_url.trim_suffix("/")
	elif backend_type == BackendType.OLLAMA_HTTP:
		if OS.get_name() == "Android":
			base_url = str(backend_config.get("android_emulator_url", "")).trim_suffix("/")
		else:
			base_url = str(backend_config.get("desktop_url", "")).trim_suffix("/")
	else:
		base_url = str(backend_config.get("base_url", "")).trim_suffix("/")
	_http.timeout = timeout_seconds
	return true

func disable_backend() -> void:
	configure_backend("disabled")

func is_network_backend_enabled() -> bool:
	return backend_type != BackendType.DISABLED and base_url != ""

func request_dialogue(npc_id: String, user_message: String, context: Dictionary = {}) -> int:
	var request_id := _next_request_id
	_next_request_id += 1
	var category := str(context.get("category", "default"))
	var clean_message := _sanitize_user_message(user_message)
	var fallback := get_fallback_dialogue(npc_id, category, clean_message)
	var item: Dictionary = {
		"request_id": request_id,
		"npc_id": npc_id,
		"user_message": clean_message,
		"context": context.duplicate(true),
		"fallback": fallback,
		"messages": [],
		"tool_rounds": 0
	}
	if not is_network_backend_enabled():
		call_deferred("_emit_fallback", item, "fallback_offline")
		return request_id
	_queue.append(item)
	_pump_queue()
	return request_id

func _pump_queue() -> void:
	if not _active.is_empty() or _queue.is_empty():
		return
	_active = _queue.pop_front()
	_active["messages"] = _build_messages(_active)
	_active["tool_rounds"] = 0
	_dispatch_active_request()

func _build_messages(item: Dictionary) -> Array:
	var npc_id := str(item.get("npc_id", "npc"))
	var messages: Array = [
		{"role": "system", "content": _system_prompt_for(npc_id, item.get("context", {}))}
	]
	for historic_message in _history_by_npc.get(npc_id, []):
		messages.append(historic_message)
	messages.append({"role": "user", "content": str(item.get("user_message", ""))})
	return messages

func _dispatch_active_request() -> void:
	if _active.is_empty():
		return
	var payload := _build_payload(_active)
	var url := _build_chat_url()
	if url == "":
		_finish_with_fallback("backend_url_empty")
		return
	var headers := PackedStringArray(["Content-Type: application/json"])
	var error := _http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if error != OK:
		_finish_with_fallback("request_start_failed_%s" % error)

func _build_chat_url() -> String:
	match backend_type:
		BackendType.OLLAMA_HTTP:
			return base_url + "/api/chat"
		BackendType.OPENAI_COMPATIBLE:
			return base_url + (chat_path if chat_path != "" else "/v1/chat/completions")
	return ""

func _build_payload(item: Dictionary) -> Dictionary:
	var messages: Array = item.get("messages", [])
	var payload: Dictionary
	if backend_type == BackendType.OLLAMA_HTTP:
		var options := {
			"temperature": temperature,
			"top_p": top_p,
			"num_predict": max_tokens,
			"seed": int(item.get("request_id", 0))
		}
		if num_ctx > 0:
			options["num_ctx"] = num_ctx
		payload = {
			"model": model_name,
			"messages": messages,
			"stream": false,
			"options": options
		}
	else:
		payload = {
			"model": model_name,
			"messages": messages,
			"stream": false,
			"temperature": temperature,
			"top_p": top_p,
			"max_tokens": max_tokens
		}
	if supports_tools and max_tool_rounds > 0:
		payload["tools"] = _read_only_tools.definitions()
	return payload

func _system_prompt_for(npc_id: String, context: Dictionary) -> String:
	var character: Dictionary = DataRegistry.get_character(npc_id)
	var display_name := str(character.get("name", npc_id.replace("_", " ").capitalize()))
	var role := str(character.get("role", "personagem"))
	var origin := str(character.get("origin", "Baixo Sul da Bahia"))
	var location := str(context.get("location", WorldState.current_hub))
	var tool_rule := ""
	if supports_tools:
		tool_rule = """
Quando a resposta depender de fato de lore, personagem, faccao, geografia ou estado atual que nao esteja explicitamente acima, use as ferramentas read-only antes de afirmar.
canon_lookup e a autoridade factual publica para este dialogo. Se ela nao encontrar o fato, o personagem deve admitir que nao sabe.
As ferramentas apenas consultam; nunca trate uma sugestao sua como mudanca de estado."""
	return """Voce interpreta %s, personagem do jogo Cria do Tatame.
Papel: %s. Origem: %s. Local atual: %s.
Responda em portugues brasileiro, em no maximo tres frases curtas.
Mantenha o canon de Ruan Macacao, Mestre Dende, Tinker Bell e do Baixo Sul da Bahia.
Nao invente personagem principal, faccao, morte, parentesco ou evento canonico novo.
Nao forneca instrucao real para machucar, lesionar ou finalizar uma pessoa.
Fale como personagem, sem explicar que voce e uma IA.
A fala pode variar. O fato canonico nao.%s""" % [display_name, role, origin, location, tool_rule]

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if _active.is_empty():
		return
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		_finish_with_fallback("http_%s_result_%s" % [response_code, result])
		return
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		_finish_with_fallback("invalid_json")
		return
	var message := _extract_response_message(parsed)
	if message.is_empty():
		_finish_with_fallback("missing_message")
		return
	if _continue_with_tool_calls(message):
		return
	var text := _sanitize_response(str(message.get("content", "")))
	if text == "" or not _passes_safety_filter(text):
		_finish_with_fallback("unsafe_or_empty_response")
		return
	var npc_id := str(_active.get("npc_id", "npc"))
	_append_history(npc_id, str(_active.get("user_message", "")), text)
	var request_id := int(_active.get("request_id", 0))
	var source := "ollama" if backend_type == BackendType.OLLAMA_HTTP else "openai_compatible_local"
	if backend_id == "nex_n25_ollama":
		source = "nex_n25_ollama"
	_active = {}
	dialogue_ready.emit(request_id, npc_id, text, source)
	_pump_queue()

func _extract_response_message(parsed: Dictionary) -> Dictionary:
	if backend_type == BackendType.OLLAMA_HTTP:
		var ollama_message = parsed.get("message", {})
		return ollama_message if ollama_message is Dictionary else {}
	var choices: Array = parsed.get("choices", [])
	if choices.is_empty() or not (choices[0] is Dictionary):
		return {}
	var openai_message = choices[0].get("message", {})
	return openai_message if openai_message is Dictionary else {}

func _continue_with_tool_calls(message: Dictionary) -> bool:
	if not supports_tools or max_tool_rounds <= 0:
		return false
	var tool_calls: Array = message.get("tool_calls", [])
	if tool_calls.is_empty():
		return false
	var rounds := int(_active.get("tool_rounds", 0))
	if rounds >= max_tool_rounds:
		_finish_with_fallback("tool_round_limit")
		return true

	var messages: Array = _active.get("messages", [])
	messages.append({
		"role": "assistant",
		"content": str(message.get("content", "")),
		"tool_calls": tool_calls.duplicate(true)
	})

	var request_context: Dictionary = _active.get("context", {})
	for tool_call_value in tool_calls:
		if not (tool_call_value is Dictionary):
			continue
		var tool_call: Dictionary = tool_call_value
		var function_data = tool_call.get("function", {})
		if not (function_data is Dictionary):
			continue
		var tool_name := str(function_data.get("name", ""))
		var arguments = function_data.get("arguments", {})
		if arguments is String:
			var decoded = JSON.parse_string(arguments)
			arguments = decoded if decoded is Dictionary else {}
		elif not (arguments is Dictionary):
			arguments = {}
		var tool_result := _read_only_tools.execute(tool_name, arguments, request_context)
		var tool_message := {
			"role": "tool",
			"content": JSON.stringify(tool_result),
			"tool_name": tool_name
		}
		if tool_call.has("id"):
			tool_message["tool_call_id"] = str(tool_call.get("id", ""))
		messages.append(tool_message)

	_active["messages"] = messages
	_active["tool_rounds"] = rounds + 1
	call_deferred("_dispatch_active_request")
	return true

func _append_history(npc_id: String, user_message: String, assistant_message: String) -> void:
	var history: Array = _history_by_npc.get(npc_id, [])
	history.append({"role": "user", "content": user_message})
	history.append({"role": "assistant", "content": assistant_message})
	while history.size() > max_history_messages:
		history.pop_front()
	_history_by_npc[npc_id] = history

func clear_history(npc_id: String = "") -> void:
	if npc_id == "":
		_history_by_npc.clear()
	else:
		_history_by_npc.erase(npc_id)

func get_fallback_dialogue(npc_id: String, category: String = "default", entropy: String = "") -> String:
	var root_data: Dictionary = DataRegistry.ai_dialogue_fallbacks
	var character_sets: Dictionary = root_data.get("characters", {})
	var npc_data: Dictionary = character_sets.get(npc_id, {})
	var options: Array = npc_data.get(category, npc_data.get("default", []))
	if options.is_empty():
		options = root_data.get("global_fallback", [])
	if options.is_empty():
		return "O tatame ficou em silencio. Volte ao objetivo atual."
	var index := absi(hash("%s|%s|%s" % [npc_id, category, entropy])) % options.size()
	return str(options[index])

func _emit_fallback(item: Dictionary, source: String) -> void:
	dialogue_ready.emit(
		int(item.get("request_id", 0)),
		str(item.get("npc_id", "npc")),
		str(item.get("fallback", "")),
		source
	)

func _finish_with_fallback(reason: String) -> void:
	var item := _active.duplicate(true)
	_active = {}
	dialogue_failed.emit(int(item.get("request_id", 0)), str(item.get("npc_id", "npc")), reason)
	_emit_fallback(item, "fallback_after_error")
	_pump_queue()

func _sanitize_user_message(text: String) -> String:
	var clean := text.strip_edges().replace("\r", " ").replace("\n", " ")
	while clean.find("  ") >= 0:
		clean = clean.replace("  ", " ")
	return clean.left(300)

func _sanitize_response(text: String) -> String:
	var clean := text.strip_edges().replace("\r", " ").replace("\n", " ")
	while clean.find("  ") >= 0:
		clean = clean.replace("  ", " ")
	return clean.left(max_response_chars)

func _passes_safety_filter(text: String) -> bool:
	var lower := text.to_lower()
	var blocked_phrases := [
		"quebre o braco",
		"torca ate quebrar",
		"continue mesmo depois do tap",
		"apague o adversario",
		"cause lesao"
	]
	for phrase in blocked_phrases:
		if lower.find(phrase) >= 0:
			return false
	for forbidden_value in DataRegistry.local_ai_config.get("prompt_rules", {}).get("forbidden_output_fragments", []):
		var forbidden := str(forbidden_value).to_lower()
		if forbidden != "" and lower.find(forbidden) >= 0:
			return false
	return true
