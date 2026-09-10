#!/usr/bin/env python3
"""Fail-closed validator for CRIA BJJ Authority Reconstruction V1."""

from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BUILDER_PATH = ROOT / "tools/data/build_bjj_reconstruction_v1.py"
COMPLETION_VALIDATOR_PATH = ROOT / "tools/data/validate_bjj_completion_gate_v1.py"
AUTHORITATIVE_FULL_GRAPH = ROOT / "data/bjj/bjj_knowledge_graph_v1.json"
CANDIDATE_GRAPH = ROOT / "data/bjj/bjj_knowledge_graph_candidate_v1.json"


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot import {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def fail(message: str) -> None:
    print(f"BJJ_AUTHORITY_RECONSTRUCTION_FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def validate() -> dict:
    builder = load_module("build_bjj_reconstruction_v1", BUILDER_PATH)
    completion = load_module("validate_bjj_completion_gate_v1_reconstruction", COMPLETION_VALIDATOR_PATH)

    try:
        report = builder.build()
    except Exception as exc:  # fail closed at repository boundary
        fail(f"builder_exception:{type(exc).__name__}:{exc}")

    if not report.get("ok", False):
        fail("candidate_builder_errors:" + json.dumps(report.get("errors", []), ensure_ascii=False))
    if report.get("counts") != {"positions": 40, "techniques": 120, "chains": 10}:
        fail(f"candidate_counts_not_exact:{report.get('counts')}")
    if report.get("structural_candidate_complete") is not True:
        fail("candidate_structure_not_complete")
    if report.get("promotion_ready") is not False:
        fail("candidate_must_not_be_promotion_ready")
    if report.get("authoritative_full_graph_created") is not False:
        fail("builder_must_not_claim_authoritative_graph_created")
    if len(report.get("family_files", [])) != 12:
        fail("expected_12_reviewable_technique_families")
    mappings = report.get("known_gold_mappings", {})
    expected_mappings = {"t001", "slice_sprawl", "t005", "t025", "t049", "slice_side_to_mount", "t057"}
    if set(mappings) != expected_mappings:
        fail(f"gold_mapping_set_drift:{sorted(mappings)}")
    if report.get("expert_pending_techniques") != 120:
        fail("all reconstructed techniques must remain pending expert review in V1")
    if report.get("rules_pending_techniques") != 120:
        fail("all reconstructed techniques must remain pending rules review in V1")

    candidate_manifest = json.loads(CANDIDATE_GRAPH.read_text(encoding="utf-8"))
    if candidate_manifest.get("runtime_authority") is not False:
        fail("candidate_manifest_cannot_be_runtime_authority")
    if candidate_manifest.get("full_graph_claim") is not False:
        fail("candidate_manifest_cannot_claim_full_graph")
    if candidate_manifest.get("shipping") is not False:
        fail("candidate_manifest_cannot_ship")
    promotion = candidate_manifest.get("promotion", {})
    if promotion.get("may_replace_data_bjj_bjj_knowledge_graph_v1_json") is not False:
        fail("candidate_manifest_cannot_replace_authority")

    completion_report = completion.build_report()
    if AUTHORITATIVE_FULL_GRAPH.exists():
        # Reconstruction V1 must never create the authoritative path. If another branch/source
        # supplied it, the completion gate itself becomes the authority for its status.
        if completion_report.get("full_ready") is True:
            fail("unexpected_authoritative_full_graph_ready_during_reconstruction_v1")
    else:
        blockers = completion_report.get("blockers", [])
        codes = {str(item.get("code")) for item in blockers if isinstance(item, dict)}
        if "full_bjj_kg_missing" not in codes:
            fail("completion_gate_must_still_report_missing_authoritative_full_graph")
        if completion_report.get("full_ready") is not False:
            fail("completion_gate_must_remain_blocked")

    return {
        "ok": True,
        "candidate_counts": report["counts"],
        "family_files": len(report["family_files"]),
        "gold_mappings": len(mappings),
        "expert_pending": report["expert_pending_techniques"],
        "rules_pending": report["rules_pending_techniques"],
        "candidate_structural_complete": True,
        "authoritative_full_graph_exists": AUTHORITATIVE_FULL_GRAPH.exists(),
        "promotion_ready": False,
        "shipping": False,
    }


def main() -> int:
    report = validate()
    print("BJJ_AUTHORITY_RECONSTRUCTION_PASS " + json.dumps(report, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
