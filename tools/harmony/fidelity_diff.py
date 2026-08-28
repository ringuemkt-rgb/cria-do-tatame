#!/usr/bin/env python3
"""Measure pose fidelity between evidence and an AI-derived candidate."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import statistics
import sys
from pathlib import Path
from typing import Any


def _read(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError("root must be an object")
    return value


def _hash_payload(value: dict[str, Any]) -> str:
    raw = json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(raw).hexdigest()


def _points(payload: dict[str, Any]) -> dict[tuple[int, str, str], tuple[float, float]]:
    if payload.get("coordinate_space") != "normalized_0_1":
        raise ValueError("both inputs must use normalized_0_1 coordinates")
    output: dict[tuple[int, str, str], tuple[float, float]] = {}
    for frame in payload.get("frames", []):
        timestamp = frame.get("timestamp_ms")
        if not isinstance(timestamp, int):
            raise ValueError("timestamp_ms must be an integer")
        for actor_id, actor in frame.get("actors", {}).items():
            for joint, point in actor.get("keypoints", {}).items():
                output[(timestamp, actor_id, joint)] = (float(point["x"]), float(point["y"]))
    return output


def compare(
    evidence: dict[str, Any],
    derived: dict[str, Any],
    mean_max: float,
    p95_max: float,
    missing_max: float,
) -> dict[str, Any]:
    if not all(0.0 <= value <= 1.0 for value in (mean_max, p95_max, missing_max)):
        raise ValueError("all limits must be within 0..1 normalized space")
    reference = _points(evidence)
    candidate = _points(derived)
    if not reference:
        raise ValueError("evidence contains no comparable keypoints")
    common = sorted(reference.keys() & candidate.keys())
    distances = [math.dist(reference[key], candidate[key]) for key in common]
    missing = sorted(reference.keys() - candidate.keys())
    unexpected = sorted(candidate.keys() - reference.keys())
    missing_rate = len(missing) / len(reference)
    mean = statistics.fmean(distances) if distances else 1.0
    ordered = sorted(distances)
    p95_index = max(0, math.ceil(len(ordered) * 0.95) - 1) if ordered else 0
    p95 = ordered[p95_index] if ordered else 1.0
    maximum = max(ordered) if ordered else 1.0
    passed = mean <= mean_max and p95 <= p95_max and missing_rate <= missing_max
    return {
        "schema_version": "1.0.0",
        "state": "derived_quality_report",
        "status": "PASS" if passed else "FAIL",
        "automatic_pass_is_not_human_approval": True,
        "limits": {"mean_max": mean_max, "p95_max": p95_max, "missing_max": missing_max},
        "metrics": {
            "matched_keypoints": len(common),
            "reference_keypoints": len(reference),
            "missing_keypoints": len(missing),
            "unexpected_keypoints": len(unexpected),
            "missing_rate": round(missing_rate, 6),
            "mean_distance": round(mean, 6),
            "p95_distance": round(p95, 6),
            "maximum_distance": round(maximum, 6),
        },
        "evidence_payload_sha256": _hash_payload(evidence),
        "derived_payload_sha256": _hash_payload(derived),
        "missing_examples": [list(value) for value in missing[:20]],
        "unexpected_examples": [list(value) for value in unexpected[:20]],
        "runtime_authority": False,
        "human_gates": ["BJJ", "ANIMATION", "ART"],
    }


def _self_test() -> None:
    evidence = {
        "coordinate_space": "normalized_0_1",
        "frames": [{"timestamp_ms": 0, "actors": {"a": {"keypoints": {"hand": {"x": 0.1, "y": 0.1}}}}}],
    }
    derived = json.loads(json.dumps(evidence))
    derived["frames"][0]["actors"]["a"]["keypoints"]["hand"]["x"] = 0.11
    result = compare(evidence, derived, 0.02, 0.02, 0.0)
    assert result["status"] == "PASS"
    result = compare(evidence, derived, 0.001, 0.001, 0.0)
    assert result["status"] == "FAIL"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("evidence", nargs="?", type=Path)
    parser.add_argument("derived", nargs="?", type=Path)
    parser.add_argument("output", nargs="?", type=Path)
    parser.add_argument("--mean-max", type=float)
    parser.add_argument("--p95-max", type=float)
    parser.add_argument("--missing-max", type=float)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        _self_test()
        print(json.dumps({"tool": "fidelity_diff", "self_test": "PASS"}))
        return 0
    if args.evidence is None or args.derived is None or args.output is None:
        parser.error("evidence, derived and output are required")
    if args.mean_max is None or args.p95_max is None or args.missing_max is None:
        parser.error("all three limits are required; the tool does not invent QA thresholds")
    try:
        result = compare(
            _read(args.evidence), _read(args.derived), args.mean_max, args.p95_max, args.missing_max
        )
        args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(json.dumps({"tool": "fidelity_diff", "status": "FAIL", "error": str(exc)}))
        return 1
    print(json.dumps({"tool": "fidelity_diff", "status": result["status"], "output": str(args.output)}))
    return 0 if result["status"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
