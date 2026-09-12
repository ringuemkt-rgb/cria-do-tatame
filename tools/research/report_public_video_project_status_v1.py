#!/usr/bin/env python3
"""Summarize Public Video Intelligence impact without exposing operational chatter."""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
DIRECTOR = ROOT / "data/research/public_video_analysis_director_v1.json"
LEDGER = ROOT / "data/research/public_video_observation_ledger_v1.json"
MOTION = ROOT / "data/motion/ruan_davi_motion_slice_v1.json"
PLANNER = ROOT / "tools/research/plan_public_video_research_v1.py"


def load(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path.relative_to(ROOT)} root must be object")
    return value


def next_targets(limit: int) -> list[dict[str, Any]]:
    proc = subprocess.run(
        [sys.executable, str(PLANNER), "--limit", str(limit), "--json"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(proc.stdout).get("next_targets", [])


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--next", type=int, default=5)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    director = load(DIRECTOR)
    ledger = load(LEDGER)
    motion = load(MOTION)
    claims = ledger.get("claims", {})
    units = [row for row in motion.get("units", []) if isinstance(row, dict)]
    pending_capture = [row for row in units if row.get("capture_status") != "COMPLETE"]
    promotions = motion.get("promotion", {})
    targets = next_targets(max(0, args.next))

    blockers: list[str] = []
    if int(claims.get("sources_visually_reviewed", 0)) == 0:
        blockers.append("no_public_sources_visually_reviewed_yet")
    if int(claims.get("triangulated_findings", 0)) == 0:
        blockers.append("no_multi_source_findings_yet")
    if pending_capture:
        blockers.append("ruan_davi_owned_capture_pending")
    if not promotions.get("sprite_forge_complete", False):
        blockers.append("paired_sprite_forge_motion_not_complete")
    if not promotions.get("godot_visual_qa_complete", False):
        blockers.append("motion_runtime_visual_qa_not_complete")

    report = {
        "ok": True,
        "director_status": director.get("status"),
        "evidence_base": {
            "sources_discovered": int(claims.get("sources_discovered", 0)),
            "sources_visually_reviewed": int(claims.get("sources_visually_reviewed", 0)),
            "timestamped_observations": int(claims.get("timestamped_observations", 0)),
            "triangulated_findings": int(claims.get("triangulated_findings", 0)),
        },
        "motion_factory": {
            "units_total": len(units),
            "capture_pending": len(pending_capture),
            "capture_complete": bool(promotions.get("capture_complete", False)),
            "retarget_complete": bool(promotions.get("retarget_complete", False)),
            "sprite_forge_complete": bool(promotions.get("sprite_forge_complete", False)),
            "godot_visual_qa_complete": bool(promotions.get("godot_visual_qa_complete", False)),
        },
        "project_assessment": (
            "INFRASTRUCTURE_READY_EVIDENCE_COLLECTION_NOT_STARTED"
            if int(claims.get("sources_discovered", 0)) == 0
            else "EVIDENCE_COLLECTION_ACTIVE"
        ),
        "true_blockers": blockers,
        "next_autonomous_targets": [
            {
                "technique_id": row.get("technique_id"),
                "name": row.get("name_pt"),
                "score": row.get("information_gain_score"),
                "from": row.get("from"),
                "to": row.get("to"),
            }
            for row in targets
        ],
        "user_action_required_now": False,
    }

    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print(f"PROJECT: {report['project_assessment']}")
        print(
            "EVIDENCE: "
            f"sources={report['evidence_base']['sources_discovered']} "
            f"visual={report['evidence_base']['sources_visually_reviewed']} "
            f"observations={report['evidence_base']['timestamped_observations']} "
            f"triangulated={report['evidence_base']['triangulated_findings']}"
        )
        print(
            "MOTION: "
            f"units={report['motion_factory']['units_total']} "
            f"capture_pending={report['motion_factory']['capture_pending']}"
        )
        print("BLOCKERS: " + (", ".join(blockers) if blockers else "none"))
        print("NEXT:")
        for row in report["next_autonomous_targets"]:
            print(f"- {row['technique_id']} | {row['name']} | score={row['score']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
