#!/usr/bin/env python3
"""Extract licensed video frames at 12 fps and normalize to 128x128 nearest.

Example:
  python scripts/extract_frames.py --video /tmp/source.mp4 --out /tmp/raw
"""
from __future__ import annotations
import argparse
import shutil
import subprocess
from pathlib import Path


def extract(video: Path, out: Path, fps: int = 12) -> None:
    if not video.is_file():
        raise FileNotFoundError(video)
    if not shutil.which("ffmpeg"):
        raise RuntimeError("FFmpeg executable is required on PATH")
    if out.exists() and any(out.iterdir()):
        raise FileExistsError("output directory must be empty")
    out.mkdir(parents=True, exist_ok=True)
    cmd = ["ffmpeg", "-hide_banner", "-nostdin", "-v", "error", "-i", str(video),
           "-vf", f"fps={fps},scale=128:128:flags=neighbor,format=rgba",
           "-fps_mode", "vfr", "-start_number", "0", str(out / "frame_%04d.png")]
    subprocess.run(cmd, check=True)
    if not list(out.glob("frame_*.png")):
        raise RuntimeError("extraction produced no frames")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--video", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--fps", type=int, default=12)
    args = ap.parse_args()
    if args.fps <= 0:
        ap.error("fps must be positive")
    extract(args.video, args.out, args.fps)


if __name__ == "__main__":
    main()
