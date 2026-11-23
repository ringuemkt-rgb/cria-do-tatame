#!/usr/bin/env python3
"""Transcode user-provided licensed WAV sources; never synthesize sound.

Expected manifest: {"packs":[{"id":"tatame_impacts","source":"tatame.wav"}, ...]}
"""
from __future__ import annotations
import argparse
import json
import shutil
import subprocess
from pathlib import Path
try:
    from .common import candidate, json_write, safe_id
except ImportError:
    from common import candidate, json_write, safe_id


def build(source_dir: Path, manifest: Path, out: Path) -> None:
    if not shutil.which("ffmpeg"):
        raise RuntimeError("ffmpeg required")
    data = json.loads(manifest.read_text(encoding="utf-8"))
    jobs = data.get("packs", [])
    if not isinstance(jobs, list) or not jobs:
        raise ValueError("audio manifest must have nonempty packs")
    for job in jobs:
        pack_id = safe_id(job["id"])
        src_name = job.get("source")
        if not isinstance(src_name, str) or Path(src_name).name != src_name:
            raise ValueError(f"{pack_id}: invalid source filename")
        source = source_dir / src_name
        if not source.is_file() or source.suffix.lower() != ".wav":
            raise FileNotFoundError(f"{pack_id}: real source WAV required: {source}")
    if out.exists() and any(out.iterdir()):
        raise FileExistsError("output must be empty")
    out.mkdir(parents=True, exist_ok=True)
    for job in jobs:
        src = source_dir / job["source"]
        dest = out / job["id"]
        dest.mkdir()
        master, runtime = dest / "master.wav", dest / "runtime.ogg"
        subprocess.run(["ffmpeg", "-hide_banner", "-nostdin", "-v", "error", "-y",
                        "-i", str(src), "-ar", "48000", "-acodec", "pcm_s24le",
                        str(master)], check=True)
        subprocess.run(["ffmpeg", "-hide_banner", "-nostdin", "-v", "error", "-y",
                        "-i", str(master), "-c:a", "libvorbis", "-q:a", "5",
                        str(runtime)], check=True)
        json_write(dest / "audio_metadata.json", candidate(
            "audio_pack", id=job["id"], source=str(src), master="master.wav",
            runtime="runtime.ogg", loudness_reviewed=False, licensed=False))
        json_write(dest / "metadata.json", candidate("audio_pack", id=job["id"]))
        (dest / "license.txt").write_text(
            "PENDING rights verification; shipping=false\n", encoding="utf-8")
        (dest / "qa_report.md").write_text(
            "# Audio candidate\n\n- [ ] Rights\n- [ ] Loudness\n- [ ] Game mix\n\nshipping=false\n",
            encoding="utf-8")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--source-dir", type=Path, required=True)
    ap.add_argument("--manifest", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    args = ap.parse_args()
    build(args.source_dir, args.manifest, args.out)


if __name__ == "__main__":
    main()
