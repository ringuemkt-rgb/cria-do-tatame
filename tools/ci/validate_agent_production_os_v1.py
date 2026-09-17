#!/usr/bin/env python3
"""Fail-closed validation for CRIA Universal Agent Production OS v1."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
CONTRACT = ROOT / "data/production/agent_production_contract_v1.json"
EXTERNAL = ROOT / "data/production/external_tool_registry_v1.json"
SHA40 = re.compile(r"^[0-9a-f]{40}$")

REQUIRED_EXTERNAL_IDS = {
    "agent_sprite_forge",
    "godot_mcp_sods2",
    "blender_mcp_ahujasid",
    "comfy_mcp_official",
    "comfyui_official",
}

REQUIRED_WORKFLOWS = {
    ".criaforge/workflows/technique_to_gameplay.yaml",
    ".criaforge/workflows/visual_asset_to_runtime.yaml",
    ".criaforge/workflows/paired_bjj_to_runtime.yaml",
    ".criaforge/workflows/map_world_to_runtime.yaml",
    ".criaforge/workflows/release_vertical_slice.yaml",
}


def load(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path}: root must be object")
    return value


def path_exists(rel: str) -> bool:
    clean = rel.rstrip("/")
    return (ROOT / clean).exists()


def main() -> int:
    errors: list[str] = []
    try:
        contract = load(CONTRACT)
        external = load(EXTERNAL)
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        print(json.dumps({"ok": False, "errors": [str(exc)]}, indent=2))
        return 1

    if contract.get("status") != "ACTIVE_ORCHESTRATION_CONTRACT":
        errors.append("agent production contract status must be ACTIVE_ORCHESTRATION_CONTRACT")
    if contract.get("version") != "1.0.0":
        errors.append("agent production contract version must be 1.0.0")

    authority = contract.get("authority", {})
    if authority.get("runtime") != "Godot":
        errors.append("Godot must remain the only runtime authority")
    if authority.get("shipping_authority") is not False:
        errors.append("agent production contract cannot authorize shipping")

    for key, rel in authority.items():
        if key in {"runtime", "shipping_authority"}:
            continue
        if not isinstance(rel, str) or not path_exists(rel):
            errors.append(f"authority path missing: {key}={rel}")

    capability_rows = contract.get("capabilities", [])
    if not isinstance(capability_rows, list) or not capability_rows:
        errors.append("capabilities must be a non-empty list")
        capability_rows = []
    capability_ids: set[str] = set()
    for row in capability_rows:
        cid = str(row.get("id", "")) if isinstance(row, dict) else ""
        if not cid:
            errors.append("capability missing id")
            continue
        if cid in capability_ids:
            errors.append(f"duplicate capability: {cid}")
        capability_ids.add(cid)

    tier_ids: set[str] = set()
    for tier in contract.get("execution_tiers", []):
        if not isinstance(tier, dict):
            errors.append("execution tier must be object")
            continue
        tid = str(tier.get("id", ""))
        if not tid or tid in tier_ids:
            errors.append(f"invalid/duplicate tier id: {tid}")
        tier_ids.add(tid)
        for req in tier.get("requires_all", []):
            if req not in capability_ids:
                errors.append(f"{tid}: unknown requires_all capability {req}")
        for group in tier.get("requires_any", []):
            if not isinstance(group, list) or not group:
                errors.append(f"{tid}: requires_any group must be non-empty list")
                continue
            for req in group:
                if req not in capability_ids:
                    errors.append(f"{tid}: unknown requires_any capability {req}")

    expected_tiers = {
        "T0_OBSERVER", "T1_AUTHOR", "T2_ASSET_AUTHOR",
        "T3_RUNTIME_INTEGRATOR", "T4_MOTION_PRODUCER", "T5_RELEASE_OPERATOR",
    }
    if tier_ids != expected_tiers:
        errors.append(f"execution tiers mismatch: {sorted(tier_ids)}")

    routes = contract.get("domain_routes", {})
    if not isinstance(routes, dict) or not routes:
        errors.append("domain_routes missing")
    else:
        for domain, route in routes.items():
            if not isinstance(route, dict):
                errors.append(f"domain route {domain} must be object")
                continue
            skill = route.get("skill")
            if not isinstance(skill, str) or not path_exists(skill):
                errors.append(f"domain route skill missing: {domain}={skill}")
            for rel in route.get("authorities", []):
                if not isinstance(rel, str) or not path_exists(rel):
                    errors.append(f"domain route authority missing: {domain}={rel}")

    workflow_files = set(contract.get("workflow_files", []))
    if workflow_files != REQUIRED_WORKFLOWS:
        errors.append("workflow_files must list exactly the five v1 workflows")
    for rel in REQUIRED_WORKFLOWS:
        if not path_exists(rel):
            errors.append(f"workflow missing: {rel}")

    bootstrap = contract.get("bootstrap", {})
    for key in ("detector", "validator"):
        rel = bootstrap.get(key)
        if not isinstance(rel, str) or not path_exists(rel):
            errors.append(f"bootstrap {key} missing: {rel}")

    external_rows = external.get("sources", [])
    external_by_id = {
        str(row.get("id")): row for row in external_rows if isinstance(row, dict) and row.get("id")
    }
    missing_external = sorted(REQUIRED_EXTERNAL_IDS - set(external_by_id))
    if missing_external:
        errors.append(f"required universal-agent external sources missing: {missing_external}")

    for sid in REQUIRED_EXTERNAL_IDS & set(external_by_id):
        row = external_by_id[sid]
        revision = str(row.get("revision", ""))
        if not SHA40.fullmatch(revision):
            errors.append(f"{sid}: revision must be immutable 40-char SHA")
        if row.get("direct_asset_reuse") is not False:
            errors.append(f"{sid}: direct_asset_reuse must remain false")
        if row.get("runtime_dependency", False) is not False:
            errors.append(f"{sid}: external authoring source cannot be runtime dependency")

    # Important license-specific boundaries.
    sprite = external_by_id.get("agent_sprite_forge", {})
    if sprite:
        if sprite.get("license_status") != "CLEAR_MIT":
            errors.append("agent_sprite_forge must remain CLEAR_MIT")
        if sprite.get("adoption") != "PORT_SELECTED_PATTERNS":
            errors.append("agent_sprite_forge adoption must be PORT_SELECTED_PATTERNS")

    godot_mcp = external_by_id.get("godot_mcp_sods2", {})
    blender_mcp = external_by_id.get("blender_mcp_ahujasid", {})
    for sid, row in (("godot_mcp_sods2", godot_mcp), ("blender_mcp_ahujasid", blender_mcp)):
        if row and row.get("license_status") != "CLEAR_MIT":
            errors.append(f"{sid} must remain CLEAR_MIT")

    comfy_mcp = external_by_id.get("comfy_mcp_official", {})
    if comfy_mcp and comfy_mcp.get("license_status") != "AGPL_3_OR_COMMERCIAL_DUAL":
        errors.append("comfy_mcp_official license boundary changed; review required")
    comfyui = external_by_id.get("comfyui_official", {})
    if comfyui and comfyui.get("license_status") != "GPL_3_0":
        errors.append("comfyui_official license boundary changed; review required")

    # The orchestration layer must not install itself into the game runtime.
    forbidden_runtime_markers = {"new_autoload", "second_project_godot", "llm_combat_loop"}
    invariants_text = " ".join(str(x).lower() for x in contract.get("invariants", []))
    if "only game runtime" not in invariants_text:
        errors.append("invariants must state single Godot runtime")
    if "frame-by-frame combat loop" not in invariants_text:
        errors.append("invariants must forbid LLM frame-by-frame combat control")

    result = {
        "ok": not errors,
        "capabilities": len(capability_ids),
        "tiers": sorted(tier_ids),
        "domains": len(routes) if isinstance(routes, dict) else 0,
        "external_sources_checked": sorted(REQUIRED_EXTERNAL_IDS & set(external_by_id)),
        "errors": errors,
    }
    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    return 0 if not errors else 1


if __name__ == "__main__":
    sys.exit(main())
