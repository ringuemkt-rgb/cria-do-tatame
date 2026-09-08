#!/usr/bin/env python3
"""Fail-closed validation for the BJJ reducer-v2 pre-integration slice."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "data/bjj/bjj_kg_slice_ruan_davi_v1.json"
FULL_KG = ROOT / "data/bjj/bjj_knowledge_graph_v1.json"
AUTHORING = ROOT / "data/combat/bjj_kg_authoring_contract_v1.json"
RULES = ROOT / "data/combat/bjj_rulesets_verified_v1.json"
POSITION_VALUES = ROOT / "data/combat/bjj_position_values_v1.json"
TIMING = ROOT / "data/combat/bjj_timing_windows_v1.json"
REDUCER = ROOT / "src/combat/BJJGraphReducerV2.gd"
TIMING_POLICY = ROOT / "src/combat/BJJTimingPolicyV1.gd"
LOADER = ROOT / "src/combat/BJJGraphLoader.gd"
UTILITY = ROOT / "src/ai/BJJUtilityScorerV2.gd"
SMOKE = ROOT / "tests/bjj_reducer_v2_smoke.gd"

ALLOWED_COUNTER_OUTCOMES = {
    "deny_to_same_state",
    "redirect_to_scramble",
    "redirect_to_front_headlock",
    "redirect_to_knee_shield",
    "reverse_to_top",
    "submission_threat",
    "reset_to_neutral",
}
EXPECTED_POSITION_BANDS = {
    "back_mount": 1.0,
    "mount": 0.9,
    "side": 0.75,
    "knee_on_belly": 0.7,
    "pass_in_progress": 0.6,
    "half_top": 0.5,
    "neutral": 0.45,
    "guards_bottom": 0.4,
    "half_bottom": 0.35,
    "turtle": 0.25,
}


def load(path: Path) -> dict:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path}: root must be object")
    return value


def validate_p1_tuning(position_values: dict, timing: dict) -> list[str]:
    errors: list[str] = []
    if position_values.get("status") != "AUTHORING_INITIAL":
        errors.append("position values must remain AUTHORING_INITIAL before playtest/calibration")
    if position_values.get("empirical_status") != "UNCALIBRATED_AUTHORING":
        errors.append("position values must not claim empirical calibration")
    if float(position_values.get("unmapped_fallback", -1.0)) != 0.45:
        errors.append("position-value fallback must remain neutral=0.45")
    bands = position_values.get("bands", {})
    for band_id, expected in EXPECTED_POSITION_BANDS.items():
        if float(bands.get(band_id, -999.0)) != expected:
            errors.append(f"position band {band_id} must equal authored V.5 value {expected}")
    ladder = position_values.get("hud_ladder", [])
    pass_rows = [row for row in ladder if isinstance(row, dict) and row.get("id") == "pass_in_progress"]
    if len(pass_rows) != 1 or pass_rows[0].get("transient_only") is not True:
        errors.append("pass_in_progress must remain an explicitly transient HUD band")

    if timing.get("status") != "AUTHORING_INITIAL":
        errors.append("timing windows must remain AUTHORING_INITIAL before playtest")
    if timing.get("empirical_status") != "UNCALIBRATED_AUTHORING":
        errors.append("timing windows must not claim empirical calibration")
    touch = timing.get("input_profiles", {}).get("touch", {})
    touch_floor = int(touch.get("minimum_counter_window_ms", 0))
    if touch_floor < 250:
        errors.append("touch counter floor must be >=250ms")
    tiers = timing.get("tiers", {})
    default_tier = str(timing.get("default_tier", ""))
    if default_tier not in tiers:
        errors.append("timing default_tier must exist")
    for tier_id, tier in tiers.items():
        if not isinstance(tier, dict):
            errors.append(f"timing tier {tier_id} must be object")
            continue
        if int(tier.get("window_ms", 0)) < touch_floor:
            errors.append(f"timing tier {tier_id} violates touch floor")
        if not str(tier.get("telegraph", "")):
            errors.append(f"timing tier {tier_id} requires telegraph metadata")
    return errors


def validate_fixture(fixture: dict, authoring: dict, rules: dict, timing: dict | None = None) -> list[str]:
    errors: list[str] = []
    if fixture.get("status") != "SLICE_FIXTURE_NONCANONICAL":
        errors.append("slice fixture must remain explicitly noncanonical")
    if fixture.get("runtime_authority") is not False:
        errors.append("slice fixture cannot have runtime authority")
    if fixture.get("full_graph_claim") is not False:
        errors.append("slice fixture cannot claim to be the full graph")
    if fixture.get("rules_authority") != "data/combat/bjj_rulesets_verified_v1.json":
        errors.append("slice fixture must reference versioned rules authority")
    if fixture.get("position_value_authority") != "data/combat/bjj_position_values_v1.json":
        errors.append("slice fixture must reference positional-value authority")
    if fixture.get("timing_authority") != "data/combat/bjj_timing_windows_v1.json":
        errors.append("slice fixture must reference timing authority")

    valid_tiers = set((timing or {}).get("tiers", {}).keys())
    source_status = fixture.get("source_status", {})
    if source_status.get("last_complete_received_technique_id") != "t092":
        errors.append("source ledger must preserve t092 as last complete received technique")
    if source_status.get("received_complete_techniques") is not False:
        errors.append("source ledger cannot claim complete techniques")
    if source_status.get("received_complete_chains") is not False:
        errors.append("source ledger cannot claim complete chains")
    if source_status.get("promotion_blocked") is not True:
        errors.append("promotion must remain blocked until full payload exists")

    if authoring.get("runtime_authority") is not False:
        errors.append("authoring contract unexpectedly gained runtime authority")
    if authoring.get("success_model", {}).get("authoring_prior_field") != "authoring_prior":
        errors.append("authoring contract must use authoring_prior")
    if authoring.get("scoring_model", {}).get("forbid_unversioned_pts_tuple_as_authority") is not True:
        errors.append("static pts tuples must remain forbidden")

    positions = fixture.get("positions", [])
    techniques = fixture.get("techniques", [])
    pos_ids = {str(item.get("id", "")) for item in positions if isinstance(item, dict)}
    tech_ids = {str(item.get("id", "")) for item in techniques if isinstance(item, dict)}
    if "standing_neutral" not in pos_ids or "submission" not in pos_ids:
        errors.append("slice fixture requires standing_neutral and submission")

    for tech in techniques:
        if not isinstance(tech, dict):
            errors.append("technique must be object")
            continue
        tid = str(tech.get("id", ""))
        if "base" in tech:
            errors.append(f"{tid}: raw base field forbidden; use authoring_prior")
        prior = tech.get("authoring_prior")
        if not isinstance(prior, (int, float)) or isinstance(prior, bool) or not 0.0 <= float(prior) <= 1.0:
            errors.append(f"{tid}: invalid authoring_prior")
        if tech.get("prior_status") != "UNCALIBRATED_EXPERT_HEURISTIC":
            errors.append(f"{tid}: prior status must remain uncalibrated")
        if tech.get("empirical_success") is not None:
            errors.append(f"{tid}: empirical_success must be null before F3")
        if "pts" in tech:
            errors.append(f"{tid}: static pts tuple forbidden")
        if str(tech.get("from", "")) not in pos_ids or str(tech.get("to", "")) not in pos_ids:
            errors.append(f"{tid}: edge references missing position")
        if tech.get("actor_role_from") not in {"neutral", "top", "bottom"}:
            errors.append(f"{tid}: invalid actor_role_from")
        if tech.get("actor_role_to") not in {"neutral", "top", "bottom"}:
            errors.append(f"{tid}: invalid actor_role_to")
        availability = tech.get("availability", {})
        if not isinstance(availability, dict) or set(availability) != {"gi", "nogi"}:
            errors.append(f"{tid}: availability must explicitly contain gi/nogi")
        legality = tech.get("legality", {})
        for ruleset_id in ("ibjjf_v6", "adcc_championship_current", "clandestine_cria_v1"):
            gate = legality.get(ruleset_id, {}) if isinstance(legality, dict) else {}
            if not {"allowed", "belt_or_skill_division", "age_division"}.issubset(gate):
                errors.append(f"{tid}: incomplete legality for {ruleset_id}")
        for counter in tech.get("counters", []):
            if not isinstance(counter, dict):
                errors.append(f"{tid}: counter must be semantic object")
                continue
            counter_id = str(counter.get("technique_id", ""))
            if counter_id not in tech_ids:
                errors.append(f"{tid}: missing counter target {counter_id}")
            if counter.get("outcome") not in ALLOWED_COUNTER_OUTCOMES:
                errors.append(f"{tid}: invalid counter outcome {counter.get('outcome')}")
            timing_tier = str(counter.get("timing_tier", ""))
            if not timing_tier:
                errors.append(f"{tid}: counter {counter_id} requires timing_tier")
            elif valid_tiers and timing_tier not in valid_tiers:
                errors.append(f"{tid}: counter {counter_id} uses unknown timing tier {timing_tier}")

    adcc = rules.get("rulesets", {}).get("adcc_championship_current", {}).get("points", {})
    if adcc.get("mount") != 2 or adcc.get("back_mount_hooks_or_body_triangle") != 3:
        errors.append("versioned ADCC authority regressed")
    return errors


def validate_repository() -> list[str]:
    errors: list[str] = []
    required = [
        FIXTURE,
        AUTHORING,
        RULES,
        POSITION_VALUES,
        TIMING,
        REDUCER,
        TIMING_POLICY,
        LOADER,
        UTILITY,
        SMOKE,
    ]
    for path in required:
        if not path.exists():
            errors.append(f"missing required reducer-v2 artifact: {path.relative_to(ROOT)}")
    if errors:
        return errors
    try:
        fixture = load(FIXTURE)
        authoring = load(AUTHORING)
        rules = load(RULES)
        position_values = load(POSITION_VALUES)
        timing = load(TIMING)
        errors.extend(validate_p1_tuning(position_values, timing))
        errors.extend(validate_fixture(fixture, authoring, rules, timing))
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        errors.append(f"parse failure: {exc}")
        return errors

    if FULL_KG.exists():
        try:
            full = load(FULL_KG)
            positions = full.get("positions", full.get("posicoes", []))
            techniques = full.get("techniques", full.get("tecnicas", []))
            chains = full.get("chains", [])
            if len(positions) < 40 or len(techniques) < 120 or len(chains) < 10:
                errors.append("canonical bjj_knowledge_graph_v1.json exists without full 40/120/10 payload")
        except (OSError, ValueError, json.JSONDecodeError) as exc:
            errors.append(f"canonical KG parse failure: {exc}")

    reducer_text = REDUCER.read_text(encoding="utf-8")
    if "randomize()" in reducer_text or "randf()" in reducer_text:
        errors.append("BJJGraphReducerV2 must not use unseeded Godot RNG")
    if "authoring_prior" not in reducer_text:
        errors.append("BJJGraphReducerV2 must consume authoring_prior")
    if "pending_score" not in reducer_text:
        errors.append("BJJGraphReducerV2 must defer scoring until stabilization")
    for required_token in ("BJJTimingPolicyV1.gd", "defense_elapsed_ms", "counter_late", "counter_timing"):
        if required_token not in reducer_text:
            errors.append(f"BJJGraphReducerV2 missing P1 timing token: {required_token}")

    timing_text = TIMING_POLICY.read_text(encoding="utf-8")
    if "window_ms_for" not in timing_text or "is_within_window" not in timing_text:
        errors.append("BJJTimingPolicyV1 must expose deterministic window queries")

    utility_text = UTILITY.read_text(encoding="utf-8")
    if "DEFAULT_POSITION_VALUES" in utility_text:
        errors.append("BJJUtilityScorerV2 must not restore hardcoded position table")
    if "position_value_for" not in utility_text or "position_groups" not in utility_text:
        errors.append("BJJUtilityScorerV2 must consume versioned positional tuning")
    return errors


def main() -> int:
    errors = validate_repository()
    if errors:
        for error in errors:
            print("FAIL", error)
        print(f"BJJ reducer-v2 slice gate failed: {len(errors)} error(s)")
        return 1
    print("BJJ reducer-v2 slice PASS: P1 positional values + touch timing staged; full KG promotion remains blocked")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
