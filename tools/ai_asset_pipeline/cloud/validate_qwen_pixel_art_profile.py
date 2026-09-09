#!/usr/bin/env python3
"""Fail-closed offline gate for the CRIA Qwen-Image-2512 Pixel Art authoring profile."""
from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[3]
PROFILE_PATH = ROOT / "data/ai/qwen_pixel_art_profile_v1.json"
REGISTRY_PATH = ROOT / "data/ai/model_registry_v02.json"
HEX40 = re.compile(r"^[0-9a-f]{40}$")
HEX64 = re.compile(r"^[0-9a-f]{64}$")


def load(path: Path, errors: list[str]) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        errors.append(f"invalid JSON {path.relative_to(ROOT)}: {exc}")
        return {}
    if not isinstance(value, dict):
        errors.append(f"JSON root is not an object: {path.relative_to(ROOT)}")
        return {}
    return value


def main() -> int:
    errors: list[str] = []
    profile = load(PROFILE_PATH, errors)
    registry = load(REGISTRY_PATH, errors)
    if errors:
        print(json.dumps({"ok": False, "errors": errors}, ensure_ascii=False, indent=2))
        return 1

    if profile.get("status") != "CANDIDATE_AUTHORING_PROFILE":
        errors.append("Qwen profile must remain CANDIDATE_AUTHORING_PROFILE")
    if profile.get("runtime_authority") is not False:
        errors.append("Qwen profile must never have runtime authority")
    if profile.get("shipping") is not False:
        errors.append("Qwen generation profile must default shipping=false")

    base = profile.get("base_model", {})
    lora = profile.get("lora", {})
    if base.get("id") != "Qwen/Qwen-Image-2512":
        errors.append("Unexpected Qwen base model")
    if lora.get("id") != "prithivMLmods/Qwen-Image-2512-Pixel-Art-LoRA":
        errors.append("Unexpected pixel-art LoRA")
    for label, revision in (("base", base.get("revision")), ("lora", lora.get("revision"))):
        if not isinstance(revision, str) or not HEX40.fullmatch(revision):
            errors.append(f"{label} revision must be a full immutable 40-char SHA")
    if base.get("license_metadata") != "apache-2.0" or lora.get("license_metadata") != "apache-2.0":
        errors.append("Audited Qwen base/LoRA license metadata drifted")
    if lora.get("trigger") != "Pixel Art":
        errors.append("Pixel-art trigger must remain exactly `Pixel Art`")
    if not isinstance(lora.get("weights_sha256"), str) or not HEX64.fullmatch(lora["weights_sha256"]):
        errors.append("LoRA weights SHA256 must be pinned")
    if lora.get("training_dataset_provenance") != "NOT_DISCLOSED_IN_MODEL_CARD":
        errors.append("Training dataset provenance risk must remain explicit")

    acquisition = profile.get("acquisition", {})
    clone = str(acquisition.get("metadata_clone", ""))
    if not clone.startswith("GIT_LFS_SKIP_SMUDGE=1 git clone "):
        errors.append("Metadata audit clone must skip LFS smudge")
    if "prithivMLmods/Qwen-Image-2512-Pixel-Art-LoRA" not in clone:
        errors.append("Metadata clone points to the wrong LoRA repository")
    if acquisition.get("weights_download_policy") != "ON_DEMAND_PINNED_REVISION_ONLY":
        errors.append("Weights must be downloaded only on demand at a pinned revision")
    if acquisition.get("verify_sha256_before_inference") is not True:
        errors.append("LoRA SHA256 verification must remain mandatory")

    inference = profile.get("inference", {})
    if inference.get("steps_default") not in inference.get("steps_allowed", []):
        errors.append("Default inference steps must be inside the audited range")
    if inference.get("steps_allowed") != [45, 46, 47, 48, 49, 50]:
        errors.append("Audited LoRA inference step range drifted")
    dims = {(d.get("width"), d.get("height")) for d in inference.get("published_dimensions", []) if isinstance(d, dict)}
    if {(1024, 1024), (1280, 832)} - dims:
        errors.append("Published upstream dimensions are incomplete")
    note = str(inference.get("dimension_note", ""))
    if "1.538" not in note or "incorrect ratio label" not in note:
        errors.append("Upstream 1280x832 ratio-label correction must remain documented")

    routing = profile.get("routing", {})
    forbidden_authority = set(routing.get("not_authoritative_alone", []))
    required_non_authority = {
        "fighter_core_spritesheet",
        "fighter_clinch_spritesheet",
        "fighter_ground_spritesheet",
        "paired_bjj_technique",
        "identity_from_real_person_reference",
        "ui_with_baked_text",
    }
    if not required_non_authority.issubset(forbidden_authority):
        errors.append("Qwen LoRA is being over-promoted beyond safe authoring roles")

    post = set(profile.get("postprocess_required", []))
    required_post = {
        "human_visual_selection",
        "palette_snap",
        "manual_pixel_cleanup",
        "sprite_forge_qa_when_sprite",
        "provenance_sidecar",
        "rights_review",
        "human_approval",
        "godot_integration_before_product_status",
    }
    if not required_post.issubset(post):
        errors.append("Qwen profile lost mandatory post-processing/promotion gates")

    guards = profile.get("promotion_guards", {})
    for key in (
        "generation_implies_approval",
        "generation_implies_rights_clearance",
        "generation_implies_shipping",
        "model_license_implies_training_dataset_provenance",
    ):
        if guards.get(key) is not False:
            errors.append(f"Promotion guard must remain false: {key}")

    models = {item.get("id"): item for item in registry.get("models", []) if isinstance(item, dict)}
    for descriptor in (base, lora):
        model_id = descriptor.get("id")
        entry = models.get(model_id)
        if not entry:
            errors.append(f"Qwen profile model missing from registry: {model_id}")
            continue
        if entry.get("adoption_status") != "candidate_generation_allowed":
            errors.append(f"Qwen stack must be candidate_generation_allowed: {model_id}")
        if entry.get("requested_ref") != descriptor.get("revision"):
            errors.append(f"Profile/registry revision mismatch: {model_id}")
        if entry.get("license") != descriptor.get("license_metadata"):
            errors.append(f"Profile/registry license mismatch: {model_id}")

    result = {
        "ok": not errors,
        "errors": errors,
        "base": base.get("id"),
        "lora": lora.get("id"),
        "shipping": profile.get("shipping"),
    }
    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
