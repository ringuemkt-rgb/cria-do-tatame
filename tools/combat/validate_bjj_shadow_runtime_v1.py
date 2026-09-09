#!/usr/bin/env python3
"""Validate the non-authoritative CombatManager -> BJJ reducer shadow runtime."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
MAP_PATH = ROOT / "data/combat/combat_manager_bjj_shadow_map_v1.json"
ADAPTER_PATH = ROOT / "src/combat/CombatManagerBJJShadowAdapterV1.gd"
OBSERVER_PATH = ROOT / "src/autoloads/BJJShadowRuntimeObserver.gd"
PROJECT_PATH = ROOT / "project.godot"
SMOKE_PATH = ROOT / "tests/combat_manager_bjj_shadow_smoke.gd"

REQUIRED_CLASSIFICATIONS = {
    "MATCH",
    "KNOWN_SEMANTIC_DELTA",
    "OUTCOME_DIVERGENCE",
    "UNMAPPED",
    "AMBIGUOUS",
}
REQUIRED_AUTHORITY_FALSE = {
    "shadow_may_change_live_combat",
    "shadow_may_award_score",
    "shadow_may_finish_combat",
}
REQUIRED_ACTION_FIELDS = {
    "canonical",
    "confidence",
    "legacy_from",
    "legacy_to",
    "canonical_from",
    "canonical_to",
}


def fail(message: str) -> None:
    print(f"BJJ_SHADOW_FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"{path.relative_to(ROOT)} invalid: {exc}")
    if not isinstance(value, dict):
        fail(f"{path.relative_to(ROOT)} must contain a JSON object")
    return value


def require_file(path: Path) -> str:
    if not path.is_file():
        fail(f"missing required file: {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8")


def validate() -> dict[str, Any]:
    mapping = load_json(MAP_PATH)
    if mapping.get("$schema") != "cria.combat_manager_bjj_shadow_map.v1":
        fail("unexpected shadow-map schema")
    if mapping.get("status") != "SHADOW_ONLY_NON_AUTHORITATIVE":
        fail("shadow map must remain SHADOW_ONLY_NON_AUTHORITATIVE")
    if mapping.get("shipping") is not False:
        fail("shadow map shipping must remain false")

    authority = mapping.get("authority")
    if not isinstance(authority, dict):
        fail("authority block missing")
    for field in REQUIRED_AUTHORITY_FALSE:
        if authority.get(field) is not False:
            fail(f"authority.{field} must be false")

    state_map = mapping.get("legacy_state_map")
    action_map = mapping.get("legacy_action_map")
    if not isinstance(state_map, dict) or not state_map:
        fail("legacy_state_map missing")
    if not isinstance(action_map, dict) or not action_map:
        fail("legacy_action_map missing")

    if state_map.get("PLAYER_STANDING_NEUTRAL", {}).get("canonical") != "standing_neutral":
        fail("standing neutral must map to standing_neutral")

    ambiguous_count = 0
    for legacy_state, row in state_map.items():
        if not isinstance(row, dict):
            fail(f"legacy state row is not an object: {legacy_state}")
        confidence = str(row.get("confidence", ""))
        if confidence == "AMBIGUOUS":
            ambiguous_count += 1
            if row.get("canonical") is not None:
                fail(f"ambiguous legacy state must not guess canonical state: {legacy_state}")
            if not str(row.get("reason", "")).strip():
                fail(f"ambiguous legacy state must explain uncertainty: {legacy_state}")

    semantic_delta_count = 0
    for legacy_action, row in action_map.items():
        if not isinstance(row, dict):
            fail(f"legacy action row is not an object: {legacy_action}")
        missing = sorted(REQUIRED_ACTION_FIELDS - set(row))
        if missing:
            fail(f"legacy action {legacy_action} missing fields: {missing}")
        canonical = str(row.get("canonical", ""))
        if not canonical:
            fail(f"mapped legacy action {legacy_action} has empty canonical id")
        if str(row.get("known_delta", "")).strip():
            semantic_delta_count += 1

    policy = mapping.get("unmapped_policy")
    if not isinstance(policy, dict):
        fail("unmapped_policy missing")
    if policy.get("legacy_action_without_verified_canonical_edge") != "REPORT_UNMAPPED_AND_DO_NOT_GUESS":
        fail("unmapped legacy actions must fail closed")
    if policy.get("ambiguous_legacy_state") != "REPORT_AMBIGUOUS_AND_DO_NOT_SYNC":
        fail("ambiguous legacy states must fail closed")
    if policy.get("semantic_delta_blocks_authority_promotion") is not True:
        fail("semantic deltas must block authority promotion")

    adapter = require_file(ADAPTER_PATH)
    observer = require_file(OBSERVER_PATH)
    project = require_file(PROJECT_PATH)
    smoke = require_file(SMOKE_PATH)

    required_adapter_tokens = [
        'return {"ok": false, "error": "legacy_state_ambiguous"',
        '"policy": "REPORT_UNMAPPED_AND_DO_NOT_GUESS"',
        '"authoritative": false',
        "reducer.reduce(shadow_state, action)",
    ]
    for token in required_adapter_tokens:
        if token not in adapter:
            fail(f"adapter missing fail-closed/runtime token: {token}")

    forbidden_adapter_tokens = [
        "CombatManager.apply_player_action",
        "CombatManager.finish_combat",
        "SignalBus.technique_resolved.emit",
    ]
    for token in forbidden_adapter_tokens:
        if token in adapter:
            fail(f"shadow adapter must not mutate live combat: {token}")

    if 'BJJShadowRuntimeObserver="*res://src/autoloads/BJJShadowRuntimeObserver.gd"' not in project:
        fail("project.godot must register BJJShadowRuntimeObserver autoload")
    if '"classification": "UNMAPPED"' not in observer:
        fail("observer must default comparisons to UNMAPPED")
    for classification in ("OUTCOME_DIVERGENCE", "KNOWN_SEMANTIC_DELTA", "MATCH"):
        if classification not in observer:
            fail(f"observer missing classification: {classification}")
    if "BJJ_SHADOW_SMOKE PASS" not in smoke:
        fail("dedicated Godot smoke marker missing")

    return {
        "ok": True,
        "ambiguous_states": ambiguous_count,
        "mapped_actions": len(action_map),
        "semantic_deltas": semantic_delta_count,
        "required_classifications": sorted(REQUIRED_CLASSIFICATIONS),
        "authoritative": False,
        "shipping": False,
    }


def main() -> int:
    report = validate()
    print("BJJ_SHADOW_PASS " + json.dumps(report, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
