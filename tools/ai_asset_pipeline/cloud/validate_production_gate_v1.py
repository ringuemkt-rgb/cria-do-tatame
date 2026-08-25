#!/usr/bin/env python3
"""Validate the GPT WORK production gate without contacting external services."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[3]
GATE_PATH = ROOT / "data" / "production" / "gpt_work_production_gate_v1.json"
LAYOUT_PATH = ROOT / "data" / "ai" / "cloud_drive_layout_v02.json"
SPECS_PATH = ROOT / "data" / "ai" / "lote3_arranque_specs_v01.json"
MODELS_PATH = ROOT / "data" / "ai" / "model_registry_v02.json"
CHECKPOINT_PATH = ROOT / "data" / "ai" / "lote3_arranque_checkpoint_v01.json"

EXPECTED_FACTIONS = {
    "LEM": ("Lá Ele Mil Vezes", "#3FBF3F"),
    "NTM": ("Nós Tem Um Molho", "#D93A2B"),
    "ALE": ("Os Aleluiados", "#2E8FE2"),
}
EXPECTED_FOLDERS = {
    "fila", "fila/entradas", "fila/em_processo", "fila/saidas", "fila/mortos",
    "assets", "assets/candidatos", "assets/aprovados", "assets/reprovados",
    "assets/quarentena_licenca", "audio", "audio/sfx", "audio/vozes", "audio/musica",
    "models", "models/staging", "cache", "data", "data/specs", "data/motions",
    "data/refs", "qa", "qa/relatorios", "ops", "ops/apps_script", "ops/backups",
    "ops/dvc_remote", "builds", "colab_logs", "docs", "manifest",
}
EXPECTED_FILES = {
    "models/registry.json", "cache/index.json", "qa/gate_l1_promocoes.json",
    "ops/heartbeat.json", "ops/quota_ledger.json", "manifest/private_state.json",
}
EXPECTED_PHASES = [
    "antecipacao", "entrada", "contato", "estabilizacao", "resposta", "recuperacao"
]
REQUIRED_ALLOWED_TOOLS = {
    "dvc-gdrive", "comfyui", "controlnet", "dwpose", "flux.1-schnell-safetensors",
    "wan2.2-safetensors", "limboai-mit-offline-fixed-seed",
}


def read_object(path: Path, errors: list[str]) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        errors.append(f"invalid JSON {path.relative_to(ROOT)}: {exc}")
        return {}
    if not isinstance(value, dict):
        errors.append(f"JSON root is not an object: {path.relative_to(ROOT)}")
        return {}
    return value


def validate_gate(gate: dict[str, Any], errors: list[str]) -> None:
    factions = gate.get("canon", {}).get("active_factions", {})
    if set(factions) != set(EXPECTED_FACTIONS):
        errors.append("production gate must expose exactly LEM, NTM and ALE")
    for faction_id, (name, color) in EXPECTED_FACTIONS.items():
        entry = factions.get(faction_id, {})
        if (entry.get("display_name"), entry.get("color")) != (name, color):
            errors.append(f"canonical identity mismatch for {faction_id}")
    protagonist = gate.get("canon", {}).get("protagonist", {})
    if protagonist.get("id") != "ruan_macacao" or protagonist.get("belt") != "blue" or protagonist.get("stripes") != 2:
        errors.append("Ruan must be blue belt with two stripes in the direction contract")
    style = gate.get("style_lock", {})
    if style.get("internal_resolution") != [480, 270] or style.get("upscale_filter") != "nearest":
        errors.append("STYLE-LOCK resolution/filter mismatch")
    for field in ("anti_aliasing", "blur", "watermark", "generated_text_allowed"):
        if style.get(field) is not False:
            errors.append(f"STYLE-LOCK requires {field}=false")
    gate_l1 = gate.get("gate_l1", {})
    allowed = set(gate_l1.get("allowed", []))
    blocked = set(gate_l1.get("blocked_commercial", []))
    if not REQUIRED_ALLOWED_TOOLS.issubset(allowed):
        errors.append(f"missing approved tools: {sorted(REQUIRED_ALLOWED_TOOLS - allowed)}")
    if allowed.intersection(blocked):
        errors.append("a tool cannot be both allowed and commercially blocked")
    if gate_l1.get("automatic_promotion_forbidden") is not True:
        errors.append("automatic promotion must remain forbidden")
    delegated = gate_l1.get("delegated_auto_promotion", {})
    if delegated.get("requested") is not True or delegated.get("active") is not False:
        errors.append("delegated promotion must remain recorded-but-inactive until governance migration")
    if delegated.get("conditions", {}).get("biomechanical_confidence_min") != 0.75:
        errors.append("delegated biomechanical threshold must be 0.75")
    if len(delegated.get("reserved_human_only", [])) != 7:
        errors.append("delegated promotion reserved list must contain seven human-only assets")
    if gate_l1.get("weights_extension_allowlist") != [".safetensors"]:
        errors.append("model weights must be restricted to .safetensors")
    if gate.get("hitbox_phase_order") != EXPECTED_PHASES:
        errors.append("hitbox phases differ from SPEC V1")


def validate_layout(layout: dict[str, Any], errors: list[str]) -> None:
    if layout.get("root_folder_name") != "CriaDoTatame":
        errors.append("Drive root must be exactly CriaDoTatame")
    folders = layout.get("folders", [])
    if set(folders) != EXPECTED_FOLDERS or len(folders) != len(EXPECTED_FOLDERS):
        errors.append("Drive v2 folder tree differs from the production contract")
    if set(layout.get("required_files", [])) != EXPECTED_FILES:
        errors.append("Drive v2 required state files differ from the production contract")
    if layout.get("automatic_promotion_to_approved") is not False:
        errors.append("Drive layout permits automatic promotion")
    if layout.get("provider_ids_versioned") is not False:
        errors.append("Drive layout permits provider IDs in Git")
    queue = layout.get("queue", {})
    if queue.get("heartbeat_seconds") != 300 or queue.get("max_attempts") != 3:
        errors.append("queue heartbeat/retry policy mismatch")
    if layout.get("dvc", {}).get("remote_config_scope") != "local_only":
        errors.append("DVC provider configuration must remain local-only")


def validate_specs(specs: dict[str, Any], errors: list[str]) -> None:
    entries = specs.get("specs")
    if not isinstance(entries, list) or len(entries) != 5:
        errors.append("Lote 3 arranque must contain five character specs")
        return
    if sum(len(entry.get("assets", [])) for entry in entries if isinstance(entry, dict)) != 20:
        errors.append("Lote 3 arranque must contain exactly twenty assets")
    expected_ids = {
        "ruan_macacao", "leoa_quilombola", "nado_pending_canon_id",
        "bia_pimenta_souza", "oni_da_lapa",
    }
    if {entry.get("character_id") for entry in entries} != expected_ids:
        errors.append("Lote 3 character identities differ from the arranque order")
    ready = [entry for entry in entries if entry.get("status") == "entrada_pronta"]
    held = [entry for entry in entries if entry.get("status") == "entrada_hold"]
    if [entry.get("character_id") for entry in ready] != ["leoa_quilombola"] or len(held) != 4:
        errors.append("only Leoa may be ready before the recorded canon migrations")
    for entry in held:
        if not entry.get("hold_codes"):
            errors.append(f"held spec lacks hold_codes: {entry.get('id')}")
    serialized = json.dumps(specs, sort_keys=True)
    for forbidden in ("drive_id", "folder_id", "refresh_token", "access_token"):
        if forbidden in serialized:
            errors.append(f"public Lote 3 specs contain private field {forbidden}")


def validate_models(registry: dict[str, Any], errors: list[str]) -> None:
    models = {entry.get("id"): entry for entry in registry.get("models", []) if isinstance(entry, dict)}
    required = {
        "black-forest-labs/FLUX.1-schnell": "apache-2.0",
        "Wan-AI/Wan2.2-T2V-A14B": "apache-2.0",
        "Wan-AI/Wan2.2-I2V-A14B": "apache-2.0",
        "xinsir/controlnet-openpose-sdxl-1.0": "apache-2.0",
        "yzd-v/DWPose": "apache-2.0",
    }
    for model_id, license_id in required.items():
        entry = models.get(model_id)
        if not entry:
            errors.append(f"approved model/tool missing from registry: {model_id}")
            continue
        if entry.get("license") != license_id:
            errors.append(f"license mismatch for {model_id}")
    flux = models.get("black-forest-labs/FLUX.1-schnell", {})
    if flux.get("adoption_status") != "candidate_generation_allowed":
        errors.append("FLUX.1 schnell must be candidate-only")
    if flux.get("weight_format_policy") != "safetensors_only":
        errors.append("FLUX.1 schnell must enforce safetensors-only weights")
    for blocked_id in ("Comfy-Org/MiniMax-H3", "facebook/musicgen-large", "stabilityai/stable-audio-open-1.0"):
        if str(models.get(blocked_id, {}).get("adoption_status", "")).startswith("candidate_generation"):
            errors.append(f"commercially blocked model marked candidate-capable: {blocked_id}")


def validate_checkpoint(checkpoint: dict[str, Any], errors: list[str]) -> None:
    if checkpoint.get("corrida") != "lote3_arranque_20260811_01" or checkpoint.get("lote") != 3:
        errors.append("Lote 3 checkpoint identity mismatch")
    if checkpoint.get("status") != "blocked_pre_generation" or checkpoint.get("ativos") != []:
        errors.append("checkpoint must not claim generated assets while pre-generation is blocked")
    if checkpoint.get("auto_promovidos") != [] or checkpoint.get("quota_h") != 0:
        errors.append("checkpoint claims promotion or GPU quota without evidence")
    if checkpoint.get("heartbeat") != "ok" or checkpoint.get("prox_spec") != "lote3_leoa_quilombola_v1":
        errors.append("checkpoint heartbeat/next spec mismatch")
    if len(checkpoint.get("pausas_humanas", [])) < 7:
        errors.append("checkpoint omits required human pauses")


def main() -> int:
    errors: list[str] = []
    gate = read_object(GATE_PATH, errors)
    layout = read_object(LAYOUT_PATH, errors)
    specs = read_object(SPECS_PATH, errors)
    models = read_object(MODELS_PATH, errors)
    checkpoint = read_object(CHECKPOINT_PATH, errors)
    if not errors:
        validate_gate(gate, errors)
        validate_layout(layout, errors)
        validate_specs(specs, errors)
        validate_models(models, errors)
        validate_checkpoint(checkpoint, errors)
    result = {"ok": not errors, "errors": errors, "checked_files": 5}
    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
