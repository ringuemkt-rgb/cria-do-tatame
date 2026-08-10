#!/usr/bin/env python3
"""Normalize reviewed two-performer pose data into a Godot-facing motion package.

This tool intentionally has no ML dependency. Pose2Sim, FreeMoCap, GEM-X or a
first-party capture system run outside the game and export the small neutral
JSON contract accepted here. The output never changes combat simulation; it is
an animation-production artifact that still requires human BJJ approval.
"""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
REGISTRY_PATH = ROOT / "data" / "production" / "motion_source_registry_v01.json"
TECHNIQUES_PATH = ROOT / "data" / "techniques.json"
JOINT_CHAINS = {
    "left_elbow": ("left_shoulder", "left_elbow", "left_wrist"),
    "right_elbow": ("right_shoulder", "right_elbow", "right_wrist"),
    "left_knee": ("left_hip", "left_knee", "left_ankle"),
    "right_knee": ("right_hip", "right_knee", "right_ankle"),
}
APPROVED_STATUSES = {"preferred", "approved_external_tool", "approved_external_copyleft"}


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError(f"{path} must contain an object")
    return value


def source_registry() -> dict[str, dict[str, Any]]:
    raw = load_json(REGISTRY_PATH)
    return {str(item.get("id", "")): item for item in raw.get("sources", []) if isinstance(item, dict)}


def technique_ids() -> set[str]:
    raw = load_json(TECHNIQUES_PATH)
    return {str(item.get("id", "")) for item in raw.get("techniques", []) if isinstance(item, dict)}


def point(value: Any) -> tuple[float, float, float] | None:
    if not isinstance(value, list) or len(value) < 2:
        return None
    confidence = float(value[2]) if len(value) >= 3 else 1.0
    return float(value[0]), float(value[1]), confidence


def angle_degrees(a: Any, b: Any, c: Any) -> float | None:
    pa, pb, pc = point(a), point(b), point(c)
    if pa is None or pb is None or pc is None:
        return None
    first = (pa[0] - pb[0], pa[1] - pb[1])
    second = (pc[0] - pb[0], pc[1] - pb[1])
    norm = math.hypot(*first) * math.hypot(*second)
    if norm <= 1e-8:
        return None
    cosine = max(-1.0, min(1.0, (first[0] * second[0] + first[1] * second[1]) / norm))
    return round(math.degrees(math.acos(cosine)), 2)


def root_position(joints: dict[str, Any]) -> list[float]:
    left = point(joints.get("left_hip"))
    right = point(joints.get("right_hip"))
    if left and right:
        return [round((left[0] + right[0]) * 0.5, 6), round((left[1] + right[1]) * 0.5, 6)]
    available = [item for item in (left, right) if item]
    return [available[0][0], available[0][1]] if available else [0.0, 0.0]


def frame_metrics(frame: dict[str, Any], performer_ids: list[str], minimum_confidence: float) -> dict[str, Any]:
    performers = frame.get("performers", {})
    output: dict[str, Any] = {"joint_angles": {}, "low_confidence_joints": []}
    roots: dict[str, list[float]] = {}
    for performer_id in performer_ids:
        performer = performers.get(performer_id, {})
        joints = performer.get("joints", {}) if isinstance(performer, dict) else {}
        roots[performer_id] = root_position(joints)
        performer_angles: dict[str, float] = {}
        for angle_id, chain in JOINT_CHAINS.items():
            measured = angle_degrees(joints.get(chain[0]), joints.get(chain[1]), joints.get(chain[2]))
            if measured is not None:
                performer_angles[angle_id] = measured
        output["joint_angles"][performer_id] = performer_angles
        for joint_id, joint_value in joints.items():
            parsed = point(joint_value)
            if parsed is not None and parsed[2] < minimum_confidence:
                output["low_confidence_joints"].append(f"{performer_id}:{joint_id}")
    output["roots"] = roots
    if len(performer_ids) == 2:
        a, b = roots[performer_ids[0]], roots[performer_ids[1]]
        output["performer_distance"] = round(math.dist(a, b), 6)
    return output


