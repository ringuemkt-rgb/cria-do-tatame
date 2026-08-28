#!/usr/bin/env python3
"""Validate Harmony identity, millisecond phases, HUD input and safety contracts."""

from __future__ import annotations

import argparse
import ast
import copy
import json
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
EXPECTED_GOLD = [
    "grip_de_ferro",
    "baiana",
    "sprawl",
    "corte_joelho",
    "cem_quilos",
    "encerramento_tecnico",
]
POSITIONAL_PHASES = [
    "anticipation",
    "entry",
    "establish_contact",
    "stabilize_control",
    "response",
    "recovery",
]
SUBMISSION_PHASES = [
    "setup",
    "isolation",
    "alignment",
    "control",
    "technical_pressure",
    "tap_or_escape",
    "release_recovery",
]


def _read(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path}: root must be an object")
    return value


def _active_techniques() -> dict[str, dict[str, Any]]:
    payload = _read(ROOT / "data/techniques.json")
    return {
        item["id"]: item
        for item in payload.get("techniques", [])
        if isinstance(item, dict) and item.get("id")
    }


def _runtime_cards() -> dict[str, dict[str, Any]]:
    payload = _read(ROOT / "data/ruan_deck_inicial.json")
    return {
        item["technique_id"]: item
        for item in payload.get("cards", [])
        if isinstance(item, dict) and item.get("technique_id")
    }


def _validate_import_quarantine(errors: list[str]) -> None:
    blocked_modules = {"smpl", "scail"}
    for path in sorted((ROOT / "tools/harmony").glob("*")):
        if not path.is_file() or path.suffix not in {"", ".py"}:
            continue
        try:
            tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
        except SyntaxError as exc:
            errors.append(f"{path.relative_to(ROOT)}: Python syntax error: {exc}")
            continue
        for node in ast.walk(tree):
            names: list[str] = []
            if isinstance(node, ast.Import):
                names = [alias.name for alias in node.names]
            elif isinstance(node, ast.ImportFrom):
                names = [node.module or ""]
            for name in names:
                root_name = name.lower().split(".", 1)[0]
                if root_name in blocked_modules:
                    errors.append(f"{path.relative_to(ROOT)} imports quarantined module {name}")


