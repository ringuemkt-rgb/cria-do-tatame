#!/usr/bin/env python3
"""Calibrate reversible auto-review recommendations; never promote assets/runtime."""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_RUBRIC = ROOT / "tools/gates/ai_review_rubric.json"
DEFAULT_LOG = ROOT / "tools/gates/agreement_log.json"


def load(path: Path) -> dict:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"objeto JSON esperado: {path}")
    return value


def should_sample(record_id: str, rate: float) -> bool:
    bucket = int(hashlib.sha256(record_id.encode("utf-8")).hexdigest()[:8], 16) / 0xFFFFFFFF
    return bucket < rate


def consecutive_agreements(entries: list[dict], category: str) -> int:
    count = 0
    for item in reversed(entries):
        if item.get("category") != category:
            continue
        human = item.get("human_outcome")
        machine = item.get("machine_outcome")
        if not item.get("human_signed") or human not in {"PASS", "FAIL", "NA"} or human != machine:
            break
        count += 1
    return count


def decide(rubric: dict, log: dict, category: str, record_id: str) -> dict:
    if rubric.get("promotion_forbidden") is not True or log.get("promotion_forbidden") is not True:
        return {"status": "BLOCKED_POLICY_INVALID", "asset_promotion": False}
    if category in rubric.get("irreducible_human_gates", []):
        return {"status": "HUMAN_REQUIRED", "category": category, "asset_promotion": False}
    for audit in log.get("sample_audits", []):
        if audit.get("category") == category and audit.get("agreement") is False:
            return {"status": "RELOCKED", "category": category, "reason": "sample_disagreement", "asset_promotion": False}
    threshold = int(rubric["minimum_consecutive_agreements"])
    agreements = consecutive_agreements(log.get("agreements", []), category)
    if agreements < threshold:
        return {"status": "LOCKED_CALIBRATING", "category": category, "agreements": agreements, "required": threshold, "asset_promotion": False}
    sampled = should_sample(record_id, float(rubric["human_sample_rate"]))
    return {
        "status": "AUTO_REVIEW_ELIGIBLE_PENDING_SAMPLE" if sampled else "AUTO_REVIEW_RECOMMENDATION",
        "category": category,
        "agreements": agreements,
        "human_sample_required": sampled,
        "asset_promotion": False,
        "runtime_integration": False,
    }


def self_test() -> None:
    rubric = {
        "promotion_forbidden": True,
        "minimum_consecutive_agreements": 20,
        "human_sample_rate": 0.1,
        "irreducible_human_gates": ["consent"],
    }
    entries = [{"category": "lore", "human_outcome": "PASS", "machine_outcome": "PASS", "human_signed": True} for _ in range(20)]
    log = {"promotion_forbidden": True, "agreements": entries, "sample_audits": []}
    assert decide(rubric, log, "consent", "x")["status"] == "HUMAN_REQUIRED"
    result = decide(rubric, log, "lore", "record-20")
    assert result["status"].startswith("AUTO_REVIEW_") and result["asset_promotion"] is False
    log["sample_audits"] = [{"category": "lore", "agreement": False}]
    assert decide(rubric, log, "lore", "x")["status"] == "RELOCKED"
    print(json.dumps({"tool": "auto_promote", "self_test": "PASS"}))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rubric", type=Path, default=DEFAULT_RUBRIC)
    parser.add_argument("--log", type=Path, default=DEFAULT_LOG)
    parser.add_argument("--category")
    parser.add_argument("--record-id", default="unspecified")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return 0
    if not args.category:
        parser.error("--category é obrigatório")
    result = decide(load(args.rubric), load(args.log), args.category, args.record_id)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if result["status"] not in {"BLOCKED_POLICY_INVALID", "RELOCKED"} else 1


if __name__ == "__main__":
    sys.exit(main())
