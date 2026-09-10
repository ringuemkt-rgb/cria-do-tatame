#!/usr/bin/env python3
"""Fail-closed structural validator for Grappling Fatigue + F3 V1."""

from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
FATIGUE_CONTRACT = ROOT / "data/combat/grappling_fatigue_contract_v1.json"
FATIGUE_PROFILES = ROOT / "data/combat/grappling_fatigue_profiles_slice_v1.json"
F3_CONTRACT = ROOT / "data/combat/f3_calibration_contract_v1.json"
F3_LEDGER = ROOT / "data/research/f3_observation_ledger_v1.json"
GOLDEN = ROOT / "data/combat/golden_chain_ruan_davi_v1.json"
GRAPH = ROOT / "data/bjj/bjj_kg_slice_ruan_davi_v1.json"
RUNTIME = ROOT / "src/combat/CriaGrapplingRuntimeV1.gd"
FATIGUE_RUNTIME = ROOT / "src/combat/GrapplingFatigueModelV1.gd"
CALIBRATOR = ROOT / "tools/combat/f3_calibrate_bjj_v1.py"

EXPECTED_DIMENSIONS = [
    "systemic",
    "forearm_grip",
    "upper_body_isometric",
    "trunk_isometric",
    "lower_body",
    "recovery_debt",
]
EXPECTED_LEVELS = {"UNKNOWN", "LOW", "MODERATE", "HIGH", "VERY_HIGH"}


