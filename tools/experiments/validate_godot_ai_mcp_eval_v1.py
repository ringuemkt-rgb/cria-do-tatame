#!/usr/bin/env python3
"""Validate the isolated Godot AI / Godot 4.7 evaluation contract."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
CONTRACT = ROOT / "data/production/godot_ai_mcp_eval_v1.json"

REQUIRED_GATES = {
    "npm_run_quality",
    "godot_4_7_headless_import_and_parser",
    "mandatory_flow_runtime_smoke",
    "forty_mission_data_and_reference_regression",
    "world_map_routes_nodes_and_travel_regression",
    "save_load_roundtrip_and_migration_regression",
    "ruan_davi_combat_determinism_regression",
    "godot_ai_read_only_scene_and_resource_inspection",
    "godot_ai_reversible_test_scene_edit",
    "android_arm64_export",
    "android_physical_install_touch_full_flow_save_restart",
    "windows_export_smoke",
    "performance_fps_memory_temperature_battery_comparison",
    "plugin_removal_restores_clean_project",
}


def load() -> dict[str, Any]:
    value = json.loads(CONTRACT.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError("Godot AI eval contract root must be object")
    return value


def main() -> int:
    errors: list[str] = []
    try:
        contract = load()
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        print(json.dumps({"ok": False, "errors": [str(exc)]}, indent=2))
        return 1

    if contract.get("status") != "EXPERIMENT_ONLY":
        errors.append("status must remain EXPERIMENT_ONLY")
    for key in ("shipping", "runtime_dependency", "main_engine_version_change_authorized"):
        if contract.get(key) is not False:
            errors.append(f"{key} must remain false before migration approval")

    baseline = contract.get("baseline", {})
    if baseline.get("engine_production_version") != "4.3+":
        errors.append("baseline engine production version must remain 4.3+")
    if baseline.get("engine_minimum_audited") != "4.2.2":
        errors.append("minimum audited baseline must remain 4.2.2")

    candidate = contract.get("candidate", {})
    if candidate.get("branch") != "build/godot-ai-mcp-eval":
        errors.append("candidate branch drift")
    if candidate.get("engine_version") != "4.7":
        errors.append("Godot AI v4 experiment must use Godot 4.7")
    if candidate.get("godot_ai_version") != "4.1.0":
        errors.append("Godot AI experiment must remain pinned to reviewed v4.1.0")
    if candidate.get("godot_ai_release_tag") != "v4.1.0":
        errors.append("release tag must remain v4.1.0")
    if candidate.get("godot_ai_release_commit") != "7968ada03044473372a8ab4beadd975c60b9d94a":
        errors.append("release commit drift")
    if candidate.get("godot_ai_archive_sha256") != "535d8a7541871af8d991b07fe5031550dd6121a31b844400476b334a70612831":
        errors.append("reviewed archive hash drift")
    if candidate.get("godot_ai_v4_minimum_engine") != "4.7":
        errors.append("v4 minimum engine must remain 4.7")
    if candidate.get("godot_ai_v3_2_5_minimum_engine") != "4.5":
        errors.append("v3.2.5 compatibility fact must remain 4.5")
    if candidate.get("plugin_may_be_required_by_shipping_runtime") is not False:
        errors.append("Godot AI may not become a shipping runtime dependency")

    isolation = contract.get("isolation", {})
    for key in (
        "do_not_modify_main_during_experiment",
        "do_not_commit_provider_credentials",
        "do_not_commit_local_mcp_client_config",
        "do_not_make_new_gameplay_manager",
        "do_not_change_combat_authority",
        "do_not_change_save_schema_only_for_plugin",
    ):
        if isolation.get(key) is not True:
            errors.append(f"isolation.{key} must remain true")

    gates = contract.get("gates")
    if not isinstance(gates, list) or not gates:
        errors.append("evaluation gates missing")
        gates = []
    names: set[str] = set()
    ids: set[str] = set()
    allowed_statuses = set(contract.get("decision_rule", {}).get("allowed_statuses", []))
    for row in gates:
        if not isinstance(row, dict):
            errors.append("gate entry must be object")
            continue
        gid = row.get("id")
        name = row.get("name")
        status = row.get("status")
        if not isinstance(gid, str) or not gid:
            errors.append("gate missing id")
        elif gid in ids:
            errors.append(f"duplicate gate id: {gid}")
        else:
            ids.add(gid)
        if not isinstance(name, str) or not name:
            errors.append(f"{gid}: gate missing name")
        else:
            names.add(name)
        if status not in allowed_statuses:
            errors.append(f"{gid}: invalid gate status {status}")

    missing = sorted(REQUIRED_GATES - names)
    if missing:
        errors.append(f"required migration gates missing: {missing}")

    decision = contract.get("decision_rule", {})
    if decision.get("adopt_engine_4_7_only_if_all_gates_pass") is not True:
        errors.append("4.7 adoption must require every gate PASS")
    if decision.get("any_fail_blocks_main_migration") is not True:
        errors.append("any FAIL must block main migration")
    if decision.get("blocked_human_device_gate_blocks_release_claim") is not True:
        errors.append("blocked device gate must block release claim")
    if decision.get("godot_ai_success_does_not_require_godot_ai_in_shipping") is not True:
        errors.append("tooling success must stay decoupled from shipping dependency")

    evidence = contract.get("evidence", {})
    if evidence.get("current_state") not in {"NOT_EXECUTED_IN_THIS_ENVIRONMENT", "PARTIAL", "COMPLETE"}:
        errors.append("invalid evidence.current_state")

    result = {"ok": not errors, "gates": len(gates), "errors": errors}
    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
