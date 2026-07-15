extends Node

var equipped := {"gi": "gi_trancado_perola_basico", "rashguard": "", "shorts": "", "faixa": "branca", "cabelo": "", "barba": "", "tatuagem": ""}
var inventory := ["gi_trancado_perola_basico"]

func reset() -> void:
	equipped = {"gi": "gi_trancado_perola_basico", "rashguard": "", "shorts": "", "faixa": "branca", "cabelo": "", "barba": "", "tatuagem": ""}
	inventory = ["gi_trancado_perola_basico"]

func get_item(item_id: String) -> Dictionary:
	return DataRegistry.gear_catalog.get("items", {}).get(item_id, {})

func buy_item(item_id: String) -> Dictionary:
	var item: Dictionary = get_item(item_id)
	if item.is_empty():
		return {"ok": false, "message": "Item inexistente."}
	if inventory.has(item_id):
		return {"ok": true, "already_owned": true, "message": "Item já está no inventário."}
	var requirement_failure: String = _requirement_failure(item.get("requires", {}))
	if requirement_failure != "":
		return {"ok": false, "message": requirement_failure}
	var cost: int = maxi(0, int(item.get("cost", 0)))
	if WorldState.money < cost:
		return {"ok": false, "message": "Dinheiro insuficiente."}
	WorldState.money -= cost
	inventory.append(item_id)
	WorldState._sync_aliases()
	return {"ok": true, "already_owned": false, "message": "Item comprado: " + str(item.get("name", item_id))}

func equip_item(item_id: String) -> Dictionary:
	var item: Dictionary = get_item(item_id)
	if item.is_empty():
		return {"ok": false, "message": "Item inexistente."}
	if not inventory.has(item_id):
		return {"ok": false, "message": "Item não está no inventário."}
	var requirement_failure: String = _requirement_failure(item.get("requires", {}))
	if requirement_failure != "":
		return {"ok": false, "message": requirement_failure}
	var slot: String = str(item.get("slot", ""))
	if slot == "" or not equipped.has(slot):
		return {"ok": false, "message": "Item possui slot inválido."}
	if str(equipped.get(slot, "")) == item_id:
		return {"ok": true, "already_equipped": true, "message": "Item já está equipado."}
	equipped[slot] = item_id
	_apply_reputation_modifiers(item.get("modifiers", {}))
	return {"ok": true, "already_equipped": false, "message": "Equipado: " + str(item.get("name", item_id))}

func _requirement_failure(requires_value) -> String:
	if typeof(requires_value) != TYPE_DICTIONARY:
		return ""
	var requires: Dictionary = requires_value
	for key_value in requires.keys():
		var key: String = str(key_value)
		if key.ends_with("_min"):
			var axis: String = key.trim_suffix("_min")
			if WorldState.get_reputation(axis) < float(requires[key]):
				return "Reputação insuficiente em %s." % axis.replace("_", " ")
		elif key == "belt":
			if str(WorldState.belt) != str(requires[key]):
				return "Faixa necessária: %s." % str(requires[key])
	return ""

func get_combat_modifiers() -> Dictionary:
	var output := {}
	for slot_value in equipped.keys():
		var item_id: String = str(equipped[slot_value])
		if item_id == "":
			continue
		var mods: Dictionary = get_item(item_id).get("modifiers", {})
		for key_value in mods.keys():
			var key: String = str(key_value)
			if key in ["honra", "hype", "sombra", "legado", "moral", "raiz"]:
				continue
			output[key] = float(output.get(key, 0.0)) + float(mods[key_value])
	return output

func is_restricted(restriction_id: String) -> bool:
	for slot_value in equipped.keys():
		var item_id: String = str(equipped[slot_value])
		if item_id == "":
			continue
		var item: Dictionary = get_item(item_id)
		if item.get("restrictions", []).has(restriction_id):
			return true
	return false

func _apply_reputation_modifiers(mods: Dictionary) -> void:
	for axis_value in ["honra", "hype", "sombra", "legado", "moral", "raiz"]:
		var axis: String = str(axis_value)
		if mods.has(axis):
			WorldState.modify_reputation(axis, float(mods[axis]))

func to_dict() -> Dictionary:
	return {"equipped": equipped.duplicate(true), "inventory": inventory.duplicate(true)}

func load_from_dict(data: Dictionary) -> void:
	var loaded_equipped = data.get("equipped", equipped)
	var loaded_inventory = data.get("inventory", inventory)
	if typeof(loaded_equipped) == TYPE_DICTIONARY:
		equipped = loaded_equipped.duplicate(true)
	if typeof(loaded_inventory) == TYPE_ARRAY:
		inventory = loaded_inventory.duplicate(true)
	for slot in ["gi", "rashguard", "shorts", "faixa", "cabelo", "barba", "tatuagem"]:
		if not equipped.has(slot):
			equipped[slot] = ""
	if not inventory.has("gi_trancado_perola_basico"):
		inventory.append("gi_trancado_perola_basico")
