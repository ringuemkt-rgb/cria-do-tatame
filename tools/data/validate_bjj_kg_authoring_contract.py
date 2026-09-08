#!/usr/bin/env python3
"""Validate BJJ KG authoring/rules authority before a full graph is promoted."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONTRACT = ROOT / "data/combat/bjj_kg_authoring_contract_v1.json"
RULES = ROOT / "data/combat/bjj_rulesets_verified_v1.json"


def load(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError(f"{path}: root must be object")
    return value


def validate(contract: dict, rules: dict) -> list[str]:
    errors: list[str] = []

    if contract.get("runtime_authority") is not False:
        errors.append("F1 authoring contract cannot have runtime authority")
    if contract.get("calibration_authority") is not False:
        errors.append("F1 authoring contract cannot have calibration authority")

    success = contract.get("success_model", {})
    if success.get("authoring_prior_allowed") is not True:
        errors.append("authoring priors should remain allowed but explicitly uncalibrated")
    if success.get("authoring_prior_status") != "UNCALIBRATED_EXPERT_HEURISTIC":
        errors.append("authoring prior status must remain UNCALIBRATED_EXPERT_HEURISTIC")
    if success.get("empirical_success_default", "missing") is not None:
        errors.append("empirical_success must default to null before F3")
    if success.get("rl_output_is_empirical_frequency") is not False:
        errors.append("RL output must never be labeled empirical real-world frequency")

    perspective = contract.get("perspective_model", {})
    required = set(perspective.get("required_edge_fields", []))
    if not {"actor_role_from", "actor_role_to"}.issubset(required):
        errors.append("actor-relative edges must require actor_role_from and actor_role_to")

    scoring = contract.get("scoring_model", {})
    if scoring.get("authority_file") != "data/combat/bjj_rulesets_verified_v1.json":
        errors.append("BJJ ruleset authority file mismatch")
    if scoring.get("forbid_unversioned_pts_tuple_as_authority") is not True:
        errors.append("unversioned pts tuples cannot be scoring authority")

    legality = contract.get("legality_model", {})
    if legality.get("gi_nogi_flags_are_sufficient") is not False:
        errors.append("gi/nogi flags alone are insufficient for technique legality")

    rulesets = rules.get("rulesets", {})
    ibjjf = rulesets.get("ibjjf_v6", {})
    adcc = rulesets.get("adcc_championship_current", {})
    clandestine = rulesets.get("clandestine_cria_v1", {})

    ibjjf_points = ibjjf.get("points", {})
    expected_ibjjf = {
        "takedown": 2,
        "sweep": 2,
        "knee_on_belly": 2,
        "guard_pass": 3,
        "mount": 4,
        "back_control": 4,
    }
    for key, expected in expected_ibjjf.items():
        if ibjjf_points.get(key) != expected:
            errors.append(f"IBJJF {key} must be {expected}")

    adcc_points = adcc.get("points", {})
    expected_adcc = {
        "takedown_to_guard_or_half": 2,
        "clean_takedown_past_guard": 4,
        "sweep_to_guard_or_half": 2,
        "clean_sweep_past_guard": 4,
        "knee_on_stomach": 2,
        "guard_pass": 3,
        "mount": 2,
        "back_mount_hooks_or_body_triangle": 3,
    }
    for key, expected in expected_adcc.items():
        if adcc_points.get(key) != expected:
            errors.append(f"ADCC {key} must be {expected}")
    if adcc.get("stabilization_seconds") != 3:
        errors.append("ADCC scoring stabilization must be 3 seconds")

    if clandestine.get("striking_or_ko_runtime_authority") is not False:
        errors.append("clandestine striking/KO cannot gain runtime authority in this F1 contract")
    if clandestine.get("authority") != "game_design_only":
        errors.append("clandestine ruleset must remain game_design_only")

    return errors


def main() -> int:
    try:
        errors = validate(load(CONTRACT), load(RULES))
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"FAIL BJJ KG authoring contract: {exc}")
        return 1

    if errors:
        for error in errors:
            print("FAIL", error)
        print(f"BJJ KG authoring contract failed: {len(errors)} error(s)")
        return 1

    print("BJJ KG authoring contract PASS: rules/version/calibration authority locked; full graph not implied")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