def fail(message: str) -> None:
    print(f"GRAPPLING_FATIGUE_F3_FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def load(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"{path.relative_to(ROOT)} invalid: {exc}")
    if not isinstance(value, dict):
        fail(f"{path.relative_to(ROOT)} must contain an object")
    return value


def load_calibrator():
    spec = importlib.util.spec_from_file_location("f3_calibrate_bjj_v1", CALIBRATOR)
    if spec is None or spec.loader is None:
        fail("cannot import F3 calibrator")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def golden_ids(golden: dict[str, Any]) -> set[str]:
    used: set[str] = set()
    for row in golden.get("success_chain", []):
        if isinstance(row, dict):
            used.add(str(row.get("technique_id", "")))
    for row in golden.get("defense_branches", []):
        if isinstance(row, dict):
            used.add(str(row.get("attack_id", "")))
            used.add(str(row.get("counter_id", "")))
    for row in golden.get("alternate_branches", []):
        if isinstance(row, dict):
            used.add(str(row.get("technique_id", "")))
    return {item for item in used if item}


def validate() -> dict[str, Any]:
    fatigue = load(FATIGUE_CONTRACT)
    profiles = load(FATIGUE_PROFILES)
    f3 = load(F3_CONTRACT)
    ledger = load(F3_LEDGER)
    golden = load(GOLDEN)
    graph = load(GRAPH)

    if fatigue.get("status") != "SHADOW_CALIBRATION_ONLY" or fatigue.get("shipping") is not False:
        fail("fatigue V1 must remain shadow-only and shipping=false")
    if fatigue.get("dimensions") != EXPECTED_DIMENSIONS:
        fail("fatigue dimensions drifted")

    authority = fatigue.get("authority", {})
    for flag in (
        "fatigue_may_change_position",
        "fatigue_may_change_score",
        "fatigue_may_change_winner",
        "fatigue_may_change_rng",
        "fatigue_may_modify_success_before_f3_approval",
    ):
        if authority.get(flag) is not False:
            fail(f"fatigue authority boundary relaxed: {flag}")

    scale = fatigue.get("load_scale", {})
    if set(scale) != EXPECTED_LEVELS:
        fail("fatigue qualitative load scale must remain canonical")
    if scale.get("UNKNOWN") is not None:
        fail("UNKNOWN load must not be imputed")
    for name in EXPECTED_LEVELS - {"UNKNOWN"}:
        value = scale.get(name)
        if not isinstance(value, (int, float)) or isinstance(value, bool) or not 0 <= float(value) <= 1:
            fail(f"invalid shadow load scalar: {name}")

    evidence = {str(row.get("id")): row for row in fatigue.get("evidence_basis", []) if isinstance(row, dict)}
    for source_id in ("pmid_39467539", "pmid_25559902"):
        if source_id not in evidence:
            fail(f"missing fatigue evidence source: {source_id}")
        if evidence[source_id].get("coefficient_source") is not False:
            fail(f"literature must not silently become gameplay coefficient source: {source_id}")

    if profiles.get("status") != "UNCALIBRATED_AUTHORING_PRIORS" or profiles.get("shipping") is not False:
        fail("fatigue profiles must remain uncalibrated and non-shipping")
    policy = profiles.get("policy", {})
    if policy.get("levels_are_empirical_measurements") is not False:
        fail("qualitative profile levels cannot claim empirical measurement")
    if policy.get("levels_may_modify_reducer_probability") is not False:
        fail("uncalibrated fatigue profiles cannot modify reducer probability")

    graph_ids = {
        str(row.get("id"))
        for row in graph.get("techniques", [])
        if isinstance(row, dict) and row.get("id")
    }
    required = golden_ids(golden)
    profile_rows = {
        str(row.get("technique_id")): row
        for row in profiles.get("profiles", [])
        if isinstance(row, dict) and row.get("technique_id")
    }
    missing = sorted(required - set(profile_rows))
    if missing:
        fail(f"golden techniques missing fatigue profiles: {missing}")
    unknown_graph = sorted(set(profile_rows) - graph_ids)
    if unknown_graph:
        fail(f"fatigue profile references unknown slice technique: {unknown_graph}")

    for technique_id in sorted(required):
        row = profile_rows[technique_id]
        if row.get("review_status") != "AUTHORING_PRIOR_UNCALIBRATED":
            fail(f"profile promoted without F3/expert gate: {technique_id}")
        load_map = row.get("performer_load")
        if not isinstance(load_map, dict) or set(load_map) != set(EXPECTED_DIMENSIONS):
            fail(f"fatigue profile dimensions incomplete: {technique_id}")
        for dimension, level in load_map.items():
            if level not in EXPECTED_LEVELS:
                fail(f"invalid load level {technique_id}:{dimension}:{level}")
        if row.get("opponent_load") != "UNKNOWN":
            fail(f"opponent load must remain UNKNOWN until reviewed: {technique_id}")

    if f3.get("status") != "INFRASTRUCTURE_READY_DATA_PENDING" or f3.get("shipping") is not False:
        fail("F3 contract must remain infrastructure-ready/data-pending")
    boundaries = f3.get("hard_boundaries", {})
    for flag in (
        "authoring_prior_is_empirical_success",
        "video_frequency_is_success_probability",
        "self_play_frequency_is_empirical_frequency",
        "model_prediction_is_ground_truth",
        "unreviewed_observation_may_enter_calibration",
        "rights_blocked_source_may_enter_promotion_dataset",
        "F3_may_change_rules_or_legality",
        "F3_may_activate_runtime_effects_by_itself",
    ):
        if boundaries.get(flag) is not False:
            fail(f"F3 boundary relaxed: {flag}")

    split_policy = f3.get("split_policy", {})
    if split_policy.get("same_source_event_may_cross_splits") is not False:
        fail("source-event split leakage must remain forbidden")
    if split_policy.get("same_athlete_pair_group_may_cross_splits") is not False:
        fail("athlete-pair split leakage must remain forbidden")
    if split_policy.get("holdout_required_for_promotion") is not True:
        fail("holdout must remain required for F3 promotion")

    observations = ledger.get("observations", [])
    if not isinstance(observations, list):
        fail("F3 observations must be an array")
    if not observations:
        claims = ledger.get("claims", {})
        if any(int(claims.get(key, 0)) != 0 for key in ("eligible_observations", "train", "validation", "holdout")):
            fail("empty F3 ledger cannot claim observations")
        if claims.get("F3_status") != "DATA_PENDING":
            fail("empty F3 ledger must report DATA_PENDING")

    calibrator = load_calibrator()
    report = calibrator.calibrate(ledger=ledger, contract=f3)
    if report.get("runtime_effect_active") is not False or report.get("graph_mutated") is not False:
        fail("F3 calibrator must remain report-only")
    if not report.get("ok", False):
        fail(f"F3 calibrator rejected repository ledger: {report.get('errors', [])}")

    runtime_text = RUNTIME.read_text(encoding="utf-8")
    fatigue_runtime_text = FATIGUE_RUNTIME.read_text(encoding="utf-8")
    for token in (
        "GrapplingFatigueModelV1.gd",
        "fatigue_model.observe_step",
        '"authoritative_state_changed_by_fatigue": false',
        "rest_fatigue",
    ):
        if token not in runtime_text:
            fail(f"grappling runtime missing fatigue integration token: {token}")
    if "reducer.reduce" in fatigue_runtime_text:
        fail("fatigue model must not call reducer.reduce")
    for token in (
        '"active": false',
        '"success_multiplier": 1.0',
        '"cost_multiplier": 1.0',
        '"reason": "F3_NOT_APPROVED"',
    ):
        if token not in fatigue_runtime_text:
            fail(f"fatigue projected effect is not fail-closed: {token}")

    return {
        "ok": True,
        "golden_profiles": len(required),
        "F3_status": report["status"],
        "eligible_observations": report["eligible_observations"],
        "runtime_effect_active": False,
        "shipping": False,
    }


def main() -> int:
    report = validate()
    print("GRAPPLING_FATIGUE_F3_PASS " + json.dumps(report, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
