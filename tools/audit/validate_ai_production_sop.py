#!/usr/bin/env python3
"""Validate the AI-assisted production SOP against repository authorities."""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SOP_PATH = ROOT / "data" / "production" / "ai_production_sop_v01.json"
CANON_PATH = ROOT / "data" / "production" / "canon_contract_v4_1.json"
PROJECT_PATH = ROOT / "project.godot"


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise AssertionError(f"{path.relative_to(ROOT)} must contain an object")
    return value


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def project_viewport() -> list[int]:
    text = PROJECT_PATH.read_text(encoding="utf-8")
    width = re.search(r"window/size/viewport_width=(\d+)", text)
    height = re.search(r"window/size/viewport_height=(\d+)", text)
    require(width is not None and height is not None, "project viewport is not explicit")
    return [int(width.group(1)), int(height.group(1))]


def main() -> int:
    sop = load_json(SOP_PATH)
    canon = load_json(CANON_PATH)
    require(sop.get("$schema") == "ai_production_sop_v1", "invalid SOP schema")
    require(sop.get("status") == "active_production_contract", "SOP is not active")

    for relative in sop.get("memory_authorities", []):
        require((ROOT / relative).is_file(), f"missing memory authority: {relative}")
    require(sop.get("runtime_authorities") == canon.get("runtime_authorities"), "SOP duplicates or changes runtime authority")

    repository_policy = sop.get("repository_policy", {})
    require(repository_policy.get("single_runtime") == "Godot", "Godot must remain the only runtime")
    require(repository_policy.get("parallel_spec_tree_forbidden") is True, "parallel specs tree must be forbidden")
    for relative in repository_policy.get("forbidden_parallel_paths", []):
        require(not (ROOT / relative).exists(), f"forbidden parallel path exists: {relative}")

    limits = sop.get("automation_limits", {})
    for key in [
        "autonomous_merge_allowed",
        "autonomous_shipping_asset_promotion_allowed",
        "runtime_network_ai_allowed",
        "llm_may_change_combat_outcome",
        "text_specification_replaces_asset_qa",
    ]:
        require(limits.get(key) is False, f"unsafe automation limit enabled: {key}")
    require(limits.get("human_approval_required") is True, "human approval must remain mandatory")
    require(limits.get("android_physical_device_gate_required") is True, "Android physical test cannot be automated away")
    require(limits.get("binary_assets_allowed_with_provenance") is True, "SOP cannot pretend all assets are text")

    artifact_states = sop.get("artifact_states", [])
    require(len(artifact_states) == 6 and artifact_states[-1] == "release_ready", "six artifact states changed")
    required_assets = set(sop.get("asset_pipeline", {}).get("required_before_shipping", []))
    require({"origin", "license", "qa", "human_approval", "godot_integration"} <= required_assets, "asset promotion gate incomplete")

    resolution = sop.get("resolution_policy", {})
    require(resolution.get("current_runtime_viewport") == project_viewport(), "SOP runtime resolution does not match project.godot")
    require(resolution.get("runtime_change_requires_dedicated_device_batch") is True, "resolution changes need a device batch")

    tools = {str(item.get("id", "")): item for item in sop.get("toolchain_decisions", [])}
    require(tools.get("pixelorama", {}).get("license") == "MIT", "Pixelorama license changed")
    require(tools.get("penpot", {}).get("license") == "MPL-2.0", "Penpot license changed")
    require(tools.get("tiled", {}).get("native_godot4_tmx_import_assumed") is False, "native TMX import must not be assumed")
    require(tools.get("yarn_spinner_godot_gdscript", {}).get("decision") == "blocked_current_runtime", "alpha Godot 4.6 Yarn integration cannot enter current runtime")

    for relative in sop.get("ci_authorities", []):
        require((ROOT / relative).is_file(), f"missing CI authority: {relative}")
    runtime_ci = (ROOT / ".github/workflows/runtime-audit.yml").read_text(encoding="utf-8")
    hardening_ci = (ROOT / ".github/workflows/full-game-hardening.yml").read_text(encoding="utf-8")
    require("Godot_v4.2.2-stable" in runtime_ci, "runtime audit must pin Godot")
    require("res://tests/runtime_smoke.gd" in runtime_ci, "runtime smoke missing from CI")
    require("android-debug-export" in hardening_ci, "Android export candidate job missing")

    print(
        "[ai-production-sop] ok: existing authorities, six states, toolchain decisions, "
        "asset provenance and human/device gates validated"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
