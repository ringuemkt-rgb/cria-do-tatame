#!/usr/bin/env python3
"""Fail-closed static accessibility checks for the slice input contract."""
from __future__ import annotations

import argparse
import json
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CONTROLS = ROOT / "data/ux/controls_slice_v1.json"
EXPECTED_PRIORITY = ["tap", "pause_or_menu", "defensive_input", "contextual_action"]
EXPECTED_DEVICES = {"touch", "gamepad", "keyboard"}
EXPECTED_LAYERS = {"mapa", "rua", "combate"}
EXPECTED_COMBAT_ACTIONS = {
    "move", "context_1", "context_2", "context_3", "context_4", "context_5",
    "defense", "special", "tap", "pause",
}


def load_contract(path: Path) -> dict:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError("o contrato de controles deve ser um objeto JSON")
    return value


def validate(contract: dict) -> list[dict[str, str]]:
    findings: list[dict[str, str]] = []
    timing = contract.get("timing", {})
    rules = contract.get("rules", {})
    layers = contract.get("layers", {})

    if timing.get("canonical_unit") != "ms" or timing.get("input_buffer_ms") != 100:
        findings.append({"code": "TIMING_CONTRACT_INVALID"})
    if contract.get("priority") != EXPECTED_PRIORITY:
        findings.append({"code": "INPUT_PRIORITY_INVALID"})
    if rules.get("no_dead_input") is not True:
        findings.append({"code": "DEAD_INPUT_POLICY_MISSING"})
    if rules.get("tap_sovereign") is not True:
        findings.append({"code": "TAP_SOVEREIGN_MISSING"})
    if set(rules.get("remappable_devices", [])) != EXPECTED_DEVICES:
        findings.append({"code": "REMAP_DEVICE_COVERAGE_INVALID"})
    if set(layers) != EXPECTED_LAYERS:
        findings.append({"code": "INPUT_LAYERS_INVALID"})

    for layer_name, actions in layers.items():
        if not isinstance(actions, list) or not actions:
            findings.append({"code": "EMPTY_LAYER", "layer": layer_name})
            continue
        seen: set[str] = set()
        for action in actions:
            action_id = action.get("id", "")
            if not action_id or action_id in seen:
                findings.append({"code": "ACTION_ID_INVALID", "layer": layer_name, "action": action_id})
            seen.add(action_id)
            for device in EXPECTED_DEVICES:
                if not action.get(device):
                    findings.append({"code": "DEVICE_BINDING_MISSING", "layer": layer_name, "action": action_id, "device": device})
            feedback = action.get("feedback", {})
            for channel in ("visual", "audio", "haptic"):
                if channel not in feedback or feedback[channel] == "":
                    findings.append({"code": "FEEDBACK_CHANNEL_MISSING", "layer": layer_name, "action": action_id, "channel": channel})

    combat = {item.get("id"): item for item in layers.get("combate", [])}
    if set(combat) != EXPECTED_COMBAT_ACTIONS:
        findings.append({"code": "COMBAT_ACTION_SET_INVALID"})
    tap = combat.get("tap", {})
    if tap.get("priority") != "tap" or tap.get("enabled_when") != "submission_defense=true":
        findings.append({"code": "TAP_CONTEXT_INVALID"})
    if tap.get("result") != "immediate_release" or not tap.get("ui_context_swap"):
        findings.append({"code": "TAP_RELEASE_INVALID"})
    context_2 = combat.get("context_2", {})
    if context_2.get("gamepad") != "B" or context_2.get("enabled_when") != "submission_defense=false":
        findings.append({"code": "B_CONTEXT_SWAP_INVALID"})
    return findings


def self_test() -> None:
    clean = load_contract(DEFAULT_CONTROLS)
    assert validate(clean) == []
    broken = json.loads(json.dumps(clean))
    broken["rules"]["tap_sovereign"] = False
    broken["layers"]["combate"][-2]["result"] = "delayed"
    codes = {item["code"] for item in validate(broken)}
    assert {"TAP_SOVEREIGN_MISSING", "TAP_RELEASE_INVALID"} <= codes
    with tempfile.TemporaryDirectory(prefix="accessibility-check-") as temp:
        sample = Path(temp) / "controls.json"
        sample.write_text(json.dumps(clean), encoding="utf-8")
        assert validate(load_contract(sample)) == []
    print(json.dumps({"tool": "accessibility_checks", "self_test": "PASS"}))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--controls", type=Path, default=DEFAULT_CONTROLS)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return 0
    findings = validate(load_contract(args.controls))
    report = {"gate": "SLICE_ACCESSIBILITY", "status": "PASS" if not findings else "BLOCKED", "findings": findings}
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if not findings else 1


if __name__ == "__main__":
    sys.exit(main())
