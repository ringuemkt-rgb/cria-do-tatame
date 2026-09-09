#!/usr/bin/env python3
"""Fail-closed structural validator for CRIA Combat Intelligence OS v1."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
CONTRACT = ROOT / "data/combat/combat_intelligence_contract_v1.json"
COMPLETION = ROOT / "data/combat/bjj_completion_gate_v1.json"
RULES = ROOT / "data/combat/bjj_rulesets_verified_v1.json"
STRATEGY = ROOT / "data/combat/ruleset_strategy_profiles_v1.json"
CORPUS = ROOT / "data/research/grappling_video_corpus_contract_v1.json"
LEDGER = ROOT / "data/research/grappling_video_source_ledger_v1.json"
OBS_SCHEMA = ROOT / "assets/schemas/grappling_observation_v1.schema.json"
RESEARCH_REGISTRY = ROOT / "data/research/combat_research_registry_v1.json"
MIGRATION = ROOT / "data/production/godot_migration_plan_v1.json"
REDUCER = ROOT / "src/combat/BJJGraphReducerV2.gd"
SKILL = ROOT / ".agents/skills/cria-combat-intelligence/SKILL.md"


def load(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path}: root must be object")
    return value


def validate(root: Path = ROOT) -> dict[str, Any]:
    del root
    errors: list[str] = []
    required = [CONTRACT, COMPLETION, RULES, STRATEGY, CORPUS, LEDGER, OBS_SCHEMA, RESEARCH_REGISTRY, MIGRATION, REDUCER, SKILL]
    for path in required:
        if not path.exists():
            errors.append(f"missing required file: {path.relative_to(ROOT)}")
    if errors:
        return {"ok": False, "errors": errors}

    contract = load(CONTRACT)
    completion = load(COMPLETION)
    rules = load(RULES)
    strategy = load(STRATEGY)
    corpus = load(CORPUS)
    ledger = load(LEDGER)
    schema = load(OBS_SCHEMA)
    registry = load(RESEARCH_REGISTRY)
    migration = load(MIGRATION)
    reducer_text = REDUCER.read_text(encoding="utf-8")
    skill_text = SKILL.read_text(encoding="utf-8")

    if contract.get("version") != "1.0.0":
        errors.append("combat intelligence contract must be v1.0.0")
    if contract.get("shipping") is not False:
        errors.append("combat intelligence authoring contract must remain shipping=false")

    authority = contract.get("authority", {})
    if authority.get("runtime_engine") != "Godot":
        errors.append("Godot must remain the runtime engine authority")
    if authority.get("runtime_state_authority") != "src/combat/BJJGraphReducerV2.gd":
        errors.append("v1 must wrap, not silently replace, BJJGraphReducerV2")
    for flag in (
        "video_or_ml_may_define_legality",
        "video_or_ml_may_define_scoring",
        "llm_may_run_inner_combat_loop",
        "this_contract_may_set_shipping_true",
    ):
        if authority.get(flag) is not False:
            errors.append(f"authority fail-closed flag must be false: {flag}")

    target = completion.get("minimum_targets", {})
    if target != {"positions": 40, "techniques": 120, "chains": 10}:
        errors.append("Combat Intelligence must not weaken the canonical 40/120/10 BJJ target")

    canonical_phases = completion.get("paired_animation_contract", {}).get("required_phases", [])
    interaction_phases = contract.get("interaction_state", {}).get("animation_phases", [])
    if interaction_phases != canonical_phases:
        errors.append("Combat Intelligence animation phases diverge from BJJ completion gate")

    technique_required = set(contract.get("technique_contract", {}).get("required_fields", []))
    for field in ("preconditions", "required_connections", "force_direction", "defender_responses", "failure_topology", "rules_legality", "animation_phases"):
        if field not in technique_required:
            errors.append(f"technique contract missing realism field: {field}")
    if contract.get("technique_contract", {}).get("generic_attack_animation_is_valid_technique_definition") is not False:
        errors.append("generic attack animation cannot define a grappling technique")

    ai = contract.get("tactical_ai", {})
    if ai.get("inner_loop") != "deterministic_reducer":
        errors.append("tactical AI must keep deterministic reducer as inner loop")
    forbidden_roles = set(ai.get("llm_forbidden_roles", []))
    for role in ("legality_decision", "score_decision", "runtime_rng", "submission_safety_decision"):
        if role not in forbidden_roles:
            errors.append(f"LLM forbidden-role contract missing: {role}")

    if strategy.get("runtime_authority") is not False:
        errors.append("strategy profile must not silently become rules/runtime authority")
    if strategy.get("scoring_authority") != "data/combat/bjj_rulesets_verified_v1.json":
        errors.append("strategy timing profile must defer point values to verified rules")
    adcc_rules = rules.get("rulesets", {}).get("adcc_championship_current", {})
    if int(adcc_rules.get("stabilization_seconds", 0)) != 3:
        errors.append("verified ADCC rules must preserve 3-second stabilization")
    expected_profiles = {
        "adcc_world_qualifying": (600000, 300000, 1),
        "adcc_world_finals_superfight": (1200000, 600000, 2),
        "adcc_trials_qualifying": (360000, 180000, 1),
        "adcc_trials_final": (480000, 240000, 1),
    }
    profiles = strategy.get("profiles", {})
    for profile_id, expected in expected_profiles.items():
        profile = profiles.get(profile_id, {})
        if (int(profile.get("regulation_ms", -1)), int(profile.get("overtime_ms", -1)), int(profile.get("max_overtimes", -1))) != expected:
            errors.append(f"ADCC timing profile mismatch: {profile_id}")
        phases = profile.get("phases", [])
        if len(phases) != 2 or int(phases[0].get("start_ms", -1)) != 0 or int(phases[-1].get("end_ms", -1)) != expected[0]:
            errors.append(f"ADCC phase coverage mismatch: {profile_id}")
        if "points" in profile:
            errors.append(f"strategy profile must not duplicate scoring table: {profile_id}")

    rights = corpus.get("rights_policy", {})
    if rights.get("default_status") != "BLOCKED_UNTIL_RIGHTS_CLASSIFIED":
        errors.append("video corpus must default to rights-blocked")
    if rights.get("public_url_is_not_permission") is not True:
        errors.append("corpus must explicitly reject public URL as permission")
    if rights.get("broadcast_or_instructional_video_may_be_used_automatically_for_commercial_training") is not False:
        errors.append("broadcast/instructional footage cannot default to commercial training")
    if rights.get("preferred_corpus") != "CRIA_OWN_CAPTURE_WITH_RELEASES":
        errors.append("own capture with releases must be preferred commercial corpus")

    if ledger.get("status") != "ACTIVE_EMPTY_LEDGER":
        errors.append("v1 source ledger status must accurately describe current empty ingestion state")
    sources = ledger.get("sources", [])
    claims = ledger.get("ingestion_claim", {})
    if sources:
        errors.append("initial Combat Intelligence PR must not pretend external videos were ingested")
    for field in ("videos_ingested", "expert_reviewed_observations", "commercial_training_eligible_videos"):
        if int(claims.get(field, -1)) != 0:
            errors.append(f"empty source ledger must claim zero: {field}")

    benchmarks = {x.get("id"): x for x in corpus.get("external_benchmarks", []) if isinstance(x, dict)}
    vicos = benchmarks.get("vicos_bjj_positions", {})
    if vicos.get("license_status") != "CC_BY_NC_SA_4_0_NONCOMMERCIAL" or vicos.get("commercial_training_default") is not False:
        errors.append("ViCoS BJJ dataset must remain noncommercial research only")

    required_schema_fields = set(schema.get("required", []))
    for field in ("source_id", "position", "phase", "athletes", "interaction", "confidence", "review"):
        if field not in required_schema_fields:
            errors.append(f"grappling observation schema missing: {field}")
    review_status = schema.get("properties", {}).get("review", {}).get("properties", {}).get("status", {}).get("enum", [])
    if "UNCERTAIN" not in review_status:
        errors.append("observation schema must support UNCERTAIN review state")

    if registry.get("external_tool_authority") != "data/production/external_tool_registry_v1.json":
        errors.append("research registry must not replace external tool policy authority")
    if registry.get("policy", {}).get("this_file_may_authorize_code_or_asset_reuse") is not False:
        errors.append("research registry cannot authorize code/asset reuse")

    restricted = {x.get("id") for x in registry.get("blocked_or_restricted_examples", []) if isinstance(x, dict)}
    for expected in ("smplx", "flux_dev_family", "deeplabcut_superanimal"):
        if expected not in restricted:
            errors.append(f"restricted research example missing: {expected}")

    if migration.get("target_engine") != "4.7.2-stable":
        errors.append("engine migration plan must target audited stable Godot 4.7.2")
    if migration.get("status") != "PLANNED_SEPARATE_BRANCH":
        errors.append("engine migration must remain isolated from combat architecture PR")
    if migration.get("success_policy", {}).get("deterministic_bjj_replays_must_match") is not True:
        errors.append("engine migration must preserve deterministic BJJ replays")

    for token in ("seed", "pending_score", "rules_engine", "timing_policy"):
        if token not in reducer_text:
            errors.append(f"existing deterministic reducer invariant missing: {token}")

    for token in ("CRIA Rhythm", "Evidence-first video laboratory", "LLMs", "Six-phase paired motion contract"):
        if token not in skill_text:
            errors.append(f"combat skill missing required section/token: {token}")

    return {
        "ok": not errors,
        "errors": errors,
        "bjj_target": target,
        "animation_phases": canonical_phases,
        "adcc_strategy_profiles": len(profiles),
        "research_tools": len(registry.get("findings", [])),
        "external_benchmarks": len(benchmarks),
        "videos_ingested": int(claims.get("videos_ingested", 0)),
        "godot_migration_target": migration.get("target_engine"),
        "commercial_video_default": rights.get("default_status"),
    }


def main() -> int:
    result = validate()
    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    return 0 if result.get("ok") else 1


if __name__ == "__main__":
    raise SystemExit(main())
