#!/usr/bin/env python3
"""Empacota animações prioritárias e o animatic pareado do lote visual v02."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import shutil
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw

from build_character_pose_library import (
    grid_crop,
    keep_significant_alpha_components,
)
from chroma_key_asset import remove_chroma
from normalize_sprite_strip_to_anchor import alpha_bbox


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CATALOG = "data/visual/character_animation_batch_v02.json"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Constrói packs de animação do lote v02.")
    parser.add_argument("--catalog", default=DEFAULT_CATALOG)
    parser.add_argument("--job", help="Executa apenas character_id:source_action_id.")
    parser.add_argument("--animatic-only", action="store_true")
    return parser.parse_args()


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def normalize_sequence(
    cells: list[Image.Image],
    anchor: Image.Image,
    frame_size: int,
    lock_first: bool,
    lock_last: bool,
) -> tuple[list[Image.Image], tuple[int, int]]:
    anchor = anchor.convert("RGBA")
    if anchor.size != (frame_size, frame_size):
        anchor = anchor.resize((frame_size, frame_size), Image.Resampling.NEAREST)
    anchor_box = alpha_bbox(anchor, 8)
    if anchor_box is None:
        raise ValueError("Âncora sem conteúdo alfa.")
    contents: list[Image.Image] = []
    for cell in cells:
        box = alpha_bbox(cell, 8)
        if box is None:
            raise ValueError("Quadro gerado sem conteúdo alfa.")
        contents.append(cell.crop(box))

    center_x = round((anchor_box[0] + anchor_box[2]) / 2)
    ground_y = anchor_box[3]
    anchor_height = anchor_box[3] - anchor_box[1]
    available_width = 2 * min(center_x, frame_size - center_x)
    max_width = max(content.width for content in contents)
    max_height = max(content.height for content in contents)
    scale = min(anchor_height / max_height, available_width / max_width)

    frames: list[Image.Image] = []
    for content in contents:
        width = max(1, round(content.width * scale))
        height = max(1, round(content.height * scale))
        resized = content.resize((width, height), Image.Resampling.NEAREST)
        frame = Image.new("RGBA", (frame_size, frame_size), (0, 0, 0, 0))
        frame.alpha_composite(resized, (round(center_x - width / 2), ground_y - height))
        frames.append(frame)
    if lock_first:
        frames[0] = anchor.copy()
    if lock_last:
        frames[-1] = anchor.copy()
    return frames, (center_x, ground_y)


def build_contact_sheet(frames: list[Image.Image], frame_size: int) -> Image.Image:
    gap = 8
    width = len(frames) * frame_size + (len(frames) - 1) * gap
    board = Image.new("RGBA", (width, frame_size), (18, 20, 24, 255))
    draw = ImageDraw.Draw(board)
    colors = ((238, 241, 244, 255), (211, 217, 223, 255))
    for y in range(0, frame_size, 24):
        for x in range(0, width, 24):
            draw.rectangle(
                (x, y, min(width, x + 24), min(frame_size, y + 24)),
                fill=colors[((x // 24) + (y // 24)) % 2],
            )
    for index, frame in enumerate(frames):
        board.alpha_composite(frame, (index * (frame_size + gap), 0))
    return board


def write_gif(frames: list[Image.Image], path: Path, fps: int) -> None:
    duration = round(1000 / fps)
    frames[0].save(
        path,
        save_all=True,
        append_images=frames[1:],
        duration=duration,
        loop=0,
        disposal=2,
    )


def build_job(job: dict[str, Any]) -> dict[str, Any]:
    raw_path = ROOT / str(job["raw_chroma"])
    anchor_path = ROOT / str(job["anchor"])
    output_dir = ROOT / str(job["output"])
    if not raw_path.is_file():
        raise FileNotFoundError(raw_path)
    if not anchor_path.is_file():
        raise FileNotFoundError(anchor_path)
    output_dir.mkdir(parents=True, exist_ok=True)
    frames_dir = output_dir / "frames"
    frames_dir.mkdir(parents=True, exist_ok=True)

    clean = remove_chroma(Image.open(raw_path), str(job["key"]), 15)
    raw_copy = output_dir / "raw_sheet.png"
    clean_path = output_dir / "clean_sheet.png"
    shutil.copyfile(raw_path, raw_copy)
    clean.save(clean_path, optimize=True)

    columns = int(job["grid"]["columns"])
    rows = int(job["grid"]["rows"])
    frame_count = int(job["frame_count"])
    if frame_count > columns * rows:
        raise ValueError("frame_count excede a grade")
    paired = bool(str(job.get("paired_character_id", "")))
    cells: list[Image.Image] = []
    for index in range(frame_count):
        cell = grid_crop(
            clean,
            index,
            columns,
            rows,
            overlap_ratio=0.0,
            isolate_component=False,
        )
        cell = keep_significant_alpha_components(
            cell,
            max_components=2 if paired else 1,
            min_relative_area=0.25,
        )
        cells.append(cell)

    frame_size = int(job["frame_size"])
    frames, pivot = normalize_sequence(
        cells,
        Image.open(anchor_path),
        frame_size,
        bool(job.get("lock_first_to_anchor", False)),
        bool(job.get("lock_last_to_anchor", False)),
    )
    for index, frame in enumerate(frames, start=1):
        frame.save(frames_dir / f"{index:02d}.png", optimize=True)

    atlas = Image.new("RGBA", (frame_size * frame_count, frame_size), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        atlas.alpha_composite(frame, (index * frame_size, 0))
    atlas_path = output_dir / "spritesheet.png"
    atlas.save(atlas_path, optimize=True)
    preview_path = output_dir / "preview.gif"
    write_gif(frames, preview_path, int(job["fps"]))
    contact_path = output_dir / "contact_sheet.png"
    build_contact_sheet(frames, frame_size).save(contact_path, optimize=True)

    duration = round(1000 / int(job["fps"]))
    layout = [
        {
            "index": index,
            "state": str(job["action_id"]),
            "path": f"frames/{index + 1:02d}.png",
            "sha256": sha256(frames_dir / f"{index + 1:02d}.png"),
            "x": index * frame_size,
            "y": 0,
            "w": frame_size,
            "h": frame_size,
            "duration_ms": duration,
            "pivot": {"x": pivot[0], "y": pivot[1]},
        }
        for index in range(frame_count)
    ]
    manifest = {
        "version": "2.0.0",
        "character_id": str(job["character_id"]),
        "source_action_id": str(job["source_action_id"]),
        "action_id": str(job["action_id"]),
        "paired_character_id": str(job.get("paired_character_id", "")),
        "image": "spritesheet.png",
        "image_sha256": sha256(atlas_path),
        "preview": "preview.gif",
        "preview_sha256": sha256(preview_path),
        "raw_sheet": "raw_sheet.png",
        "raw_sheet_sha256": sha256(raw_copy),
        "clean_sheet": "clean_sheet.png",
        "clean_sheet_sha256": sha256(clean_path),
        "contact_sheet": "contact_sheet.png",
        "contact_sheet_sha256": sha256(contact_path),
        "placeholder": False,
        "candidate_only": True,
        "loop": bool(job["loop"]),
        "fps": int(job["fps"]),
        "runtime_context": str(job["runtime_context"]),
        "runtime_state_initial": str(job["runtime_state_initial"]),
        "runtime_state_final": str(job["runtime_state_final"]),
        "facing": str(job["facing"]),
        "interaction_origin": {"x": pivot[0], "y": pivot[1]},
        "frame_layout": layout,
        "events": list(job.get("events", [])),
        "resource_delta": dict(job.get("resource_delta", {})),
        "result": str(job.get("result", "")),
        "source_anchor": anchor_path.relative_to(ROOT).as_posix(),
        "qa_status": str(job.get("qa_status", "asset_qa_pending_visual_review")),
        "runtime_gate": "godot_4_2_and_mobile_pending",
        "license": "project-generated-original; final release legal review required",
    }
    manifest_path = output_dir / "manifest.json"
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    boxes = [frame.getchannel("A").getbbox() for frame in frames]
    metadata = {
        "version": "2.0.0",
        "character_id": str(job["character_id"]),
        "source_action_id": str(job["source_action_id"]),
        "frame_size": [frame_size, frame_size],
        "frame_count": frame_count,
        "fps": int(job["fps"]),
        "loop": bool(job["loop"]),
        "pivot": {"x": pivot[0], "y": pivot[1]},
        "alpha_boxes": [list(box) if box is not None else None for box in boxes],
        "texture_filter": "nearest",
        "runtime_transition": {
            "from": str(job["runtime_state_initial"]),
            "to": str(job["runtime_state_final"]),
        },
        "events": list(job.get("events", [])),
        "resource_delta": dict(job.get("resource_delta", {})),
        "result": str(job.get("result", "")),
        "qa_status": manifest["qa_status"],
        "spritesheet_sha256": sha256(atlas_path),
    }
    (output_dir / "metadata.json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    (output_dir / "source_notes.md").write_text(
        "# Fonte da animação\n\n"
        "Tira gerada integralmente pela ferramenta de imagem integrada da OpenAI a "
        "partir da folha-modelo, seed e key pose canônicos do projeto. O chroma foi "
        "removido deterministicamente e todos os quadros usam escala e pivô comuns.\n\n"
        "O pack é candidato e não substitui o placeholder até passar pelo Godot 4.2+, "
        "transições mecânicas e QA mobile.\n",
        encoding="utf-8",
    )
    (output_dir / "import_notes.md").write_text(
        "# Importação Godot\n\n"
        f"- Importar `spritesheet.png` sem filtro/mipmaps, {frame_count} quadros de "
        f"{frame_size}x{frame_size}, {job['fps']} FPS.\n"
        f"- Loop: `{str(bool(job['loop'])).lower()}`; pivô: `{pivot}`.\n"
        f"- Transição: `{job['runtime_state_initial']}` → `{job['runtime_state_final']}`.\n"
        "- Disparar os eventos descritos no manifesto e preservar fallback.\n",
        encoding="utf-8",
    )
    (output_dir / "qa_report.md").write_text(
        "# QA do asset\n\n"
        f"- Quadros: `{frame_count}`; caixas alfa: `{boxes}`.\n"
        f"- Atlas SHA-256: `{sha256(atlas_path)}`.\n"
        f"- Status: `{manifest['qa_status']}`.\n"
        "- Teste Godot e mobile pendentes.\n",
        encoding="utf-8",
    )
    return {
        "character_id": str(job["character_id"]),
        "action_id": str(job["action_id"]),
        "frames": frame_count,
        "manifest": manifest_path.relative_to(ROOT).as_posix(),
        "spritesheet_sha256": sha256(atlas_path),
    }


def build_paired_animatic(config: dict[str, Any]) -> dict[str, Any]:
    source_manifest = ROOT / str(config["source_manifest"])
    source = json.loads(source_manifest.read_text(encoding="utf-8"))
    output_dir = ROOT / str(config["output"])
    frames_dir = output_dir / "frames"
    frames_dir.mkdir(parents=True, exist_ok=True)
    frames: list[Image.Image] = []
    states: list[str] = []
    for index, item in enumerate(source.get("states", []), start=1):
        state = str(item["state"])
        source_path = ROOT / str(item["path"])
        target = frames_dir / f"{index:02d}_{state}.png"
        shutil.copyfile(source_path, target)
        frames.append(Image.open(target).convert("RGBA"))
        states.append(state)
    if not frames:
        raise ValueError("Animatic pareado sem frames.")
    frame_size = frames[0].width
    atlas = Image.new("RGBA", (frame_size * len(frames), frame_size), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        atlas.alpha_composite(frame, (index * frame_size, 0))
    atlas_path = output_dir / "spritesheet.png"
    atlas.save(atlas_path, optimize=True)
    preview_path = output_dir / "preview.gif"
    write_gif(frames, preview_path, int(config["fps"]))
    contact_path = output_dir / "contact_sheet.png"
    build_contact_sheet(frames, frame_size).save(contact_path, optimize=True)
    events = [
        "grip_connect",
        "weight_commit",
        "off_balance",
        "impact",
        "control_stable",
        "tap_window",
        "reset_ready",
    ]
    duration = round(1000 / int(config["fps"]))
    manifest = {
        "version": "2.0.0",
        "sequence_id": str(config["id"]),
        "characters": list(source.get("characters", [])),
        "image": "spritesheet.png",
        "image_sha256": sha256(atlas_path),
        "preview": "preview.gif",
        "preview_sha256": sha256(preview_path),
        "contact_sheet": "contact_sheet.png",
        "contact_sheet_sha256": sha256(contact_path),
        "placeholder": False,
        "animatic_only": True,
        "loop": bool(config["loop"]),
        "fps": int(config["fps"]),
        "frame_layout": [
            {
                "index": index,
                "state": state,
                "path": f"frames/{index + 1:02d}_{state}.png",
                "sha256": sha256(frames_dir / f"{index + 1:02d}_{state}.png"),
                "x": index * frame_size,
                "y": 0,
                "w": frame_size,
                "h": frame_size,
                "duration_ms": duration,
                "pivot": {"x": frame_size // 2, "y": frame_size - 20},
            }
            for index, state in enumerate(states)
        ],
        "events": [
            {"frame": index, "name": name} for index, name in enumerate(events)
        ],
        "qa_status": "asset_qa_passed_runtime_animation_pending",
        "runtime_gate": "intermediate_frames_and_godot_pending",
    }
    manifest_path = output_dir / "manifest.json"
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    (output_dir / "source_notes.md").write_text(
        "# Animatic biomecânico\n\n"
        "Compilado deterministicamente das sete key poses aprovadas de Ruan × Davi. "
        "Serve para validar leitura, ordem e eventos antes de gerar in-betweens.\n",
        encoding="utf-8",
    )
    return {
        "sequence_id": str(config["id"]),
        "frames": len(frames),
        "manifest": manifest_path.relative_to(ROOT).as_posix(),
        "spritesheet_sha256": sha256(atlas_path),
    }


def main() -> None:
    args = parse_args()
    catalog_path = ROOT / args.catalog
    catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    built: list[dict[str, Any]] = []
    if not args.animatic_only:
        jobs = list(catalog.get("jobs", []))
        if args.job:
            jobs = [
                job
                for job in jobs
                if f"{job['character_id']}:{job['source_action_id']}" == args.job
            ]
            if not jobs:
                raise SystemExit(f"Job não encontrado: {args.job}")
        built = [build_job(job) for job in jobs]
    animatic = None
    if not args.job:
        animatic = build_paired_animatic(dict(catalog["paired_animatic"]))
    print(json.dumps({"ok": True, "jobs": built, "animatic": animatic}, ensure_ascii=False))


if __name__ == "__main__":
    main()
