#!/usr/bin/env python3
"""M3 gameplay-frame gate for the 2.5D Pixel Art protocol.

Only gameplay frames under assets/chars/frames are checked here. Reference boards,
portraits, arenas, UI and branding have separate contracts.
"""
from __future__ import annotations

import argparse
import json
import pathlib
import sys

from PIL import Image

FRAME_SIZE = (128, 128)
PIVOT = [64, 96]
CANON = {
    (30, 58, 95), (45, 80, 22), (212, 165, 116), (184, 92, 56),
    (232, 223, 208), (26, 26, 26), (184, 134, 11), (139, 0, 0),
    (57, 255, 20), (75, 0, 130), (11, 11, 13), (201, 151, 28),
    (237, 230, 214), (74, 74, 74),
}
REQUIRED_SIDECARS = ("license", "provenance", "qa")


def _sidecar(png: pathlib.Path, kind: str) -> pathlib.Path:
    return png.with_suffix(f".{kind}.json")


def _read_json(path: pathlib.Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError("root must be an object")
    return value


def check_frame(png: pathlib.Path) -> list[str]:
    errors: list[str] = []
    with Image.open(png) as source:
        image = source.convert("RGBA")
    if image.size != FRAME_SIZE:
        errors.append(f"size={image.size}, expected={FRAME_SIZE}")
        return errors

    for x, y, rgba in ((x, y, image.getpixel((x, y))) for y in range(128) for x in range(128)):
        r, g, b, a = rgba
        if a not in (0, 255):
            errors.append(f"anti_alias_alpha@{x},{y}:{a}")
            break
        if a == 255 and (r, g, b) not in CANON:
            errors.append(f"off_palette@{x},{y}:#{r:02X}{g:02X}{b:02X}")
            break

    alpha = image.getchannel("A").resize((32, 32), Image.Resampling.NEAREST)
    if alpha.getbbox() is None or sum(1 for value in alpha.getdata() if value) < 8:
        errors.append("silhouette_32px_unreadable")

    for kind in REQUIRED_SIDECARS:
        path = _sidecar(png, kind)
        if not path.exists():
            errors.append(f"missing_sidecar:{path.name}")
            continue
        try:
            data = _read_json(path)
        except (OSError, ValueError, json.JSONDecodeError) as exc:
            errors.append(f"invalid_sidecar:{path.name}:{exc}")
            continue
        if kind == "qa" and data.get("pivot") != PIVOT:
            errors.append(f"qa_pivot!={PIVOT}")
        if data.get("shipping") is True:
            errors.append(f"premature_shipping:{path.name}")

    return errors


def check_manifest(repo_root: pathlib.Path, frame_paths: list[pathlib.Path]) -> list[str]:
    manifest_path = repo_root / "assets/manifest_v2.json"
    if not manifest_path.exists():
        return ["missing assets/manifest_v2.json"]
    try:
        manifest = _read_json(manifest_path)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        return [f"invalid manifest_v2.json: {exc}"]
    indexed = {item.get("path") for item in manifest.get("assets", []) if isinstance(item, dict)}
    errors: list[str] = []
    for frame in frame_paths:
        rel = frame.relative_to(repo_root / "assets").as_posix()
        if rel not in indexed:
            errors.append(f"manifest_missing:{rel}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default="assets/chars/frames")
    args = parser.parse_args()
    repo_root = pathlib.Path.cwd()
    root = repo_root / args.root
    frames = sorted(root.rglob("*.png")) if root.exists() else []
    failures = 0
    for frame in frames:
        errors = check_frame(frame)
        if errors:
            failures += 1
            print("FAIL", frame, " | ".join(errors))
    manifest_errors = check_manifest(repo_root, frames)
    for error in manifest_errors:
        failures += 1
        print("FAIL", error)
    if failures:
        print(f"asset protocol failed: {failures} failure(s)")
        return 1
    print(f"asset protocol PASS: {len(frames)} gameplay frame(s) checked")
    return 0


if __name__ == "__main__":
    sys.exit(main())
