#!/usr/bin/env python3
"""Fail-closed structural validator for CRIA Sprite Forge v2."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from derive_sprite_forge_v2_requirements import derive

ROOT = Path(__file__).resolve().parents[2]
CONTRACT = ROOT / "data/visual/sprite_forge_contract_v2.json"
POLICY = ROOT / "data/visual/sprite_forge_requirements_v2.json"
BJJ_GATE = ROOT / "data/combat/bjj_completion_gate_v1.json"
REGISTRY = ROOT / "data/production/external_tool_registry_v1.json"
ROSTER = ROOT / "data/combat/roster_v3.json"
ARENAS = ROOT / "data/world/arena_info_v1.json"


def load(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path}: root must be object")
    return value


def main() -> int:
    errors: list[str] = []
    for required in (CONTRACT, POLICY, BJJ_GATE, REGISTRY, ROSTER, ARENAS):
        if not required.exists():
            errors.append(f"missing required source: {required.relative_to(ROOT)}")
    if errors:
        print(json.dumps({"ok": False, "errors": errors}, indent=2))
        return 1

    contract = load(CONTRACT)
    policy = load(POLICY)
    bjj_gate = load(BJJ_GATE)
    registry = load(REGISTRY)
    roster = load(ROSTER)
    arenas = load(ARENAS)

    if contract.get("version") != "2.0.0":
        errors.append("Sprite Forge v2 contract version must be 2.0.0")
    authority = contract.get("authority", {})
    if authority.get("runtime") != "Godot":
        errors.append("Godot must remain sole runtime authority")
    if authority.get("this_contract_may_set_shipping_true") is not False:
        errors.append("Sprite Forge v2 cannot authorize shipping")

    frame = contract.get("frame_contract", {})
    if frame.get("normalized_gameplay_frame_px") != [128, 128]:
        errors.append("normalized gameplay frame must remain 128x128")
    if frame.get("upright_pivot_px") != [64, 96]:
        errors.append("upright pivot must remain [64,96]")
    if frame.get("resampling") != "nearest" or frame.get("integer_scale_only") is not True:
        errors.append("pixel-art resampling must remain nearest + integer-only")
    if frame.get("raw_generation_is_never_runtime_asset") is not True:
        errors.append("raw generated image must never be runtime asset")

    identity = contract.get("identity_lock", {})
    if identity.get("required_for_playable_character") is not True:
        errors.append("playable characters require identity lock")
    for field in ("turnaround", "front_combat_pose", "back_view", "side_view", "palette_signature", "silhouette_signature"):
        if field not in identity.get("master_artifacts", []):
            errors.append(f"identity_lock missing master artifact: {field}")

    paired = contract.get("paired_bjj_animation", {})
    canonical_phases = bjj_gate.get("paired_animation_contract", {}).get("required_phases", [])
    if paired.get("required_phases") != canonical_phases:
        errors.append("paired BJJ phases diverge from BJJ completion gate")
    if paired.get("generic_attack_prompt_cannot_define_bjj_motion") is not True:
        errors.append("generic attack prompts must not define BJJ motion")
    if paired.get("expert_biomechanical_review_required") is not True:
        errors.append("paired BJJ animation requires expert biomechanical review")

    preview = contract.get("preview_harness", {})
    if preview.get("required_before_godot_promotion") is not True:
        errors.append("preview harness must run before Godot promotion")
    if preview.get("zero_frames_checked_is_pass") is not False:
        errors.append("zero-frame preview cannot pass")

    world = contract.get("world_art", {})
    if world.get("generated_single_flat_map_is_not_shipping_ready") is not True:
        errors.append("single flat generated maps must not be shipping-ready")
    if world.get("walkable_space_must_be_defined_by_game_data_not_image_guessing") is not True:
        errors.append("walkability must remain game-data authority")

    provenance = contract.get("provenance_sidecar", {})
    if provenance.get("shipping_default") is not False:
        errors.append("provenance sidecars must default shipping=false")
    for field in ("source_requirement_id", "model_or_tool_revision", "qa_evidence", "human_approval", "rights_status", "shipping"):
        if field not in provenance.get("required_fields", []):
            errors.append(f"provenance sidecar missing required field: {field}")

    sources = {row.get("id"): row for row in registry.get("sources", []) if isinstance(row, dict)}
    external = sources.get("blendi_sprite_sheet_creator")
    if not external:
        errors.append("external registry missing blendi_sprite_sheet_creator")
    else:
        if external.get("license_status") != "NO_LICENSE_FOUND":
            errors.append("blendi sprite-sheet-creator must remain NO_LICENSE_FOUND until upstream publishes license")
        if external.get("direct_code_reuse") is not False or external.get("direct_asset_reuse") is not False:
            errors.append("unlicensed sprite-sheet-creator cannot allow direct reuse")
        if external.get("adoption") != "STUDY_AND_REIMPLEMENT_CONCEPTS_ONLY":
            errors.append("unlicensed sprite-sheet-creator must remain concept reimplementation only")

    output = derive(ROOT)
    reqs = output.get("requirements", [])
    ids = [r.get("requirement_id") for r in reqs]
    if len(ids) != len(set(ids)):
        errors.append("derived requirement ids are not unique")
    if any(r.get("shipping") is not False for r in reqs):
        errors.append("derived requirements must all remain shipping=false")
    if output.get("summary", {}).get("fighters") != len(roster.get("fighters", [])):
        errors.append("derived fighter coverage does not equal roster")
    if output.get("summary", {}).get("world_locations") != len(arenas.get("arenas", [])):
        errors.append("derived world coverage does not equal arena catalog")

    p1_fighters = set(policy.get("priority", {}).get("p1_fighters", []))
    for fid in p1_fighters:
        fighter_rows = [r for r in reqs if r.get("category") == "character" and r.get("source_id") == fid]
        if not fighter_rows or any(r.get("priority") != 1 for r in fighter_rows):
            errors.append(f"P1 fighter not fully priority-1 derived: {fid}")

    if output.get("source_blockers"):
        technique_rows = [r for r in reqs if r.get("category") == "technique"]
        if technique_rows and any(r.get("scope") == "FULL_GAME" and not r.get("blockers") for r in technique_rows):
            errors.append("incomplete BJJ source cannot silently create unblocked FULL_GAME technique art")

    result = {
        "ok": not errors,
        "fighters": output.get("summary", {}).get("fighters"),
        "world_locations": output.get("summary", {}).get("world_locations"),
        "requirements": output.get("summary", {}).get("requirements_total"),
        "source_blockers": output.get("source_blockers"),
        "errors": errors,
    }
    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
