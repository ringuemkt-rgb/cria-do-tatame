#!/usr/bin/env python3
"""Build CRIA Sprite Forge consistency metadata from normalized gameplay frames.

This tool does not generate art and never promotes assets. It measures existing
128x128 candidate frames and writes an animation-level manifest used by the
Sprite Forge validator. The existing Asset Pipeline v2 remains authoritative for
palette, sidecars, M3 QA and Godot ingestion.
"""
from __future__ import annotations

import argparse
import json
import pathlib
import statistics
import sys
from typing import Any

from PIL import Image

FRAME_SIZE = (128, 128)
PIVOT = [64, 96]
PROTOCOL_VERSION = "1.0.0"
LOOP_ACTIONS = {"idle", "walk", "run", "guard", "stance", "breathing", "hover"}


def _safe_token(value: str) -> bool:
    return bool(value) and all(ch.isalnum() or ch in "_-" for ch in value) and "/" not in value and ".." not in value


def _frame_measurements(path: pathlib.Path) -> dict[str, Any]:
    with Image.open(path) as source:
        image = source.convert("RGBA")
    if image.size != FRAME_SIZE:
        raise ValueError(f"{path}: size={image.size}, expected={FRAME_SIZE}")

    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return {"empty": True, "body_scale": 0.0, "anchor_y": 0.0, "edge_touch": False}

    x0, y0, x1, y1 = bbox
    edge_touch = x0 <= 0 or y0 <= 0 or x1 >= FRAME_SIZE[0] or y1 >= FRAME_SIZE[1]
    return {
        "empty": False,
        "body_scale": (y1 - y0) / FRAME_SIZE[1],
        "anchor_y": y1 / FRAME_SIZE[1],
        "edge_touch": edge_touch,
    }


def measure_action(action_dir: pathlib.Path) -> dict[str, Any]:
    pngs = sorted(action_dir.glob("*.png"))
    if not pngs:
        raise ValueError(f"{action_dir}: no PNG frames")

    measured = [_frame_measurements(path) for path in pngs]
    valid = [item for item in measured if not item["empty"]]
    if not valid:
        raise ValueError(f"{action_dir}: all frames are empty")

    scales = [float(item["body_scale"]) for item in valid]
    anchors = [float(item["anchor_y"]) for item in valid]
    scale_mean = statistics.fmean(scales)
    scale_std = statistics.pstdev(scales) if len(scales) > 1 else 0.0
    anchor_mean = statistics.fmean(anchors)
    anchor_std = statistics.pstdev(anchors) if len(anchors) > 1 else 0.0

    return {
        "frame_count": len(pngs),
        "body_scale_mean": round(scale_mean, 6),
        "body_scale_cv": round(scale_std / scale_mean if scale_mean else 0.0, 6),
        "anchor_y_mean": round(anchor_mean, 6),
        "anchor_y_std": round(anchor_std, 6),
        "edge_touch_frames": sum(1 for item in measured if item["edge_touch"]),
        "empty_frames": sum(1 for item in measured if item["empty"]),
        "paste_clamped_frames": 0,
    }


def build_manifest(repo_root: pathlib.Path, character_id: str, master_action: str) -> dict[str, Any]:
    if not _safe_token(character_id) or not _safe_token(master_action):
        raise ValueError("unsafe character or action id")

    char_dir = repo_root / "assets" / "chars" / "frames" / character_id
    if not char_dir.is_dir():
        raise ValueError(f"missing character frame directory: {char_dir}")

    action_dirs = sorted(path for path in char_dir.iterdir() if path.is_dir() and any(path.glob("*.png")))
    if not action_dirs:
        raise ValueError(f"{char_dir}: no action directories with PNG frames")

    measurements = {path.name: measure_action(path) for path in action_dirs}
    if master_action not in measurements:
        raise ValueError(f"master action '{master_action}' not found for {character_id}")

    master_scale = float(measurements[master_action]["body_scale_mean"])
    if master_scale <= 0:
        raise ValueError("master action has invalid body scale")

    actions: dict[str, Any] = {}
    for action_dir in action_dirs:
        action = action_dir.name
        metrics = dict(measurements[action])
        action_scale = float(metrics["body_scale_mean"])
        metrics["profile_body_scale_drift"] = round(abs(action_scale - master_scale) / master_scale, 6)
        actions[action] = {
            "frames_dir": action_dir.relative_to(repo_root).as_posix(),
            "frame_count": metrics.pop("frame_count"),
            "loop": action in LOOP_ACTIONS,
            "qc": metrics,
        }

    master_metrics = measurements[master_action]
    return {
        "version": 1,
        "protocol_version": PROTOCOL_VERSION,
        "character_id": character_id,
        "master_action": master_action,
        "scale_profile": {
            "source_action": master_action,
            "frame_size": list(FRAME_SIZE),
            "pivot": PIVOT,
            "align": "feet",
            "body_scale_mean": master_metrics["body_scale_mean"],
            "anchor_y_mean": master_metrics["anchor_y_mean"],
        },
        "actions": actions,
        "human_gate": "pending",
        "rights_gate": "pending",
        "m3_qa": "pending",
        "shipping": False,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--character", required=True)
    parser.add_argument("--master-action", default="idle")
    parser.add_argument("--root", default=".")
    parser.add_argument("--write", action="store_true", help="write sprite_forge_manifest.json beside the character actions")
    args = parser.parse_args()

    repo_root = pathlib.Path(args.root).resolve()
    try:
        manifest = build_manifest(repo_root, args.character, args.master_action)
    except (OSError, ValueError) as exc:
        print(f"FAIL sprite forge profile: {exc}")
        return 1

    text = json.dumps(manifest, ensure_ascii=False, indent=2) + "\n"
    if args.write:
        out = repo_root / "assets" / "chars" / "frames" / args.character / "sprite_forge_manifest.json"
        out.write_text(text, encoding="utf-8")
        print(f"wrote {out}")
    else:
        print(text, end="")
    return 0


if __name__ == "__main__":
    sys.exit(main())
