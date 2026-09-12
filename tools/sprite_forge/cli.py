"""Deterministic candidate packer for Cria do Tatame M4.

This is deliberately not an AI generator and never promotes assets. It turns a
PNG candidate into a traceable package, removes an optional magenta chroma key,
creates frame/contact-sheet metadata, and emits a structural validation report.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
from typing import Any, Iterable

from PIL import Image

VERSION = "0.1.0"
DEFAULT_KEY = (255, 0, 255)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def parse_hex(value: str) -> tuple[int, int, int]:
    value = value.strip().lstrip("#")
    if len(value) != 6:
        raise ValueError("cor da chave deve estar no formato RRGGBB")
    try:
        rgb = tuple(int(value[index : index + 2], 16) for index in (0, 2, 4))
    except ValueError as exc:
        raise ValueError("cor da chave invalida") from exc
    return rgb  # type: ignore[return-value]


def split_frames(image: Image.Image, frame_width: int | None, frame_height: int | None) -> list[Image.Image]:
    if frame_width is None and frame_height is None:
        return [image.copy()]
    if frame_width is None or frame_height is None:
        raise ValueError("frame-width e frame-height devem ser usados juntos")
    if frame_width <= 0 or frame_height <= 0:
        raise ValueError("dimensoes de frame devem ser positivas")
    if image.width % frame_width or image.height % frame_height:
        raise ValueError("a imagem nao fecha uma grade inteira de frames")
    frames: list[Image.Image] = []
    for top in range(0, image.height, frame_height):
        for left in range(0, image.width, frame_width):
            frames.append(image.crop((left, top, left + frame_width, top + frame_height)))
    return frames


def cleanup_chroma(image: Image.Image, key: tuple[int, int, int], threshold: int) -> tuple[Image.Image, int, int]:
    """Remove a chave de cor e reduz fringe magenta de forma deterministica."""
    if threshold < 0:
        raise ValueError("threshold nao pode ser negativo")
    rgba = image.convert("RGBA")
    cleaned: list[tuple[int, int, int, int]] = []
    removed = 0
    softened = 0
    kr, kg, kb = key
    for r, g, b, alpha in rgba.getdata():
        if alpha == 0 or threshold == 0:
            cleaned.append((r, g, b, alpha))
            continue
        distance = math.sqrt((r - kr) ** 2 + (g - kg) ** 2 + (b - kb) ** 2)
        if distance <= threshold:
            if distance <= threshold * 0.45:
                cleaned.append((r, g, b, 0))
                removed += 1
                continue
            ratio = (distance - threshold * 0.45) / (threshold * 0.55)
            new_alpha = max(0, min(alpha, int(alpha * ratio)))
            spill = max(0, min(r, b) - g)
            new_green = min(255, g + int(spill * 0.8))
            cleaned.append((r, new_green, b, new_alpha))
            softened += 1
            continue
        cleaned.append((r, g, b, alpha))
    output = Image.new("RGBA", rgba.size)
    output.putdata(cleaned)
    return output, removed, softened


def make_contact_sheet(frames: list[Image.Image], columns: int = 8) -> Image.Image:
    if not frames:
        raise ValueError("nenhum frame para contact sheet")
    columns = max(1, min(columns, len(frames)))
    frame_width = max(frame.width for frame in frames)
    frame_height = max(frame.height for frame in frames)
    rows = math.ceil(len(frames) / columns)
    sheet = Image.new("RGBA", (columns * frame_width, rows * frame_height), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        x = (index % columns) * frame_width
        y = (index // columns) * frame_height
        sheet.alpha_composite(frame, (x, y))
    return sheet


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def write_license_template(path: Path, asset_id: str, source: Path) -> None:
    write_json(
        path,
        {
            "schema_version": 1,
            "asset_id": asset_id,
            "status": "pending_human_review",
            "source": {"path": str(source), "sha256": sha256(source)},
            "model": None,
            "resolved_revision": None,
            "dataset": None,
            "adapters": [],
            "license_chain": [],
            "human_signoff": None,
            "notes": "Preencher e revisar antes de qualquer promocao; este arquivo nao e uma aprovacao.",
        },
    )


def generate2dsprite(args: argparse.Namespace) -> int:
    source = Path(args.input).resolve()
    if not source.is_file():
        raise FileNotFoundError(f"input nao encontrado: {source}")
    output = Path(args.output_dir).resolve()
    output.mkdir(parents=True, exist_ok=True)
    image = Image.open(source).convert("RGBA")
    key = parse_hex(args.chroma_key)
    clean, removed, softened = cleanup_chroma(image, key, args.key_threshold)
    frames = split_frames(clean, args.frame_width, args.frame_height)

    image.save(output / "raw_sheet.png")
    clean.save(output / "clean_sheet.png")
    clean.save(output / "spritesheet.png")
    frames_dir = output / "frames"
    frames_dir.mkdir(exist_ok=True)
    for index, frame in enumerate(frames):
        frame.save(frames_dir / f"frame_{index:03d}.png")

    contact = make_contact_sheet(frames, args.columns)
    contact.save(output / "contact_sheet.png")
    frames[0].save(
        output / "preview.gif",
        save_all=True,
        append_images=frames[1:],
        duration=max(1, int(1000 / args.fps)),
        loop=0,
        disposal=2,
        transparency=0,
    )

    frame_width, frame_height = frames[0].size
    metadata = {
        "schema_version": 1,
        "tool": "cria_sprite_forge_compat",
        "tool_version": VERSION,
        "asset_id": args.asset_id,
        "source": {"path": str(source), "sha256": sha256(source)},
        "image": {"width": clean.width, "height": clean.height, "mode": "RGBA"},
        "frame_size": [frame_width, frame_height],
        "frame_count": len(frames),
        "fps": args.fps,
        "loop": True,
        "pivot": {"x": frame_width // 2, "y": frame_height - 1, "anchor": "bottom_center"},
        "grid_px": args.grid_px,
        "chroma_key": {"color": args.chroma_key, "threshold": args.key_threshold},
        "cleanup": {"key_pixels_removed": removed, "edge_pixels_softened": softened},
        "state": "automated_qa_pass_pending_human",
    }
    write_json(output / "metadata.json", metadata)
    write_license_template(output / "license.json", args.asset_id, source)
    (output / "import_notes.md").write_text(
        "# Import notes\n\n"
        "- Importar como RGBA.\n"
        "- Usar filtro nearest-neighbor.\n"
        "- Preservar o pivot `bottom_center` registrado no metadata.\n"
        "- Nao integrar automaticamente em uma cena Godot.\n",
        encoding="utf-8",
    )
    (output / "qa_report.md").write_text(
        "# QA report\n\n"
        "- Structural package: PASS\n"
        f"- Frames: {len(frames)} at {args.fps} FPS\n"
        f"- Chroma pixels removed: {removed}\n"
        f"- Edge pixels softened: {softened}\n"
        "- License/canon/human visual review: PENDING\n"
        "- Promotion: FORBIDDEN\n",
        encoding="utf-8",
    )
    print(json.dumps({"ok": True, "output_dir": str(output), "frame_count": len(frames), "state": metadata["state"]}, ensure_ascii=False, indent=2))
    return 0


def map_sheet(args: argparse.Namespace) -> int:
    source = Path(args.input).resolve()
    if not source.is_file():
        raise FileNotFoundError(f"input nao encontrado: {source}")
    image = Image.open(source).convert("RGBA")
    if args.frame_width <= 0 or args.frame_height <= 0:
        raise ValueError("dimensoes de frame devem ser positivas")
    if image.width % args.frame_width or image.height % args.frame_height:
        raise ValueError("a imagem nao fecha uma grade inteira de frames")
    labels = [item.strip() for item in args.labels.split(",") if item.strip()]
    regions: list[dict[str, Any]] = []
    index = 0
    for top in range(0, image.height, args.frame_height):
        for left in range(0, image.width, args.frame_width):
            name = labels[index] if index < len(labels) else f"frame_{index:03d}"
            regions.append(
                {
                    "name": name,
                    "index": index,
                    "rect": {"x": left, "y": top, "w": args.frame_width, "h": args.frame_height},
                    "pivot": {"x": args.frame_width // 2, "y": args.frame_height - 1, "anchor": "bottom_center"},
                }
            )
            index += 1
    destination = Path(args.output).resolve()
    write_json(
        destination,
        {
            "schema_version": 1,
            "tool": "cria_sprite_forge_compat",
            "tool_version": VERSION,
            "source": {"path": str(source), "sha256": sha256(source)},
            "sheet_size": [image.width, image.height],
            "frame_size": [args.frame_width, args.frame_height],
            "regions": regions,
            "state": "automated_qa_pass_pending_human",
        },
    )
    print(json.dumps({"ok": True, "output": str(destination), "regions": len(regions)}, ensure_ascii=False, indent=2))
    return 0


def validate_package(args: argparse.Namespace) -> int:
    root = Path(args.package_dir).resolve()
    required = [
        "raw_sheet.png",
        "clean_sheet.png",
        "spritesheet.png",
        "frames",
        "preview.gif",
        "contact_sheet.png",
        "metadata.json",
        "import_notes.md",
        "qa_report.md",
        "license.json",
    ]
    errors: list[str] = [item for item in required if not (root / item).exists()]
    metadata: dict[str, Any] = {}
    license_data: dict[str, Any] = {}
    if not errors:
        try:
            metadata = json.loads((root / "metadata.json").read_text(encoding="utf-8"))
            license_data = json.loads((root / "license.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            errors.append(f"metadata/licence invalido: {exc}")
    frame_files = sorted((root / "frames").glob("frame_*.png")) if (root / "frames").exists() else []
    if not frame_files:
        errors.append("frames sem PNGs")
    expected_count = metadata.get("frame_count")
    if expected_count is not None and expected_count != len(frame_files):
        errors.append(f"frame_count={expected_count} mas encontrados={len(frame_files)}")
    for filename in ("raw_sheet.png", "clean_sheet.png", "spritesheet.png", "contact_sheet.png"):
        path = root / filename
        if path.exists():
            try:
                with Image.open(path) as image:
                    if image.mode not in {"RGBA", "LA", "P"}:
                        errors.append(f"{filename} sem canal de transparencia: {image.mode}")
            except OSError as exc:
                errors.append(f"{filename} invalido: {exc}")
    if license_data and license_data.get("status") not in {"pending_human_review", "approved_by_human"}:
        errors.append("license.json sem estado reconhecido")
    result = {
        "ok": not errors,
        "package": str(root),
        "errors": errors,
        "state": "automated_qa_pass_pending_human" if not errors else "blocked",
        "license_status": license_data.get("status", "missing"),
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if not errors else 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Compatibilizador deterministico do M4")
    sub = parser.add_subparsers(dest="command", required=True)
    generate = sub.add_parser("generate2dsprite", help="empacota e limpa um PNG candidato")
    generate.add_argument("--input", required=True)
    generate.add_argument("--output-dir", required=True)
    generate.add_argument("--asset-id", required=True)
    generate.add_argument("--frame-width", type=int)
    generate.add_argument("--frame-height", type=int)
    generate.add_argument("--fps", type=int, default=12)
    generate.add_argument("--grid-px", type=int, default=16)
    generate.add_argument("--columns", type=int, default=8)
    generate.add_argument("--chroma-key", default="#FF00FF")
    generate.add_argument("--key-threshold", type=int, default=24)
    generate.set_defaults(handler=generate2dsprite)

    mapping = sub.add_parser("map", help="gera mapa deterministico de regioes do spritesheet")
    mapping.add_argument("--input", required=True)
    mapping.add_argument("--output", required=True)
    mapping.add_argument("--frame-width", type=int, required=True)
    mapping.add_argument("--frame-height", type=int, required=True)
    mapping.add_argument("--labels", default="")
    mapping.set_defaults(handler=map_sheet)

    validate = sub.add_parser("validate", help="valida a estrutura de um pacote candidato")
    validate.add_argument("--package-dir", required=True)
    validate.set_defaults(handler=validate_package)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    return int(args.handler(args))


if __name__ == "__main__":
    raise SystemExit(main())
