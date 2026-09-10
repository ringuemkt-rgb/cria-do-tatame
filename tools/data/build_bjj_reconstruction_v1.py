#!/usr/bin/env python3
"""Build and validate the non-authoritative CRIA BJJ reconstruction candidate.

The builder deliberately never writes data/bjj/bjj_knowledge_graph_v1.json.
It expands the fragment manifest into reports/ for review and QA only.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
CONTRACT_PATH = ROOT / "data/combat/bjj_authority_reconstruction_contract_v1.json"
POSITIONS_PATH = ROOT / "data/bjj/bjj_position_taxonomy_candidate_v1.json"
TECHNIQUE_MANIFEST_PATH = ROOT / "data/bjj/bjj_technique_taxonomy_candidate_v1.json"
CHAINS_PATH = ROOT / "data/bjj/bjj_chain_taxonomy_candidate_v1.json"
CANDIDATE_MANIFEST_PATH = ROOT / "data/bjj/bjj_knowledge_graph_candidate_v1.json"
GOLD_SLICE_PATH = ROOT / "data/bjj/bjj_kg_slice_ruan_davi_v1.json"
DEFAULT_OUTPUT = ROOT / "reports/bjj_reconstruction/bjj_knowledge_graph_candidate_v1.expanded.json"

ALLOWED_ROLES = {"neutral", "top", "bottom"}
ALLOWED_REVIEW = {"PENDING", "APPROVED", "REJECTED"}
ALLOWED_RULES_REVIEW = {"PENDING", "APPROVED", "REJECTED", "NOT_APPLICABLE"}
ALLOWED_SELF_LOOP_TYPES = {"control", "grip", "defense"}
FORBIDDEN_DANGEROUS_KEYS = {
    "torque_direction",
    "rotation_direction",
    "joint_break_threshold",
    "choke_pressure_threshold",
    "forced_range_of_motion",
    "directional_escape_instruction",
}


def load(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path.relative_to(ROOT)} must contain a JSON object")
    return value


def rel(path: Path) -> str:
    return str(path.relative_to(ROOT)).replace("\\", "/")


def load_families(manifest: dict[str, Any]) -> tuple[list[dict[str, Any]], list[str]]:
    techniques: list[dict[str, Any]] = []
    family_files: list[str] = []
    for raw_path in manifest.get("family_files", []):
        path_text = str(raw_path)
        path = ROOT / path_text
        family = load(path)
        family_files.append(path_text)
        if family.get("shipping") is not False:
            raise ValueError(f"family must remain shipping=false: {path_text}")
        rows = family.get("techniques")
        if not isinstance(rows, list):
            raise ValueError(f"family techniques must be an array: {path_text}")
        techniques.extend(row for row in rows if isinstance(row, dict))
        if len(rows) != len([row for row in rows if isinstance(row, dict)]):
            raise ValueError(f"family contains non-object technique: {path_text}")
    return techniques, family_files


def collect_dangerous_keys(value: Any, prefix: str = "") -> list[str]:
    hits: list[str] = []
    if isinstance(value, dict):
        for key, child in value.items():
            path = f"{prefix}.{key}" if prefix else str(key)
            if key in FORBIDDEN_DANGEROUS_KEYS:
                hits.append(path)
            hits.extend(collect_dangerous_keys(child, path))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            hits.extend(collect_dangerous_keys(child, f"{prefix}[{index}]"))
    return hits


def build() -> dict[str, Any]:
    contract = load(CONTRACT_PATH)
    positions_doc = load(POSITIONS_PATH)
    technique_manifest = load(TECHNIQUE_MANIFEST_PATH)
    chains_doc = load(CHAINS_PATH)
    candidate_manifest = load(CANDIDATE_MANIFEST_PATH)
    gold = load(GOLD_SLICE_PATH)

    errors: list[str] = []
    warnings: list[str] = []

    if contract.get("status") != "CANDIDATE_AUTHORING_ONLY" or contract.get("shipping") is not False:
        errors.append("contract_must_remain_candidate_nonshipping")
    truth = contract.get("current_truth", {})
    if truth.get("authoritative_full_graph_exists") is not False:
        errors.append("contract_must_not_claim_missing_full_graph_exists")
    if truth.get("historical_payload_materialized_in_repository") is not False:
        errors.append("contract_must_not_claim_historical_payload_recovered")
    if truth.get("reconstruction_is_recovery_of_original_payload") is not False:
        errors.append("reconstruction_must_not_claim_original_payload_recovery")

    for doc_name, doc in (
        ("positions", positions_doc),
        ("technique_manifest", technique_manifest),
        ("chains", chains_doc),
        ("candidate_manifest", candidate_manifest),
    ):
        if doc.get("shipping") is not False:
            errors.append(f"{doc_name}_must_remain_shipping_false")
        if doc.get("full_graph_claim") is not False:
            errors.append(f"{doc_name}_must_remain_full_graph_claim_false")

    positions = positions_doc.get("positions", [])
    if not isinstance(positions, list):
        errors.append("positions_must_be_array")
        positions = []
    position_ids: set[str] = set()
    duplicate_positions: set[str] = set()
    for row in positions:
        if not isinstance(row, dict):
            errors.append("position_not_object")
            continue
        pid = str(row.get("id", ""))
        if not pid:
            errors.append("position_missing_id")
            continue
        if pid in position_ids:
            duplicate_positions.add(pid)
        position_ids.add(pid)
        if row.get("side") not in ALLOWED_ROLES:
            errors.append(f"position_invalid_side:{pid}")
    for pid in sorted(duplicate_positions):
        errors.append(f"duplicate_position_id:{pid}")

    try:
        techniques, family_files = load_families(technique_manifest)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        errors.append(f"family_load:{exc}")
        techniques, family_files = [], []

    required_fields = set(contract.get("technique_policy", {}).get("minimum_fields", []))
    technique_ids: set[str] = set()
    duplicate_techniques: set[str] = set()
    technique_by_id: dict[str, dict[str, Any]] = {}
    canonical_mappings: dict[str, str] = {}
    gold_by_id = {
        str(row.get("id")): row
        for row in gold.get("techniques", [])
        if isinstance(row, dict) and row.get("id")
    }

    for row in techniques:
        tid = str(row.get("id", ""))
        if not tid:
            errors.append("technique_missing_id")
            continue
        if tid in technique_ids:
            duplicate_techniques.add(tid)
        technique_ids.add(tid)
        technique_by_id[tid] = row
        if not tid.startswith("rec_"):
            errors.append(f"candidate_technique_id_must_use_rec_prefix:{tid}")
        missing = sorted(required_fields - set(row))
        if missing:
            errors.append(f"technique_missing_fields:{tid}:{','.join(missing)}")
        if row.get("from") not in position_ids:
            errors.append(f"technique_unknown_from:{tid}:{row.get('from')}")
        if row.get("to") not in position_ids:
            errors.append(f"technique_unknown_to:{tid}:{row.get('to')}")
        if row.get("actor_role_from") not in ALLOWED_ROLES or row.get("actor_role_to") not in ALLOWED_ROLES:
            errors.append(f"technique_invalid_actor_role:{tid}")
        if row.get("expert_review_status") not in ALLOWED_REVIEW:
            errors.append(f"technique_invalid_expert_review:{tid}")
        if row.get("rules_review_status") not in ALLOWED_RULES_REVIEW:
            errors.append(f"technique_invalid_rules_review:{tid}")
        if row.get("empirical_success") is not None:
            errors.append(f"candidate_empirical_success_must_be_null:{tid}")
        source_basis = row.get("source_basis")
        if not isinstance(source_basis, list) or not source_basis:
            errors.append(f"technique_missing_source_basis:{tid}")
        if row.get("from") == row.get("to") and row.get("type") not in ALLOWED_SELF_LOOP_TYPES:
            errors.append(f"invalid_self_loop:{tid}:{row.get('type')}")
        if row.get("from") == "submission":
            errors.append(f"submission_must_be_terminal:{tid}")
        if row.get("type") == "submission" and row.get("to") != "submission":
            errors.append(f"submission_must_end_terminal:{tid}")
        dangerous = collect_dangerous_keys(row)
        if dangerous:
            errors.append(f"dangerous_directional_detail_forbidden:{tid}:{','.join(dangerous)}")

        mapping = row.get("canonical_mapping")
        if mapping is not None:
            mapping = str(mapping)
            if mapping in canonical_mappings:
                errors.append(f"duplicate_canonical_mapping:{mapping}:{canonical_mappings[mapping]}:{tid}")
            canonical_mappings[mapping] = tid
            if mapping not in gold_by_id:
                errors.append(f"canonical_mapping_not_in_gold_slice:{tid}:{mapping}")
            else:
                gold_row = gold_by_id[mapping]
                if row.get("from") != gold_row.get("from") or row.get("to") != gold_row.get("to"):
                    errors.append(f"canonical_mapping_transition_drift:{tid}:{mapping}")
                if row.get("actor_role_from") != gold_row.get("actor_role_from") or row.get("actor_role_to") != gold_row.get("actor_role_to"):
                    errors.append(f"canonical_mapping_role_drift:{tid}:{mapping}")

    for tid in sorted(duplicate_techniques):
        errors.append(f"duplicate_technique_id:{tid}")

    chains = chains_doc.get("chains", [])
    if not isinstance(chains, list):
        errors.append("chains_must_be_array")
        chains = []
    chain_ids: set[str] = set()
    duplicate_chains: set[str] = set()
    for chain in chains:
        if not isinstance(chain, dict):
            errors.append("chain_not_object")
            continue
        cid = str(chain.get("id", ""))
        if not cid:
            errors.append("chain_missing_id")
            continue
        if cid in chain_ids:
            duplicate_chains.add(cid)
        chain_ids.add(cid)
        steps = chain.get("steps")
        if not isinstance(steps, list) or len(steps) < 2:
            errors.append(f"chain_too_short:{cid}")
            continue
        unknown = [str(step) for step in steps if str(step) not in technique_by_id]
        if unknown:
            errors.append(f"chain_unknown_technique:{cid}:{','.join(unknown)}")
            continue
        first = technique_by_id[str(steps[0])]
        last = technique_by_id[str(steps[-1])]
        if chain.get("start_position") != first.get("from"):
            errors.append(f"chain_start_mismatch:{cid}:{chain.get('start_position')}:{first.get('from')}")
        if chain.get("end_position") != last.get("to"):
            errors.append(f"chain_end_mismatch:{cid}:{chain.get('end_position')}:{last.get('to')}")
        for left_id, right_id in zip(steps, steps[1:]):
            left = technique_by_id[str(left_id)]
            right = technique_by_id[str(right_id)]
            if left.get("to") != right.get("from"):
                errors.append(
                    f"chain_discontinuity:{cid}:{left_id}->{right_id}:{left.get('to')}!={right.get('from')}"
                )
        if chain.get("expert_review_status") not in ALLOWED_REVIEW:
            errors.append(f"chain_invalid_expert_review:{cid}")
        if chain.get("rules_review_status") not in ALLOWED_RULES_REVIEW:
            errors.append(f"chain_invalid_rules_review:{cid}")
    for cid in sorted(duplicate_chains):
        errors.append(f"duplicate_chain_id:{cid}")

    targets = contract.get("targets", {})
    actual_counts = {
        "positions": len(positions),
        "techniques": len(techniques),
        "chains": len(chains),
    }
    for key, actual in actual_counts.items():
        expected = int(targets.get(key, -1))
        if actual != expected:
            errors.append(f"count_mismatch:{key}:{actual}:{expected}")

    expected_family_files = technique_manifest.get("family_files", [])
    if len(expected_family_files) != 12 or len(family_files) != 12:
        errors.append(f"family_manifest_count_mismatch:{len(family_files)}")
    if len(set(expected_family_files)) != len(expected_family_files):
        errors.append("duplicate_family_file_reference")
    if int(technique_manifest.get("family_size", 0)) != 10:
        errors.append("family_size_contract_must_be_10")

    expected_gold_mappings = int(candidate_manifest.get("known_gold_mappings_expected", -1))
    if len(canonical_mappings) != expected_gold_mappings:
        errors.append(f"gold_mapping_count_mismatch:{len(canonical_mappings)}:{expected_gold_mappings}")

    # Candidate structure may be complete while promotion remains deliberately blocked.
    expert_pending = sum(1 for row in techniques if row.get("expert_review_status") != "APPROVED")
    rules_pending = sum(1 for row in techniques if row.get("rules_review_status") != "APPROVED")
    promotion_ready = (
        not errors
        and expert_pending == 0
        and rules_pending == 0
        and contract.get("promotion_ready") is True
        and candidate_manifest.get("promotion", {}).get("may_replace_data_bjj_bjj_knowledge_graph_v1_json") is True
    )
    if promotion_ready:
        errors.append("automatic_promotion_forbidden_in_reconstruction_v1")
        promotion_ready = False

    # Coverage is descriptive and helps reviewers find isolated authoring states.
    incident_positions: set[str] = set()
    for row in techniques:
        if row.get("from") in position_ids:
            incident_positions.add(str(row.get("from")))
        if row.get("to") in position_ids:
            incident_positions.add(str(row.get("to")))
    isolated_positions = sorted(position_ids - incident_positions)
    if isolated_positions:
        warnings.append("isolated_positions:" + ",".join(isolated_positions))

    expanded = {
        "$schema": "cria.bjj_knowledge_graph_candidate.expanded.v1",
        "version": "1.0.0",
        "status": "STRUCTURAL_CANDIDATE_PENDING_EXPERT_RULES_CALIBRATION",
        "runtime_authority": False,
        "full_graph_claim": False,
        "shipping": False,
        "reconstruction_contract": rel(CONTRACT_PATH),
        "rules_authority": "data/combat/bjj_rulesets_verified_v1.json",
        "positions": positions,
        "techniques": techniques,
        "chains": chains,
        "counts": actual_counts,
        "known_gold_mappings": canonical_mappings,
        "review_summary": {
            "expert_pending_techniques": expert_pending,
            "rules_pending_techniques": rules_pending,
            "promotion_ready": False,
        },
        "warnings": warnings,
    }

    return {
        "ok": not errors,
        "errors": errors,
        "warnings": warnings,
        "counts": actual_counts,
        "family_files": family_files,
        "known_gold_mappings": canonical_mappings,
        "expert_pending_techniques": expert_pending,
        "rules_pending_techniques": rules_pending,
        "structural_candidate_complete": not errors and actual_counts == {"positions": 40, "techniques": 120, "chains": 10},
        "promotion_ready": False,
        "authoritative_full_graph_created": False,
        "expanded": expanded,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--write-expanded", action="store_true")
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--require-promotion-ready", action="store_true")
    args = parser.parse_args(argv)

    try:
        report = build()
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"BJJ_RECONSTRUCTION_FAIL: {exc}", file=sys.stderr)
        return 1

    if args.write_expanded and report["ok"]:
        output = Path(args.output)
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(json.dumps(report["expanded"], ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    public_report = {key: value for key, value in report.items() if key != "expanded"}
    print("BJJ_RECONSTRUCTION_REPORT " + json.dumps(public_report, ensure_ascii=False, sort_keys=True))
    if not report["ok"]:
        return 1
    if args.require_promotion_ready and not report["promotion_ready"]:
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
