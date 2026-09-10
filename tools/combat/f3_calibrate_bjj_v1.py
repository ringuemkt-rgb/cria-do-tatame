#!/usr/bin/env python3
"""CRIA F3 calibration harness.

This module is intentionally report-only. It never mutates the BJJ graph, rules,
or runtime parameters. Empty data is a valid repository state and yields
DATA_PENDING. Promotion remains a separate human-reviewed action.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
CONTRACT_PATH = ROOT / "data/combat/f3_calibration_contract_v1.json"
LEDGER_PATH = ROOT / "data/research/f3_observation_ledger_v1.json"

BINARY_OUTCOMES = {"SUCCESS": 1, "FAILURE": 0, "COUNTERED": 0}
ALLOWED_SPLITS = {"train", "validation", "holdout"}


def load_json(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path} must contain a JSON object")
    return value


def canonical_sha256(value: Any) -> str:
    payload = json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def wilson_95(successes: int, n: int) -> tuple[float, float]:
    if n <= 0:
        return (0.0, 0.0)
    z = 1.959963984540054
    p = successes / n
    denominator = 1.0 + (z * z) / n
    center = (p + (z * z) / (2.0 * n)) / denominator
    margin = (z / denominator) * math.sqrt((p * (1.0 - p) / n) + (z * z) / (4.0 * n * n))
    return (max(0.0, center - margin), min(1.0, center + margin))


def is_eligible(row: dict[str, Any]) -> bool:
    if row.get("expert_review_status") != "APPROVED":
        return False
    if row.get("rules_review_status") != "APPROVED":
        return False
    if row.get("rights_eligible_for_calibration") is not True:
        return False
    if row.get("split") not in ALLOWED_SPLITS:
        return False
    if row.get("attempt_outcome") not in BINARY_OUTCOMES:
        return False
    required = [
        "observation_id",
        "source_id",
        "source_event_id",
        "clip_id",
        "athlete_pair_group",
        "technique_id",
        "from_position",
        "ruleset",
        "modality",
        "skill_band",
        "provenance_sha256",
    ]
    if any(not str(row.get(field, "")).strip() for field in required):
        return False
    provenance = str(row.get("provenance_sha256", ""))
    return len(provenance) == 64 and all(char in "0123456789abcdef" for char in provenance)


def split_leakage(rows: list[dict[str, Any]]) -> list[str]:
    errors: list[str] = []
    for field in ("source_event_id", "athlete_pair_group"):
        seen: dict[str, set[str]] = defaultdict(set)
        for row in rows:
            value = str(row.get(field, ""))
            split = str(row.get("split", ""))
            if value and split in ALLOWED_SPLITS:
                seen[value].add(split)
        for value, splits in sorted(seen.items()):
            if len(splits) > 1:
                errors.append(f"split_leakage:{field}:{value}:{','.join(sorted(splits))}")
    return errors


def calibrate(ledger: dict[str, Any] | None = None, contract: dict[str, Any] | None = None) -> dict[str, Any]:
    ledger = load_json(LEDGER_PATH) if ledger is None else ledger
    contract = load_json(CONTRACT_PATH) if contract is None else contract
    raw_rows = ledger.get("observations", [])
    if not isinstance(raw_rows, list):
        raise ValueError("observations must be an array")

    eligible = [row for row in raw_rows if isinstance(row, dict) and is_eligible(row)]
    leakage_errors = split_leakage(eligible)

    grouped: dict[tuple[str, str, str, str, str], dict[str, int]] = defaultdict(lambda: {"successes": 0, "failures": 0})
    split_counts = {"train": 0, "validation": 0, "holdout": 0}
    for row in eligible:
        outcome = str(row["attempt_outcome"])
        key = (
            str(row["technique_id"]),
            str(row["from_position"]),
            str(row["ruleset"]),
            str(row["modality"]),
            str(row["skill_band"]),
        )
        if BINARY_OUTCOMES[outcome] == 1:
            grouped[key]["successes"] += 1
        else:
            grouped[key]["failures"] += 1
        split_counts[str(row["split"])] += 1

    groups: list[dict[str, Any]] = []
    small_sample_threshold = int(contract.get("reports", {}).get("small_sample_warning_below_n", 20))
    for key in sorted(grouped):
        counts = grouped[key]
        n = counts["successes"] + counts["failures"]
        low, high = wilson_95(counts["successes"], n)
        groups.append(
            {
                "technique_id": key[0],
                "from_position": key[1],
                "ruleset": key[2],
                "modality": key[3],
                "skill_band": key[4],
                "n": n,
                "successes": counts["successes"],
                "failures": counts["failures"],
                "empirical_success_candidate": counts["successes"] / n if n else None,
                "wilson_95": [low, high],
                "small_sample_warning": n < small_sample_threshold,
            }
        )

    if leakage_errors:
        status = "INVALID_SPLIT_LEAKAGE"
    elif not eligible:
        status = "DATA_PENDING"
    elif split_counts["holdout"] == 0:
        status = "PILOT_NO_HOLDOUT"
    else:
        status = "CANDIDATE_REPORT_PENDING_HUMAN_APPROVAL"

    snapshot_rows = sorted(eligible, key=lambda row: str(row.get("observation_id", "")))
    return {
        "ok": not leakage_errors,
        "status": status,
        "eligible_observations": len(eligible),
        "excluded_observations": len(raw_rows) - len(eligible),
        "split_counts": split_counts,
        "groups": groups,
        "errors": leakage_errors,
        "snapshot_sha256": canonical_sha256(snapshot_rows),
        "runtime_effect_active": False,
        "graph_mutated": False,
        "promotion_automatic": False,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--require-data", action="store_true", help="Fail if no eligible F3 observations exist.")
    parser.add_argument("--require-holdout", action="store_true", help="Fail if the eligible dataset has no holdout rows.")
    args = parser.parse_args(argv)

    try:
        report = calibrate()
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"F3_CALIBRATION_FAIL: {exc}", file=sys.stderr)
        return 1

    print("F3_CALIBRATION_REPORT " + json.dumps(report, sort_keys=True))
    if not report["ok"]:
        return 1
    if args.require_data and report["eligible_observations"] == 0:
        return 2
    if args.require_holdout and report["split_counts"]["holdout"] == 0:
        return 3
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
