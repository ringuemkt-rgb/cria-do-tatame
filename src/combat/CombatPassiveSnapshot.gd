class_name CombatPassiveSnapshot
extends RefCounted

## Normaliza os modificadores consumidos pelo combate v4.1.
## Multiplicadores usam 1.0 como identidade; bônus aditivos usam 0.0.

const MULTIPLIER_KEYS: Array[String] = [
	"sweet_spot_mult",
	"dreno_foco_arena_mult",
	"fadiga_dano_mult",
	"gas_cost_mult",
	"focus_cost_mult",
	"submission_attack_mult",
	"submission_defense_mult",
]

const ADDITIVE_KEYS: Array[String] = [
	"grip_inicial",
	"grip_por_pegada",
	"vida_max_bonus",
	"gas_max_bonus",
	"foco_max_bonus",
]

static func normalize(payload: Dictionary) -> Dictionary:
	var output: Dictionary = {}
	for key in MULTIPLIER_KEYS:
		output[key] = maxf(0.0, float(payload.get(key, 1.0)))
	for key in ADDITIVE_KEYS:
		output[key] = float(payload.get(key, 0.0))
	return output

static func empty() -> Dictionary:
	return normalize({})

static func merge(base: Dictionary, extra: Dictionary) -> Dictionary:
	var output := normalize(base)
	for key in MULTIPLIER_KEYS:
		output[key] = float(output[key]) * maxf(0.0, float(extra.get(key, 1.0)))
	for key in ADDITIVE_KEYS:
		output[key] = float(output[key]) + float(extra.get(key, 0.0))
	return output