def validate(contract: dict[str, Any], hub: dict[str, Any]) -> dict[str, Any]:
    errors: list[str] = []
    warnings: list[str] = []
    active_techniques = _active_techniques()
    runtime_cards = _runtime_cards()

    if contract.get("status") != "specified_not_integrated":
        errors.append("contract must remain specified_not_integrated")
    if contract.get("gold_technique_order") != EXPECTED_GOLD:
        errors.append("gold_technique_order must match the active tutorial sequence")
    if contract.get("identity_layers") != ["card", "runtime_ms", "sync_map", "hud", "mastery"]:
        errors.append("identity_layers must declare the five D238 layers")
    decisions = contract.get("decision_register", {})
    for decision_id in ("D234", "D235", "D236", "D237", "D239"):
        if decisions.get(decision_id, {}).get("status") != "missing_body_blocked":
            errors.append(f"{decision_id} must remain missing_body_blocked on this base")
        else:
            warnings.append(f"{decision_id}: body missing; dependent integration remains blocked")
    if decisions.get("D238", {}).get("identity_rule") != "card_runtime_sync_map_hud_mastery_1_to_1_by_technique_id":
        errors.append("D238 identity rule is missing")

    timing = contract.get("timing_policy", {})
    if timing.get("canonical_unit") != "ms" or timing.get("input_buffer_ms") != 100:
        errors.append("D229 requires canonical ms and a 100 ms input buffer")
    if timing.get("difficulty_adjustments_ms") != {"training": 67, "standard": 0, "master": -33}:
        errors.append("D229 difficulty adjustments do not match the governing order")
    preview_duration = timing.get("preview", {}).get("duration_ms")
    if not isinstance(preview_duration, int) or preview_duration <= 0:
        errors.append("preview duration_ms must be a positive integer")

    techniques = contract.get("techniques")
    if not isinstance(techniques, list) or len(techniques) != 6:
        errors.append("contract must contain exactly six gold techniques")
        techniques = []
    seen: set[str] = set()
    for technique in techniques:
        technique_id = technique.get("technique_id")
        prefix = f"technique[{technique_id}]"
        if technique_id not in EXPECTED_GOLD:
            errors.append(f"{prefix}: not in gold sequence")
        if technique_id in seen:
            errors.append(f"{prefix}: duplicate technique_id")
        seen.add(technique_id)
        if technique_id not in active_techniques:
            errors.append(f"{prefix}: ID does not exist in data/techniques.json")
        for layer in contract.get("identity_layers", []):
            if technique.get(layer, {}).get("technique_id") != technique_id:
                errors.append(f"{prefix}: {layer}.technique_id breaks D238 1:1")

        runtime = technique.get("runtime_ms", {})
        for field in ("base_defense_window_ms", "input_buffer_ms"):
            if not isinstance(runtime.get(field), int) or runtime[field] <= 0:
                errors.append(f"{prefix}: {field} must be a positive integer in ms")
        if runtime.get("runtime_authority") is not True:
            errors.append(f"{prefix}: runtime_ms must retain runtime authority")
        active = active_techniques.get(technique_id, {})
        if active:
            source_entry = active.get("entry_state", active.get("estado_entrada"))
            source_success = active.get("exit_state", active.get("estado_saida"))
            source_cost = active.get("cost", active.get("custo", {}))
            expected_cost = {
                "gas": source_cost.get("gas", active.get("gas_cost", 0)),
                "focus": source_cost.get("focus", source_cost.get("foco", active.get("focus_cost", 0))),
            }
            if runtime.get("entry_state") != source_entry or runtime.get("success_state") != source_success:
                errors.append(f"{prefix}: runtime states diverge from data/techniques.json")
            if runtime.get("cost") != expected_cost:
                errors.append(f"{prefix}: runtime cost diverges from data/techniques.json")
            source_window_ms = round(float(active.get("defense_window", 0.25)) * 1000)
            if runtime.get("base_defense_window_ms") != source_window_ms:
                errors.append(f"{prefix}: defense window diverges from active resolver fallback/source")

        card = technique.get("card", {})
        source_card = runtime_cards.get(technique_id)
        if source_card is None:
            if card.get("runtime_card_id") is not None or card.get("binding_status") != "missing_runtime_card_blocked":
                errors.append(f"{prefix}: absent runtime card must remain explicitly blocked")
        else:
            if card.get("runtime_card_id") != source_card.get("id") or card.get("binding_status") != "existing":
                errors.append(f"{prefix}: card binding diverges from data/ruan_deck_inicial.json")

        sync_map = technique.get("sync_map", {})
        if sync_map.get("runtime_authority") is not False:
            errors.append(f"{prefix}: sync_map cannot claim runtime authority")
        if not sync_map.get("attacker_id") or not sync_map.get("defender_id"):
            errors.append(f"{prefix}: paired actors are required")
        if sync_map.get("attacker_id") == sync_map.get("defender_id"):
            errors.append(f"{prefix}: attacker and defender must differ")
        origin = sync_map.get("shared_origin", {})
        if not all(isinstance(origin.get(axis), int) for axis in ("x", "y")):
            errors.append(f"{prefix}: integer shared_origin is required")
        profile = sync_map.get("profile")
        expected_phases = SUBMISSION_PHASES if profile == "submission" else POSITIONAL_PHASES
        phases = sync_map.get("phases", [])
        if [phase.get("id") for phase in phases] != expected_phases:
            errors.append(f"{prefix}: phases do not match {profile} profile")
        cursor = 0
        for phase in phases:
            start = phase.get("start_ms")
            end = phase.get("end_ms")
            if not isinstance(start, int) or not isinstance(end, int):
                errors.append(f"{prefix}: phase times must be integer ms")
                continue
            if start != cursor or end <= start:
                errors.append(f"{prefix}: phase timeline must be contiguous and increasing")
            cursor = end
        if preview_duration is not None and cursor != preview_duration:
            errors.append(f"{prefix}: phase timeline must end at preview duration")
        branches = sync_map.get("branches", [])
        if len(branches) < 3:
            errors.append(f"{prefix}: success/defense/recovery branches are required")
        for contact in sync_map.get("contacts", []):
            start = contact.get("start_ms")
            end = contact.get("end_ms")
            if not isinstance(start, int) or not isinstance(end, int) or start < 0 or end <= start:
                errors.append(f"{prefix}: invalid contact interval")
            if end > preview_duration:
                errors.append(f"{prefix}: contact exceeds preview duration")
            if contact.get("review") != "pending_human_BJJ":
                errors.append(f"{prefix}: every contact must remain pending_human_BJJ")

        if technique_id == "encerramento_tecnico":
            if runtime.get("submission_defense") is not True or runtime.get("tap_priority") != 1:
                errors.append(f"{prefix}: submission runtime must expose sovereign TAP")
            branch_names = set(sync_map.get("branches", []))
            if not {"tap_release", "escape_release", "referee_release"}.issubset(branch_names):
                errors.append(f"{prefix}: all safe submission exits are required")
            interrupts = {item.get("id"): item for item in sync_map.get("interrupt_windows", [])}
            if interrupts.get("tap_sovereign", {}).get("priority") != 1:
                errors.append(f"{prefix}: tap_sovereign interrupt must have priority 1")

    if seen != set(EXPECTED_GOLD):
        errors.append("technique set does not match the six gold IDs")

    if hub.get("status") != "specified_not_integrated":
        errors.append("combat hub must remain specified_not_integrated")
    priority = [item.get("action") for item in hub.get("in_fight", {}).get("input_priority", [])]
    if priority != ["tap", "pause_menu", "defense", "contextual"]:
        errors.append("D231 input priority is incorrect")
    gamepad = hub.get("in_fight", {}).get("gamepad", {})
    expected_bindings = {
        "A": "contextual_1",
        "X": "contextual_3",
        "Y": "contextual_4",
        "RB": "contextual_5",
        "RT": "defense",
        "LB": "special",
        "START": "pause_menu",
    }
    for key, action in expected_bindings.items():
        if gamepad.get(key, {}).get("action") != action:
            errors.append(f"D230 binding {key} must be {action}")
    b_binding = gamepad.get("B", {})
    if b_binding.get("default_action") != "contextual_2" or b_binding.get("submission_defense_action") != "tap":
        errors.append("D230 B contextual/TAP context swap is incorrect")
    tap = hub.get("in_fight", {}).get("tap", {})
    if tap.get("sovereign") is not True or "animation_event" not in tap.get("cannot_be_consumed_by", []):
        errors.append("TAP must be sovereign over runtime and animation events")
    dead_input = hub.get("in_fight", {}).get("no_dead_input", {})
    if dead_input.get("required") is not True or dead_input.get("silent_discard_forbidden") is not True:
        errors.append("no-dead-input contract is missing")

    _validate_import_quarantine(errors)
    return {
        "schema_version": "1.0.0",
        "status": "PASS" if not errors else "FAIL",
        "checks": {
            "gold_techniques": len(techniques),
            "identity_layers_per_technique": 5,
            "canonical_unit": "ms",
            "tap_sovereign": tap.get("sovereign") is True,
        },
        "errors": errors,
        "warnings": warnings,
    }


def _self_test(contract: dict[str, Any], hub: dict[str, Any]) -> None:
    good = validate(contract, hub)
    if good["status"] != "PASS":
        raise AssertionError(f"real contract failed: {good['errors']}")
    bad = copy.deepcopy(contract)
    bad["techniques"][0]["hud"]["technique_id"] = "wrong"
    report = validate(bad, hub)
    if report["status"] != "FAIL" or not any("D238" in item for item in report["errors"]):
        raise AssertionError("D238 adversarial mutation was not rejected")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("contract", nargs="?", type=Path, default=ROOT / "data/combat/harmony_contract_v1.json")
    parser.add_argument("hub", nargs="?", type=Path, default=ROOT / "data/ux/combat_hub_v1.json")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    try:
        contract = _read(args.contract)
        hub = _read(args.hub)
        if args.self_test:
            _self_test(contract, hub)
            print(json.dumps({"tool": "phase_check", "self_test": "PASS"}))
            return 0
        report = validate(contract, hub)
    except (OSError, ValueError, json.JSONDecodeError, AssertionError) as exc:
        print(json.dumps({"tool": "phase_check", "status": "FAIL", "error": str(exc)}))
        return 1
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if report["status"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
