#!/usr/bin/env python3
"""Derive autonomous public-video research targets from CRIA project gaps.

This planner is intentionally network-free. It produces ranked discovery queries and
research questions. A separate authorized search/browser/API surface executes them.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
DIRECTOR = ROOT / "data/research/public_video_analysis_director_v1.json"
GOLDEN = ROOT / "data/combat/golden_chain_ruan_davi_v1.json"
LEDGER = ROOT / "data/research/public_video_observation_ledger_v1.json"


def load(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path.relative_to(ROOT)} root must be object")
    return value


def technique_rows(golden: dict[str, Any]) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    seen: set[str] = set()
    for lane in ("success_chain", "alternate_branches"):
        for row in golden.get(lane, []):
            if not isinstance(row, dict):
                continue
            tid = str(row.get("technique_id", "")).strip()
            if tid and tid not in seen:
                seen.add(tid)
                out.append({
                    "technique_id": tid,
                    "from": row.get("from"),
                    "to": row.get("to"),
                    "kind": "transition",
                    "priority_reason": "golden_chain_gap",
                })
    for row in golden.get("defense_branches", []):
        if not isinstance(row, dict):
            continue
        for key, kind in (("attack_id", "attack"), ("counter_id", "counter")):
            tid = str(row.get(key, "")).strip()
            if tid and tid not in seen:
                seen.add(tid)
                out.append({
                    "technique_id": tid,
                    "from": row.get("from"),
                    "to": row.get("to"),
                    "kind": kind,
                    "priority_reason": "missing_counter_or_failure" if kind == "counter" else "golden_chain_gap",
                })
    return out


def observed_techniques(ledger: dict[str, Any]) -> set[str]:
    observed: set[str] = set()
    for row in ledger.get("observations", []):
        if not isinstance(row, dict):
            continue
        tid = row.get("technique_candidate")
        status = row.get("status")
        if isinstance(tid, str) and tid and status in {
            "OBSERVED_HIGH_CONFIDENCE",
            "OBSERVED_MODERATE_CONFIDENCE",
        }:
            observed.add(tid)
    return observed


def build_queries(target: dict[str, Any], ruleset: str) -> list[str]:
    tid = target["technique_id"]
    src = target.get("from") or ""
    dst = target.get("to") or ""
    base = f"Brazilian Jiu-Jitsu {tid} {src} {dst}".strip()
    return [
        f"{base} competition match {ruleset}",
        f"{base} technique class mechanics counter",
        f"{base} championship full match",
    ]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=12)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    director = load(DIRECTOR)
    golden = load(GOLDEN)
    ledger = load(LEDGER)
    weights = director.get("information_gain_weights", {})
    observed = observed_techniques(ledger)
    ruleset = str(golden.get("ruleset", "bjj"))

    ranked: list[dict[str, Any]] = []
    for target in technique_rows(golden):
        reason = target["priority_reason"]
        score = int(weights.get(reason, 1))
        if target["technique_id"] in observed:
            score -= 2
        ranked.append({
            **target,
            "information_gain_score": score,
            "queries": build_queries(target, ruleset),
            "desired_sources": [
                "official_or_full_competition",
                "credible_instruction_reference",
                "independent_competition_example",
            ],
            "promotion_note": "public observations inform priority only; motion derivation needs owned/licensed capture",
        })

    ranked.sort(key=lambda r: (-r["information_gain_score"], r["technique_id"]))
    report = {
        "ok": True,
        "ruleset": ruleset,
        "targets_total": len(ranked),
        "observed_high_or_moderate": sorted(observed),
        "next_targets": ranked[: max(0, args.limit)],
        "user_selection_required": False,
    }
    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        for index, row in enumerate(report["next_targets"], 1):
            print(f"{index:02d}. {row['technique_id']} score={row['information_gain_score']} {row.get('from')} -> {row.get('to')}")
            for query in row["queries"]:
                print(f"    - {query}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
