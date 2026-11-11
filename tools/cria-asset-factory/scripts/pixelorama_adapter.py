#!/usr/bin/env python3
"""Export a human-edited Pixelorama .pxo as candidate spritesheet.

Requires a *separately installed desktop Pixelorama binary* and a licensed
project. Dry-run unless --export. Does not touch Godot runtime directories.
"""
from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]


def command(binary: Path, project: Path, output: Path) -> list[str]:
    if project.suffix.lower() != ".pxo" or not project.is_file():
        raise ValueError("existing Pixelorama .pxo project required")
    if output.suffix.lower() != ".png" or output.exists():
        raise ValueError("new PNG output path required")
    if any(output.resolve().is_relative_to((ROOT / item).resolve()) for item in ("src", "scenes", "assets", "data")):
        raise ValueError("output may not enter official runtime/asset paths")
    if not binary.is_file():
        raise FileNotFoundError(binary)
    return [str(binary), "--headless", "--quit", "--",
            "--export", "--spritesheet", "--output", str(output.resolve()),
            str(project.resolve())]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--project", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--binary", type=Path,
                    help="Desktop Pixelorama executable. Otherwise resolved from PATH.")
    ap.add_argument("--export", action="store_true", help="Opt-in to writing a new PNG spritesheet")
    args = ap.parse_args()
    resolved = shutil.which("pixelorama") or shutil.which("Pixelorama")
    binary = args.binary or (Path(resolved) if resolved else Path("__pixelorama_missing__"))
    try:
        cmd = command(binary, args.project, args.out)
        if args.export:
            args.out.parent.mkdir(parents=True, exist_ok=True)
            subprocess.run(cmd, check=True)
            if not args.out.is_file():
                raise RuntimeError("Pixelorama returned successfully but no PNG was exported")
        print(json.dumps({"status": "EXPORTED_CANDIDATE" if args.export else "DRY_RUN_VALID",
                          "command": cmd, "shipping": False,
                          "qa_status": "pending"}, indent=2))
        return 0
    except (FileNotFoundError, ValueError, RuntimeError, subprocess.CalledProcessError) as exc:
        ap.error(str(exc))
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
