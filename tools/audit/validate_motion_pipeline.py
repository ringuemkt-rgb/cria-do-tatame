#!/usr/bin/env python3
"""Validate motion-source licensing, biomechanical package building and tile intake."""

from __future__ import annotations

import importlib.util
import json
from copy import deepcopy
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
REGISTRY_PATH = ROOT / "data" / "production" / "motion_source_registry_v01.json"
TILESET_PATH = ROOT / "data" / "production" / "biome_tileset_contract_v01.json"
FIXTURE_PATH = ROOT / "tests" / "fixtures" / "motion_capture" / "raw_baiana_sample.json"
BUILDER_PATH = ROOT / "tools" / "animation" / "build_motion_package.py"


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise AssertionError(f"{path.relative_to(ROOT)} must contain an object")
    return value


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def load_builder():
    spec = importlib.util.spec_from_file_location("build_motion_package", BUILDER_PATH)
    require(spec is not None and spec.loader is not None, "cannot load motion builder")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main() -> int:
    registry = load_json(REGISTRY_PATH)
    tileset = load_json(TILESET_PATH)
    raw_fixture = load_json(FIXTURE_PATH)
    builder = load_builder()

    require(registry.get("$schema") == "motion_source_registry_v1", "invalid source registry schema")
    policy = registry.get("policy", {})
    require(policy.get("runtime_ai_required") is False, "AI cannot be required by game runtime")
    require(policy.get("runtime_network_required") is False, "motion runtime must stay offline")
    require(policy.get("human_bjj_review_required") is True, "human BJJ review is mandatory")
    require(policy.get("performer_consent_required") is True, "performer consent is mandatory")
    require(
        policy.get("derived_keypoints_do_not_waive_source_rights") is True,
        "derived keypoints cannot waive source-video rights",
    )

    sources = {str(item.get("id", "")): item for item in registry.get("sources", [])}
    require(sources.get("own_capture", {}).get("status") == "preferred", "first-party capture must be preferred")
    require(sources.get("pose2sim", {}).get("license") == "BSD-3-Clause", "Pose2Sim license decision changed")
    require(sources.get("freemocap", {}).get("license") == "AGPL-3.0", "FreeMoCap copyleft must stay explicit")
    grapplemap = sources.get("grapplemap", {})
    require(grapplemap.get("license") == "public_domain", "GrappleMap license snapshot changed")
    require(
        grapplemap.get("status") == "blocked_pending_parser_and_bjj_review",
        "GrappleMap must remain quarantined until parser and BJJ review pass",
    )
    grapplemap_format = grapplemap.get("format_snapshot", {})
    require(grapplemap_format.get("proposed_line_parser_compatible") is False, "unverified GrappleMap parser was approved")
    require(grapplemap_format.get("uses_position_transition_keywords") is False, "GrappleMap format was misrepresented")
    hf_bjj = sources.get("bjj_positions_submissions_hf", {})
    require(
        hf_bjj.get("status") == "blocked_pending_source_rights",
        "unverified BJJ video/keypoint input must remain blocked",
    )
    hf_snapshot = hf_bjj.get("dataset_card_snapshot", {})
    require(
        hf_snapshot.get("sample_count") == 1 and hf_snapshot.get("class_count") == 1,
        "BJJ dataset snapshot must not be overstated as a motion library",
    )
    for blocked_id in ["spinepose", "kungfu_fiesta", "motionmillion", "ai4animation"]:
        require(sources.get(blocked_id, {}).get("status") == "blocked_commercial", f"{blocked_id} must remain blocked for commercial output")

    draft = builder.build_package(raw_fixture, "baiana")
    require(draft.get("$schema") == "motion_capture_package_v1", "builder returned wrong schema")
    require(draft.get("shipping_ready") is False, "unreviewed motion cannot be shipping-ready")
    require(draft.get("review", {}).get("status") == "needs_human_review", "draft lacks review gate")
    require(len(draft.get("frames", [])) == 3, "fixture did not preserve synchronized frames")
    require(all("sync" in frame and "biomechanics" in frame for frame in draft["frames"]), "frame metadata incomplete")

    approved = builder.build_package(raw_fixture, "baiana", reviewer="fixture_bjj_reviewer", human_reviewed=True)
    require(approved.get("shipping_ready") is True, "clean reviewed first-party package should pass")
    require(approved.get("source", {}).get("face_data_retained") is False, "face data retention is forbidden")

    blocked_fixture = deepcopy(raw_fixture)
    blocked_fixture["source"]["source_id"] = "spinepose"
    try:
        builder.build_package(blocked_fixture, "baiana")
    except ValueError as exc:
        require("blocked_commercial" in str(exc), "blocked source failed for the wrong reason")
    else:
        raise AssertionError("non-commercial source produced a commercial motion package")

    unverified_fixture = deepcopy(raw_fixture)
    unverified_fixture["source"]["source_id"] = "bjj_positions_submissions_hf"
    try:
        builder.build_package(unverified_fixture, "baiana")
    except ValueError as exc:
        require("blocked_pending_source_rights" in str(exc), "unverified dataset failed for the wrong reason")
    else:
        raise AssertionError("unverified third-party keypoints produced a motion package")

    grapplemap_fixture = deepcopy(raw_fixture)
    grapplemap_fixture["source"]["source_id"] = "grapplemap"
    try:
        builder.build_package(grapplemap_fixture, "baiana")
    except ValueError as exc:
        require("blocked_pending_parser_and_bjj_review" in str(exc), "GrappleMap failed for the wrong reason")
    else:
        raise AssertionError("quarantined GrappleMap data produced a motion package")

    require(tileset.get("$schema") == "biome_tileset_contract_v1", "invalid tileset contract schema")
    require(tileset.get("projection") == "isometric_2_to_1", "tileset projection must stay 2:1")
    require(tileset.get("required_alpha") is True, "shipping tiles require real alpha")
    require(tileset.get("baked_checkerboard_forbidden") is True, "baked checkerboards must be rejected")
    intake = tileset.get("reference_intake", [])
    require(len(intake) == 2, "two supplied reference sheets must be inventoried")
    require(all(item.get("shipping_status") == "blocked_reference_only" for item in intake), "invalid attachments cannot enter shipping atlas")
    require(all(item.get("license_status") == "pending_user_confirmation" for item in intake), "attachment provenance must remain pending")

    print(
        "[motion-pipeline] ok: source licenses, consent, two-body sync, "
        "human review, third-party dataset gates and supplied tileset intake validated"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
