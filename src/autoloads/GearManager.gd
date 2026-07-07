extends Node

var equipped := {"gi": "gi_trancado_perola_basico", "rashguard": "", "shorts": "", "faixa": "branca", "cabelo": "", "barba": "", "tatuagem": ""}
var inventory := ["gi_trancado_perola_basico"]

func reset() -> void:
	equipped = {"gi": "gi_trancado_perola_basico", "rashguard": "", "shorts": "", "faixa": "branca", "cabelo": "", "barba": "", "tatuagem": ""}
	inventory = ["gi_trancado_perola_basico"]

func get_item(item_id: String) -> Dictionary:
	return DataRegistry.gear_catalog.get("items", {}).get(item_id, {})

func buy_item(item_id: String) -> Dictionary:
	var item := get_item(item_id)
	if item.is_empty():
		return {"ok": false, "message": "Item inexistente."}
	var cost := int(item.get("cost", 0))
	if WorldState.money < cost:
		return {"ok": false, "message": "Dinheiro insuficiente."}
	WorldState.money -= cost
	if not inventory.has(item_id):
		inventory.append(item_id)
	return {"ok": true, "message": "Item comprado: " + str(item.get("name", item_id))}

func equip_item(item_id: String) -> Dictionary:
	var item := get_item(item_id)
	if item.is_empty():
		return {"ok": false, "message": "Item inexistente."}
	if not inventory.has(item_id):
		return {"ok": false, "message": "Item nao esta no inventario."}
	var slot := str(item.get("slot", ""))
	if slot == "":
		return {"ok": false, "message": "Item sem slot."}
	equipped[slot] = item_id
	_apply_reputation_modifiers(item.get("modifiers", {}))
	return {"ok": true, "message": "Equipado: " + str(item.get("name", item_id))}

func get_combat_modifiers() -> Dictionary:
	var output := {}
	for slot in equipped.keys():
		var item_id := str(equipped[slot])
		if item_id == "":
			continue
		var mods: Dictionary = get_item(item_id).get("modifiers", {})
		for key in mods.keys():
			output[key] = float(output.get(key, 0.0)) + float(mods[key])
	return output

func is_restricted(restriction_id: String) -> bool:
	for slot in equipped.keys():
		var item_id := str(equipped[slot])
		if item_id == "":
			continue
		var item := get_item(item_id)
		if item.get("restrictions", []).has(restriction_id):
			return true
	return false

func _apply_reputation_modifiers(mods: Dictionary) -> void:
	for axis in ["honra", "hype", "sombra", "legado", "moral", "raiz"]:
		if mods.has(axis):
			WorldState.modify_reputation(axis, float(mods[axis]))

func to_dict() -> Dictionary:
	return {"equipped": equipped, "inventory": inventory}

func load_from_dict(data: Dictionary) -> void:
	equipped = data.get("equipped", equipped)
	inventory = data.get("inventory", inventory)
