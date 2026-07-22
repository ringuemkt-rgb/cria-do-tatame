#!/usr/bin/env python3
"""Pack cleaned PNG frames into a deterministic Godot-ready sprite atlas."""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path
from typing import Any

from PIL import Image


def discover_frames(input_dir: Path) -> list[Path]:
    frames = sorted(path for path in input_dir.glob("*.png") if path.is_file())
    if not frames:
        raise ValueError(f"nenhum PNG encontrado em {input_dir}")
    return frames


def image_size(path: Path) -> tuple[int, int]:
    with Image.open(path) as image:
        return image.size


def pack_frames(
    frame_paths: list[Path],
    output_dir: Path,
    columns: int,
    cell_width: int | None,
    cell_height: int | None,
    fps: float,
    pivot_x: float,
    pivot_y: float,
    contact_y: float,
) -> dict[str, Any]:
    sizes = [image_size(path) for path in frame_paths]
    width = cell_width or max(size[0] for size in sizes)
    height = cell_height or max(size[1] for size in sizes)
    if width <= 0 or height <= 0:
        raise ValueError("celula precisa ter dimensoes positivas")
    if columns <= 0:
        columns = max(1, math.ceil(math.sqrt(len(frame_paths))))
    rows = math.ceil(len(frame_paths) / columns)
    atlas = Image.new("RGBA", (columns * width, rows * height), (0, 0, 0, 0))
    metadata_frames: list[dict[str, Any]] = []
    preview_frames: list[Image.Image] = []

    for index, path in enumerate(frame_paths):
        with Image.open(path) as source:
            frame = source.convert("RGBA")
        if frame.width > width or frame.height > height:
            raise ValueError(
                f"frame {path.name} ({frame.width}x{frame.height}) excede celula {width}x{height}; "
                "normalize os frames antes de empacotar"
            )
        col = index % columns
        row = index // columns
        offset_x = col * width + (width - frame.width) // 2
        offset_y = row * height + (height - frame.height)
        atlas.alpha_composite(frame, (offset_x, offset_y))
        padded = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        padded.alpha_composite(frame, ((width - frame.width) // 2, height - frame.height))
        preview_frames.append(padded)
        metadata_frames.append(
            {
                "index": index,
                "source": path.name,
                "rect": {"x": col * width, "y": row * height, "w": width, "h": height},
                "source_size": {"w": frame.width, "h": frame.height},
                "pivot_normalized": {"x": pivot_x, "y": pivot_y},
                "contact_y_normalized": contact_y,
                "duration_ms": round(1000.0 / fps),
            }
        )

    output_dir.mkdir(parents=True, exist_ok=True)
    atlas_path = output_dir / "spritesheet.png"
    atlas.save(atlas_path, format="PNG", optimize=False)
    gif_path = output_dir / "preview.gif"
    preview_frames[0].save(
        gif_path,
        save_all=True,
        append_images=preview_frames[1:],
        duration=round(1000.0 / fps),
        loop=0,
        disposal=2,
        transparency=0,
    )
    metadata = {
        "schema_version": "1.0.0",
        "texture_filter": "nearest",
        "frame_count": len(frame_paths),
        "fps": fps,
        "columns": columns,
        "rows": rows,
        "cell": {"w": width, "h": height},
        "atlas": {"path": atlas_path.name, "w": atlas.width, "h": atlas.height},
        "preview": gif_path.name,
        "frames": metadata_frames,
    }
    (output_dir / "atlas_metadata.json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    return metadata


def parser() -> argparse.ArgumentParser:
    value = argparse.ArgumentParser(description="Build a deterministic Godot sprite atlas from cleaned PNG frames")
    value.add_argument("input_dir", type=Path)
    value.add_argument("output_dir", type=Path)
    value.add_argument("--columns", type=int, default=0, help="0 escolhe uma grade aproximadamente quadrada")
    value.add_argument("--cell-width", type=int, default=None)
    value.add_argument("--cell-height", type=int, default=None)
    value.add_argument("--fps", type=float, default=12.0)
    value.add_argument("--pivot-x", type=float, default=0.5)
    value.add_argument("--pivot-y", type=float, default=1.0)
    value.add_argument("--contact-y", type=float, default=1.0)
    return value


def main() -> int:
    args = parser().parse_args()
    try:
        if args.fps <= 0:
            raise ValueError("--fps precisa ser positivo")
        for name in ("pivot_x", "pivot_y", "contact_y"):
            value = float(getattr(args, name))
            if not 0.0 <= value <= 1.0:
                raise ValueError(f"--{name.replace('_', '-')} precisa ficar entre 0 e 1")
        frames = discover_frames(args.input_dir)
        result = pack_frames(
            frames,
            args.output_dir,
            args.columns,
            args.cell_width,
            args.cell_height,
            args.fps,
            args.pivot_x,
            args.pivot_y,
            args.contact_y,
        )
        print(json.dumps({"ok": True, **result}, ensure_ascii=False, indent=2))
        return 0
    except (OSError, ValueError) as exc:
        print(json.dumps({"ok": False, "error": str(exc)}, ensure_ascii=False), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