def build_package(
    raw: dict[str, Any],
    technique_id: str,
    reviewer: str = "",
    human_reviewed: bool = False,
    allow_conditional: bool = False,
) -> dict[str, Any]:
    if technique_id not in technique_ids():
        raise ValueError(f"unknown canonical technique: {technique_id}")
    source = raw.get("source", {})
    source_id = str(source.get("source_id", ""))
    registry = source_registry()
    if source_id not in registry:
        raise ValueError(f"source is not registered: {source_id}")
    source_status = str(registry[source_id].get("status", "blocked"))
    if source_status not in APPROVED_STATUSES and not (allow_conditional and source_status == "conditional_legal_review"):
        raise ValueError(f"source status cannot produce a package: {source_status}")
    if source.get("performer_consent") is not True:
        raise ValueError("performer consent must be explicit")
    if source.get("video_rights") is not True:
        raise ValueError("input video rights must be explicit")

    performers = raw.get("performers", [])
    if not isinstance(performers, list) or len(performers) != 2:
        raise ValueError("exactly two performers are required")
    roles = {str(item.get("role", "")): str(item.get("id", "")) for item in performers if isinstance(item, dict)}
    if set(roles) != {"attacker", "defender"} or not all(roles.values()):
        raise ValueError("performers must define unique attacker and defender roles")
    performer_ids = [roles["attacker"], roles["defender"]]
    if len(set(performer_ids)) != 2:
        raise ValueError("performer ids must be unique")

    fps = float(raw.get("fps", 0.0))
    if not 1.0 <= fps <= 240.0:
        raise ValueError("fps must be between 1 and 240")
    frames = raw.get("frames", [])
    if not isinstance(frames, list) or len(frames) < 2:
        raise ValueError("at least two synchronized frames are required")
    minimum_confidence = float(raw.get("minimum_confidence", 0.55))
    canonical_frames: list[dict[str, Any]] = []
    warnings: list[str] = []
    for index, frame_value in enumerate(frames):
        if not isinstance(frame_value, dict):
            raise ValueError(f"frame {index} must be an object")
        performer_tracks = frame_value.get("performers", {})
        if any(pid not in performer_tracks for pid in performer_ids):
            raise ValueError(f"frame {index} is missing a performer track")
        metrics = frame_metrics(frame_value, performer_ids, minimum_confidence)
        if metrics["low_confidence_joints"]:
            warnings.append(f"frame {index}: low confidence in {', '.join(metrics['low_confidence_joints'])}")
        canonical_frames.append(
            {
                "frame": index,
                "time_ms": round(index * 1000.0 / fps, 3),
                "performers": performer_tracks,
                "biomechanics": metrics,
                "sync": {
                    "attacker_root": metrics["roots"][roles["attacker"]],
                    "defender_root": metrics["roots"][roles["defender"]],
                    "distance": metrics.get("performer_distance", 0.0),
                },
            }
        )

    review_status = "approved" if human_reviewed and reviewer.strip() else "needs_human_review"
    if review_status != "approved":
        warnings.append("human BJJ review is still required")
    return {
        "$schema": "motion_capture_package_v1",
        "version": "1.0.0",
        "technique_id": technique_id,
        "provider": str(raw.get("provider", source_id)),
        "source": {
            "source_id": source_id,
            "capture_id": str(source.get("capture_id", "")),
            "source_status": source_status,
            "performer_consent": True,
            "video_rights": True,
            "face_data_retained": False,
        },
        "coordinate_space": str(raw.get("coordinate_space", "normalized_2d")),
        "fps": fps,
        "performers": performers,
        "frames": canonical_frames,
        "review": {
            "status": review_status,
            "reviewer": reviewer.strip(),
            "biomechanics_reviewed": human_reviewed,
            "tap_and_stop_reviewed": human_reviewed,
        },
        "warnings": warnings,
        "shipping_ready": review_status == "approved" and not warnings,
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path, help="Neutral two-performer pose JSON")
    parser.add_argument("--technique", required=True, help="Canonical technique id")
    parser.add_argument("--output", required=True, type=Path, help="Destination package JSON")
    parser.add_argument("--reviewer", default="", help="Human BJJ reviewer name/id")
    parser.add_argument("--human-reviewed", action="store_true", help="Assert completed human review")
    parser.add_argument("--allow-conditional", action="store_true", help="Allow a source already cleared by legal review")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    package = build_package(
        load_json(args.input),
        args.technique,
        reviewer=args.reviewer,
        human_reviewed=args.human_reviewed,
        allow_conditional=args.allow_conditional,
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(package, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"[motion-package] wrote {args.output} ({len(package['frames'])} frames, {package['review']['status']})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
