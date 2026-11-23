#!/usr/bin/env python3
"""Create handoff notes, without writing to the official Godot runtime."""
from __future__ import annotations
import argparse
from pathlib import Path
try:
    from .common import read
except ImportError:
    from common import read


def export(candidate_dir: Path, output: Path) -> None:
    meta = read(candidate_dir / "metadata.json")
    if meta.get("shipping") is not False:
        raise ValueError("cannot export shipping=true candidate")
    if meta.get("kind") == "paired_technique" and not (candidate_dir / "sync_map.json").is_file():
        raise ValueError("missing paired sync_map.json")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        "# Godot candidate handoff\n\n"
        "- This is a note, not an integrated scene or animation authority.\n"
        "- Godot 4.3+; import at 12 fps, nearest filtering, 128x128, pivot (64,96).\n"
        "- Pair attacker and defender using identical timeline and sync_map.json.\n"
        "- Bind SpriteFrames/AnimationPlayer only to **existing scenes** after human review.\n"
        "- Do not change CombatManager/TechniqueResolver or compute gameplay state from frames.\n"
        "- Validate the asset protocol sidecars and manifest in the official repository.\n"
        "- Run npm run quality, Godot import/smokes and human QA before release.\n"
        "- shipping=false; qa_status=pending.\n", encoding="utf-8")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--candidate", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    args = ap.parse_args()
    export(args.candidate, args.out)


if __name__ == "__main__":
    main()
