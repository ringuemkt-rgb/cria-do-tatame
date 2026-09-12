#!/usr/bin/env python3
"""Fail-closed structural validator for CRIA Motion Factory V1."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
CONTRACT = ROOT / "data/production/motion_factory_v1.json"
SLICE = ROOT / "data/motion/ruan_davi_motion_slice_v1.json"
GOLDEN_CHAIN = ROOT / "data/combat/golden_chain_ruan_davi_v1.json"
EXTERNAL_REGISTRY = ROOT / "data/production/external_tool_registry_v1.json"
MOTION_REGISTRY = ROOT / "data/research/motion_tool_registry_v1.json"
ADAPTER = ROOT / "tools/motion_factory/run_mixamo_llm_mocap.py"
DOC = ROOT / "docs/gameplay/MOTION_FACTORY_V1.md"
RAW_MEDIA_EXTENSIONS = {".mp4", ".mov", ".mkv", ".avi", ".mxf", ".webm", ".mts", ".m2ts"}
PINNED_REVISION = "00dfd5385506022d533c84f6737a09f5f4392623"
CANONICAL_PHASES = ["anticipation", "entry", "establish", "stabilize", "response", "recovery"]


def load(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path.relative_to(ROOT)} root must be an object")
    return value


def validate() -> dict[str, Any]:
    errors: list[str] = []
    for path in (CONTRACT, SLICE, GOLDEN_CHAIN, EXTERNAL_REGISTRY, MOTION_REGISTRY, ADAPTER, DOC):
        if not path.exists():
            errors.append(f"missing required file: {path.relative_to(ROOT)}")
    if errors:
        return {"ok": False, "errors": errors}

    contract = load(CONTRACT)
    slice_data = load(SLICE)
    chain = load(GOLDEN_CHAIN)
    external = load(EXTERNAL_REGISTRY)
    motion = load(MOTION_REGISTRY)
    adapter_text = ADAPTER.read_text(encoding="utf-8")
    doc_text = DOC.read_text(encoding="utf-8")

    if contract.get("version") != "1.0.0" or contract.get("status") != "ACTIVE_OFFLINE_AUTHORING_PIPELINE":
        errors.append("Motion Factory must remain active v1.0.0 offline authoring pipeline")
    if contract.get("shipping") is not False or contract.get("runtime_dependency") is not False:
        errors.append("Motion Factory cannot be shipping evidence or a runtime dependency")

    upstream = contract.get("upstream", {})
    if upstream.get("source") != "squall01337/mixamo-llm-mocap":
        errors.append("unexpected mixamo-llm-mocap upstream source")
    if upstream.get("revision") != PINNED_REVISION:
        errors.append("mixamo-llm-mocap revision must remain immutable and audited")
    if upstream.get("code_license") != "MIT":
        errors.append("upstream code license classification changed; re-audit required")
    if upstream.get("vendored") is not False or upstream.get("runtime_dependency") is not False:
        errors.append("upstream must remain external/offline rather than vendored/runtime")

    if contract.get("canonical_phases") != CANONICAL_PHASES:
        errors.append("Motion Factory phases diverge from canonical grappling phases")
    if slice_data.get("canonical_phases") != CANONICAL_PHASES:
        errors.append("Ruan x Davi slice phases diverge from Motion Factory")

    hard = contract.get("hard_gates", {})
    for flag in (
        "mocap_may_define_technique",
        "mocap_may_define_rules",
        "mocap_may_define_score",
        "mocap_may_set_shipping_true",
        "generated_or_retargeted_output_may_auto_approve",
        "pair_collision_proxy_may_replace_mesh_contact_when_visuals_disagree",
    ):
        if hard.get(flag) is not False:
            errors.append(f"hard gate must remain false: {flag}")
    for flag in ("human_review_required", "rights_review_required", "sprite_forge_required", "godot_runtime_evidence_required"):
        if hard.get(flag) is not True:
            errors.append(f"hard gate must remain true: {flag}")

    qa = contract.get("qa_gates", [])
    if not isinstance(qa, list) or len(qa) != 10:
        errors.append("Motion Factory must keep exactly ten named animation QA gates")
    for prefix in ("ANIM_QA_01", "ANIM_QA_07", "ANIM_QA_10"):
        if not any(str(item).startswith(prefix) for item in qa):
            errors.append(f"missing critical QA gate: {prefix}")

    external_rows = {row.get("id"): row for row in external.get("sources", []) if isinstance(row, dict)}
    ext = external_rows.get("mixamo_llm_mocap")
    if not isinstance(ext, dict):
        errors.append("mixamo_llm_mocap missing from external tool reuse registry")
    else:
        if ext.get("source") != "squall01337/mixamo-llm-mocap" or ext.get("revision") != PINNED_REVISION:
            errors.append("external registry mixamo-llm-mocap source/revision mismatch")
        if ext.get("direct_asset_reuse") is not False:
            errors.append("upstream example/Mixamo assets cannot default to direct reuse")

    high_rows = {row.get("id"): row for row in motion.get("high_value_candidates", []) if isinstance(row, dict)}
    research_entry = high_rows.get("mixamo_llm_mocap")
    if not isinstance(research_entry, dict):
        errors.append("mixamo_llm_mocap missing from motion research registry")
    elif research_entry.get("revision") != PINNED_REVISION:
        errors.append("motion research registry mixamo revision mismatch")

    allowed_techniques: set[str] = set()
    for row in chain.get("success_chain", []):
        if isinstance(row, dict) and row.get("technique_id"):
            allowed_techniques.add(str(row["technique_id"]))
    for row in chain.get("alternate_branches", []):
        if isinstance(row, dict) and row.get("technique_id"):
            allowed_techniques.add(str(row["technique_id"]))
    for row in chain.get("defense_branches", []):
        if not isinstance(row, dict):
            continue
        for key in ("attack_id", "counter_id"):
            if row.get(key):
                allowed_techniques.add(str(row[key]))

    units = slice_data.get("units", [])
    if not isinstance(units, list) or not units:
        errors.append("Ruan x Davi Motion Factory slice has no units")
        units = []
    seen: set[str] = set()
    for unit in units:
        if not isinstance(unit, dict):
            errors.append("slice unit is not an object")
            continue
        uid = str(unit.get("id", ""))
        technique = str(unit.get("technique_id", ""))
        if not uid or uid in seen:
            errors.append(f"invalid or duplicate slice unit id: {uid}")
        seen.add(uid)
        if technique not in allowed_techniques:
            errors.append(f"slice unit references technique outside canonical golden chain: {technique}")
        if unit.get("capture_status") != "PENDING":
            errors.append(f"uncaptured seed unit must remain PENDING: {uid}")
        if unit.get("action_spec_status") != "PENDING_HUMAN_BEAT_REVIEW":
            errors.append(f"seed unit cannot claim reviewed action spec: {uid}")

    promotion = slice_data.get("promotion", {})
    for key, value in promotion.items():
        if value is not False:
            errors.append(f"uncaptured seed slice promotion flag must remain false: {key}")
    if slice_data.get("shipping") is not False:
        errors.append("Ruan x Davi Motion Factory slice cannot claim shipping")

    raw_media = [str(path.relative_to(ROOT)) for path in (ROOT / "data/motion").rglob("*") if path.is_file() and path.suffix.lower() in RAW_MEDIA_EXTENSIONS]
    if raw_media:
        errors.append("raw media committed under data/motion: " + ", ".join(raw_media))

    for token in (
        PINNED_REVISION,
        "compare_pair.py",
        "run_in_blender.py",
        "contact",
        "--person",
        "Re-audit before changing the pin",
    ):
        if token not in adapter_text:
            errors.append(f"adapter missing required pinned-pipeline token: {token}")

    for token in (
        "offline authoring",
        "Ruan",
        "Davi",
        "Sprite Forge V2",
        "SMPL-X",
        "shipping=false",
    ):
        if token not in doc_text:
            errors.append(f"Motion Factory documentation missing required concept: {token}")

    return {
        "ok": not errors,
        "errors": errors,
        "units": len(units),
        "allowed_techniques": sorted(allowed_techniques),
        "pinned_revision": PINNED_REVISION,
        "raw_media_in_motion_tree": raw_media,
        "shipping": False,
    }


def main() -> int:
    report = validate()
    print(json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True))
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
