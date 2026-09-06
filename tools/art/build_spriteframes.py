#!/usr/bin/env python3
"""Build deterministic Godot SpriteFrames resources offline.

Input layout:
  assets/chars/frames/<char_id>/<anim>/<frame>.png
Output:
  assets/chars/frames/<char_id>/<anim>.tres

Runtime code never scans frame directories.
"""
from __future__ import annotations

import pathlib
import sys

FPS = 12.0
ROOT = pathlib.Path("assets/chars/frames")


def _resource_text(pngs: list[pathlib.Path]) -> str:
    lines = [f'[gd_resource type="SpriteFrames" load_steps={len(pngs) + 1} format=3]', ""]
    for index, path in enumerate(pngs, 1):
        lines.append(
            f'[ext_resource type="Texture2D" path="res://{path.as_posix()}" id="{index}"]'
        )
    lines.extend(["", "[resource]", "animations = [{", '"frames": ['])
    for index in range(1, len(pngs) + 1):
        comma = "," if index < len(pngs) else ""
        lines.extend(
            [
                "{",
                '"duration": 1.0,',
                f'"texture": ExtResource("{index}")',
                f"}}{comma}",
            ]
        )
    lines.extend(
        [
            "],",
            '"loop": true,',
            '"name": &"default",',
            f'"speed": {FPS}',
            "}]",
        ]
    )
    return "\n".join(lines) + "\n"


def build_character(char_dir: pathlib.Path) -> int:
    written = 0
    for anim_dir in sorted(path for path in char_dir.iterdir() if path.is_dir()):
        pngs = sorted(anim_dir.glob("*.png"))
        if not pngs:
            continue
        out = char_dir / f"{anim_dir.name}.tres"
        out.write_text(_resource_text(pngs), encoding="utf-8")
        print("wrote", out)
        written += 1
    return written


def main() -> int:
    if not ROOT.exists():
        print(f"no frame root: {ROOT}")
        return 0
    total = 0
    for char_dir in sorted(path for path in ROOT.iterdir() if path.is_dir()):
        total += build_character(char_dir)
    print(f"built {total} SpriteFrames resource(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
