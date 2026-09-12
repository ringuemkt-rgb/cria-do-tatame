#!/usr/bin/env python3
"""Fail-closed structural validator for CRIA Public Video Intelligence V1."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
DIRECTOR = ROOT / "data/research/public_video_analysis_director_v1.json"
LEDGER = ROOT / "data/research/public_video_observation_ledger_v1.json"
CORPUS = ROOT / "data/research/grappling_video_corpus_contract_v1.json"
MOTION_LAB = ROOT / "data/research/grappling_motion_lab_contract_v1.json"
MOTION_FACTORY = ROOT / "data/production/motion_factory_v1.json"
SKILL = ROOT / ".agents/skills/cria-public-video-intelligence/SKILL.md"
PLANNER = ROOT / "tools/research/plan_public_video_research_v1.py"


def load(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path.relative_to(ROOT)} root must be object")
    return value


def main() -> int:
    errors: list[str] = []
    for path in (DIRECTOR, LEDGER, CORPUS, MOTION_LAB, MOTION_FACTORY, SKILL, PLANNER):
        if not path.exists():
            errors.append(f"missing required file: {path.relative_to(ROOT)}")
    if errors:
        print(json.dumps({"ok": False, "errors": errors}, indent=2))
        return 1

    director = load(DIRECTOR)
    ledger = load(LEDGER)
    corpus = load(CORPUS)
    motion_lab = load(MOTION_LAB)
    motion_factory = load(MOTION_FACTORY)
    skill = SKILL.read_text(encoding="utf-8")

    if director.get("version") != "1.0.0" or director.get("status") != "ACTIVE_AUTONOMOUS_RESEARCH_DIRECTOR":
        errors.append("director must be active v1.0.0")
    if director.get("shipping") is not False or director.get("runtime_authority") is not False:
        errors.append("public video director must remain non-shipping and non-runtime-authoritative")

    platform = director.get("platform_policy", {})
    expected = {
        "youtube_public_url_is_permission": False,
        "youtube_official_api_for_discovery_metadata": True,
        "third_party_caption_download_via_youtube_data_api_default": False,
        "caption_download_requires_video_edit_permission": True,
        "automated_scraping_or_download_default": False,
        "store_raw_third_party_media_in_git": False,
        "store_extracted_third_party_frames_in_git": False,
        "store_timestamped_transformed_observations": True,
    }
    for key, value in expected.items():
        if platform.get(key) is not value:
            errors.append(f"platform_policy.{key} must be {value}")

    promotion = director.get("promotion_rules", {})
    for key in (
        "single_video_may_define_gameplay_mechanic",
        "public_video_may_define_rules",
        "public_video_may_define_score",
        "public_video_may_define_canon",
        "public_video_may_be_gold_3d_biomechanics_authority",
        "public_standard_license_video_may_train_commercial_model_by_default",
        "public_standard_license_video_may_feed_motion_factory_by_default",
        "public_standard_license_video_may_create_shipping_frames_by_default",
    ):
        if promotion.get(key) is not False:
            errors.append(f"promotion rule must remain false: {key}")
    if promotion.get("owned_or_separately_licensed_capture_required_for_motion_derivation") is not True:
        errors.append("motion derivation must require owned/separately licensed capture")

    fail_closed = director.get("fail_closed", {})
    for key in (
        "metadata_never_implies_visual_observation",
        "transcript_never_implies_visual_observation",
        "hidden_contact_remains_unknown",
        "no_access_never_becomes_negative_evidence",
        "source_failure_auto_selects_next_candidate",
        "user_not_required_to_select_next_query",
    ):
        if fail_closed.get(key) is not True:
            errors.append(f"fail_closed.{key} must remain true")

    cycle = director.get("autonomous_cycle", [])
    ids = [row.get("id") for row in cycle if isinstance(row, dict)]
    expected_cycle = [f"PV{i:02d}" for i in range(14)]
    if ids != expected_cycle:
        errors.append("autonomous cycle must remain contiguous PV00..PV13")

    states = set(director.get("capability_states", []))
    for state in ("METADATA_READY", "VISUAL_READY", "PARTIAL_METADATA_ONLY", "VISUAL_ACCESS_UNAVAILABLE", "RIGHTS_BLOCKED"):
        if state not in states:
            errors.append(f"missing capability state: {state}")

    statuses = set(director.get("observation_statuses", []))
    for status in ("OBSERVED_HIGH_CONFIDENCE", "TRANSCRIPT_ONLY", "METADATA_ONLY", "UNKNOWN_OCCLUDED", "NOT_ACCESSIBLE"):
        if status not in statuses:
            errors.append(f"missing observation status: {status}")

    if ledger.get("status") not in {"ACTIVE_EMPTY_LEDGER", "ACTIVE_LEDGER"}:
        errors.append("unexpected observation ledger status")
    policy = ledger.get("policy", {})
    if policy.get("raw_media_storage") is not False or policy.get("third_party_frame_storage") is not False:
        errors.append("observation ledger must not store raw media or third-party frames")
    if policy.get("visual_claim_requires_visual_access") is not True:
        errors.append("visual claims must require visual access")

    sources = ledger.get("sources", [])
    observations = ledger.get("observations", [])
    claims = ledger.get("claims", {})
    if not sources and ledger.get("status") != "ACTIVE_EMPTY_LEDGER":
        errors.append("empty source list must keep ACTIVE_EMPTY_LEDGER")
    if not sources:
        for key in ("sources_discovered", "sources_visually_reviewed", "timestamped_observations", "triangulated_findings", "motion_derivation_eligible_sources"):
            if int(claims.get(key, -1)) != 0:
                errors.append(f"empty ledger must claim zero: {key}")
    if int(claims.get("timestamped_observations", 0)) > len(observations):
        errors.append("timestamped observation claim cannot exceed stored observations")

    if corpus.get("rights_policy", {}).get("public_url_is_not_permission") is not True:
        errors.append("video corpus must preserve public-url-is-not-permission rule")
    if motion_lab.get("biomechanics", {}).get("single_view_broadcast_is_gold_3d_authority") is not False:
        errors.append("Motion Lab single-view broadcast rule changed unexpectedly")
    if motion_factory.get("input_policy", {}).get("public_url_is_permission") is not False:
        errors.append("Motion Factory public URL rule changed unexpectedly")

    for token in (
        "Autonomous loop",
        "Capability truth table",
        "Visual/frame-level analysis",
        "Information-gain prioritization",
        "Do not ask the user to paste videos",
    ):
        if token not in skill:
            errors.append(f"skill missing policy token: {token}")

    result = {
        "ok": not errors,
        "errors": errors,
        "cycle_stages": len(ids),
        "source_records": len(sources),
        "observations": len(observations),
        "shipping": False,
    }
    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
