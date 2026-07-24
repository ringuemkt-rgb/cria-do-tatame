extends "res://src/autoloads/WorldState.gd"

## Extensão compatível do WorldState legado com o contrato narrativo v4.
## `story_flags`, `flags`, `flags_historia` e `narrative_flags` apontam para
## o mesmo estado serializável, evitando quatro fontes de verdade.

signal narrative_flag_changed(key: String, value: Variant)

const NARRATIVE_DEFAULTS := {
	"dende_confianca": 0,
	"leoa_vinculo": 0,
	"joaquim_confianca": 0,
	"cassio_relacao": 0,
	"verena_confianca": 0,
	"reis_confianca": 0,
	"underground_acesso": "nenhum",
	"bencao_mare": false,
	"informant_status": "nenhum",
	"mangue_estado": "vivo",
	"tupa200_resolucao": "pendente",
	"provas_joaquim": 0,
	"beats": [],
}

var flags: Dictionary = {}
var narrative_flags: Dictionary = {}

func _ready() -> void:
	_sync_narrative_aliases()

func _sync_aliases() -> void:
	super._sync_aliases()
	_sync_narrative_aliases()

func reset_new_game() -> void:
	super.reset_new_game()
	story_flags = NARRATIVE_DEFAULTS.duplicate(true)
	_sync_aliases()

func set_narrative_flag(key: String, value: Variant) -> void:
	story_flags[key] = value
	_sync_narrative_aliases()
	narrative_flag_changed.emit(key, value)

func get_narrative_flag(key: String, fallback: Variant = null) -> Variant:
	return story_flags.get(key, fallback)

func add_narrative_beat(beat_id: String) -> void:
	var beats: Array = story_flags.get("beats", [])
	if beat_id != "" and not beats.has(beat_id):
		beats.append(beat_id)
		story_flags["beats"] = beats
		_sync_narrative_aliases()
		narrative_flag_changed.emit("beats", beats.duplicate())

func to_dict() -> Dictionary:
	_sync_aliases()
	var data: Dictionary = super.to_dict()
	data["story_flags"] = story_flags.duplicate(true)
	data["narrative_flags"] = story_flags.duplicate(true)
	return data

func load_from_dict(data) -> void:
	super.load_from_dict(data)
	var incoming: Dictionary = data.get("narrative_flags", data.get("story_flags", {})).duplicate(true)
	story_flags = NARRATIVE_DEFAULTS.duplicate(true)
	story_flags.merge(incoming, true)
	_sync_aliases()

func _sync_narrative_aliases() -> void:
	var merged := NARRATIVE_DEFAULTS.duplicate(true)
	merged.merge(story_flags, true)
	story_flags = merged
	flags = story_flags
	narrative_flags = story_flags
	flags_historia = story_flags
