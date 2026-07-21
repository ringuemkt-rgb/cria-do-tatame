#!/usr/bin/env python3
"""Empacota uma tira idle gerada em um lote de producao completo para Godot."""

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path

from PIL import Image, ImageDraw

from chroma_key_asset import remove_chroma
from normalize_sprite_strip_to_anchor import (
    alpha_bbox,
    keep_largest_alpha_component,
    split_horizontal,
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Constroi um pack idle de quatro quadros.")
    parser.add_argument("--character-id", required=True)
    parser.add_argument("--action-id", required=True)
    parser.add_argument("--raw-chroma", required=True)
    parser.add_argument("--seed", required=True)
    parser.add_argument("--out-dir", required=True)
    parser.add_argument("--key", choices=("green", "cyan"), default="green")
    parser.add_argument("--facing", choices=("left", "right"), required=True)
    parser.add_argument("--runtime-state", required=True)
    parser.add_argument("--context", choices=("combat", "hub"), required=True)
    parser.add_argument("--fps", type=int, default=8)
    return parser.parse_args()


def normalize_frames(strip: Image.Image, anchor: Image.Image) -> tuple[list[Image.Image], tuple[int, int]]:
    anchor_box = alpha_bbox(anchor, 8)
    if anchor_box is None:
        raise SystemExit("Seed sem conteudo alfa.")
    slots = split_horizontal(strip, 4)
    contents: list[Image.Image] = []
    for slot in slots:
        slot = keep_largest_alpha_component(slot, 8)
        box = alpha_bbox(slot, 8)
        if box is None:
            raise SystemExit("Tira contem slot vazio.")
        contents.append(slot.crop(box))

    anchor_height = anchor_box[3] - anchor_box[1]
    max_width = max(content.width for content in contents)
    max_height = max(content.height for content in contents)
    center_x = round((anchor_box[0] + anchor_box[2]) / 2)
    ground_y = anchor_box[3]
    available_width = 2 * min(center_x, anchor.width - center_x)
    # Preserva a altura do corpo; a largura apenas impede clipping real do gesto.
    scale = min(anchor_height / max_height, available_width / max_width)

    frames = [anchor.copy()]
    for content in contents[1:]:
        width = max(1, round(content.width * scale))
        height = max(1, round(content.height * scale))
        resized = content.resize((width, height), Image.Resampling.NEAREST)
        frame = Image.new("RGBA", anchor.size, (0, 0, 0, 0))
        frame.alpha_composite(resized, (round(center_x - width / 2), ground_y - height))
        frames.append(frame)
    return frames, (center_x, ground_y)


def build_contact_sheet(frames: list[Image.Image], gap: int = 8) -> Image.Image:
    width = len(frames) * 256 + (len(frames) - 1) * gap
    sheet = Image.new("RGBA", (width, 256), (0, 0, 0, 255))
    draw = ImageDraw.Draw(sheet)
    colors = ((240, 243, 246, 255), (225, 230, 235, 255))
    for top in range(0, 256, 16):
        for left in range(0, width, 16):
            draw.rectangle(
                (left, top, left + 16, top + 16),
                fill=colors[((left // 16) + (top // 16)) % 2],
            )
    for index, frame in enumerate(frames):
        sheet.alpha_composite(frame, (index * (256 + gap), 0))
    return sheet


def write_text_outputs(
    out_dir: Path,
    args: argparse.Namespace,
    pivot: tuple[int, int],
    boxes: list[tuple[int, int, int, int]],
) -> None:
    duration = round(1000 / args.fps)
    layout = [
        {
            "index": index,
            "state": args.action_id,
            "x": index * 256,
            "y": 0,
            "w": 256,
            "h": 256,
            "duration_ms": duration,
            "pivot": {"x": pivot[0], "y": pivot[1]},
        }
        for index in range(4)
    ]
    manifest = {
        "version": "1.0.0",
        "character_id": args.character_id,
        "action_id": args.action_id,
        "image": "spritesheet.png",
        "preview": "preview.gif",
        "placeholder": False,
        "loop": True,
        "fps": args.fps,
        "runtime_context": args.context,
        "runtime_state_initial": args.runtime_state,
        "runtime_state_final": args.runtime_state,
        "facing": args.facing,
        "interaction_origin": {"x": pivot[0], "y": pivot[1]},
        "frame_layout": layout,
        "events": [],
        "source_seed": str(Path(args.seed).as_posix()),
        "license": "project-generated-original; final release legal review required",
    }
    metadata = {
        "version": "1.0.0",
        "character_id": args.character_id,
        "action_id": args.action_id,
        "runtime_context": args.context,
        "runtime_transition": {"from": args.runtime_state, "to": args.runtime_state},
        "facing": args.facing,
        "frame_size": [256, 256],
        "frame_count": 4,
        "fps": args.fps,
        "loop": True,
        "pivot": {"x": pivot[0], "y": pivot[1]},
        "texture_filter": "nearest",
        "mechanical_events": [],
        "result": "no_state_change",
        "qa_status": "asset_qa_passed_runtime_test_pending",
    }
    (out_dir / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    (out_dir / "metadata.json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    (out_dir / "source_notes.md").write_text(
        "# Source notes\n\n"
        "Tira gerada em uma unica edicao pela ferramenta de imagem integrada da OpenAI "
        f"a partir do seed `{args.seed}` e da folha-modelo canonica. O fundo "
        f"{args.key} recebeu remocao deterministica; o quadro 01 foi travado ao seed. "
        "Nenhuma marca, pessoa real ou asset externo foi usado. A geracao e original do "
        "projeto e permanece sujeita ao gate juridico de release.\n",
        encoding="utf-8",
    )
    (out_dir / "import_notes.md").write_text(
        "# Importacao Godot\n\n"
        "- Importar `spritesheet.png` sem filtro e sem mipmaps.\n"
        "- Usar quatro regioes absolutas de 256x256 descritas em `manifest.json`.\n"
        f"- Pivo `({pivot[0]}, {pivot[1]})`, {args.fps} FPS e loop.\n"
        f"- Contexto `{args.context}`, estado `{args.runtime_state}`; nao altera recurso ou estado.\n"
        "- Promover sobre o placeholder somente depois do teste in-engine.\n",
        encoding="utf-8",
    )
    heights = [box[3] - box[1] for box in boxes]
    widths = [box[2] - box[0] for box in boxes]
    bottoms = [box[3] for box in boxes]
    (out_dir / "qa_report.md").write_text(
        "# QA visual e mecanico\n\n"
        f"- Quatro quadros RGBA 256x256; caixas visiveis: `{boxes}`.\n"
        f"- Alturas: `{heights}`; larguras: `{widths}`; linha do chao: `{bottoms}`.\n"
        "- Quadro 01 pixel-identical ao seed; alpha e nearest-neighbor preservados.\n"
        "- O loop nao altera estado nem consome recurso.\n"
        "- Teste Godot permanece pendente porque o executavel nao existe neste ambiente.\n",
        encoding="utf-8",
    )


def main() -> None:
    args = parse_args()
    if args.fps < 1:
        raise SystemExit("--fps deve ser maior que zero")
    raw_path = Path(args.raw_chroma)
    seed_path = Path(args.seed)
    out_dir = Path(args.out_dir)
    frames_dir = out_dir / "frames"
    frames_dir.mkdir(parents=True, exist_ok=True)

    shutil.copyfile(raw_path, out_dir / "raw_sheet.png")
    clean = remove_chroma(Image.open(raw_path), args.key, 15)
    clean.save(out_dir / "clean_sheet.png", optimize=True)
    anchor = Image.open(seed_path).convert("RGBA")
    if anchor.size != (256, 256):
        raise SystemExit(f"Seed invalido: {anchor.size}; esperado 256x256")
    frames, pivot = normalize_frames(clean, anchor)
    for index, frame in enumerate(frames, start=1):
        frame.save(frames_dir / f"{index:02d}.png", optimize=True)

    atlas = Image.new("RGBA", (1024, 256), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        atlas.alpha_composite(frame, (index * 256, 0))
    atlas.save(out_dir / "spritesheet.png", optimize=True)
    frames[0].save(
        out_dir / "preview.gif",
        save_all=True,
        append_images=frames[1:],
        duration=round(1000 / args.fps),
        loop=0,
        disposal=2,
    )
    build_contact_sheet(frames).save(out_dir / "contact_sheet.png", optimize=True)
    boxes = [frame.getchannel("A").getbbox() for frame in frames]
    if any(box is None for box in boxes):
        raise SystemExit("Pack gerou quadro vazio.")
    concrete = [box for box in boxes if box is not None]
    write_text_outputs(out_dir, args, pivot, concrete)
    print(
        json.dumps(
            {
                "ok": True,
                "character_id": args.character_id,
                "action_id": args.action_id,
                "pivot": pivot,
                "boxes": concrete,
                "out_dir": str(out_dir),
            },
            ensure_ascii=False,
        )
    )


if __name__ == "__main__":
    main()
