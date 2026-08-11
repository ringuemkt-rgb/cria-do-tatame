class_name PackLoader
extends Node
## Downloads immutable release packs, verifies SHA-256 and extracts below user://packs.

signal pack_pronto(id: String, caminho: String)
signal falha_pack(id: String, erro: String)

const MANIFEST_PATH := "res://data/mobile/packs_runtime.json"
const PACK_ROOT := "user://packs"
const DOWNLOAD_ROOT := "user://packs/.downloads"
const RELEASE_PREFIX := "https://github.com/ringuemkt-rgb/cria-do-tatame/releases/download/"

var manifesto: Dictionary = {}
var _instalando: Dictionary = {}


func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("packs_runtime.json inválido")
		return
	manifesto = parsed
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PACK_ROOT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DOWNLOAD_ROOT))


func instalar(id: String) -> bool:
	return await _instalar_recursivo(id, {})


func _instalar_recursivo(id: String, pilha: Dictionary) -> bool:
	var info := _buscar_pack(id)
	if info.is_empty():
		_falhar(id, "pack_desconhecido")
		return false
	if pilha.has(id):
		_falhar(id, "ciclo_dependencia")
		return false
	if _instalado(info):
		pack_pronto.emit(id, _caminho_final(info))
		return true
	if _instalando.has(id):
		_falhar(id, "instalacao_em_andamento")
		return false
	pilha[id] = true
	for dependency: Variant in info.get("deps", []):
		if not await _instalar_recursivo(str(dependency), pilha):
			pilha.erase(id)
			return false
	pilha.erase(id)
	_instalando[id] = true
	var ok := await _baixar_e_instalar(info)
	_instalando.erase(id)
	return ok


func _buscar_pack(id: String) -> Dictionary:
	for candidate: Variant in manifesto.get("packs", []):
		if candidate is Dictionary and str(candidate.get("id", "")) == id:
			return candidate
	return {}


func _baixar_e_instalar(info: Dictionary) -> bool:
	var id := str(info.get("id", ""))
	var expected_sha := str(info.get("sha256", "")).to_lower()
	var url := str(info.get("url", ""))
	if expected_sha.length() != 64 or not url.begins_with(RELEASE_PREFIX):
		_falhar(id, "manifesto_inseguro")
		return false
	var zip_path := "%s/%s-%s.zip" % [DOWNLOAD_ROOT, id, expected_sha.substr(0, 12)]
	if not FileAccess.file_exists(zip_path):
		var partial := zip_path + ".partial"
		if FileAccess.file_exists(partial):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(partial))
		var http := HTTPRequest.new()
		http.name = "PackDownload_%s" % id
		http.download_file = partial
		http.timeout = 0.0
		http.body_size_limit = int(info.get("bytes", 100_000_000)) + 1_048_576
		add_child(http)
		var start_error := http.request(url)
		if start_error != OK:
			http.queue_free()
			_falhar(id, "http_inicio_%s" % start_error)
			return false
		var response: Array = await http.request_completed
		http.queue_free()
		if response.size() != 4 or int(response[0]) != HTTPRequest.RESULT_SUCCESS:
			_falhar(id, "http_transporte")
			return false
		var response_code := int(response[1])
		if response_code < 200 or response_code >= 300:
			_falhar(id, "http_%s" % response_code)
			return false
		if FileAccess.get_sha256(partial).to_lower() != expected_sha:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(partial))
			_falhar(id, "sha256")
			return false
		var rename_error := DirAccess.rename_absolute(
			ProjectSettings.globalize_path(partial), ProjectSettings.globalize_path(zip_path)
		)
		if rename_error != OK:
			_falhar(id, "cache_rename_%s" % rename_error)
			return false
	elif FileAccess.get_sha256(zip_path).to_lower() != expected_sha:
		_falhar(id, "cache_sha256")
		return false
	return _extrair_pack(info, zip_path)


func _extrair_pack(info: Dictionary, zip_path: String) -> bool:
	var id := str(info["id"])
	var final_path := _caminho_final(info)
	if _instalado(info):
		pack_pronto.emit(id, final_path)
		return true
	var staging := "%s/%s/.staging-%s-%s" % [
		PACK_ROOT, id, str(info["sha256"]).substr(0, 12), Time.get_ticks_usec()
	]
	var mkdir_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(staging))
	if mkdir_error != OK:
		_falhar(id, "staging_mkdir_%s" % mkdir_error)
		return false
	var reader := ZIPReader.new()
	var open_error := reader.open(zip_path)
	if open_error != OK:
		_remover_arvore_segura(staging)
		_falhar(id, "zip_open_%s" % open_error)
		return false
	var entries := reader.get_files()
	entries.sort()
	var total_unpacked := 0
	var max_unpacked := int(info.get("unpacked_bytes", 0))
	for entry: String in entries:
		var normalized := entry.replace("\\", "/")
		if not _entrada_zip_segura(normalized):
			reader.close()
			_remover_arvore_segura(staging)
			_falhar(id, "zip_path_traversal")
			return false
		var destination := staging.path_join(normalized)
		if normalized.ends_with("/"):
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(destination))
			continue
		var bytes := reader.read_file(entry)
		total_unpacked += bytes.size()
		if max_unpacked <= 0 or total_unpacked > max_unpacked:
			reader.close()
			_remover_arvore_segura(staging)
			_falhar(id, "zip_unpacked_budget")
			return false
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(destination.get_base_dir()))
		var output := FileAccess.open(destination, FileAccess.WRITE)
		if output == null:
			reader.close()
			_remover_arvore_segura(staging)
			_falhar(id, "zip_write")
			return false
		output.store_buffer(bytes)
		output = null
	reader.close()
	var marker := FileAccess.open(staging.path_join(".installed.json"), FileAccess.WRITE)
	if marker == null:
		_remover_arvore_segura(staging)
		_falhar(id, "marker_write")
		return false
	marker.store_string(JSON.stringify({"id": id, "sha256": info["sha256"], "versao": manifesto.get("versao", "")}, "  "))
	marker = null
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(final_path.get_base_dir()))
	var rename_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(staging), ProjectSettings.globalize_path(final_path)
	)
	if rename_error != OK:
		_remover_arvore_segura(staging)
		_falhar(id, "install_rename_%s" % rename_error)
		return false
	pack_pronto.emit(id, final_path)
	return true


func _entrada_zip_segura(path: String) -> bool:
	if path.is_empty() or path.begins_with("/") or path.contains(":"):
		return false
	for part: String in path.split("/", false):
		if part.is_empty() or part == "." or part == "..":
			return false
	return true


func _caminho_final(info: Dictionary) -> String:
	return "%s/%s/%s" % [PACK_ROOT, info["id"], str(info["sha256"]).substr(0, 12)]


func _instalado(info: Dictionary) -> bool:
	var marker_path := _caminho_final(info).path_join(".installed.json")
	if not FileAccess.file_exists(marker_path):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(marker_path))
	return typeof(parsed) == TYPE_DICTIONARY and str(parsed.get("sha256", "")) == str(info.get("sha256", ""))


func _remover_arvore_segura(path: String) -> void:
	if not path.begins_with(PACK_ROOT + "/"):
		return
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)):
		return
	for filename: String in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path.path_join(filename)))
	for dirname: String in DirAccess.get_directories_at(path):
		_remover_arvore_segura(path.path_join(dirname))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _falhar(id: String, erro: String) -> void:
	falha_pack.emit(id, erro)
