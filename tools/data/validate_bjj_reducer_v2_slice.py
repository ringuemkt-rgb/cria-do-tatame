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
REDUCER = ROOT / "src/combat/BJJGraphReducerV2.gd"
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


def load(path: Path) -> dict:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path}: root must be object")
    return value


def validate_fixture(fixture: dict, authoring: dict, rules: dict) -> list[str]:
    errors: list[str] = []
    if fixture.get("status") != "SLICE_FIXTURE_NONCANONICAL":
        errors.append("slice fixture must remain explicitly noncanonical")
    if fixture.get("runtime_authority") is not False:
        errors.append("slice fixture cannot have runtime authority")
    if fixture.get("full_graph_claim") is not False:
        errors.append("slice fixture cannot claim to be the full graph")
    if fixture.get("rules_authority") != "data/combat/bjj_rulesets_verified_v1.json":
        errors.append("slice fixture must reference versioned rules authority")

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

    adcc = rules.get("rulesets", {}).get("adcc_championship_current", {}).get("points", {})
    if adcc.get("mount") != 2 or adcc.get("back_mount_hooks_or_body_triangle") != 3:
        errors.append("versioned ADCC authority regressed")
    return errors


def validate_repository() -> list[str]:
    errors: list[str] = []
    required = [FIXTURE, AUTHORING, RULES, REDUCER, LOADER, UTILITY, SMOKE]
    for path in required:
        if not path.exists():
            errors.append(f"missing required reducer-v2 artifact: {path.relative_to(ROOT)}")
    if errors:
        return errors
    try:
        errors.extend(validate_fixture(load(FIXTURE), load(AUTHORING), load(RULES)))
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
    return errors


def main() -> int:
    errors = validate_repository()
    if errors:
        for error in errors:
            print("FAIL", error)
        print(f"BJJ reducer-v2 slice gate failed: {len(errors)} error(s)")
        return 1
    print("BJJ reducer-v2 slice PASS: deterministic adapter core staged; full KG promotion remains blocked")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
