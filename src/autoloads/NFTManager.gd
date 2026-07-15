extends Node

signal catalog_loaded(item_count: int)
signal entitlements_synced(entitlements: Array, source: String)
signal entitlement_sync_failed(reason: String)

const CATALOG_PATH := "res://data/nft/nft_catalog_v01.json"

var catalog: Dictionary = {}
var state: Dictionary = {"wallet_address": "", "entitlements": [], "verified_at": "", "source": "offline_empty"}
var _http: HTTPRequest
var _backend_url := ""
var _sync_active := false
var _pending_player_id := ""

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.name = "NFTEntitlementHTTPRequest"
	add_child(_http)
	_http.request_completed.connect(_on_entitlement_response)
	catalog = _load_json(CATALOG_PATH)
	catalog_loaded.emit(catalog.get("items", []).size())

func configure_backend(base_url: String) -> void:
	_backend_url = base_url.strip_edges().trim_suffix("/")

func disable_backend() -> void:
	_backend_url = ""

func sync_entitlements(player_id: String, wallet_address: String) -> bool:
	if _sync_active:
		return false
	if _backend_url == "":
		_emit_sync_failure("backend_disabled")
		return false
	var clean_wallet := wallet_address.strip_edges()
	if clean_wallet.length() < 8 or clean_wallet.length() > 128:
		_emit_sync_failure("invalid_wallet")
		return false
	_pending_player_id = player_id.left(64)
	var payload := {"player_id": _pending_player_id, "wallet_address": clean_wallet, "catalog_version": str(catalog.get("version", "0"))}
	var headers := PackedStringArray(["Content-Type: application/json"])
	_http.timeout = 10.0
	var error := _http.request(_backend_url + "/v1/nft/entitlements", headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if error != OK:
		_emit_sync_failure("request_start_failed_%s" % error)
		return false
	_sync_active = true
	return true

func _on_entitlement_response(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_sync_active = false
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		_emit_sync_failure("http_%s_result_%s" % [response_code, result])
		return
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		_emit_sync_failure("invalid_json")
		return
	var validated := _validate_entitlements(parsed.get("entitlements", []))
	state = {"wallet_address": str(parsed.get("wallet_address", "")).left(128), "entitlements": validated, "verified_at": str(parsed.get("verified_at", Time.get_datetime_string_from_system())), "source": str(parsed.get("source", "remote_verified")).left(48), "player_id": _pending_player_id}
	entitlements_synced.emit(validated, str(state["source"]))
	if SignalBus.has_signal("nft_entitlements_synced"):
		SignalBus.nft_entitlements_synced.emit(validated, str(state["source"]))

func _validate_entitlements(incoming) -> Array:
	if typeof(incoming) != TYPE_ARRAY:
		return []
	var known: Dictionary = {}
	for item_value in catalog.get("items", []):
		if typeof(item_value) == TYPE_DICTIONARY:
			known[str(item_value.get("id", ""))] = item_value
	var output: Array = []
	for entitlement_value in incoming:
		var entitlement: Dictionary = entitlement_value if typeof(entitlement_value) == TYPE_DICTIONARY else {"item_id": str(entitlement_value)}
		var item_id := str(entitlement.get("item_id", ""))
		if not known.has(item_id):
			continue
		var item: Dictionary = known[item_id]
		if not bool(item.get("cosmetic_only", true)):
			continue
		output.append({"item_id": item_id, "token_id": str(entitlement.get("token_id", "")), "standard": str(entitlement.get("standard", item.get("standard", "offchain"))), "verified": bool(entitlement.get("verified", true))})
	return output

func has_entitlement(item_id: String) -> bool:
	for entitlement in state.get("entitlements", []):
		if str(entitlement.get("item_id", "")) == item_id and bool(entitlement.get("verified", false)):
			return true
	return false

func get_item(item_id: String) -> Dictionary:
	for item_value in catalog.get("items", []):
		if str(item_value.get("id", "")) == item_id:
			return item_value
	return {}

func get_owned_items() -> Array:
	var output: Array = []
	for entitlement in state.get("entitlements", []):
		var item := get_item(str(entitlement.get("item_id", "")))
		if not item.is_empty():
			output.append(item)
	return output

func get_cosmetic_asset(item_id: String) -> String:
	if not has_entitlement(item_id):
		return ""
	return str(get_item(item_id).get("asset_path", ""))

func clear_wallet_cache() -> void:
	state = {"wallet_address": "", "entitlements": [], "verified_at": "", "source": "offline_empty"}

func to_dict() -> Dictionary:
	return state.duplicate(true)

func load_from_dict(data: Dictionary) -> void:
	state = data.duplicate(true) if not data.is_empty() else {"wallet_address": "", "entitlements": [], "verified_at": "", "source": "offline_empty"}
	state["entitlements"] = _validate_entitlements(state.get("entitlements", []))

func _emit_sync_failure(reason: String) -> void:
	_sync_active = false
	entitlement_sync_failed.emit(reason)
	if SignalBus.has_signal("nft_entitlement_sync_failed"):
		SignalBus.nft_entitlement_sync_failed.emit(reason)

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
