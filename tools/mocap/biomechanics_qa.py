#!/usr/bin/env python3
"""Deterministic geometry QA for paired-motion candidates.

This tool checks continuity, paired contacts and phase coverage. It is not a
clinical validator and cannot replace technical human review.
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

from validate_paired_motion import validate as validate_structure


def distance(a: list[float], b: list[float]) -> float:
    return math.sqrt(sum((float(x) - float(y)) ** 2 for x, y in zip(a, b)))


def load_thresholds(manifest_path: Path) -> dict:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    return manifest["prototype"]["qa_thresholds"]


def frame_index(data: dict) -> dict[int, dict]:
    return {int(item["frame"]): item for item in data["frames"]}


def endpoint_position(frame: dict, ref: str) -> list[float] | None:
    role, joint = ref.split(".", 1)
    if role == "environment":
        return None
    return frame[role]["joints"].get(joint)


def continuity_report(data: dict) -> dict:
    frames = data["frames"]
    worst = {"distance": 0.0, "role": None, "joint": None, "from": None, "to": None}
    samples = 0
    for left, right in zip(frames, frames[1:]):
        for role in ("attacker", "defender"):
            for joint in data["joint_set"]:
                a = left[role]["joints"][joint]
                b = right[role]["joints"][joint]
                d = distance(a, b)
                samples += 1
                if d > worst["distance"]:
                    worst = {
                        "distance": round(d, 6),
                        "role": role,
                        "joint": joint,
                        "from": left["frame"],
                        "to": right["frame"],
                    }
    return {"samples": samples, "worst_step": worst}


def contact_report(data: dict) -> dict:
    frames = frame_index(data)
    reports = []
    worst = 0.0
    for contact in data["contacts"]:
        tolerance = float(contact.get("tolerance", 0.12))
        distances = []
        for number in sorted(frames):
            if contact["start"] <= number <= contact["end"]:
                a = endpoint_position(frames[number], contact["a"])
                b = endpoint_position(frames[number], contact["b"])
                if a is None or b is None:
                    continue
                d = distance(a, b)
                distances.append(d)
                worst = max(worst, d)
        max_distance = max(distances) if distances else None
        reports.append({
            "a": contact["a"],
            "b": contact["b"],
            "kind": contact["kind"],
            "start": contact["start"],
            "end": contact["end"],
            "tolerance": tolerance,
            "samples": len(distances),
            "max_distance": round(max_distance, 6) if max_distance is not None else None,
            "pass": max_distance is None or max_distance <= tolerance,
        })
    return {"contacts": reports, "worst_distance": round(worst, 6)}


def evaluate(data: dict, thresholds: dict) -> dict:
    structural_errors = validate_structure(data)
    if structural_errors:
        return {
            "status": "FAIL",
            "structural_errors": structural_errors,
            "disclaimer": "Geometric QA did not run because the structural contract failed.",
        }

    continuity = continuity_report(data)
    contacts = contact_report(data)
    teleport_limit = float(thresholds["teleport_distance_normalized_max"])
    continuity_pass = continuity["worst_step"]["distance"] <= teleport_limit
    contacts_pass = all(item["pass"] for item in contacts["contacts"])

    provenance = data["provenance"]
    restricted = list(provenance.get("restricted_components_used", []))
    human_required = True
    status = "PASS_AUTOMATED_PENDING_HUMAN" if continuity_pass and contacts_pass else "FAIL"

    return {
        "status": status,
        "technique_id": data["technique_id"],
        "continuity": {
            **continuity,
            "threshold": teleport_limit,
            "pass": continuity_pass,
        },
        "paired_contacts": {**contacts, "pass": contacts_pass},
        "provenance": {
            "source_type": provenance["source_type"],
            "restricted_components_used": restricted,
            "shipping_eligible": bool(provenance["shipping_eligible"]),
        },
        "human_review_required": human_required,
        "disclaimer": "Automated geometry QA is not clinical validation and cannot approve shipping.",
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("motion", type=Path)
    parser.add_argument(
        "--manifest",
        type=Path,
        default=Path("data/manifest/mocap_stack_v1.json"),
    )
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()

    try:
        data = json.loads(args.motion.read_text(encoding="utf-8"))
        thresholds = load_thresholds(args.manifest)
        report = evaluate(data, thresholds)
    except (OSError, KeyError, json.JSONDecodeError, ValueError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    rendered = json.dumps(report, indent=2, ensure_ascii=False) + "\n"
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(rendered, encoding="utf-8")
    print(rendered, end="")
    return 0 if report["status"].startswith("PASS_") else 1


if __name__ == "__main__":
    raise SystemExit(main())
