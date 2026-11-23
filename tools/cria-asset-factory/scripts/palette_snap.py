#!/usr/bin/env python3
"""Snap existing PNGs to the canonical palette, never create new artwork."""
from __future__ import annotations
import argparse
from pathlib import Path
from PIL import Image
try:
    from .common import FACTIONS, output_dir, pngs, snap
except ImportError:
    from common import FACTIONS, output_dir, pngs, snap


def run(source: Path, out: Path, faction: str | None = None) -> None:
    inp = [source] if source.is_file() else pngs(source)
    if not inp or any(x.suffix.lower() != ".png" for x in inp):
        raise ValueError("PNG input required")
    output_dir(out)
    for p in inp:
        with Image.open(p) as image:
            snap(image, faction).save(out / p.name)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--input", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--faction", choices=FACTIONS)
    args = ap.parse_args()
    run(args.input, args.out, args.faction)


if __name__ == "__main__":
    main()
