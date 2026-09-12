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
BJJ_SLICE = ROOT / "data/bjj/bjj_kg_slice_ruan_davi_v1.json"
LEDGER = ROOT / "data/research/public_video_observation_ledger_v1.json"


def load(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path.relative_to(ROOT)} root must be object")
    return value


def technique_catalog(bjj: dict[str, Any]) -> dict[str, dict[str, Any]]:
    catalog: dict[str, dict[str, Any]] = {}
    for row in bjj.get("techniques", []):
        if not isinstance(row, dict):
            continue
        tid = str(row.get("id", "")).strip()
        if tid:
            catalog[tid] = row
    return catalog


def technique_rows(golden: dict[str, Any], catalog: dict[str, dict[str, Any]]) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    seen: set[str] = set()

    def append_target(tid: str, src: Any, dst: Any, kind: str, reason: str) -> None:
        if not tid or tid in seen:
            return
        seen.add(tid)
        meta = catalog.get(tid, {})
        out.append({
            "technique_id": tid,
            "name_pt": meta.get("pt") or tid,
            "technique_type": meta.get("type") or kind,
            "from": src or meta.get("from"),
            "to": dst or meta.get("to"),
            "kind": kind,
            "priority_reason": reason,
        })

    for lane in ("success_chain", "alternate_branches"):
        for row in golden.get(lane, []):
            if isinstance(row, dict):
                append_target(
                    str(row.get("technique_id", "")).strip(),
                    row.get("from"),
                    row.get("to"),
                    "transition",
                    "golden_chain_gap",
                )

    for row in golden.get("defense_branches", []):
        if not isinstance(row, dict):
            continue
        append_target(
            str(row.get("attack_id", "")).strip(),
            row.get("from"),
            row.get("to"),
            "attack",
            "golden_chain_gap",
        )
        append_target(
            str(row.get("counter_id", "")).strip(),
            row.get("from"),
            row.get("to"),
            "counter",
            "missing_counter_or_failure",
        )
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
    name = str(target.get("name_pt") or target["technique_id"])
    src = str(target.get("from") or "").replace("_", " ")
    dst = str(target.get("to") or "").replace("_", " ")
    technique_type = str(target.get("technique_type") or "")
    context = " ".join(part for part in (name, technique_type, src, dst) if part).strip()
    return [
        f"Brazilian Jiu-Jitsu {context} competition full match {ruleset}",
        f"BJJ {context} technique mechanics common mistakes counter",
        f"BJJ championship {context} full match",
    ]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=12)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    director = load(DIRECTOR)
    golden = load(GOLDEN)
    bjj = load(BJJ_SLICE)
    ledger = load(LEDGER)
    weights = director.get("information_gain_weights", {})
    observed = observed_techniques(ledger)
    ruleset = str(golden.get("ruleset", "bjj"))
    catalog = technique_catalog(bjj)

    ranked: list[dict[str, Any]] = []
    for target in technique_rows(golden, catalog):
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
            print(
                f"{index:02d}. {row['technique_id']} {row['name_pt']} "
                f"score={row['information_gain_score']} {row.get('from')} -> {row.get('to')}"
            )
            for query in row["queries"]:
                print(f"    - {query}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
