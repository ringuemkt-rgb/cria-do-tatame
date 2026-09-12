#!/usr/bin/env python3
"""Pinned offline adapter from CRIA Motion Factory to mixamo-llm-mocap.

This script intentionally does not download footage, models, checkpoints or rigs.
All heavy inputs live outside Git and must pass CRIA rights/provenance gates first.
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Iterable

PINNED_SOURCE = "squall01337/mixamo-llm-mocap"
PINNED_REVISION = "00dfd5385506022d533c84f6737a09f5f4392623"
REQUIRED_PIPELINE_FILES = (
    "pipeline/estimate_pose_gvhmr.py",
    "pipeline/analyze_landmarks.py",
    "pipeline/lift_to_mixamo.py",
    "pipeline/run_in_blender.py",
    "pipeline/qa_clip.py",
    "pipeline/compare_reference.py",
    "pipeline/compare_pair.py",
    "pipeline/render_preview.py",
)
REQUIRED_SPEC_FIELDS = (
    "name",
    "action_name",
    "landmarks",
    "joints_out",
    "armature",
    "rig_profile",
    "src_fps",
    "dst_fps",
)


def _run(cmd: list[str], cwd: Path, dry_run: bool) -> None:
    print("+", " ".join(cmd))
    if not dry_run:
        subprocess.run(cmd, cwd=str(cwd), check=True)


def _git_head(root: Path) -> str:
    proc = subprocess.run(
        ["git", "rev-parse", "HEAD"],
        cwd=str(root),
        check=True,
        capture_output=True,
        text=True,
    )
    return proc.stdout.strip()


def validate_upstream(root: Path) -> None:
    if not root.is_dir():
        raise SystemExit(f"upstream root does not exist: {root}")
    missing = [name for name in REQUIRED_PIPELINE_FILES if not (root / name).is_file()]
    if missing:
        raise SystemExit("upstream checkout missing required files: " + ", ".join(missing))
    head = _git_head(root)
    if head != PINNED_REVISION:
        raise SystemExit(
            f"upstream revision mismatch: expected {PINNED_REVISION}, got {head}. "
            "Re-audit before changing the pin."
        )


def validate_spec(path: Path) -> None:
    if not path.is_file():
        raise SystemExit(f"action spec does not exist: {path}")
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise SystemExit(f"action spec root must be an object: {path}")
    missing = [field for field in REQUIRED_SPEC_FIELDS if field not in value]
    if missing:
        raise SystemExit(f"action spec missing required fields ({path}): {', '.join(missing)}")
    if int(value.get("src_fps", 0)) <= 0 or int(value.get("dst_fps", 0)) <= 0:
        raise SystemExit(f"action spec FPS values must be positive: {path}")


def _single_commands(upstream: Path, spec: Path, gvhmr_python: str, render: bool) -> Iterable[list[str]]:
    spec_s = str(spec.resolve())
    yield [gvhmr_python, str(upstream / "pipeline/lift_to_mixamo.py"), "--spec", spec_s]
    yield [sys.executable, str(upstream / "pipeline/run_in_blender.py"), "all", spec_s]
    yield [gvhmr_python, str(upstream / "pipeline/qa_clip.py"), "--spec", spec_s]
    yield [gvhmr_python, str(upstream / "pipeline/compare_reference.py"), "--spec", spec_s]
    if render:
        yield [gvhmr_python, str(upstream / "pipeline/render_preview.py"), spec_s, "--showcase"]


def cmd_estimate(args: argparse.Namespace) -> int:
    upstream = Path(args.upstream_root).resolve()
    validate_upstream(upstream)
    cmd = [
        args.gvhmr_python,
        str(upstream / "pipeline/estimate_pose_gvhmr.py"),
        "--video",
        str(Path(args.video).resolve()),
        "--out",
        str(Path(args.out).resolve()),
    ]
    if args.person:
        cmd.extend(["--person", args.person])
    _run(cmd, upstream, args.dry_run)
    return 0


def cmd_analyze(args: argparse.Namespace) -> int:
    upstream = Path(args.upstream_root).resolve()
    validate_upstream(upstream)
    cmd = [
        args.gvhmr_python,
        str(upstream / "pipeline/analyze_landmarks.py"),
        "--landmarks",
        str(Path(args.landmarks).resolve()),
    ]
    _run(cmd, upstream, args.dry_run)
    return 0


def cmd_single(args: argparse.Namespace) -> int:
    upstream = Path(args.upstream_root).resolve()
    spec = Path(args.spec).resolve()
    validate_upstream(upstream)
    validate_spec(spec)
    for command in _single_commands(upstream, spec, args.gvhmr_python, not args.skip_render):
        _run(command, upstream, args.dry_run)
    return 0


def cmd_pair(args: argparse.Namespace) -> int:
    upstream = Path(args.upstream_root).resolve()
    left = Path(args.left_spec).resolve()
    right = Path(args.right_spec).resolve()
    validate_upstream(upstream)
    validate_spec(left)
    validate_spec(right)

    for spec in (left, right):
        for command in _single_commands(upstream, spec, args.gvhmr_python, not args.skip_render):
            _run(command, upstream, args.dry_run)

    left_s = str(left)
    right_s = str(right)
    _run(
        [
            args.gvhmr_python,
            str(upstream / "pipeline/compare_pair.py"),
            "--spec",
            left_s,
            "--spec",
            right_s,
        ],
        upstream,
        args.dry_run,
    )
    _run(
        [
            sys.executable,
            str(upstream / "pipeline/run_in_blender.py"),
            "contact",
            left_s,
            "--with",
            right_s,
        ],
        upstream,
        args.dry_run,
    )
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "CRIA offline adapter for the pinned mixamo-llm-mocap revision. "
            "No runtime/Godot dependency is created."
        )
    )
    parser.add_argument("--upstream-root", required=True, help="Local pinned mixamo-llm-mocap checkout")
    parser.add_argument(
        "--gvhmr-python",
        default=sys.executable,
        help="Python executable with the upstream GVHMR environment",
    )
    parser.add_argument("--dry-run", action="store_true", help="Print commands after validation without executing them")

    sub = parser.add_subparsers(dest="command", required=True)

    estimate = sub.add_parser("estimate", help="Estimate one performer from a rights-cleared plate")
    estimate.add_argument("--video", required=True)
    estimate.add_argument("--out", required=True)
    estimate.add_argument("--person", choices=("left", "right"))
    estimate.set_defaults(func=cmd_estimate)

    analyze = sub.add_parser("analyze", help="Generate numeric landmark evidence for beat review")
    analyze.add_argument("--landmarks", required=True)
    analyze.set_defaults(func=cmd_analyze)

    single = sub.add_parser("single", help="Retarget and QA one reviewed action spec")
    single.add_argument("--spec", required=True)
    single.add_argument("--skip-render", action="store_true")
    single.set_defaults(func=cmd_single)

    pair = sub.add_parser("pair", help="Retarget, compare and mesh-check two reviewed action specs")
    pair.add_argument("--left-spec", required=True)
    pair.add_argument("--right-spec", required=True)
    pair.add_argument("--skip-render", action="store_true")
    pair.set_defaults(func=cmd_pair)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    return int(args.func(args))


if __name__ == "__main__":
    raise SystemExit(main())
