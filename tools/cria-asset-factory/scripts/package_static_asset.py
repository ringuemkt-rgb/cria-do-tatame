#!/usr/bin/env python3
"""Copy existing licensed static PNG artwork to a candidate pack (no generation)."""
from __future__ import annotations
import argparse
from pathlib import Path
try:
    from .common import candidate, copy_frame, json_write, output_dir, pngs, safe_id, sidecars
except ImportError:
    from common import candidate, copy_frame, json_write, output_dir, pngs, safe_id, sidecars

KINDS = {"arena", "map", "icon", "prop", "ui", "identity"}


def run(kind: str, asset_id: str, source: Path, out: Path,
        origin: str, license_id: str) -> None:
    if kind not in KINDS:
        raise ValueError("not a supported static asset kind")
    safe_id(asset_id)
    inputs = [source] if source.is_file() else pngs(source)
    if not inputs or any(p.suffix.lower() != ".png" for p in inputs):
        raise ValueError("real source PNG files are required")
    if kind == "map" and len(inputs) != 1:
        raise ValueError("map requires exactly one 1536x864 PNG")
    if kind == "arena" and {p.name for p in inputs} != {f"L{i}.png" for i in range(6)}:
        raise ValueError("arena requires L0.png..L5.png")
    from PIL import Image
    if kind == "map":
        with Image.open(inputs[0]) as img:
            if img.size != (1536, 864):
                raise ValueError("map must be 1536x864")
    output_dir(out)
    for src in inputs:
        dst = out / src.name
        copy_frame(src, dst)
        sidecars(dst, origin, license_id)
    json_write(out / "metadata.json", candidate(kind, id=asset_id, input_files=[x.name for x in inputs],
               origin=origin, license_id=license_id, rights_reviewed=False))
    (out / "qa_report.md").write_text(
        "# Static candidate\n\n- [ ] Art review\n- [ ] Rights\n- [ ] Godot import\n\nshipping=false\n",
        encoding="utf-8")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--kind", required=True, choices=sorted(KINDS))
    ap.add_argument("--id", required=True)
    ap.add_argument("--input", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--origin", default="UNKNOWN")
    ap.add_argument("--license", default="UNKNOWN")
    args = ap.parse_args()
    run(args.kind, args.id, args.input, args.out, args.origin, args.license)


if __name__ == "__main__":
    main()
