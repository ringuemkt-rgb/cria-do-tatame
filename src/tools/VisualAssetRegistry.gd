extends Node
class_name VisualAssetRegistry

const CATALOG_PATH := "res://data/visual/runtime_visual_catalog_v1.json"
var entries: Dictionary = {}

func load_catalog(path: String = CATALOG_PATH) -> bool:
    if not FileAccess.file_exists(path):
        push_warning("Visual catalog not found: %s" % path)
        return false
    var file := FileAccess.open(path, FileAccess.READ)
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        push_error("Invalid visual catalog JSON")
        return false
    entries.clear()
    for item in parsed.get("entries", []):
        entries[item.get("asset_id", "")] = item
    return true

func has_asset(asset_id: String) -> bool:
    return entries.has(asset_id)

func get_asset(asset_id: String) -> Dictionary:
    return entries.get(asset_id, {})

func get_file_path(asset_id: String, file_key: String) -> String:
    var item: Dictionary = get_asset(asset_id)
    if item.is_empty():
        return ""
    var rel: String = item.get("files", {}).get(file_key, "")
    if rel.is_empty():
        return ""
    return "res://%s/%s" % [item.get("base_path", ""), rel]
