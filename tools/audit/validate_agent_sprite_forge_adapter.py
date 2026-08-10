#!/usr/bin/env python3
"""Validate the pinned, candidate-only Agent Sprite Forge integration."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PROFILE_PATH = ROOT / "data" / "production" / "agent_sprite_forge_profile_v01.json"
SOP_PATH = ROOT / "data" / "production" / "ai_production_sop_v01.json"
SCHEMA_PATH = ROOT / "schemas" / "agent_sprite_forge_profile.schema.json"
ADAPTER_PATH = ROOT / "tools" / "visual" / "agent_sprite_forge_adapter.py"
PINNED_COMMIT = "64fd0b57d3f2ae117ef0a95e4c2decc25b4c9dd2"


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise AssertionError(f"{path.relative_to(ROOT)} must contain an object")
    return value


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def load_adapter():
    spec = importlib.util.spec_from_file_location("agent_sprite_forge_adapter", ADAPTER_PATH)
    require(spec is not None and spec.loader is not None, "cannot load adapter")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main() -> int:
    profile = load_json(PROFILE_PATH)
    sop = load_json(SOP_PATH)
    schema = load_json(SCHEMA_PATH)
    adapter = load_adapter()

    require(profile.get("$schema") == "agent_sprite_forge_profile_v1", "invalid profile schema")
    require(profile.get("status") == "approved_candidate_postprocessor", "unsafe adoption status")
    source = profile.get("source", {})
    require(source.get("pinned_commit") == PINNED_COMMIT, "upstream commit is not pinned")
    require(source.get("license") == "MIT", "upstream license decision changed")
    for key in ["license_sha256", "requirements_sha256", "entrypoint_sha256"]:
        value = str(source.get(key, ""))
        require(len(value) == 64 and all(char in "0123456789abcdef" for char in value), f"invalid {key}")

    dependency = profile.get("dependency_policy", {})
    require(dependency.get("runtime_dependency") is False, "external processor cannot enter runtime")
    require(dependency.get("runtime_network_required") is False, "external processor cannot add runtime network")
    require(dependency.get("vendored_into_game") is False, "external processor must remain outside game tree")
    require(dependency.get("automatic_global_skill_install") is False, "global skill install cannot be automatic")

    blocked = set(profile.get("adoption", {}).get("blocked", []))
    require("shipping_asset_auto_promotion" in blocked, "automatic shipping promotion must stay blocked")
    require("paired_grappling_shipping_export" in blocked, "paired grappling shipping export is unsupported")
    require("automatic_sync_map_generation" in blocked, "upstream does not create Cria sync maps")
    require("default_prompt_builder_for_cria_canon" in blocked, "generic upstream prompts conflict with canon")
    require("video_generation_in_codex" in blocked, "Codex has no upstream image-to-video generator")

    compatibility = profile.get("compatibility", {})
    require(compatibility.get("default_prompt_builder_used") is False, "upstream prompt builder cannot override Cria briefs")
    paired = compatibility.get("paired_grappling", {})
    require(paired.get("shipping_supported") is False, "paired shipping support was overstated")
    missing = set(paired.get("missing_contracts", []))
    require({"separate_attacker_sheet", "separate_defender_sheet", "shared_pivot", "sync_map", "human_bjj_review"} <= missing, "paired gaps are incomplete")

    execution = profile.get("execution", {})
    require(execution.get("adapter") == "tools/visual/agent_sprite_forge_adapter.py", "wrong adapter path")
    require(execution.get("candidate_output_root") == "production/candidates/agent_sprite_forge", "candidate output escaped production root")
    require(execution.get("candidate_state") == "candidate", "external output must start as candidate")
    require(execution.get("promotion_allowed") is False, "adapter cannot promote output")
    require(execution.get("raw_source_rights_required") is True, "source rights gate is mandatory")

    tools = {str(item.get("id", "")): item for item in sop.get("toolchain_decisions", [])}
    decision = tools.get("agent_sprite_forge", {})
    require(decision.get("pinned_commit") == PINNED_COMMIT, "SOP and profile pins diverged")
    require(decision.get("decision") == "approved_candidate_postprocessor", "SOP adoption is too broad")
    require(decision.get("runtime_dependency") is False, "SOP introduced a runtime dependency")

    require(schema.get("$id") == "agent_sprite_forge_profile.schema.json", "wrong JSON schema")
    require(ADAPTER_PATH.is_file(), "adapter is missing")
    require(set(adapter.PROCESS_PROFILES) == {"character_idle", "character_walk", "effect_impact", "effect_projectile", "paired_composite_preview"}, "adapter profiles changed without review")

    candidate = adapter.candidate_output_dir("vertical_slice_01", "ruan_idle")
    require(str(candidate).endswith("production/candidates/agent_sprite_forge/vertical_slice_01/ruan_idle"), "candidate path is not deterministic")
    try:
        adapter.candidate_output_dir("../escape", "ruan_idle")
    except adapter.AdapterError:
        pass
    else:
        raise AssertionError("unsafe candidate path was accepted")

    intake = adapter.intake_payload(
        "paired_composite_preview",
        ROOT / "tests" / "fixture.png",
        candidate,
        {"commit": PINNED_COMMIT, "license": "MIT"},
    )
    require(intake.get("artifact_state") == "candidate", "intake promoted external output")
    require(intake.get("promotion_allowed") is False, "intake can promote output")
    require(intake.get("paired_grappling_shipping_supported") is False, "composite preview became paired shipping art")
    reviews = set(intake.get("required_reviews", []))
    require({"human_bjj_review", "attacker_defender_split", "shared_pivot_and_sync_map"} <= reviews, "paired review gates missing")

    adapter_source = ADAPTER_PATH.read_text(encoding="utf-8")
    require("shell=True" not in adapter_source, "adapter cannot execute through a shell")
    require("subprocess.run(command, check=True)" in adapter_source, "adapter execution must fail closed")
    for flag in ["--shared-scale", "--scale-strategy", "preserve", "--strict-qc", "--reject-edge-touch"]:
        require(flag in adapter_source, f"required processor flag missing: {flag}")

    tests = profile.get("upstream_test_snapshot", {})
    require(tests.get("tests_run") == 15 and tests.get("result") == "pass", "upstream test evidence changed")
    print(
        "[agent-sprite-forge] ok: MIT pin, external-only adapter, candidate root, "
        "strict processor flags and paired-grappling limits validated"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
