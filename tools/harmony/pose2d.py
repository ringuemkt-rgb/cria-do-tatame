#!/usr/bin/env python3
"""Normalize paired 2D pose evidence without inventing missing keypoints."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path
from typing import Any


def _read_json(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError("root must be an object")
    return value


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _point(value: Any) -> tuple[float, float, float]:
    if isinstance(value, list) and len(value) == 3:
        x, y, confidence = value
    elif isinstance(value, dict):
        x, y, confidence = value.get("x"), value.get("y"), value.get("confidence")
    else:
        raise ValueError("keypoint must be [x,y,confidence] or an object")
    if not all(isinstance(item, (int, float)) for item in (x, y, confidence)):
        raise ValueError("keypoint values must be numeric")
    if not 0.0 <= float(confidence) <= 1.0:
        raise ValueError("confidence must be between 0 and 1")
    return float(x), float(y), float(confidence)


def normalize(payload: dict[str, Any], source_video: Path | None = None) -> dict[str, Any]:
    width = payload.get("width")
    height = payload.get("height")
    fps = payload.get("fps")
    if not isinstance(width, int) or width <= 0 or not isinstance(height, int) or height <= 0:
        raise ValueError("positive integer width and height are required")
    if not isinstance(fps, (int, float)) or float(fps) <= 0:
        raise ValueError("positive fps is required")

    declared_hash = payload.get("source_video_sha256")
    observed_hash = None
    if source_video is not None:
        observed_hash = _sha256(source_video)
        if declared_hash is not None and declared_hash != observed_hash:
            raise ValueError("source video SHA-256 does not match declaration")

    frames = payload.get("frames")
    if not isinstance(frames, list) or not frames:
        raise ValueError("frames must be a non-empty array")

    output_frames: list[dict[str, Any]] = []
    seen_indices: set[int] = set()
    actor_ids: set[str] = set()
    last_timestamp = -1
    for frame in frames:
        if not isinstance(frame, dict):
            raise ValueError("each frame must be an object")
        index = frame.get("frame_index")
        timestamp = frame.get("timestamp_ms")
        actors = frame.get("actors")
        if not isinstance(index, int) or index < 0 or index in seen_indices:
            raise ValueError("frame_index must be a unique non-negative integer")
        if not isinstance(timestamp, int) or timestamp < 0 or timestamp <= last_timestamp:
            raise ValueError("timestamp_ms must be a strictly increasing integer")
        if not isinstance(actors, dict) or not actors:
            raise ValueError("each frame must contain actors")
        seen_indices.add(index)
        last_timestamp = timestamp
        normalized_actors: dict[str, Any] = {}
        for actor_id in sorted(actors):
            actor = actors[actor_id]
            if not isinstance(actor_id, str) or not actor_id or not isinstance(actor, dict):
                raise ValueError("actor IDs and actor payloads must be valid")
            keypoints = actor.get("keypoints")
            if not isinstance(keypoints, dict):
                raise ValueError(f"actor {actor_id} has no keypoints object")
            normalized_points: dict[str, Any] = {}
            for joint in sorted(keypoints):
                x, y, confidence = _point(keypoints[joint])
                if not 0.0 <= x <= width or not 0.0 <= y <= height:
                    raise ValueError(f"{actor_id}.{joint} is outside the capture bounds")
                normalized_points[joint] = {
                    "x": round(x / width, 6),
                    "y": round(y / height, 6),
                    "confidence": round(confidence, 6),
                }
            normalized_actors[actor_id] = {"keypoints": normalized_points}
            actor_ids.add(actor_id)
        output_frames.append(
            {"frame_index": index, "timestamp_ms": timestamp, "actors": normalized_actors}
        )

    if len(actor_ids) != 2:
        raise ValueError("paired Harmony evidence requires exactly two stable actor IDs")

    return {
        "schema_version": "1.0.0",
        "state": "processed_evidence",
        "coordinate_space": "normalized_0_1",
        "source": {
            "video_sha256": observed_hash or declared_hash,
            "width": width,
            "height": height,
            "fps": fps,
            "capture_is_evidence": True,
            "ai_is_derivative": True,
        },
        "actor_ids": sorted(actor_ids),
        "frames": output_frames,
        "missing_keypoint_policy": "preserve_missing_never_interpolate_silently",
        "runtime_authority": False,
    }


def _self_test() -> None:
    payload = {
        "width": 100,
        "height": 200,
        "fps": 60,
        "source_video_sha256": "0" * 64,
        "frames": [
            {
                "frame_index": 0,
                "timestamp_ms": 1,
                "actors": {
                    "a": {"keypoints": {"wrist": [25, 100, 0.9]}},
                    "b": {"keypoints": {"shoulder": {"x": 75, "y": 50, "confidence": 0.8}}},
                },
            },
            {
                "frame_index": 1,
                "timestamp_ms": 17,
                "actors": {
                    "a": {"keypoints": {"wrist": [50, 100, 0.7]}},
                    "b": {"keypoints": {"shoulder": [75, 75, 0.6]}},
                },
            },
        ],
    }
    result = normalize(payload)
    assert result["actor_ids"] == ["a", "b"]
    assert result["frames"][0]["actors"]["a"]["keypoints"]["wrist"]["x"] == 0.25
    bad = json.loads(json.dumps(payload))
    bad["frames"][1]["timestamp_ms"] = 1
    try:
        normalize(bad)
    except ValueError:
        return
    raise AssertionError("non-increasing timestamps were accepted")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", nargs="?", type=Path)
    parser.add_argument("output", nargs="?", type=Path)
    parser.add_argument("--source-video", type=Path)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        _self_test()
        print(json.dumps({"tool": "pose2d", "self_test": "PASS"}))
        return 0
    if args.input is None or args.output is None:
        parser.error("input and output are required unless --self-test is used")
    try:
        result = normalize(_read_json(args.input), args.source_video)
        args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(json.dumps({"tool": "pose2d", "status": "FAIL", "error": str(exc)}))
        return 1
    print(json.dumps({"tool": "pose2d", "status": "PASS", "output": str(args.output)}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
