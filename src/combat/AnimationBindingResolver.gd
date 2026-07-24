class_name AnimationBindingResolver
extends RefCounted

var character_id := ""
var bindings: Dictionary = {}

func configure(manifest: Dictionary) -> Dictionary:
	character_id = str(manifest.get("character_id", ""))
	bindings = manifest.get("bindings", {}).duplicate(true)
	return {
		"ok": character_id != "" and not bindings.is_empty(),
		"character_id": character_id,
		"bindings": bindings.size(),
	}

func resolve(card_id: String) -> Dictionary:
	if not bindings.has(card_id):
		return {"ok": false, "error": "binding_missing", "card_id": card_id}
	var binding: Dictionary = bindings[card_id].duplicate(true)
	binding["ok"] = true
	binding["character_id"] = character_id
	return binding

func has_binding(card_id: String) -> bool:
	return bindings.has(card_id)

func validate_against_cards(cards_payload: Dictionary) -> Dictionary:
	var cards_by_id: Dictionary = {}
	for raw in cards_payload.get("cartas", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var card_id := str(raw.get("id", ""))
		if card_id != "":
			cards_by_id[card_id] = raw
	var errors: Array[String] = []
	for card_id_value in bindings.keys():
		var card_id := str(card_id_value)
		var binding: Dictionary = bindings[card_id]
		if not cards_by_id.has(card_id):
			errors.append("card_missing:%s" % card_id)
			continue
		if str(binding.get("card_id", "")) != card_id:
			errors.append("card_id_mismatch:%s" % card_id)
		if str(binding.get("animation_state", "")) == "":
			errors.append("animation_state_missing:%s" % card_id)
		var card_animation := str(cards_by_id[card_id].get("frames_anim", ""))
		if card_animation != "" and card_animation != str(binding.get("animation_state", "")):
			errors.append("animation_state_mismatch:%s" % card_id)
	return {"ok": errors.is_empty(), "errors": errors}
