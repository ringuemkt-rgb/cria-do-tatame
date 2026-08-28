#!/usr/bin/env python3
"""Draft 2D contact intervals from normalized paired-pose evidence."""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path
from typing import Any


def _read(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError("root must be an object")
    return value


def _parse_endpoint(value: str) -> tuple[str, str]:
    actor, separator, joint = value.partition(".")
    if not separator or not actor or not joint:
        raise ValueError(f"invalid endpoint: {value}")
    return actor, joint


def _parse_pair(value: str) -> tuple[str, str, str, str]:
    left, separator, right = value.partition("=")
    if not separator:
        raise ValueError(f"invalid pair: {value}")
    actor_a, joint_a = _parse_endpoint(left)
    actor_b, joint_b = _parse_endpoint(right)
    if actor_a == actor_b:
        raise ValueError("contact endpoints must belong to different actors")
    return actor_a, joint_a, actor_b, joint_b


def _point(frame: dict[str, Any], actor: str, joint: str) -> dict[str, Any] | None:
    return frame.get("actors", {}).get(actor, {}).get("keypoints", {}).get(joint)


def draft_contacts(
    evidence: dict[str, Any], pairs: list[str], threshold: float, min_confidence: float
) -> dict[str, Any]:
    if evidence.get("coordinate_space") != "normalized_0_1":
        raise ValueError("contact drafting requires normalized_0_1 evidence")
    if not 0.0 < threshold <= 1.0 or not 0.0 <= min_confidence <= 1.0:
        raise ValueError("threshold and confidence must be within normalized bounds")
    frames = evidence.get("frames")
    if not isinstance(frames, list) or not frames:
        raise ValueError("evidence has no frames")

    contacts: list[dict[str, Any]] = []
    for pair_text in pairs:
        actor_a, joint_a, actor_b, joint_b = _parse_pair(pair_text)
        intervals: list[dict[str, Any]] = []
        active: dict[str, Any] | None = None
        last_timestamp: int | None = None
        for frame in frames:
            timestamp = frame.get("timestamp_ms")
            if not isinstance(timestamp, int):
                raise ValueError("frame timestamp_ms must be an integer")
            point_a = _point(frame, actor_a, joint_a)
            point_b = _point(frame, actor_b, joint_b)
            close = False
            distance = None
            if point_a is not None and point_b is not None:
                confidence = min(float(point_a["confidence"]), float(point_b["confidence"]))
                distance = math.dist(
                    (float(point_a["x"]), float(point_a["y"])),
                    (float(point_b["x"]), float(point_b["y"])),
                )
                close = confidence >= min_confidence and distance <= threshold
            if close:
                if active is None:
                    active = {
                        "start_ms": timestamp,
                        "end_ms": timestamp,
                        "minimum_distance": distance,
                        "sample_count": 1,
                    }
                else:
                    active["end_ms"] = timestamp
                    active["minimum_distance"] = min(active["minimum_distance"], distance)
                    active["sample_count"] += 1
            elif active is not None:
                intervals.append(active)
                active = None
            last_timestamp = timestamp
        if active is not None:
            active["end_ms"] = last_timestamp
            intervals.append(active)
        for interval in intervals:
            interval["minimum_distance"] = round(float(interval["minimum_distance"]), 6)
        contacts.append(
            {
                "pair": pair_text,
                "endpoints": [f"{actor_a}.{joint_a}", f"{actor_b}.{joint_b}"],
                "intervals": intervals,
                "review": "pending_human_BJJ",
            }
        )

    return {
        "schema_version": "1.0.0",
        "state": "draft",
        "draft_only": True,
        "method": "normalized_2d_proximity",
        "threshold": threshold,
        "minimum_confidence": min_confidence,
        "contacts": contacts,
        "limitations": [
            "2d_proximity_does_not_prove_depth_or_pressure",
            "human_BJJ_review_required",
        ],
        "runtime_authority": False,
    }


def _self_test() -> None:
    evidence = {
        "coordinate_space": "normalized_0_1",
        "frames": [
            {"timestamp_ms": 0, "actors": {"a": {"keypoints": {"hand": {"x": 0.1, "y": 0.1, "confidence": 1}}}, "b": {"keypoints": {"arm": {"x": 0.5, "y": 0.5, "confidence": 1}}}}},
            {"timestamp_ms": 17, "actors": {"a": {"keypoints": {"hand": {"x": 0.2, "y": 0.2, "confidence": 1}}}, "b": {"keypoints": {"arm": {"x": 0.21, "y": 0.2, "confidence": 1}}}}},
            {"timestamp_ms": 34, "actors": {"a": {"keypoints": {"hand": {"x": 0.2, "y": 0.2, "confidence": 1}}}, "b": {"keypoints": {"arm": {"x": 0.22, "y": 0.2, "confidence": 1}}}}},
        ],
    }
    result = draft_contacts(evidence, ["a.hand=b.arm"], 0.03, 0.5)
    interval = result["contacts"][0]["intervals"][0]
    assert interval["start_ms"] == 17 and interval["end_ms"] == 34
    assert result["draft_only"] is True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", nargs="?", type=Path)
    parser.add_argument("output", nargs="?", type=Path)
    parser.add_argument("--pair", action="append", default=[])
    parser.add_argument("--threshold", type=float)
    parser.add_argument("--min-confidence", type=float)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        _self_test()
        print(json.dumps({"tool": "contact_draft", "self_test": "PASS"}))
        return 0
    if args.input is None or args.output is None or not args.pair:
        parser.error("input, output and at least one --pair are required")
    if args.threshold is None or args.min_confidence is None:
        parser.error("--threshold and --min-confidence are required; the tool does not invent QA limits")
    try:
        result = draft_contacts(_read(args.input), args.pair, args.threshold, args.min_confidence)
        args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(json.dumps({"tool": "contact_draft", "status": "FAIL", "error": str(exc)}))
        return 1
    print(json.dumps({"tool": "contact_draft", "status": "PASS", "output": str(args.output)}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
