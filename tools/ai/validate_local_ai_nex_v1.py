#!/usr/bin/env python3
"""Fail-closed contract gate for the optional Nex-N2.5 local dialogue slice."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
CONFIG = ROOT / "data/ai/local_ai_config_v01.json"
PROFILE = ROOT / "data/ai/nex_n25_dialogue_profile_v1.json"
CANON = ROOT / "data/production/canon_contract_v4_1.json"
MANAGER = ROOT / "src/autoloads/LocalAIManager.gd"
TOOLS = ROOT / "src/ai/LocalAIReadOnlyTools.gd"
DOC = ROOT / "docs/LOCAL_AI_ANDROID.md"

HEX40 = re.compile(r"^[0-9a-f]{40}$")
HEX64 = re.compile(r"^[0-9a-f]{64}$")


def read_json(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path.relative_to(ROOT)} root must be object")
    return value


def require(condition: bool, message: str, errors: list[str]) -> None:
    if not condition:
        errors.append(message)


def main() -> int:
    errors: list[str] = []
    for path in (CONFIG, PROFILE, CANON, MANAGER, TOOLS, DOC):
        if not path.is_file():
            errors.append(f"missing required file: {path.relative_to(ROOT)}")
    if errors:
        print(json.dumps({"ok": False, "errors": errors}, ensure_ascii=False, indent=2))
        return 1

    config = read_json(CONFIG)
    profile = read_json(PROFILE)
    canon = read_json(CANON)
    manager = MANAGER.read_text(encoding="utf-8")
    tools = TOOLS.read_text(encoding="utf-8")
    doc = DOC.read_text(encoding="utf-8")

    policy = config.get("runtime_policy", {})
    require(policy.get("enabled_by_default") is False, "network AI must remain disabled by default", errors)
    require(policy.get("combat_llm_allowed") is False, "LLM must remain forbidden in combat", errors)
    require(policy.get("apk_requires_llm") is False, "APK must not require LLM", errors)
    require(policy.get("fallback_required") is True, "offline fallback must remain mandatory", errors)
    require(policy.get("network_default") is False, "network must remain opt-in", errors)

    backend = config.get("backends", {}).get("nex_n25_ollama", {})
    require(backend.get("type") == "ollama_http", "Nex backend must use ollama_http", errors)
    require(
        backend.get("model") == "hf.co/abenzerps/Nex-N2.5-mini-GGUF:Q4_K_M",
        "Nex backend model reference changed",
        errors,
    )
    require(backend.get("supports_tools") is True, "Nex backend must declare tool support", errors)
    require(1 <= int(backend.get("max_tool_rounds", 0)) <= 4, "tool rounds must be bounded to 1..4", errors)
    require(0 < int(backend.get("num_ctx", 0)) <= 32768, "default Nex context must be explicitly bounded", errors)

    require(profile.get("runtime_authority") is False, "Nex cannot be runtime authority", errors)
    require(profile.get("shipping") is False, "Nex profile cannot be shipping by default", errors)
    require(profile.get("critical_gameplay_dependency") is False, "Nex cannot be a critical gameplay dependency", errors)
    quant = profile.get("quantized_runtime", {})
    require(quant.get("license") == "Apache-2.0", "quantized runtime license must be Apache-2.0", errors)
    require(bool(HEX40.fullmatch(str(quant.get("revision", "")))), "quantized revision must be immutable SHA", errors)
    require(bool(HEX64.fullmatch(str(quant.get("artifact_sha256", "")))), "Q4_K_M artifact SHA-256 invalid", errors)

    allowed = set(profile.get("integration", {}).get("allowed_tools", []))
    require(
        allowed == {"canon_lookup", "scene_state_get", "progression_summary_get"},
        f"unexpected Nex tool allowlist: {sorted(allowed)}",
        errors,
    )
    require(profile.get("integration", {}).get("state_mutation_by_model") is False, "model state mutation must remain false", errors)
    require(profile.get("integration", {}).get("combat_use") is False, "Nex combat use must remain false", errors)

    factions = {
        str(item.get("id", "")): str(item.get("display_name", ""))
        for item in canon.get("active_factions_future_domain", [])
        if isinstance(item, dict)
    }
    require(factions.get("ALE") == "Os Aleluiado", "ALE display name must follow D10", errors)
    require(factions.get("NTM") == "Nós Tem Um Molho", "NTM display name must follow canon v4.1", errors)

    for required_fragment in (
        'preload("res://src/ai/LocalAIReadOnlyTools.gd")',
        '"tool_calls"',
        '"tool_name"',
        'payload["tools"]',
        "max_tool_rounds",
        "tool_round_limit",
    ):
        require(required_fragment in manager, f"LocalAIManager missing tool-call contract: {required_fragment}", errors)

    for required_fragment in (
        'CANON_CONTRACT_PATH := "res://data/production/canon_contract_v4_1.json"',
        '"canon_lookup"',
        '"scene_state_get"',
        '"progression_summary_get"',
        '"active_factions_future_domain"',
    ):
        require(required_fragment in tools, f"read-only tool layer missing: {required_fragment}", errors)

    forbidden_mutation_fragments = (
        "record_event(",
        "save_game(",
        "change_scene",
        ".emit(",
        "apply_player_action",
        "finish_combat(",
        "skill_points =",
        "money =",
        "reputation =",
    )
    for fragment in forbidden_mutation_fragments:
        require(fragment not in tools, f"read-only tool layer contains mutation primitive: {fragment}", errors)

    stale_fragments = set(config.get("prompt_rules", {}).get("forbidden_output_fragments", []))
    require("os aleluiados" in stale_fragments, "stale ALE output must be rejected", errors)
    require("nós tem o molho" in stale_fragments, "stale NTM output must be rejected", errors)

    require(
        "ollama run hf.co/abenzerps/Nex-N2.5-mini-GGUF:Q4_K_M" in doc,
        "Nex operator command missing from LOCAL_AI_ANDROID.md",
        errors,
    )
    require(
        'configure_backend("nex_n25_ollama")' in doc,
        "Nex activation example missing from LOCAL_AI_ANDROID.md",
        errors,
    )

    result = {"ok": not errors, "errors": errors, "checked_files": 6}
    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
