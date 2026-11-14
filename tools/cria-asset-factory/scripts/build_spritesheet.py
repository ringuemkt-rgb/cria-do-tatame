#!/usr/bin/env python3
"""Build raw -> clean -> final, SpriteSheet, preview.gif and contact_sheet.

Requires user-supplied, rights-cleared 128x128 PNG inputs.
"""
from __future__ import annotations
import argparse
import math
from pathlib import Path
from PIL import Image, ImageDraw
try:
    from .common import SIZE, FPS, FACTIONS, candidate, copy_frame, json_write, output_dir, pngs, sidecars, snap
except ImportError:
    from common import SIZE, FPS, FACTIONS, candidate, copy_frame, json_write, output_dir, pngs, sidecars, snap


def build(source: Path, dest: Path, kind: str = "animation", faction: str | None = None,
          origin: str = "UNKNOWN", license_id: str = "UNKNOWN", fps: int = FPS) -> dict:
    inputs = pngs(source)
    if fps <= 0:
        raise ValueError("fps must be positive")
    if dest.resolve() == source.resolve() or source.resolve().is_relative_to(dest.resolve()):
        raise ValueError("input cannot be inside output")
    output_dir(dest)
    for part in ("raw", "clean", "final"):
        (dest / part).mkdir(parents=True)
    frames: list[Image.Image] = []
    for ix, input_file in enumerate(inputs):
        name = f"frame_{ix:04d}.png"
        copy_frame(input_file, dest / "raw" / name)
        with Image.open(input_file) as original:
            if original.size != SIZE:
                raise ValueError(f"{input_file} must be exactly {SIZE}")
            clean = snap(original, faction)
        clean.save(dest / "clean" / name)
        clean.save(dest / "final" / name)
        sidecars(dest / "final" / name, origin, license_id)
        frames.append(clean)
    sheet = Image.new("RGBA", (128 * len(frames), 128), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        sheet.alpha_composite(frame, (128 * i, 0))
    sheet.save(dest / "spritesheet.png")
    duration = int(round(1000 / fps))
    frames[0].save(dest / "preview.gif", save_all=True, append_images=frames[1:],
                   duration=duration, loop=0, disposal=2, optimize=False)
    cols = min(6, len(frames))
    rows = math.ceil(len(frames) / cols)
    contact = Image.new("RGBA", (cols * 128, rows * 148), "#0B0B0D")
    painter = ImageDraw.Draw(contact)
    for i, frame in enumerate(frames):
        x, y = i % cols * 128, i // cols * 148
        contact.alpha_composite(frame, (x, y))
        painter.text((x + 3, y + 131), str(i), fill="#EDE6D6")
    contact.save(dest / "contact_sheet.png")
    metadata = candidate(kind, frame_count=len(frames), frame_size=[128, 128],
                         fps=fps, faction=faction, origin=origin, license_id=license_id)
    json_write(dest / "metadata.json", metadata)
    (dest / "qa_report.md").write_text(
        "# Mechanical candidate build only\n\n- [ ] Human visual check\n"
        "- [ ] Rights review\n- [ ] Godot scene check\n- [ ] npm run quality\n"
        "\nshipping=false\n", encoding="utf-8")
    return metadata


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--input", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--faction", choices=FACTIONS)
    ap.add_argument("--fps", type=int, default=12)
    ap.add_argument("--origin", default="UNKNOWN")
    ap.add_argument("--license", default="UNKNOWN")
    args = ap.parse_args()
    print(build(args.input, args.out, faction=args.faction, origin=args.origin,
                license_id=args.license, fps=args.fps))


if __name__ == "__main__":
    main()
